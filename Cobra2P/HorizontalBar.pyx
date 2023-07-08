# cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

import pygame
from pygame import BLEND_RGB_ADD, BLEND_RGB_MAX, BLEND_RGB_SUB
from pygame.image import frombuffer
from pygame.surface import Surface
from pygame.surfarray import make_surface
from pygame.transform import smoothscale

import numpy
from numpy import uint8, empty, asarray
cimport numpy as np

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


cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;

FONT = pygame.font.SysFont("arial", 10, 'bold')



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef create_horizontal_gradient_3d_alpha(
        int width, int height, tuple start_color=(255, 0, 0, 0), tuple end_color=(0, 255, 0, 0)):
    cdef:
        float [:] diff_ =  numpy.array(end_color, dtype=numpy.float32) - \
                            numpy.array(start_color, dtype=numpy.float32)
        float [::1] row = numpy.arange(width, dtype=numpy.float32) / (width - <float>1.0)
        unsigned char [:, :, ::1] rgba_gradient = empty((width, height, 4), dtype=numpy.uint8)
        float [4] start = numpy.array(start_color, dtype=numpy.float32)
        int i=0, j=0

    with nogil:
        for i in prange(width, schedule='static', num_threads=8):
            for j in range(height):
               rgba_gradient[i, j, 0] = <unsigned char>(start[0] + row[i] * diff_[0])
               rgba_gradient[i, j, 1] = <unsigned char>(start[1] + row[i] * diff_[1])
               rgba_gradient[i, j, 2] = <unsigned char>(start[2] + row[i] * diff_[2])
               rgba_gradient[i, j, 3] = <unsigned char> (start[3] + row[i] * diff_[3])

    return asarray(rgba_gradient)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef create_horizontal_gradient_3d(int width, int height,
                                   tuple start_color=(255, 0, 0), tuple end_color=(0, 255, 0)):
    cdef:
        float [:] diff_ =  numpy.array(end_color, dtype=numpy.float32) - \
                            numpy.array(start_color, dtype=numpy.float32)
        float [::1] row = numpy.arange(width, dtype=numpy.float32) / (width - <float>1.0)
        unsigned char [:, :, ::1] rgb_gradient = empty((width, height, 3), dtype=numpy.uint8)
        float [3] start = numpy.array(start_color, dtype=numpy.float32)
        int i=0, j=0
    with nogil:
        for i in prange(width, schedule='static', num_threads=8):
            for j in range(height):
               rgb_gradient[i, j, 0] = <unsigned char>(start[0] + row[i] * diff_[0])
               rgb_gradient[i, j, 1] = <unsigned char>(start[1] + row[i] * diff_[1])
               rgb_gradient[i, j, 2] = <unsigned char>(start[2] + row[i] * diff_[2])

    return asarray(rgb_gradient)


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class HorizontalBar:

    cdef:
        tuple orange, red, white
        int maximum, minimum, half_max, h, w, scan_index
        bint alpha, scan
        public int current_value
        object font, scan_surface, start_color, end_color, gradient_array
        float factor

    def __init__(self,
                 start_color_,    # pygame.Color (left color on the gradient bar)
                 end_color_,      # pygame.Color (right color on the gradient bar)
                 int maximum_,          # Max value (e.g maximum life, maximum energy etc)
                 int minimum_,          # Min value (e.g minimum life etc)
                 int current_value_,    # Actual value
                 bint alpha_,           # bool, allow bar transparency
                 int h_,                # bar's height
                 int w_,                # bar's length
                 bint scan_ = True):    # Scan effect True | False

        self.orange         = (255, 132, 64, 255)
        self.red            = (255, 0, 0, 255)
        self.white          = (255, 255, 255, 255)
        self.start_color    = start_color_
        self.end_color      = end_color_
        self.maximum        = maximum_
        self.half_max       = maximum_ // 2
        self.minimum        = minimum_
        self.current_value  = current_value_
        self.alpha          = alpha_
        self.h              = h_
        self.w              = w_
        self.scan           = scan_
        self.factor         = <float>maximum_ / <float>w_
        self.font           = FONT
        self.scan_index     = randRange(0, 20)
        self.scan_surface   = smoothscale(pygame.image.load(
            'Assets/Graphics/Hud/icon_glareFx.png').convert(), (50, self.h))

        if alpha_:
            self.gradient_array = create_horizontal_gradient_3d_alpha(
                self.w, self.h, self.start_color, self.end_color)
        else:
            self.gradient_array = create_horizontal_gradient_3d(
                self.w, self.h, (self.start_color[0], self.start_color[1], self.start_color[2]),
                                (self.end_color[0], self.end_color[1], self.end_color[2]))


    cdef slice_array(self, unsigned char [:, :, : ] array_, int start_,
                     int end_, int w_, int h_, int dim_):

        cdef int i = 0, j = 0
        cdef unsigned char [:, :, :] slice_array_ = empty((end_, h_, dim_), uint8)


        if dim_ == 3:
            with nogil:
                for i in prange(start_, end_, schedule='static', num_threads=8):
                    for j in range(h_):
                        slice_array_[i, j, 0] = array_[i, j, 0]
                        slice_array_[i, j, 1] = array_[i, j, 1]
                        slice_array_[i, j, 2] = array_[i, j, 2]

            return asarray(slice_array_)

        elif dim_ == 4:
            with nogil:
                for i in prange(start_, end_, schedule='static', num_threads=8):
                    for j in range(h_):
                        slice_array_[i, j, 0] = array_[i, j, 0]
                        slice_array_[i, j, 1] = array_[i, j, 1]
                        slice_array_[i, j, 2] = array_[i, j, 2]
                        slice_array_[i, j, 3] = array_[i, j, 3]

            return asarray(slice_array_)
        else:
            raise ValueError(
                "\n Array not understood or not valid."
                "\nExpecting array shape (width, height, 3) or (width, height, 4)")


    cdef create_surface(self, unsigned char [:, :, :] array_):

        cdef:
            int w, h, dim, new_w

        w, h, dim = (<object>array_).shape
        new_w = <int>(self.current_value // self.factor)

        array_slice = self.slice_array(array_, 0, new_w, w, h, dim)
        # TYPE RGB
        if dim == 3:
            surf = make_surface(array_slice)
        # TYPE RGBA
        else:
            surf = frombuffer(array_slice, (new_w, h), "RGBA")
        return surf


    cpdef display_value(self):
        """
        THIS CREATES A NEW SURFACE WITH THE SPECIFIED TEXT RENDERED ON IT.

        :return: pygame.Surface, render(text, antialias, color, background=None)
        """
        cdef:
            int current_value = self.current_value
            tuple c
            int half_max = self.half_max
            int minimum  = self.minimum

        if half_max < current_value < self.maximum:
             c = self.orange

        elif minimum < current_value < half_max:
            c = self.red

        else:
            c = self.white
        return self.font.render(str(current_value), False, (c[0], c[1], c[2]))


    cpdef display_gradient(self):

        gradient_surface = self.create_surface(self.gradient_array)

        cdef:
            int w, h, dim
            int scan_index = self.scan_index

        w, h, dim  = self.gradient_array.shape

        if self.current_value > 1:

            if w == 0 or h == 0:
                return Surface((0, 0))

            if self.scan:

                if scan_index < w - 1:
                    scan_index += 4

                else:
                    scan_index = 0
                gradient_surface.blit(
                    self.scan_surface, (scan_index, 0), special_flags=BLEND_RGB_ADD)

            self.scan_index = scan_index
            return gradient_surface

        else:
            self.scan_index = scan_index
            return pygame.Surface((0, 0))