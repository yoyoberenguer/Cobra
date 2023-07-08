# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


import pygame
from pygame import Rect
from pygame.math import Vector2
from pygame.transform import smoothscale
from Sprites cimport Sprite
from Sprites cimport LayeredUpdates
import numpy
from numpy import float32


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

cdef float SIXTYFPS = 1.0/60.0

HIGHLIGHT_INVENTORY = []
HIGHLIGHT_INVENTORY_APPEND = HIGHLIGHT_INVENTORY.append
HIGHLIGHT_INVENTORY_REMOVE = HIGHLIGHT_INVENTORY.remove

CURRENT_TARGET = []


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Target:

    cdef:
        object draw_poly, screenrect, target, centre, enemy
        int w2, h2, speed
        tuple color
        float f


    def __init__(self, gl_, enemy_, tuple color_=(255, 0, 0), int speed_=16):
        """
        SHOW A LOZENGE QUICKLY FOCUSING ON A SPECIFIC TARGET

        :param gl_: class; constants/variables
        :param enemy_: class/instance; Enemy instance with attributes
        :param color_: tuple; color of the targeting system defautl red
        :param speed_: integer; focus speed of the targeting system
        """
        cdef:
            int width, height


        screenrect_ = gl_.screenrect
        width       = screenrect_.w
        height      = screenrect_.h
        self.w2          = width >> 1
        self.h2          = height >> 1

        self.centre = Vector2(enemy_.rect.centerx - self.w2, enemy_.rect.centery - self.h2)
        self.enemy  = enemy_
        self.color      = color_
        self.f = <float>500.0

        gl_.CURRENT_TARGET = [self]

    cpdef get_polyrect(self, poly_):
        cdef:
            int width, height, center_x, center_y

        width       = <int>(poly_[2][0] - poly_[0][0])
        height      = <int>(poly_[3][1] - poly_[1][1])
        center_x    = width >> 1
        center_y    = height >> 1
        rect        = Rect(0, 0, width, height)
        rect.center = (center_x, center_y)
        return rect

    cpdef update_poly(self, screen_):

        cdef:
            unsigned char n = 100
            centre_x = self.centre.x
            centre_y = self.centre.y

        self.centre = Vector2(self.enemy.rect.centerx, self.enemy.rect.centery)

        # LOZENGE
        self.target = numpy.array(
            [(centre_x - n - self.f,     centre_y),
             (centre_x,                  centre_y - n - self.f),
             (centre_x + n + self.f,     centre_y),
             (centre_x,                  centre_y + n + self.f),
             (centre_x - n - self.f,     centre_y)], dtype=float32)

        pygame.draw.aalines(screen_ , self.color, True, self.target, blend=0)

        self.f -= 25



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class HighlightTarget(Sprite):

    cdef:
        public object image, rect, target
        object player, image_copy
        float timing, dt
        int _layer, size

    def __init__(self, image_, group_, player_, gl_,
                 target_, float timing_=SIXTYFPS, int layer_= -4):
        """
        DRAW A RED RECTANGLE / LOZENGE AROUND A SPECIFIC TARGET
        THE RED LOZENGE MEANS THAT THE TARGET HAS BEEN AUTOMATICALLY SELECTED BY THE PLAYER TURRET

        :param group_ : pygame.Surface; Target square (lozenge) sprite
        :param player_: class; player instance with attributes
        :param gl_    : class Constants/Variables
        :param target_: class; Target instance with all attributes
        :param timing_: float CAP max fps to 60
        :param layer_ : integer; layer to use for the sprite (should be equivalent to target layer)
        """

        # NEVER HAPPEN TWICE FOR THE SAME TARGET
        if id(target_) in HIGHLIGHT_INVENTORY:
            return

        Sprite.__init__(self, group_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, target_._layer if
                PyObject_HasAttr(target_, '_layer') else layer_)

        HIGHLIGHT_INVENTORY_APPEND(id(target_))

        self.timing     = timing_
        self.image_copy = image_.copy()
        self.target     = target_
        self.image      = smoothscale(image_, (10, 10))
        self.rect       = self.image.get_rect(
            center=target_.rect.center)
        self.gl         = gl_
        self.player     = player_
        self.size       = 0
        self.dt         = 0
        self.factor     = 6

        Target(gl_, enemy_=self.target, color_=(255, 0, 0))


    cpdef void quit(self):

        if id(self.target) in HIGHLIGHT_INVENTORY:
            HIGHLIGHT_INVENTORY_REMOVE(id(self.target))

        self.kill()


    cpdef update(self, args=None):

        cdef:
            target_rect  = self.target.rect
            int factor   = self.factor
            int size     = self.size

        if self.target.alive() and self.player.alive():

            if self.target in self.gl.GROUP_UNION:

                if self.dt > self.timing:

                    self.image       = smoothscale(self.image_copy, (50 + size, 50 + size))
                    self.rect        = self.image.get_rect()
                    self.rect.center = target_rect.center

                    size += factor

                    if size > <int>(target_rect.w * <float>1.3):
                        factor = -factor

                    if size < 1:
                        factor = -factor

                    self.dt     = 0
                    self.size   = size
                    self.factor = factor
            else:
                self.quit()

            self.dt += self.gl.TIME_PASSED_SECONDS
        else:
            self.quit()

