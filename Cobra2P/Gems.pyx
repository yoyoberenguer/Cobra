# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# NUMPY IS REQUIRED
from Sprites cimport Sprite
from Sprites cimport LayeredUpdates
from Textures import GEM_SPRITES

try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, full_like, add, putmask, int16, arange, repeat, newaxis
except ImportError:
    print("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")
    raise SystemExit


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
    import pygame
    from pygame import Rect, BLEND_RGB_MIN, BLEND_RGB_MAX
    from pygame.math import Vector2
    from pygame import Rect, BLEND_RGB_ADD, HWACCEL
    from pygame import Surface, SRCALPHA, mask, RLEACCEL
    from pygame.transform import rotate, scale, smoothscale
    from pygame.surfarray import array3d, pixels3d, array_alpha, pixels_alpha
    from pygame.image import frombuffer

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

DEF M_PI = 3.14159265359
DEF DEG_TO_RAD = M_PI / 180.0

GEM_VALUE = numpy.array(list(range(1, 22))) * 22

GEM_INVENTORY        = set()
GEM_INVENTORY_ADD    = GEM_INVENTORY.add
GEM_INVENTORY_REMOVE = GEM_INVENTORY.remove


cdef extern from 'Include/vector.c' nogil:

    struct vector2d:
        float x;
        float y;

    void vecinit(vector2d *v, float x, float y);
    vector2d adjust_vector(vector2d player, vector2d rect, vector2d speed)
    vector2d RandAngleVector2d(int minimum, int maximum, float angle)
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef adjust_vector_c(player, rect, speed):
    cdef vector2d p, r, s, vector
    vecinit(&p, player.x, player.y)
    vecinit(&r, rect.x, rect.y)
    vecinit(&s, speed.x, speed.y)
    vector = adjust_vector(p, r, s)
    return Vector2(vector.x, vector.y)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef rand_angle_vector_c(int min_, int max_, float rad_angle_):
    cdef vector2d new_vector
    new_vector = RandAngleVector2d(min_, max_, rad_angle_)
    return Vector2(new_vector.x, new_vector.y)

GEM_VALUE = numpy.array(list(range(1, 22))) * 22

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Gems(Sprite):
    cdef:
        public object rect, image, _blend, mask
        public int value, counter
        object gl, player, speed, object_
        float timing, dt, angle
        int layer, gem_number, theta

    def __init__(self, gl_, player_, object_, float timing_, offset_=None, int layer_=-1):
        """
        CREATE GEMS COLLECTABLE AFTER AN ENEMY EXPLOSION, THE GEMS WILL AUTOMATICALLY
        MERGED TO THE PLAYER POSITION

       :param gl_      : class; GL class contains all the game constants
       :paran group_   : pygame sprite group; Group where the sprite belongs
       :param player_  : class/instance; Player instance P1 or P2
       :param object_  : class/instance; Object being destroyed producing gems
       :param timing_  : integer; must be > 0. Refreshing rate e.g 15ms 60 fps
       :param offset_  : pygame.Rect; Offset from the object center
       :param layer_   : integer; must be < 0. Layer used by the gems
       """
        if id(object_) in GEM_INVENTORY:
            return

        Sprite.__init__(self, (gl_.gems, gl_.All))

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.timing = timing_
        self.player = player_

        gem_number = randRange(0, len(GEM_SPRITES) - <int>1)
        self.value = GEM_VALUE[gem_number]
        self.image = GEM_SPRITES[gem_number]
        self.image_copy = self.image.copy()

        self.image  = rotate(self.image, randRange(<int>0, <int>360))
        self.gl     = gl_

        if offset_ is not None:
            self.rect = self.image.get_rect(center=offset_.center)
        else:
            self.rect = self.image.get_rect(center=object_.rect.center)

        self.speed  = Vector2(0, randRange(<int>25, <int>35))
        self.dt     = <int>0
        self.theta  = <int>0
        self._blend = <int>0
        self.object_ = object_
        angle = <float> (DEG_TO_RAD * randRangeFloat(<float>0.0, <float>359.0))
        self.vector = rand_angle_vector_c(<int>10, <int>20, angle)

        # FORCE BLENDING
        self._blend = BLEND_RGB_ADD

        self.counter = 0
        GEM_INVENTORY_ADD(id(self))

    def remove_from_inventory(self):
        id_ = id(self)
        if id_ in GEM_INVENTORY:
            GEM_INVENTORY_REMOVE(id_)
        self.kill()

    cpdef update(self, args=None):

        cdef:
            object gl     = self.gl
            object rect   = self.rect
            object player = self.player
            float vec_x   = self.vector.x
            float vec_y   = self.vector.y
            object vector = self.vector
            object speed  = self.speed

        if self.dt > self.timing:

            if gl.screenrect.contains(rect):

                self.image = rotate(self.image_copy, self.theta)
                rect = self.image.get_rect(center=rect.center)

                # GEMS FOLLOW PLAYER
                if player is not None and PyObject_HasAttr(player, 'alive') and player.alive():

                    # GEMS SPREAD 360 DEGREES
                    rect.move_ip((vec_x, vec_y))
                    vec_x *= <float>0.95
                    vec_y *= <float>0.95
                    vector = Vector2(vec_x, vec_y)
                    if self.counter > <int>30 or vector.length() < <float>0.5:
                        if not rect.colliderect(player.rect):
                            # GEMS FOLLOW PLAYER
                            vec = adjust_vector_c(player.rect, rect, speed)
                            rect.move_ip(vec.x, vec.y)
                    self.counter += <int>1
                else:
                    # GEMS FOLLOW THE SCENE
                    rect.move_ip(speed.x, 8)

                self.theta += <int>2
                self.theta %= <int>359

            else:
                self.remove_from_inventory()

            self.dt = 0

        self.vector = vector
        self.rect   = rect
        self.dt    += gl.TIME_PASSED_SECONDS
