# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from BindSprite import BindSprite
from Blast import BLAST_INVENTORY, Blast
from Bonus import bonus_energy, bonus_bomb, bonus_life, bonus_ammo, bonus_gems
from EnemyShield import EnemyShield
from Follower import Follower, FOLLOWER_INVENTORY
from Halo import Halo
from HomingMissile import Homing, ExtraAttributes
from Miscellaneous import ImpactBurst, Score, Explosion1
from PlayerLife import PlayerLife
from ShowDamage import DamageDisplay
from Sounds import EXPLOSION_COLLECTION_SOUND
from Sprites cimport LayeredUpdates
from SurfaceBurst import burst, VERTEX_ARRAY_SUBSURFACE
from Textures import LASER_EX, G5V200_EXPLOSION_DEBRIS, HALO_SPRITE11, HALO_SPRITE12, \
    HALO_SPRITE13, HALO_SPRITE14, RADIAL, \
    SMOKE, HOTFURNACE, HOTFURNACE2 # , LAVA_TEXTURE
from Tools cimport blend_texture_32c, blend_texture_24c, blend_to_textures_24c, \
    blend_to_textures_32c

from Weapons import BEAM

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

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, linspace, ndarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

cimport numpy as np
from numpy cimport float64_t, float32_t, int32_t

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, BLEND_RGB_ADD, Rect
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d,\
        make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotate, flip, rotozoom
except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from XML_parsing import xml_get_weapon, xml_parsing_missile

# Load the missile from xml file
STINGER_XML = dict(xml_get_weapon('xml/Missiles.xml', 'STINGER'))
BUMBLEBEE_XML = dict(xml_get_weapon('xml/Missiles.xml', 'BUMBLEBEE'))
WASP_XML = dict(xml_get_weapon('xml/Missiles.xml', 'WASP'))
HORNET_XML = dict(xml_get_weapon('xml/Missiles.xml', 'HORNET'))

# Parse the values into dictionaries
STINGER_FEATURES = xml_parsing_missile(STINGER_XML)
BUMBLEBEE_FEATURES = xml_parsing_missile(BUMBLEBEE_XML)
WASP_FEATURES = xml_parsing_missile(WASP_XML)
HORNET_FEATURES = xml_parsing_missile(HORNET_XML)



cdef extern from 'Include/randnumber.c':
    void init_clock()nogil;
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;

from Sprites cimport Sprite

from libc.math cimport cos, sin, atan2, sqrt


DEF M_PI = 3.14159265359
DEF M_2PI = M_PI / 2.0
DEF RAD_TO_DEG = 180.0 / M_PI
DEF DEG_TO_RAD = 1.0 / RAD_TO_DEG


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef float get_distance(float p1_x, float p1_y, float p2_x, float p2_y)nogil:
    """
    GET THE DISTANCE BETWEEN THE TO COORDINATES (ENEMY RECT CENTER AND TARGET RECT CENTRE)
    
    :param p1_x: float; Vector coordinate p1 x 
    :param p1_y: float; Vector coordinate p1 y
    :param p2_x: float; Vector coordinate p2 x 
    :param p2_y: float; Vector coordinate p2 y 
    :return: float; Return the distance (float)  
    """
    return <float>sqrt((p2_x - p1_x) * (p2_x - p1_x) + (p2_y - p1_y) * (p2_y - p1_y))

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef float vector_length(float vx, float vy)nogil:
    """
    RETURN THE VECTOR LENGTH such v(x, y) -> |v|
    
    :param vx: Vector coordinate x 
    :param vy: Vector coordinate y 
    :return: float; Return the vector length |v| 
    """
    return <float>sqrt(vx * vx + vy * vy)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef tuple normalized_vector(float vx, float vy):
    """
    NORMALIZED A VECTOR SUCH AS v(x, y) -> v(x/|v|, y/|v|)
    
    :param vx: Vector coordinate x 
    :param vy: Vector coordinate y 
    :return: tuple; Return vector elements v.x, v.y normalized
    """
    cdef float v_length = vector_length(vx, vy)

    if v_length == 0:
        return 0, 0

    cdef:
        float vx_norm = vx / v_length
        float vy_norm = vy / v_length

    return vx_norm, vy_norm


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef tuple rot_center(image_, int angle_, rect_):
    new_image = rotozoom(image_, angle_, <float>1.0)
    return new_image, new_image.get_rect(center=(rect_.centerx, rect_.centery))

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef void show_debris(gl_, screen_):
    """
    DISPLAY ALL THE ENEMY FLYING DEBRIS WITH THE ADDITIVE MODE

    * All debris are slowing down after explosion and sprite's size shrink over the time
    This effect start when the aircraft is exploding

    :param gl_: class; global variable / constants
    :param screen_: Surface; pygame surface (screen display)
    :return: void
    """

    screenrect  = gl_.screenrect
    screen_blit = gl_.screen.blit
    cdef int w, h, reduction_x, reduction_y

    for p_ in gl_.VERTEX_DEBRIS:

        p_rect  = p_.rect

        # DISPLAY THE PARTICLE
        if p_rect.colliderect(screenrect):

            p_index = p_.index

            p_rect.move_ip(p_.vector)
            w, h = p_.image.get_size()

            PyObject_CallFunctionObjArgs(
                screen_blit,
                <PyObject*> p_.image,
                <PyObject*> p_rect.center,
                <PyObject*> None,
                <PyObject*> p_._blend,
                NULL)

            # DEBRIS DECELERATION
            p_.vector *= <float>1.0 / (<float>1.0 + <float>0.0001 * (p_index * p_index))

            reduction_x = <int>(w - p_index / <float>20.0)
            reduction_y = <int>(h - p_index / <float>20.0)

            if reduction_x <=0:
                p_.kill()
            elif reduction_y <=0:
                p_.kill()

            # SIZE REDUCTION EVERY 6 TICKS
            if p_index % 6 == 0:
                p_.image = scale(p_.image, (reduction_x , reduction_y))

            if p_index > 100:
                p_.kill()

            p_.index = p_.index + <unsigned char>1

        else:
            p_.kill()


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef debris(gl_, rect_):
    """
    CREATE ENEMY FLYING DEBRIS
    
    * Create a debris after an explosion
    
    :param rect_: 
    :param gl_: class; global variables/constants 
    :return: void
    """


    # CAP THE NUMBER OF DEBRIS TO AVOID LAG
    if len(gl_.VERTEX_DEBRIS) > 100:
        return

    sprite_ = Sprite()
    image            = G5V200_EXPLOSION_DEBRIS[
        randRange(<int>0, <int>len(G5V200_EXPLOSION_DEBRIS) - 1)]
    sprite_.position = Vector2(<float>rect_.centerx, <float>rect_.centery - <float>30.0)
    sprite_._blend   = BLEND_RGB_ADD
    sprite_.image    = rotozoom(image, randRange(<int>0, <int>360),
                                randRangeFloat(<float>0.1, <float>1.0))
    sprite_.rect     = sprite_.image.get_rect(
        center=(rect_.centerx, rect_.centery - <unsigned char>30))
    sprite_.vector   = Vector2(randRangeFloat(-<float>15.0, <float>15.0),
                               randRangeFloat(-<float>15.0, <float>15.0))
    sprite_.index    = 0

    gl_.VERTEX_DEBRIS.add(sprite_)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef int damage_radius_calculator(int damage_, float gamma_, float distance_)nogil:
    """
    DAMAGE VARY IN FUNCTION TO THE DISTANCE
    
    * proportional to the distance (highest damages at close range)
    * Always return a minimum damage equal to argument damage_
    
    :param damage_  : Maximum damages
    :param gamma_   : Arbitrary constant 0.01 
    :param distance_: Distance from the center of the explosion 
    :return: int; Return the quantity of damages (function to the distance)
    """
    cdef int v

    if damage_ < 0:
        damage_ = 0

    if distance_ == <float>0.0:
        return damage_

    v = <int>(damage_ / (gamma_ * distance_))

    if v < damage_:
        return damage_

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class EnemyShot(Sprite):

    """
    CLASS FOR ENEMY SHOTS.

    This will create a sprite with attributes (check below the list)
    The sprite will be place into two groups (gl.enemyshots, gl.All)
    gl.enemyshots is a group type and gl.All is a LayeredUpdatesModified (derived from
    LayeredUpdates group)
    """

    cdef:
        public int _layer, _blend
        object weapon, images_copy, speed, vector
        public image, rect
        public int damage
        object pos
        int index, dt, timing

    def __init__(self, gl_, containers_, tuple pos_, weapon_,
                 bint mute_, tuple offset_, vector_, int angle_,
                 float spaceship_aim_, rect_, int timing_= 33,
                 int layer_ = -5, blend_=BLEND_RGB_ADD):
        """

        :param gl_:
        :param containers_:
        :param pos_:
        :param weapon_:
        :param mute_:
        :param offset_:
        :param vector_:
        :param angle_:
        :param spaceship_aim_: float; Angle in radians
        :param rect_:
        :param timing_:
        :param layer_:
        :param blend_:
        """

        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self._layer      = layer_
        self.weapon      = weapon_
        self.damage      = weapon_.damage
        self.images_copy = self.weapon.sprite.copy()

        self.image       = <object>PyList_GetItem(self.images_copy, 0) if \
            PyObject_IsInstance(self.images_copy, list) else self.images_copy

        self.image       = rotozoom(self.image, angle_, 1)
        self.speed       = weapon_.velocity
        # LASER VECTOR 2D NORMALIZED (LASER DIRECTION)
        self.vector      = vector_
        self.gl_         = gl_
        self._blend      = blend_

        cdef tuple offset

        if offset_ is None:
            offset_ = (0, 0)

        cdef float dx, dy, hypo
        dx = pos_[0] + offset_[0] - rect_.centerx
        dy = pos_[1] + offset_[1] - rect_.centery
        new_vector = Vector2(dx, dy)

        if dx != dy:
            hypo = vector_length(new_vector.x, new_vector.y)
            self.pos = Vector2(
                rect_.centerx + <float>cos(<float>atan2(new_vector.y, new_vector.x) +
                                    spaceship_aim_ + <float>M_2PI) * hypo,
                rect_.centery - <float>sin(<float>atan2(new_vector.y, new_vector.x) +
                                    spaceship_aim_ + <float>M_2PI) * hypo)
        else:
            self.pos = Vector2(rect_.center)

        self.rect   = self.image.get_rect(center=self.pos)
        self.index  = 0
        self.dt     = 0
        self.timing = timing_

        cdef int i

        if self.weapon.name == 'LZRFX025':

            if PyObject_HasAttr(self.weapon, 'animation') and self.weapon.animation is not None:
                animation = self.weapon.animation.copy()
                i = 0
                for surface in animation:
                    animation[i] = rotate(surface, <float>RAD_TO_DEG * spaceship_aim_)
                    i += 1

                Follower(gl_,
                         gl_.All,
                         animation,
                         offset_        = self.rect.center,
                         timing_        = 15,
                         loop_          = False,
                         event_         = 'Muzzle flash',
                         object_        = self,
                         layer_         = -2,
                         vector_        = None,
                         blend_         = 0)

        if not mute_:
            mixer = gl_.SC_spaceship
            if mixer.get_identical_sounds(self.weapon.sound_effect):
                mixer.stop_object(id(self.weapon.sound_effect))
            mixer.play(sound_           = self.weapon.sound_effect,
                       loop_            = False,
                       priority_        = 0,
                       volume_          = gl_.SOUND_LEVEL,
                       fade_out_ms      = 0,
                       panning_         = True,
                       name_            = self.weapon.name,
                       x_               = self.rect.centerx)

    cpdef location(self):
        return self.rect

    cpdef update(self, args=None):

        cdef int index
        index        = self.index
        weapon       = self.weapon
        w_detonation = weapon.detonation_dist
        gl_          = self.gl_
        p1           = gl_.player
        p2           = gl_.player2
        mixer        = gl_.SC_spaceship
        vec          = self.vector


        if self.dt > self.timing:

            # Animation
            if PyObject_IsInstance(self.images_copy, list):

                self.image = <object>PyList_GetItem(self.images_copy, index)

                if index < len(self.images_copy) -1:
                    index += 1
                else:
                    index = 0

            self.pos += vec * vector_length(self.speed.x, self.speed.y)
            self.rect.center = self.pos

            # GROUND TURRET SHOT
            if PyObject_HasAttr(weapon, "detonation_dist") and w_detonation is not None:

                if bool(gl_.PLAYER_GROUP):

                    if p1.alive() and not p1.invincible:

                        # PLAYER 1
                        if get_distance(p1.position.x, p1.position.y,
                                        self.pos.x, self.pos.y) < w_detonation:

                            PlayerLife(gl_, player_=p1, object_=self)
                            mixer.play(sound_           = EXPLOSION_COLLECTION_SOUND[6],
                                       loop_            = False,
                                       priority_        = 0,
                                       volume_          = gl_.SOUND_LEVEL,
                                       fade_out_ms      = 0,
                                       panning_         = True,
                                       name_            = weapon.name,
                                       x_               = self.rect.centerx)

                            Follower(gl_,
                                     gl_.All,
                                     LASER_EX,
                                     offset_        = self.rect.center,
                                     timing_        = 20,
                                     loop_          = False,
                                     event_         = 'LASER_EX',
                                     object_        = self,
                                     layer_         = -2,
                                     vector_        = vec,
                                     blend_         = BLEND_RGB_ADD)

                            self.kill()

                    if p2 and p2.alive() and not p2.invincible:

                        # PLAYER 2
                        if get_distance(p2.position.x, p2.position.y,
                                        self.pos.x, self.pos.y) < w_detonation:

                            PlayerLife(gl_, player_=p2, object_=self)
                            mixer.play(sound_           = EXPLOSION_COLLECTION_SOUND[6],
                                       loop_            = False,
                                       priority_        = 0,
                                       volume_          = gl_.SOUND_LEVEL,
                                       fade_out_ms      = 0,
                                       panning_         = True,
                                       name_            = weapon.name,
                                       x_               = self.rect.centerx)

                            Follower(gl_,
                                     gl_.All,
                                     LASER_EX,
                                     offset_            = self.rect.center,
                                     timing_            = 20,
                                     loop_              = False,
                                     event_             = 'LASER_EX',
                                     object_            = self,
                                     layer_             = -2,
                                     vector_            = vec,
                                     blend_             = BLEND_RGB_ADD)

                            self.kill()

            if not self.rect.colliderect(gl_.screenrect):
                self.kill()

            self.dt = 0
            self.index =index

        self.dt += gl_.TIME_PASSED_SECONDS


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef select_player(gl_):
    """
    ENEMY SELECT PLAYER 1 OR PLAYER 2 AS A TARGET 
    
    * Return player 1 or player 2.
    * Return None if no players are alive 
    
    :param gl_: class; Global variables / constants
    :return: Return player 1 or player 2 or return None if no players are alive
    """
    sg                 = gl_.PLAYER_GROUP
    cdef bint sg_any_sprites = bool(sg)  #  test if any Sprites are contained
    cdef int sg_length = len(sg)
    p1                 = gl_.player
    p2                 = gl_.player2
    cdef bint p1_not_none = p1 is not None
    cdef bint p2_not_none = p2 is not None

    if sg_any_sprites:

        # ONLY ONE PLAYER LEFT IN THE GAME
        # RETURN P1 OR P2
        if sg_length == 1:

            if p1_not_none and sg.has(p1):
                return p1
            elif p2_not_none and sg.has(p2):
                return p2
            else:
                return None

        # TWO PLAYERS IN THE GAME
        # RETURN RANDOMLY P1 OR P2
        if sg_length == 2:
            if p1_not_none and p2_not_none:
                if p1.alive() and p2.alive():
                    return [p1, p2][randRange(0, 1)]
                else:
                    if p1.alive():
                        return p1
                    else:
                        return p2
            else:
                if p1_not_none:
                    return p1
                else:
                    return p2

        if sg_length == 0 and not sg_any_sprites:
            return None
    else:
        return None


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
class EnemyParentClass(Sprite):

    """
    ENEMY PARENT CLASS inheriting from Sprite class

    This class contains methods for the enemies, a sprite instantiateded
    with this class will inherit all its methods + Sprites methods

    """

    def __init__(self, gl_):

        Sprite.__init__(self, gl_.All)
        self.gl = gl_

    # TODO THIS METHOD CAN BE CALLED DIRECTLY (STATICMETHOD)
    def select_player(self):
        return select_player(self.gl)


    @staticmethod
    def show_debris(gl_, screen_):
        show_debris(gl_, screen_)

    @staticmethod
    def rot_center(image_, angle_, rect_):
        return rot_center(image_, angle_, rect_)

    def debris(self):
        debris(self.gl, self.rect)

    def location(self):
        """
        RETURN SPRITE RECT

        :return: Rect; return sprite rect
        """
        return self.rect

    def quit(self):
        """
        REMOVE THE SPRITE

        :return: void
        """
        self.kill()

    def distance_to_player(self, player_):
        """
        DISTANCE BETWEEN THIS ENEMY INSTANCE AND THE TARGET (PLAYER)

        * The distance is calculated from the center of each objects

        :param player_: instance; Target rect to use for the calculation
        :return: float; Return the cartesian distance between both objects
        """
        if not type(player_).__name__ == 'Player':
            raise ValueError("Argument player_ is not a Player instance got %s " % type(player_))

        if not hasattr(self, "position"):
            raise AttributeError("self missing attribute position ")

        return vector_length(player_.rect.centerx - self.position.x,
                             player_.rect.centery - self.position.y)

    def enemy_rotation(self):
        """
        AIMING DIRECTION
        THE AIRCRAFT IS ALWAYS FACING ITS TARGET INDEPENDENTLY OF ITS DIRECTION

        * Set the lock variable when the target is +/- 5 degrees
        from the aircraft aiming direction

        :return: void
        """

        cdef:
            float dx, dy
            int angle_deg, left, right

        target = self.targeted_player

        if target is None:
            return

        # CAP THE AIRCRAFT ANGLE TO RANGE [0 ... 360]
        self.spaceship_aim %= 360

        # AIM TOLERANCE +/- 5 DEGREES
        if PyObject_HasAttr(target, 'rect'):
            dy = target.rect.centery - self.rect.centery
            dx = target.rect.centerx - self.rect.centerx
            angle_deg = <int>(-<float>atan2(dy, dx) * <float>RAD_TO_DEG)

            # SET ANGLE WITHING [0 .. 360] DEGREES
            if angle_deg < 0:
                angle_deg = <unsigned int>360 - abs(angle_deg)

            left = (self.spaceship_aim - angle_deg) % <unsigned int>360
            right = <unsigned int>360 - left
            # FIND THE SHORTEST ANGULAR DISTANCE
            rotation_step = -self.enemy_.rotation_speed \
                if left < right else self.enemy_.rotation_speed

            # ANGLE TOLERANCE
            # THE ENEMY SPACESHIP WILL STOP ROTATING IF IN +/- 5 DEGREES
            # TOLERANCE ZONE.
            if angle_deg - <unsigned char>5 <= self.spaceship_aim <= angle_deg + <unsigned char>5:
                self.lock_on = True
            else:
                self.spaceship_aim += rotation_step
                self.lock_on = False

    def shooting_vector(self):
        """
        THIS METHOD RETURN THE ANGLE TO REACH THE TARGET AND THE
        NORMALIZED VECTOR (DIRECTION TO FOLLOW)

        * Angle (int) between the enemy and the target (player) range [0 ... 360]
        * Vector direction pointing toward the target (player), normalized

        :return: tuple angle (int) and normalized vector
        """
        cdef float dx, dy
        cdef float angle_deg
        if self.targeted_player is not None:
            dy = self.rect.centery - self.targeted_player.rect.centery
            dx = self.rect.centerx - self.targeted_player.rect.centerx
            angle_deg = (<int>(180.0 - <float>atan2(dy, dx) * <float>RAD_TO_DEG)
                         ) % <unsigned int>360
            dx, dy = normalized_vector(dx, dy)
            return angle_deg, -Vector2(dx, dy)
        else:
            return <int>270, Vector2(0, 1)

    def shot_accuracy(self):
        """
        DETERMINE THE SHOT ACCURACY

        * laser_accuracy value is in degrees and correspond to
        the maximum deviation at the highest range

        * The total deviation is relative to the distance between the
        aircraft and the target (player). The deviation is higher at long range
        and lower at short distance.

        :return: Angle (in degrees) and shooting vector (normalized)
        """

        if self.gl.screenrect.h == 0:
            raise ValueError("self.gl.screenrect height cannot be null ! ")

        if self.targeted_player is None:
            return <int>270, Vector2(<float>0.0, <float>1.0)

        cdef:
            float rate    = self.enemy_.laser_accuracy / self.gl.screenrect.h
            int deviation = <int>(rate * self.distance_to_player(self.targeted_player))
            int low_angle, high_angle, angle_deg
            float angle_rad

        # MAX SPREAD
        low_angle  = self.spaceship_aim - deviation
        high_angle = self.spaceship_aim + deviation

        if low_angle < high_angle:
            # THIS SHOT
            angle_deg = randRange(low_angle, high_angle)
        else:
            angle_deg = low_angle

        angle_rad = <float>(angle_deg * <float>DEG_TO_RAD)
        return <int>angle_deg, Vector2(<float>cos(angle_rad), -<float>sin(angle_rad))

    def laser_shot(self):
        """
        ENEMY SHOOTING ALL WEAPONS LASER(S) AND MISSILE(S)

        * Enemy can shoot only if the lock is True (enemy facing the target) and
        if the weapon is not reploading

        :return: void
        """

        if self.targeted_player is None:
            return

        targeted_player = self.targeted_player
        weapon_laser    = self.enemy_.laser
        weapon_missile  = self.enemy_.missile
        gl              = self.gl
        cdef int frame  = gl.FRAME
        cdef int angle
        cdef float distance = self.distance_to_player(targeted_player)

        # SHOOT ALL LASERS FROM THE ENEMY AIRCRAFT
        # THE LOCK IS SET ONLY IF THE TARGET IS IN RANGE (ENEMY FACING TARGET)
        if bool(self.gl.PLAYER_GROUP) and targeted_player is not None:

            if weapon_laser:

                if self.enemy_.category == 'friend':
                    self.lock_on = True

                if self.lock_on:
                    # ANGLE TOWARD TARGET (IN DEGREES) AND NORMALIZED VECTOR
                    angle, vector = self.shot_accuracy()

                    # ITERATE OVER EVERY MOUNTED WEAPONS
                    for laser_position, laser_type in weapon_laser.items():

                        if not laser_type.is_reloading(frame) \
                                and laser_type.range > distance:

                            laser_type.shooting(frame)
                            EnemyShot(
                                gl_            = gl,
                                containers_    = (gl.enemyshots, gl.All),
                                pos_           = eval(laser_position),
                                weapon_        = laser_type,
                                mute_          = False,
                                offset_        = laser_type.offset,
                                vector_        = vector,
                                angle_         = angle,
                                spaceship_aim_ = self.spaceship_aim * <float>DEG_TO_RAD,
                                rect_          = self.rect,
                                timing_        = 16, # 20
                                layer_         = -5)

                            gl.PAUSE_TIMER = 0

            # if weapon_missile:
            #
            #     for missile_position, missile in weapon_missile.items():
            #
            #         if not missile.is_reloading(frame) and \
            #                 missile.range >= distance:
            #
            #             extra = ExtraAttributes(
            #                 {'target': targeted_player,
            #                  'shoot_angle': 90,
            #                  'ignition': False,
            #                  'offset': (-30, 0)})
            #
            #             s = Homing(
            #                 gl_= gl,
            #                 group_= (gl.All, gl.enemy_group),
            #                 weapon_features_=WASP_FEATURES,
            #                 extra_attributes=extra,
            #                 timing_=800,
            #             )
            #
            #             missile.shooting(frame)
            #             gl.PAUSE_TIMER = 0

    def laser_shot_without_lock(self):
        """
        TARGET SHOOTING WITHOUT THE LOCK ON

        :return:
        """

        if self.targeted_player is None:
            return

        cdef int angle
        cdef float distance = self.distance_to_player(self.targeted_player)
        gl = self.gl
        frame = gl.FRAME
        enemy_laser = self.enemy_.laser

        if enemy_laser:

            # ANGLE (DEGREES) AND VECTOR DIRECTION (NORMALIZED)
            angle, vector = self.shooting_vector()

            # ITERATE OVER ALL WEAPONS
            for laser_position, laser_type in enemy_laser.items():

                if not laser_type.is_reloading(frame) and laser_type.range > distance:

                    if PyObject_HasAttr(laser_type, 'animation') \
                            and laser_type.animation is not None:

                        Follower(gl,
                                 gl.All,
                                 laser_type.animation.copy(),
                                 offset_    = None,
                                 timing_    = 20,
                                 loop_      = False,
                                 event_     = 'muzzle flash',
                                 object_    = self,
                                 layer_     = -2,
                                 vector_    = None,
                                 blend_     = 0)

                    EnemyShot(gl_           = gl,
                              containers_   = (gl.enemyshots, gl.All),
                              pos_          = eval(laser_position),
                              weapon_       = laser_type,
                              mute_         = False,
                              offset_       = laser_type.offset,
                              vector_       = vector,
                              angle_        = angle + 180,
                              spaceship_aim_= self.spaceship_aim * <float>DEG_TO_RAD,
                              rect_         = self.rect,
                              timing_       = 16, # 20
                              layer_        = -5)

                    laser_type.shooting(frame)
                    gl.PAUSE_TIMER = 0



    def explosion(self, bint mute_= False, int layer_=-1):
        """
        HANDLE AN ENEMY EXPLOSION, CREATE A SOUND EFFECT,
        UPDATE PLAYER SCORE AND START METHOD BONUS_ENERGY.

        :param mute_ : bool; Mute the sound if True
        :param layer_: int; Layer to use for the sprites
        :return: void
        """
        cdef:
            int w, h, r

        sound  = self.enemy_.explosion_sound
        gl     = self.gl
        rect   = self.rect
        cdef int rect_x = rect.centerx
        cdef int rect_y = rect.centery
        cdef int sound_len
        cdef bint collide

        if not mute_:
            if PyObject_IsInstance(sound, list):
                sound_len = len(sound)
                selected_sound = sound[randRange(0, sound_len - 1)]
            else:
                selected_sound = sound

            gl.SC_explosion.play(
                sound_      = selected_sound,
                loop_       = False,
                priority_   = 0,
                volume_     = gl.SOUND_LEVEL,
                fade_out_ms = 0,
                panning_    = True,
                name_       = 'GROUND_EXPLOSION', x_=rect_x, object_id_=self.enemy_.id)

        # Enemy aircraft
        if type(self).__name__ == 'Enemy':

            # EXPLOSION NOT FOLLOWING VECTOR SPEED
            if vector_length(self.vector.x, self.vector.y) > randRange(9, 12):

                Explosion1(gl,
                           gl.All,
                           self,
                           timing_  = 16,
                           layer_   = layer_,
                           vector_  = None,
                           blend_   = BLEND_RGB_ADD)

            # EXPLOSION FOLLOWING VECTOR SPEED
            # else:
            Explosion1(
                gl,
                gl.All,
                self,
                timing_=0,
                layer_=layer_,
                vector_=None,
                blend_=BLEND_RGB_ADD)

            w, h = self.image.get_size()

            im = scale(self.image, (64, 64))
            burst(
                gl,
                im,
                vertex_array_=VERTEX_ARRAY_SUBSURFACE,
                block_size_ = 4,
                rows_       = 16,
                columns_    = 16,
                x_          = rect.topleft[0],
                y_          = rect.topleft[1],
                max_angle_  = 359,
                type_       = 0)

            Halo(gl,
                 self.gl.All,
                 (HALO_SPRITE11, HALO_SPRITE12, HALO_SPRITE13, HALO_SPRITE14)[randRange(0, 3)],
                 rect_x,
                 rect_y
                 )

            for r in range(5):
                self.debris()

            BindSprite(
                group_      = gl.All,
                images_     = RADIAL,
                object_     = self,
                gl_         = gl,
                offset_     = None,
                timing_     = 15.0,
                layer_      = 0,
                loop_       = False,
                dependency_ = False,
                follow_     = False,
                event_      = 'FLASH',
                blend_      = BLEND_RGB_ADD)

        # GroundEnemyTurret or other type
        # Explosion and AE (after effects)
        else:

            # Explosion sprite animation
            Explosion1(
                gl,
                gl.All,
                self,
                timing_     = 16,
                layer_      = layer_,
                vector_     = self.vector,
                blend_      = BLEND_RGB_ADD
            )

            Follower(gl,
                     gl.All,
                     SMOKE,
                     offset_        = (rect_x, rect_y),
                     timing_        = 25,
                     loop_          = False,
                     event_         = 'SMOKE',
                     object_        = self,
                     layer_         = layer_ - 4,
                     blend_         = BLEND_RGB_ADD
                     )

            Halo(
                gl,
                gl.All,
                (HALO_SPRITE11, HALO_SPRITE12, HALO_SPRITE13)[randRange(0, 2)],
                rect_x,
                rect_y
            )

            # create debris / fragments flying around
            for r in range(5):
                self.debris()

            collide = False


            # Don't bother if too many instances
            if len(FOLLOWER_INVENTORY) < 100:

                # detect if two craters are adjacent
                for instance in FOLLOWER_INVENTORY:

                    if instance.event == 'CRATER':

                        if not instance.rect.colliderect(rect):
                            continue
                        else:
                            collide = True
                            break

            if not collide:

                Follower(gl,
                         gl.All,
                         (HOTFURNACE, HOTFURNACE2)[randRange(0, 1)],
                         offset_    = (rect_x, rect_y),
                         timing_    = 25,
                         loop_      = True,
                         event_     = 'HOTFURNACE',
                         object_    = self,
                         layer_     = layer_ - 4,
                         blend_     = BLEND_RGB_ADD)

        Score(gl, self.player_inflicting_damage).update(self.enemy_.score)

        if type(self).__name__ == "Enemy":
            if not bonus_energy(gl, self):
                if not bonus_bomb(gl, self):
                    if not bonus_life(gl, self):
                        bonus_ammo(gl, self)

            bonus_gems(gl, self, self.player_inflicting_damage, 5, 20, 50)

        self.quit()

    # TODO REMOVE ASSERTS AND HASATTR FOR RELEASE VERSION
    def blend(self, int damages):

        cdef float dam
        cdef short int bitsize

        if damages < 0:
            damages = 0

        if damages > self.enemy_.max_hp:
            damages = self.enemy_.max_hp

        if PyObject_HasAttr(self, 'enemy_'):

                if PyObject_HasAttr(self.enemy_, 'max_hp'):

                    if PyObject_HasAttr(self, 'images_copy'):

                        assert self.enemy_.max_hp != 0, " MAX_HP CANNOT BE EQUAL ZERO "
                        dam = damages / self.enemy_.max_hp

                        if dam > self.enemy_.max_hp:
                            dam = self.enemy_.max_hp

                        # IGNORE THE LIST
                        if not PyObject_IsInstance(self.images_copy, list):
                            bitsize = self.images_copy.get_bitsize()

                            ...

                            # if bitsize == 32:
                            #     # self.images_copy = blend_texture_32c(self.images_copy,
                            #     (255, 0, 25), 10)
                            #     self.images_copy = blend_to_textures_32c(self.images_copy,
                            #     self.lava_texture, 10)
                            #
                            # elif bitsize == 24:
                            #     # self.images_copy = blend_texture_24c(self.images_copy,
                            #     (255, 0, 0), 10)
                            #     self.images_copy = blend_to_textures_24c(self.images_copy,
                            #     self.lava_texture, 10)
                            #
                            # else:
                            #     return
                            #     # TEXTURE WITH 8 - BIT DEPTH COLOR CANNOT BE BLENDED


    def enemy_blast(self):

        cdef int r, l

        if PyObject_HasAttr(self, 'enemy_'):

            if PyObject_HasAttr(self.enemy_, 'disintegration_sprites'):

                if self.enemy_.disintegration_sprites is not None:

                    if id(self) not in BLAST_INVENTORY:

                        spr = self.enemy_.disintegration_sprites
                        gl  = self.gl
                        l   = len(spr) if isinstance(
                            self.enemy_.disintegration_sprites, list) else 1

                        for r in range(l):

                            Blast(group_    = gl.All,
                                  images_   = spr[r],
                                  gl_       = gl,
                                  object_   = self,
                                  timing_   = 16.67,
                                  blend_    = 0)

                            BLAST_INVENTORY.remove(id(self))


    # TODO REMOVE ASSERT FOR RELEASE VERSION
    def hit(self, player_, object_, weapon_, bint bomb_effect_=False, rect_center=None):
        """
        THIS METHOD IS USED AFTER DETECTING A COLLISION DETECTION (CollisionDetection.pyx)

        * if rect_center is None revert to player rect center position

        :param player_: class/instance; Player instance (player 1 or player 2)
        :param object_: class/instance; object receiving damages
        :param weapon_: class/instance; weapon type
        :param bomb_effect_: True | False if the weapon damage include a bomb effect
        :param rect_center: Rect; Pygame Rect to use for the damage position
        :return: void
        """
        assert type(player_).__name__  == 'Player', \
            "Argument player_ must be a Player instance got %s " % type(player_)

        cdef:
            gl         = self.gl
            screenrect = gl.screenrect
            int damage = 0
            float dist = get_distance(
                player_.rect.centerx, player_.rect.centery,
                object_.rect.centerx, object_.rect.centery)


        # INVINCIBLE OBJECT
        if PyObject_HasAttr(object_.enemy_, 'invincible') and object_.enemy_.invincible:
            return

        # PLAYER INSTANCE CAUSING DAMAGE TO OBJECT (TARGET)
        self.player_inflicting_damage = player_

        # DEFAULT REVERT TO THE OBJECT RECT POSITION
        if rect_center is None:
            if hasattr(object_, "rect"):
                rect_center = object_.rect
            else:
                raise AttributeError("Object has no attribute rect")

        if hasattr(object_, "rect"):
            obj_rect     = object_.rect
        else:
            raise AttributeError("Object has no attribute rect")

        if hasattr(object_, "enemy_"):
            obj_enemy    = object_.enemy_
        else:
            raise AttributeError("Object has no attribute enemy_")

        if hasattr(object_.enemy_, "weakness"):
            obj_weakness = obj_enemy.weakness
        else:
            raise AttributeError("Object has no attribute weakness ")

        if not hasattr(weapon_, 'damage'):
            raise AttributeError("weapon has not attribute damage")

        cdef int w_damage     = weapon_.damage
        cdef float p_damage


        # ONLY IF THE OBJECT IS WITHING THE GAME DISPLAY OTHERWISE DISREGARD
        if obj_rect.colliderect(screenrect):

            # BOMB EFFECT
            # DETERMINE THE AMOUNT OF DAMAGES
            # IN FUNCTION TO THE DISTANCE
            if bomb_effect_:
                damage = damage_radius_calculator(w_damage, 0.1E-1, dist)

                # SHIELD
                # NUKE DISRUPT THE SHIELD
                if weapon_.name != 'NUCLEAR_HALO':
                    if PyObject_HasAttr(obj_enemy, 'shield') and obj_enemy.shield is not None:
                        if object_.shield.is_shield_up():
                            object_.shield.force_shield_disruption()

                # NO SHIELD
                # DAMAGE THE HULL
                object_.hp -= damage
                if object_.hp < 0:
                    self.explosion()

                # SHOW THE DAMAGE
                DamageDisplay(gl.All, object_, damage, event_=None)

            # OTHER DAMAGES (MISSILES/LASERS/BEAM ETC)
            else:

                # SHIELD
                # CHECK IF THE FIGHTER HAS A SHIELD
                if PyObject_HasAttr(object_, 'shield') and object_.shield is not None:

                    # SHIELD
                    if object_.shield.is_shield_up():
                        pass

                        # MISSILES
                        # MISSILE WILL NEVER DESTROY AN ENEMY WITH A THE FIRST HIT,
                        # THE MISSILE WILL DISABLE THE SHIELD FIRST
                        if weapon_.name == 'STINGER_SINGLE':
                            object_.shield.force_shield_disruption()

                        # SHIELD IS STILL UP
                        # ANYTHING ELSE THAN MISSILES
                        else:
                            # PASS DAMAGE TO THE SHIELD
                            # WHEN DAMAGE IS GREATER THAN THE SHIELD ENERGY, PASS
                            # DAMAGE TO THE HULL
                            object_.shield.shield_impact(w_damage)

                            # GLOWING EFFECT (SHIELD ABSORBING DAMAGES)
                            if rect_center:
                                object_.shield.heat_glow(obj_rect.clip(rect_center))
                            else:
                                object_.shield.heat_glow(obj_rect)

                    # SHIELD IS DOWN
                    else:
                        damage = w_damage

                        # TODO NOT SURE ABOUT 0.5 to 1 + bonus
                        if obj_weakness is not None:
                            # BONUS APPLY
                            if weapon_.type_ in obj_weakness:
                                # BASE DAMAGE FRACTION (0.5 TO 1)  + BONUS
                                damage = randRange(round(0.5 * w_damage), w_damage) + \
                                         round(object_.weakness[weapon_.type_] * w_damage)


                        if weapon_.name != 'STINGER_SINGLE':
                            # LASER TYPE DAMAGE ARE PROPORTIONAL TO DISTANCE
                            if screenrect.h != 0:
                                p_damage = damage / screenrect.h
                            else:
                                p_damage = damage
                            damage = max(<int>(damage - p_damage * dist), 1)

                        if not hasattr(object_, "hp"):
                            raise AttributeError("object_ is missing attribute hp")
                        object_.hp -= damage
                        if object_.hp < 0:
                            self.explosion()

                        # SHOW IMPACT BURST (PARTICLES)
                        if weapon_.type_ not in ('BULLET', 'TESLA', 'BEAM', 'DEATHRAY'):
                            ImpactBurst(
                                gl,
                                gl.All,
                                object_,
                                images_     = None,
                                loop_       = False,
                                timing_     = 33,
                                layer_      = -2)

                        # SHOW BEAM IMPACT
                        else:
                            ImpactBurst(
                                gl,
                                gl.All,
                                object_,
                                BEAM[player_.name][2],
                                loop_       = False,
                                timing_     = 1,
                                layer_      = -2)

                # NO SHIELD
                else:
                    if obj_weakness:
                        # Weapon bonus apply
                        # +50%, +20% +15% more damage for specific weapons
                        if weapon_.type_ in obj_weakness:
                            # base damage fraction (0.5 to 1)  + bonus
                            damage = randRange(round(0.5 * w_damage), w_damage) + \
                                     round(object_.weakness[weapon_.type_] * w_damage)
                    # No bonus
                    else:
                        damage = w_damage

                    if weapon_.name != 'STINGER_SINGLE':
                        if screenrect.h != 0:
                            p_damage = damage / screenrect.h
                        else:
                            p_damage = damage
                        damage = max(<int>(damage - p_damage * dist), 1)

                    damage = w_damage
                    if not hasattr(object_, "hp"):
                        raise AttributeError("object_ is missing attribute hp")

                    object_.hp -= damage
                    if object_.hp < 0:
                        self.explosion()

                    object_.blend(damage)

                    # DISPLAY DAMAGES EXCEPT FOR TESLA EFFECT
                    if weapon_.type_ != 'TESLA':

                        DamageDisplay(
                            gl.All,
                            object_,
                            damage,
                            event_=None)

                    # DISPLAY BURST EXCEPT FOR 'BULLET', 'TESLA' AND 'BEAM' EFFECT
                    if weapon_.type_ not in ('BULLET', 'TESLA', 'BEAM'):

                        ImpactBurst(gl,
                                    gl.All,
                                    object_,
                                    images_ = None,
                                    loop_   = False,
                                    timing_ = 33,
                                    layer_  = -2)

                    # BEAM IMPACT BURST
                    else:
                        ImpactBurst(gl,
                                    gl.All,
                                    object_,
                                    BEAM[player_.name][2],
                                    loop_   = False,
                                    timing_ = 1,
                                    layer_  = -2)





@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
class Enemy(EnemyParentClass):

    """
    ENEMY CLASS

    This class inherit fromt the EnmeyParentClass

    """


    def __init__(self,
                 gl_,
                 images_,
                 enemy_,
                 int timing_    = 10,
                 int layer_     = -4):

        EnemyParentClass.__init__(self, gl_)

        self._layer = layer_
        self.enemy_ = enemy_

        self.initialized = False

        # PLAYER CAUSING DAMAGE TO THE ENEMY
        self.player_inflicting_damage = None

        # SELECT A PLAYER AT INIT TIME
        self.targeted_player = self.select_player()
        self.lock_on = False

        if isinstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        # LOAD THE PATH
        self.path = enemy_.path

        self.images_copy = images_.copy()
        self.image = self.images_copy[0] if isinstance(images_, list) \
            else self.images_copy

        # arr = numpy.array([0, 1,  # violet
        #                    0, 1,  # blue
        #                    0, 1,  # green
        #                    2, 619,  # yellow
        #                    620, 650,  # orange
        #                    651, 660],  # red
        #                   numpy.int)
        #
        # HEATMAP = [custom_map(i - 20, arr, 1.0) for i in range(380, 800)]
        #
        # # HEATMAP = [heatmap(i - 20, 1.0) for i in range(380, 800)]
        # heatmap_array = numpy.zeros((800 - 380, 3), uint8)
        # heatmap_rescale = numpy.zeros(255, numpy.uint)
        #
        # i = 0
        # for t in HEATMAP:
        #     heatmap_array[i, 0] = t[0]
        #     heatmap_array[i, 1] = t[1]
        #     heatmap_array[i, 2] = t[2]
        #     i += 1
        # for r in range(0, 255):
        #     s = int(r * (800.0 - 380.0) / 255)
        #     heatmap_rescale[r] = rgb_to_int(heatmap_array[s][0], heatmap_array[s][1], heatmap_array[s][2])
        #
        # self.heatmap_rescale = numpy.ascontiguousarray(heatmap_rescale[::-1])
        # w, h = self.image.get_size()
        # w2, h2 = w >> 1, h >> 1
        # self.lava_texture = scale(LAVA_TEXTURE, (w, h))
        # self.fire_array = numpy.zeros((h, w), dtype=numpy.float32)



        # CREATE A NUMPY ARRAY CONTAINING WAYPOINTS.
        # THIS IS A BEZIER CURVE THAT REPRESENT THE ENEMY PATH.
        # THE LIST IS BUILD WITH 100 COORDINATES (DEFAULT VALUE).
        # ACCURACY CAN BE CHANGED BY PASSING AN ARGUMENT TO THE FUNCTION BEZIER_CURVE,
        # E.G ENEMY.BEZIER_CURVE(SELF.PATH[:, 0], SELF.PATH[:, 1], N_TIMES_=50)
        # FOR 50 COORDINATES.
        self.waypoint_list = []

        # TODO MAY BE THE PATH CAN BE REVERSE WHEN CREATING IT
        # REVERSE THE WAYPOINT AND WORK FROM THE COPY
        # WORKING FROM PATH COPY IS ESSENTIAL TO AVOID CHANGING
        # THE PATH EACH TIME THE PLAYER IS RESTARTING A GAME. (PATH X RATIO)
        self.path = self.path[::-1].copy()

        # Adjust the enemy path to screen dimension from the path.copy()
        i = 0
        for x, y in self.path:
            self.path[i] = float(x * gl_.RATIO.x), float(y * gl_.RATIO.y)
            i += 1

        n = 60
        self.waypoint_list_ = Enemy.bezier_curve(self.path[:, 0], self.path[:, 1], n_times_=n)


        # OVERRIDE THE ACCELERATION VALUES TO MATCH THE REFINING OF THE BEZIER CURVE
        self.enemy_.acceleration = numpy.array([1 for r in range(n)])

        for r in list(zip(self.waypoint_list_[0], self.waypoint_list_[1])):
            self.waypoint_list.append(r)

        # SET THE DICTIONARY CONTAINING VECTORS AND ANGLES
        # ANGLE ARE INTEGER IN DEGREES AND VECTOR IS VECTOR2D NORMALIZED
        self.waypoint_dict = self.init_path(self.waypoint_list)

        self.rect = self.image.get_rect(center=(self.enemy_.pos.x * gl_.RATIO.x,
                                                self.enemy_.pos.y * gl_.RATIO.y))

        self.position = Vector2(self.enemy_.pos.x * gl_.RATIO.x,
                                            self.enemy_.pos.y * gl_.RATIO.y)

        if self.enemy_.strategy == 'PATH':

            # Calculate the last waypoint
            self.max_waypoint = len(self.waypoint_list)

            # Index on the first waypoint
            self.waypoint = 0
            # Waypoint_list coordinates are numpy_array format and
            # needs to be converted to vector2d to allow vector calculation
            # position is the vessel coordinates
            # self.position = Vector2(list(self.waypoint_list[0]))
            # Create vectors for vessel direction
            # Vessel speed and direction will be calculated
            # with two points from the Bezier curve.
            self.vector1 = Vector2()
            self.vector2 = Vector2()

            # vector is the vessel direction and speed
            self.vector = self.new_vector()

        else:
            # todo : need to implement other strategy
            self.max_waypoint = 2

            # Index on the first waypoint
            self.waypoint = 0

            # Create vectors for vessel direction
            # Vessel speed and direction will be calculated
            # with two points from the Bezier curve.
            self.vector1 = Vector2()
            self.vector2 = Vector2()

            # vector is the vessel direction and speed
            self.vector = self.new_vector()

        # how many degrees the sprite need to be rotated clockwise
        # in order to be oriented/align with a zero degree angle.
        self.spaceship_aim_offset = self.enemy_.sprite_orientation
        # aim angle right at the start
        self.spaceship_aim = -self.spaceship_aim_offset  # inverted to get the right angle

        if self.enemy_.strategy == 'PATH':
            # set the spaceship angle
            self.enemy_rotation_path()

        # timing constant
        self.dt = 0

        # enemy has a lock-on
        # Lock on is automatically set to True
        # when the enemy spaceship angle is in the tolerance
        # area of +/- 5 degrees (True trigger shots)
        self.lock_on = False

        # Enemy life points
        self.hp = self.enemy_.hp

        self.index = 0

        # ---   for compatibility with other class ---
        self.explosion_sprites = enemy_.explosion_sprites
        self.impact_sprite = enemy_.impact_sprite
        self.impact_sound = enemy_.impact_sound
        self.damage = enemy_.collision_damage

        self.evasive = False
        self.timing = timing_

        # FOR BLENDING

        # self._blend = pygame.BLEND_RGB_ADD

    def acceleration(self, vector: Vector2):
        return vector * self.enemy_.acceleration[self.waypoint]

    def init_path(self, waypoint_list_):
        """
        ITERATE OVER ALL THE WAYPOINTS AND DEFINE THE EQUIVALENT NORMALIZED VECTOR, ANGLE(INT)
        AND POSITION, THEN AND SAVE IT INTO A PYTHON DICT
        
        :param waypoint_list_: The list of waypoints
        :return: Return the dictionary containing vectors and angles
        """

        cdef list dx_list = []
        cdef list dx_ = []
        cdef int l, angle

        l = len(waypoint_list_)
        for r in range(l):
            point =  waypoint_list_[r]
            dx_list.append(Vector2(point[0], point[1]))

        cdef dict waypoint_dict = {}
        for r in range(l - 1):
            current_waypoint = dx_list[r]
            next_waypoint    = dx_list[r+1]
            v                = next_waypoint - current_waypoint
            vec              = Vector2(normalized_vector(v.x, v.y))
            angle            = (<int>(-<float>atan2(vec.y, vec.x) * <float>RAD_TO_DEG) + 360) % 360
            # ! -v.y INVERSE Y
            waypoint_dict[r] = [Vector2(vec.x, vec.y), angle, current_waypoint]

        return waypoint_dict






    @property
    def waypoint(self):
        return self.__waypoint

    @waypoint.setter
    def waypoint(self, waypoint):
        if waypoint >= self.max_waypoint - 1:
            self.__waypoint = 0
            # Aircraft stopped
            self.vector.x, self.vector.y = (0, 0)
            self.evasive = False
        else:
            self.__waypoint = waypoint

    # def __next__(self) -> list:
    #     # Return the next waypoint from the
    #     # the Bezier curve.
    #     # Loop back to index 0 when the end of
    #     # the list is reached.
    #     try:
    #         item = self.waypoint_list[self.waypoint]
    #     except IndexError:
    #         self.waypoint = 0
    #         self.vector.x, self.vector.y = (0, 0)
    #         item = self.waypoint_list[0]
    #
    #     self.waypoint += 1
    #     return item


    def is_waypoint_passed(self):
        """
        THIS METHOD CHECKS IF THE ENEMY SPACESHIP IS COLLIDING WITH ONE OF THE MANY
        WAYPOINT FROM THE BEZIER CURVE (POINT ARE REPRESENTED BY HIDDEN RECTANGLE).

        :return: void
        """

        # CREATE A DUMMY RECTANGLE PLACED IN THE CENTER
        rect  = Rect(self.rect.centerx - 30, self.rect.centery - 30, 60, 60)

        # SET THE SPRITE IMAGE ORIENTATION
        if self.enemy_.angle_follow_path:
            # KEEP AIRCRAFT AIMING TOWARD THE PATH DIRECTION AND SET THE LOCK TRUE | FALSE
            self.enemy_rotation_path()

        else:
            # AIMING TOWARD THE PLAYER (IF ANY) FOLLOWING THE PATH
            # AND SET THE LOCK TRUE | FALSE
            if bool(self.gl.PLAYER_GROUP) and self.targeted_player is not None:
                self.enemy_rotation()

        cdef point = self.waypoint_dict[self.waypoint][2]
        waypoint_rect = Rect(point[0] - 30, point[1] - 30, 60, 60)

        # CHECK IF RECT COLLIDE WITH WAYPOINT
        if rect.colliderect(waypoint_rect):

            if self.waypoint < self.max_waypoint:
                # NEXT DIRECTION VECTOR CALCULATION
                self.vector = self.new_vector()
                self.waypoint += 1
        else:
            pass

    def tracking_vector(self):
        """

        :return:
        """

        # TODO REMOVE CHECKS FOR RELEASE VERSION
        if not PyObject_HasAttr(self, "vector1"):
            raise AttributeError("Object is missing attribute vector1")

        if not PyObject_HasAttr(self, "waypoint"):
            raise AttributeError("Object is missing attribute waypoint")

        if not PyObject_HasAttr(self, "waypoint_list"):
            raise AttributeError("Object is missing attribute waypoint_list")

        if not PyObject_HasAttr(self, "enemy_"):
            raise AttributeError("Object is missing attribute enemy_")

        if not PyObject_HasAttr(self.enemy_, "speed"):
            raise AttributeError("Object is missing attribute enemy_.speed")

        if not isinstance(self.enemy_.speed, Vector2):
            raise ValueError("Argument enemy_.speed is not a Vector2 type got %s "
                             % type(self.enemy_.speed))

        # CURRENT AIRCRAFT COORDINATES
        self.vector1.x, self.vector1.y = self.rect.center

        # LOAD ACTIVE WAYPOINT (DESTINATION)
        self.vector2 = Vector2(self.waypoint_dict[self.waypoint][2])

        vector = Vector2(self.vector2 - self.vector1)

        cdef float v_len, speed

        speed  = <float>vector_length(self.enemy_.speed.x, self.enemy_.speed.y)
        v_norm = Vector2(normalized_vector(vector.x, vector.y))
        v_len  = <float>vector_length(v_norm.x, v_norm.y)

        if v_len != 0:
            return v_norm * speed / v_len
        else:
            return vector

    def new_vector(self):

        # TODO REMOVE CHECK FOR RELEASE VERSION
        if not PyObject_HasAttr(self, "vector1"):
            raise AttributeError("Object is missing attribute vector1")

        if not PyObject_HasAttr(self, "waypoint"):
            raise AttributeError("Object is missing attribute waypoint")

        if not PyObject_HasAttr(self, "waypoint_list"):
            raise AttributeError("Object is missing attribute waypoint_list")

        if not PyObject_HasAttr(self, "enemy_"):
            raise AttributeError("Object is missing attribute enemy_")

        if not PyObject_HasAttr(self.enemy_, "speed"):
            raise AttributeError("Object is missing attribute enemy_.speed")

        if not isinstance(self.enemy_.speed, Vector2):
            raise ValueError("Argument enemy_.speed is not a Vector2 type got %s "
                             % type(self.enemy_.speed))

        if not PyObject_HasAttr(self.enemy_, "acceleration"):
            raise AttributeError("Object is missing attribute enemy_.acceleration")

        # CURRENT COORDINATES (ENEMY POSITION)
        self.vector1 = Vector2(self.rect.centerx, self.rect.centery)

        # ENEMY CONSTANT SPEED
        cdef float speed = <float> vector_length(self.enemy_.speed.x, self.enemy_.speed.y)

        if self.waypoint < self.max_waypoint - 2:
            # LOAD THE NEXT WAYPOINT (POSITION OF THE NEXT RECT)
            waypoint = self.waypoint_dict[self.waypoint + 1]
            self.vector2 = Vector2(waypoint[2])
        else:
            # # USE THE LAST VECTOR DIRECTION * SPEED
            last_vector = self.waypoint_dict[self.max_waypoint - 2]
            return Vector2(last_vector[2]) * speed


        cdef float v_len, acceleration

        # DETERMINE THE DIRECT VECTOR TOWARD THE NEW RECT POSITION
        vector       = self.vector2 - self.vector1
        v_norm       = Vector2(normalized_vector(vector.x, vector.y))
        v_len        = vector_length(v_norm.x, v_norm.y)

        if v_len != 0:
            if PyObject_HasAttr(self.enemy_, "acceleration"):
                acceleration = <float> self.enemy_.acceleration[self.waypoint]
                return v_norm * speed * acceleration
            else:
                return v_norm * speed
        else:
            # TODO CHECK WAYPOINT + 1
            self.waypoint += 1
            return vector

    @staticmethod
    def fact(int n):
        cdef int r
        for r in range(1, n):
            n *= r
        return <int>n

    @staticmethod
    def comb_(int n, int k):
        cdef int l
        if k > n:
            return 0
        l = <int>(Enemy.fact(k) * Enemy.fact(n - k))
        if l!=0:
            return <int>(Enemy.fact(n)) / l
        else:
            return 1

    @staticmethod
    def bernstein_poly(int index, int n, np.ndarray[np.float32_t, ndim=1] t):
        return Enemy.comb_(n, index) * (t ** (n - index)) * (1 - t) ** index

    @staticmethod
    def bezier_curve(np.ndarray[np.int32_t, ndim=1] x_points,
                     np.ndarray[np.int32_t, ndim=1] y_points,
                     int n_times_= 30):

        cdef:
            int n_points = len(x_points)
            np.ndarray[np.float32_t, ndim=1] t = numpy.linspace(
            0.0, 1.0, n_times_, dtype=numpy.float32)
            int i
            np.ndarray[np.float32_t, ndim=2] polynomial_array = \
            numpy.array([Enemy.bernstein_poly(i, n_points - 1, t) for i in range(0, n_points)])
        new_array = numpy.dot([x_points, y_points], polynomial_array).astype(dtype=numpy.int16)
        return new_array

    def enemy_rotation_path(self):
        """
        ADJUST THE AIMING DIRECTION ACCORDING TO THE VECTOR DIRECTION
        SET THE LOCK STATUS TRUE | FALSE

        * Adjust the aircraft aiming direction
        * lock is True when the aircraft angle is within the enemy fov tolerance
        * lock is always True if no player are alive

        :return: void
        """

        cdef float angle_rad
        cdef int predicted_angle_deg, target_angle, diff_angle, angle_deg
        cdef float dx, dy

        # TODO REMOVE FOR RELEASE VERSION
        if not PyObject_HasAttr(self, 'vector'):
            raise AttributeError("Object missing attribute vector")

        # PREDICTED ANGLE
        # predicted_angle_deg = self.waypoint_dict[self.waypoint][1]

        angle_rad = -<float>atan2(self.vector.y, self.vector.x)
        angle_deg = (<int>(angle_rad * <float>RAD_TO_DEG) + 360) % 360

        self.spaceship_aim = angle_deg

        # SET TO FALSE EXCEPT TOLD OTHERWISE
        self.lock_on = False

        if self.targeted_player is not None:
            player_rect = self.targeted_player.rect
            dy = player_rect.centery - self.rect.centery
            dx = player_rect.centerx - self.rect.centerx
            target_angle = (<int>(-<float>atan2(dy, dx) * <float>RAD_TO_DEG)) % 360

            diff_angle = target_angle - angle_deg
            # ALLOW THE LOCK ON|OFF TRIGGERING THE AIRCRAFT FIRING
            if diff_angle <= (self.enemy_.fov >> 1):
                self.lock_on = True
        else:
            self.lock_on = True

    def kamikaze(self):
        """
        RETURN A VECTOR DIRECTION FOR THE KAMIKAZE ENEMY

        * If tno player are alive, return a vetector direction toward the mid bottom of the screen
          otherwise return a collision vector to the player location

        :return:
        """

        if PyObject_HasAttr(self.enemy_, "speed"):
            if PyObject_IsInstance(self.enemy_.speed, tuple):
                self.enemy_.speed = Vector2(self.enemy_.speed)
        else:
            raise AttributeError("Object is missing the attribute speed")

        gl_screenrect    = self.gl.screenrect

        cdef float speed =  vector_length(self.enemy_.speed.x, self.enemy_.speed.y)
        cdef float v_len


        # CURRENT AIRCRAFT COORDINATES
        self.vector1.x, self.vector1.y = self.rect.center

        # TRAJECTORY
        vector2 = Vector2()

        if self.targeted_player is None:
            vector2.x = gl_screenrect.midbottom[0]
            vector2.y = gl_screenrect.midbottom[1]
        else:
            target_rect = self.targeted_player.rect
            vector2.x = target_rect.centerx
            vector2.y = target_rect.centery

        # DIRECTION VECTOR
        vector = vector2 - self.vector1
        v_norm = Vector2(normalized_vector(vector.x, vector.y))
        v_len  = vector_length(v_norm.x, v_norm.y)

        if v_len !=0:
            return v_norm * speed / v_len
        else:
            return vector

    def update(self):

        gl = self.gl
        if self.hp < 0:
            self.explosion()

        if self.dt > self.timing:


            index = self.index
            # Trigger enemy according to FRAME number
            if not self.initialized:
                if gl.FRAME < self.enemy_.spawn:
                    return
                else:
                    self.initialized = True

                    # INSTANTIATE THE SHIELD IF ANY
                    if self.enemy_.shield:
                        self.shield = EnemyShield(
                            gl_             = gl,
                            containers_     = gl.All,
                            images_         = self.enemy_.shield.sprite,
                            object_         = self,
                            loop_           = True,
                            timing_         = self.timing,
                            event_          = 'SHIELD_INIT',
                            shield_type     = self.enemy_.shield
                        )

            if self.alive() and self.rect.colliderect(gl.screenrect):

                # SELECT A PLAYER FOR TARGETING
                if self.targeted_player is not None:
                    if not self.targeted_player.alive():
                        self.targeted_player = self.select_player()
                else:
                    self.targeted_player = self.select_player()

                # update sprite position
                self.position   += self.vector if not \
                    isinstance(self.vector, type(None)) else (0, 0)
                self.rect.center = self.position

                if self.enemy_.invincible:
                    self.laser_shot()

                else:
                    if gl.FRAME > self.enemy_.spawn :
                        self.laser_shot()

                if isinstance(self.images_copy, list):
                    self.image, self.rect = self.rot_center(
                        self.images_copy[index],
                        self.spaceship_aim + self.spaceship_aim_offset,
                        self.rect)
                    if index < len(self.images_copy) - 1:
                        self.index += 1
                    else:
                        self.index = 0

                else:
                    self.image, self.rect = self.rot_center\
                        (self.images_copy,
                         self.spaceship_aim + self.spaceship_aim_offset,
                         self.rect)

                if self.enemy_.strategy == 'PATH':
                    self.is_waypoint_passed()

                # KAMIKAZE STRATEGY
                elif self.enemy_.strategy == 'KAMIKAZE' and not self.enemy_.kamikaze_lock:
                    self.vector = self.kamikaze()
                    self.enemy_rotation_path()
                    self.enemy_.kamikaze_lock = True

            # BELOW control sprite behavior outside SCREENRECT
            else:
                if self.waypoint > 1:
                    self.quit()
                else:
                    # kill the KAMIKAZE when outside the SCREENRECT ONLY IF TRIGGERED
                    # self.enemy_.kamikaze_lock is True
                    if self.enemy_.kamikaze_lock is True:
                        self.quit()
                    self.vector = self.tracking_vector()
                    self.position += self.vector if not isinstance(
                        self.vector, type(None)) else (0, 0)
                    self.rect.center = self.position
                    self.enemy_rotation_path()

            self.dt = 0

        self.dt += gl.TIME_PASSED_SECONDS
