#cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=False, optimize.use_switch=True, profile=False
from random import randint

import numpy
from numpy import array

from Halo import Halo
from Sounds import SD_LASER_LARGE_ALT_03, IMPACT1
from Textures import BLURRY_WATER1, G5V200_LASER_FX074, G5V200_FX074_ROTATE_BUFFER, \
    G5V200_LASER_FX086, \
    G5V200_FX086_ROTATE_BUFFER, STATION_BUFFER, STATION_LASER_LZRFX029, \
    STATION_LASER_LZRFX029_ROTATE_BUFFER, \
    HALO_SPRITE_G5V200, STATION_IMPULSE

from hsv_surface cimport hsv_surface24c

try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject, PyObject_HasAttr, PyObject_IsInstance, \
        PyObject_CallFunctionObjArgs
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size, PyList_SetItem
    from cpython.dict cimport PyDict_Values, PyDict_Keys, PyDict_Items, PyDict_GetItem, \
        PyDict_SetItem, PyDict_Copy
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

try:
    import pygame
    from pygame.math import Vector2
    from pygame import Rect, BLEND_RGB_ADD, HWACCEL, BLEND_RGB_MAX, BLEND_RGB_MULT,\
        transform, BLEND_RGB_SUB
    from pygame import Surface, SRCALPHA, mask, event, RLEACCEL
    from pygame.transform import rotate, scale, smoothscale, rotozoom
except ImportError as e:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:
   from Sprites cimport Sprite, collide_mask, spritecollideany, LayeredUpdates, \
       collide_rect, collide_rect_ratio
   from Sprites import Group
except ImportError:
    raise ImportError("\nSprites.pyd missing!.Build the project first.")

from libc.math cimport cos, exp, sin, atan2, hypot, atan, copysign, sqrt, round
from EnemyShot import select_player

cdef extern from 'Include/vector.c':

    struct c_tuple:
        int primary;
        int secondary;

    struct vector2d:
       float x;
       float y;

    cdef float M_PI;
    cdef float M_PI2;
    cdef float M_2PI;
    cdef float RAD_TO_DEG;
    cdef float DEG_TO_RAD;
    void vecinit(vector2d *v, float x, float y)nogil
    float vlength(vector2d *v)nogil
    void subv_inplace(vector2d *v1, vector2d v2)nogil
    vector2d subcomponents(vector2d v1, vector2d v2)nogil
    void scale_inplace(float c, vector2d *v)nogil
    float randRangeFloat(float lower, float upper)nogil
    int randRange(int lower, int upper)nogil

STATION_VERTEX_BULLET_HELL  = []
# BULLET FREQUENCY/PATTERN
cdef long int [::1] PATTERNS = array([10, 11, 12, 15,  16, 17, 18, 22, 24, 33], dtype=int)
cdef unsigned int PATTERN_LENGTH = len(PATTERNS) - 1



# CONVENIENT HOOK TO DISPLAY THE BULLETS FROM THE MAIN PROGRAM
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef station_loop_display_bullets(gl_):
    station_display_bullets(gl_)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef void station_display_bullets(gl):
    """
    DISPLAY(DRAW) BULLETS 

    This method can be call from the main loop of your program or 
    in the update method of your sprite class. 
    To avoid a flickering effect between video flips, make sure
    to call this method every ticks.

    VERTEX_BULLET_HELL is a vertex array (python list) containing 
    all the bullets to be processed. 
    Bullets are dictionaries entity, not pygame sprites. 
    The above statement imply the following:
    1 - When a bullet is outside your game display, the function remove 
        will be called to erase the bullet.. not kill(). 
    2 - Make sure to call this function last and before flipping your display (no layer attributes)    

    e.g calling this method before drawing the background will place all the bullets 
    behind the background.

    Note: The game maximum FPS (default 60 FPS) is automatically dealt with pygame function
    in the main loop of your program. 
    If the value maximum FPS is changed to 800 for example, this would have an effect 
    on the bullets speed since the bullet velocity was computed for 60 FPS.  
    :return: None
    """

    cdef:
        screenrect  = gl.screenrect
        vertex_remove = STATION_VERTEX_BULLET_HELL.remove

    global STATION_VERTEX_BULLET_HELL

    for spr in STATION_VERTEX_BULLET_HELL:

        # BULLET OUTSIDE DISPLAY ?
        if screenrect.contains(spr.rect):

            spr.center.x += spr.vec.x
            spr.center.y += spr.vec.y
            spr.rect.centerx = spr.center.x
            spr.rect.centery = spr.center.y

        else:
            if spr in STATION_VERTEX_BULLET_HELL:
                vertex_remove(spr)
                spr.kill()




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

# ---- THESE ARE DUPLICATE METHODS (SEE EnemyShot.pyx)
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

    cdef float vx_norm = vx / v_length
    cdef float vy_norm = vy / v_length
    return vx_norm, vy_norm

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
class EnemyClass:
    def __init__(self):
        self.category   = "boss"
        self.invincible = False
        self.name       = "STATION"
        self.id         = id(self)
        self.mass       = 10


DUMMY_CLASS = EnemyClass()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Station(Sprite):

    # todo CDEF variable

    cdef:
        int pattern_index,
        public int _layer, _blend
        public object rect, image, vector

    def __init__(self,
                 gl_,
                 weapon1_,
                 weapon2_,
                 attributes_,
                 group_,
                 surface_,
                 pos_x,
                 pos_y,
                 blend_,
                 layer_,
                 float timing_=16.0):

        Sprite.__init__(self, group_)

        self._layer = layer_
        self.gl = gl_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        if PyObject_IsInstance(surface_, list):
            self.image = <object> PyList_GetItem(surface_, 0)
            self.length1 = PyList_Size(surface_) - 1
        else:
            self.image = surface_

        self.image_copy = surface_.copy()
        self.rect       = self.image.get_rect(center=(pos_x, pos_y))
        self.dt         = 0
        self.index      = 0
        self.timing     = timing_
        self._blend     = blend_
        self.mask       = pygame.mask.from_surface(self.image)

        # FLAG RAISED WHEN SHIP IS EXPLODING
        self.destruction_status = False
        self.destruction_timer = 0

        # FLAG RAISED WHEN SHIP IS DISRUPTED
        self.disruption_status = False
        self.disruption_index = 0

        self._rotation = 0.0
        self.rotation_speed = 1.0

        self.weapon1 = weapon1_
        self.weapon2 = weapon2_
        self.bullet_hell_ring_reload = \
            <object> PyDict_GetItem(weapon1_, 'reloading_time')  # 1.5 seconds
        self.ring_count_down = \
            <object> PyDict_GetItem(weapon1_, 'reload_countdown')
        self.fx074_damage = <object> PyDict_GetItem(weapon1_, 'damage')

        self.bullet_hell_reload = \
            <object> PyDict_GetItem(weapon2_, 'reloading_time')
        self.bullet_count_down = \
            <object> PyDict_GetItem(weapon2_, 'reload_countdown')
        self.fx086_damage = <object> PyDict_GetItem(weapon2_, 'damage')

        # TIME IN BETWEEN PATTERNS 10 secs
        # PATTERN IS A LIST CONTAINING DIFFERENT ANGLE IN BETWEEN SHOTS
        self.pattern_countdown = 200  # 10k ms correspond to 10 secs
        self.pattern_index = 0

        # LOAD FIRST PATTERN
        self.bullet_hell_angle = PATTERNS[0]
        self.shooting_angle_FX086 = 0


        # PLAYER CAUSING DAMAGE TO THIS INSTANCE
        self.player_inflicting_damage = None

        # SELECT A PLAYER AT INIT TIME
        self.targeted_player = select_player(gl_)

        # ADD EXTRA ATTRIBUTES FROM XML FILE G5V200.xml
        self.hp          = <object> PyDict_GetItem(attributes_, 'life')
        self.max_hp      = <object> PyDict_GetItem(attributes_, 'max_life')
        self.strategy    = <object> PyDict_GetItem(attributes_, 'strategy')
        self.score       = <object> PyDict_GetItem(attributes_, 'score')
        self.path        = <object> PyDict_GetItem(attributes_, 'path')
        self.damage      = <object> PyDict_GetItem(attributes_, 'damage')  # COLLISION DAMAGE
        self.path        = self.path[::-1]
        self.start_frame = <object> PyDict_GetItem(attributes_, 'start_frame')

        # IMPACT SOUND (PLAYER HITS THE BOSS)
        self.impact_sound = IMPACT1
        self.enemy_ = DUMMY_CLASS

        self.position = Vector2(<float>self.rect.centerx, <float>self.rect.centery)
        self.speed    = Vector2(<float>gl_.bv.x, <float>gl_.bv.y)

        self.vector = self.speed

        # COUNTDOWN, AFTER 200 FRAMES THE STATION
        # STARTING TO ROTATE ON ITSELF GAINING SPEED AND
        # TRIGGERING AN IMPULSE EFFECT THAT WILL DEACTIVATE THE
        # PLAYER SHIELD. THE IMPULSE EFFECT IS A WHITE HALO OF ENERGY
        # MOVING IN EVERY DIRECTION.
        # MAX_ROTATION_SPEED IS THE MAXIMUM SPEED AT THE TIME OF THE
        # IMPULSE EFFECT.
        # AFTER THE IMPULSE EFFECT THE STATION ROTATION SPEED WIL SLOWLY
        # DECELERATE AN THE COUNTDOWN WILL START OVER AGAIN.
        # DURING THE IMPULSE EFFECT THE TIME WILL SLOW DOWN AND A SCREEN
        # FILTER WILL BE ADDED

        self.rotation_counter = 200
        self.max_rotation_speed = 20   # in degrees
        self.rotation_status  = 1      # 1 accelerate, 2 decelerate


    cdef tuple rot_center(self, image_, float angle_, int x, int y):
        """
        ROTATE THE ENEMY SPACESHIP IMAGE  

        :param y     : integer; x coordinate (rect center value) 
        :param x     : integer; y coordinate (rect center value)
        :param image_: pygame.Surface; Surface to rotate
        :param angle_: integer; Angle in degrees 
        :return: Return a tuple (surface, rect)
        """
        cdef int width  = image_.get_width()
        cdef int height = image_.get_height()
        cdef int w2, h2

        w2 = width >> 1
        h2 = height >> 1

        image_rescale = smoothscale(image_, (w2, h2))

        new_image = rotozoom(image_rescale, angle_, 1.0)
        new_image = smoothscale(new_image, (width, height))

        return new_image, new_image.get_rect(center=(x, y))

    cpdef location(self):
        """
        RETURN SPRITE RECT
        :return: Return the sprite rect (keep compatibility with other class)
        """
        return self.rect

    cdef float get_distance(self, vector2d v1, vector2d v2)nogil:
        """
        RETURN EUCLIDEAN DISTANCE BETWEEN TWO OBJECTS (v2 - v1)

        :param v1: vector2d; Vector 1 (Center of object 1)
        :param v2: vector2d; Vector 2 (Center of object 2)
        :return  : float; Vector length (Distance between two objects)
        """
        subv_inplace(&v2, v1)
        return vlength(&v2)

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

        return vector_length(player_.rect.centerx - self.rect.centerx,
                             player_.rect.centery - self.rect.centery)

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
        assert type(player_).__name__ == 'Player', \
            "Argument player_ must be a Player instance got %s " % type(player_)

        cdef:
            gl = self.gl
            screenrect = gl.screenrect
            int damage = 0
            float dist = get_distance(
                player_.rect.centerx, player_.rect.centery,
                object_.rect.centerx, object_.rect.centery)


        # INVINCIBLE OBJECT
        if PyObject_HasAttr(object_, 'enemy_'):
            if PyObject_HasAttr(object_.enemy_, 'invincible') and object_.enemy_.invincible:
                return

        # PLAYER INSTANCE CAUSING DAMAGE TO OBJECT (TARGET)
        self.player_inflicting_damage = player_

        # DEFAULT REVERT TO THE OBJECT RECT POSITION
        if rect_center is None:
            rect_center = object_.rect

        obj_rect = object_.rect

        if hasattr(weapon_, 'damage'):
            self.hp -= weapon_.damage
            if self.hp <= 0:
                self.destruction_status = True
                self.hp = 0

        # if self.blf is not None:
        #     self.blf.life_update(self.hp)

    cdef disruption_effect(self, image_):
        """
        APPLY A TEXTURE TO SELF.IMAGE (SPACESHIP DISRUPTION EFFECT)
        :return: pygame.Surface
        """
        cdef int length = <object> PyList_Size(BLURRY_WATER1) - 1
        disruption_layer_effect = <object> PyList_GetItem(BLURRY_WATER1,
                                                          self.disruption_index % length)
        image_.blit(disruption_layer_effect, (0, 0), special_flags=BLEND_RGB_ADD)
        self.disruption_index += 1
        return image_

    cdef void disruption_effect_stop(self):
        """
        STOP THE DISRUPTION EFFECT 
        :return: None
        """
        self.disruption_index = 0

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(False)
    cdef void create_bullet_hell_ring(self, bint disruption_or_destruction,
                                      int layer_, int damage_):
        """
        CREATE BULLET RING (BULLET HELL)

        This method create bullets and put them into a vertex array VERTEX_BULLET_HELL

        :param : disruption_or_destruction: bool; Boolean value True if ship
         is exploding or disrupted
        :param : integer; layer_
        :param : integer; damage_
        :return: None
        """
        if disruption_or_destruction:
            return

        # NOTE 36 BULLETS CAN BE CREATED BEFORE THE MAIN LOOP
        # ONLY RECTS AND POSITION ATTRIBUTES HAVE TO BE UPDATE.
        # SEE METHOD ADD_BULLET FOR AN IMPLEMENTATION EXAMPLE.
        cdef:
            # COVER 0 - 360 degrees
            int shooting_range = 36
            gl                 = self.gl
            float velocity     = (<object> PyDict_GetItem(self.weapon1, 'velocity')).length()
            float cs           = 50.0
            float rad_angle, offset_x, offset_y, rad_angle_
            int rect_x         = self.rect.centerx
            int rect_y         = self.rect.centery
            image              = STATION_LASER_LZRFX029
            list FX074         = STATION_LASER_LZRFX029_ROTATE_BUFFER
            int r
            int rotation       = self._rotation
            vertex_append      = STATION_VERTEX_BULLET_HELL.append
            gl_enemy_add       = gl.enemyshots.add
            gl_all_add         = gl.All.add


        rad_angle_ = DEG_TO_RAD * rotation
        position = Vector2(rect_x, rect_y)

        cdef gl_all = gl.All
        # CREATE 36 BULLETS
        self.shooting_angle_FX074 = 0

        if 0 < rect_x < gl.screenrect.w:
            self.gl.SC_explosion.play(
                sound_      =SD_LASER_LARGE_ALT_03,
                loop_       =False,
                priority_   =2,
                volume_     =gl.SOUND_LEVEL,
                fade_out_ms =0,
                panning_    =True,
                name_       ='HELL_RING',
                x_          =rect_x)

        for r in range(shooting_range):
            spr = Sprite()

            gl_all_add(spr)

            if PyObject_IsInstance(gl_all, LayeredUpdates):
                gl_all.change_layer(spr, layer_)

            rad_angle = (r * 10) * DEG_TO_RAD
            spr.image = <object> PyList_GetItem(FX074, (r * 10))
            spr.rect = spr.image.get_rect(center=(position.x, position.y))
            spr.vec = Vector2(<float> cos(rad_angle) * velocity, -<float> sin(rad_angle) * velocity)
            spr._blend = BLEND_RGB_ADD
            spr._layer = layer_
            spr.center = Vector2(position.x, position.y)
            spr.damage = damage_
            spr.name = "FX074"
            gl_enemy_add(spr)
            vertex_append(spr)

    cdef bint is_bullet_ring_reloading(self):
        """
        CHECK IF A WEAPON IS RELOADED AND READY.

        Returns True when the weapon is ready to shoot else return False
        :return: bool; True | False
        """

        if self.ring_count_down <= 0:
            # RESET THE COUNTER
            self.ring_count_down = self.bullet_hell_ring_reload
            # READY TO SHOOT
            return True
        else:
            # DECREMENT COUNT DOWN VALUE WITH LATEST DT (DIFFERENTIAL TIME) VALUE
            self.ring_count_down -= self.gl.TIME_PASSED_SECONDS
            # RELOADING
            return False

    cdef bint is_bullet_reloading(self):
        """
        CHECK IF A WEAPON IS RELOADED AND READY.
        Returns True when the weapon is ready to shoot else return False
        :return: bool; True | False
        """
        if self.bullet_count_down <= 0:
            # RESET THE COUNTER
            self.bullet_count_down = self.bullet_hell_reload
            # READY TO SHOOT
            return True
        else:
            # DECREMENT COUNT DOWN VALUE WITH LATEST DT (DIFFERENTIAL TIME) VALUE
            self.bullet_count_down -= self.gl.TIME_PASSED_SECONDS
            # RELOADING
            return False

    cdef void create_bullet_hell(self, bint disruption_or_destruction, int layer_,
                                 int damage_, int offset_=0):
        """
        CREATE BULLET HELL

        One the bullet has been pushed into the vertex array, the method display_bullets 
        will take over and update all the bullets positions at once on your display.

        :return: None
        """
        if disruption_or_destruction:
            return

        cdef:
            float rad_angle, offset_x, offset_y
            int deg_angle   = 0
            gl              = self.gl
            gl_all          = gl.All
            float velocity  = Vector2(self.weapon2['velocity'], self.weapon2['velocity']).length()
            int rect_x      = self.rect.centerx
            int rect_y      = self.rect.centery
            image           = STATION_LASER_LZRFX029  # not defined yet
            list FX086      = STATION_LASER_LZRFX029_ROTATE_BUFFER
            int r, i
            int rotation    = self._rotation
            gl_enemyshots_add = gl.enemyshots.add
            vertex_bullet_append = STATION_VERTEX_BULLET_HELL.append

        # CHANGE BULLET PATTERN
        if self.pattern_countdown <= 0:
            # PATTERN IS A NUMPY ARRAY
            self.pattern_index += 1
            self.bullet_hell_angle = PATTERNS[self.pattern_index % PATTERN_LENGTH]
            self.pattern_countdown = 200
        else:
            self.pattern_countdown -= 1

        # BULLET ORIGIN
        position = Vector2(rect_x, rect_y)

        cdef int bullet_hell_angle = self.bullet_hell_angle

        for r in range(1):
            # CREATE 4 BULLETS SHOOT AT DIFFERENT ANGLE (SAME ORIGIN)
            # AT CONSTANT VELOCITY
            spr = Sprite()

            gl_all.add(spr)

            if PyObject_IsInstance(gl_all, LayeredUpdates):
                gl_all.change_layer(spr, layer_)

            self.shooting_angle_FX086 += bullet_hell_angle + offset_

            self.shooting_angle_FX086 %= 360

            spr.rad_angle = self.shooting_angle_FX086 * DEG_TO_RAD
            spr.vec       = Vector2(<float> cos(spr.rad_angle) * velocity,
                                   -<float> sin(spr.rad_angle) * velocity)
            spr.image     = <object> PyList_GetItem(FX086, self.shooting_angle_FX086)
            spr.rect      = spr.image.get_rect(center=(position.x, position.y))
            spr.center    = position
            spr._blend    = BLEND_RGB_ADD
            spr._layer    = layer_
            spr.damage    = damage_
            spr.name      = 'FX086'
            gl_enemyshots_add(spr)
            vertex_bullet_append(spr)

    cdef station_impulse(self):
        cdef gl = self.gl

        # CREATE HALO
        Halo(gl_=gl,
             containers_=gl.All,
             images_    =STATION_IMPULSE,
             x          =self.rect.centerx,
             y          =self.rect.centery,
             timing_    =self.timing,
             layer_     =self._layer,
             blend_     =BLEND_RGB_ADD)

    cdef rotation_accelerate(self, float increment_):
        self.rotation_speed += increment_
        self.rotation_speed = min(self.rotation_speed, self.max_rotation_speed)
        if self.rotation_speed == self.max_rotation_speed:
            self.station_impulse()
            self.rotation_status = 0


    cdef rotation_decelerate(self, float increment_):
        self.rotation_speed -= increment_
        self.rotation_speed = max(self.rotation_speed, 0)
        if self.rotation_speed == 0:
            self.rotation_counter = 200
            self.rotation_status = 1

    cpdef update(self, args=None):

        cdef:
            gl              = self.gl
            int index       = self.index
            float speed_x   = self.speed.x
            float speed_y   = self.speed.y
            float acceleration = gl.ACCELERATION
            bint disruption_or_destruction = \
            self.disruption_status or self.destruction_status
            bint on_screen  = gl.screenrect.colliderect(self.rect)
            bint fully_on_screen = gl.screenrect.contains(self.rect)

        # *** BELOW CODE WILL BE CALL EVERY FRAMES ***
        if on_screen:
            if self.is_bullet_reloading():
                self.create_bullet_hell(disruption_or_destruction,
                                        self._layer, self.fx086_damage, offset_=0)
                self.create_bullet_hell(disruption_or_destruction,
                                        self._layer, self.fx086_damage, offset_=180)
        else:
            pass

        if not fully_on_screen:
            self.position.x += speed_x
            self.position.y += speed_y * acceleration

        else:
            pass

        # *** BELOW CODE WILL BE CALL EVERY self.timing MILLI-SECOND
        if self.dt >= self.timing:

            if on_screen:
                self.image = <object> PyList_GetItem(STATION_BUFFER, (<int> self._rotation) % 359)
                self.rect = self.image.get_rect(center=(self.rect.centerx, self.rect.centery))
                self.mask = pygame.mask.from_surface(self.image)

            if fully_on_screen:

                if self.rotation_counter == 0:

                    if self.rotation_status:
                        self.rotation_accelerate(0.1)
                    else:
                        self.rotation_decelerate(0.1)


                self.rotation_counter -= 1 if self.rotation_counter > 0 else 0

            self.rect.centerx = <int>self.position.x
            self.rect.centery = <int>self.position.y  # if pos y = 0 remove the line

            self.dt = 0

            self._rotation += <float>self.rotation_speed

        else:
            self.dt += self.gl.TIME_PASSED_SECONDS


        self.index = index