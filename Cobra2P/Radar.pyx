# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from __future__ import print_function

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, linspace
except ImportError:
    raise ValueError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

cimport numpy as np

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

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, BLEND_RGB_ADD, Rect
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL
    from pygame.transform import scale, smoothscale, rotate

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:
    from Sprites cimport Sprite
    from Sprites cimport LayeredUpdates
except ImportError:
    raise ImportError("\nSprites.pyd missing?!.Build the project first.")


from SpriteSheet import Sprite_Sheet_Uniform_RGB
from Halo import Halo
from Tools cimport  wave_xy_c, damped_oscillation
from PygameShader import horizontal_glitch

from libc.math cimport sqrt, atan2, sin, cos, INFINITY
from AI_cython import Threat

cdef extern from 'Include/vector.c':
    struct vector2d:
        float x;
        float y;

    cdef float M_PI;
    void vecinit(vector2d *v, float x, float y)nogil
    float vlength(vector2d *v)nogil
    void addv_inplace(vector2d *v1, vector2d v2)nogil
    void subv_inplace(vector2d *v1, vector2d v2)nogil
    vector2d subcomponents(vector2d v1, vector2d v2)nogil
    void scale_inplace(float c, vector2d *v)nogil

cdef struct coordinates:
    float x;
    float y;
    float r;

from Textures import RADAR_INTERFACE as RADAR
from Textures import DIALOGBOX_READOUT as READ
from Textures import HALO_SPRITE_WHITE

cdef list RADAR_ZOOM_IN = []
cdef int w, h
cdef float f
w, h= RADAR[0].get_size()
f = 1.0

for sprite in RADAR:
    sprite = smoothscale(sprite, (<int>(w * f), <int>(h * f))).convert()
    f += <float>0.2
    RADAR_ZOOM_IN.append(sprite)

RADAR_ZOOM_IN = RADAR_ZOOM_IN[::-1]


READOUT = READ.copy()
cdef int i = 0
for r in READOUT:
    READOUT[i] = smoothscale(r, (w, h))
    i += <unsigned char>1

RADAR_CST = RadarCst()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef coordinates fish_eye(object gl_, int x_, int y_):
    """
    DETERMINE THE POSITION OF A TARGET IN THE RADAR SCOPE (ROUND SCREEN REPRESENTATION)
    
    * Apply a fish_eye transformation of the target coordinates (x, y) -> (x', y', r) 
    
    :param gl_: object; class containing the variables / constants  
    :param x_ : integer; position x of the dot 
    :param y_ : integer; position y of the dot
    :return: Return a structure coordinates containing values of x, y, r (dot position in the radar scope)
    """

    cdef object surface = gl_.screen
    cdef:
        int x = x_
        int y = y_
        int w = surface.get_width()
        int h = surface.get_height()
        float w2 = w * <float>0.5
        float h2 = h * <float>0.5
        float ny, ny2, nx, nx2, r, nr, theta, nxn, nyn, x2, y2
        coordinates coords

    coords.x = 0
    coords.y = 0
    coords.r = 0

    ny = <float>(((<float>2.0 * y) / h) - <float>1.0)
    ny2 = ny * ny

    nx = <float>(((<float>2.0 * x) / w) - <float>1.0)
    nx2 = nx * nx

    r = <float>sqrt(nx2 + ny2)

    if r <= <float>1.0:

        nr = <float>((r + <float>1.0 - <float>sqrt(<float>1.0 - r * r )) * <float>.5)

        if nr <= <float>1.0:

            theta = <float>atan2(ny, nx)
            nxn = <float>(nr * <float>cos(theta))
            nyn = <float>(nr * <float>sin(theta))
            x2 = nxn * w2 + w2
            y2 = nyn * h2 + h2

        coords.x = <int>x2
        coords.y = <int>y2
        coords.r  = r

    return coords

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class RadarCst:
    cdef:
        public bint active
        public list inventory
        public dict category
        public list hostiles
        public tuple mouse_position

    def __init__(self):
        self.active    = False           # True the Radar is active
        self.inventory = []              # Contains All the instance(s)
        self.category  = {}              # Models
        self.hostiles  = []              # Enemies/missiles currently display on the screen

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class RadarClass(Sprite):
    cdef:
        public object image, rect
        public int _blend
        object group, player, gl, screenrect
        tuple location, center
        int width, height, pulse_time, last_pulse, index, length, dot_index, timing, dt
        float radius, Radius, ratio, inv_ratio
        list hostiles, images, images_copy
        bint pulse

    def __init__(self, list surface_, object group_, tuple location_,
                 object gl_, object player_, int layer_=-1, timing_=16, blend_=0):

        Sprite.__init__(self, group_)

        if isinstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.image = <object>PyList_GetItem(surface_, 0)
        self.images = surface_
        # todo check if we can avoid to make a copy
        self.images_copy = surface_.copy()
        self.length = PyList_Size(self.images_copy) - 4
        self.rect = self.image.get_rect(center=(location_[0],location_[1]))
        self.location   = location_
        self.player     = player_
        self.gl         = gl_
        self.screenrect = gl_.screenrect
        self.width, self.height = self.image.get_size()
        # Radar bitmap radius and size
        cdef:
            int w2 = self.width >> 1
            int h2 = self.height >> 1

        self.radius = <float>sqrt(w2 * w2 + h2 * h2)

        # SCREENRECT radius
        self.Radius = <float>sqrt(
            self.screenrect.centerx * self.screenrect.centerx +
            self.screenrect.centery * self.screenrect.centery)
        # ratio
        self.ratio      = self.Radius / self.radius
        self.inv_ratio  = <float>1.0 / self.ratio
        self.center     = self.screenrect.center
        self.index      = 0
        # list of hostile aircraft coordinates (position vector)
        self.hostiles   = []
        self.dot_index  = 0
        self.pulse      = False
        self.pulse_time = 40  # number of frames between pulse (halo)
        self.last_pulse = 0
        self._blend     = blend_
        self.timing     = timing_
        self.dt         = 0
        self.dampening_fx  = False
        self.rotate_fx     = False
        self.zoom_in_fx    = False
        self.disruption_fx = False
        self.counter_fx    = 0

        RADAR_CST.active = True
        RADAR_CST.inventory.append(id(self))

    cpdef bint check_pulse(self):
        return self.gl.FRAME - self.last_pulse > self.pulse_time

    @staticmethod
    cdef inline void destroy():
        global RADAR_CST
        if RADAR_CST.inventory > 0:
            for instance in RADAR_CST.inventory:
                if hasattr(instance, 'active'):
                    instance.active = False
                if hasattr(instance, 'hostiles'):
                    instance.hostiles = []
                if hasattr(instance, 'kill'):
                    instance.kill()
                RADAR_CST.inventory.remove(instance)
        RADAR_CST.inventory = []

    cdef inline void get_hostiles(self):

        objects = Threat(player_rect_=self.player.rect).create_entities(
            self.gl.screenrect, self.gl.GROUP_UNION)

        self.hostiles = []
        for id_, entity_ in objects.items():
            # No need to check if the sprite is colliding with screenrect (already checked in AI)
            # Add the position (x, y), category and euclid's distance
            self.hostiles.append(
                [pygame.math.Vector2(entity_.position[0],
                    entity_.position[1]), entity_.category, entity_.distance_to_player])

        # # simulation
        # objects = {}
        # self.hostiles = []
        # self.hostiles.append([Vector2(10, 120), 'aircraft', 150])
        # self.hostiles.append([Vector2(200, 180), 'ground', 110])
        # self.hostiles.append([Vector2(250, 220), 'ground', 50])
        # self.hostiles.append([Vector2(0, 0), 'boss', 200])
        # self.hostiles.append([Vector2(768, 512), 'missile', 350])
        # self.hostiles.append([Vector2(512, 512), 'friend', 1])

    cdef inline void disable_radar(self):
        RADAR_CST.active = False
        self.kill()

    cdef inline void wave_effect(self):
        self.image = wave_xy_c(self.image, <float>8.0 * self.index * M_PI / <float>180.0, 10)


    cpdef void set_disruption_fx(self):
        self.disruption_fx = True
        self.counter_fx = 120

    @cython.cdivision(False)
    cdef inline void disruption_effect(self):
        horizontal_glitch(self.image, 1, <float>0.3, (<float>50 - self.index) % <unsigned char>20)
        if self.counter_fx == 0:
            self.disruption_fx = False

    cpdef void set_zoom_fx(self):
        self.zoom_in_fx = True
        self.counter_fx = 120

    cdef inline void zoom_in_effect(self):
        self.image = RADAR_ZOOM_IN[self.index % PyList_Size(RADAR_ZOOM_IN)]
        self.rect = self.image.get_rect(center=self.location)
        if self.counter_fx == 0:
            self.zoom_in_fx = False

    cpdef void set_rotate_fx(self):
        self.rotate_fx = True
        self.counter_fx = 120

    @cython.cdivision(True)
    cdef inline void rotate_effect(self):
        self.image = rotate(self.image, (self.index * <unsigned char>5) % <unsigned int>360)
        self.rect = self.image.get_rect(center=self.location)
        if self.counter_fx == 0:
            self.rotate_fx = False

    cpdef void set_dampening_fx(self):
        self.dampening_fx= True
        self.counter_fx = 120

    @cython.cdivision(True)
    cdef inline void dampening_effect(self):
        cdef float t = damped_oscillation((self.index/<float>20.0) % <unsigned char>100)
        cdef int w, h, ww, hh
        cdef float tm = t * <float>120.0
        w, h = self.image.get_size()
        if w + tm < 0:
            tm = 0
        if h + tm < 0:
            tm = 0

        self.image = smoothscale(self.image, (<int>(w + tm), <int>(h + tm)))
        self.rect = self.image.get_rect(center=self.location)
        if self.counter_fx == 0:
            self.dampening_fx = False

    cpdef update(self, args=None):

        cdef:
            coordinates coords
            list hostile, dot_surfaces
            str category
            int distance, dot_w, dot_h
            image = self.image
            gl_ = self.gl
            vector2d v_res, v_dot, h_rect


        # screenrect = gl_.screenrect
        # self.location = (screenrect.w - (self.image.get_width() >> 1),
        #                  screenrect.h - (self.image.get_height() >> 1))

        if self.dt > self.timing:

            image = (<object>PyList_GetItem(
                self.images_copy, self.index % self.length)).copy()

            image_blit = image.blit

            self.rect = image.get_rect(center=self.location)

            self.get_hostiles()

            for hostile in self.hostiles:

                vector, category, distance = list(hostile)

                dot_surfaces = RADAR_CST.category[category]

                coords = fish_eye(gl_, vector.x, vector.y)
                res, distance_ = (coords.x, coords.y), coords.r

                if PyObject_IsInstance(dot_surfaces, list):
                    dot_w, dot_h = (<object>PyList_GetItem(dot_surfaces, 0)).get_size()
                    hrect = (<object>PyList_GetItem(dot_surfaces, 0)).get_rect()

                    vecinit(&v_res, res[0], res[1])
                    scale_inplace(self.inv_ratio, &v_res)

                    hrect.center = (v_res.x, v_res.y)


                    vecinit(&v_dot, dot_w, dot_h)
                    scale_inplace(<float>0.5, &v_dot)

                    vecinit(&h_rect, hrect.centerx, hrect.centery)
                    subv_inplace(&h_rect, v_dot)
                    hrect.centerx = h_rect.x
                    hrect.centery = h_rect.y


                    PyObject_CallFunctionObjArgs(
                        image_blit,
                        <PyObject*> <object>PyList_GetItem(
                            dot_surfaces, self.dot_index % PyList_Size(dot_surfaces)),
                        <PyObject*> hrect.center,
                        <PyObject*> None,
                        <PyObject*> <object>BLEND_RGB_ADD,
                        NULL)

                else:
                    dot_surf = RADAR_CST.category[category]
                    dot_w, dot_h = dot_surf.get_size()
                    hrect = dot_surf.get_rect()
                    hrect.center = Vector2(res) * self.inv_ratio
                    hrect.center -= Vector2(dot_w, dot_h) * <float>0.5
                    PyObject_CallFunctionObjArgs(
                        image_blit,
                        <PyObject*> <object> dot_surfaces,
                        <PyObject*> hrect.center,
                        <PyObject*> None,
                        <PyObject*> <object> BLEND_RGB_ADD,
                        NULL)

            r = (0, 0)
            PyObject_CallFunctionObjArgs(
                image_blit,
                <PyObject*> <object> PyList_GetItem(READOUT,
                                                    self.index % PyList_Size(READOUT)),
                <PyObject*> r,
                <PyObject*> None,
                <PyObject*> <object> BLEND_RGB_ADD,
                NULL)


            if self.check_pulse():
                self.pulse = True
                self.last_pulse = gl_.FRAME
                PyObject_CallFunctionObjArgs(
                    Halo,
                    <PyObject*> <object> gl_,
                    <PyObject*> <object> gl_.All,
                    <PyObject*> <object> HALO_SPRITE_WHITE,
                    <PyObject*> <object> self.rect.centerx,
                    <PyObject*> <object> self.rect.centery,
                    <PyObject*> <object> 0,
                    <PyObject*> <object> 0,
                    <PyObject*> <object> 0,  # NO BLEND (32 bit TEXTURE)
                    NULL
                )


            else:
                self.pulse = False

            self.image = image
            self.index += 1
            self.dot_index += 1



            if self.dampening_fx:
                self.dampening_effect()

            if self.rotate_fx:
                self.rotate_effect()

            if self.zoom_in_fx:
                self.zoom_in_effect()

            if self.disruption_fx:
                self.disruption_effect()

            self.counter_fx -= 1

            if self.counter_fx < 0:
                self.counter_fx = 0

            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS
