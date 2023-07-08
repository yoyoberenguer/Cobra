# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

import pygame
from pygame.math import Vector2

from Player import Player
from Sprites cimport Sprite
from Sprites cimport LayeredUpdates
from Weapons import DEBRIS
from Shot import Shot

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

cdef extern from 'Include/randnumber.c':
    void init_clock()nogil;
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;

BLAST_INVENTORY = []
BLAST_INVENTORY_APPEND = BLAST_INVENTORY.append
BLAST_INVENTORY_REMOVE = BLAST_INVENTORY.remove

@cython.binding(False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Blast(Sprite):

    cdef:
        public object image, rect
        public int _blend
        float timing
        public int layer
        object group_, images_, gl_, object_, speed
        int index, _frame
        float dt

    def __init__(self, group_, images_, gl_, object_, float timing_=16.67, int layer_=-3, int blend_=0):
        """
        MOVE A SPRITE WITH A LINEAR DECELERATION (BLAST EFFECT)

        The sprite is most likely to be a part of the enemy hull

        :param group_  : sprite group(s); Sprite group this sprite belong
        :param images_ : pygame surface; list of surfaces or single surface
        :param gl_     : class; constants/ variables
        :param object_ : Instance; Object causing the blast (most likely to be the player instance)
        :param timing_ : float; default 60 fps (16.67ms)
        :param layer_  : integer; Sprite layer to use default -3
        :param blend_  : integer; Additive mode blend (default no blend)
        """

        if id(object_) in BLAST_INVENTORY:
            return

        Sprite.__init__(self, group_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        object_rect = object_.rect

        self.object_    = object_
        self._blend     = blend_
        self.speed      = Vector2(
            [randRange(-6, -2), randRange(2, 6)][randRange(0, 1)],
            [randRange(-6, -2), randRange(2, 6)][randRange(0, 1)])

        self.images_copy = images_.copy()
        self.image = <object>PyList_GetItem(images_, 0) if \
            PyObject_IsInstance(images_, list) else images_

        self.rect       = self.image.get_rect(center=object_rect.center)
        self._frame     = 0
        self.index      = 0
        self.dt         = 0
        self.timing     = timing_
        self.gl         = gl_
        self.length     = PyList_Size(images_)  if PyObject_IsInstance(images_, list) else 1

        # ONLY FOR THE PLAYER SPACESHIP EXPLOSION
        # TRANSFORM THE SPACESHIP DEBRIS INTO LETHAL PROJECTILES (USING
        # DEBRIS WEAPON INSTANCE)
        if PyObject_IsInstance(object_, Player):
            DEBRIS.velocity = self.speed
            DEBRIS.sprite   = self.image

            Shot(group_         = (self.gl.shots, self.gl.All),
                 pos_           = object_rect.center,
                 current_weapon_= DEBRIS,
                 player_        = object_,
                 mute_          = True,
                 offset_        = (0, object_rect.centery),
                 timing_        = <float>1.0/<float>60.0,
                 gl_            = gl_,
                 layer_         = 0)
            # NO NEED TO STAY INTO BLAST FOR DEBRIS ANIMATION,
            # THE CLASS SHOT WILL TAKE OVER.
            self.quit()

        BLAST_INVENTORY_APPEND(id(self.object_))

    cpdef int get_animation_index(self):
        return self.index

    cdef void quit(self):
        try:
            if id(self.object_) in BLAST_INVENTORY:
                BLAST_INVENTORY_REMOVE(id(self.object_))
        except Exception as e:
            print('Blast Error : %s' % e)
        finally:
            self.kill()

    cpdef update(self, args=None):

        cdef:
            int _frame  = self._frame
            int index   = self.index
            float c     = 0
            speed       = self.speed

        if self.dt > self.timing:

            if self.gl.screenrect.colliderect(self.rect):

                if PyObject_IsInstance(self.images_copy, list):
                    if index > self.length:
                        self.quit()
                        return
                    self.image = <object>PyList_GetItem(self.images_copy, index % self.length)

                # CANNOT DIV BY ZERO DUE TO 1+
                c = <float>1.0 / (<float>1.0 + <float>0.0001 * _frame * _frame)
                speed.x *= c
                speed.y *= c

                if speed.length() < <float>0.9:
                    self.quit()

                self.rect.move_ip(speed)

                index += <int>1
                _frame += <int>1

            else:
                self.quit()

            self.dt     = <float>0.0
            self.index  = index
            self._frame = _frame
            self.speed  = speed

        self.dt += self.gl.TIME_PASSED_SECONDS

