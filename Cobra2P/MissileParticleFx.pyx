# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# CYTHON IS REQUIRED

try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject_CallFunctionObjArgs, PyObject, \
        PyList_SetSlice, PyObject_HasAttr, PyObject_IsInstance, \
        PyObject_CallMethod, PyObject_CallObject
    from cpython.dict cimport PyDict_DelItem, PyDict_Clear, PyDict_GetItem, PyDict_SetItem, \
        PyDict_Values, PyDict_Keys, PyDict_Items
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size, PyList_SetItem
    from cpython.object cimport PyObject_SetAttr
except ImportError:
    raise ImportError("\n<Cython> library is missing on your system."
                      "\nTry: \n   C:\\pip install cython on a window command prompt.")

# C LIBRARY
from libc.math cimport cos, sin, atan2, round

try:
    import pygame
    from pygame.math import Vector2
    from pygame import Rect, transform, surfarray, BLEND_RGB_ADD, HWSURFACE, display, BLEND_RGB_MAX
    from pygame.transform import smoothscale
except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
                      "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:
    from Sprites cimport Sprite
    from Sprites import Group
except ImportError:
    raise ImportError("\nSprites.pyd missing!.Build the project first.")

#
# cdef extern from 'Include/vector.c':
#
#     struct vector2d:
#         float x;
#         float y;
#
#     void vecinit(vector2d *v, float x, float y)nogil;
#     float vlength(vector2d *v)nogil;
#     float randRangeFloat(float lower, float upper)nogil;
#     int randRange(int lower, int upper)nogil;


from SpriteSheet cimport sprite_sheet_fs8
import numpy

# TODO THIS CAN BE MOVED TO TEXTURES
MISSILE_TRAIL1 = sprite_sheet_fs8('Assets/Graphics/Exhaust/2/Smoke_trail_2_64x64.png', 64, 6, 6)
func = numpy.linspace(0.8, 1.2, len(MISSILE_TRAIL1))
i = 0
for surface in MISSILE_TRAIL1:
    MISSILE_TRAIL1[i] = smoothscale(surface,
                           (int(surface.get_width() * func[i]),
                            int(surface.get_height() * func[i])))
    i += 1

# TODO THIS CAN BE IMPORTED FROM CONSTANTS
DEF M_PI       = 3.14159265358979323846
DEF M_2PI      = 2 * M_PI
DEF M_PI2      = 3.14159265358979323846 / 2.0
DEF DEG_TO_RAD = M_PI / 180.0
DEF RAD_TO_DEG = 1.0 / DEG_TO_RAD

cdef float DEG_TO_RAD_ = <float>DEG_TO_RAD
cdef float RAD_TO_DEG_ = <float>RAD_TO_DEG


VERTEX_ARRAY_MP = []

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef transparency(image_, int alpha_):
    """
    CONTROL THE SPRITE/IMAGE TRANSPARENCY 
    USE PYGAME METHOD SET_ALPHA

    :param image_: pygame.Surface; Image to control 
    :param alpha_: integer; Alpha value to set to the surface
    :return: tuple; Image with alpha changed and new alpha value (decreased)
    """
    image_.set_alpha(alpha_)
    with nogil:
        alpha_ -= 10
        if alpha_ < 0:
            alpha_ = 0
    return image_, alpha_


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef float get_angle(vector2d object1, vector2d object2)nogil:
    """
    GET THE RADIAN ANGLE BETWEEN TWO OBJECTS

    :param object1: Vector2; Object 1 location (x1, y1)
    :param object2: Vector2; Object 2 location (x2, y2)
    :return: Return the angle between object1 and object2 (angle in radian)
    """
    cdef float dx = object2.x - object1.x
    cdef float dy = object2.y - object1.y
    return -<float> atan2(dy, dx)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline vector2d projection_radian(vector2d point_, vector2d rect_, float angle_)nogil:
    """
    CHANGE ROTATE THE SPRITE IMAGE IN FUNCTION OF THE MISSILE TRAJECTORY

    :param point_ : Vector2; Exhaust position
    :param rect_  : Vector2; missile center coordinates 
    :param angle_ : float; missile current heading
    :return: 
    """
    cdef float p_angle = -<float> atan2(point_.y, point_.x)
    cdef float length = vlength(&point_)
    cdef float rotation = p_angle + angle_ - M_PI2
    cdef vector2d v;
    # CREATE A VECTOR2D
    # FASTER THAN PYGAME VECTOR2 AND ALLOW US TO
    # PLACE A INLINE/NOGIL ON THE METHOD
    vecinit(&v, rect_.x + <float> cos(rotation) * length, rect_.y - <float> sin(rotation) * length)
    return v

cdef VERTEX_ARRAY_APPEND = VERTEX_ARRAY_MP.append
cdef VERTEX_ARRAY_REMOVE = VERTEX_ARRAY_MP.remove


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class MissileParticleFx_improve:

    # cdef:
    #     int length_1, alpha, _layer, index, _blend,
    #     last_frame, n
    #     object images, image, rect, vector, gl
    #     list VERTEX_ARRAY_MP
    #     float timing, dt, timer
    #     vector2d position

    def __init__(self, gl_, rect_, vector_, int layer_, int angle_, exhaust_pos_,
                 list texture_=MISSILE_TRAIL1, int mode_=BLEND_RGB_ADD, float timing_=60.0):
        """
        CREATE MISSILE PROPULSION PARTICLE EFFECT

        :param gl_          : Class; Global constant
        :param rect_        : tuple; Missile rectangle center
        :param vector_      : Vector2; Missile trajectory
        :param layer_       : integer; Missile layer level
        :param angle_       : integer; Missile orientation angle in degrees
        :param exhaust_pos_ : Vector2; Missile exhaust position
        :param texture_     : dict   ; dict containing all the textures and rects for the
        particle effect.
        :param timing_      : integer; Value in FPS. Control the speed of the animation
        (by default the animation
        will run at 60 FPS)
        """

        self.length_1         = len(texture_) - 1
        self.images           = texture_
        self.image            = texture_[0]
        self.rect             = self.image.get_rect()
        self.alpha            = 255
        self._layer           = layer_
        self.vector           = -vector_ * randRangeFloat(<float>0.0, <float>0.1)
        self.index            = 0
        self._blend           = mode_

        cdef vector2d exhaust_pos_v, rect_v, v;
        vecinit(&exhaust_pos_v, exhaust_pos_.x, exhaust_pos_.y)
        vecinit(&rect_v, rect_.x, rect_.y)
        v = projection_radian(exhaust_pos_v, rect_v, angle_ * DEG_TO_RAD)

        cdef vector2d position
        vecinit(&position, v.x, v.y)
        self.position = position
        VERTEX_ARRAY_APPEND(self)
        self.gl = gl_

        # REFRESH THE LIST AT 60 FPS (DEFAULT VALUE)
        self.timing = timing_
        # TIMER TO CAP THE FRAME RATE AT 60 FPS 1000.0 / 60.0 = 16.667 ms
        self.timer  = <float>1000.0 / self.timing
        # TIME VARIABLE
        self.dt     = 0
        self.rect.center = (v.x, v.y)

        # LIST INDEX INCREMENT
        self.n = <int> round(self.length_1 / <float>19.0)

    cpdef update(self, screen, screen_rect):
        """
        METHOD CALLED EVERY FRAMES FROM THE MAIN LOOP 
        ROLE : UPDATE THE PARTICLE EFFECT 

        :param screen_rect: pygame.Rect; display rect shape
        :param screen: pygame.Rect; Active display dimensions
        :return: None
        """

        cdef:
            screen_blit = screen.blit
            int index   = self.index
            image       = self.image
            rect        = self.rect
            list images = self.images
            int time_passed_seconds = self.gl.TIME_PASSED_SECONDS
            vector2d position, vector
            _blend      = self._blend
            float timing = self.timing
            int n       = self.n


        vecinit(&position, self.position.x, self.position.y)
        vecinit(&vector, self.vector.x, self.vector.y)

        if self.rect.colliderect(screen_rect):

            if index < self.length_1:
                try:
                    image = images[index]
                    rect  = image.get_rect()
                except IndexError:
                    # IGNORE
                    ...
                rect.center = (position.x, position.y)
                self.rect = rect

                if _blend == BLEND_RGB_MAX:
                    if index < randRange(<int>3, <int>6):
                        _blend = 1  # pygame.BLEND_RGB_ADD

                PyObject_CallFunctionObjArgs(screen_blit,
                                             <PyObject*> image,  # image
                                             <PyObject*> rect,  # destination
                                             <PyObject*> None,  # Area
                                             <PyObject*> _blend,  # special_flags
                                             NULL)

                self.position.y += vector.y
                self.position.x += vector.x

                # IF THE FPS IS ABOVE SELF.TIMING THEN
                # SLOW DOWN THE PARTICLE ANIMATION
                if self.gl.MAXFPS > timing:
                    if self.dt > self.timer:
                        index += randRange(n - 1, n + 1)
                        self.dt = 0
                # FPS IS PROBABLY 60 FPS
                else:
                    index += randRange(n - 1, n + 1)

                self.index = index

                # LINE BELOW WORKS ONLY WITHOUT ADDITIVE MODES.
                # self.images[index][0], self.alpha =\
                # transparency(self.images[index][0], self.alpha)

            else:
                VERTEX_ARRAY_REMOVE(self)

        else:
            VERTEX_ARRAY_REMOVE(self)

        self.dt += time_passed_seconds


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
cdef class MParticleFX(object):

    def __init__(self, gl_, rect_, vector_, int layer_, int angle_,
                 exhaust_pos_, dict texture_, int mode_, float timing_=60.0):
        """
        CREATE MISSILE PROPULSION PARTICLE EFFECT

        :param gl_          : Class; Global constant
        :param rect_        : tuple; Missile rectangle center
        :param vector_      : Vector2; Missile trajectory
        :param layer_       : integer; Missile layer level
        :param angle_       : integer; Missile orientation angle in degrees
        :param exhaust_pos_ : Vector2; Missile exhaust position
        :param texture_     : dict   ; dict containing all the textures and rects for the particle effect.
        :param timing_      : integer; Value in FPS. Control the speed of the animation (by default the animation
        will run at 60 FPS)
        """

        self.length_1 = <int> len(texture_) - 1
        self.images = texture_
        self.image, self.rect = texture_[ 0 ]
        # self.rect = self.image.get_rect(center=(rect_.x, rect_.y))
        self.alpha = 255
        self._layer = layer_
        self.vector = -vector_ * randRangeFloat(0, 0.1)
        self.index = 0
        self._blend = mode_
        cdef vector2d exhaust_pos_v, rect_v, v;
        vecinit(&exhaust_pos_v, exhaust_pos_.x, exhaust_pos_.y)
        vecinit(&rect_v, rect_.x, rect_.y)
        v = projection_radian(exhaust_pos_v, rect_v, angle_ * DEG_TO_RAD_)
        cdef vector2d position
        vecinit(&position, v.x, v.y)
        self.position = position
        VERTEX_ARRAY_MP.append(self)
        self.gl = gl_

        # REFRESH THE LIST AT 60 FPS (DEFAULT VALUE)
        self.timing = timing_

        # TIMER TO CAP THE FRAME RATE AT 60 FPS 1000.0 / 60.0 = 16.667 ms
        self.timer = <float> 1000.0 / self.timing

        # TIME VARIABLE
        self.dt = <float> 0.0

        self.rect.center = (v.x, v.y)

        # LIST INDEX INCREMENT
        self.n = <int> round(self.length_1 / <float> 19.0)

        # Rect representing the space for the missile, beyond these rect limits the
        # sprite will be killed.
        self.rr = self.gl.screenrect.inflate(800, 1024)
        self.rr[ 1 ] = 0

    cpdef update(self, screen):
        """
        METHOD CALLED EVERY FRAMES FROM THE MAIN LOOP 
        ROLE : UPDATE THE PARTICLE EFFECT 

        :param screen: pygame.Rect; Active display dimensions
        :return: None
        """

        cdef:
            screen_blit = screen.blit
            int index = self.index
            image = self.image
            dict images = self.images
            int time_passed_seconds = self.gl.TIME_PASSED_SECONDS
            vector2d position, vector
            _blend = self._blend
            float timing = self.timing
            int n = self.n

        vecinit(&position, self.position.x, self.position.y)
        vecinit(&vector, self.vector.x, self.vector.y)

        if self.rect.colliderect(self.rr):

            if index < self.length_1:
                try:
                    image, rect = images[ index ]
                except IndexError:
                    # IGNORE
                    ...
                rect.center = (position.x, position.y)
                self.rect = rect

                if _blend == pygame.BLEND_RGB_MAX:
                    if index < randRange(3, 6):
                        _blend = 1  # pygame.BLEND_RGB_ADD

                # _blend = pygame.BLEND_RGBA_ADD

                PyObject_CallFunctionObjArgs(screen_blit,
                                             <PyObject *> image,  # image
                                             <PyObject *> rect,  # destination
                                             <PyObject *> None,  # Area
                                             <PyObject *> _blend,  # special_flags
                                             NULL)

                # LINE BELOW WORKS ONLY WITHOUT ADDITIVE MODES.
                # self.images[index][0], self.alpha = \
                #     set_transparency(self.images[index][0], self.alpha)

                self.position.y += vector.y
                self.position.x += vector.x

                # IF THE FPS IS ABOVE SELF.TIMING THEN
                # SLOW DOWN THE PARTICLE ANIMATION
                if self.gl.MAXFPS > timing:
                    if self.dt > self.timer:
                        index += randRange(n - 1, n + 1)
                        self.dt = 0
                # FPS IS PROBABLY 60 FPS
                else:
                    index += randRange(n - 1, n + 1)

                self.index = index

            else:
                VERTEX_ARRAY_MP.remove(self)

        else:
            VERTEX_ARRAY_MP.remove(self)

        self.dt += self.gl.TIME_PASSED_SECONDS
