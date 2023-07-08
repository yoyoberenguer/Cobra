# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True
# encoding: utf-8

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, Rect, BLEND_RGB_ADD
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface,\
        blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL
    from pygame.transform import scale, smoothscale, rotate, rotozoom
except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

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

from Textures import FLARE, PARTICLES_SPRITES

from libc.math cimport atan2
from Sprites cimport Sprite
from Sprites cimport LayeredUpdates

cdef extern from 'Include/randnumber.c':
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;


cdef float  RAD_TO_DEG = 180.0 / 3.14159265359
cdef float SIXTYFPS = 1.0/60.0 * 1000

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class ShootingStar(Sprite):

    cdef:
        public object image, rect, position
        object gl, group, speed
        int w, h,
        float timing, dt
        public int _layer, _blend

    def __init__(self, image_, group_, gl_, int layer_=-1, float timing_ = SIXTYFPS):
        """
        DISPLAY SHOOTING STARS AT RANDOM TIME AND POSITIONS

        :param image_: pygame.Surface; Shooting Star texture
        :param group_: Sprite group; default VERTEX_SHOOTING_STAR, GL.All
        :param gl_   : class; global variable/constants
        :param layer_: Sprite layer default -1 (below the HUD sprites)
        :param timing_: default 60 FPS cap (whatever the main loop speed is)
        """

        Sprite.__init__(self, group_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self._layer = layer_

        self.images_copy    = image_.copy()
        self.image          = <object>PyList_GetItem(image_, 0) \
            if PyObject_IsInstance(image_, list) else image_

        self.w, self.h      = pygame.display.get_surface().get_size()
        self.position       = Vector2(randRange(0, self.w), randRange(-self.h, 0))
        self.rect           = self.image.get_rect(midbottom=self.position)
        self.speed          = Vector2(randRangeFloat(-<float>30.0, <float>30.0), <float>60.0)
        self.image          = rotozoom(self.image, -<float>270.0 - <float>atan2(self.speed.y,
                                       self.speed.x) * <float>RAD_TO_DEG, 1)
        self._blend         = BLEND_RGB_ADD
        self.timing         = timing_
        self.gl = gl_
        self.dt = 0

    cpdef update(self, args=None):

        if self.dt > self.timing:

            if self.rect.centery > self.h:
                self.kill()

            self.rect = self.image.get_rect(center=self.position)
            self.position += self.speed

            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS


cdef int FRAME_ACCEL = 300
cdef int FRAME_DEC = 250

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BrightStars(Sprite):

    cdef:
        public object image, rect, position
        public int _layer, _blend
        object bv, gl, pos, image_copy, speed
        float acc_speed, timing, dt
        int w, h, index
        bint acceleration

    def __init__(self, group_,
                 bv_,
                 gl_,
                 pos_=None,
                 int layer_=-10,
                 bint acceleration_ = False,
                 float acc_speed_ = 6.0,
                 float timing_ = SIXTYFPS
                 ):

        """

        :param group_: pygame sprite group to assign sprite
        :param bv_   : Vector2; background speed
        :param gl_   : class; global variables / constants
        :param pos_  : None or tuple (width, height) defining the range where the stars can spawn
        :param layer_: integer; Sprite layer
        :param acceleration_: bool;  acceleration True | False, allow the sprite to speed up and match the
        background speed
        :param acc_speed_: float; acceleration value default 6.0
        :param timing_: float; CAP the sprite animation at 60 FPS if the main loop is > 60 FPS
        """
        Sprite.__init__(self, group_)

        # change sprite layer
        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self._layer = layer_

        self.images_copy = PARTICLES_SPRITES.copy()
        self.image = <object>PyList_GetItem(self.images_copy, 0) if \
            PyObject_IsInstance(PARTICLES_SPRITES, list) else self.images_copy

        self.w, self.h = pygame.display.get_surface().get_size()

        if pos_ is not None:
            self.position = Vector2(randRange(0, pos_.w), randRange(0, pos_.h)
            if pos_.h > 0 else randRange(pos_.h, 0))
        else:
            self.position = Vector2(randRange(0, self.w), randRange(0, self.h))

        self.rect         = self.image.get_rect(midbottom=self.position)
        self.index        = 0
        self.speed        = bv_
        self.acceleration = acceleration_
        self.acc_speed    = acc_speed_
        self.gl           = gl_
        self.timing       = timing_
        self.dt           = 0
        self._blend       = BLEND_RGB_ADD

    cpdef update(self, args=None):

        cdef:
            int index   = self.index
            images_copy = self.images_copy
            float acc_speed   = self.acc_speed

        if self.dt > self.timing:

            # EXPLOSION EVENT
            if randRange(0, 10000) > 9990:
                if not images_copy == FLARE:
                    images_copy = FLARE
                    index = <int>0

            else:
                self.image = <object>PyList_GetItem(images_copy, index)

            if index < len(images_copy) - <unsigned char>1:
                index += <int>1
            else:
                index = <int>0

            if self.rect.centery > self.h:
                self.kill()

            if self.acceleration:
                if self.gl.FRAME < FRAME_ACCEL:
                    self.position += self.speed * acc_speed
                    # START TO DECELERATE
                    if self.gl.FRAME > FRAME_DEC:
                        acc_speed -= <float>0.1
                        if  acc_speed < <float>1.0:
                            acc_speed = <float>1.0

            self.rect = self.image.get_rect(center=self.position)
            self.position += self.speed
            self.dt = <float>0.0

        self.dt += self.gl.TIME_PASSED_SECONDS

        self.index = index
        self.acc_speed = acc_speed