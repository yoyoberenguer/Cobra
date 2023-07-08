#cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=False, optimize.use_switch=True, profile=False

from random import randint

import numpy

from Bonus import bonus_gems
# from CobraLightEngine import LightEngine
from EnemyShot import select_player
from Halo import Halo
from Miscellaneous import Score
from Sounds import EXPLOSION_SOUND_2, GROUND_EXPLOSION, THUNDER, IMPACT1, SD_LASER_LARGE_ALT_03
from Tools cimport make_transparent32, mask_shadow
from PygameShader.misc import horizontal_grad3d as create_horizontal_gradient_3d

from SurfaceBurst import burst, VERTEX_ARRAY_SUBSURFACE

from Textures import G5V200_SHADOW, G5V200_SHADOW_ROTATION_BUFFER, BLURRY_WATER1, RADIAL, \
    EXPLOSION19, \
    HALO_SPRITE_G5V200, G5V200_EXPLOSION_DEBRIS, G5V200_LASER_FX074, G5V200_FX074_ROTATE_BUFFER, \
    G5V200_LASER_FX086, \
    G5V200_FX086_ROTATE_BUFFER, G5V200_EXHAUST4, G5V200_EXPLOSION_LIST, G5V200_HALO_SPRITE12, \
    EXPLOSIONS, HOTFURNACE2, \
    G5V200_LIFE, SKULL, PHOTON_PARTICLE_1 # , RADIAL4_ARRAY_64x64_FAST, RADIAL4_ARRAY_32x32_FAST

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
    from pygame import Rect, BLEND_RGB_ADD, HWACCEL, BLEND_RGB_MAX, BLEND_RGB_MULT, transform,\
        BLEND_RGB_SUB
    from pygame import Surface, SRCALPHA, mask, event, RLEACCEL
    from pygame.transform import rotate, scale, smoothscale, rotozoom
except ImportError as e:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:
   from Sprites cimport Sprite, collide_mask
   from Sprites cimport LayeredUpdates
except ImportError:
    raise ImportError("\nSprites.pyd missing!.Build the project first.")

from numpy import array
cimport numpy as np

from libc.math cimport cos, exp, sin, atan2, hypot, atan, copysign, sqrt, round

import hsv_surface
from hsv_surface cimport hsv_surface24c, hsv_surface32c


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

cdef long int [::1] OSCILLATIONS = array([10, 7, 2, -2, -5, -6, -4, -1,
                      -1, 3, 3, 2, 0, -1, -3, -2, -2,
                      0, 0, 1, 1, 0, -1, -1, 0], dtype=int)

VERTEX_DEBRIS       = []
VERTEX_BULLET_HELL  = []

cdef list COS_TABLE = []
cdef list SIN_TABLE = []
cdef int angle
COS_TABLE.append(cos(angle * DEG_TO_RAD) for angle in range(0, 360))
SIN_TABLE.append(sin(angle * DEG_TO_RAD) for angle in range(0, 360))



cdef:
    list HSV_LIST = []
    int r
    float c

for r in range(15):
    c = <float>(r / <float>19.0)
    if c > 1.0:
        c = 1.0
    if c < 0.0:
        c = 0.0
    HSV_LIST.append(c)


cdef list VERTEX_FIRE_PARTICLES_FX = []
cdef VERTEX_FIRE_APPEND = VERTEX_FIRE_PARTICLES_FX.append
cdef VERTEX_FIRE_REMOVE = VERTEX_FIRE_PARTICLES_FX.remove

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef display_fire_particle_fx():

    for p_ in VERTEX_FIRE_PARTICLES_FX:

        # move the particle in the vector direction
        p_.rect.move_ip(p_.vector)
        p_.image = <object>PyList_GetItem(p_.images, p_.index)

        if p_.index > len(p_.images) - <unsigned char>2:
            if p_ in VERTEX_FIRE_PARTICLES_FX:
                VERTEX_FIRE_REMOVE(p_)
            p_.kill()

        p_.index += <int>1

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef fire_particles_fx(gl_,
                      position_,                # particle starting location
                      vector_,                  # particle speed
                      images_,                  # surface used for the particle
                      int layer_=0              # Layer used to display the particles
                      ):
        # Cap the number of particles to avoid lag
        if len(VERTEX_FIRE_PARTICLES_FX) > <unsigned char>100:
            return

        # Create fire particles when the aircraft is disintegrating
        sprite_ = Sprite()

        # instantiation slow down the program
        # pygame.sprite.Sprite.__init__(sprite_, All, EnemyBoss.VERTEX_FIRE_PARTICLES_FX)
        cdef gl_all = gl_.All
        gl_all.add(sprite_)
        VERTEX_FIRE_APPEND(sprite_)
        # assign the particle to a specific layer
        if PyObject_IsInstance(gl_all, LayeredUpdates):
            gl_all.change_layer(sprite_, layer_)

        sprite_._blend  = BLEND_RGB_ADD   # use the additive mode
        sprite_.images  = images_
        sprite_.image   = <object>PyList_GetItem(images_, 0)
        sprite_.rect    = sprite_.image.get_rect(center=position_)
        sprite_.vector  = vector_        # vector
        sprite_.index   = 0

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class LifeLevelIndicator(Sprite):

    cdef public object rect, image
    cdef public int _layer, _blend
    cdef int life, N, length, dt, timing, alpha_Value, value
    cdef float ratio
    cdef object image_copy, gl, object

    def __init__(self, gl_, object_, int max_life_, int life_, int blend_=0,
                 int layer_=0, int timing_=16):

        Sprite.__init__(self, gl_.All)

        self.N = 15
        self.height = G5V200_LIFE.get_height() - 18
        self.width  = G5V200_LIFE.get_width() - 10
        self.rect   = pygame.Rect(10, 100, self.width, self.N * self.height + 18)
        self.rect.topleft = (10, 250)
        self.image = pygame.Surface((self.rect.w, self.rect.h), pygame.SRCALPHA)
        self.image.fill((0, 0, 0, 0))
        self.image_copy = self.image.copy()
        self.image_copy.convert(32, pygame.RLEACCEL)
        self.image.convert(32, pygame.RLEACCEL)
        pygame.draw.rect(self.image_copy, (125, 158, 200),
                         pygame.Rect(0, 0, self.width, self.N * self.height + 18), 3)
        self.ratio    = <float>max_life_ / <float>self.N
        self.life     = max_life_
        self.length   = len(HSV_LIST)
        self.max_life = max_life_
        self.dt       = 0
        self.gl       = gl_
        self.timing   = timing_
        self._layer   = layer_
        self._blend   = blend_
        self.object   = object_
        self.alpha_Value = 0
        self.value    = 10
        self.skull = smoothscale(SKULL, (self.rect.w >> 1, self.rect.w >> 1))

    cpdef update(self, args=None):

        cdef:
            int l, t, r
            alpha_Value = self.alpha_Value

        if not self.object.alive():
            self.kill()

        if self.dt > self.timing:

            l = <int>(<float>self.life / <float>self.ratio)

            t = (self.max_life - self.life) // <int>self.ratio

            self.image = self.image_copy.copy()

            for r in range(self.N - t):
                bar1 = hsv_surface32c(G5V200_LIFE, HSV_LIST[(r + <int>t) % self.length])
                self.image.blit(bar1, (-5, 0 + t * self.height + r * self.height), special_flags=0)

            if self.life < <int>45000:
                # skull1 = horizontal_glitch32(skull.copy(), 1.0, 0.1, 10)
                #     self.image.blit(skull1, (0, 0))
                skull1 = make_transparent32(self.skull, alpha_Value)
                # skull.set_alpha(alpha_Value)
                self.image.blit(skull1, (self.width >> 2, 10))
                alpha_Value += self.value
                if alpha_Value > 255:
                    self.value *= -1
                    alpha_Value = <unsigned char>255
                elif alpha_Value < 0:
                    self.value *= - 1
                    alpha_Value = <unsigned char>0
            self.dt = 0
            self.alpha_Value = alpha_Value


        self.dt += self.gl.TIME_PASSED_SECONDS

    cpdef life_update(self, int life_):
        self.life = life_


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline int fact(int n)nogil:
    cdef int r
    for r in range(1, n):
        n *= r
    return <int>n

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef int comb_(int n, int k)nogil:
    cdef int l
    if k > n:
        return 0
    l = <int>(fact(k) * fact(n - k))
    if l!=0:
        return <int>(fact(n)) / l
    else:
        return 1

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef bernstein_poly(int index, int n, np.ndarray[np.float32_t, ndim=1] t):
    return comb_(n, index) * (t ** (n - index)) * (<unsigned char>1 - t) ** index

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef bezier_curve(np.ndarray[np.int32_t, ndim=1] x_points,
                 np.ndarray[np.int32_t, ndim=1] y_points,
                 int n_times_= 30):
    cdef int n_points = len(x_points)
    cdef np.ndarray[np.float32_t, ndim=1] t = numpy.linspace(<float>0.0, <float>1.0,
                                                             n_times_, dtype=numpy.float32)
    cdef int i
    cdef np.ndarray[np.float32_t, ndim=2] polynomial_array = \
        numpy.array([bernstein_poly(i, n_points - <unsigned char>1, t) for i in range(0, n_points)])
    new_array = numpy.dot([x_points, y_points], polynomial_array).astype(dtype=numpy.int16)
    return new_array

# ---- THESE ARE DUPLICATE METHODS (SEE EnemyShot.pyx)
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

        if distance_ == 0.0:
            return damage_

        v = <int> (damage_ / (gamma_ * distance_))

        if v < damage_:
            return damage_

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


# ---- THESE ARE DUPLICATE METHODS (SEE EnemyShot.pyx)
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
cdef class DebrisGenerator(Sprite):

        cdef:
            public int _layer, _blend
            public object image, rect
            object position, vector, gl
            int index
            float dt, timing

        def __init__(self, gl_, int x_, int y_, float timing_ =16.0, int _blend=0, int _layer=0):
            """
            CREATE HULL DEBRIS AFTER THE BOSS EXPLOSION

            * Debris are decelerating after the initial explosion

            :param gl_:class; global constants/variables
            :param x_: integer; x coordinate
            :param y_: integer; y coordinate
            :param timing_: float; timing in milli seconds (default 16ms cap the FPS to 60)
            :param _blend: integer; blend mode default none
            :param _layer: integer; layer to use for this sprite
            """

            Sprite.__init__(self, gl_.All)

            self.image    = <object>PyList_GetItem(G5V200_EXPLOSION_DEBRIS,
                                                   randRange(0, len(G5V200_EXPLOSION_DEBRIS) - 1))
            self.image    = rotozoom(self.image, randRange(<int>0, <int>359),
                                     randRangeFloat(<float>0.4, <float>1.0))
            self.position = Vector2(x_ + randRange(-<int>100, <int>100), y_ +
                                    randRange(-<int>100, <int>100))
            self.rect     = self.image.get_rect(center=self.position)
            cdef:
                float angle = randRangeFloat(0, <float>M_2PI)
            self.vector   = Vector2(<float>cos(angle) * randRange(-<int>50, <int>50),
                                    <float>sin(angle) * randRange(-<int>50, <int>50))

            self.index    = 0
            self._layer   = _layer
            self._blend   = _blend
            self.dt       = 0
            self.gl       = gl_
            self.timing   = timing_

        cpdef update(self, args=None):

            cdef:
                float deceleration
                float dt         = self.dt
                rect             = self.rect
                screenrect       = self.gl.screenrect
                float vector_x   = self.vector.x
                float vector_y   = self.vector.y
                image            = self.image
                int index        = self.index
                int w, h

            if dt > self.timing:

                if rect.colliderect(screenrect):

                    rect.x -= vector_x
                    rect.y -= vector_y
                    with nogil:
                        # DEBRIS DECELERATION
                        deceleration = <float>1.0 / (<float>1.0 + <float>0.0001 * index * index)
                        vector_x *= deceleration
                        vector_y *= deceleration

                    if index % 2 == 0:
                        try:
                            w = image.get_width()
                            h = image.get_height()
                            image = scale(image, (w-<unsigned char>1, h-<unsigned char>1))
                        except ValueError:
                            self.kill()

                    dt = 0
                    self.index += 1
                    self.vector.x = vector_x
                    self.vector.y = vector_y
                    self.image = image

                else:
                    self.kill()

            dt += self.gl.TIME_PASSED_SECONDS
            self.dt = dt

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
# CONVENIENT HOOK TO DISPLAY THE BULLETS FROM THE MAIN PROGRAM
cpdef loop_display_bullets(gl_):
    display_bullets(gl_)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef void display_bullets(gl):
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
        vertex_remove = VERTEX_BULLET_HELL.remove

    global VERTEX_BULLET_HELL

    for spr in VERTEX_BULLET_HELL:

        # BULLET OUTSIDE DISPLAY ?
        if screenrect.contains(spr.rect):

            spr.center.x += spr.vec.x
            spr.center.y += spr.vec.y
            spr.rect.centerx = spr.center.x
            spr.rect.centery = spr.center.y

        else:
            if spr in VERTEX_BULLET_HELL:
                vertex_remove(spr)
            spr.kill()




# FIRE PARTICLE CONTAINER
cdef list EXPLOSION_CONTAINER = []
cdef dict EXPLOSION_DICT = {'center': (0, 0), 'index': 0}

# BULLET DICTIONARY
cdef dict BULLET_DICT = \
    {'image'    : G5V200_LASER_FX074,
     'rect'     : None,
     'position' : None,
     'vector'   : None,
     '_blend'   : 1,
     'index'    : 0,
     'damage'   : 0,
     'w2'       : G5V200_LASER_FX074.get_width() >> 1,
     'h2'       : G5V200_LASER_FX074.get_height() >> 1
    }

# RING BULLET DICTIONARY
cdef dict RING_DICT = \
    {'image'    : None,
     'rect'     : None,
     'position' : None,
     'vector'   : None,
     '_blend'   : 1,
     'index'    : 0,
     'damage'   : 0
     }
cdef list RING_MODEL = []

# BULLET FREQUENCY/PATTERN
cdef long int [::1] PATTERNS = array([10, 11, 12, 15,  16, 17, 18, 22, 24, 33], dtype=int)
cdef unsigned int PATTERN_LENGTH = len(PATTERNS) - 1

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline vector2d get_vector(int heading_, float magnitude_)nogil:
    """
    RETURN VECTOR COMPONENTS RELATIVE TO A GIVEN ANGLE AND MAGNITUDE 
    :return: Vector2d 
    """
    cdef float angle_radian = DEG_TO_RAD * heading_
    cdef vector2d vec
    vecinit(&vec, <float>cos(angle_radian), -<float>sin(angle_radian))
    scale_inplace(magnitude_, &vec)
    return vec

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(False)
@cython.profile(False)
cdef inline int get_angle(int obj1_x, int obj1_y, int obj2_x, int obj2_y)nogil:
        """
        RETURN THE ANGLE IN RADIANS BETWEEN TWO OBJECT OBJ1 & OBJ2 (center to center)

        :param obj1_x: source x coordinate
        :param obj1_y: source y coordinate
        :param obj2_x: target x coordinate
        :param obj2_y: target y coordinate
        :return: integer;  Angle between both objects (degrees)
        """
        cdef int dx = obj2_x - obj1_x
        cdef int dy = obj2_y - obj1_y
        return -<int>((<float>RAD_TO_DEG * <float>atan2(dy, dx)) % <int>360)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
class BossLifeBar(Sprite):


    def __init__(self,
                 gl_,
                 object_,
                 int width_,
                 int height_,
                 int topleft_x_,
                 int topleft_y_,
                 int layer_=-1,
                 int blend_=0):

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        gradient_array = create_horizontal_gradient_3d(
            width_, height_, start_color=(255, 0, 0), end_color=(0, 255, 0))

        self.image  = pygame.surfarray.make_surface(gradient_array)
        self.rect   = self.image.get_rect(topleft=(topleft_x_, topleft_y_))
        self._layer = layer_
        self._blend = blend_
        self.gl     = gl_
        self.life   = object_.hp
        self.ratio  = float(width_) / float(object_.max_hp)
        self.height = height_
        self.object = object_


    def update(self, args=None):

        if not self.object.alive():
            self.kill()

        cdef int w = self.ratio * self.life

        surface = pygame.Surface((w, self.height))
        surface.blit(self.image, (0, 0), (0, 0, w, self.height))
        self.image = surface

        # gradient_array = create_horizontal_gradient_3d(
        #     w, self.height, start_color=(255, 0, 0), end_color=(0, 255, 0))
        #
        # self.image = pygame.surfarray.make_surface(gradient_array)

    def life_update(self, int life_):
        self.life = life_

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
        self.name       = "G5V200"
        self.id         = id(self)
        self.mass       = 10


DUMMY_CLASS = EnemyClass()

cdef class EnemyBoss(Sprite):

    cdef:
        # TODO public vector ??
        public object image, rect, impact_sound, momentum
        public int _layer, _blend, _rotation, last_rotation, clocking_index
        object image_copy
        int length, index, length1, sprite_orientation, disruption_index, \
            quake_length, quake_index, exp_length, bullet_hell_angle, shooting_angle, \
            destruction_timer, explosion_frequency, pattern_index
        float timing, dt, bullet_hell_ring_reload
        public bint clocking_status, destruction_status, disruption_status,\
            quake


    def __init__(self,
                 gl_,
                 weapon1_,
                 weapon2_,
                 attributes_,
                 containers_,
                 int pos_x,
                 int pos_y,
                 image_,
                 float timing_=16.0,
                 int layer_=-2,
                 int _blend=0):
        """
        BOSS G5V200 WITH BULLET HELL WEAPON

        :param gl_        : class; global Constants/variables
        :param weapon1_   : dict; weapon1 features
        :param weapon2_   : dict; weapon2 features
        :param containers_: Sprite group(s) to use
        :param pos_x      : integer; x coordinates
        :param pos_y      : integer; y coordinates
        :param image_     : Surface; Surface/animations
        :param timing_    : float; CAP FPS to 60 (16ms)
        :param layer_     : integer; Layer to use
        :param _blend     : integer; additive mode
        """

        Sprite.__init__(self, containers_)

        self._layer = layer_
        self.gl     = gl_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        if PyObject_IsInstance(image_, list):
            self.image   = <object>PyList_GetItem(image_, 0)
            self.length1 = PyList_Size(image_) - <unsigned char>1
        else:
            self.image   = image_

        self.image_copy  = image_.copy()
        # self.mask = pygame.mask.from_surface(self.image)

        self.rect        = self.image.get_rect(center=(pos_x, pos_y))
        self.dt          = 0
        self.index       = 0
        self.timing      = timing_
        self._blend      = _blend

        # FLAG RAISED WHEN SHIP IS EXPLODING
        self.destruction_status  = False
        self.destruction_timer   = 0
        self.explosion_frequency = 50
        # FLAG RAISED WHEN SHIP IS DISRUPTED
        self.disruption_status  = False
        self.disruption_index   = 0

        # SPRITE ORIENTATION
        # ANGLE IN DEGREES CORRESPONDING
        # TO THE ORIGINAL IMAGE ORIENTATION
        # 0 DEGREES, SPACESHIP IMAGE IS ORIENTED
        # TOWARD THE RIGHT
        # self.sprite_orientation = 0

        # ANGLE IN DEGREES CORRESPONDING
        # TO THE DIFFERENCE BETWEEN ORIGINAL (
        # self.sprite._rotation) IMAGE AND
        # ACTUAL SPRITE ORIENTATION
        # ZERO WOULD MEAN THAT THE SPRITE ANGLE IS
        # EQUAL TO THE ORIGINAL IMAGE ORIENTATION
        self._rotation      = 0
        # LEAVE IT AT 1 (INITIATE FIRST SHADOW DISPLAY)
        self.last_rotation  = 1

        self.weapon1 = weapon1_
        self.weapon2 = weapon2_
        self.bullet_hell_ring_reload = \
            <object>PyDict_GetItem(weapon1_,'reloading_time')  # 1.5 seconds
        self.ring_count_down         = \
            <object>PyDict_GetItem(weapon1_,'reload_countdown')
        self.fx074_damage = <object> PyDict_GetItem(weapon1_, 'damage')

        self.bullet_hell_reload      = \
            <object>PyDict_GetItem(weapon2_,'reloading_time')
        self.bullet_count_down       = \
            <object>PyDict_GetItem(weapon2_,'reload_countdown')
        self.fx086_damage   = <object>PyDict_GetItem(weapon2_,'damage')

        # TIME IN BETWEEN PATTERNS 10 secs
        # PATTERN IS A LIST CONTAINING DIFFERENT ANGLE IN BETWEEN SHOTS
        self.pattern_countdown       = 200 # 10k ms correspond to 10 secs
        self.pattern_index           = 0

        # LOAD FIRST PATTERN
        self.bullet_hell_angle = PATTERNS[0]
        self.shooting_angle_FX086 = 0

        self.shadow         = G5V200_SHADOW
        self.quake_range    = OSCILLATIONS
        self.quake_length   = len(self.quake_range) - <unsigned char>1
        self.quake_index    = 0
        self.quake          = False

        # CLOCKING DEVICE STATUS
        self.clocking_status = False
        self.clocking_index  = 0    # START @ MAX OPACITY

        self.exp_surface = HOTFURNACE2
        self.exp_length  = PyList_Size(HOTFURNACE2) - 1

        # DROP THE ENEMY SPACESHIP SHADOW
        self.enemy_shadow()

        # BUFFER 100 DEBRIS THAT WILL BE DISPLAY AFTER BOSS SPACESHIP EXPLOSION
        self.create_debris(x_=self.rect.centerx,
                           y_=self.rect.centery, debris_number_=200)

        # CREATE 36 BULLETS
        # self.create_bullet_hell_ring(False)

        # DISPLAY PROPULSION
        self.exhaust_instance = None
        self.display_exhaust()

        # PLAYER CAUSING DAMAGE TO THIS INSTANCE
        self.player_inflicting_damage = None

        # SELECT A PLAYER AT INIT TIME
        self.targeted_player = select_player(gl_)

        # ADD EXTRA ATTRIBUTES FROM XML FILE G5V200.xml
        self.hp       = <object>PyDict_GetItem(attributes_,'life')
        self.max_hp   = <object>PyDict_GetItem(attributes_,'max_life')
        self.strategy = <object>PyDict_GetItem(attributes_,'strategy')
        self.score    = <object>PyDict_GetItem(attributes_,'score')
        self.path     = <object>PyDict_GetItem(attributes_,'path')
        self.damage   = <object>PyDict_GetItem(attributes_,'damage')  # COLLISION DAMAGE
        self.path = self.path[::-1]
        self.start_frame = <object> PyDict_GetItem(attributes_, 'start_frame')

        # IMPACT SOUND (PLAYER HITS THE BOSS)
        self.impact_sound = IMPACT1
        self.waypoint_list = []
        self.momentum = Vector2(0, 0)

        cdef i = 0
        cdef float x, y
        for x, y in self.path:
            self.path[i] = <float>(x * gl_.RATIO.x), <float>(y * gl_.RATIO.y)
            i += 1

        cdef int n = 60
        self.waypoint_list_ = bezier_curve(self.path[:, 0], self.path[:, 1], n_times_=n)

        for r in list(zip(self.waypoint_list_[0], self.waypoint_list_[1])):
            self.waypoint_list.append(r)

        self.waypoint_dict = self.init_path(self.waypoint_list)

        self.max_waypoint = len(self.waypoint_list)
        self.waypoint = 0
        self.vector = Vector2(<float>0.0, <float>0.0)
        waypoint_1 = self.waypoint_list[0]

        self.position = Vector2(self.rect.centerx, self.rect.centery)
        self.vector = (waypoint_1 - self.position).normalize()
        global DUMMY_CLASS
        self.enemy_ = DUMMY_CLASS

        # self.blf = None # Boss life bar reference

        self.indicator = None

    @cython.binding(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(False)
    @cython.profile(False)
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
            point = waypoint_list_[r]
            dx_list.append(Vector2(point[0], point[1]))

        cdef dict waypoint_dict = {}
        for r in range(l - <unsigned char>1):
            current_waypoint = dx_list[r]
            next_waypoint = dx_list[r + 1]
            v = next_waypoint - current_waypoint
            vec = Vector2(normalized_vector(v.x, v.y))
            angle = (<int> (-<float>atan2(vec.y, vec.x) * <float>RAD_TO_DEG) + <int>360) % <int>360
            # ! -v.y INVERSE Y
            waypoint_dict[r] = [Vector2(vec.x, vec.y), angle, current_waypoint]

        return waypoint_dict

    cdef new_vector(self):

        vector1 = Vector2(self.rect.centerx, self.rect.centery)
        if self.waypoint < self.max_waypoint:
            vector2 = Vector2()
            vector2.x, vector2.y = self.waypoint_list[self.waypoint]

        vector = vector2 - vector1
        if vector.length() > 0:
            return vector
        else:
            return Vector2(<float>0.0, <float>0.0)

    cdef is_waypoint_passed(self):

        dummy_rect = pygame.Rect(self.rect.centerx - <unsigned char>30,
                                 self.rect.centery - <unsigned char>30,
                                 <unsigned char>60, <unsigned char>60)
        vec = Vector2(<float>0.0, <float>0.0)

        if self.waypoint < self.max_waypoint:
            if dummy_rect.collidepoint(self.waypoint_list[self.waypoint]):
                # next direction vector calculation
                self.waypoint += 1
                vec = self.new_vector()
            else:
                vec =  Vector2(self.waypoint_list[self.waypoint]) - Vector2(self.rect.center)
        return vec

    cdef clocking_device(self, image, clock_value):
        """
        CONTROL THE SPACESHIP HULL OPACITY 

        Add transparency to a surface (image)
        :param image      : Surface; image to modify  
        :param clock_value: Alpha value to use 
        :return           : return a pygame surface 
        """
        return make_transparent32(image, clock_value).convert_alpha()

    def full_merge(self, right, left):
        """
        RETURN TRUE WHEN BOTH MASK FULLY OVERLAP

        This method is used to determine if a mask fully overlap (e.g bomb crater
        must fully overlap with the background image and not only a section)

        :param right: pygame.Sprite; right sprite
        :param left : pygame.Sprite; left sprite
        :return: bool; True | False
        """
        cdef int xoffset = right.rect[0] - left.rect[0]
        cdef int yoffset = right.rect[1] - left.rect[1]
        r_mask = left.mask.overlap_mask(right.mask, (xoffset, yoffset))
        if r_mask.count() == self.mask_count:
            return True
        else:
            return False

    cdef drop_shadow_improve(self, texture_, texture_mask, gl_, tuple center_):
        """
        DROP THE AIRCRAFT SHADOW ON THE GROUND

        Return True when the shadow can be cast to the background surface otherwise return False

        :param texture_: pygame.Surface; Aircraft shadow image/texture
        :param texture_mask: Surface mask e.g pygame.mask.from_surface(self.image)
        :param gl_: class; global variables/constants
        :param center_: tuple; centre of the sprite shadow
        :return: True | False
        """
        shadow_sprite       = Sprite()
        shadow_sprite.image = texture_
        shadow_sprite.mask  = texture_mask
        shadow_sprite.rect  = texture_.get_rect(center=(center_[0], center_[1]))

        cdef:
            list sprites_at_drop_position
            gl_All = gl_.All
            get_sprites_at = gl_All.get_sprites_at
            int w, h
            crater_sprite_rect = shadow_sprite.rect
            list ground_level_group = []
            int ground_layer = -7
            int xoffset, yoffset

        w, h = texture_.get_size()
        # RETURN A LIST WITH ALL SPRITES AT THAT POSITION
        # LAYEREDUPDATES.GET_SPRITES_AT(POS): RETURN COLLIDING_SPRITES
        # BOTTOM SPRITES ARE LISTED FIRST; THE TOP ONES ARE LISTED LAST.
        sprites_at_drop_position = get_sprites_at(shadow_sprite.rect.center)

        for sp in sprites_at_drop_position:
            if not PyObject_HasAttr(sp, '_layer'):
                continue

            if sp._layer != ground_layer:
                continue
            else:
                ground_level_group.append(sp)

        if len(ground_level_group) > 0:

            for spr in ground_level_group:

                # ONLY PLATFORM 0 AND PLATFORM 7 HAVE A MASK OTHER BACKGROUND SPRITE DOES NOT.
                # OTHER BACKGROUND HAVE A PLAN SURFACE
                if PyObject_HasAttr(spr, 'mask') and spr.mask is not None:
                    # Tests for collision between two sprites by testing if their bitmasks
                    # overlap. If the sprites have a "mask" attribute, that is used as the mask;
                    # otherwise, a mask is created from the sprite image. Intended to be passed
                    # as a collided callback function to the *collide functions. Sprites must
                    # have a "rect" and an optional "mask" attribute.

                    if collide_mask(spr, shadow_sprite):
                        # return self.full_merge(spr, shadow_sprite)

                        xoffset = spr.rect[0] - shadow_sprite.rect[0]
                        yoffset = spr.rect[1] - shadow_sprite.rect[1]
                        lmask = shadow_sprite.mask.overlap_mask(spr.mask, (xoffset, yoffset))
                        mask_surface = lmask.to_surface(setcolor=(255, 255, 255),
                                                        unsetcolor=(0, 0, 0))

                        # CREATE A SURFACE WITH SAME DIMENSION THAT THE SHADOW
                        # AND BLIT THE MASK ON IT
                        new_surface = Surface((w, h))
                        new_surface.fill((0, 0, 0))
                        new_surface.blit(mask_surface, (0, 0))

                        return mask_shadow(texture_.copy(), new_surface)
                else:

                    return texture_
        s = pygame.Surface((w, h), pygame.SRCALPHA)
        s.fill((0, 0, 0, 0))
        return s

    @cython.cdivision(False)
    cdef void enemy_shadow(self):
        """
        # DROP A SHADOW BELOW THE AIRCRAFT

        This method has to be called during instantiation
        Shadow instance is autonomous
        :return: None
        """
        cdef:
            gl    = self.gl
            rect  = self.rect
            int angle = self._rotation % <int>360
            int length    = len(G5V200_SHADOW_ROTATION_BUFFER)

        shadow = G5V200_SHADOW_ROTATION_BUFFER[angle % (length - 1)]
        shadow_mask = pygame.mask.from_surface(shadow)
        cdef int w_2 = G5V200_SHADOW_ROTATION_BUFFER[0].get_width() >> 2
        cdef int h_2 = G5V200_SHADOW_ROTATION_BUFFER[0].get_height() >> 2

        shadow = self.drop_shadow_improve(
                            texture_     = shadow,
                            texture_mask = shadow_mask,
                            gl_          = gl,
                            center_      = (rect.centerx + w_2, rect.centery + h_2))

        # BindShadow(containers_      = gl.All,
        #            object_          = self,
        #            gl_              = gl,
        #            offset_          = (w_2, h_2),
        #            rotation_buffer_ = G5V200_SHADOW_ROTATION_BUFFER,
        #            timing_          = self.timing,
        #            layer_           = self._layer - 1,
        #            dependency_      = True,
        #            blend_           = BLEND_RGB_SUB)

        from BindSprite import BindSprite
        BindSprite(group_      = gl.All,
                   images_      = shadow,
                   object_      = self,
                   gl_          = gl,
                   offset_      = (w_2, h_2),
                   timing_      = self.timing,
                   layer_       = self._layer - <unsigned char>1,
                   loop_        = False,
                   dependency_  = True,
                   follow_      = False,
                   blend_       = BLEND_RGB_SUB,
                   event_       = 'SHADOW')



    cdef tuple rot_center(self, image_, int angle_, int x, int y):
        """
        ROTATE THE ENEMY SPACESHIP IMAGE  

        :param y     : integer; x coordinate (rect center value) 
        :param x     : integer; y coordinate (rect center value)
        :param image_: pygame.Surface; Surface to rotate
        :param angle_: integer; Angle in degrees 
        :return: Return a tuple (surface, rect)
        """
        new_image = rotozoom(image_, angle_, <float>1.0)
        return new_image, new_image.get_rect(center=(x, y))

    cpdef location(self):
        """
        RETURN SPRITE RECT
        :return: Return the sprite rect (keep compatibility with other class)
        """
        return self.rect

    cdef int damage_calculator(self, int damage_, float gamma_, float distance_)nogil:
        """
        DETERMINES MAXIMUM DAMAGE TRANSFERABLE TO A TARGET.

        :param damage_  : int; Maximal damage  
        :param gamma_   : float;   
        :param distance_: float; distance between target and enemy rect center
        :return         : integer; Damage to transfer to target after impact.
        """
        cdef float delta = gamma_ * distance_

        if delta == 0:
            return damage_

        damage = <int>(damage_ / delta)
        if damage > damage_:
            return damage_
        return damage

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

    cdef float damped_oscillation(self, double t)nogil:
        """
        DAMPENING EQUATION
        :return: float; 
        """
        return <float>(<float>exp(-t) * <float>cos(<float>M_PI * t))

    cdef void spaceship_quake(self):
        """
        CREATE A QUAKE EFFECT (SPACESHIP SHACKING EFFECT)
        :return: None
        """
        cdef:
            int qi = self.quake_index
            int ql = self.quake_length

        self.rect.centerx += OSCILLATIONS[qi]
        qi += 1

        if qi > self.quake_length:
            self.quake = False
            qi = 0

        self.quake_index = qi

    cdef disruption_effect(self, image_):
        """
        APPLY A TEXTURE TO SELF.IMAGE (SPACESHIP DISRUPTION EFFECT)
        :return: pygame.Surface
        """
        cdef int length         = <object>PyList_Size(BLURRY_WATER1) - <unsigned char>1
        disruption_layer_effect = <object>PyList_GetItem(BLURRY_WATER1,
                                                         self.disruption_index % length)
        image_.blit(disruption_layer_effect, (0, 0), special_flags=BLEND_RGB_ADD)
        self.disruption_index   += <unsigned char>1
        return image_

    cdef void disruption_effect_stop(self):
        """
        STOP THE DISRUPTION EFFECT 
        :return: None
        """
        self.disruption_index = 0

    cdef void create_hull_explosions_fx(self, int x_, int y_):
        """
        MULTIPLE HULL EXPLOSION EFFECT

        :param x_       : integer; particle x coordinate
        :param y_       : integer; particle y coordinate
        :return         : None
        """
        new_dict = PyDict_Copy(EXPLOSION_DICT)
        PyDict_SetItem(new_dict, 'center', (x_, y_))
        PyList_Append(EXPLOSION_CONTAINER, new_dict)


    cdef display_hull_explosions_fx(self, image_):
        """
        ITERATE OVER THE EXPLOSION CONTAINER

        :return: None 
        """

        cdef:
            int explosion_index
            int exp_length = self.exp_length
            exp_surface    = self.exp_surface
            list explosion_container = EXPLOSION_CONTAINER
            dict explosion

        for explosion in explosion_container:

            explosion_index = <object>PyDict_GetItem(explosion, 'index')
            image           = <object>PyList_GetItem(exp_surface, explosion_index)
            center          = <object>PyDict_GetItem(explosion, 'center')

            PyObject_CallFunctionObjArgs(image_.blit,
                                         <PyObject*>image,
                                         <PyObject*>center,
                                         <PyObject*>None,
                                         <PyObject*>BLEND_RGB_ADD,
                                         NULL)

            if explosion_index >= exp_length:
                explosion_container.remove(explosion)
            explosion['index'] += 1
        return image_


    cdef void enemy_explosion(self):
        """
        ENEMY SPACESHIP IS EXPLODING (LIGHT AND SOUND EFFECT)
        :return: None
        """
        cdef:
            gl = self.gl
            int rect_x = self.rect.centerx
            int rect_y = self.rect.centery
            int x, y, r


        # CREATE A FLASHING LIGHT EFFECT
        BindSprite(images_      = RADIAL,
                   containers_  = gl.All,
                   object_      = self,
                   gl_          = gl,
                   offset_      = None,
                   timing_      = self.timing,
                   layer_       = 0,
                   blend_       = BLEND_RGB_ADD)

        BindExplosion(containers_   = gl.All,
                      images_       = EXPLOSION19,
                      gl_           = gl,
                      pos_x         = rect_x,
                      pos_y         = rect_y,
                      timing_       = self.timing,
                      layer_        = 0,
                      blend_        = BLEND_RGB_ADD)

        for r in range(4):
            # RANDOMIZE POSITION
            x = randRange(rect_x  - 100, rect_x + 100)
            y = randRange(rect_y  - 100, rect_y + 100)
            # CREATE AN EXPLOSION
            BindExplosion(containers_   = gl.All,
                          images_       = EXPLOSION19,
                          gl_           = gl,
                          pos_x         = x,
                          pos_y         = y,
                          timing_       = self.timing,
                          layer_        = 0,
                          blend_        = BLEND_RGB_ADD)

        # CREATE HALO
        Halo(gl_        = gl,
             containers_= gl.All,
             images_    = HALO_SPRITE_G5V200,
             x          = rect_x,
             y          = rect_y,
             timing_    = self.timing,
             layer_     = 0,
             blend_     = BLEND_RGB_ADD)

        gl.SC_explosion.play(
                sound_      = THUNDER,
                loop_       = 0,
                priority_   = 0,
                volume_     = gl.SOUND_LEVEL,
                fade_out_ms = 0,
                panning_    = False,
                name_       = 'G5V200_EXPLOSION',
                x_          = rect_x,
            object_id_      = id(EXPLOSION_SOUND_2))

        # BELOW CAUSE THE PROGRAM TO LAG
        self.gl.SHOCKWAVE = True

        im = scale(self.image, (256, 256))
        burst(
            gl,
            im,
            vertex_array_= VERTEX_ARRAY_SUBSURFACE,
            block_size_ = 4,
            rows_       = 64,
            columns_    = 64,
            x_          = self.rect.topleft[0],
            y_          = self.rect.topleft[1],
            max_angle_  = 359,
            type_       = 0)

        # IF THE PLAYER GROUP EXIST AND PLAYER INFLICTING DAMAGE IS NOT NULL
        if bool(gl.PLAYER_GROUP) and self.player_inflicting_damage \
                is not None and self.player_inflicting_damage.alive():
            bonus_gems(gl_=gl, object_=self, player_=self.player_inflicting_damage,
                       min_=50, max_=200, chance_=100)

        # TODO PLAYER KILLING ENEMY SHOULD GET THE GEMS
        # CHECK THE NUMBER OF PLAYERS
        # IF TWO PLAYERS CHOOSE RANDOMLY THE PLAYER GETTING ALL THE GEMS
        # OTHERWISE PLAYER1 IS HAVING IT ALL
        else:
            if bool(gl.PLAYER_GROUP):
                if len(gl.PLAYER_GROUP) == 2:
                    bonus_gems(gl_=gl, object_=self,
                               player_=gl.PLAYER_GROUP.sprites()[randRange(0, 1)],
                               min_=50, max_=200,
                               chance_=100)
                elif len(gl.PLAYER_GROUP) == 1:
                    bonus_gems(gl_=gl, object_=self,
                               player_=gl.PLAYER_GROUP.sprites()[0],
                               min_=50, max_=200,
                               chance_=100)

        # GIVE THE SCORE ONLY TO THE PLAYER THAT CAUSE THE ENEMY DESTRUCTION
        if self.player_inflicting_damage is not None and\
                self.player_inflicting_damage.alive():
            # self.score is the value in the XML file G5200.xml
            Score(gl, self.player_inflicting_damage).update(self.score)

        for spr in VERTEX_FIRE_PARTICLES_FX:
            spr.kill()

        self.gl.WOBBLY = 0
        self.gl.SHOCKWAVE = False

        # DESTROY SPACESHIP
        self.kill()


    cdef void create_debris(self, int x_, int y_, int debris_number_):
        """
        CREATE SPACESHIP DEBRIS (DISPLAY AFTER EXPLOSION)
        
        * Debris can be created during the BOSS instantiation (all debris are assigned 
        to the LIST VERTEX_DEBRIS

        :param debris_number_: integer; Debris number to be display (max entities)
        :param x_: integer; centre of the explosion x coordinate
        :param y_: integer; centre of the explosion y coordinate 
        :return: return None
        """

        cdef:
            int r
            dict debris_dict = {'image':None, 'rect':None, 'vector':None, 'index':0}
            int length = PyList_Size(G5V200_EXPLOSION_DEBRIS) - 1, pos_x, pos_y
            float velocity, angle
            float rand
            vector2d vector

        for r in range(debris_number_):
            with nogil:
                angle = randRangeFloat(<float>0.0, <float>M_2PI)
                rand  = randRangeFloat(<float>0.4, <float>1.0)
                pos_x = x_ + randRange(-<int>100, <int>100)
                pos_y = y_ + randRange(-<int>100, <int>100)
                velocity           = randRange(<int>1, <int>25)
                vecinit(&vector, <float>cos(angle) * velocity, <float>sin(angle) * velocity)
            debris             = PyDict_Copy(debris_dict)
            PyDict_SetItem(debris, 'image',
                           <object>PyList_GetItem(G5V200_EXPLOSION_DEBRIS,
                                                                   randRange(0, length)))
            PyDict_SetItem(debris, 'image',
                           rotozoom(debris['image'],
                                                     <int>(angle * <float>RAD_TO_DEG), rand))
            PyDict_SetItem(debris, 'rect', debris['image'].get_rect(center=(pos_x, pos_y)))
            PyDict_SetItem(debris, 'vector', vector)
            # PyDict_SetItem(debris, 'index', 0)
            VERTEX_DEBRIS.append(debris)


    # TODO : NOT USED
    cpdef void update_debris(self, gl_, int framerate_):
        """ 
        
        UPDATE DEBRIS POSITIONS (FLYING DEBRIS AFTER BOSS EXPLOSION) 

        This method has to be called from the main loop has the 
        enemy instance would be killed when the enemy ship is destroyed.  

        :param framerate_: integer; Framerate   
        :param gl_       : class; global game variable / constants
        :return          : None
        """

        cdef:
            screenrect = gl_.screenrect
            screen     = gl_.screen
            float deceleration = 0
            int w, h
            screen_blit = screen.blit
            int index
            vector2d vector
            dict debris

        for debris in VERTEX_DEBRIS:

            rect    = <object>PyDict_GetItem(debris, 'rect')
            image   = <object>PyDict_GetItem(debris, 'image')
            index   = <object>PyDict_GetItem(debris, 'index')
            vector_ = <object>PyDict_GetItem(debris, 'vector')
            vecinit(&vector, vector_['x'], vector_['y'])

            if PyObject_CallFunctionObjArgs(rect.colliderect, <PyObject*>screenrect, NULL):
                with nogil:
                    deceleration = <float>1.0 / (<float>1.0 + <float>1e-6 * index * index)
                    vector.x *= deceleration
                    vector.y *= deceleration
                rect.move_ip(vector.x, vector.y)

                PyObject_CallFunctionObjArgs(screen_blit,
                                         <PyObject*>image,
                                         <PyObject*>rect.center,
                                         <PyObject*>None,
                                         <PyObject*>BLEND_RGB_ADD,
                                         NULL)

                if index % framerate_ == 0:

                    try:
                        w = image.get_width()
                        h = image.get_height()
                        image = scale(image, (w - <unsigned char>1, h - <unsigned char>1))
                    except ValueError:
                        VERTEX_DEBRIS.remove(debris)
                        continue

                PyDict_SetItem(debris, 'index', index + <unsigned char>1)
                PyDict_SetItem(debris, 'rect', rect)
                PyDict_SetItem(debris, 'image', image)
                PyDict_SetItem(debris, 'vector', vector)

            else:
                VERTEX_DEBRIS.remove(debris)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(False)
    cdef void create_bullet_hell_ring(self,
                                      bint disruption_or_destruction, int layer_, int damage_):
        """
        CREATE BULLET RING (BULLET HELL)

        This method create bullets and put them into a vertex array VERTEX_BULLET_HELL

        :param : disruption_or_destruction: bool; 
        Boolean value True if ship is exploding or disrupted
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
            gl = self.gl
            float velocity = (<object> PyDict_GetItem(self.weapon1, 'velocity')).length()
            float cs = 50.0
            float rad_angle, offset_x, offset_y, rad_angle_
            int rect_x = self.rect.centerx
            int rect_y = self.rect.centery
            image = G5V200_LASER_FX074
            list FX074 = G5V200_FX074_ROTATE_BUFFER
            int r
            int rotation = self._rotation
            vertex_append = VERTEX_BULLET_HELL.append
            gl_enemy_add = gl.enemyshots.add
            gl_all_add = gl.All.add

        with nogil:
            rad_angle_ = DEG_TO_RAD * rotation
            offset_x, offset_y = -<float>cos(rad_angle_) * cs, -<float>sin(rad_angle_) * cs

        position = Vector2(rect_x + offset_x, rect_y - offset_y)

        cdef gl_all = gl.All
        # CREATE 36 BULLETS
        self.shooting_angle_FX074 = 0

        if 0 < rect_x < gl.screenrect.w:
            self.gl.SC_explosion.play(
                sound_      = SD_LASER_LARGE_ALT_03,
                loop_       = False,
                priority_   = 2,
                volume_     = gl.SOUND_LEVEL,
                fade_out_ms = 0,
                panning_    = True,
                name_       = 'HELL_RING',
                x_          = rect_x)


        for r in range(shooting_range):
            spr = Sprite()

            gl_all_add(spr)

            if PyObject_IsInstance(gl_all, LayeredUpdates):
                gl_all.change_layer(spr, layer_)

            rad_angle = (r * 10) * DEG_TO_RAD
            spr.image    = <object> PyList_GetItem(FX074, (r * 10))
            spr.rect     = spr.image.get_rect(center=(position.x, position.y))
            spr.vec      = Vector2(<float> cos(rad_angle) *
                                   velocity, -<float> sin(rad_angle) * velocity)
            spr._blend   = BLEND_RGB_ADD
            spr._layer   = layer_
            spr.center   = Vector2(position.x, position.y)
            spr.damage   = damage_
            spr.name     = "FX074"
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


    cdef void display_exhaust(self):
        """
        DISPLAY ENEMY PROPULSION EXHAUST (FOLLOW THE SHIP MOVEMENT)

        :return: None
        """
        cdef:
            int height = (<object>PyList_GetItem(self.image_copy, 0)).get_height()
            int offset_y = (height >> 1) + <unsigned char>20

        self.exhaust_instance = BindSprite(
            images_     = G5V200_EXHAUST4,
            containers_ = self.gl.All,
            object_     = self,
            gl_         = self.gl,
            offset_     = (0, offset_y),
            timing_     = self.timing,
            layer_      = self._layer - 1,
            loop_       = True,
            dependency_ = True,
            follow_     = True,
            event_      = 'G5200_EXHAUST',
            blend_      = 0)

    cdef void stop_exhaust(self, exhaust_running):
        if exhaust_running:
            self.exhaust_instance.kill_instance(self.exhaust_instance)


    cdef void create_bullet_hell(self, bint disruption_or_destruction, int layer_, int damage_):
        """
        CREATE BULLET HELL

        One the bullet has been pushed into the vertex array, the method display_bullets 
        will take over and update all the bullets positions at once on your display.

        :return: None
        """
        if disruption_or_destruction:
            return

        cdef:
            int deg_angle = 0
            gl = self.gl
            gl_all = gl.All
            float rad_angle, offset_x, offset_y, rad_angle_
            float velocity = Vector2(self.weapon2['velocity'], self.weapon2['velocity']).length()
            float cs = 50.0
            int rect_x = self.rect.centerx
            int rect_y = self.rect.centery
            image = G5V200_LASER_FX086  # not defined yet
            list FX086 = G5V200_FX086_ROTATE_BUFFER
            int r, i
            int rotation = self._rotation
            gl_enemyshots_add = gl.enemyshots.add
            vertex_bullet_append = VERTEX_BULLET_HELL.append

        # CHANGE BULLET PATTERN
        if self.pattern_countdown <= 0:
            # PATTERN IS A NUMPY ARRAY
            self.pattern_index += 1
            self.bullet_hell_angle = PATTERNS[self.pattern_index % PATTERN_LENGTH]
            self.pattern_countdown = 200

            # ROTATE THE BULLET HUE
            i = 0
            for s in FX086:
                FX086[i] = hsv_surface24c(s, <float>0.2)
                i+= 1
        else:
            self.pattern_countdown -= 1

        # RELEASE THE GIL
        with nogil:
            # rad_angle_ is the spaceship rotation value in radians
            rad_angle_ = DEG_TO_RAD * rotation
            # OFFSET BULLETS ORIGIN
            offset_x, offset_y = -<float>cos(rad_angle_) * cs, -<float>sin(rad_angle_) * cs

        # BULLET ORIGIN
        position = Vector2(rect_x + offset_x, rect_y - offset_y)

        cdef int bullet_hell_angle = self.bullet_hell_angle

        for r in range(1):
            # CREATE 4 BULLETS SHOOT AT DIFFERENT ANGLE (SAME ORIGIN)
            # AT CONSTANT VELOCITY
            spr = Sprite()

            gl_all.add(spr)

            if PyObject_IsInstance(gl_all, LayeredUpdates):
                gl_all.change_layer(spr, layer_)

            self.shooting_angle_FX086 += bullet_hell_angle
            self.shooting_angle_FX086 %= 360

            spr.rad_angle       = self.shooting_angle_FX086 * DEG_TO_RAD
            spr.vec             = Vector2(<float>cos(spr.rad_angle) * velocity,
                                         -<float>sin(spr.rad_angle) * velocity)
            spr.image           = <object> PyList_GetItem(FX086, self.shooting_angle_FX086)
            spr.rect            = spr.image.get_rect(center=(position.x, position.y))
            spr.center          = position
            spr._blend          = BLEND_RGB_ADD
            spr._layer          = layer_
            spr.damage          = damage_
            spr.name            = 'FX086'
            gl_enemyshots_add(spr)
            vertex_bullet_append(spr)

            # LightEngine(gl,
            #             spr,
            #             array_alpha_     = RADIAL4_ARRAY_32x32_FAST,  # RADIAL4_ARRAY_128x128,
            #             fast_array_alpha_= RADIAL4_ARRAY_32x32_FAST,  # RADIAL4_ARRAY_64x64_FAST,
            #             intensity_       = 1.0,
            #             color_           = numpy.array([128, 128, 128],
            #             dtype=numpy.float32, copy=False),
            #             smooth_          = False,
            #             saturation_      = False,
            #             sat_value_       = 1.0,
            #             bloom_           = False,
            #             bloom_threshold_ = 128,
            #             heat_            = False,
            #             frequency_       = 1.0,
            #             blend_           = 0,
            #             timing_          = 0.0,
            #             fast_            = False,
            #             offset_x         = 0,
            #             offset_y         = 0)

    @property
    def waypoint(self):
        return self.__waypoint

    @waypoint.setter
    def waypoint(self, waypoint):
        if waypoint >= self.max_waypoint - 1:
            self.__waypoint = 0
            # Aircraft stopped
            self.vector.x, self.vector.y = (0, 0)
        else:
            self.__waypoint = waypoint

    cpdef update(self, args=None):

        cdef:
            int w2, h2, r, w, h
            float f_vol, volume
            float dt = self.dt
            gl = self.gl
            image = self.image
            image_copy = self.image_copy
            rect = self.rect
            int index = self.index
            p_rect = gl.player.rect
            clocking_index = self.clocking_index
            # COMPILE LOGIC VARIABLE
            bint is_list = \
                PyObject_IsInstance(image_copy, list)
            bint disruption_or_destruction = \
                self.disruption_status or self.destruction_status
            bint exhaust_running = \
                self.exhaust_instance is not None and self.exhaust_instance.alive()

        if gl.FRAME == self.start_frame:
            # self.blf = BossLifeBar(gl, self, 600, 10, 100, 150, layer_=-3, blend_=0)
            self.indicator = LifeLevelIndicator(self.gl, self, self.max_hp, self.hp)

        # THE AIRCRAFT START MOVING WHEN FRAME >= START_FRAME
        if gl.FRAME < self.start_frame:
            return

        if self.indicator is not None:
            self.indicator.life_update(self.hp)

        self.enemy_shadow()

        cdef:
            int rect_cx = rect.centerx
            int rect_cy = rect.centery
            object momentum = self.momentum
            object position = self.position
            float momentum_length = <float>round(momentum.length())

        if not disruption_or_destruction:

            if self.strategy == 'path':

                vec = self.is_waypoint_passed()

                if vec.length() != 0:

                    vec.normalize_ip()
                    position.x += vec.x
                    position.y += vec.y
                    rect_cx = int(position.x)
                    rect_cy = int(position.y)
                else:
                    self.vector = Vector2(<float>0, <float>0)

            # ELASTIC COLLISION
            if momentum_length > <float>1.0:

                position.x += momentum.x
                position.y += momentum.y

                rect_cx = <int>position.x
                rect_cy = <int>position.y

                reflect_vec = Vector2(momentum.x * -<float>1.0,
                                      momentum.y * -<float>1) / <float>10.0
                momentum.x += reflect_vec.x
                momentum.y += reflect_vec.y

        self.momentum.x = momentum.x
        self.momentum.y = momentum.y
        self.position.x = position.x
        self.position.y = position.y

        if self.is_bullet_reloading():
            self.create_bullet_hell(disruption_or_destruction, self._layer - 1, self.fx086_damage)

        if dt > self.timing:

            # GET THE ANGLE BETWEEN THE SPACESHIP AND THE PLAYER
            # TODO IMPLEMENT THE MAX_ROTATION / FRAME OTHERWISE SHIP WILL TURN
            # VERY FAST WHEN PLAYER IS PASSING BY

            if not disruption_or_destruction:
                self._rotation = get_angle(rect_cx, rect_cy,
                                           p_rect.centerx, p_rect.centery)

            image, rect = self.rot_center(
                <object> PyList_GetItem(image_copy, index),
                self._rotation, rect_cx, rect_cy)

            # if self.disruption_status:
            #     image = self.disruption_effect(image)

            # DISRUPTION EFFECT (APPLY TEXTURE TO SELF.IMAGE)
            if disruption_or_destruction:

                if self.alive():
                    position = Vector2(randRange(-<int>50, <int>50), randRange(-<int>50, <int>50))
                    for r in range(min(<int>(
                            self.destruction_timer * <float>1.0 / <float>100.0), 1)):
                        fire_particles_fx(
                            gl,
                            position_   = position + Vector2(self.rect.center),
                            vector_     = Vector2(randRangeFloat(-<float>1.0, <float>1.0),
                                                  randRangeFloat(-<float>1.0, -<float>5.0)),
                            images_     = PHOTON_PARTICLE_1,
                            layer_      = 0)

                image = self.disruption_effect(image)
                # SHOW EXPLOSIONS ON THE SPACESHIP HULL
                # CREATE HULL EXPLOSIONS
                position = Vector2(randRange(-rect.w >> 1, rect.w >> 1),
                                   randRange(-rect.h, rect.h))

                self.create_hull_explosions_fx(position.x, position.y)
                image = self.display_hull_explosions_fx(image)

            # QUAKE EFFECT
            if self.quake:
                self.spaceship_quake()
                # UPDATE THE RECT POSITION
                rect = self.rect
                rect_cx = self.rect.centerx
                rect_cy = self.rect.centery

            if self.destruction_status:

                # STOP THE SHIP EXHAUST SYSTEM
                self.stop_exhaust(exhaust_running)

                self.destruction_timer += 1

                # TRIGGER THE SPACESHIP EXPLOSION
                if self.destruction_timer > 200:
                    self.enemy_explosion()

                if self.explosion_frequency <= 0:

                    # self.gl.WOBBLY = 5 if self.gl.WOBBLY in (0, -5) else -5
                    self.gl.SHOCKWAVE = True

                    # CHOOSE AN EXPLOSION FROM A PRE DEFINED LIST
                    rnd_explosion = <object> PyList_GetItem(
                        G5V200_EXPLOSION_LIST,
                        randRange(0, PyList_Size(G5V200_EXPLOSION_LIST) - 1))

                    w = (<object> PyList_GetItem(rnd_explosion, 0)).get_width()
                    h = (<object> PyList_GetItem(rnd_explosion, 0)).get_height()
                    w2 = w >> 2
                    h2 = h >> 2

                    # RANDOMIZE EXPLOSION LOCATION (OFFSET)
                    position = Vector2(randRangeFloat(-w2, w2),
                                       randRangeFloat(-h2, h2))

                    # CREATE A FLASHING LIGHT EFFECT
                    Halo(gl_            = gl,
                         containers_    = gl.All,
                         images_        = RADIAL,
                         x              = position.x + rect_cx,
                         y              = position.y + rect_cy,
                         timing_        = 15,
                         layer_         = self._layer - 1,
                         blend_         = BLEND_RGB_ADD)

                    # PLAY AN EXPLOSION SOUND FROM A LIST OF SOUNDS
                    self.gl.SC_explosion.play(
                        sound_=<object> PyList_GetItem(
                            GROUND_EXPLOSION, randRange(0, PyList_Size(GROUND_EXPLOSION) - 1)),
                        loop_=False,
                        priority_=2,
                        volume_=gl.SOUND_LEVEL,
                        fade_out_ms=0,
                        panning_=True,
                        name_='EXPLOSIONS',
                        x_=rect.centerx)

                    # RANDOMIZE EXPLOSION FREQUENCY
                    self.explosion_frequency = randRange(5, 25)

                    # DISPLAY EXPLOSION
                    BindExplosion(containers_=gl.All,
                                  images_=rnd_explosion,
                                  gl_=gl,
                                  pos_x=position.x + rect_cx,
                                  pos_y=position.y + rect_cy,
                                  timing_=15,
                                  layer_=self._layer,
                                  blend_=BLEND_RGB_ADD)

                    rect_ = self.rect.copy()
                    rect_.center = position + Vector2(rect.center)

                    Halo(gl_        = gl,
                         containers_= gl.All,
                         images_    = G5V200_HALO_SPRITE12,
                         x          = rect_.centerx,
                         y          = rect_.centery,
                         timing_    = 4,
                         layer_     = self._layer - 1,
                         blend_     = 0) # pygame.BLEND_RGB_ADD)

                    # WILL ALLOW THE FUNCTION CALL spaceship_quake
                    self.quake = True

                    for r in range(10):
                        DebrisGenerator(gl_=gl,
                                        x_=rect_cx,
                                        y_=rect_cy,
                                        timing_=self.timing,
                                        _blend=BLEND_RGB_ADD,
                                        _layer=0)
                else:
                    self.explosion_frequency -= 1

            # if self.gl.FRAME % 100 == 0:
            #     self.add_ring()
            #     ...

            if self.clocking_status and not disruption_or_destruction:
                image = self.clocking_device(image, clocking_index)

            if is_list:
                if index < self.length1:
                    index += 1
                else:
                    index = 0

            dt = 0

        else:
            dt += gl.TIME_PASSED_SECONDS

        self.dt = dt
        self.index = index
        self.image = image
        self.rect = rect


        if self.is_bullet_ring_reloading():
            self.create_bullet_hell_ring(disruption_or_destruction,
                                         self._layer - 1, self.fx074_damage)



        # display_bullets(gl)

        # TESTING CLOCKING DEVICE
        # if gl.FRAME > 250:
        #     self.clocking_status = True
        #     self.clocking_index += 1 if clocking_index < 180 else 0

        # # TESTING EXPLOSIONS
        # if gl.FRAME > 800:
        #     self.destruction_status = True
        # self.pattern_countdown -= gl.TIME_PASSED_SECONDS

        # # TESTING DISRUPTION
        # if gl.FRAME > 2000:
        #     self.disruption_status = True
        #
        # # TESTING EXPLOSIONS
        # if gl.FRAME > 2500:
        #     self.destruction_status = True
        if len(VERTEX_FIRE_PARTICLES_FX) > 0:
            display_fire_particle_fx()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindSprite(Sprite):
    cdef:
        public int _blend, _layer
        public object image, rect
        object gl,
        int index, length, off_t
        float timing, dt
        bint loop, dependency, follow
        str event
        tuple offset

    def __init__(self,
                 images_,
                 containers_,
                 object_,
                 gl_,
                 offset_          = None,
                 float timing_    = 60.0,
                 int layer_       = 0,
                 bint loop_       = False,
                 bint dependency_ = False,
                 bint follow_     = False,
                 int blend_       = 0,
                 str event_       = None
                 ):

        Sprite.__init__(self, containers_)

        self._blend = blend_
        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.images_copy = images_.copy()

        if PyObject_IsInstance(images_, list):
            self.image = <object> PyList_GetItem(images_, 0)
            self.length = <object> PyList_Size(images_) - <unsigned char>2
        else:
            self.image = images_
            self.length = 0

        self.object_ = object_
        self.offset = offset_

        cdef:
            tuple center
            obj_rect = object_.rect

        if offset_ is not None:
            center = (obj_rect.centerx + offset_[0],
                      obj_rect.centery + offset_[1])
            if offset_[0] != 0:
                self.off_t = <int> (<float>RAD_TO_DEG * <float> atan(
                    <float> offset_[1] / <float> offset_[0]))
            else:
                self.off_t = 0
        else:
            center = obj_rect.center

        self.rect = self.image.get_rect(
            center=(center[0], center[1]))

        self.dt = 0
        self.index = 0
        self.loop = loop_
        self.gl = gl_
        self.dependency = dependency_
        self.event = event_
        self.follow = follow_

        # IF THE FPS IS ABOVE SELF.TIMING THEN
        # SLOW DOWN THE UPDATE
        self.timing = timing_

        # RECORD LAST VALUE (OBJECT ANGLE)
        # ALGORITHMS SPEED CAN BE IMPROVED
        # WHEN OBJECT ANGLE IS CONSTANT FROM
        # ONE FRAME TO ANOTHER.
        self.previous_rotation = 1

    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindSprite):
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    cdef int get_angle(self, int off_x, int off_y)nogil:
        """
        RETURN THE ANGLE OF THE OFFSET POINT RELATIVE TO THE PARENT CENTER

        :param off_x: integer; Offset x coordinate 
        :param off_y: integer; Offset y coordinate
        :return: integer; return an integer, angle of the offset relative to the parent center 
        """

        if off_x == 0:
            # ATAN(OFF_Y/ OFF_X WITH OFFS_X = 0) -> INF
            # AVOID DIVISION BY ZERO AND DETERMINE ANGLE -90 OR 90 DEGREES
            return <int> (<unsigned char>90 * copysign(1, off_x))
        else:
            return self.off_t

    cdef c_tuple get_offset(self, int angle, float hypo, int object_rotation)nogil:
        """
        RECALCULATE THE OFFSET POSITION (COORDINATES) WHEN PARENT OBJECT IS ROTATING

        :param angle          : integer; correspond to the offset's angle like
         tan(offset_y/offset_x), 
                                offset is equivalent to a single point of coordinate
                                 (offset_x, offset_y) or, 
                                (obj center_x + offset_x, obj center_y + offset_y). 
                                Angle between the center of the object and the offset coordinates.    
        :param hypo           : float; Distance between the object's center 
        and the offset coordinates
        :param object_rotation: integer; Actual sprite angle (orientation) 
        :return               : Return a tuple of coordinates (new offset position) / projection
        """

        cdef:
            float a
            c_tuple ctuple

        a = <float>DEG_TO_RAD * (-<float>180.0 + object_rotation)
        ctuple.primary = <int> (<float>cos(a) * <float>hypo)
        ctuple.secondary = <int> (-<float>sin(a) * <float>hypo)

        return ctuple

    cdef tuple rot_center(self, image_, int angle_, rect_):
        """
        RETURN A ROTATED SURFACE AND ITS CORRESPONDING RECT SHAPE

        :param image_: pygame Surface; 
        :param angle_: integer; angle in degrees 
        :param rect_ : Rect; rectangle shape
        :return      : tuple 
        """
        new_image = rotozoom(image_, angle_, <float>1.0)
        return new_image, new_image.get_rect(center=rect_.center)

    cdef clocking_device(self, image, clock_value):
        """
        CONTROL IMAGE OPACITY 

        :param image      : Surface; image to modify  
        :param clock_value: Alpha value to use 
        :return           : return a pygame surface 
        """
        return make_transparent32(image, clock_value).convert_alpha()

    @cython.cdivision(False)
    cpdef update(self, args=None):

        if self.dependency and not self.object_.alive():
            self.kill()
            self.gl.All.remove(self)

        cdef:
            images_copy = self.images_copy
            image = self.image
            int index = self.index
            object_ = self.object_
            object_rect = object_.rect
            int length = self.length
            rect = self.rect
            int obj_x = object_rect.centerx
            int obj_y = object_rect.centery
            int off_x = self.offset[0] if self.offset is not None else 0
            int off_y = self.offset[1] if self.offset is not None else 0
            bint loop = not self.loop
            float hypo
            c_tuple convert_tuple

        if PyObject_HasAttr(object_, '_rotation'):
            object_rotation = object_._rotation


        if self.dt > self.timing:

            if PyObject_IsInstance(images_copy, list):

                image = <object> PyList_GetItem(images_copy, index)
                if object_.clocking_status:
                    image = self.clocking_device(image, object_.clocking_index * <unsigned char>2)

                if self.follow:
                    # TODO change 90 to a variable corresponding to the image orientation
                    image, rect = self.rot_center(
                        image, object_rotation + <unsigned char>90, rect)

            if index > length:
                if loop:
                    self.kill()
                index = 0
            else:
                index += 1

            self.index = index

            # SPRITE HAS OFFSET FROM THE CENTER
            if self.offset is not None:

                # SPRITE FOLLOW PARENT ROTATE_INPLACE
                if self.follow and PyObject_HasAttr(object_, '_rotation'):

                    # IF PREVIOUS VALUE IS EQUAL SKIP ALL THE CALCULATION
                    # if self.previous_rotation != object_rotation:

                    # ASSUMING THAT object_._rotation is a variable
                    # and can change during the game play
                    # ASSUMING THAT the self.image can rotate (otherwise self.rect is constant)
                    hypo = <float> hypot(off_x, off_y)
                    angle = self.get_angle(off_x, off_y) % <int>360
                    convert_tuple = self.get_offset(angle, hypo, object_rotation)
                    # ADJUST THE OBJECT CENTER COORDINATES AFTER PARENT OBJECT ROTATION.
                    rect = image.get_rect(
                        center=(obj_x + convert_tuple.primary,
                                obj_y + convert_tuple.secondary))

                    # else:
                    #     rect = image.get_rect(
                    #                 center=(obj_x + off_x,
                    #                         obj_y + off_y))

                    # UPDATE VALUE
                    # self.previous_rotation = object_rotation

                else:
                    rect = image.get_rect(
                        center=(obj_x + off_x,
                                obj_y + off_y))
            else:
                rect = image.get_rect(
                    center=object_rect.center)

            self.rect = rect
            self.image = image
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindShadow(Sprite):
    cdef:
        public int _blend, _layer
        public object image, rect
        object gl,
        float timing, dt
        bint dependency
        tuple offset
        list rotation_buffer

    def __init__(self,
                 containers_,
                 object_,
                 gl_,
                 offset_               = None,
                 list rotation_buffer_ = None,
                 float timing_         = 16.0,
                 int layer_            = 0,
                 bint dependency_      = False,
                 int blend_            = 0,
                 ):
        """
        DROP SHADOW AT A GIVEN OFFSET (BELOW OBJECT)

        :param containers_      : Sprite container
        :param object_          : Parent object (class)
        :param gl_              : Constants / variables class
        :param offset_          : tuple, offset (x, y) from parent rect.center
        :param rotation_buffer_ : Buffer containing rotated shadow surface, 0 to 360 degrees.
        :param timing_          : Timer
        :param layer_           : Layer
        :param dependency_      : Kill the sprite if parent is destroyed
        :param blend_           : Additive mode
        """

        Sprite.__init__(self, containers_)

        self._blend = blend_
        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)
        assert hasattr(object_, 'shadow'), \
            '\nParent object missing attribute shadow'
        self.image = object_.shadow
        self.object_ = object_
        assert hasattr(object_, '_rotation'), \
            '\nParent object missing attribute _rotation'
        assert hasattr(object_, 'last_rotation'), \
            '\nParent object missing attribute last_rotation'
        self.offset = offset_

        cdef:
            tuple center
            obj_rect = object_.rect

        if offset_ is not None:
            center = (obj_rect.centerx + offset_[0],
                      obj_rect.centery + offset_[1])
        else:
            center = obj_rect.center

        self.rect = self.image.get_rect(
            center=(center[0], center[1]))

        self.dt = 0
        self.gl = gl_
        self.dependency = dependency_
        self.rotation_buffer = rotation_buffer_

        # IF THE FPS IS ABOVE SELF.TIMING THEN
        # SLOW DOWN THE UPDATE
        self.timing = <float>1000.0 / timing_


        self.last_rotation = 0

    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindSprite):
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    @cython.binding(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(False)
    @cython.profile(False)
    cdef rot_center(self, int angle_):
        """
        ROTATE THE ENEMY SPACESHIP IMAGE  

        :param angle_: integer; Angle in degrees 
        :return: Return a tuple (surface, rect)
        """
        return <object> PyList_GetItem(self.rotation_buffer, (angle_ + <int>360) % <int>360)

    @cython.binding(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    @cython.profile(False)
    cpdef update(self, args=None):

        cdef:

            image = self.image
            int obj_x = self.object_.rect.centerx
            int obj_y = self.object_.rect.centery
            int off_x = self.offset[0] if self.offset is not None else 0
            int off_y = self.offset[1] if self.offset is not None else 0
            object_ = self.object_
            float dt = self.dt

        if self.dependency and not self.object_.alive():
            self.kill()

        if dt > self.timing:

            # ONLY UPDATE IMAGE IF PARENT IMAGE HAS ROTATED
            if self.rotation_buffer:
                if self.last_rotation != object_._rotation:
                    image = self.rot_center(object_._rotation)
                self.last_rotation = object_._rotation
            dt = 0

        self.rect = image.get_rect(center=(obj_x + off_x, obj_y + off_y))
        self.image = image

        dt += self.gl.TIME_PASSED_SECONDS
        self.dt = dt

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindExplosion(Sprite):
    cdef:
        public int _blend, _layer
        public object image, rect
        object gl,
        float timing, dt
        int pos_x, pos_y, index
        list images

    def __init__(self,
                 containers_,
                 list images_,
                 gl_,
                 int pos_x,
                 int pos_y,
                 float timing_         = 16.0,
                 int layer_            = 0,
                 int blend_            = 0,
                 ):
        """

        :param containers_:
        :param gl_:
        :param timing_:
        :param layer_:
        :param blend_:
        """

        Sprite.__init__(self, containers_)

        self._blend = blend_
        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)
        assert PyObject_IsInstance(images_, list), \
            '\nArgument images must be a python list'

        self.images = images_
        self.length = <int> PyList_Size(images_) - <unsigned char>1
        self.image = <object> PyList_GetItem(images_, 0)
        self.rect = self.image.get_rect(center=(pos_x, pos_y))
        if not self.rect.colliderect(gl_.screenrect):
            self.kill()
            return
        self.dt = 0
        self.gl = gl_
        self.index = 0

        # IF THE FPS IS ABOVE SELF.TIMING THEN
        # SLOW DOWN THE UPDATE
        self.timing = timing_


    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindSprite):
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    @cython.binding(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    @cython.profile(False)
    cpdef update(self, args=None):

        cdef:
            float dt = self.dt

        if dt > self.timing:

            self.image = <object> PyList_GetItem(self.images, self.index)
            self.index += 1
            if self.index >= self.length:
                self.kill()

            dt = <float>0.0
        dt += self.gl.TIME_PASSED_SECONDS
        self.dt = dt

