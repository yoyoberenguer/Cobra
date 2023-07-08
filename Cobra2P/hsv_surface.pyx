# cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

import warnings

try:
    import pygame
    from pygame.surfarray import pixels3d, pixels_alpha
    from pygame import Surface
    from pygame.image import frombuffer

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:
    cimport cython
    from cython.parallel cimport prange
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

try:
    import numpy
    from numpy import empty, uint8, zeros, float32
except ImportError:
    raise ImportError("\n<Numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

DEF ONE_255 = 1.0/255.0
DEF ONE_360 = 1.0/360.0


# EXTERNAL C CODE (file 'hsv_c.c')
cdef extern from 'Include/hsv_c.c' nogil:
    struct hsv:
        float h
        float s
        float v

    struct rgb:
        float r
        float g
        float b

    struct rgba:
        float r
        float g
        float b
        float a

    float fmax_rgb_value(float red, float green, float blue)nogil
    float fmin_rgb_value(float red, float green, float blue)nogil
    hsv struct_rgb_to_hsv(float r, float g, float b)nogil
    rgb struct_hsv_to_rgb(float h, float s, float v)nogil

ctypedef hsv HSV
ctypedef rgb RGB


DEF SCHEDULE = 'static'

DEF OPENMP = True
# num_threads – The num_threads argument indicates how many threads the team should consist of.
# If not given, OpenMP will decide how many threads to use.
# Typically this is the number of cores available on the machine. However,
# this may be controlled through the omp_set_num_threads() function,
# or through the OMP_NUM_THREADS environment variable.
DEF THREAD_NUMBER = 1
if OPENMP is True:
    DEF THREAD_NUMBER = 8

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef hsv_surface24(surface_, float shift_):
    """
    HSV (HUE, SATURATION, VALUE) ROTATION OF PIXELS 
    
    * Video system must be initialised 
    * Return a 24-bit texture with HSV rotation. The image is converted to fast blit 
    * shift_ range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
    
    :param surface_: pygame.Surface; Surface 24-bit without transparency layer  
    :param shift_  : shift range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
    :return: Return a 24-bit texture with HSV rotation. The image is converted to fast blit 
    """

    assert isinstance(surface_, Surface), \
           'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(shift_, float), \
            'Expecting float for argument shift_, got %s ' % type(shift_)
    assert 0.0<= shift_ <=1.0, 'Positional argument shift_ should be between[0.0 .. 1.0]'

    warnings.warn("Deprecated version, use hsv_surface24c instead", DeprecationWarning)

    cdef int width, height
    width, height = surface_.get_size()

    cdef:
        unsigned char [:, :, :] rgb_array

    try:
        rgb_array = pixels3d(surface_)

    except (pygame.error, ValueError):
        raise ValueError('\nInvalid pixel format.')

    cdef:
        unsigned char [:, :, ::1] new_array = zeros((height, width, 3), dtype=uint8)
        int i=0, j=0
        float r, g, b
        float h, s, v
        float rr, gg, bb, mx, mn
        float df, df_
        float f, p, q, t, ii

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):
                r, g, b = rgb_array[i, j, 0], rgb_array[i, j, 1], rgb_array[i, j, 2]

                rr = r * <float>ONE_255
                gg = g * <float>ONE_255
                bb = b * <float>ONE_255

                mx = max(rr, gg, bb)
                mn = min(rr, gg, bb)

                df = mx-mn
                if df <= 0:
                    continue
                df_ = <float>1.0/df
                if mx == mn:
                    h = <float>0.0
                elif mx == rr:
                    h = (<float>60.0 * ((gg-bb) * df_) + <float>360.0) % 360
                elif mx == gg:
                    h = (<float>60.0 * ((bb-rr) * df_) + <float>120.0) % 360
                elif mx == bb:
                    h = (<float>60.0 * ((rr-gg) * df_) + <float>240.0) % 360
                if mx == 0:
                    s = <float>0.0
                else:
                    s = df/mx
                v = mx
                h = (h * <float>ONE_360) + shift_

                if s == <float>0.0:
                    r, g, b = v, v, v
                else:
                    ii = <int>(h * <float>6.0)
                    f = (h * <float>6.0) - ii
                    p = v*(<float>1.0 - s)
                    q = v*(<float>1.0 - s * f)
                    t = v*(<float>1.0 - s * (<float>1.0 - f))
                    ii = ii % 6

                    if ii == 0:
                        r, g, b = v, t, p
                    if ii == 1:
                        r, g, b = q, v, p
                    if ii == 2:
                        r, g, b = p, v, t
                    if ii == 3:
                        r, g, b = p, q, v
                    if ii == 4:
                        r, g, b = t, p, v
                    if ii == 5:
                        r, g, b = v, p, q

                new_array[j, i, 0], new_array[j, i, 1], \
                new_array[j, i, 2] = <int>(r*<float>255.0),\
                                     <int>(g*<float>255.0), <int>(b*<float>255.0)

    return frombuffer(new_array, (width, height), 'RGB').convert()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void hsv_surface24_inplace(surface_, float shift_):
        """
        HSV (HUE, SATURATION, VALUE) ROTATION OF PIXELS INPLACE
    
        * Video system must be initialised 
        * shift_ range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
    
        :param surface_: pygame.Surface; Surface 24-bit without transparency layer  
        :param shift_  : shift range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
        :return: void
        """

        assert isinstance(surface_, Surface), \
               'Expecting Surface for argument surface_ got %s ' % type(surface_)
        assert isinstance(shift_, float), \
                'Expecting float for argument shift_, got %s ' % type(shift_)
        assert 0.0<= shift_ <=1.0, 'Positional argument shift_ should be between[0.0 .. 1.0]'

        warnings.warn("Deprecated version, use hsv_surface24c_inplace instead", DeprecationWarning)

        cdef int width, height
        width, height = surface_.get_size()

        cdef:
            unsigned char [:, :, :] rgb_array

        try:
            rgb_array = pixels3d(surface_)

        except (pygame.error, ValueError):
            raise ValueError('\nInvalid pixel format.')

        cdef:
            int i=0, j=0
            float r, g, b
            float h, s, v
            float rr, gg, bb, mx, mn
            float df, df_
            float f, p, q, t, ii

        with nogil:
            for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
                for j in range(height):
                    r, g, b = rgb_array[i, j, 0], rgb_array[i, j, 1], rgb_array[i, j, 2]

                    rr = r * <float>ONE_255
                    gg = g * <float>ONE_255
                    bb = b * <float>ONE_255

                    mx = max(rr, gg, bb)
                    mn = min(rr, gg, bb)

                    df = mx-mn
                    if df <= 0:
                        continue
                    df_ = <float>1.0/df
                    if mx == mn:
                        h = 0
                    elif mx == rr:
                        h = (<float>60.0 * ((gg-bb) * df_) + <float>360.0) % 360
                    elif mx == gg:
                        h = (<float>60.0 * ((bb-rr) * df_) + <float>120.0) % 360
                    elif mx == bb:
                        h = (<float>60.0 * ((rr-gg) * df_) + <float>240.0) % 360
                    if mx == 0:
                        s = <float>0.0
                    else:
                        s = df/mx
                    v = mx
                    h = (h * <float>ONE_360) + shift_

                    if s == <float>0.0:
                        r, g, b = v, v, v
                    else:
                        ii = <int>(h * <float>6.0)
                        f = (h * <float>6.0) - ii
                        p = v*(<float>1.0 - s)
                        q = v*(<float>1.0 - s * f)
                        t = v*(<float>1.0 - s * (<float>1.0 - f))
                        ii = ii % 6

                        if ii == 0:
                            r, g, b = v, t, p
                        if ii == 1:
                            r, g, b = q, v, p
                        if ii == 2:
                            r, g, b = p, v, t
                        if ii == 3:
                            r, g, b = p, q, v
                        if ii == 4:
                            r, g, b = t, p, v
                        if ii == 5:
                            r, g, b = v, p, q

                    rgb_array[i, j, 0], rgb_array[i, j, 1], \
                    rgb_array[i, j, 2] = <int>(r*<float>255.0), \
                                         <int>(g*<float>255.0), <int>(b*<float>255.0)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef hsv_surface24c(surface_, float shift_):
    """
    HSV (HUE, SATURATION, VALUE) ROTATION OF PIXELS 

    * Video system must be initialised 
    * Return a 24-bit texture with HSV rotation. The image is converted to fast blit 
    * shift_ range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees

    :param surface_: pygame.Surface; Surface 24-bit without transparency layer  
    :param shift_  : shift range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
    :return: Return a 24-bit texture with HSV rotation. The image is converted to fast blit 
    """

    assert isinstance(surface_, Surface), \
           'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(shift_, float), \
            'Expecting float for argument shift_, got %s ' % type(shift_)
    assert 0.0<= shift_ <=1.0, 'Positional argument shift_ should be between[0.0 .. 1.0]'

    cdef int width, height
    width, height = surface_.get_size()

    cdef:
        unsigned char [:, :, :] rgb_array

    try:
        rgb_array = pixels3d(surface_)

    except (pygame.error, ValueError):
        raise ValueError('\nInvalid pixel format.')

    cdef:
        unsigned char [:, :, ::1] new_array = zeros((height, width, 3), dtype=uint8)
        int i=0, j=0
        HSV hsv_
        RGB rgb_
        unsigned char r, g, b
        float h

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):
                r, g, b = rgb_array[i, j, 0], rgb_array[i, j, 1], rgb_array[i, j, 2]

                hsv_ = struct_rgb_to_hsv(r * <float>ONE_255, g * <float>ONE_255, b * <float>ONE_255)
                h = hsv_.h + shift_
                rgb_ = struct_hsv_to_rgb(h, hsv_.s, hsv_.v)

                new_array[j, i, 0], new_array[j, i, 1], \
                new_array[j, i, 2] = <unsigned char>(rgb_.r*<float>255.0), \
                                     <unsigned char>(rgb_.g*<float>255.0),\
                                     <unsigned char>(rgb_.b*<float>255.0)

    return frombuffer(new_array, (width, height), 'RGB').convert()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void hsv_surface24c_inplace(surface_, float shift_):
    """
    HSV (HUE, SATURATION, VALUE) ROTATION OF PIXELS INPLACE

    * Video system must be initialised 
    * shift_ range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees

    :param surface_: pygame.Surface; Surface 24-bit without transparency layer  
    :param shift_  : shift range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
    :return: void
    """

    assert isinstance(surface_, Surface), \
           'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(shift_, float), \
            'Expecting float for argument shift_, got %s ' % type(shift_)
    assert 0.0<= shift_ <=1.0, 'Positional argument shift_ should be between[0.0 .. 1.0]'

    cdef int width, height
    width, height = surface_.get_size()

    cdef:
        unsigned char [:, :, :] rgb_array

    try:
        rgb_array = pixels3d(surface_)

    except (pygame.error, ValueError):
        raise ValueError('\nInvalid pixel format.')

    cdef:
        int i=0, j=0
        HSV hsv_
        RGB rgb_
        unsigned char *r
        unsigned char *g
        unsigned char *b
        float h

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in prange(height):
                r = &rgb_array[i, j, 0]
                g = &rgb_array[i, j, 1]
                b = &rgb_array[i, j, 2]

                hsv_ = struct_rgb_to_hsv(r[0] * <float>ONE_255,
                                         g[0] * <float>ONE_255, b[0] * <float>ONE_255)
                h = hsv_.h + shift_
                rgb_ = struct_hsv_to_rgb(h, hsv_.s, hsv_.v)

                r[0], g[0], b[0] = \
                    <unsigned char>(rgb_.r*<float>255.0),\
                    <unsigned char>(rgb_.g*<float>255.0), \
                    <unsigned char>(rgb_.b*<float>255.0)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef hsv_surface32(surface_: Surface, float shift_):
    """
    HSV (HUE, SATURATION, VALUE) ROTATION OF PIXELS 

    * Video system must be initialised 
    * Return a 32-bit texture with HSV rotation. The image is converted to fast blit 
    * shift_ range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees

    :param surface_: pygame.Surface; Surface 32-bit with transparency layer  
    :param shift_  : shift range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
    :return: Return a 32-bit texture with HSV rotation. The image is converted to fast blit (convert_alpha)
    """

    assert isinstance(surface_, Surface), \
           'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(shift_, float), \
           'Expecting float for argument shift_, got %s ' % type(shift_)
    assert 0.0 <= shift_ <= 1.0, 'Positional argument shift_ should be between[0.0 .. 1.0]'

    warnings.warn("Deprecated version, use hsv_surface32c instead", DeprecationWarning)

    try:
        rgb_ = pixels3d(surface_)
        alpha_ = pixels_alpha(surface_)
    except (pygame.error, ValueError):
       raise ValueError('Compatible only for 32-bit format with per-pixel transparency.')

    cdef int width, height
    width, height = surface_.get_size()

    cdef:
        unsigned char [:, :, :] rgb_array = rgb_
        unsigned char [:, :] alpha_array = alpha_
        unsigned char [:, :, ::1] new_array = empty((height, width, 4), dtype=uint8)
        int i=0, j=0
        float r, g, b
        float h, s, v
        float rr, gg, bb, mx, mn
        float df, df_
        float f, p, q, t, ii
        float *hsv
        float *rgb

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):
                r, g, b = rgb_array[i, j, 0], rgb_array[i, j, 1], rgb_array[i, j, 2]

                rr = r * <float>ONE_255
                gg = g * <float>ONE_255
                bb = b * <float>ONE_255
                mx = max(rr, gg, bb)
                mn = min(rr, gg, bb)
                df = mx-mn
                if df <= 0:
                    new_array[j, i, 0], new_array[j, i, 1], \
                    new_array[j, i, 2], new_array[j, i, 3] = 0, 0, 0, 0
                    continue
                df_ = <float>1.0/df
                if mx == mn:
                    h = 0
                elif mx == rr:
                    h = (<float>60.0 * ((gg-bb) * df_) + <float>360.0) % 360
                elif mx == gg:
                    h = (<float>60.0 * ((bb-rr) * df_) + <float>120.0) % 360
                elif mx == bb:
                    h = (<float>60.0 * ((rr-gg) * df_) + <float>240.0) % 360
                if mx == 0:
                    s = <float>0.0
                else:
                    s = df/mx
                v = mx

                h = h * <float>ONE_360 + shift_

                if s == <float>0.0:
                    r, g, b = v, v, v
                ii = <int>(h * <float>6.0)
                f = (h * <float>6.0) - ii
                p = v*(<float>1.0 - s)
                q = v*(<float>1.0 - s * f)
                t = v*(<float>1.0 - s * (<float>1.0 - f))
                ii = ii % 6

                if ii == 0:
                    r, g, b = v, t, p
                if ii == 1:
                    r, g, b = q, v, p
                if ii == 2:
                    r, g, b = p, v, t
                if ii == 3:
                    r, g, b = p, q, v
                if ii == 4:
                    r, g, b = t, p, v
                if ii == 5:
                    r, g, b = v, p, q

                new_array[j, i, 0], new_array[j, i, 1], \
                new_array[j, i, 2], new_array[j, i, 3] = int(r*<float>255.0),\
                                                         int(g*<float>255.0),\
                                                         int(b*<float>255.0), alpha_array[i, j]

    return frombuffer(new_array, (height, width), 'RGBA').convert_alpha()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef hsv_surface32c(surface_: Surface, float shift_):
    """
    HSV (HUE, SATURATION, VALUE) ROTATION OF PIXELS 

    * Video system must be initialised 
    * Return a 32-bit texture with HSV rotation. The image is converted to fast blit 
    * shift_ range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees

    :param surface_: pygame.Surface; Surface 32-bit with transparency layer  
    :param shift_  : shift range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
    :return: Return a 32-bit texture with HSV rotation. The image is converted to fast blit (convert_alpha)
    """

    assert isinstance(surface_, Surface), \
           'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(shift_, float), \
           'Expecting float for argument shift_, got %s ' % type(shift_)
    assert 0.0 <= shift_ <= 1.0, 'Positional argument shift_ should be between[0.0 .. 1.0]'

    cdef:
        unsigned char [:, :, :] rgb_array
        unsigned char [:, :] alpha_array

    try:
        rgb_array = pixels3d(surface_)
        alpha_array = pixels_alpha(surface_)

    except (pygame.error, ValueError):
       raise ValueError('Compatible only for 32-bit format with per-pixel transparency.')

    cdef int width, height
    width, height = surface_.get_size()

    cdef:
        unsigned char [:, :, ::1] new_array = empty((height, width, 4), dtype=uint8)
        int i=0, j=0
        unsigned char r, g, b
        HSV hsv_
        RGB rgb_
        float h

    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):
                r, g, b = rgb_array[i, j, 0], rgb_array[i, j, 1], rgb_array[i, j, 2]
                hsv_ = struct_rgb_to_hsv(r * <float>ONE_255,
                                         g * <float>ONE_255, b * <float>ONE_255)
                h = hsv_.h + shift_
                rgb_ = struct_hsv_to_rgb(h, hsv_.s, hsv_.v)

                new_array[j, i, 0], new_array[j, i, 1], \
                new_array[j, i, 2], new_array[j, i, 3] = \
                    <unsigned char> (rgb_.r * <float>255.0),\
                    <unsigned char> (rgb_.g * <float>255.0), \
                    <unsigned char>(rgb_.b * <float>255.0), alpha_array[i, j]

    return frombuffer(new_array, (width, height ), 'RGBA').convert_alpha()


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void hsv_surface32c_inplace(surface_: Surface, float shift_):
    """
    HSV (HUE, SATURATION, VALUE) ROTATION OF PIXELS 

    * Video system must be initialised 
    * Return a 32-bit texture with HSV rotation. The image is converted to fast blit 
    * shift_ range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees

    :param surface_: pygame.Surface; Surface 32-bit with transparency layer  
    :param shift_  : shift range [0.0 ... 1.0] equivalent to [0.0 ... 360.0] degrees
    :return: Return a 32-bit texture with HSV rotation. The image is converted to fast blit (convert_alpha)
    """

    assert isinstance(surface_, Surface), \
           'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(shift_, float), \
           'Expecting float for argument shift_, got %s ' % type(shift_)
    assert 0.0 <= shift_ <= 1.0, 'Positional argument shift_ should be between[0.0 .. 1.0]'


    cdef:
            unsigned char [:, :, :] rgb_array
            unsigned char [:, :] alpha_array

    try:
        rgb_array = pixels3d(surface_)
        alpha_array = pixels_alpha(surface_)
    except (pygame.error, ValueError):
       raise ValueError('Compatible only for 32-bit format with per-pixel transparency.')

    cdef int width, height
    width, height = surface_.get_size()

    cdef:
        int i=0, j=0
        HSV hsv_
        RGB rgb_
        float h
        unsigned char *r
        unsigned char *g
        unsigned char *b


    with nogil:
        for i in prange(width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(height):

                r = &rgb_array[i, j, 0]
                g = &rgb_array[i, j, 1]
                b = &rgb_array[i, j, 2]

                hsv_ = struct_rgb_to_hsv(r[0] * <float>ONE_255, g[0] * <float>ONE_255,
                                         b[0] * <float>ONE_255)
                h = hsv_.h + shift_
                rgb_ = struct_hsv_to_rgb(h, hsv_.s, hsv_.v)

                r[0], g[0], b[0], rgb_array[i, j, 3] = \
                    <unsigned char> (rgb_.r * <float>255.0), \
                    <unsigned char> (rgb_.g * <float>255.0), \
                    <unsigned char>(rgb_.b * <float>255.0), alpha_array[i, j]



import colorsys
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
def hsv_shift(r, g, b, shift_):
    """ hue shifting algorithm
        Transform an RGB color into its hsv equivalent and rotate color with shift_ parameter
        then transform hsv back to RGB."""
    # The HSVA components are in the ranges H = [0, 360], S = [0, 100], V = [0, 100], A = [0, 100].
    h, s, v, a = pygame.Color(int(r), int(g), int(b)).hsva
    # shift the hue and revert back to rgb
    rgb_color = colorsys.hsv_to_rgb((h + shift_) * <float>0.002777,
                                    s * <float>0.01, v * <float>0.01) # (1/360, 1/100, 1/100)
    return rgb_color[0] * <unsigned char>255, \
           rgb_color[1] * <unsigned char>255, \
           rgb_color[2] * <unsigned char>255

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
def hue_surface(surface_: pygame.Surface, shift_: int):

    rgb_array = pygame.surfarray.pixels3d(surface_)
    alpha_array = pygame.surfarray.pixels_alpha(surface_)

    vectorize_ = numpy.vectorize(hsv_shift)
    source_array_ = vectorize_(rgb_array[:, :, 0], rgb_array[:, :, 1], rgb_array[:, :, 2], shift_)

    source_array_ = numpy.array(source_array_).transpose(1, 2, 0)
    #array = make_array(source_array_, alpha_array)
    #return make_surface(array).convert_alpha()
    array = numpy.dstack((source_array_, alpha_array))
    return pygame.image.frombuffer((array.transpose(1, 0, 2)).copy(order='C').astype(numpy.uint8),
                                   (array.shape[:2][0], array.shape[:2][1]), 'RGBA').convert_alpha()