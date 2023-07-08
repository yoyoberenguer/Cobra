# cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8
# # distutils: extra_compile_args = -fopenmp
# # distutils: extra_link_args = -fopenmp

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

# PROJECT:
This Library provide a selection of fast CYTHON methods designed to create realistic
light effects on PYGAME surface (SDL surface).
All light's algorithms are derived from my original project (LightEffect, per-pixel light effects in
a 2d environment) that you can find using the following link: https://github.com/yoyoberenguer/LightEffect
Those algorithms have been massively improved using CYTHON and multiprocessing techniques.

The light effect algorithms are compatible for both 24, 32-bit format textures (PNG file are recomanded
for both background image and radial alpha mask).
You will find different light effect techniques that does the same job for example
area24 (array) and area24b (buffer). The main difference reside in the type of array passed to
the function (either buffer or numpy array).

# TECHNIQUE:
The technique behind the scene is very simple:

1) A portion of the screen is taken (corresponding to the size of the light's radial mask),
   often an RGB block of pixels under the light source.
2) Then applying changes to the RGB block using the pre-defined settings such
   as light coloration, light intensity value and other techniques that will be explain below,
   (smoothing, saturation, bloom effect, heat wave convection effect)
3) The final array is build from both portions (RGB block and Alpha block, process also called STACKING)
   in order to provide an array shape (w, h, 4) to be converted to a pygame surface with
   pygame.image.frombuffer method.
4) The resulting image is blit onto the background with the additive mode (blending mode) using pygame
   special flag BLEND_RGBA_ADD
   Note: For 32-bit surface, additive mode is not required as the surface contains per-pixel alpha
   transparency channel. Blending it to the background will create a rectangular surface shape and alter
   the alpha channel (creating an undesirable rendering effect).

# EFFECTS
Some effect can be added to the light source to increase realistic rendering and or to alter
light source effect.
Here is the list of available effect you can use:
- Smooth     : Smooth the final light source effect with a GAUSSIAN BLUR, kernel 5x5 in real time
- Saturation : Create a saturation effect. You can set a variable between [-1.00 ... 1.0] to adjust the
               saturation level. Below zero, the light source turns slowly to a greyscale and above zero,
               the RGB block will have saturated pixels. Default value is 0.2 and create a moderate saturation effect.
               The saturation effect is achieve using HSL algorithm that I have also attached to this project.
               HSL algorithms are build in C language (external references with rgb_to_hsl and hsl_to_rgb.
               Both techniques are using C pointer and allocate memory blocks for each function calls
               in order to return a tuple hue, saturation, lightness. This imply that each block of memory needs
               to be freed after each function call. This is done automatically but be aware of that particularity if
               you are using HSL algorithms in a different project.
               see https://github.com/yoyoberenguer/HSL for more details.
- Bloom      : Bloom effect is a computer graphics effect used in video games, demos, and high dynamic range
               rendering to reproduce an imaging artifact of real-world cameras.
               In our scenario, the bloom effect will enhance the light effect when the light source
               is pointed toward another bright area / light spot etc. It use a bright pass filter (that can be
               adjusted with the variable threshold default 0). Threshold determine if a pixel will be included in the
               bloom process. The highest the threshold the fewer pixel will be included into the bloom process.
               See https://github.com/yoyoberenguer/BLOOM for more details concerning the bloom method.
- Heat       : Heat wave effect or convection effect. This algorithm create an illusion of hot air circulating in
               the light source. A mask is used to determine the condition allowing the pixels distortion.

If none of the above methods are used, a classic light source rendering effect is returned using only
coloration and light intensity parameters.

REQUIREMENT:
- python > 3.0
- numpy arrays
- pygame with SDL version 1.2 (SDL version 2 untested)
  Cython
- A compiler such visual studio, MSVC, CGYWIN setup correctly
  on your system

# MULTI - PROCESSING CAPABILITY
The flag OPENMP can be changed any time if you wish to use multiprocessing
or not (default True, using multi-processing).
Also you can change the number of threads needed with the flag THREAD_NUMBER (default 10 threads)

BUILDING PROJECT:
Use the following command:
C:\>python setup_lights.py build_ext --inplace


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

cimport numpy as np


# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface
    from pygame.image import frombuffer

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

cimport numpy as np
from libc.stdio cimport printf
from libc.stdlib cimport free, rand
from libc.math cimport round, fmin, fmax, sin
import sys

try:
    import Mapping
except ImportError:
    raise ImportError("\n<MAPPING> library is missing on your system.")

try:
    from Mapping cimport xyz, to1d_c, to3d_c, vfb_rgb_c, vfb_c
except ImportError:
    raise ImportError("\n<MAPPING> Cannot import methods.")


try:
    import Saturation
except ImportError:
    ImportError("\n<SATURATION> library is missing on your system.")

try:
    from Saturation cimport saturation_buffer_mask_c, saturation_array24_mask_c,\
        saturation_array32_mask_c, saturation_array24_c, saturation_array32_c
except ImportError:
    raise ImportError("\n<SATURATION> Cannot import methods.")



# SATURATION LIBRARY IS REQUIRED
try:
    import bloom
except ImportError:
    ImportError("\n<bloom> library is missing on your system.")

try:
    from bloom cimport bloom_effect_buffer24_c, bloom_effect_buffer32_c,\
        bloom_effect_array24_c, blur5x5_buffer24_c, \
        blur5x5_array24_c, blur5x5_array32_c
except ImportError:
    raise ImportError("\n<bloom> Cannot import methods.")



# C-structure to store 3d array index values
cdef struct xyz:
    int x;
    int y;
    int z;


DEF OPENMP = True

if OPENMP:
    DEF THREAD_NUMBER = 6
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


# ----------------- INTERFACE --------------------
# ** BELOW METHOD ACCESSIBLE FROM PYTHON SCRIPT **

# ------------------------------------------------
#                     ARRAY 
# CREATE REALISTIC LIGHT EFFECT ON 24-BIT SURFACE.
# DETERMINE THE PORTION OF THE SCREEN EXPOSED TO THE LIGHT SOURCE.
# COMPATIBLE WITH 24 BIT ONLY

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
def area24(int x, int y, np.ndarray[np.uint8_t, ndim=3]
background_rgb, np.ndarray[np.uint8_t, ndim=2] mask_alpha,
           float intensity, float [::1] color=numpy.array(
            [128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0],
           numpy.float32, copy=False), bint smooth=False, bint saturation=False,
           float sat_value=0.2, bint bloom=False, unsigned char bloom_threshold=128,
           bint heat=False, float frequency=1.0):
    return area24_c(x, y, background_rgb, mask_alpha, intensity, color,
                    smooth, saturation, sat_value, bloom, bloom_threshold, heat, frequency)



# CREATE REALISTIC LIGHT EFFECT ON 32-BIT SURFACE.
# COMPATIBLE WITH 32-BIT ONLY

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
def area32(x, y, background_rgb, mask_alpha,
           intensity, color=numpy.array([128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0],
           numpy.float32, copy=False), smooth=False, saturation=False,
           sat_value=0.2, bloom=False, heat=False, frequency=1.0):
    return area32_c(x, y, background_rgb, mask_alpha, intensity, color,
                    smooth, saturation, sat_value, bloom, heat, frequency)

# ------------------ BUFFERS --------------------------

# NO USED
# Create a light effect on the given portion of the screen (compatible 32 bit)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
def apply32b(rgb_buffer_, alpha_buffer_, intensity, color, w, h):
    return apply32b_c(rgb_buffer_, alpha_buffer_, intensity, color, w, h)
# ------------------------------------------------

# ------------------------------------------------
#                     BUFFER 
# CREATE REALISTIC LIGHT EFFECT ON 24-BIT SURFACE.
# DETERMINE THE PORTION OF THE SCREEN EXPOSED TO THE LIGHT SOURCE AND
# APPLY LIGHT EFFECT.COMPATIBLE 24 BIT ONLY
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
def area24b(x, y, background_rgb, mask_alpha,
                  color, intensity, smooth=False,
                  saturation=False, sat_value=0.2, bloom=False,
            heat=False, frequency=1.0, array_=None)->Surface:
    return area24b_c(x, y, background_rgb, mask_alpha,
                           color, intensity, smooth, saturation,
                     sat_value, bloom, heat, frequency, array_)

# UNDER TEST (ONLY BUFFERS) NOT COMPLETED YET
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
def area24bb(x, y, background_rgb, w, h, mask_alpha, mw, mh,
                  color, intensity, smooth=False,
                  saturation=False, sat_value=0.2, bloom=False, heat=False, frequency=1.0)->Surface:
    return area24bb_c(x, y, background_rgb, w, h, mask_alpha, mw, mh,
                           color, intensity, smooth, saturation, sat_value, bloom, heat, frequency)

# CREATE REALISTIC LIGHT EFFECT ON 32-BIT SURFACE.
# DETERMINE THE PORTION OF THE SCREEN EXPOSED TO THE LIGHT SOURCE AND
# APPLY LIGHT EFFECT.COMPATIBLE 32 BIT ONLY
# FIXME: NOT FINALIZED
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
def area32b(x, y, background_rgb, mask_alpha,
                  color, intensity, smooth)->Surface:
    return area32b_c(x, y, background_rgb,
                           mask_alpha, color, intensity, smooth)

# ------------------------------------------------

# CREATE 2D LIGHT EFFECT WITH VOLUMETRIC EFFECT APPLY TO ALPHA CHANNEL

def light_volume(x, y, background_rgb,  mask_alpha, intensity, color, volume=None)->Surface:
    return light_volume_c(x, y, background_rgb, mask_alpha, intensity, color, volume)
# SUB FUNCTION
def light_volumetric(rgb, alpha, intensity,
                     color, volume)->Surface:
    return light_volumetric_c(rgb, alpha, intensity, color, volume)


# --------- FLATTEN ARRAY
# FLATTEN 2d -> BUFFER
def flatten2d(array):
    return flatten2d_c(array)

# FLATTEN RGB 3d ARRAY -> BUFFER
def flatten3d_rgb(array):
    return flatten3d_rgb_c(array)

# FLATTEN RGBA 3d ARRAY -> BUFFER
def flatten3d_rgba(array):
    return flatten3d_rgba_c(array)


# -------- NORMALISATION
# ARRAY
# NORMALIZED A 2d ARRAY (SELECTIVE NORMALISATION)
def array2d_normalized_thresh(array, threshold = 127):
    return array2d_normalized_thresh_c(array, threshold)

# NORMALIZED AN ARRAY
def array2d_normalized(array):
    return array2d_normalized_c(array)

# BUFFER NORMALISATION (SELECTIVE)
def buffer_normalized_thresh(buffer, threshold = 127):
    return buffer_normalized_thresh_c(buffer, threshold)

# BUFFER NORMALISATION
def buffer_normalized(array):
    return buffer_normalized_c(array)

# ----------- STACKING
# STACK RGB AND ALPHA BUFFERS
def stack_buffer(rgb_array_, alpha_, w, h, transpose):
    return stack_buffer_c(rgb_array_, alpha_, w, h, transpose)

# STACK OBJECTS RGB AND ALPHA
def stack_object(rgb_array_, alpha_, transpose=False):
    return stack_object_c(rgb_array_, alpha_, transpose)

# ---------------- HEAT EFFECT
# HORIZONTAL HEAT WAVE EFFECT FOR RGB ARRAY (24 BIT SURFACE)
def heatwave_array24_horiz(
        rgba_array, mask_array, frequency, amplitude, attenuation=0.10, threshold=64):
    return heatwave_array24_horiz_c(
        rgba_array, mask_array, frequency, amplitude, attenuation, threshold)

# HORIZONTAL HEAT WAVE EFFECT FOR RGBA ARRAY (32 BIT SURFACE)
def heatwave_array32_horiz(
        rgba_array, mask_array, frequency, amplitude, attenuation=0.10, threshold=64):
    return heatwave_array32_horiz_c(
        rgba_array, mask_array, frequency, amplitude, attenuation, threshold)

# HORIZONTAL HEAT WAVE EFFECT FOR RGB BUFFER (COMPATIBLE 24-BIT SURFACE)
def heatwave_buffer24_horiz(rgb_buffer, mask_buffer, width, height, frequency,
                              amplitude, attenuation=0.10, threshold=64):
    return heatwave_buffer24_horiz_c(rgb_buffer, mask_buffer, width, height, frequency,
                              amplitude, attenuation, threshold)

# Create a greyscale 2d array (w, h)
def greyscale_3d_to_2d(array):
    return greyscale_3d_to_2d_c(array)

# ----------------IMPLEMENTATION -----------------

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef apply32b_c(unsigned char [:] rgb_buffer_,
               unsigned char [:] alpha_buffer_,
               float intensity,
               float [:] color,
               int w, int h):
    """
    Create a light effect on the given portion of the screen
    If the output surface is blit with the additive mode, the transparency alpha 
    will be merged with the background (rectangular image).
    In order to keep the light aspect (radial shape) do not blend with additive mode.
    Intensity can be adjusted in range (0.0 ... N). 
    
    :param rgb_buffer_: Portion of the screen to be exposed 
    (Buffer 1d numpy.ndarray or MemoryViewSlice)
    Buffer containing RGB format pixels (numpy.uint8)
    buffer = surface.transpose(1, 0)
    buffer = buffer.flatten(order='C')
    :param alpha_buffer_: Light alpha buffer. 1d Buffer numpy.ndarray or MemoryvViewSlice 
    :param intensity: Float; Value defining the light intensity  
    :param color: numpy.ndarray; Light color numpy.ndarray filled with RGB
     floating values normalized 
    such as: array([128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0], float32, copy=False) 
    :param w: integer; light width
    :param h: integer; light height
    :return: Return a pygame.Surface 32-bit 
    """

    assert intensity >= 0.0, '\nIntensity value cannot be < 0.0'
    # return an empty Surface when intensity = 0.0
    if intensity == 0.0:
        return Surface((w, h), SRCALPHA)

    cdef int a_length, b_length

    try:
        a_length = len(alpha_buffer_)
    except (ValueError, pygame.error):
        raise ValueError('\nAlpha buffer length not understood')

    try:
        b_length = len(rgb_buffer_)
    except (ValueError, pygame.error):
        raise ValueError('\nAlpha buffer length not understood')

    assert b_length == w * h * 3, \
        'Incorrect RGB buffer length, expecting %s got %s ' % (w * h * 3, b_length)
    assert a_length == w * h, \
        '\nIncorrect alpha buffer length, expecting %s got %s ' % (w * h, a_length)

    cdef:
        int i, j = 0
        unsigned char [::1] new_array = numpy.empty(w * h * <unsigned short int>44, uint8)

    with nogil:
         for i in prange(0, b_length, 4, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
              j = <int>(i / <unsigned short int>4)
              new_array[i    ] = min(<unsigned char>(rgb_buffer_[i - j    ] *
                                                     intensity * color[0]), <unsigned char>4255)
              new_array[i + <unsigned short int>41] = \
                  min(<unsigned char>(rgb_buffer_[i - j + <unsigned short int>1] *
                    intensity * color[1]), <unsigned char>255)
              new_array[i + <unsigned short int>42] = min(<unsigned char>(rgb_buffer_[i - j + 2] *
                    intensity * color[2]), <unsigned char>255)
              new_array[i + <unsigned short int>43] = alpha_buffer_[j]

    return pygame.image.frombuffer(new_array, (w, h), 'RGBA')



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline area24_c(int x, int y, background_rgb,
              mask_alpha, float intensity=1.0,
              float [::1] color=numpy.array([128.0, 128.0, 128.0], dtype=numpy.float32, copy=False),
              bint smooth=False, bint saturation=False, float sat_value=0.2, bint bloom=False,
              unsigned char bloom_threshold=128, bint heat=False, float frequency=1):
    """
    Create a realistic light effect on a pygame.Surface or texture.
    
    You can blit the output surface with additive mode using pygame flag BLEND_RGBA_ADD.
    
    Modes definition 
    ================
    SMOOTH : Apply a Gaussian blur with kernel 5x5 over the output texture, the light effect will 
    be slightly blurred.
    Timing : 5ms for a 400x400x3 texture against 0.4812155ms without it)
    
    SATURATION : Create a saturation effect (increase of the texture lightness 
    using HSL color conversion
    algorithm. saturation threshold value should be included in range [-1.0, 1.0] default is 0.2 
    Saturation above 0.5 will deteriorate the output coloration. Threshold value below zero will 
    greyscale output texture.
    Timing :  37ms for a 400x400x3 texture against 0.4812155ms without it)
    
    BLOOM: Create a bloom effect to the output texture.
    see https://github.com/yoyoberenguer/BLOOM for more information about bloom algorithm. 
    Bloom effect is CPU demanding (25ms for a 400x400x3 texture against 0.4812155ms without it)
    
    HEAT: Create a heat effect on the output itexture (using the alpha channel) 
    
    intensity: 
    Intensity is a float value defining how bright will be the light effect. 
    If intensity is zero, a new pygame.Surface is returned with RLEACCEL flag (empty surface)
    
    EFFECTS ARE NON CUMULATIVE
    
    Color allows you to change the light coloration, if omitted, the light color by default is 
    R = 128.0, G = 128.0 and B = 128.0 
       
    :param x: integer, light x coordinates (must be in range [0..max screen.size x] 
    :param y: integer, light y coordinates (must be in range [0..max screen size y]
    :param background_rgb: numpy.ndarray (w, h, 3) uint8. 3d array shape containing all RGB values
    of the background surface (display background).
    :param mask_alpha: numpy.ndarray (w, h) uint8, 2d array with light texture alpha values.
    For better appearances, choose a texture with a radial mask shape (maximum 
    light intensity in the center)  
    :param color: numpy.array; Light color (RGB float), default 
    array([128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0], float32, copy=False)
    :param intensity: float; Light intensity range [0.0 ... 20.0]   
    :param bloom: boolean; Bloom effect, default False
    :param bloom_threshold:unsigned char;
    :param sat_value: float; Set the saturation value 
    :param saturation: boolean; Saturation effect
    :param smooth: boolean; Blur effect
    :param frequency: float; frequency must be incremental
    :param heat: boolean; Allow heat wave effect 
    :return: Return a pygame surface 24 bit without per-pixel information,
    surface with same size as the light texture. Represent the lit surface.
    """

    assert intensity >= 0.0, '\nIntensity value cannot be < 0.0'


    cdef int w, h, lx, ly, ax, ay
    try:
        w, h = background_rgb.shape[0], background_rgb.shape[1]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    try:
        ax, ay = mask_alpha.shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    # return an empty Surface when intensity = 0.0
    if intensity == 0.0:
        return Surface((ax, ay), SRCALPHA), ax, ay


    lx = ax >> 1
    ly = ay >> 1

    cdef:
        int i=0, j=0
        float f
        int w_low = lx
        int w_high = lx
        int h_low = ly
        int h_high = ly
        int x1, x2, y1, y2

    with nogil:
        if x < lx:
            w_low = x
        elif x > w - lx:
            w_high = w - x

        if y < ly:
            h_low = y
        elif y >  h - ly:
            h_high = h - y

        x1 = x - w_low
        x2 = x + w_high
        y1 = y - h_low
        y2 = y + h_high
        x1 = max(x1, 0)
        x1 = min(x1, w)
        x2 = max(x2, 0)
        x2 = min(x2, w)
        y1 = max(y1, 0)
        y1 = min(y1, h)
        y2 = max(y2, 0)
        y2 = min(y2, h)

    # RGB block and ALPHA
    cdef:
        unsigned char [:, : , :] rgb = background_rgb[x1:x2, y1:y2, :]
        unsigned char [:, :] alpha = mask_alpha[lx - w_low:lx + w_high, ly - h_low:ly + h_high]

    # RGB ARRAY IS TRANSPOSED IN THE LOOP
    ax, ay = rgb.shape[:2]
    cdef:
        unsigned char [:, :, :] new_array = empty((ay, ax, 3),  numpy.uint8)
        float c1 = ONE_255 * intensity
        float red   = color[0]
        float green = color[1]
        float blue  = color[2]
        float r, g, b

    # NOTE the array is transpose
    with nogil:
        for i in prange(ax, schedule='static'):
            for j in range(ay):
                f = alpha[i, j] * c1
                r = rgb[i, j, <unsigned short int>0] * f * red
                g = rgb[i, j, <unsigned short int>1] * f * green
                b = rgb[i, j, <unsigned short int>2] * f * blue
                new_array[j, i, <unsigned short int>0] = \
                    <unsigned char>(r if r <255 else <unsigned char>255)
                new_array[j, i, <unsigned short int>1] = \
                    <unsigned char>(g if g <255 else <unsigned char>255)
                new_array[j, i, <unsigned short int>2] = \
                    <unsigned char>(b if b <255 else <unsigned char>255)
    # As the array is transposed we
    # we need to adjust ax and ay (swapped).
    ay, ax = new_array.shape[:2]

    # Return an empty surface if the x or y are not within the normal range.
    if ax <1 or ay < 1:
        return Surface((ax, ay), SRCALPHA), ax if ax > 0 else 0, ay if ay > 0 else 0

    # SATURATION
    # mask array is equivalent to array alpha normalized (float values)
    # sat_value variable can be adjusted at the function call
    # new_array is a portion of the background, the array is flipped.
    # NOTE the mask is optional, it filters the output image pixels and
    # remove bright edges or image contours.
    # If you wish to remove the mask alpha to gain an extra processing time
    # use the method saturation_array24_c instead (no mask).
    # e.g surface = saturation_array24(new_array, sat_value)
    if saturation:
        surface = saturation_array24_mask_c(new_array, sat_value, alpha, swap_row_column=True)

    # BLOOM
    elif bloom:

        surface = frombuffer(new_array, (ax, ay), 'RGB')
        # All alpha pixel values will be re-scaled between [0...1.0]
        mask = array2d_normalized_c(alpha)
        # surface = bloom_effect_buffer24_c(surface,
        # threshold_=bloom_threshold, smooth_=1, mask_=mask, fast_=True)
        surface = bloom_effect_array24_c(
            surface, threshold_=bloom_threshold, smooth_=1, mask_=mask, fast_=True)

    # SMOOTH
    # Apply a gaussian 5x5 to smooth the output image
    # Only the RGB array is needed as we are working with
    # 24 bit surface.
    # Transparency is already included into new_array (see f variable above)
    elif smooth:
        surface = frombuffer(blur5x5_array24_c(new_array), (ax, ay), "RGB")

    elif heat:
        # alpha = numpy.full((ax, ay), 255, numpy.uint8)
        surface = heatwave_array24_horiz_c(
            numpy.asarray(new_array).transpose(1, 0, 2), # --> array is transposed
            alpha, frequency, (frequency % <unsigned short int>2) / <float>400.0,
                                           attenuation=0.20, threshold=64)

    else:
        surface = frombuffer(new_array, (ax, ay), 'RGB')
        # surface.set_colorkey((0, 0, 0, 0), pygame.RLEACCEL)


    return surface, ax, ay




@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef area32_c(int x, int y, np.ndarray[np.uint8_t, ndim=3] background_rgb,
              np.ndarray[np.uint8_t, ndim=2] mask_alpha, float intensity=1.0,
              float [:] color=numpy.array([128.0, 128.0, 128.0], dtype=numpy.float32, copy=False),
              smooth=False, saturation=False,
              sat_value=0.2, bloom=False, heat=False, frequency=1.0):
    """
    
    Create a realistic light effect on a pygame.Surface or texture.
    
    You can blit the output surface with additive mode using pygame flag BLEND_RGBA_ADD.
    
    Modes definition 
    ================
    SMOOTH : Apply a Gaussian blur with kernel 5x5 over the output texture, the light effect will 
    be slightly blurred.
    Timing : 5ms for a 400x400x3 texture against 0.4812155ms without it)
    
    SATURATION : Create a saturation effect (increase of the texture lightness 
    using HSL color conversion
    algorithm. saturation threshold value should be included in range [-1.0, 1.0] default is 0.2 
    Saturation above 0.5 will deteriorate the output coloration. Threshold value below zero will 
    greyscale output texture.
    Timing :  37ms for a 400x400x3 texture against 0.4812155ms without it)
    
    BLOOM: Create a bloom effect to the output texture.
    see https://github.com/yoyoberenguer/BLOOM for more information about bloom algorithm. 
    Bloom effect is CPU demanding (25ms for a 400x400x3 texture against 0.4812155ms without it)
    
    HEAT: Create a heat effect on the output itexture (using the alpha channel) 
    
    intensity: 
    Intensity is a float value defining how bright will be the light effect. 
    If intensity is zero, a new pygame.Surface is returned with RLEACCEL flag (empty surface)
    
    EFFECTS ARE NON CUMULATIVE
    
    Color allows you to change the light coloration, if omitted, the light color by default is 
    R = 128.0, G = 128.0 and B = 128.0 
    
    
    :param x: integer, light x coordinates (must be in range [0..max screen.size x] 
    :param y: integer, light y coordinates (must be in range [0..max screen size y]
    :param background_rgb: numpy.ndarray (w, h, 3) uint8. 3d array shape containing all RGB values
    of the background surface (display background).
    :param mask_alpha: numpy.ndarray (w, h) uint8, 2d array with light texture alpha values.
    For better appearances, choose a texture with a radial mask shape (maximum 
    light intensity in the center)
    :param intensity: float; Light intensity range [0.0 ... 20.0] 
    :param color: numpy.array; Light color (RGB float), default 
    array([128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0], float32, copy=False)  
    :param bloom: boolean; Bloom effect, default False
    :param sat_value: float; Set the saturation value 
    :param saturation: boolean; Saturation effect
    :param smooth: boolean; Blur effect
    :param heat: boolean; Allow heat effect
    :param frequency: float; frequency must be incremental
    :return: Return a pygame surface 32 bit wit per-pixel information,
    """

    assert intensity >= 0.0, '\nIntensity value cannot be > 0.0'


    cdef int w, h, lx, ly, ax, ay
    try:
        w, h = background_rgb.shape[0], background_rgb.shape[1]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    try:
        ax, ay = (<object>mask_alpha).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    # Return an empty surface if the x or y are not within the normal range.
    if (x < 0) or (x > w - 1) or (y < 0) or (y > h - 1):
        return Surface((ax, ay), SRCALPHA), ax, ay

    # return an empty Surface when intensity = 0.0
    if intensity == 0.0:
        return Surface((ax, ay), SRCALPHA), ax, ay

    lx = ax >> 1
    ly = ay >> 1

    cdef:
        np.ndarray[np.uint8_t, ndim=3] rgb = empty((lx, ly, 3), uint8, order='C')
        np.ndarray[np.uint8_t, ndim=2] alpha = empty((lx, ly), uint8, order='C')
        int i=0, j=0
        float f
        int w_low = lx
        int w_high = lx
        int h_low = ly
        int h_high = ly

    if x < lx:
        w_low = x
    elif x > w - lx:
        w_high = w - x

    if y < ly:
        h_low = y
    elif y >  h - ly:
        h_high = h - y

    # RGB block and ALPHA
    rgb = background_rgb[x - w_low:x + w_high, y - h_low:y + h_high, :]
    alpha = mask_alpha[lx - w_low:lx + w_high, ly - h_low:ly + h_high]

    ax, ay = rgb.shape[:2]
    cdef unsigned char [:, :, ::1] new_array = empty((ay, ax, 4), numpy.uint8)  # TRANSPOSED

    with nogil:
        for i in prange(ax, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(ay):
                f = alpha[i, j] * ONE_255 * intensity
                new_array[j, i, <unsigned short int>0] = \
                    <unsigned char>fmin(rgb[i, j, <unsigned short int>0] * f, <float>255.0)
                new_array[j, i, <unsigned short int>1] =\
                    <unsigned char>fmin(rgb[i, j, <unsigned short int>1] * f, <float>255.0)
                new_array[j, i, <unsigned short int>2] = \
                    <unsigned char>fmin(rgb[i, j, <unsigned short int>2] * f, <float>255.0)
                new_array[j, i, <unsigned short int>3] =\
                    alpha[i, j]

    # As the array is transposed ax and ay are swapped.
    ax, ay = new_array.shape[:2]

    # SMOOTH
    # Apply a gaussian 5x5 to smooth the output image
    # Only the RGB array is needed as we are working with
    # 24 bit surface.
    # Transparency is already included into new_array (see f variable above)
    if smooth:
        ax, ay = ay, ax
        array_ = blur5x5_array32_c(new_array)
        surface = pygame.image.frombuffer(array_, (ax, ay), "RGBA")

    # SATURATION
    # sat_value variable can be adjusted at the function call
    # new_array is a portion of the background, the array is flipped.
    elif saturation:
        surface = saturation_array32_c(new_array, alpha, sat_value, False)
        ax, ay = ay, ax
    # BLOOM
    elif bloom:
        ax, ay = ay, ax
        surface = pygame.image.frombuffer(new_array, (ax, ay), 'RGBA')
        # All alpha pixel values will be re-scaled between [0...1.0]
        mask = array2d_normalized_c(alpha)
        # threshold_ = 0 (highest brightness)
        # Bright pass filter will compute all pixels
        surface = bloom_effect_buffer32_c(surface, threshold_=190, smooth_=1, mask_=mask)

    elif heat:
        ax, ay = ay, ax
        # alpha = numpy.full((ax, ay), 255, dtype=numpy.uint8)
        surface = heatwave_array32_horiz_c(numpy.asarray(new_array).transpose(1, 0, 2),
                                           # --> array is transposed
            alpha, frequency, (frequency % <unsigned short int>2) / <float>1000.0,
                                           attenuation=0.10, threshold=64)

    else:
        # (ay, ax) as array is transposed
        surface = pygame.image.frombuffer(new_array, (ay, ax), 'RGBA')
        # swap values
        ax, ay = ay, ax

    return surface, ax, ay




@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef area24b_c(int x, int y, unsigned char [:, :, :] background_rgb,
               unsigned char [:, :] mask_alpha, float [:] color, float intensity,
               bint smooth, bint saturation, float sat_value, bint bloom, bint heat,
               float frequency, array_):
    """
    Create a realistic light effect on a pygame.Surface or texture.
    
    You can blit the output surface with additive mode using pygame flag BLEND_RGBA_ADD.
    
    Modes definition 
    ================
    SMOOTH : Apply a Gaussian blur with kernel 5x5 over the output texture, the light effect will 
    be slightly blurred.
    Timing : 5ms for a 400x400x3 texture against 0.4812155ms without it)
    
    SATURATION : Create a saturation effect (increase of the texture lightness
     using HSL color conversion
    algorithm. saturation threshold value should be included in range [-1.0, 1.0] default is 0.2 
    Saturation above 0.5 will deteriorate the output coloration. Threshold value below zero will 
    greyscale output texture.
    Timing :  37ms for a 400x400x3 texture against 0.4812155ms without it)
    
    BLOOM: Create a bloom effect to the output texture.
    see https://github.com/yoyoberenguer/BLOOM for more information about bloom algorithm. 
    Bloom effect is CPU demanding (25ms for a 400x400x3 texture against 0.4812155ms without it)
    
    intensity: 
    Intensity is a float value defining how bright will be the light effect. 
    If intensity is zero, a new pygame.Surface is returned with RLEACCEL flag (empty surface)
    
    
    EFFECTS ARE NON CUMULATIVE

    :param array_: Optional mask
    :param sat_value:
    :param x: integer; x coordinate
    :param y: integer; y coordinate
    :param background_rgb: 3d numpy.ndarray (w, h, 3) containing RGB  values of the background image
    :param mask_alpha: 2d numpy.ndarray (w, h) containing light mask alpha
    :param color: numpy.ndarray containing light colours (RGB values, unsigned char values)
    :param intensity: light intensity or brightness factor
    :param smooth: bool; smooth the final image (call a gaussian 5x5 function)
    :param saturation: bool; change output image saturation, create a black and
    white array from the mask_alpha argument.
    :param bloom: bool; create a bloom effect.
    :param heat: bool; create a heat effect
    :param frequency: float; incremental variable
    :return: return a pygame.Surface same size than the mask alpha (w, h)
     without per-pixel information
    """

    cdef int w, h
    try:
        w, h = (<object>background_rgb).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    cdef int ax, ay, ax_, ay_
    try:
        ax, ay = (<object>mask_alpha).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    # assert intensity >= 0.0, '\nIntensity value cannot be < 0.0'

    cdef int lx, ly
    lx = ax >> 1
    ly = ay >> 1

    # Return an empty surface if the x or y are not within the normal range.
    if (x < 0) or (x > w - 1) or (y < 0) or (y > h - 1):
        return Surface((w, h), pygame.RLEACCEL), ax, ay

    cdef:
        int b_length = ax * ay
        # unsigned char [::1] rgb = numpy.empty(b_length * 3, uint8)

    # return an empty Surface when intensity = 0.0
    if intensity == 0.0:
        return Surface((ax, ay), pygame.RLEACCEL), ax, ay

    cdef:
        int i=0, j=0, ii, ix, jy, jy_=0, index=0
        float m, c1, c2, c3
        int w_low, w_high, h_low, h_high

    w_low  = max(x - lx, 0)
    w_high = min(x + lx, w)
    h_low  = max(y - ly, 0)
    h_high = min(y + ly, h)

    c1 = color[0] * intensity
    c2 = color[1] * intensity
    c3 = color[2] * intensity

    # new dimensions for RGB and ALPHA arrays
    ax_, ay_ = w_high - w_low, h_high - h_low

    cdef:
        unsigned char [::1] rgb = numpy.empty(ax_ * ay_ * 3, uint8)
        unsigned char [:, :] new_mask = numpy.empty((ax_, ay_), uint8)
        unsigned char [:, :] other_array = array_
        int ax3 = ax_ * 3
        int ayh = ay - h_high
        int adiff = ax - ax_

    with nogil:
        for j in prange(h_low, h_high, 1, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            jy = j - h_low  # jy must start from zero

            # adjust the mask alpha (@top and bottom)
            jy_ = jy
            if ay_ < ay and y < ly:
                    jy_ = j + ayh

            for i in range(w_low, w_high, 1):
                ix = i - w_low  # ix must start at zero

                ## ii = to1d_c(ix, jy, 0, ax_, 3)
                ii = jy * ax3 + ix * <unsigned short int>3

                # adjust the mask alpha (left side)
                if ax_ < ax and x < lx:
                    ix = ix + adiff

                new_mask[i - w_low, jy] = mask_alpha[ix, jy_]

                m = mask_alpha[ix, jy_] * ONE_255

                rgb[ii    ] = <unsigned char>fmin((background_rgb[i, j, 0]) * m * c1, <float>255.0)
                rgb[ii + <unsigned short int>1] =\
                    <unsigned char>fmin((background_rgb[i, j, 1]) * m * c2, <float>255.0)
                rgb[ii + <unsigned short int>2] =\
                    <unsigned char>fmin((background_rgb[i, j, 2]) * m * c3, <float>255.0)

    # SMOOTH
    # Apply a gaussian 5x5 to smooth the output image
    # Only the RGB array is needed as we are working with
    # 24 bit surface.
    if smooth:
        surface, array_notuse = blur5x5_buffer24_c(rgb, ax_, ay_, 3)

    # SATURATION
    # here the alpha mask (new_mask) is use for filtering
    # the output image contours
    elif saturation:
        mask = array2d_normalized_c(new_mask)
        surface = saturation_buffer_mask_c(rgb, sat_value, mask)

    # BLOOM
    elif bloom:
        surface = pygame.image.frombuffer(rgb, (ax_, ay_), 'RGB')
        # threshold = 0
        # All alpha pixel values will be re-scaled between [0...1.0]
        # Also threshold = 0 give a higher light spread and a larger lens
        # Threshold = 128 narrow the lens.

        mask = array2d_normalized_c(new_mask)

        # threshold_ = 0 (highest brightness)
        # Bright pass filter will compute all pixels
        surface = bloom_effect_buffer24_c(surface, threshold_=200, smooth_=1, mask_=mask)

    elif heat:
        surface = heatwave_buffer24_horiz_c(rgb,
            new_mask, ax_, ay_, frequency, (frequency % <unsigned short int>2) / <float>100.0,
                                            attenuation=0.10, threshold=80)

    else:
        surface = pygame.image.frombuffer(rgb, (ax_, ay_), 'RGB')

    return surface, ax_, ay_



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef area24bb_c(int x, int y, unsigned char [:] background_rgb, int w, int h,
                unsigned char [:] mask_alpha, int ax, int ay,
                float [:] color, float intensity,
                bint smooth, bint saturation, float sat_value, bint bloom,
                bint heat, float frequency):
    """
    
    Create a realistic light effect on a pygame.Surface or texture.
    
    You can blit the output surface with additive mode using pygame flag BLEND_RGBA_ADD.
    
    Modes definition 
    ================
    SMOOTH : Apply a Gaussian blur with kernel 5x5 over the output texture, the light effect will 
    be slightly blurred.
    Timing : 5ms for a 400x400x3 texture against 0.4812155ms without it)
    
    SATURATION : Create a saturation effect (increase of the texture lightness 
    using HSL color conversion
    algorithm. saturation threshold value should be included in range [-1.0, 1.0] default is 0.2 
    Saturation above 0.5 will deteriorate the output coloration. Threshold value below zero will 
    greyscale output texture.
    Timing :  37ms for a 400x400x3 texture against 0.4812155ms without it)
    
    BLOOM: Create a bloom effect to the output texture.
    see https://github.com/yoyoberenguer/BLOOM for more information about bloom algorithm. 
    Bloom effect is CPU demanding (25ms for a 400x400x3 texture against 0.4812155ms without it)
    
    intensity: 
    Intensity is a float value defining how bright will be the light effect. 
    If intensity is zero, a new pygame.Surface is returned with RLEACCEL flag (empty surface)
    
    
    EFFECTS ARE NON CUMULATIVE

    :param bloom: 
    :param ay: integer; Light surface height
    :param ax: integer; Light surface width 
    :param h: integer; background height 
    :param w: intenger; background width
    :param x: integer; x coordinate of the light source center
    :param y: integer; y coordinate of the light source center
    :param background_rgb: MemoryViewSlice or numpy.ndarray 1d buffer 
    contains all the RGB pixels of the background surface
    :param mask_alpha: 1d buffer containing alpha values of the light 
    :param color: numpy.ndarray containing light colours (RGB values, unsigned char values)
    :param intensity: float to multiply rgb values to increase color saturation
    :param smooth: bool; smooth the final image (call a gaussian 5x5 function)
    :param saturation: bool; change output image saturation
    :param sat_value: saturation value
    :param bloom: bool; create a bloom effect.
    :param heat: bool; create a heat wave effect
    :param frequency: float; incremental variable
    :return: return a pygame.Surface 24 bit format without per-pixel information
    """

    cdef int a_length, b_length

    try:
        a_length = len(background_rgb)
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    try:
        b_length = len(mask_alpha)
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    if a_length != w * h * 3:
        raise ValueError('\nArgument <background_rgb> '
                         'buffer length does not match given '
                         'width and height expecting %s got %s ' % (w * h * 3, a_length)
        )

    if b_length != ax * ay:
        raise ValueError('\nArgument <mask_alpha> '
                         'buffer length does not match given width and height'
        )

    cdef int lx, ly
    lx = ax >> 1
    ly = ay >> 1

    # Return an empty surface if the x or y are not within the normal range.
    if (x < 0) or (x > w - 1) or (y < 0) or (y > h - 1):
        return Surface((w, h), pygame.RLEACCEL), ax, ay

    # return an empty Surface when intensity = 0.0
    if intensity == 0.0:
        return Surface((ax, ay), pygame.RLEACCEL), ax, ay

    cdef:
        float m, c1, c2, c3
        int w_low, w_high, h_low, h_high

    w_low  = max(x - lx, 0)
    w_high = min(x + lx, w)
    h_low  = max(y - ly, 0)
    h_high = min(y + ly, h)

    c1 = color[0] * intensity
    c2 = color[1] * intensity
    c3 = color[2] * intensity

    cdef int ax_, ay_
    ax_, ay_ = w_high - w_low, h_high - h_low

    cdef:
        unsigned char [::1] rgb = numpy.empty(ax_ * ay_ * 3, uint8)
        unsigned char [:] new_mask = numpy.empty(ax_ * ay_, uint8)
        int i, j, index, ii, jy, ix, jy_
        int ax3 = ax_ * 3
        int w3 = w * 3
        int ayh = ay - h_high
        int adiff = ax - ax_

    with nogil:

        for j in prange(h_low, h_high, 1, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            jy = j - h_low  # iy must start from zero

            # adjust the mask alpha (@top and bottom)
            jy_ = jy
            if ay_ < ay and y < ly:
                    jy_ = j + ayh

            for i in range(w_low, w_high, 1):

                ii = j * w3 + i * <unsigned short int>3

                ix = i - w_low  # ix must start at zero

                index = jy * ax3 + ix * <unsigned short int>3

                 # adjust the mask alpha (left side)
                if ax_ < ax and x < lx:
                    ix = ix + adiff

                new_mask[<int>(index/3)] = mask_alpha[jy_* ax + ix]


                m = mask_alpha[jy_* ax + ix] * ONE_255

                # multiply pixel by alpha otherwise return a rectangle shape
                rgb[index    ] = <unsigned char>fmin(background_rgb[ii    ] * m * c1, <float>255.0)
                rgb[index + <unsigned short int>1] = \
                    <unsigned char>fmin(background_rgb[ii + 1] * m * c2, <float>255.0)
                rgb[index + <unsigned short int>2] = \
                    <unsigned char>fmin(background_rgb[ii + 2] * m * c3, <float>255.0)
    mask = new_mask

    # SMOOTH
    if smooth:
        mask = buffer_monochrome_thresh_c(new_mask, threshold_=0)
        surface, not_use = blur5x5_buffer24_c(rgb, ax_, ay_, 3, mask) #, numpy.asarray(new_mask, numpy.float32))

    # SATURATION
    elif saturation:
        new_mask = vfb_c(new_mask, numpy.empty(ax_ * ay_, dtype=numpy.uint8), ax_, ay_)  # Flip the buffer
        # mask = buffer_normalized_thresh_c(new_mask, threshold=0)
        # mask = numpy.asarray(mask, dtype=float32).reshape(ax_, ay_)
        mask = numpy.ones((ax_, ay_), dtype=numpy.float32)
        surface = saturation_buffer_mask_c(rgb, 0.20, mask)
        ...

    # BLOOM
    elif bloom:
        surface = pygame.image.frombuffer(rgb, (ax_, ay_), 'RGB')
        new_mask = vfb_c(new_mask, numpy.empty(ax_ * ay_, dtype=numpy.uint8), ax_, ay_)  # Flip the buffer
        mask = buffer_normalized_thresh_c(new_mask, threshold=0)                         # Normalized buffer
        mask = numpy.asarray(mask, dtype=float32).reshape(ax_, ay_)                      # Transform to 2d (w, h)

        surface = bloom_effect_buffer24_c(surface, threshold_=200, smooth_=1, mask_=mask)

    elif heat:
        new_mask = vfb_c(new_mask, numpy.empty(ax_ * ay_, dtype=numpy.uint8), ax_, ay_)  # Flip the buffer
        mask = numpy.asarray(new_mask, dtype=numpy.uint8).reshape(ax_, ay_)                  # Transform to 2d (w, h)
        surface = heatwave_buffer24_horiz_c(rgb,
            mask, ax_, ay_, frequency, (frequency % <unsigned short int>2) / <float>100.0,
                                            attenuation=0.10, threshold=80)


    else:
        surface = pygame.image.frombuffer(rgb, (ax_, ay_), 'RGB')

    return surface, ax_, ay_



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef area32b_c(int x, int y, unsigned char [:, :, :] background_rgb,
                unsigned char [:, :] mask_alpha, float [:] color, float intensity, bint smooth):
    """
    Create a realistic light effect on a pygame.Surface or texture
    C buffer method (slightly slower than light_area_c32 method)
    When blitting the surface onto the background display, do not use any blending effect
    This algorithm do not use multiprocessing unlike light_area_c32
    
    :param x: integer; x coordinate 
    :param y: integer; y coordinate
    :param background_rgb: 3d numpy.ndarray (w, h, 3) containing RGB  values of the background image 
    :param mask_alpha: 2d numpy.ndarray (w, h) containing light mask alpha 
    :param color: numpy.ndarray containing light colours (RGB values, unsigned char values)
    :param intensity: float to multiply rgb values to increase color saturation
    :param smooth: bool; smooth the final image
    :return: return a pygame.Surface same size than the mask alpha (w, h) with per - pixel information
    """

    cdef int w, h
    try:
        w, h = (<object>background_rgb).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    cdef int ax, ay
    try:
        ax, ay = (<object>mask_alpha).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    cdef int lx, ly
    lx = ax >> 1
    ly = ay >> 1

    # Return an empty surface if the x or y are not within the normal range.
    if (x < 0) or (x > w - 1) or (y < 0) or (y > h - 1):
        return Surface((w, h), SRCALPHA)

    cdef:
        int b_length = ax * ay
        unsigned char [::1] rgba = numpy.empty(b_length * 4, uint8)
        int w_low = lx
        int w_high = lx
        int h_low = ly
        int h_high = ly

    if x < lx:
        w_low = x
    elif x > w - lx:
        w_high = w - x

    if y < ly:
        h_low = y
    elif y >  h - ly:
        h_high = h - y

    # return an empty Surface when intensity = 0.0
    if intensity == 0.0:
        return Surface((ax, ay), SRCALPHA)

    cdef:
        int ix=0, iy=0, x_low = x - w_low, y_low = y - h_low
        int i=0, j=0, ii=0
        float c1, c2, c3

    c1 = color[0] * intensity
    c2 = color[1] * intensity
    c3 = color[2] * intensity
    with nogil:
        for j in prange(y_low, y + h_high, 1, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            iy = j - y_low
            for i in range(x_low, x + w_high, 1):
                    ix = i - x_low
                    ii = (iy * ax + ix) * <unsigned short int>4
                    rgba[ii    ] = \
                        <unsigned char>fmin(background_rgb[i, j, <unsigned short int>0] * c1, <float>255.0)
                    rgba[ii + <unsigned short int>1] = \
                        <unsigned char>fmin(background_rgb[i, j, <unsigned short int>1] * c2, <float>255.0)
                    rgba[ii + <unsigned short int>2] = \
                        <unsigned char>fmin(background_rgb[i, j, <unsigned short int>2] * c3, <float>255.0)
                    rgba[ii + <unsigned short int>3] = \
                        mask_alpha[ix, iy]//<unsigned short int>2
    if smooth:
        # TODO
        # blur_image = gaussian_blur5x5_array_32_c(numpy.asarray(rgba).reshape(ax, ay, 4))
        # return pygame.image.frombuffer(blur_image, (ay, ax), 'RGBA')
        raise NotImplemented
    else:
        return pygame.image.frombuffer(rgba, (ay, ax), 'RGBA')


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef light_volume_c(int x, int y, np.ndarray[np.uint8_t, ndim=3] background_rgb,
                    np.ndarray[np.uint8_t, ndim=2] mask_alpha, float intensity, float [:] color,
                    np.ndarray[np.uint8_t, ndim=3] volume):

    cdef int w, h, lx, ly

    try:
        w, h = background_rgb.shape[0], background_rgb.shape[1]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

     # return an empty Surface when intensity = 0.0
    if intensity == 0.0:
        return Surface((w, h), SRCALPHA), w, h

    try:
        lx, ly = (<object>mask_alpha).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    lx = lx >> 1
    ly = ly >> 1

    # Return an empty surface if the x or y are not within the normal range.
    if (x < 0) or (x > w - 1) or (y < 0) or (y > h - 1):
        return Surface((w, h), SRCALPHA), w, h

    cdef:
        np.ndarray[np.uint8_t, ndim=3] rgb = \
            numpy.empty((lx, ly, 3), numpy.uint8, order='C')
        np.ndarray[np.uint8_t, ndim=2] alpha = \
            numpy.empty((lx, ly), numpy.uint8, order='C')

        int w_low = lx
        int w_high = lx
        int h_low = ly
        int h_high = ly

    if x < lx:
        w_low = x
    elif x > w - lx:
        w_high = w - x

    if y < ly:
        h_low = y
    elif y >  h - ly:
        h_high = h - y

    # RGB block and ALPHA
    rgb = background_rgb[x - w_low:x + w_high, y - h_low:y + h_high, :]
    alpha = mask_alpha[lx - w_low:lx + w_high, ly - h_low:ly + h_high]

    if volume is not None:
        vol = light_volumetric_c(rgb, alpha, intensity, color, volume)
        return vol, vol.get_width(), vol.get_height()

    cdef int ax, ay
    ax, ay = rgb.shape[:2]

    cdef:
        unsigned char [:, :, ::1] new_array = empty((ay, ax, 3), uint8)
        int i=0, j=0
        float f

    with nogil:
        for i in prange(ax, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(ay):
                f = alpha[i, j] * ONE_255 * intensity
                new_array[j, i, <unsigned short int>0] = <unsigned char>\
                    fmin(rgb[i, j, <unsigned short int>0] * f * color[0], <unsigned char>255)
                new_array[j, i, <unsigned short int>1] = <unsigned char>\
                    fmin(rgb[i, j, <unsigned short int>1] * f * color[1], <unsigned char>255)
                new_array[j, i, <unsigned short int>2] = <unsigned char>\
                    fmin(rgb[i, j, <unsigned short int>2] * f * color[2], <unsigned char>255)

    ay, ax = new_array.shape[:2]
    return pygame.image.frombuffer(new_array, (ax, ay), 'RGB'), ax, ay




@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef light_volumetric_c(unsigned char[:, :, :] rgb, unsigned char[:, :] alpha,
                        float intensity, float [:] color, unsigned char[:, :, :] volume):
    """
    
    :param rgb: numpy.ndarray (w, h, 3) uint8, array containing all the background RGB colors values
    :param alpha: numpy.ndarray (w, h) uint8 represent the light mask alpha transparency
    :param intensity: float, light intensity default value for volumetric effect is 1e-6, adjust the value to have
    the right light illumination.
    :param color: numpy.ndarray, Light color (RGB values)
    :param volume: numpy.ndarray, array containing the 2d volumetric texture to merge with the background RGB values
    The texture should be slightly transparent with white shades colors. Texture with black nuances
    will increase opacity
    :return: Surface, Returns a surface representing a 2d light effect with a 2d volumetric
    effect display the radial mask.
    """

    cdef int w, h, vol_width, vol_height

    try:
        w, h = (<object>alpha).shape[:2]
        vol_width, vol_height = (<object>volume).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    # assert (vol_width != w or vol_height != h), \
    #        'Assertion error, Alpha (w:%s, h:%s) and Volume (w:%s, h:%s) arrays shapes are not identical.' \
    #        % (w, h, vol_width, vol_height)

    cdef:
        unsigned char [:, :, ::1] new_array = empty((h, w, 3), uint8)
        int i=0, j=0
        float f

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                f = alpha[i, j] * ONE_255 * intensity
                new_array[j, i, <unsigned short int>0] = <unsigned char>\
                    fmin(rgb[i, j, <unsigned short int>0] * f * color[0] *
                         volume[i, j, <unsigned short int>0] * ONE_255, <unsigned char>255)
                new_array[j, i, <unsigned short int>1] = <unsigned char>\
                    fmin(rgb[i, j, <unsigned short int>1] * f * color[1] *
                         volume[i, j, <unsigned short int>1] * ONE_255, <unsigned char>255)
                new_array[j, i, <unsigned short int>2] = <unsigned char>\
                    fmin(rgb[i, j, <unsigned short int>2] * f * color[2] *
                         volume[i, j, <unsigned short int>2] * ONE_255, <unsigned char>255)

    cdef int ax, ay
    ax, ay = new_array.shape[:2]
    return pygame.image.frombuffer(new_array, (w, h), 'RGB')

# ------------------------------------------- ARRAY NORMALIZATION ------------------------------
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef  float [:, :] array2d_normalized_thresh_c(unsigned char [:, :] array_, int threshold = 127):

    """
    NORMALIZED 2d ARRAY (selective normalization with threshold)
    Transform/convert an array_ shapes (w, h) containing unsigned char values 
    into a MemoryViewSlice (2d array_) with float values rescale in range [0 ... 1.0]
    UNDER THE THRESHOLD VALUE, all pixels will be black and ABOVE all pixels will be normalized.

    :param array_: numpy.array_ shape (w, h) containing unsigned int values (uint8)
    :param threshold: unsigned int; Threshold for the pixel, under that value all pixels will be black and
    above all pixels will be normalized.Default is 127
    :return: a MemoryViewSlice 2d array_ shape (w, h) with float values in range [0 ... 1.0] 
    
    """
    cdef:
        int w, h
    try:
        # assume (w, h) type array_
        w, h = array_.shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood. Only 2d array_ shape (w, h) are compatible.')

    cdef:
        int i = 0, j = 0
        float [:, :] array_f = numpy.asarray(array_, dtype='float32')

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                if array_f[i, j] > threshold:
                    array_f[i, j] = <float>(array_f[i, j] * ONE_255)
                else:
                    array_f[i, j] = <float>0.0
    return array_f

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef  float [:, :] array2d_normalized_c(unsigned char [:, :] array):

    """
    NORMALIZED AN ARRAY 
    Transform/convert an array shapes (w, h) containing unsigned char values 
    into a MemoryViewSlice (2d array) with float values rescale in range [0 ... 1.0]

    :param array: numpy.array shape (w, h) containing unsigned int values (uint8)
    :return: a MemoryViewSlice 2d array shape (w, h) with float values in range [0 ... 1.0] 
    
    """
    cdef:
        int w, h
    try:
        w, h = array.shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood. Only 2d array shape (w, h) are compatible.')

    cdef:
        int i = 0, j = 0
        float [:, :] array_f = numpy.empty((w, h), numpy.float32)

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                array_f[i, j] = <float>(array[i, j] * ONE_255)
    return array_f

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef  float [:] buffer_normalized_thresh_c(unsigned char [:] buffer_, int threshold=127):

    """
    NORMALIZED A BUFFER
    Transform/convert a BUFFER containing unsigned char values 
    into a MemoryViewSlice same shape with float values rescale in range [0 ... 1.0]

    :param threshold: integer; Threshold value
    :param buffer_: BUFFER containing unsigned int values (uint8)
    :return: a MemoryViewSlice with float values in range [0 ... 1.0] 
    
    """
    cdef:
        int b_length, i=0
    try:
        # assume (w, h) type array
       b_length = len(<object>buffer_)
    except (ValueError, pygame.error) as e:
        raise ValueError('\nBuffer type not understood, compatible only with buffers.')

    cdef:
        float [:] array_f = numpy.empty(b_length, numpy.float32)

    with nogil:
        for i in prange(b_length, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            if buffer_[i] > threshold:
                array_f[i] = <float>(buffer_[i] * ONE_255)
            else:
                array_f[i] = <float>0.0
    return array_f

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef  float [:] buffer_normalized_c(unsigned char [:] buffer_):

    """
    NORMALIZED A BUFFER
    Transform/convert a BUFFER containing unsigned char values 
    into a MemoryViewSlice same shape with float values rescale in range [0 ... 1.0]

    :param buffer_: BUFFER containing unsigned int values (uint8)
    :return: a MemoryViewSlice with float values in range [0 ... 1.0] 
    
    """
    cdef:
        int b_length, i=0
    try:
        # assume (w, h) type array
       b_length = len(buffer_)
    except (ValueError, pygame.error) as e:
        raise ValueError('\nBuffer type not understood, compatible only with buffers.')

    cdef:
        float [:] array_f = numpy.frombuffer(buffer_, dtype='float32')

    with nogil:
        for i in prange(b_length, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
                array_f[i] = <float>(buffer_[i] * ONE_255)
    return array_f


# ----------------------------------------- ARRAY/BUFFER TRANSFORMATION ------------------------------
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef  float [:] buffer_monochrome_thresh_c(unsigned char [:] buffer_, unsigned int threshold_ = 127):

    """
    Transform/convert a buffer containing unsigned char values in 
    range [0 ... 255]) into equivalent C-Buffer RGB structure mono-chromatic (float values
    in range [0.0 ... 1.0]) same length, all value below threshold_ will be zeroed.

    :param buffer_: 1d buffer containing unsigned char values (uint8)
    :param threshold_: unsigned int; Pixel threshold
    :return: 1d C-Buffer contiguous structure (MemoryViewSlice) containing all 
    pixels RGB float values (range [0...1.0] R=G=B). 
    
    """
    assert isinstance(threshold_, int), \
           "Argument threshold should be a python int, got %s " % type(threshold_)
    cdef:
        int b_length
    try:
        # assume (w, h) type array
        b_length = len(<object>buffer_)

    except (ValueError, pygame.error) as e:
        raise ValueError('\nBuffer not understood.')

    cdef:
        float [::1] flat = numpy.empty(b_length, numpy.float32)
        int i = 0

    with nogil:
        for i in prange(b_length, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            if buffer_[i] > threshold_:
                flat[i] = <float>(buffer_[i] * ONE_255)
            else:
                flat[i] = <float>0.0
    return flat


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef  unsigned char [:] flatten2d_c(unsigned char [:, :] array2d):

    """
    FLATTEN A 2D ARRAY SHAPE (W, H) INTO 1D C-BUFFER STRUCTURE OF LENGTH W * H

    :param array2d: numpy.array2d or MemoryViewSlice shape (w, h) of length w * h
    :return: 1D C-BUFFER contiguous structure (MemoryViewSlice) 
     
    """
    cdef:
        int w, h
    try:
        w, h = (<object>array2d).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood, compatible only with 2d array2d shape (w, h).')

    cdef:
        unsigned char [::1] flat = numpy.empty((w * h), dtype=numpy.uint8)
        int i = 0, j = 0, index

    with nogil:
        for j in prange(h, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for i in range(w):
                index = j * w + i
                flat[index] = array2d[i, j]
    return flat


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef unsigned char [:] flatten3d_rgb_c(unsigned char [:, :, :] rgb_array):
    """
    FLATTEN AN ARRAY SHAPE (w, h, 3) CONTAINING RGB VALUES INTO 
    1D C-BUFFER RGB STRUCTURE OF LENGTH w * h * 3

    :param rgb_array: numpy.rgb_array shape (w, h, 3) RGB FORMAT
    :return: 1d C-Buffer contiguous structure (MemoryViewSlice) containing RGB pixels values.
    NOTE: to convert the BUFFER back into a pygame.Surface, prefer pygame.image.frombuffer(buffer, (w, h), 'RGB')
    instead of pygame.surfarray.make_surface.
    
    """

    cdef:
        int w, h, dim

    try:
        w, h, dim = (<object>rgb_array).shape[:3]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood, compatible with 3d rgb_array only type(w, h, 3).')

    assert dim == 3, "Incompatible 3d rgb_array"

    cdef:
        unsigned char [::1] flat = numpy.empty((w * h * 3), dtype=numpy.uint8)
        int i = 0, j = 0, index
        # xyz v;

    with nogil:
        for j in prange(0, h, 1, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for i in range(0, w):
                # index = to1d_c(x=i, y=j, z=0, width=w, depth=3)
                index = <int>(j * w * <unsigned short int>3 + i * <unsigned short int>3)
                flat[index  ] = rgb_array[i, j, <unsigned short int>0]
                flat[index+<unsigned short int>1] = rgb_array[i, j, <unsigned short int>1]
                flat[index+<unsigned short int>2] = rgb_array[i, j, <unsigned short int>2]

    return flat


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef unsigned char [:] flatten3d_rgba_c(unsigned char [:, :, :] rgba_array):

    """
    FLATTEN ARRAY SHAPE (W, H, 4) CONTAINING RGBA VALUES INTO
    A C-BUFFER LENGTH w * h * 4

    :param rgba_array: numpy.rgba_array shape (w, h, 4) containing RGBA unsigned char values (uint8)
    :return: 1d C-Buffer contiguous structure (MemoryViewSlice) containing RGBA pixels values.
    
    """

    cdef:
        int w, h, dim
    try:
        w, h, dim = (<object>rgba_array).shape[:3]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood, compatible with 3d rgba_array only type(w, h, 4).')
    assert dim == 4, "3d rgba_array is not shape (w, h, 4)"
    cdef:
        unsigned char [::1] flat = numpy.empty((w * h * 4), dtype=numpy.uint8)
        int i = 0, j = 0, index

    with nogil:
        for j in prange(h, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for i in range(w):
                index = <int>(j * w * <unsigned short int>4 + i * <unsigned short int>4)
                flat[index    ] = rgba_array[i, j, <unsigned short int>0]
                flat[index + <unsigned short int>1] = rgba_array[i, j, <unsigned short int>1]
                flat[index + <unsigned short int>2] = rgba_array[i, j, <unsigned short int>2]
                flat[index + <unsigned short int>3] = rgba_array[i, j, <unsigned short int>3]
    return flat


#-------------------------------------- STACKING ------------------------------------------------
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef stack_object_c(unsigned char[:, :, :] rgb_array_,
                    unsigned char[:, :] alpha_, bint transpose=False):
    """
    Stack RGB pixel values together with alpha values and return a python object,
    numpy.ndarray (faster than numpy.dstack)
    If transpose is True, transpose rows and columns of output array.
    
    :param transpose: boolean; Transpose rows and columns
    :param rgb_array_: numpy.ndarray (w, h, 3) uint8 containing RGB values 
    :param alpha_: numpy.ndarray (w, h) uint8 containing alpha values 
    :return: return a contiguous numpy.ndarray (w, h, 4) uint8, stack array of RGBA pixel values
    The values are copied into a new array.
    """
    cdef int width, height
    try:
        width, height = (<object> rgb_array_).shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    cdef:
        unsigned char[:, :, ::1] new_array =  numpy.empty((width, height, 4), dtype=uint8)
        unsigned char[:, :, ::1] new_array_t =  numpy.empty((height, width, 4), dtype=uint8)
        int i=0, j=0
    # Equivalent to a numpy.dstack
    with nogil:
        # Transpose rows and columns
        if transpose:
            for j in prange(0, height, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
                for i in range(0, width):
                    new_array_t[j, i, <unsigned short int>0] = rgb_array_[i, j, <unsigned short int>0]
                    new_array_t[j, i, <unsigned short int>1] = rgb_array_[i, j, <unsigned short int>1]
                    new_array_t[j, i, <unsigned short int>2] = rgb_array_[i, j, <unsigned short int>2]
                    new_array_t[j, i, <unsigned short int>3] =  alpha_[i, j]

        else:
            for i in prange(0, width, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
                for j in range(0, height):
                    new_array[i, j, <unsigned short int>0] = rgb_array_[i, j, <unsigned short int>0]
                    new_array[i, j, <unsigned short int>1] = rgb_array_[i, j, <unsigned short int>1]
                    new_array[i, j, <unsigned short int>2] = rgb_array_[i, j, <unsigned short int>2]
                    new_array[i, j, <unsigned short int>3] =  alpha_[i, j]

    return asarray(new_array) if transpose == False else asarray(new_array_t)



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)

cdef unsigned char[::1] stack_buffer_c(rgb_array_, alpha_, int w, int h, bint transpose=False):
    """
    Stack RGB & ALPHA MemoryViewSlice C-buffers structures together.
    If transpose is True, the output MemoryViewSlice is flipped.
    
    :param h: integer; Texture height
    :param w: integer; Texture width
    :param transpose: boolean; Transpose rows and columns (default False)
    :param rgb_array_: MemoryViewSlice or pygame.BufferProxy (C-buffer type) representing the texture
    RGB values filled with uint8
    :param alpha_:  MemoryViewSlice or pygame.BufferProxy (C-buffer type) representing the texture
    alpha values filled with uint8 
    :return: Return a contiguous MemoryViewSlice representing RGBA pixel values
    """

    cdef:
        int b_length = w * h * 3
        int new_length = w * h * 4
        unsigned char [:] rgb_array = rgb_array_
        unsigned char [:] alpha = alpha_
        unsigned char [::1] new_buffer =  numpy.empty(new_length, dtype=numpy.uint8)
        unsigned char [::1] flipped_array = numpy.empty(new_length, dtype=numpy.uint8)
        int i=0, j=0, ii, jj, index, k
        int w4 = w * 4

    with nogil:

        for i in prange(0, b_length, 3, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
                ii = i // <unsigned short int>3
                jj = ii * <unsigned short int>4
                new_buffer[jj]   = rgb_array[i]
                new_buffer[jj+<unsigned short int>1] = rgb_array[i+<unsigned short int>1]
                new_buffer[jj+<unsigned short int>2] = rgb_array[i+<unsigned short int>2]
                new_buffer[jj+<unsigned short int>3] = alpha[ii]

        if transpose:
            for i in prange(0, w4, 4, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
                for j in range(0, h):
                    index = i + (w4 * j)
                    k = (j * <unsigned short int>4) + (i * h)
                    flipped_array[k    ] = new_buffer[index    ]
                    flipped_array[k + <unsigned short int>1] = new_buffer[index + <unsigned short int>1]
                    flipped_array[k + <unsigned short int>2] = new_buffer[index + <unsigned short int>2]
                    flipped_array[k + <unsigned short int>3] = new_buffer[index + <unsigned short int>3]
            return flipped_array

    return new_buffer

#------------------------------------------------ HEAT EFFECT -----------------------------------------------

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef heatwave_array24_horiz_c(unsigned char [:, :, :] rgb_array,
                            unsigned char [:, :] mask_array,
                            float frequency, float amplitude, float attenuation=0.10,
                            unsigned char threshold=64):
    """
    HORIZONTAL HEATWAVE 
    
    DISTORTION EQUATION: 
    distortion = sin(x * attenuation + frequency) * amplitude * mask_array[x, y]
    Amplitude is equivalent to ((frequency % 2) / 1000.0) and will define the maximum pixel displacement.
    The highest the frequency the lowest the heat wave  
    
    e.g : 
    surface = heatwave_array24_horiz_c(numpy.asarray(new_array).transpose(1, 0, 2),
            alpha, heat_value, (frequency % 2) / 1000.0, attenuation=0.10)
            
    :param rgb_array: numpy.ndarray or MemoryViewSlice, array shape (w, h, 3) containing RGB values
    :param mask_array: numpy.ndarray or  MemoryViewSlice shape (w, h) containing alpha values
    :param frequency: float; increment value. The highest the frequency the lowest the heat wave  
    :param amplitude: float; variable amplitude. Max amplitude is 10e-3 * 255 = 2.55 
    when alpha is 255 otherwise 10e-3 * alpha.
    :param attenuation: float; default 0.10
    :param threshold: unsigned char; Compare the alpha value with the threshold.
     if alpha value > threshold, apply the displacement to the texture otherwise no change
    :return: Return a pygame.Surface 24 bit format 
    """


    cdef int w, h
    w, h = (<object>rgb_array).shape[:2]

    cdef:
        unsigned char [:, :, ::1] new_array = empty((h, w, 3), dtype=numpy.uint8)
        int x = 0, y = 0, xx, yy
        float distortion


    with nogil:
        for x in prange(0, w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for y in range(h):
                distortion = sin(x * attenuation + frequency) * amplitude * mask_array[x, y]

                xx = <int>(x  + distortion + rand() * <float>0.0002)
                if xx > w - <unsigned short int>1:
                    xx = w - <unsigned short int>1
                if xx < 0:
                    xx = 0

                if mask_array[x, y] > threshold:
                    new_array[y, x, <unsigned short int>0] = rgb_array[xx, y, <unsigned short int>0]
                    new_array[y, x, <unsigned short int>1] = rgb_array[xx, y, <unsigned short int>1]
                    new_array[y, x, <unsigned short int>2] = rgb_array[xx, y, <unsigned short int>2]
                else:
                    new_array[y, x, <unsigned short int>0] = rgb_array[x, y, <unsigned short int>0]
                    new_array[y, x, <unsigned short int>1] = rgb_array[x, y, <unsigned short int>1]
                    new_array[y, x, <unsigned short int>2] = rgb_array[x, y, <unsigned short int>2]

    return pygame.image.frombuffer(new_array, (w, h), 'RGB')


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef heatwave_array32_horiz_c(unsigned char [:, :, :] rgba_array,
                            unsigned char [:, :] mask_array,
                            float frequency, float amplitude, float attenuation=0.10,
                            unsigned char threshold=64):
    """
    HORIZONTAL HEATWAVE 
    
    DISTORTION EQUATION: 
    distortion = sin(x * attenuation + frequency) * amplitude * mask_array[x, y]
    Amplitude is equivalent to ((frequency % 2) / 1000.0) and will define the maximum pixel displacement.
    The highest the frequency the lowest the heat wave  
    
    e.g : 
    surface = heatwave_array32_horiz_c(numpy.asarray(new_array).transpose(1, 0, 2),
            alpha, heat_value, (frequency % 2) / 1000.0, attenuation=0.10)
            
    :param rgba_array: numpy.ndarray or MemoryViewSlice, array shape (w, h, 4) containing RGBA values
    :param mask_array: numpy.ndarray or  MemoryViewSlice shape (w, h) containing alpha values
    :param frequency: float; increment value. The highest the frequency the lowest the heat wave  
    :param amplitude: float; variable amplitude. Max amplitude is 10e-3 * 255 = 2.55 
    when alpha is 255 otherwise 10e-3 * alpha.
    :param attenuation: float; default 0.10
    :param threshold: unsigned char; Compare the alpha value with the threshold.
     if alpha value > threshold, apply the displacement to the texture otherwise no change
    :return: Return a pygame.Surface 32 bit format with per-pixel information
    """


    cdef int w, h
    w, h = (<object>rgba_array).shape[:2]

    cdef:
        unsigned char [:, :, ::1] new_array = empty((h, w, 4), dtype=numpy.uint8)
        int x = 0, y = 0, xx, yy
        float distortion


    with nogil:
        for x in prange(0, w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for y in range(h):
                distortion = sin(x * attenuation + frequency) * amplitude * mask_array[x, y]

                xx = <int>(x  + distortion + rand() * <float>0.00002)
                if xx > w - <unsigned short int>1:
                    xx = w - <unsigned short int>1
                if xx < 0:
                    xx = 0

                if mask_array[x, y] > threshold:
                    new_array[y, x, <unsigned short int>0] = rgba_array[xx, y, <unsigned short int>0]
                    new_array[y, x, <unsigned short int>1] = rgba_array[xx, y, <unsigned short int>1]
                    new_array[y, x, <unsigned short int>2] = rgba_array[xx, y, <unsigned short int>2]
                else:
                    new_array[y, x, <unsigned short int>0] = rgba_array[x, y, <unsigned short int>0]
                    new_array[y, x, <unsigned short int>1] = rgba_array[x, y, <unsigned short int>1]
                    new_array[y, x, <unsigned short int>2] = rgba_array[x, y, <unsigned short int>2]

    return pygame.image.frombuffer(new_array, (w, h), 'RGBA')




@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef heatwave_buffer24_horiz_c(unsigned char [:] rgb_buffer,
                               unsigned char [:, :] mask_buffer,
                               int width, int height,
                               float frequency, float amplitude, float attenuation=0.10,
                               unsigned char threshold=64):
    """
    HORIZONTAL HEATWAVE 
    
    DISTORTION EQUATION: 
    distortion = sin(x * attenuation + frequency) * amplitude * mask_array[x, y]
    Amplitude is equivalent to ((frequency % 2) / 1000.0) and will define the maximum pixel displacement.
    The highest the frequency the lowest the heat wave  
    
    e.g : 
    surface = heatwave_buffer24_horiz_c(numpy.asarray(new_array).transpose(1, 0, 2),
            alpha, heat_value, (frequency % 2) / 1000.0, attenuation=0.10)

    :param rgb_buffer: 1d Buffer representing the RGB portion of the light
    :param mask_buffer: 2d buffer representing the alpha portion of the light effect
    :param width: light's width
    :param height: light's height
    :param frequency: float; incremental variable 
    :param amplitude: float; amplitude is define by the following equation ((frequency % 2) / 1000.0)
    :param attenuation: float; set to 0.10 (default value) 
    :param threshold: unsigned char; set to 64 (default) if alpha below threshold the pixel is unchanged
    :return: return a pygame surface 24-bit 
    """

    cdef int b_length
    b_length = len(<object>rgb_buffer)

    cdef:
        unsigned char [:] new_array = empty(b_length, dtype=numpy.uint8)
        int i=0, index, xx
        float distortion
        xyz v;

    with nogil:
        for i in range(0, b_length, 3): # , schedule=SCHEDULE, num_threads=THREAD_NUMBER):

            # buffer to 3d indexing
            v = to3d_c(index=i, width=width, depth=3) # --> point to the red

            distortion = sin(v.x * attenuation + frequency) * amplitude * mask_buffer[v.x, v.y]

            xx = <int>(v.x  + distortion + rand() * <float>0.00002)

            if xx > width-<unsigned short int>1:
                xx = width-<unsigned short int>1
            if xx < 0:
                xx = 0

            # 3d indexing to 1d buffer
            index = to1d_c(x=xx, y=v.y, z=0, width=width, depth=3)

            if mask_buffer[v.x, v.y] > threshold:
                new_array[i  ] = rgb_buffer[index  ]
                new_array[i+<unsigned short int>1] = rgb_buffer[index+<unsigned short int>1]
                new_array[i+<unsigned short int>2] = rgb_buffer[index+<unsigned short int>2]
            else:
                new_array[i  ] = rgb_buffer[i  ]
                new_array[i+<unsigned short int>1] = rgb_buffer[i+<unsigned short int>1]
                new_array[i+<unsigned short int>2] = rgb_buffer[i+<unsigned short int>2]

    return pygame.image.frombuffer(new_array, (width, height), 'RGB')


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef heatwave_buffer24_vertical_c(unsigned char [:] rgb_buffer,
                                  unsigned char [:, :] mask_buffer,
                                  int width, int height,
                                  float frequency, float amplitude, float attenuation=0.10,
                                  unsigned char threshold=64):
    """
    VERTICAL HEATWAVE 

    DISTORTION EQUATION: 
    distortion = sin(v.x * attenuation + frequency) * amplitude * mask_buffer[v.x, v.y]
    Amplitude is equivalent to ((frequency % 2) / 1000.0) and will define the maximum pixel displacement.
    The highest the frequency the lowest the heat wave  
    
    e.g : 
    surface = heatwave_buffer24_vertical_c(numpy.asarray(new_array).transpose(1, 0, 2),
            alpha, heat_value, (frequency % 2) / 1000.0, attenuation=0.10)

    :param rgb_buffer: 1d Buffer representing the RGB portion of the light
    :param mask_buffer: 2d buffer representing the alpha portion of the light effect
    :param width: light's width
    :param height: light's height
    :param frequency: float; incremental variable 
    :param amplitude: float; amplitude is define by the following equation ((frequency % 2) / 1000.0)
    :param attenuation: float; set to 0.10 (default value) 
    :param threshold: unsigned char; set to 64 (default) if alpha below threshold the pixel is unchanged
    :return:
    """

    cdef int b_length
    b_length = len(<object>rgb_buffer)

    cdef:
        unsigned char [:] new_array = empty(b_length, dtype=numpy.uint8)
        int i=0, index, yy
        float distortion
        xyz v;

    with nogil:
        for i in range(0, b_length, 3): # , schedule=SCHEDULE, num_threads=THREAD_NUMBER):

            # buffer to 3d indexing
            v = to3d_c(index=i, width=width, depth=3) # --> point to the red

            distortion = sin(v.x * attenuation + frequency) * amplitude * mask_buffer[v.x, v.y]

            yy = <int>(v.y  + distortion + rand() * <float>0.00002)

            if yy > height-<unsigned short int>1:
                yy = height-<unsigned short int>1
            if yy < 0:
                yy = 0

            # 3d indexing to 1d buffer
            index = to1d_c(x=v.x, y=yy, z=0, width=width, depth=3)

            if mask_buffer[v.x, v.y] > threshold:
                new_array[i  ] = rgb_buffer[index  ]
                new_array[i+<unsigned short int>1] = rgb_buffer[index+<unsigned short int>1]
                new_array[i+<unsigned short int>2] = rgb_buffer[index+<unsigned short int>2]
            else:
                new_array[i  ] = rgb_buffer[i  ]
                new_array[i+<unsigned short int>1] = rgb_buffer[i+<unsigned short int>1]
                new_array[i+<unsigned short int>2] = rgb_buffer[i+<unsigned short int>2]

    return pygame.image.frombuffer(new_array, (width, height), 'RGB')



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef greyscale_3d_to_2d_c(array):
    """
    Create a greyscale 2d array (w, h)
    
    :param array: numpy.ndarray; 3d array type (w, h, 3) containing RGB values 
    :return: return a 2d numpy.ndarray type (w, h) containing greyscale value 
    
    NOTE:
        if you intend to convert the output greyscale surface to a pygame.Surface using
        pygame.surfarray.make_surface(array), be aware that the resulting will not 
        be a greyscale surface. In order to create a valid greyscale surface from the output 
        array, you need first to convert the 2d array into a 3d array then create a surface. 
    """

    cdef int w_, h_

    try:
        w_, h_ = array.shape[:2]
    except (ValueError, pygame.error) as e:
        raise ValueError('\nArray shape not understood.')

    cdef:
        int w = w_, h = h_
        unsigned char[:, :, :] rgb_array = array
        unsigned char[:, ::1] rgb_out = empty((w, h), dtype=uint8)
        int red, green, blue
        int i=0, j=0
        unsigned char c

    with nogil:
        for i in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for j in range(h):
                red, green, blue = rgb_array[i, j, <unsigned short int>0], \
                                   rgb_array[i, j, <unsigned short int>1], rgb_array[i, j, <unsigned short int>2]
                c = <unsigned char>((red + green + blue) * <float>0.3333)
                rgb_out[i, j] = c
    return asarray(rgb_out)
