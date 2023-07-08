# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# NUMPY IS REQUIRED
# from CobraLightEngine import LightEngine

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
    QUIT, K_SPACE, Rect, BLEND_RGB_ADD, BLEND_RGB_MIN, BLEND_RGB_MAX
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL
    from pygame.transform import scale, smoothscale, rotate, rotozoom

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from Sprites cimport Sprite
from Sprites cimport LayeredUpdates

from ParticleFx import *
from Textures import PHOTON_PARTICLE_1
#RADIAL4_ARRAY_128x128, RADIAL4_128x128, RADIAL4_ARRAY_64x64_FAST, RADIAL4_ARRAY_32x32_FAST
from Weapons import WEAPON_ROTOZOOM, WEAPON_OFFSET_X


cdef extern from 'Include/randnumber.c':
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;

# TODO RENAME FOR PLAYER_DEBRIS INSTEAD
# CONTAINS THE PLAYER DEBRIS
LIGHTS_VERTEX = []
LIGHTS_VERTEX_REMOVE = LIGHTS_VERTEX.remove
LIGHTS_VERTEX_APPEND = LIGHTS_VERTEX.append


cdef float ONE_255 = <float>1.0 / <float>255.0
color = numpy.array([<float>33.0 * ONE_255, <float>165.0 * ONE_255,
                     <float>86.0 * ONE_255], float32, copy=False)


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Shot(Sprite):

    cdef:
        public object Rect, image
        public int _layer, _blend
        public tuple pos, offset
        public object current_weapon, player, gl
        bint mute,
        float timing
        int length


    def __init__(self, object group_, tuple pos_, object current_weapon_, object player_,
                 bint mute_, tuple offset_, float timing_, object gl_, int layer_=-2):
        """
        HANDLE THE PLAYER(S) LASERS/SHOTS (ALSO PLAYER DEBRIS AFTER EXPLOSION)

        :param group_         : pygame groups default (gl.All, gl.shots)
        :param pos_           : tuple; tuple containing gun position x, y (player_.gun_position())
        :param current_weapon_: instance; Instance containing the type of weapon and attributes
        :param player_        : Instance; Player instance
        :param mute_          : bool; True play a sound False no sound. for multiple shots set the mute to True to
        avoid playing the shot sound effect more than once
        :param offset_        : tuple (x, y) when the shot is offset from the gun position
        :param timing_        : float; Cap the max FPS value (Useful if the GAME FPS is over 60 FPS)
        :param gl_            : class; containing all the variables and contants
        :param layer_         : integer; Layer to display the sprite default -2
        """
        Sprite.__init__(self, group_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            if layer_:
                gl_.All.change_layer(self, layer_)

        self._layer     = layer_
        self.player     = player_
        self.weapon     = current_weapon_
        self.images     = self.weapon.sprite.copy()
        self.image      = <object>PyList_GetItem(self.images, 0) if \
            PyObject_IsInstance(self.images, list) else self.images
        self.speed      = self.weapon.velocity
        self.offset_x   = offset_[0]
        self.pos        = (pos_[0] + self.offset_x, offset_[1])
        self.rect       = self.image.get_rect(center=self.pos)
        self.index      = 0
        self.dt         = 0
        self.timing     = timing_
        self._blend     = BLEND_RGB_ADD

        cdef:
            gl_sc_spaceship = gl_.SC_spaceship

        if not mute_:

            self.sound = self.weapon.sound_effect
            gl_sc_spaceship.stop_name(self.weapon.name)

            if len(gl_sc_spaceship.get_identical_sounds(self.sound)):
                gl_sc_spaceship.stop_name(self.weapon.name)

            gl_sc_spaceship.play(sound_=self.sound, loop_=False, priority_=0,
                                 volume_=gl_.SOUND_LEVEL,
                                 fade_out_ms=0, panning_=True,
                                 name_=self.weapon.name, x_=pos_[0],
                                 object_id_=id(self))

        if self.weapon.name != 'RED_DEBRIS_SINGLE':

            if self.weapon.units == 'SUPER':

                for number_ in range(randRange(<int>1, <int>5)):
                    ParticleFx(gl_, PHOTON_PARTICLE_1, self.rect, -2)

            else:
                # Rotate the sprite
                if self.offset_x != 0:
                    self.choose_image(self.image)

            self.vector = self.move(self.offset_x)

        # PLAYER DEBRIS
        else:
            self.rect.center = self.pos
            self.vector = Vector2(randRangeFloat(-<float>1.0, <float>1.0),
                                  randRangeFloat(-<float>1.0, <float>1.0))
            LIGHTS_VERTEX_APPEND(self)

        self.vector *= self.speed.length()
        self.gl_ = gl_
        self.rect_move_ip = self.rect.move_ip

        # LightEngine(gl_,
        #             self,
        #             array_alpha_     = RADIAL4_ARRAY_64x64_FAST, # RADIAL4_ARRAY_128x128,
        #             fast_array_alpha_= RADIAL4_ARRAY_32x32_FAST, # RADIAL4_ARRAY_64x64_FAST,
        #             intensity_       = 4.0,
        #             color_           = color,
        #             smooth_          = False,
        #             saturation_      = False,
        #             sat_value_       = 1.0,
        #             bloom_           = False,
        #             bloom_threshold_ = 128,
        #             heat_            = False,
        #             frequency_       = 1.0,
        #             blend_           = BLEND_RGB_ADD,
        #             timing_          = timing_,
        #             fast_            = True,
        #             offset_x         = 0,
        #             offset_y         = -8)

    cpdef center(self):
        return self.rect.center

    cpdef location(self):
        return self.rect

    cpdef int get_animation_index(self):
        return self.index

    cdef void choose_image(self, surface_):
        """
        Rotozoom the bullet surface according to the offset self.offset_x. The offset 
        determine the projectile angle. 
        
        :param surface_: Surface; surface to rotate
        :return: return the rotated surface corresponding to the offset (angle)
        """
        self.image = eval(WEAPON_ROTOZOOM[self.player.name][self.offset_x])

    cdef move(self, int offset_x):
        """
        Return the bullet vector direction 
        
        :param offset_x: integer; Offset from the center of the aircraft
        :return: Return a Vector2 (x, y) vector direction for the bullet 
        """
        return eval(WEAPON_OFFSET_X[self.player.name][offset_x])

    cpdef update(self, args=None):

        cdef:
            gl_screenrect    = self.gl_.screenrect

        if gl_screenrect is None:
            self.kill()
            return

        cdef:
            int index = self.index

        # self.image = Surface((0, 0))

        if self.dt > self.timing:
            # Animation
            if PyObject_IsInstance(self.images, list):
                self.image = <object>PyList_GetItem(self.images, index)


                if index < len(self.images) - <unsigned char>1:
                    index += 1
                else:
                    if self in LIGHTS_VERTEX:
                        LIGHTS_VERTEX_REMOVE(self)
                    self.kill()

            if self.weapon.name == 'RED_DEBRIS_SINGLE':
                self.rect.centerx += self.speed.x * <unsigned char>2
                self.rect.centery += self.speed.y * <unsigned char>2
                self.image = rotozoom(self.images.copy(), index, <float>1.0)
            else:

                self.rect_move_ip(self.vector)

            if not gl_screenrect.colliderect(self.rect):
                if self in LIGHTS_VERTEX:
                    LIGHTS_VERTEX_REMOVE(self)
                self.kill()

            self.dt = 0

        self.index = index
        self.dt += self.gl_.TIME_PASSED_SECONDS

