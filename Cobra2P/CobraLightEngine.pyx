# cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from pygame.surfarray import pixels3d
from pygame.transform import scale, scale2x
from pygame import BLEND_RGB_ADD, Surface

from Sprites cimport Sprite
from Sprites cimport LayeredUpdates

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
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

cimport numpy as np


from LIGHTS cimport area24_c
from Textures import JETLIGHTCOLOR, JETLIGHT_ARRAY, JETLIGHT_ARRAY_FAST

cdef float ONE_255 = 1.0 / 255.0


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline int crop_x(int lw, int lw2, int sw, int x)nogil:
    if sw < lw and x <= lw2:
        xx = 0
    else:
        xx = x - lw2
    return xx


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline int crop_y(int lh, int lh2, int sh, int y)nogil:
    if sh < lh and y <= lh2:
        yy = 0
    else:
        yy = y - lh2
    return yy


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline void aircraft_light(object gl_,
                          object obj_,
                          bint fast_            = False,
                          int offset_x          = <int>0,
                          int offset_y          = <int>0,
                          color_                = JETLIGHTCOLOR,
                          array_alpha_          = JETLIGHT_ARRAY,
                          fast_array_alpha_     = JETLIGHT_ARRAY_FAST,
                          float intensity_      = <float>7.0,
                          bint smooth_          = False,
                          bint saturation_      = False,
                          float sat_value_      = <float>0.35,
                          int bloom_            = False,
                          unsigned char bloom_threshold_ = <unsigned char>150,
                          bint heat_            = False,
                          float frequency_      = <float>1.0
                          ):
    """
    Display a light effect ahead of the aircraft.


    :param gl_     : class containing all the variables/constants
    :param obj_    : Sprite; Object to use for reference (player)
    :param fast_   : bool; True|False; True allow fast processing (all the surfaces are scaled down)
    :param offset_x: If the light has an offset from the player rect centerx
    :param offset_y: if the light has an offset from the player rect centery
    :param color_  : Light coloration 1d buffer containing RGB values normalized
    :param array_alpha_ :  2d array shape [:, :] containing alpha values
    :param fast_array_alpha_ : 2d array shape [:, :] containing alpha values (array downscale x2)
    :param frequency_ : float; Value for the heat effect
    :param heat_      : boolean; True | False allow the heat effect
    :param bloom_threshold_ : unsigned short; determine the bloom threshold. Increase brightness of the light
    effect when values are low and decrease the brightness for high values. Default is 150
    :param bloom_: boolean; True | False allow the bloom effect
    :param sat_value_   : float; Saturation value [-1.0 ... 1.0], value below zero will cause the light to absorb
    colors (grayscale effect) and values above zero will create light effect with brighter colors (saturate colors)
    :param saturation_  : boolean; True | False. Allow the saturation effect
    :param smooth_      : boolean; True | False, Allow to blur the light effect (smmothing effect)
    :param intensity_   : float; Control the light intensity
    :return: Void
    """

    if not (obj_.alive() and gl_.aircraft_lights):
        return

    cdef:
        int x ,y, sw, sh, xx, yy, w, h, lw, lh, lw2, lh2
        gl_screen       = gl_.screen
        gl_screen_blit  = gl_screen.blit
        player_rect     = obj_.rect

    w = gl_screen.get_width()
    h = gl_screen.get_height()

    lw, lh = array_alpha_.shape[:2]
    lw2 = lw >> 1
    lh2 = lh >> 1

    x = player_rect.centerx + offset_x
    y = player_rect.centery + offset_y

    lit_surface, sw, sh = \
        area24_c(x >> 1 if fast_ else x,
                 y >> 1 if fast_ else y,
                 pixels3d(scale(gl_screen, (w >> 1, h >> 1))) if fast_ else pixels3d(gl_screen),
                 fast_array_alpha_ if fast_ else array_alpha_,
                 intensity       = intensity_,
                 color           = JETLIGHTCOLOR,
                 smooth          = smooth_,
                 saturation      = saturation_,
                 sat_value       = sat_value_,
                 bloom           = bloom_,
                 bloom_threshold = bloom_threshold_,
                 heat            = heat_,
                 frequency       = frequency_)
    if fast_:
        lit_surface = scale2x(lit_surface).convert()

        sw = sw * 2
        sh = sh * 2
    else:
        lit_surface = lit_surface.convert()

    xx = crop_x(lw, lw2, sw, x)
    yy = crop_y(lh, lh2, sh, y)

    cdef tuple coords = (xx, yy)

    PyObject_CallFunctionObjArgs(
        gl_screen_blit,
        <PyObject *> lit_surface,
        <PyObject *> coords,
        <PyObject *> None,
        <PyObject *> BLEND_RGB_ADD,
        NULL)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class LightEngine(Sprite):

    cdef:
        public object image, rect
        bint saturation, bloom, heat, smooth
        public int _blend, _layer
        float intensity, sat_value, frequency, timing, dt
        int offset_x, offset_y
        object dummy, gl, lalpha
        unsigned char bloom_threshold
        long long int _id


    def __init__(self,
                 gl_,
                 dummy_,
                 np.ndarray[np.uint8_t, ndim=2] array_alpha_,
                 np.ndarray[np.uint8_t, ndim=2] fast_array_alpha_,
                 float intensity_ = <float>7.0,
                 color_           = JETLIGHTCOLOR,
                 bint smooth_     = False,
                 bint saturation_ = False,
                 float sat_value_ = <float>1.0,
                 bint bloom_      = False,
                 unsigned char bloom_threshold_ = <unsigned char>128,
                 bint heat_       = False,
                 float frequency_ = <float>1.0,
                 int blend_       = BLEND_RGB_ADD,
                 float timing_    = <float>16.0,
                 int offset_x     = <int>0,
                 int offset_y     = <int>0,
                 bint fast_       = False):
        """
        Create a light effect around a specific object (dummy object)

        :param gl_              : class; Global variable / constants
        :param dummy_           : class; Class holding the object position (rect position)
        :param array_alpha_     : numpy.ndarray; Array containing the alpha channel values for the light model
        :param fast_array_alpha_: numpy.ndarray; Array containing the alpha channel values for the light model, this
        array is twice smaller than the above array
        :param intensity_       : float; Light intensity value
        :param color_           : numpy.ndarray; Light colors (RGB values)
        :param smooth_          : boolean; IF true, smooth the light effect
        :param saturation_      : boolean; if True, saturate the light effect
        :param sat_value_       : float;  Float value in range [-1.0 ... 1.0], below zero, cause the light effect to
        turn gray and above zero to saturate the light effect
        :param bloom_           : boolean; Trigger a bloom effect (Light effect will be brighter when the light overlay
        bright area)
        :param bloom_threshold_ : unsigned short; Bloom threshold default 128; Cause the bloom effect to be brighter
        when the threshold value is low
        :param heat_            : boolean; Create a heat/convection effect when set to True
        :param frequency_       : float; Adjust the heat effect
        :param blend_           : boolean; Blend mode (default BLEND_RGB_ADD)
        :param timing_          : float; Timing for the light effect: internal loop time
        :param offset_x         : int; offset of the light effect; Select a value to move the light effect origin
        :param offset_y         : int; offset of the light effect; Select a value to move the light effect origin
        :param fast_            : boolean; Speed up the process when set to True but the effect will be slightly blur,
        due to the fact to use smaller array/texture
        """

        gl_all = gl_.All

        Sprite.__init__(self, gl_all)

        cdef:
            int sw, sh
            object dummy_rect  = dummy_.rect
            int dummy_layer    = dummy_._layer

        if PyObject_IsInstance(gl_all, LayeredUpdates):
            gl_all.change_layer(self, dummy_layer)

        sw, sh = (<object>array_alpha_).shape[:2]
        self.image      = Surface((sw, sh))
        self.dummy      = dummy_
        self.rect       = self.image.get_rect(
            center=(dummy_rect.centerx, dummy_rect.centery))
        self._layer     = dummy_layer
        self._blend     = blend_
        self.gl         = gl_
        self.lalpha     = array_alpha_
        self.fast_array_alpha = fast_array_alpha_
        self.intensity  = intensity_
        self.color      = color_
        self.smooth     = smooth_
        self.saturation = saturation_
        self.sat_value  = sat_value_
        self.bloom      = bloom_
        self.bloom_threshold = bloom_threshold_
        self.heat       = heat_
        self.frequency  = frequency_
        self.dt         = 0
        self.timing     = timing_
        self.offset_x   = offset_x
        self.offset_y   = offset_y
        self.fast       = fast_
        self._id        = id(self)

    cpdef update(self, args=None):

        if not self.dummy.alive():
            self.kill()
            return

        cdef int x, y, w, h, lw, lh, lw2, lh2, sw, sh, xx, yy
        cdef object gl         = self.gl
        cdef object dummy_rect = self.dummy.rect
        cdef lalpha            = self.lalpha
        cdef tuple lalpha_t    = lalpha.shape[:2]
        cdef bint fast         = self.fast

        if self.dt > self.timing:

            x = dummy_rect.centerx + self.offset_x
            y = dummy_rect.centery + self.offset_y

            # NOTE 04/10/2021 changed
            # w, h = gl.screenrect.w, gl.screenrect.h
            w, h = gl.screen.get_width(), gl.screen.get_height()


            lw, lh = lalpha_t[0], lalpha_t[1]
            lw2, lh2 = lw >> 1, lh >> 1

            image, sw, sh = \
                area24_c(
                    x >> 1 if fast else x,
                    y >> 1 if fast else y,
                    pixels3d(scale(gl.screen, (w >> 1, h >> 1))) if fast else pixels3d(gl.screen),
                    self.fast_array_alpha if fast else self.lalpha,
                    intensity   = self.intensity,
                    color       = self.color,
                    smooth      = self.smooth,
                    saturation  = self.saturation,
                    sat_value   = self.sat_value,
                    bloom       = self.bloom,
                    bloom_threshold = self.bloom_threshold,
                    heat        = self.heat,
                    frequency   = self.frequency)

            if fast:
                self.image = scale2x(image).convert()

                sw = sw * 2
                sh = sh * 2
            else:
                self.image = image.convert()

            xx = crop_x(lw, lw2, sw, x)
            yy = crop_y(lh, lh2, sh, y)

            self.rect.topleft = (xx, yy)

            self.dt = 0

        self.intensity -= 0.5
        if self.intensity <0:
            self.intensity = 0.0
            self.kill()

        self.dt += gl.TIME_PASSED_SECONDS


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class LightEngineBomb(Sprite):

    cdef:
        public object image, rect
        bint saturation, bloom, heat, smooth
        public int _blend, _layer
        float intensity, sat_value, frequency, timing, dt
        unsigned char bloom_threshold
        object gl, dummy, lalpha, color
        int ttl
        long long int _id

    def __init__(self,
                 gl_,
                 dummy_,
                 np.ndarray[np.uint8_t, ndim=2] array_alpha_,
                 np.ndarray[np.uint8_t, ndim=2] fast_array_alpha_,
                 float intensity_  = <float>7.0,
                 color_            = numpy.array(
                     [<float>127.0 * ONE_255, <float>173.0 * ONE_255,
                      <float>249.0 * ONE_255], float32, copy=False),
                 bint smooth_      = False,
                 bint saturation_  = False,
                 float sat_value_  = <float>1.0,
                 bint bloom_       = False,
                 unsigned char bloom_threshold_ = <unsigned char>128,
                 bint heat_        = False,
                 float frequency_  = <float>1.0,
                 int blend_        = BLEND_RGB_ADD,
                 float timing_     = <unsigned char>16,
                 int time_to_live_ = <unsigned char>10,
                 bint fast_        = False):
        """
        Create a light effect around a dummy object with a time to live value

        :param gl_              : class; Global variable / constants
        :param dummy_           : class; Class holding the object position (rect position)
        :param array_alpha_     : numpy.ndarray; Array containing the alpha channel values for the light model
        :param fast_array_alpha_: numpy.ndarray; Array containing the alpha channel values for the light model, this
        array is twice smaller than the above array
        :param intensity_       : float; Light intensity value
        :param color_           : numpy.ndarray; Light colors (RGB values)
        :param smooth_          : boolean; IF true, smooth the light effect
        :param saturation_      : boolean; if True, saturate the light effect
        :param sat_value_       : float;  Float value in range [-1.0 ... 1.0], below zero, cause the light effect to
        turn gray and above zero to saturate the light effect
        :param bloom_           : boolean; Trigger a bloom effect (Light effect will be brighter when the light overlay
        bright area)
        :param bloom_threshold_ : unsigned short; Bloom threshold default 128; Cause the bloom effect to be brighter
        when the threshold value is low
        :param heat_            : boolean; Create a heat/convection effect when set to True
        :param frequency_       : float; Adjust the heat effect
        :param blend_           : boolean; Blend mode (default BLEND_RGB_ADD)
        :param timing_          : float; Timing for the light effect: internal loop time
        :param time_to_live_    : integer; Value (default 10) whe the ttl reach zero the light effect is removed
        :param fast_            : boolean; Speed up the process when set to True but the effect will be slightly blur,
        due to the fact to use smaller array/texture

        """

        gl_all = gl_.All
        Sprite.__init__(self, gl_all)

        cdef:
            int sw, sh
            dummy_rect  = dummy_.rect
            dummy_layer = dummy_._layer

        if PyObject_IsInstance(gl_all, LayeredUpdates):
            gl_all.change_layer(self, dummy_layer)

        sw, sh = (<object>array_alpha_).shape[:2]
        self.image      = Surface((sw, sh))
        self.dummy      = dummy_
        self.rect       = self.image.get_rect(
            center=(dummy_rect.centerx, dummy_rect.centery))
        self._layer     = dummy_layer
        self._blend     = blend_
        self.gl         = gl_
        self.lalpha     = array_alpha_
        self.fast_array_alpha = fast_array_alpha_
        self.intensity  = intensity_
        self.color      = color_
        self.smooth     = smooth_
        self.saturation = saturation_
        self.sat_value  = sat_value_
        self.bloom      = bloom_
        self.bloom_threshold = bloom_threshold_
        self.heat       = heat_
        self.frequency  = frequency_
        self.dt         = 0
        self.timing     = timing_
        self.ttl        = time_to_live_
        self.fast       = fast_
        self._id        = id(self)

    cpdef update(self, args=None):

        if self.ttl < 1:
            self.kill()

        cdef:
            int lw, lh, lw2, lh2, x, y, xx, yy, sw, sh
            object lalpha     = self.lalpha
            object dummy_rect = self.dummy.rect
            bint fast         = self.fast
            object gl         = self.gl

        if self.dt > self.timing:

            lw, lh = lalpha.shape[:2]
            lw2, lh2 = lw >> 1, lh >> 1

            # NOTE 04/10/2021
            w, h = gl.screen.get_width(), gl.screen.get_height()
            # w, h = gl.screenrect.w, gl.screenrect.h

            x = dummy_rect.centerx
            y = dummy_rect.centery

            image, sw, sh = \
                area24_c(
                    x >> 1 if fast else x ,
                    y >> 1 if fast else y,
                    pixels3d(scale(gl.screen, (w >> 1, h >> 1))) if fast else pixels3d(gl.screen),
                    self.fast_array_alpha if fast else self.lalpha,
                    intensity   = self.intensity,
                    color       = self.color,
                    smooth      = self.smooth,
                    saturation  = self.saturation,
                    sat_value   = self.sat_value,
                    bloom       = self.bloom,
                    bloom_threshold = self.bloom_threshold,
                    heat        = self.heat,
                    frequency   = self.frequency)

            if fast:
                self.image = scale2x(image).convert()

                sw = sw * <unsigned short int>2
                sh = sh * <unsigned short int>2
            else:
                self.image = image.convert()

            xx = crop_x(lw, lw2, sw, x)
            yy = crop_y(lh, lh2, sh, y)

            self.rect.topleft = (xx, yy)

            self.dt = 0
            self.ttl -= 1

        self.intensity -= <float>0.2 if self.intensity > <float>0.2 else 0
        self.dt += self.gl.TIME_PASSED_SECONDS
