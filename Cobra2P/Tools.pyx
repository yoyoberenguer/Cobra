# cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8
# # distutils: extra_compile_args = -fopenmp
# # distutils: extra_link_args = -fopenmp

# todo explain inplace (different approach)

from __future__ import print_function


import warnings
# warnings.filterwarnings("ignore", category=DeprecationWarning)

warnings.filterwarnings("ignore", category=FutureWarning)
warnings.filterwarnings("ignore", category=RuntimeWarning)
warnings.filterwarnings("ignore", category=ImportWarning)

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, full_like, add, putmask, int16, arange, repeat, newaxis
except ImportError:
    print("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")
    raise SystemExit

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

try:
    import pygame
    from pygame import Rect
    from pygame.math import Vector2
    from pygame import Rect, BLEND_RGB_ADD, HWACCEL
    from pygame import Surface, SRCALPHA, mask, RLEACCEL
    from pygame.transform import rotate, scale, smoothscale
    from pygame.surfarray import array3d, pixels3d, array_alpha, pixels_alpha, make_surface
    from pygame.image import frombuffer

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from libc.math cimport sqrt, atan2, sin, cos, exp, round
from libc.stdlib cimport srand, rand, malloc
from libc.stdio cimport printf

DEF M_PI = 3.14159265359
cdef float ONE_255 = <float>1.0 / <float>255.0

cdef extern from 'Include/randnumber.c':
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;


DEF SCHEDULE = 'static'

DEF OPENMP = True
# num_threads – The num_threads argument indicates how many threads the team should consist of.
# If not given, OpenMP will decide how many threads to use.
# Typically this is the number of cores available on the machine. However,
# this may be controlled through the omp_set_num_threads() function,
# or through the OMP_NUM_THREADS environment variable.
DEF THREAD_NUMBER = 1
if OPENMP is True:
    DEF THREAD_NUMBER = 10



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef blend_texture_24_alpha_inplace(
        object surface_, float percentage, tuple color_, tuple background_color_=(0, 0, 0)):

    if PyObject_IsInstance(color_, pygame.Color):
        color_ = (color_.r, color_.g, color_.b)

    elif PyObject_IsInstance(color_, (tuple, list)):
        assert len(color_)==3, \
            'Invalid color format, use format (R, G, B) or [R, G, B].'
        pass
    else:
        raise TypeError('Color type argument error.')

    assert PyObject_IsInstance(surface_, Surface), \
        'Argument surface_ must be a Surface got %s ' % type(surface_)

    assert <float>0.0 <= percentage <= <float>100.0, \
        "Incorrect value for argument percentage should be [0.0 ... 100.0] got %s " % percentage

    if percentage == <float>0.0:
        return surface_

    cdef unsigned char[:, :, :] source_array
    try:
        source_array = pixels3d(surface_)
    except Exception as e:
        raise ValueError("Cannot reference pixels into a 3d array.\n %s " % e)

    cdef:
        int w = source_array.shape[0]
        int h = source_array.shape[1]
        unsigned char [:] f_color = numpy.array(color_[:3], dtype=uint8)  # take only rgb values
        unsigned char [:] bc = numpy.array(background_color_, dtype=uint8)
        int c1, c2, c3
        float c4 = <float>1.0 / <float>100.0
        int i=0, j=0
        unsigned char *r
        unsigned char *g
        unsigned char *b

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                r = &source_array[i, j, <unsigned char>0]
                g = &source_array[i, j, <unsigned char>1]
                b = &source_array[i, j, <unsigned char>2]

                if r[0]!=bc[0] and g[0]!=bc[1] and b[0]!=bc[2]:

                    c1 = min(<int> (r[<unsigned char>0]
                                    + ((f_color[<unsigned char>0] - r[<unsigned char>0])
                                       * c4) * percentage), <unsigned char>255)
                    c2 = min(<int> (g[<unsigned char>0] +
                                    ((f_color[<unsigned char>1] - g[<unsigned char>0])
                                     * c4) * percentage), <unsigned char>255)
                    c3 = min(<int> (b[<unsigned char>0] +
                                    ((f_color[<unsigned char>2] - b[<unsigned char>0])
                                     * c4) * percentage), <unsigned char>255)
                    if c1 < 0:
                        c1 = 0
                    if c2 < 0:
                        c2 = 0
                    if c3 < 0:
                        c3 = 0

                    r[<unsigned char>0], g[<unsigned char>0], b[<unsigned char>0] = c1, c2, c3


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline float damped_oscillation(float t)nogil:
    return <float>(<float>exp(-t * <float>0.1) * <float>cos(M_PI * t))



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef blend_texture_32c(surface_, final_color_, float percentage):
    """
    BLEND A TEXTURE COLORS TOWARD A GIVEN SOLID COLOR

    * This version is faster than blend_texture_32
    * Create a new surface
    * Compatible with 32-bit surface with per-pixel alpha channel only.
    * Blend a texture with a percentage of given rgb color (using linear lerp method)
      Blend at 100%, all pixels from the original texture will merge toward the given pixel colors. 
      Blend at 0%, texture is unchanged (return)
    * The output image is formatted for a fast blit (convert_alpha()). 

    :param surface_    : 32-bit pygame.Surface with per-pixel transparency
    :param final_color_: Destination color. Can be a pygame color with values RGB, a tuple (RGB) or a 
    list [RGB]. RGB values must be type integer [0..255]
    :param percentage  : float; 0 - 100%, blend percentage
    :return: return a pygame.surface with per-pixels transparency. 
    """

    if PyObject_IsInstance(final_color_, pygame.Color):
        final_color_ = (final_color_.r, final_color_.g, final_color_.b)

    elif PyObject_IsInstance(final_color_, (tuple, list)):
        assert len(final_color_)==3, \
            'Invalid color format, use format (R, G, B) or [R, G, B].'
        pass
    else:
        raise TypeError('Color type argument error.')

    assert PyObject_IsInstance(surface_, Surface), \
        'Argument surface_ must be a Surface got %s ' % type(surface_)

    assert 0.0 <= percentage <= 100.0, \
        "Incorrect value for argument percentage should be [0.0 ... 100.0]  got %s " % percentage

    if percentage == 0:
        return surface_

    cdef unsigned char [:, :, :] source_array
    cdef unsigned char [:, :] alpha_channel

    try:
        source_array = pixels3d(surface_)
    except Exception as e:
        raise ValueError("Cannot reference pixels into a 3d array.\n %s " % e)

    try:
        alpha_channel = pixels_alpha(surface_)
    except Exception as e:
        raise ValueError("Cannot reference pixel alphas into a 2d array..\n %s " % e)

    cdef:
        int w = source_array.shape[0]
        int h = source_array.shape[1]
        unsigned char [:, :, ::1] final_array = empty((h, w, 4), dtype=uint8)
        unsigned char [:] f_color = numpy.array(final_color_[:3], dtype=uint8)
        # take only rgb values
        int c1, c2, c3
        float c4 = <float>1.0 / <float>100.0
        int i=0, j=0
        unsigned char r, g, b

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                r, g, b = source_array[i, j, 0], source_array[i, j, 1], source_array[i, j, 2]
                c1 = min(<int> (r + ((f_color[0] -
                                      r) * c4) * percentage), <unsigned char>255)
                c2 = min(<int> (g + ((f_color[1] -
                                      g) * c4) * percentage), <unsigned char>255)
                c3 = min(<int> (b + ((f_color[2] -
                                      b) * c4) * percentage), <unsigned char>255)
                if c1 < 0:
                    c1 = 0
                if c2 < 0:
                    c2 = 0
                if c3 < 0:
                    c3 = 0
                final_array[j, i, 0], final_array[j, i, 1], \
                final_array[j, i, 2], final_array[j, i, 3] = c1, c2, c3, alpha_channel[i, j]

    return frombuffer(final_array, (w, h), 'RGBA').convert_alpha()


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef blend_texture_24c(surface_, final_color_, float percentage):
    """
    BLEND A TEXTURE COLORS TOWARD A GIVEN SOLID COLOR

    * This version is faster than blend_texture_24
    * Create a new surface
    * Compatible with 24-bit surface without transparency
    * Blend a texture with a percentage of given rgb color (using linear lerp method)
      Blend at 100%, all pixels from the original texture will merge toward the given pixel colors. 
      Blend at 0%, texture is unchanged (return)
    * The output image is formatted for a fast blit (convert()). 

    :param surface_    : 24-bit pygame.Surface without transparency
    :param final_color_: Destination color. Can be a pygame color with values RGB, a tuple (RGB) or a 
    list [RGB]. RGB values must be type integer [0..255]
    :param percentage  : float ; 0 - 100%, blend percentage
    :return: return a pygame.surface without transparency and converted for fast blit 
    """

    if PyObject_IsInstance(final_color_, pygame.Color):
        final_color_ = (final_color_.r, final_color_.g, final_color_.b)

    elif PyObject_IsInstance(final_color_, (tuple, list)):
        assert len(final_color_)==3, \
            'Invalid color format, use format (R, G, B) or [R, G, B].'
        pass
    else:
        raise TypeError('Color type argument error.')

    assert PyObject_IsInstance(surface_, Surface), \
        'Argument surface_ must be a Surface got %s ' % type(surface_)

    assert 0.0 <= percentage <= 100.0, \
        "Incorrect value for argument percentage should be [0.0 ... 100.0] %s " % percentage

    if percentage == 0:
        return surface_

    cdef unsigned char[:, :, :] source_array
    try:
        source_array = array3d(surface_)
    except Exception as e:
        raise ValueError("Cannot reference pixels into a 3d array.\n %s " % e)

    cdef:
        int w = source_array.shape[0]
        int h = source_array.shape[1]
        unsigned char [:] f_color = numpy.array(final_color_[:3], dtype=uint8)  # take only rgb values
        int c1, c2, c3
        float c4 = 1.0 / 100.0
        int i=0, j=0
        unsigned char r, g, b

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                r, g, b = source_array[i, j, 0], source_array[i, j, 1], source_array[i, j, 2]
                c1 = min(<int> (r + ((f_color[0] -
                                      r) * c4) * percentage), <unsigned char>255)
                c2 = min(<int> (g + ((f_color[1] -
                                      g) * c4) * percentage), <unsigned char>255)
                c3 = min(<int> (b + ((f_color[2] -
                                      b) * c4) * percentage), <unsigned char>255)
                if c1 < 0:
                    c1 = 0
                if c2 < 0:
                    c2 = 0
                if c3 < 0:
                    c3 = 0
                source_array[i, j, 0], source_array[i, j, 1], source_array[i, j, 2] = c1, c2, c3

    return make_surface(asarray(source_array)).convert()




@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef blend_to_textures_24c(source_, destination_, float percentage_):
    """
    BLEND A SOURCE TEXTURE TOWARD A DESTINATION TEXTURE 

    * Video system must be initialised 
    * Textures must be same sizes
    * Compatible with 24-bit surface
    * Create a new surface
    * Image returned is converted for fast blit (convert())

    :param source_     : pygame.Surface (Source)
    :param destination_: pygame.Surface (Destination)
    :param percentage_ : float; Percentage value between [0.0 ... 100.0]
    :return: return    : Return a 24 bit pygame.Surface and blended with a percentage of the destination texture.
    """
    assert PyObject_IsInstance(source_, Surface), \
        'Argument source_ must be a pygame.Surface got %s ' % type(source_)

    assert PyObject_IsInstance(destination_, Surface), \
        'Argument destination_ must be a pygame.Surface got %s ' % type(destination_)

    assert 0.0 <= percentage_ <= 100.0, \
        "\nIncorrect value for argument percentage should be [0.0 ... 100.0] got %s " % percentage_

    if percentage_ == 0.0:
        return source_

    assert source_.get_size() == destination_.get_size(),\
        'Source and Destination surfaces must have same dimensions: ' \
        'Source (w:%s, h:%s), destination (w:%s, h:%s).' % (*source_.get_size(), *destination_.get_size())

    cdef:
            unsigned char [:, :, :] source_array
            unsigned char [:, :, :] destination_array

    try:
        source_array      = pixels3d(source_)
    except Exception as e:
        raise ValueError("\nCannot reference source pixels into a 3d array.\n %s " % e)

    try:
        destination_array = pixels3d(destination_)
    except Exception as e:
        raise ValueError("\nCannot reference destination pixels into a 3d array.\n %s " % e)

    cdef:

        int c1, c2, c3
        int i=0, j=0
        float c4 = <float>1.0/<float>100.0
        int w = source_array.shape[0]
        int h = source_array.shape[1]
        unsigned char[:, :, :] final_array = empty((h, w, 3), dtype=uint8)
        unsigned char r, g, b

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                r, g, b = source_array[i, j, 0], source_array[i, j, 1], source_array[i, j, 2]
                c1 = min(<int> (r + ((destination_array[i, j, 0] -
                                      r) * c4) * percentage_), <unsigned char>255)
                c2 = min(<int> (g + ((destination_array[i, j, 1] -
                                      g) * c4) * percentage_), <unsigned char>255)
                c3 = min(<int> (b + ((destination_array[i, j, 2] -
                                      b) * c4) * percentage_), <unsigned char>255)
                if c1 < 0:
                    c1 = 0
                if c2 < 0:
                    c2 = 0
                if c3 < 0:
                    c3 = 0
                final_array[j, i, 0], final_array[j, i, 1], final_array[j, i, 2] = c1, c2, c3

    return frombuffer(final_array, (w, h), 'RGB').convert()





@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef blend_to_textures_32c(source_, destination_, float percentage_):
    """
    BLEND A SOURCE TEXTURE TOWARD A DESTINATION TEXTURE 

    * Video system must be initialised 
    * Textures must be same sizes
    * Compatible with 32-bit surface containing per-pixel alpha channel.
    * Create a new surface
    * Image returned is converted for fast blit (convert_alpha())

    :param source_     : pygame.Surface (Source)
    :param destination_: pygame.Surface (Destination)
    :param percentage_ : float; Percentage value between [0, 100]
    :return: return    : Return a 32 bit pygame.Surface containing alpha channel and blended 
    with a percentage of the destination texture.
    """
    assert PyObject_IsInstance(source_, Surface), \
        'Argument source_ must be a pygame.Surface got %s ' % type(source_)

    assert PyObject_IsInstance(destination_, Surface), \
        'Argument destination_ must be a pygame.Surface got %s ' % type(destination_)

    assert 0.0 <= percentage_ <= 100.0, \
        "Incorrect value for argument percentage should be [0.0 ... 100.0] %s " % percentage_

    if percentage_ == 0:
        return source_

    assert source_.get_size() == destination_.get_size(),\
        'Source and Destination surfaces must have same dimensions: ' \
        'Source (w:%s, h:%s), destination (w:%s, h:%s).' % (*source_.get_size(), *destination_.get_size())

    cdef:
            unsigned char [:, :, :] source_array
            unsigned char [:, :, :] destination_array
            unsigned char [:, :] alpha_channel

    try:
        source_array      = pixels3d(source_)
    except Exception as e:
        raise ValueError("\nCannot reference source pixels into a 3d array.\n %s " % e)

    try:
        destination_array = pixels3d(destination_)
    except Exception as e:
        raise ValueError("\nCannot reference destination pixels into a 3d array.\n %s " % e)

    try:
        alpha_channel     = pixels_alpha(source_)
    except Exception as e:
        raise ValueError("\nCannot reference source pixel alphas into a 2d array..\n %s " % e)

    cdef:

        int c1, c2, c3
        int i=0, j=0
        float c4 = 1.0/100.0
        int w = source_array.shape[0]
        int h = source_array.shape[1]
        unsigned char[:, :, :] final_array = empty((h, w, 4), dtype=uint8)
        unsigned char r, g, b
    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                r, g, b = source_array[i, j, 0], source_array[i, j, 1], source_array[i, j, 2]
                c1 = min(<int> (r + ((destination_array[i, j, 0] -
                                      r) * c4) * percentage_), <unsigned char>255)
                c2 = min(<int> (g + ((destination_array[i, j, 1] -
                                      g) * c4) * percentage_), <unsigned char>255)
                c3 = min(<int> (b + ((destination_array[i, j, 2] -
                                      b) * c4) * percentage_), <unsigned char>255)
                if c1 < 0:
                    c1 = 0
                if c2 < 0:
                    c2 = 0
                if c3 < 0:
                    c3 = 0
                final_array[j, i, 0], final_array[j, i, 1], \
                final_array[j, i, 2], final_array[j, i, 3] = c1, c2, c3, alpha_channel[i, j]

    return frombuffer(final_array, (w, h), 'RGBA').convert_alpha()



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef make_transparent32(surface_, int alpha_value):
    """
    MODIFY TRANSPARENCY TO A PYGAME SURFACE 
    
    * Video system must be initialised 
    * Compatible with 32-bit surface with transparency layer 
    * Create a new 32-bit surface with transparency layer converted to fast blit (convert_alpha())
    
    :param surface_   : Surface; pygame.Surface to modify  
    :param alpha_value: integer; integer value representing the alpha value to subtract range [0 ... 255]
    :return : 32-bit Surface with new alpha value (with transparency layer)
    """
    cdef:
        unsigned char [:, :] alpha_array
        unsigned char [:, :, :] rgb_array

    try:
        rgb_array = pixels3d(surface_)
    except (pygame.error, ValueError):
        raise ValueError('Invalid surface.')

    try:
        alpha_array = pixels_alpha(surface_)
    except (pygame.error, ValueError):
        raise ValueError('Surface without per-pixel information.')

    cdef int w, h
    w, h = surface_.get_size()

    cdef:
        unsigned char [:, :, ::1] new_array = numpy.empty((h, w, 4), dtype=numpy.uint8)
        int i=0, j=0, a

    with nogil:

        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                new_array[j, i, 0] = rgb_array[i, j, 0]
                new_array[j, i, 1] = rgb_array[i, j, 1]
                new_array[j, i, 2] = rgb_array[i, j, 2]
                a = alpha_array[i, j] - alpha_value
                if a < 0:
                    a = 0
                new_array[j, i, 3] = a

    return frombuffer(new_array, (w, h), 'RGBA').convert_alpha()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef void make_transparent32_inplace(image_, int alpha_):
    """
    MODIFY TRANSPARENCY TO A PYGAME SURFACE (INPLACE)
    
    * Video system must be initialised 
    * Compatible with 32-bit surface with transparency layer 
    * Change apply inplace

    :param image_: Surface; pygame.Surface to modify  
    :param alpha_: integer; integer value representing the alpha value to subtract range [0 ... 255]
    :return      : void
    """
    cdef unsigned char [:, :] alpha_array
    try:
        alpha_array = pixels_alpha(image_)
    except (pygame.error, ValueError):
        raise ValueError('Surface without per-pixel information.')

    cdef int w, h
    w, h = image_.get_size()

    cdef:
        int i=0, j=0, a
        unsigned char *p

    with nogil:

        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                p = &alpha_array[i, j]
                a = p[0] - alpha_
                if a < 0:
                    a = 0
                p[0] = a



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef unsigned char[:, :] alpha_mask(image_, int threshold_alpha_=0):
    """
    CREATE A MASK TO DETERMINE VISIBLE PIXELS IN AN IMAGE (FILTERED WITH A THRESHOLD ALPHA VALUE)
    THE 32BIT SURFACE/TEXTURE (image_) WILL BE FULLY TRANSPARENT AFTER THE FUNCTION CALL (ALL ALPHA VALUES ARE 
    REFERENCED VALUES AND SET EXPLICITLY TO ZERO).
    AFTER CALLING THE ADDITIONAL METHOD mask_alpha32_inplace, THE ORIGINAL ALPHA VALUES WILL BE RESTORED 
    
    THE METHOD RETURN A MASK ALPHA. 
    
    * ALPHA VALUES < threshold_alpha_ WILL BE SET TO ZERO. 
    * ALPHA VALUES > threshold_alpha_ WILL BE CONSERVED.
    * IF THRESHOLD_ALPHA IS SET TO ZERO (DEFAULT VALUE) THEN THE MASK ALPHA SHOULD BE A COPY OF THE LAYER ALPHA, AND 
      IN TERM OF SPEED, IT IS MUCH FASTER TO MAKE A DIRECT COPY OF THE LAYER ALPHA
    
    :param image_: pygame.Surface; Create a mask from the surface image_, the mask is 2d memoryview type array, 
        shape (w, h) of uint8 values. The Surface must be 32bit with per-pixel transparency  
    :param threshold_alpha_: integer; Alpha must be in range [0 ... 255]. 
    :return: Return a memoryview array shape (w, h) uint8 representing the alpha channel filtered with 
    a threshold alpha value (threshold_alpha_ argument).
    """

    if threshold_alpha_ < 0:
        raise ValueError("Argument alpha cannot be < 0")

    if threshold_alpha_ > 255:
        raise ValueError("Argument alpha cannot be > 255")

    cdef unsigned char [:, :] alpha_array

    try:
        alpha_array = pixels_alpha(image_)
    except (pygame.error, ValueError):
        raise ValueError('Surface without per-pixel information.')

    cdef int w, h
    w, h = image_.get_size()

    cdef:
        int i=0, j=0
        unsigned char [:, :] mask = zeros((w, h), dtype=uint8)
        unsigned char *p

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                p = &alpha_array[i, j]
                if p[0] > threshold_alpha_:
                    # Set the mask for alpha value > 0
                    mask[i, j] = p[0]
                    # Reset the alpha channel value to make the image fully transparent
                    p[0] = 0
    return mask


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef unsigned char[:, :] mask_alpha32_inplace(image_, unsigned char[:, :] mask_alpha, unsigned char value_):
    """
    RESTORE THE ALPHA VALUES OF AN IMAGE 
    
    * ALL ALPHA VALUES WHERE PREVIOUSLY SET TO ZERO TO MAKE THE TEXTURE INVISIBLE. 
    * THE ALPHA VALUES WILL INCREASE SLOWLY (with argument value_) AND WILL EVENTUALLY REACH THE ORIGINAL 
      ALPHA VALUE OF THE IMAGE THAT WAS KEPT IN THE MASK ALPHA
    * FINALLY ALL THE VALUES IN THE MASK ALPHA WILL BE SET TO ZERO AND THIS WILL SUGGEST THAT THE TRANSFORMATION
      IS COMPLETED. BY COMPARING THE RETURNED MASK ALPHA WITH A ZEROES NUMPY ARRAY OF SAME SIZE WE CAN 
      DETERMINE WHEN TO STOP THE ALGORITHM 
    
    :param image_: pygame.Surface; Image 32bit with per-pixel transparency. This image must have been processed 
    via the method alpha_mask
    :param mask_alpha: Array shape (w, h) containing filtered alpha values. This array contains all the original 
    alpha values. 
    :param value_: Integer; step for increasing the alpha value
    :return: Return the mask array shape (w, h) containing the status of the transformation. If the sum of the array 
    is not equal zero then we can assume that the transformation is still underway. 
    
    """
    if value_ > 255:
        raise ValueError("Argument value_ cannot be > 255")
    if value_ < 0:
        raise ValueError("Argument value_ cannot be < 0")


    cdef unsigned char [:, :] alpha_array

    try:
        alpha_array = pixels_alpha(image_)
    except (pygame.error, ValueError):
        raise ValueError('Surface without per-pixel information.')


    cdef int w, h
    w, h = image_.get_size()

    cdef:
        int i = 0, j = 0
        unsigned char *mask_a
        unsigned char *alpha

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):

                mask_a = &mask_alpha[i, j]
                alpha  = &alpha_array[i, j]

                if mask_a[0] > 0:
                    if alpha[0] + value_ < mask_a[0]:
                        alpha[0] = alpha[0] + value_
                    else:
                        alpha[0] = mask_a[0]
                        mask_a[0] = 0
    return mask_alpha


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef reshape(sprite_, factor_=1.0):
    """
    RESHAPE ANIMATION OR IMAGE USING PYGAME SCALE ALGORITHM

    :param sprite_: list, CREDIT_SPRITE; list containing the surface to rescale
    :param factor_: float, int or tuple; Represent the scale factor (new size)
    :return       : return  animation or a single CREDIT_SPRITE (rescale) 
    """

    cdef:
        float f_factor_
        tuple t_factor_

    if PyObject_IsInstance(factor_, (float, int)):
        # FLOAT OR INT
        try:
            f_factor_ = <float>factor_
            if f_factor_ == <float>1.0:
                return sprite_
        except ValueError:
            raise ValueError('Argument factor_ must be float or int got %s ' % type(factor_))
    # TUPLE
    else:
        try:
            t_factor_ = tuple(factor_)
            if <float>t_factor_[0] == 0.0 and <float>t_factor_[1] == 0.0:
                return sprite_
        except ValueError:
            raise ValueError('Argument factor_ must be a list or tuple got %s ' % type(factor_))

    cdef:
        int i = 0
        int w, h
        int c1, c2
        sprite_copy = sprite_.copy()

    if PyObject_IsInstance(factor_, (float, int)):
        if PyObject_IsInstance(sprite_, list):
            c1 = <int>(sprite_[i].get_width()  * factor_)
            c2 = <int>(sprite_[i].get_height() * factor_)
        else:
            c1 = <int>(sprite_.get_width()  * factor_)
            c2 = <int>(sprite_.get_height() * factor_)

    # ANIMATION
    if PyObject_IsInstance(sprite_copy, list):

        for surface in sprite_copy:
            if PyObject_IsInstance(factor_, (float, int)):
                sprite_copy[i] = scale(surface, (c1, c2))
            elif PyObject_IsInstance(factor_, (tuple, list)):
                sprite_copy[i] = scale(surface, (factor_[0], factor_[1]))
            else:
                raise ValueError('Argument factor_ incorrect '
                             'type must be float, int or tuple got %s ' % type(factor_))
            i += 1

    # SINGLE IMAGE
    else:
        if PyObject_IsInstance(factor_, (float, int)):
            sprite_copy = scale(sprite_copy,(c1, c2))
        elif PyObject_IsInstance(factor_, (tuple, list)):
            sprite_copy = scale(sprite_copy,factor_[0], factor_[1])
        else:
            raise ValueError('Argument factor_ incorrect '
                             'type must be float, int or tuple got %s ' % type(factor_))

    return sprite_copy


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef wave_xy_c(texture, float rad, int size):
    """
    Create a wave effect on a texture

    e.g:
    for angle in range(0, 360):
        surface = wave_xy(CREDIT_SPRITE, 8 * r * math.pi/180, 10)

    :param texture: pygame.Surface, CREDIT_SPRITE compatible format 24, 32-bit without per-pixel information
    :param rad: float,  angle in radian
    :param size: block size to copy (pixels)
    :return: returns a pygame.Surface 24-bit without per-pixel information
    """
    assert PyObject_IsInstance(texture, Surface), \
        'Argument texture must be a Surface got %s ' % type(texture)
    assert PyObject_IsInstance(rad, float), \
        'Argument rad must be a python float got %s ' % type(rad)
    assert PyObject_IsInstance(size, int), \
        'Argument size must be a python int got %s ' % type(size)

    try:
        rgb_array = pixels3d(texture)

    except (pygame.error, ValueError):
        # unsupported colormasks for alpha reference array
        print('Unsupported colormasks for alpha reference array.')
        raise ValueError('\nIncompatible pixel format.')

    cdef int w, h, dim
    try:
        w, h, dim = rgb_array.shape[:3]
    except (ValueError, pygame.error) as e:
        raise ValueError('Array shape not understood.')

    assert w != 0 or h !=0,\
            'Array with incorrect shape (w>0, h>0, 3) got (w:%s, h:%s, %s) ' % (w, h, dim)
    cdef:
        unsigned char [:, :, ::1] wave_array = zeros((h, w, 3), dtype=uint8)
        unsigned char [:, :, :] rgb = rgb_array
        int x, y, x_pos, y_pos, xx, yy
        int i=0, j=0
        float c1 = <float>1.0 / float(size * size)
        int w_1 = w - 1
        int h_1 = h - 1

    with nogil:
        for x in prange(0, w_1 - size, size, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            x_pos = x + size + <int>(sin(rad + <float>x * c1) * <float>size)
            for y in prange(0, h_1 - size, size, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
                y_pos = y + size + <int>(sin(rad + <float>y * c1) * <float>size)
                for i in range(0, size + 1):
                    for j in range(0, size + 1):
                        xx = x_pos + i
                        yy = y_pos + j

                        if xx > w_1:
                            xx = w_1
                        elif xx < 0:
                            xx = 0
                        if yy > h_1:
                            yy = h_1
                        elif yy < 0:
                            yy = 0
                        wave_array[yy, xx, 0] = rgb[x + i, y + j, 0]
                        wave_array[yy, xx, 1] = rgb[x + i, y + j, 1]
                        wave_array[yy, xx, 2] = rgb[x + i, y + j, 2]

    return pygame.image.frombuffer(wave_array, (w, h), 'RGB').convert()



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
# horizontal_glitch(surface, 1, 0.3, (50+r)% 20) with r in range [0, 360]
# horizontal_glitch(surface, 1, 0.3, (50-r)% 20) with r in range [0, 360]
cdef horizontal_glitch24(texture_, float rad1_, float frequency_, float amplitude_):
    """
    HORIZONTAL GLITCH EFFECT
    AFFECT THE ENTIRE TEXTURE BY ADDING PIXEL DEFORMATION
    HORIZONTAL_GLITCH_C(TEXTURE_, 1, 0.1, 10)

    :param texture_  :
    :param rad1_     : Angle deformation in degrees (cos(1) * amplitude will represent the deformation magnitude)
    :param frequency_: Angle in degrees to add every iteration for randomizing the effect
    :param amplitude_: Deformation amplitude, 10 is plenty
    :return:
    """

    try:
        source_array = pygame.surfarray.pixels3d(texture_)
    except (pygame.error, ValueError):
        print('Incompatible texture, must be 24-32bit format.')
        raise ValueError('\nMake sure the surface_ contains per-pixel alpha transparency values.')
    cdef int w, h
    w, h = texture_.get_size()

    cdef:
        int i=0, j=0
        float rad = <float>3.14/<float>180.0
        float angle = <float>0.0
        float angle1 = <float>0.0
        unsigned char [:, :, :] rgb_array = source_array
        unsigned char [:, :, ::1] new_array = numpy.empty((w, h, 3), dtype=numpy.uint8)
        int ii=0

    with nogil:
        for j in range(h):
            for i in range(w):
                ii = (i + <int>(<float>cos(angle) * amplitude_))
                if ii > w - 1:
                    ii = w - 1
                if ii < 0:
                    ii = 0

                new_array[i, j, 0],\
                new_array[i, j, 1],\
                new_array[i, j, 2] = rgb_array[ii, j, 0],\
                    rgb_array[ii, j, 1], rgb_array[ii, j, 2]

            angle1 += frequency_ * rad
            angle += rad1_ * rad + rand() % angle1 - rand() % angle1

    return pygame.surfarray.make_surface(numpy.asarray(new_array)).convert()


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef horizontal_glitch32(texture_, float rad1_, float frequency_, float amplitude_):
    """
    HORIZONTAL GLITCH EFFECT
    AFFECT THE ENTIRE TEXTURE BY ADDING PIXEL DEFORMATION
    HORIZONTAL_GLITCH_C(TEXTURE_, 1, 0.1, 10)

    :param texture_  :
    :param rad1_     : Angle deformation in degrees (cos(1) * amplitude will represent the deformation magnitude)
    :param frequency_: Angle in degrees to add every iteration for randomizing the effect
    :param amplitude_: Deformation amplitude, 10 is plenty
    :return:
    """

    try:
        source_array = pixels3d(texture_)
        source_alpha = pixels_alpha(texture_)
    except (pygame.error, ValueError):
        print('Incompatible texture, must be 32bit format.')
        raise ValueError('\nMake sure the surface_ contains per-pixel alpha transparency values.')
    cdef int w, h
    w, h = texture_.get_size()

    cdef:
        int i=0, j=0
        float rad = <float>3.14/<float>180.0
        float angle = <float>0.0
        float angle1 = <float>0.0
        unsigned char [:, :, :] rgb_array = source_array
        unsigned char [:, :] alpha_array  = source_alpha
        unsigned char [:, :, :] new_array = empty((h, w, 4), dtype=uint8)
        int ii=0

    with nogil:
        for j in range(h):
            for i in range(w):
                ii = (i + <int>(<float>cos(angle) * amplitude_))
                if ii > w - 1:
                    ii = w - 1
                if ii < 0:
                    ii = 0

                new_array[j, i, 0],\
                new_array[j, i, 1],\
                new_array[j, i, 2],\
                new_array[j, i, 3] = rgb_array[ii, j, 0],\
                    rgb_array[ii, j, 1], rgb_array[ii, j, 2], alpha_array[ii, j]
            angle1 += frequency_ * rad
            angle += rad1_ * rad + rand() % angle1 - rand() % angle1

    return pygame.image.frombuffer(new_array, (h, w), 'RGBA').convert_alpha()

#
# @cython.binding(False)
# @cython.boundscheck(False)
# @cython.wraparound(False)
# @cython.nonecheck(False)
# @cython.cdivision(True)
# @cython.profile(False)
# cdef create_horizontal_gradient_1d(int value, tuple start_color=(255, 0, 0), tuple end_color=(0, 255, 0)):
#     cdef:
#         float [:] diff_ =  numpy.array(end_color, dtype=float32) - \
#                             numpy.array(start_color, dtype=float32)
#         float [::1] row = numpy.arange(value, dtype=float32) / (value - <float>1.0)
#         unsigned char [:, ::1] rgb_gradient = empty((value, 3), dtype=uint8)
#         float [3] start = numpy.array(start_color, dtype=float32)
#         int i=0, j=0
#     with nogil:
#         for i in prange(value, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
#                rgb_gradient[i, 0] = <unsigned char>(start[0] + row[i] * diff_[0])
#                rgb_gradient[i, 1] = <unsigned char>(start[1] + row[i] * diff_[1])
#                rgb_gradient[i, 2] = <unsigned char>(start[2] + row[i] * diff_[2])
#
#     return asarray(rgb_gradient)
#
# @cython.binding(False)
# @cython.boundscheck(False)
# @cython.wraparound(False)
# @cython.nonecheck(False)
# @cython.cdivision(True)
# @cython.profile(False)
# cdef create_horizontal_gradient_3d(int width, int height, tuple start_color=(255, 0, 0), tuple end_color=(0, 255, 0)):
#     cdef:
#         float [:] diff_ =  numpy.array(end_color, dtype=float32) - \
#                             numpy.array(start_color, dtype=float32)
#         float [::1] row = numpy.arange(width, dtype=float32) / (width - <float>1.0)
#         unsigned char [:, :, ::1] rgb_gradient = empty((width, height, 3), dtype=uint8)
#         float [3] start = numpy.array(start_color, dtype=float32)
#         int i=0, j=0
#     with nogil:
#         for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
#             for j in range(height):
#                rgb_gradient[i, j, 0] = <unsigned char>(start[0] + row[i] * diff_[0])
#                rgb_gradient[i, j, 1] = <unsigned char>(start[1] + row[i] * diff_[1])
#                rgb_gradient[i, j, 2] = <unsigned char>(start[2] + row[i] * diff_[2])
#
#     return asarray(rgb_gradient)
#

#
# @cython.binding(False)
# @cython.boundscheck(False)
# @cython.wraparound(False)
# @cython.nonecheck(False)
# @cython.cdivision(True)
# @cython.profile(False)
# cdef create_horizontal_gradient_3d_alpha(
#         int width, int height, tuple start_color=(255, 0, 0, 0), tuple end_color=(0, 255, 0, 0)):
#     cdef:
#         float [:] diff_ =  numpy.array(end_color, dtype=float32) - \
#                             numpy.array(start_color, dtype=float32)
#         float [::1] row = numpy.arange(width, dtype=float32) / (width - <float>1.0)
#         unsigned char [:, :, ::1] rgba_gradient = empty((width, height, 4), dtype=uint8)
#         float [4] start = numpy.array(start_color, dtype=float32)
#         int i=0, j=0
#
#     with nogil:
#         for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
#             for j in range(height):
#                rgba_gradient[i, j, 0] = <unsigned char>(start[0] + row[i] * diff_[0])
#                rgba_gradient[i, j, 1] = <unsigned char>(start[1] + row[i] * diff_[1])
#                rgba_gradient[i, j, 2] = <unsigned char>(start[2] + row[i] * diff_[2])
#                rgba_gradient[i, j, 3] = <unsigned char> (start[3] + row[i] * diff_[3])
#
#     return asarray(rgba_gradient)


#
# @cython.binding(False)
# @cython.boundscheck(False)
# @cython.wraparound(False)
# @cython.nonecheck(False)
# @cython.cdivision(True)
# @cython.profile(False)
# cdef inline premultiply_3darray(
#         unsigned char [:, :, :] array_, float [:, :] alpha_, int w, int h, bint transpose = False):
#     cdef int i, j
#
#     cdef float [:, :, :] premult_array = numpy.empty((w, h, 3), dtype=float32)
#     cdef float [:, :, :] premult_array_transpose = numpy.empty((h, w, 3), dtype=float32)
#     cdef float c = 0
#     if not transpose:
#         with nogil:
#             for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
#                 for j in range(h):
#                     # alpha must have same dimension width and height
#                     c = alpha_[i, j] * ONE_255
#                     if c>1.0: c=1.0
#                     premult_array[i, j, 0], premult_array[i, j, 1], premult_array[i, j, 2] = \
#                         array_[i, j, 0] * c,  array_[i, j, 1] * c, array_[i, j, 2] * c
#         return premult_array
#     else:
#         with nogil:
#             for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
#                 for j in range(h):
#                     # works only if alpha_ is transposed
#                     c = alpha_[j, i] * ONE_255
#                     if c>1.0: c = 1.0
#                     premult_array_transpose[i, j, 0],\
#                     premult_array_transpose[i, j, 1], \
#                     premult_array_transpose[i, j, 2] = \
#                         array_[j, i, 0] * c,  array_[j, i, 1] * c, array_[j, i, 2] * c
#
#         return premult_array_transpose
#
# @cython.binding(False)
# @cython.boundscheck(False)
# @cython.wraparound(False)
# @cython.nonecheck(False)
# @cython.cdivision(True)
# @cython.profile(False)
# cdef inline premultiply_2darray(
#         unsigned char [:, :] array_,
#         float [:, :] alpha_, int w, int h, bint transpose=False):
#     cdef int i, j
#     cdef float [:, :] premult_array= numpy.empty((w, h), dtype=float32)
#     cdef float [:, :] premult_array_transpose = numpy.empty((h, w), dtype=float32)
#     cdef float c = <float>0.0
#     if not transpose:
#         with nogil:
#             for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
#                 for j in range(h):
#                     c = array_[i, j] * ONE_255 * alpha_[i, j]
#                     if c>1.0: c=<float>1.0
#                     premult_array[i, j] = c
#         return premult_array
#     else:
#         with nogil:
#             for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
#                 for j in range(h):
#                     # alpha_ must be transposed
#                     c = array_[j, i] / <float>255.0 * alpha_[j, i]
#                     if c > 1.0: c = <float>1.0
#                     premult_array_transpose[i, j] = c
#         return premult_array_transpose
#
#
#
#
# @cython.binding(False)
# @cython.boundscheck(False)
# @cython.wraparound(False)
# @cython.nonecheck(False)
# @cython.cdivision(True)
# @cython.profile(False)
# cdef transition(surface1_, surface2_, set_alpha1_, set_alpha2_, mask_=None):
#
#     """
#     ALPHA COMPOSITING / BLEND BETWEEN TWO SURFACES.
#     WHEN ALPHA1 IS 1.0 THE OUTPUT IMAGE IS SURFACE2. WHEN ALPHA1 IS 0.0, BOTH IMAGES ARE MERGED
#     SURFACE1, SURFACE2 and MASK MUST HAVE THE SAME DIMENSIONS (WIDTH AND HEIGHT).
#     THE MASK ALPHA MUST BE NORMALIZED.
#     set_alpha1_ & set_alpha2_ MUST BE IN RANGE [0.0 ... 1.0]
#
#     Premultiplied values
#     Calculations for RGB values -> outRGB = SrcRGB + DstRGB(1 - SrcA)
#     Calculation  for alpha channel -> outA = SrcA + DstA(1 - SrcA)
#
#     e.g :
#     image = transition(surface1, surface2, set_alpha1_=0.1, set_alpha2_=0.5,
#                        mask_=(pygame.surfarray.array_alpha(surface1)/255.0).astype(float32))
#
#
#     :param surface1_  : pygame.Surface; Surface 32 bit with per pixel alpha or convert_alpha (compatible 32bit)
#     :param surface2_  : pygame.Surface; Surface 32 bit with per pixel alpha or convert_alpha (compatible 32bit)
#     :param set_alpha1_: float; or numpy array; If float, the algo will convert this value into an array of float
#      (same value for all pixels)
#     :param set_alpha2_: float; or numpy array; If float, the algo will convert this value into an array of float
#      (same value for all pixels)
#     :param mask_: None or numpy array; mask alpha (normalized values)
#     :return: Return a 24 bit image with both surface blended together (depends on set_alpha1 value)
#     """
#
#     # sizes
#     cdef:
#         int w, h, w2, h2, i, j
#         float [:, :] alpha1
#         float [:, :] alpha2
#         unsigned char [:, :, :] rgb1
#         unsigned char [:, :, :] rgb2
#
#
#     assert 0.0 <= set_alpha1_ <= 1.0, "Argument set_alpha1_ must be in range [0.0 ... 1.0]"
#     assert 0.0 <= set_alpha2_ <= 1.0, "Argument set_alpha2_ must be in range [0.0 ... 1.0]"
#     w, h = surface1_.get_size()
#     w2, h2 = surface2_.get_size()
#     if (w, h) != (w2, h2):
#         raise ValueError('Transition effect: both surfaces must have the same dimensions')
#
#     cdef unsigned char [:, :, :] output = numpy.zeros((h, w, 4), dtype=uint8)
#     cdef float [:, :] mask_alpha = empty((w, h), dtype=float32)
#     cdef bint masking = False
#     if mask_ is not None:
#         mask_alpha = mask_
#         masking = True
#
#
#     if PyObject_IsInstance(set_alpha1_, float):
#         alpha1 = numpy.full((w, h), <float>set_alpha1_, dtype=float32)
#     else:
#         alpha1 = set_alpha1_
#
#     if PyObject_IsInstance(set_alpha2_, float):
#         alpha2 = numpy.full((w, h), <float>set_alpha2_, dtype=float32)
#     else:
#         alpha2 = set_alpha2_
#
#     try:
#         rgb1 = surface1_.get_view('3')
#     except ValueError as error:
#         ValueError('Transition effect is compatible for 24 - 32-bit surfaces only')
#     premultiply_3darray(rgb1, alpha1, w, h)  # normalized rgb1 and * alpha1
#
#     try:
#         rgb2 = surface2_.get_view('3')
#     except ValueError as error:
#         raise ValueError("Transition effect is compatible for 24 - 32-bit surfaces only")
#     premultiply_3darray(rgb2, alpha2, w2, h2) # normalized rgb1 and * alpha1
#
#
#     cdef float c1, c2, c3, c0
#
#     with nogil:
#         for i in prange(w):
#             for j in prange(h):
#                 # Calculations for RGB values -> outRGB = SrcRGB + DstRGB(1 - SrcA)
#                 if masking:
#                     if not mask_alpha[i, j] == 0:
#                         c0 = 1.0 - alpha1[i, j]
#                         c1 = rgb1[i, j, 0] + rgb2[i, j, 0] * c0
#                         c2 = rgb1[i, j, 1] + rgb2[i, j, 1] * c0
#                         c3 = rgb1[i, j, 2] + rgb2[i, j, 2] * c0
#                         output[j, i, 0] = <unsigned char>c1 if c1 <255.0 else 255
#                         output[j, i, 1] = <unsigned char>c2 if c2 <255.0 else 255
#                         output[j, i, 2] = <unsigned char>c3 if c3 <255.0 else 255
#                     ...
#                 else:
#                     c0 = <float>1.0 - <float>alpha1[i, j]
#                     c1 = <float>rgb1[i, j, 0] + <float>(rgb2[i, j, 0]) * c0
#                     c2 = <float>rgb1[i, j, 1] + <float>(rgb2[i, j, 1]) * c0
#                     c3 = <float>rgb1[i, j, 2] + <float>(rgb2[i, j, 2]) * c0
#                     output[j, i, 0] = <unsigned char> c1 if c1 < 255.0 else 255
#                     output[j, i, 1] = <unsigned char> c2 if c2 < 255.0 else 255
#                     output[j, i, 2] = <unsigned char> c3 if c3 < 255.0 else 255
#
#                 # Calculation for alpha channel -> outA = SrcA + DstA(1 - SrcA)
#                 output[j, i, 3] = <unsigned char>(
#                         (<float>alpha1[i, j] + <float>alpha2[i, j] *
#                          (<float>1.0 - <float>alpha1[i, j]))*<float>255.0)
#
#     return pygame.image.frombuffer(asarray(output), (w, h), 'RGBA').convert_alpha()
#     # return pygame.surfarray.make_surface(asarray(output[:,:,:3]))#.convert(32, RLEACCEL)



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
# SHADOW EFFECT
cdef void shadow_inplace(surface_):
    """
    CREATE A SHADOW IMAGE TO REPRESENTING THE PLAYER AIRCRAFT
    
    :param surface_: pygame Surface;  
    :return: void (change apply inplace)
    """

    cdef int width, height
    width, height = surface_.get_size()

    cdef:
        unsigned char grey
        unsigned char [:, :, :] rgb_array = pixels3d(surface_)
        int i=0, j=0
        unsigned char *r
        unsigned char *g
        unsigned char *b


    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):

                r = &rgb_array[i, j, 0]
                g = &rgb_array[i, j, 1]
                b = &rgb_array[i, j, 2]

                grey = <unsigned char>((r[0] + g[0] + b[0]) * 0.01)
                r[0], g[0], b[0] = grey, grey, grey

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef mask_shadow(surface_, mask_):
    """
    MASK A PORTION OF A SHADOW IMAGE USING A PYGAME MASK 
    
    This method is very useful when the aircraft shadow should not be fully drawn on the background, 
    e.g transition between the space background and a platform background (between space and the ground) 

     * White pixels from the mask represent full opacity alpha = 255 and black 
       pixel represent full transparency. Surface_ is a 24 bit surface and does not contains 
       an alpha channels. White pixel from the mask will allow to draw pixels on the output surface 24 bit 
       while black pixel will hide pixels at the same location. The mask will act like the set_colorkey method
     * surface_ and mask_ must have the same dimensions width & height 
    
    :param surface_: pygame Surface;  Shadow image 24 bit image without per pixel transparency 
    :param mask_   : pygame.Mask; Mask to use, the mask must be already converted to a
     Surface (black & white image)
    :return: void (change apply inplace)
    """

    cdef int width, height, w_mask, h_mask
    width, height = surface_.get_size()


    if PyObject_IsInstance(mask_, Surface):
        mask_arr = pixels3d(mask_)

    elif PyObject_IsInstance(mask_, ndarray):
        mask_arr = mask_

    else:
        raise ValueError("Argument mask_ is not a valid type got %s " % type(mask))

    try:
        w_mask, h_mask = mask_arr.shape[0], mask_arr.shape[1]
    except:
        raise ValueError("mask has incorrect dimension mask is w x h x 3")

    if w_mask != width or h_mask !=height:
        raise ValueError("Surface and mask have different width and "
                         "height surface(%s, %s) mask(%s, %s) " % (width, height, w_mask, h_mask))

    cdef:
        unsigned char grey
        unsigned char [:, :, :] rgb_array = pixels3d(surface_)
        unsigned char [:, :, :] mask_array = mask_arr
        int i=0, j=0

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):
                if mask_array[i, j, 0] == 0 and mask_array[i, j, 1] == 0 \
                        and mask_array[i, j, 2] == 0:
                    rgb_array[i, j, 0], rgb_array[i, j, 1],  rgb_array[i, j, 2] =\
                        <unsigned char>0, <unsigned char>0, <unsigned char>0
    return pygame.surfarray.make_surface(asarray(rgb_array))


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline float distance_ (float x1, float y1, float x2, float y2)nogil:

  return <float>sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
cdef inline float gaussian_ (float v, float sigma)nogil:

  return (<float>1.0 / (<float>2.0 * <float>3.14159265358 *
                        (sigma * sigma))) * <float>exp(-(v * v ) / (<float>2.0 * sigma *
 sigma))

