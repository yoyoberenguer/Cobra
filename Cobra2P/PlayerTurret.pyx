

import pygame
from pygame import Vector2, Rect
from pygame import Surface, BLEND_RGB_ADD
from pygame.transform import rotozoom, rotate

from Textures import MUZZLE_FLASH, TURRET_TARGET_SPRITE
from Tools cimport make_transparent32
from Weapons import TURRET_STRATEGY

# DO NOT REMOVE METHODS FROM LINE BELOW
from AI_cython import Threat, colliders_c, GetNearestTarget, \
    GetFarthestTarget, SortByHarmlessTarget, SortByDeadliestTarget

from HighLightTarget import HighlightTarget

class ERROR(BaseException):
    pass

from Sprites cimport Sprite, LayeredUpdates, GroupSingle
from Sprites import Group

from libc.math cimport atan2, cos, sin


cdef extern from 'Include/vector.c':

    struct vector2d:
       float x
       float y

    struct rect_p:
        int x
        int y

    int randRange(int lower, int upper)nogil;

DEF M_PI       = 3.14159265358979323846
DEF M_2PI      = 2 * M_PI
DEF M_PI2      = 3.14159265358979323846 / 2.0
DEF DEG_TO_RAD = M_PI / 180.0
DEF RAD_TO_DEG = 1.0 / DEG_TO_RAD


# CYTHON IS REQUIRED
try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject_CallFunctionObjArgs, PyObject, \
        PyList_SetSlice, PyObject_HasAttr, PyObject_IsInstance, \
        PyObject_CallMethod, PyObject_CallObject
    from cpython.dict cimport PyDict_DelItem, PyDict_Clear, PyDict_GetItem, PyDict_SetItem, \
        PyDict_Values, PyDict_Keys, PyDict_Items
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size
    from cpython.object cimport PyObject_SetAttr

except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
                      "\nTry: \n   C:\\pip install cython on a window command prompt.")

cdef:
    list TURRET_INVENTORY = []
    TURRET_INVENTORY_APPEND = TURRET_INVENTORY.append
    TURRET_INVENTORY_REMOVE = TURRET_INVENTORY.remove


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline float get_angle(int x, int y, int x1, int y1)nogil:
    return -RAD_TO_DEG * <float>atan2(y - y1, x - x1)


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(False)
@cython.profile(False)
cdef class TurretShot(Sprite):

    cdef:
        public object image, rect, _blend, weapon, player
        object p_turret, laser_orientation, images_copy,\
            acceleration_vector, gl, follower
        public tuple pos
        int dt, index
        bint loop
        float timing, target_angle

    """
    TurretShot(
   gl_all,
   self.weapon.sprite,
   player_      =self.player,
   target       =current_target,
   position     =self.turret_center_position(
       self.image, angle_deg),
   target_angle =angle_deg,
   gl           =gl,
   follower     =self.follower,
   )

    """
    def __init__(self,
                 group_,
                 images_,
                 player_,
                 target,
                 position,
                 target_angle,
                 gl,
                 follower,
                 float timing=16.67,
                 bint loop=True, int layer_=-1):

        Sprite.__init__(self, group_)

        if PyObject_IsInstance(gl.All, LayeredUpdates):
            gl.All.change_layer(self, layer_)

        self.player             = player_
        self.p_turret           = player_.turret
        # Projectile angle in degrees (zero for NEMESIS)
        self.laser_orientation  = self.p_turret.laser_orientation
        self.images_copy        = images_.copy()
        self.image              = <object>PyList_GetItem(self.images_copy, 0)\
            if PyObject_IsInstance(self.images_copy, list) else self.images_copy

        cdef:
            int pos_center_x = self.player.rect.centerx
            int pos_center_y =  self.player.rect.centery

        # PROJECTILE START POSITION WHEN TURRET IS FIRING
        self.proj_position = Vector2(pos_center_x, pos_center_y)

        self.dt           = 0
        self.index        = 0
        self.timing       = timing
        self.loop         = loop
        self.target_angle = <int>target_angle
        self._blend       = BLEND_RGB_ADD

        self.weapon = self.p_turret.mounted_weapon

        self.acceleration_vector = self.vector_determinant_calculator(
            <int> target_angle, self.weapon.velocity.length())

        self.target_id = id(target)

        self.target_centre = target.rect.center
        self.target_speed  = target.vector

        if self.p_turret.aim_assist:
            self.acceleration_vector, target_angle = self.auto_aim()

        self.image = rotozoom(self.image, <int>(target_angle % <unsigned int>360), <float>1.0)
        self.rect = self.image.get_rect(center=(self.player.rect.centerx,
                                                self.player.rect.centery))

        self.gl = gl
        self.follower = follower

        # PLAY THE SHOOTING SOUND
        self.shooting_sound()
        self.muzzle_flash()

        # ADD THE SHOT TO THE GL.SHOTS GROUP
        self.gl.shots.add(self)


    cdef void muzzle_flash(self):
        """
        TURRET MUZZLE FLASH ANIMATION
        
        :return: void  
        """
        cdef int i = 0
        cdef list muzzle_flash_copy = MUZZLE_FLASH.copy()

        for surface in muzzle_flash_copy:
            muzzle_flash_copy[i] = rotozoom(surface, self.target_angle, 1.0)
            i += 1

        instance_ = self.follower(self.gl, self.gl.All, muzzle_flash_copy,
                                  offset_=(self.rect.centerx - <unsigned char>1,
                                           self.rect.centery + <unsigned char>5),
                                  timing_=15, loop_=False, layer_=-1)
        if PyObject_IsInstance(instance_, self.follower):
            TURRET_INVENTORY_APPEND(instance_)

    cdef void shooting_sound(self):
        """
        CREATE THE LASER SOUND
        :return: void
        """
        self.gl.SC_spaceship.play(
            sound_=self.weapon.sound_effect, loop_=False, priority_=0,
            volume_=self.gl.SOUND_LEVEL, fade_out_ms=0, panning_=True,
            name_=self.weapon.name, x_=self.rect.center[0],
            object_id_=self.target_id)

    cdef void stop_shooting_sound(self):
        """
        STOP THE SHOOTING SOUND 
        :return: Void
        """
        self.gl.SC_spaceship.stop_object(self.target_id)

    cdef tuple auto_aim(self):
        """
        TURRET AUTO AIM OPTION
        
        Take into account the speed and direction of the target (shoot ahead of the target) for 
        100% shot accuracy.
        
        Return vector to target and turret angle 
        :return: tuple; vector (not normalized) and turret angle (in degrees)
        """

        cdef:
            float distance_from_player     = self.proj_position.distance_to(self.target_centre)
            float acceleration = self.acceleration_vector.length()

        if acceleration == 0.0:
            raise ValueError('WARNING - Turret weapon acceleration vector length should not '
                             'be equal to zero.')

        cdef float eta = distance_from_player / acceleration

        target_position_calculated = self.target_speed * eta + Vector2(self.target_centre)

        # TODO USE GET_ANGLE
        cdef int new_target_angle = -<int>(
                <float>atan2(target_position_calculated.y - self.proj_position.y,
                             target_position_calculated.x - self.proj_position.x) * RAD_TO_DEG)

        new_vector = self.vector_determinant_calculator(new_target_angle, acceleration)

        return new_vector, new_target_angle


    cdef vector_determinant_calculator(self, int angle_, float vector_magnitude):
        """
        Return a vector pointing toward the target position
        
        :param angle_: integer; Angle in degrees; Target angle
        :param vector_magnitude: float; Length of the vector, this correspond to the bullet speed 
        :return: Vector2; Laser shot direction
        """

        angle_ %= 360

        cdef float angle_rad = <float>DEG_TO_RAD * angle_
        return Vector2(<float>cos(angle_rad) * vector_magnitude,
                       <float>sin(angle_rad) * -vector_magnitude)


    cdef quit(self):
        self.stop_shooting_sound()
        self.kill()

    cpdef update(self, args=None):

        if self.dt > self.timing:

            self.index = 0

            if self.gl.screenrect.colliderect(self.rect):

                self.proj_position += self.acceleration_vector
                self.rect = self.image.get_rect(center=(self.proj_position.x, self.proj_position.y))

            else:
                self.quit()

            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS


        if not self.player.alive():
            global TURRET_INVENTORY
            for instance_ in TURRET_INVENTORY:
                if PyObject_HasAttr(instance_, 'kill_instance'):
                    instance_.kill_instance(instance_)
            TURRET_INVENTORY = []
            self.quit()



# LIST; TELLS IF THE TURRETS ARE INITIALISED TURRET_INITIALISED[0] IS PLAYER 1
# TURRET_INITIALISED[1] IS PLAYER 2
TURRET_INITIALISED = [False, False]


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(False)
@cython.profile(False)
cdef class Turret(Sprite):

    cdef:
        public object image, rect, _blend, player, weapon, gl
        public int n_player
        object p_turret, images_copy, group, vector_target, \
            highlight_target, target_group, follower
        int turret_angle, rotation_step, max_rotation, index
        bint lock
        float dt, timing, timestamp, target_distance



    def __init__(self, containers_, images_, player_, n_player, gl_,
                 follower_, timing_, group_, weapon_, int layer_=0):

        global TURRET_INITIALISED
        # todo remove these lines before releasing the game
        assert int(n_player) >= 1, '\n n_player argument should be equal or above 1'
        if TURRET_INITIALISED[int(n_player) - 1]:
             raise ValueError('Turret player %s is already running.' % n_player)

        Sprite.__init__(self, containers_)

        if isinstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.gl          = gl_
        self.player      = player_
        self.n_player    = int(n_player) - 1
        self.p_turret    = player_.turret
        self.images_copy = images_.copy()

        self.image = self.images_copy if PyObject_IsInstance(images_, Surface) \
            else self.images_copy[0]

        self.rect = self.image.get_rect(
            center=(player_.rect.centerx,
                    player_.rect.centery + <unsigned char>5))

        # TURRET POINTING DOWN WHEN INITIALISED -270 DEGRES
        self.turret_angle  = self.p_turret.rest_angle
        self.rotation_step = self.p_turret.rotation_speed
        self.max_rotation  = self.p_turret.max_rotation
        # TURRET IN LOCK POSITION
        self.lock          = False
        self.dt            = 0
        self.timing        = timing_

        self.group         = group_

        self.weapon        = weapon_
        self.vector_target = Vector2()
        self.timestamp     = 0

        self.highlight_target = None
        self.target_group     = GroupSingle()

        self.index            = 0
        self.follower         = follower_

        self.target_group.empty()

        TURRET_INITIALISED[self.n_player] = True


    cdef void blinking(self):
        """
        BLINK THE SPRITE (e.g AFTER PLAYER EXPLOSION, ALSO INDICATE PLAYER INVULNERABILITY) 
        
        :return: Void 
        """
        self.image=make_transparent32(self.image, self.player.visibility)

    cdef tuple rot_center(self, image_, int angle_, rect_):
        """
        RETURN THE SPRITE WITH A NEW ANGLE AND DETERMINE THE NEW RECT SIZE AFTER TRANSFORMATION
        
        :param image_: pygame.Sprite; Sprite to rotate  
        :param angle_: integer; angle in degrees
        :param rect_ : Rect; Actual rect size 
        :return: tuple; containing the rotated sprite and new rect
        """
        new_image = rotozoom(image_, angle_, <float>1.0)
        return new_image, new_image.get_rect(center=rect_.center)


    cdef target(self, group_, str strategy, str fallback_strategy):
        """
        STRATEGY LIST 
        STRATEGY = ['NEAR_COLLISION',  # near objects in collision course with the player 
                    'FAR_COLLISION',   # far objects in collision course with the player 
                    'LOW_DEADLINESS',  # least deadliest objects got highest priority 
                    'HIGH_DEADLINESS', # Deadlier objects got highest priority 
                    'FRONT',           # Object located at the front of the player center
                     ...
                    'NEAREST',
                    'FARTHEST',
                    'ENEMY']
        
        :param group_           : pygame.Groups; Sprite group(s) containing all the enemy 
        (this includes missiles)
        :param strategy         : string; Define the turret strategy (target priority)
        :param fallback_strategy: string; Fallback strategy when the first strategy does not
         found any target
        :return: Tuple; Return a tuple such as (371.3031005859375, [<Enemy Sprite(in 1522 
        groups)>, 2422545305072]) 
        with distance from the player and the enemy sprite or return None for no target.
        """

        # TAKE A SPRITE GROUP AS ARGUMENT AND CONVERT THE SPRITE GROUP INTO AN ENTITY MODEL
        stack = Threat(self.player.rect).create_entities(self.gl.screenrect, group_)

        # RETURN A TUPLE SUCH AS (371.3031005859375, [<Enemy Sprite(in 1522 groups)>,
        # 2422545305072]) OR
        # RETURN NONE (NO ENEMY)
        target = eval(<object>PyDict_GetItem(TURRET_STRATEGY, strategy))

        # IF STILL NO TARGET, USE FALLBACK STRATEGY
        if target is None:
            target = eval(<object>PyDict_GetItem(TURRET_STRATEGY, fallback_strategy))

        # RETURN A TUPLE OR NONE
        return target

    cdef tuple turret_center_position(self, image_, int angle_):
        """
        RETURN THE TURRET SPRITE CENTER (TURRET CENTER)
        
        :param image_: pygame.Sprite;  
        :param angle_: integer; Sprite orientation in degrees
        :return: tuple; Return the sprite center 
        """
        cdef int w, h
        w = image_.get_width()
        h = image_.get_height()
        cdef float angle_rad = angle_ * <float>DEG_TO_RAD
        return <int>(<float>cos(angle_rad) * w) // <unsigned char>2, \
               <int>(<float>sin(angle_rad) * -h) // <unsigned char>2

    cdef bint reloading(self, int frame_):
        """
        RETURN THE TURRET STATUS (FALSE READY TO SHOOT, TRUE STILL RELOADING)
        
        :param frame_: integer; Actual frame number
        :return: bool; Return True | False
        """
        if frame_ - self.timestamp > self.weapon.reloading * self.gl.MAXFPS:
            self.timestamp = 0
            return False
        else:
            return True

    cdef void shooting(self, int frame_):
        """
        UPDATE THE FRAME NUMBER/TIMESTAMP FOR THE RELOADING PROCESS 
        
        :param frame_: integer 
        :return: void 
        """
        self.timestamp = frame_

    cdef bint get_a_target(self):

            cdef float distance
            new_group = Group(*self.group)

            # SEARCH FOR A TARGET
            current_target = self.target(
                group_           = new_group,
                strategy         = self.p_turret.strategy,
                fallback_strategy= self.p_turret.fallback_strategy
            )

            # IF TARGET FOUND
            if current_target is not None:

                if PyObject_IsInstance(current_target, list):
                    target_found = <object> PyList_GetItem(current_target, 0)
                else:
                    distance, t_sprite = current_target
                    target_found = <object>PyList_GetItem(t_sprite, 0)

                # VALID TARGET HAVE A RECT
                if not PyObject_HasAttr(target_found, 'rect'):
                    self.target_group.empty()
                    return False

                self.target_group.add(target_found)
                return True

            return False

    cdef bint has_a_target(self):
        return bool(self.target_group.sprites())

    cpdef update(self, args=None):

        cdef:
            int angle_deg = 0
            int left      = 0
            int right     = 0
            lock          = self.lock
            player_rect   = self.player.rect
            turret_angle  = self.turret_angle
            max_rotation  = self.max_rotation
            gl            = self.gl
            gl_all        = gl.All


        if self.player.alive():

            if self.dt > self.timing:

                # NO CURRENT TARGET, PICK A NEW ONE
                if not self.has_a_target():
                    if not self.get_a_target():
                        lock = False

                if self.has_a_target():

                    current_target = self.target_group.sprites()[0]

                    if current_target.alive() and current_target.rect.colliderect(
                            self.gl.screenrect):
                        # RETURN THE TARGET ANGLE (FROM TURRET CENTER) IN RANGE [0.0 ... 360.0]
                        angle_deg = <int> get_angle(
                            current_target.rect.centerx, current_target.rect.centery,
                            player_rect.centerx, player_rect.centery
                        ) % <unsigned int>360

                        # ANGLE WHEN TURRET TURNS LEFT
                        left = (angle_deg - turret_angle) % <unsigned int>360
                        # TURRET TURNING RIGHT
                        right = (<unsigned int>360 - left)

                        # TURRET IS LOCKED WHEN ANGLE IS BETWEEN ANGLE_RAD +/- self.max_rotation
                        if (angle_deg - max_rotation) < turret_angle < (angle_deg + max_rotation):
                            lock = True
                        else:
                            if left < right:
                                turret_angle += self.rotation_step
                            elif left > right:
                                turret_angle -= self.rotation_step
                            elif left == right:
                                turret_angle += randRange(-<int>1, <int>1) * self.rotation_step
                            lock = False

                        # GET THE DISTANCE BETWEEN TURRET AND TARGET
                        distance = Threat(player_rect).get_point_distance(
                            current_target.rect.center)

                        if lock and self.weapon.range > distance:

                            if not self.reloading(gl.FRAME) and \
                                    self.player.aircraft_specs.energy > self.weapon.energy:


                                t = TurretShot(
                                               gl_all,
                                               self.weapon.sprite,
                                               player_      =self.player,
                                               target       =current_target,
                                               position     =self.turret_center_position(
                                                   self.image, angle_deg),
                                               target_angle =angle_deg,
                                               gl           =gl,
                                               follower     =self.follower,
                                               )

                                self.shooting(gl.FRAME)

                            # IGNORE ENEMY G5V200 AND STATION, TOO BIG
                            if current_target.enemy_.name not in ("G5V200", "STATION"):
                                self.highlight_target = \
                                    HighlightTarget(TURRET_TARGET_SPRITE, gl_all,
                                player_=self.player, gl_=gl, target_=current_target,
                                                    timing_=<float>16.67)

                    else:
                        self.target_group.empty()
                        lock = False


                turret_angle %= <unsigned int>360

                self.dt           = 0
                self.lock         = lock
                self.turret_angle = turret_angle

            self.dt += gl.TIME_PASSED_SECONDS
            self.rect.center = (player_rect.center[0], player_rect.center[1] + <unsigned char>5)

            # draw the turret
            self.image, self.rect = self.rot_center(
                self.images_copy if PyObject_IsInstance(self.images_copy, Surface) else
                self.images_copy[self.index % (len(self.images_copy) - <unsigned char>1)],
                self.turret_angle + <unsigned char>90, self.rect)

            if self.player.invincible:
                self.blinking()

            self.index += 1

        else:
            global TURRET_INITIALISED, TURRET_INVENTORY
            # turret is not initialised (player is dead)
            TURRET_INITIALISED[self.n_player] = False
            self.target_group.empty()
            TURRET_INVENTORY = []
            self.kill()

