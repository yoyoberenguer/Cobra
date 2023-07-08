#cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, optimize.use_switch=True, profile=False

"""
MIT License

Copyright (c) 2019 Yoann Berenguer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

"""

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

# CYTHON IS REQUIRED
try:
    cimport cython
    from cython.parallel cimport prange
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d
    from pygame.image import frombuffer

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")


# MAPPING LIBRARY IS REQUIRED
try:
    import Mapping
except ImportError:
    raise ImportError("\n<MAPPING> library is missing on your system.")


try:
    from Mapping cimport xyz, to1d_c, to3d_c, vfb_rgb_c, vfb_c
except ImportError:
    raise ImportError("\n<Mapping> Cannot import methods.")


from libc.stdio cimport printf
from libc.stdlib cimport free, rand
from libc.math cimport round, sin


import warnings
# warnings.filterwarnings("ignore", category=DeprecationWarning)

warnings.filterwarnings("ignore", category=FutureWarning)
warnings.filterwarnings("ignore", category=RuntimeWarning)
warnings.filterwarnings("ignore", category=ImportWarning)

__version__ = 1.01

DEF OPENMP = True

if OPENMP:
    DEF THREAD_NUMBER = 10
else:
    DEF THREAD_NUMNER = 1

DEF SCHEDULE = 'static'


DEF HALF = 1.0/2.0
DEF ONE_THIRD = 1.0/3.0
DEF ONE_FOURTH = 1.0/4.0
DEF ONE_FIFTH = 1.0/5.0
DEF ONE_SIXTH = 1.0/6.0
DEF ONE_SEVENTH = 1.0/7.0
DEF ONE_HEIGHT = 1.0/8.0
DEF ONE_NINTH = 1.0/9.0
DEF ONE_TENTH = 1.0/10.0
DEF ONE_ELEVENTH = 1.0/11.0
DEF ONE_TWELVE = 1.0/12.0
DEF ONE_255 = 1.0/255.0
DEF ONE_360 = 1.0/360.0
DEF TWO_THIRD = 2.0/3.0

# TODO single float instead
cdef extern from 'Include/hsl_c.c' nogil:
    struct hsl:
        float h;
        float s;
        float l;
    struct rgb:
        float r;
        float g;
        float b;
    float * rgb_to_hsl(float r, float g, float b)nogil;
    float * hsl_to_rgb(float h, float s, float l)nogil;
    hsl struct_rgb_to_hsl(float r, float g, float b)nogil;
    rgb struct_hsl_to_rgb(float h, float s, float l)nogil;

ctypedef hsl hsl_
ctypedef rgb rgb_


# C-structure to store 3d array index values
cdef struct xyz:
    int x;
    int y;
    int z;

# ----------------- INTERFACE --------------------

def saturation_array24_mask(array_, shift_, mask_, swap_row_column=False)->Surface:
    return saturation_array24_mask_c(array_, shift_, mask_, swap_row_column)

def saturation_array32_mask(array_, alpha_, shift_, mask_, swap_row_column=False)->Surface:
    return saturation_array32_mask_c(array_, alpha_, shift_, mask_, swap_row_column)

def saturation_array24(array_, shift_, swap_row_column=False):
    return saturation_array24_c(array_, shift_, swap_row_column)

def saturation_array32(array_, alpha_, shift_, swap_row_column=False):
    return saturation_array32_c(array_, alpha_, shift_, swap_row_column)

def saturation_buffer_mask(buffer_, shift_, mask_array):
    return saturation_buffer_mask_c(buffer_, shift_, mask_array)


# ----------------IMPLEMENTATION -----------------



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline saturation_array24_mask_c(unsigned char [:, :, :] array_,
                               float shift_, unsigned char [:, :] mask_array, bint swap_row_column):
    """
    Change the saturation level of a pygame.Surface (compatible with 24bit only).
    Transform RGB model into HSL model and <shift_> saturation value.
    Optional mask_array to determine area to be modified.
    The mask should be a 2d array filled with float values

    :param array_: 3d numpy.ndarray shapes (w, h, 3) representing a 24bit format pygame.Surface.
    :param shift_: Value must be in range [-1.0 ... 1.0],
                   between [-1.0 ... 0.0] decrease saturation.
                   between [0.0  ... 1.0] increase saturation.
    :param mask_array: unsigned char numpy.ndarray shape (width, height) 
    :param swap_row_column: swap row and column values (only apply to array_) 
    :return: a pygame.Surface 24-bit without per-pixel information 

    """

    assert -1.0 <= shift_ <= 1.0, 'Argument shift_ must be in range [-1.0 .. 1.0].'

    cdef int width, height
    try:
        if swap_row_column:
            height, width = array_.shape[:2]
        else:
            width, height = array_.shape[:2]
    except (ValueError, pygame.error):
        raise ValueError(
            '\nArray type not compatible, expecting MemoryViewSlice got %s ' % type(array_))

    cdef:
        unsigned char *r
        unsigned char *g
        unsigned char *b
        float s
        hsl hsl_
        rgb rgb_
        int i, j

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):

                # load pixel RGB values
                r = &array_[j, i, <unsigned short int>0]
                g = &array_[j, i, <unsigned short int>1]
                b = &array_[j, i, <unsigned short int>2]

                if mask_array[i, j] > 0:
                    # # change saturation
                    hsl_ = struct_rgb_to_hsl(r[0] * ONE_255, g[0] * ONE_255, b[0] * ONE_255)
                    s = min((hsl_.s + shift_), <float>1.0)
                    s = max(s, <float>0.0)
                    rgb_ = struct_hsl_to_rgb(hsl_.h, s, hsl_.l)

                    r[0] = <unsigned char> (rgb_.r * <float>255.0)
                    g[0] = <unsigned char> (rgb_.g * <float>255.0)
                    b[0] = <unsigned char> (rgb_.b * <float>255.0)

    return pygame.image.frombuffer(array_, (width, height), 'RGB')





@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef saturation_array32_mask_c(unsigned char [:, :, :] array_, unsigned char [:, :] alpha_,
                               float shift_, float [:, :] mask_array=None, bint swap_row_column=False):
    """
    Change the saturation level of a pygame.Surface (compatible with 32bit only).
    Transform RGBA model into HSL model and <shift_> saturation value.
    Optional mask_array to determine area to be modified.
    The mask_array should be a 2d array filled with float values 

    :param swap_row_column: swap row and column values (only apply to array_) 
    :param alpha_: 2d numpy.array or MemoryViewSlice containing surface alpha values
    :param array_: 3d numpy.ndarray shapes (w, h, 4) representing a 32-bit format pygame.Surface.
    :param shift_: Value must be in range [-1.0 ... 1.0],
                   between [-1.0 ... 0.0] decrease saturation.
                   between [0.0  ... 1.0] increase saturation.
    :param mask_array: float numpy.ndarray shape (width, height) 
    :return: a pygame.Surface 32-bit with per-pixel information 
    """

    assert -1.0 <= shift_ <= 1.0, '\nshift_ argument must be in range [-1.0 .. 1.0].'
    assert mask_array is not None, '\nmask_array argument cannot be None.'

    cdef int width, height

    try:
        if swap_row_column:
            height, width = array_.shape[:2]
        else:
            width, height = array_.shape[:2]
    except (ValueError, pygame.error):
        try:
            height, width = array_.shape[:2]
        except (ValueError, pygame.error):
            raise ValueError('\nArray type not compatible,'
                             ' expecting MemoryViewSlice got %s ' % type(array_))

    cdef:
        unsigned char [:, :, ::1] new_array = empty((height, width, 4), dtype=uint8)
        unsigned char r, g, b
        float h, l, s
        hsl hsl_
        rgb rgb_
        int i, j

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):

                # load pixel RGB values
                r = array_[j, i, <unsigned short int>0]
                g = array_[j, i, <unsigned short int>1]
                b = array_[j, i, <unsigned short int>2]

                if mask_array[i, j] > 0:
                    # # change saturation
                    hsl_ = struct_rgb_to_hsl(r * ONE_255, g * ONE_255, b * ONE_255)
                    h = hsl_.h
                    s = hsl_.s
                    l = hsl_.l
                    s = min((s + shift_), <float>1.0)
                    s = max(s, <float>0.0)
                    rgb_ = struct_hsl_to_rgb(h, s, l)
                    r = <unsigned char>(rgb_.r * <float>255.0)
                    g = <unsigned char>(rgb_.g * <float>255.0)
                    b = <unsigned char>(rgb_.b * <float>255.0)

                new_array[j, i, <unsigned short int>0] = r
                new_array[j, i, <unsigned short int>1] = g
                new_array[j, i, <unsigned short int>2] = b
                new_array[j, i, <unsigned short int>3] = alpha_[i, j]

    return pygame.image.frombuffer(new_array, (width, height), 'RGBA')



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef saturation_array24_c(unsigned char [:, :, :] array_, float shift_, bint swap_row_column):
    """
    Change the saturation level of an array / pygame.Surface (compatible with 24-bit format image)
    Transform RGB model into HSL model and add <shift_> value to the saturation 
    
    :param swap_row_column: swap row and column values (only apply to array_) 
    :param array_: numpy.ndarray (w, h, 3) uint8 representing 24 bit format surface
    :param shift_: Value must be in range [-1.0 ... 1.0], negative values decrease saturation
    :return: a pygame.Surface 24-bit without per-pixel information 
    """

    assert -1.0 <= shift_ <= 1.0, 'Argument shift_ must be in range [-1.0 .. 1.0].'

    cdef int width, height
    try:
        if swap_row_column:
            height, width = array_.shape[:2]
        else:
            width, height = array_.shape[:2]
    except (pygame.error, ValueError):
        raise ValueError(
            '\nArray type <array_> '
            'not understood, expecting numpy.ndarray or MemoryViewSlice got %s ' % type(array_))

    cdef:
        unsigned char [:, :, ::1] new_array = empty((height, width, 3), dtype=uint8)
        int i=0, j=0
        unsigned char *r
        unsigned char *g
        unsigned char *b
        float s
        hsl hsl_
        rgb rgb_


    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):
                r = &array_[i, j, <unsigned short int>0]
                g = &array_[i, j, <unsigned short int>1]
                b = &array_[i, j, <unsigned short int>2]
                hsl_ = struct_rgb_to_hsl(<float>r[0] * ONE_255, <float>g[0] * ONE_255, <float>b[0] * ONE_255)
                s = min((hsl_.s + shift_), <float>0.5)
                s = max(s, <float>0.0)
                rgb_ = struct_hsl_to_rgb(hsl_.h, s, hsl_.l)
                new_array[j, i, <unsigned short int>0] = <unsigned char>(rgb_.r * <float>255.0)
                new_array[j, i, <unsigned short int>1] = <unsigned char>(rgb_.g * <float>255.0)
                new_array[j, i, <unsigned short int>2] = <unsigned char>(rgb_.b * <float>255.0)

    return pygame.image.frombuffer(new_array, (width, height), 'RGB')


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef saturation_array32_c(unsigned char [:, :, :] array_,
                          unsigned char [:, :] alpha_, float shift_, bint swap_row_column):
    """
    Change the saturation level of an array/ pygame.Surface (compatible with 32-bit format image only)
    Transform RGB model into HSL model and add <shift_> value to the saturation 
        
    :param swap_row_column: swap row and column values (only apply to array_) 
    :param array_: numpy.ndarray shapes (w, h, 4) representing a pygame Surface 32 bit format
    :param alpha_: numpy.ndarray shapes (w, h) containing all alpha values
    :param shift_: Value must be in range [-1.0 ... 1.0], negative values decrease saturation  
    :return: a pygame.Surface 32-bit with per-pixel information 
    """

    assert -1.0 <= shift_ <= 1.0, 'Argument shift_ must be in range [-1.0 .. 1.0].'

    cdef int width, height, alpha_width, alpha_height

    try:
        if swap_row_column:
            height, width = array_.shape[:2]
        else:
            width, height = array_.shape[:2]
    except (ValueError, pygame.error):
        try:
            # MemoryViewSlice ?
            width, height = array_.shape[:2]
        except (ValueError, pygame.error):
            raise ValueError('\n'
                'Array <array_> type not understood '
                             'expecting numpy.ndarray or MemoryViewSlice got %s ' % type(array_))
    try:
        # numpy.ndarray ?
        alpha_width, alpha_height = alpha_.shape[:2]
    except (ValueError, pygame.error):
        try:
            # MemoryViewSlice ?
            width, height = array_.shape[:2]
        except (ValueError, pygame.error):
            raise ValueError('\n'
                'Array <alpha_> type not understood '
                             'exp'
                             'ecting numpy.ndarray or MemoryViewSlice got %s ' % type(alpha_))

    cdef:
        unsigned char [:, :, ::1] new_array = empty((height, width, 4), dtype=uint8)
        int i=0, j=0
        float h, l, s
        float r, g, b
        hsl hsl_
        rgb rgb_

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):

                # Load RGB
                r, g, b = array_[i, j, <unsigned short int>0], \
                          array_[i, j, <unsigned short int>1], array_[i, j, <unsigned short int>2]
                hsl_ = struct_rgb_to_hsl(r * ONE_255, g * ONE_255, b * ONE_255)
                h = hsl_.h
                s = hsl_.s
                l = hsl_.l
                s = min((s + shift_), <float>1.0)
                s = max(s, <float>0.0)
                rgb_ = struct_hsl_to_rgb(h, s, l)
                new_array[j, i, <unsigned short int>0] = <unsigned char>(rgb_.r * <float>255.0)
                new_array[j, i, <unsigned short int>1] = <unsigned char>(rgb_.g * <float>255.0)
                new_array[j, i, <unsigned short int>2] = <unsigned char>(rgb_.b * <float>255.0)
                new_array[j, i, <unsigned short int>3] = alpha_[i, j]

    return pygame.image.frombuffer(new_array, (width, height), 'RGBA')


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef saturation_buffer_mask_c(unsigned char [:] buffer_,
                              float shift_, float [:, :] mask_array):
    """
    Change the saturation level of all selected pixels from a buffer.
    Transform RGB model into HSL model and <shift_> values.
    mask_array argument cannot be null. The mask should be a 2d array
    (filled with normalized float values in range[0.0 ... 1.0]). 
    mask_array[i, j] with indices i, j represent a monochrome value (R=G=B)
    
    :param buffer_: 1d Buffer representing a 24bit format pygame.Surface
    :param shift_: Value must be in range [-1.0 ... 1.0],
                   between [-1.0 ... 0.0] decrease saturation.
                   between [0.0  ... 1.0] increase saturation.
    :param mask_array: numpy.ndarray with shape (width, height) mask_array width and height 
    must be equal to the buffer length
    :return: a pygame.Surface 24-bit without per-pixel information 
    """

    assert isinstance(shift_, float), \
           'Expecting float for argument shift_, got %s ' % type(shift_)
    assert -1.0 <= shift_ <= 1.0, 'Argument shift_ must be in range [-1.0 .. 1.0].'

    cdef int b_length
    try:
        b_length = len(<object>buffer_)
    except ValueError:
        raise ValueError("\nIncompatible buffer type got %s." % type(buffer_))

    cdef int width, height
    if mask_array is not None:
        try:
            width, height = mask_array.shape[:2]
        except (ValueError, pygame.error) as e:
            raise ValueError("\nIncompatible buffer type got %s." % type(buffer_))
    else:
        raise ValueError("\nIncompatible buffer type got %s." % type(buffer_))


    if width * height != (b_length // 3):
        raise ValueError("\nMask length and "
                         "buffer length mismatch, %s %s" % (b_length, width * height))

    cdef:
        int i=0, j=0, ii=0, ix
        unsigned char [:, :, ::1] new_array = empty((height, width, 3), dtype=uint8)
        unsigned char  r, g, b
        float h, l, s
        hsl hsl_
        rgb rgb_
        xyz pixel

    with nogil:
        for ii in prange(0, b_length, 3, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            # load pixel RGB values
            r = buffer_[ii]
            g = buffer_[ii + <unsigned short int>1]
            b = buffer_[ii + <unsigned short int>2]
            pixel = to3d_c(ii, width, <unsigned short int>3)

            if mask_array[pixel.x, pixel.y] > <float>0.0:
                hsl_ = struct_rgb_to_hsl(<float>r * ONE_255, <float>g * ONE_255, <float>b * ONE_255)
                h = hsl_.h
                s = hsl_.s
                l = hsl_.l
                s = min((s + shift_), <float>1.0)
                s = max(s, <float>0.0)
                rgb_ = struct_hsl_to_rgb(h, s, l)
                r = <unsigned char>(rgb_.r * <float>255.0)
                g = <unsigned char>(rgb_.g * <float>255.0)
                b = <unsigned char>(rgb_.b * <float>255.0)

            new_array[pixel.y, pixel.x, <unsigned short int>0] = r
            new_array[pixel.y, pixel.x, <unsigned short int>1] = g
            new_array[pixel.y, pixel.x, <unsigned short int>2] = b

    return pygame.image.frombuffer(new_array, (width, height), 'RGB')


