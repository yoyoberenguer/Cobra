# cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True
# encoding: utf-8
# # distutils: extra_compile_args = -fopenmp
# # distutils: extra_link_args = -fopenmp

cimport numpy as np

cdef area24_c(int x, int y, background_rgb,
              mask_alpha, float intensity=*,
              float [::1] color=*, bint smooth=*, bint saturation=*, float sat_value=*, bint bloom=*,
              unsigned char bloom_threshold=*,
              bint heat=*, float frequency=*)

cdef area32_c(int x, int y, np.ndarray[np.uint8_t, ndim=3] background_rgb,
              np.ndarray[np.uint8_t, ndim=2] mask_alpha, float intensity=*,
              float [:] color=*, smooth=*, saturation=*, sat_value=*, bloom=*, heat=*, frequency=*)

cdef apply32b_c(unsigned char [:] rgb_buffer_, unsigned char [:] alpha_buffer_, float intensity,
               float [:] color, int w, int h)

cdef area24b_c(int x, int y, unsigned char [:, :, :] background_rgb,
               unsigned char [:, :] mask_alpha, float [:] color, float intensity,
               bint smooth, bint saturation, float sat_value, bint bloom, bint heat,
               float frequency, array_)

cdef area24bb_c(int x, int y, unsigned char [:] background_rgb, int w, int h,
                unsigned char [:] mask_alpha, int ax, int ay,
                float [:] color, float intensity,
                bint smooth, bint saturation, float sat_value, bint bloom, bint heat, float frequency)

cdef area32b_c(int x, int y, unsigned char [:, :, :] background_rgb,
                unsigned char [:, :] mask_alpha, float [:] color, float intensity, bint smooth)

cdef light_volume_c(int x, int y, np.ndarray[np.uint8_t, ndim=3] background_rgb,
                    np.ndarray[np.uint8_t, ndim=2] mask_alpha, float intensity, float [:] color,
                    np.ndarray[np.uint8_t, ndim=3] volume)

cdef light_volumetric_c(unsigned char[:, :, :] rgb, unsigned char[:, :] alpha,
                        float intensity, float [:] color, unsigned char[:, :, :] volume)

cdef  unsigned char [:] flatten2d_c(unsigned char [:, :] array2d)
cdef unsigned char [:] flatten3d_rgb_c(unsigned char [:, :, :] rgb_array)
cdef unsigned char [:] flatten3d_rgba_c(unsigned char [:, :, :] rgba_array)
cdef  float [:, :] array2d_normalized_thresh_c(unsigned char [:, :] array_, int threshold=*)
cdef  float [:, :] array2d_normalized_c(unsigned char [:, :] array)
cdef  float [:] buffer_normalized_thresh_c(unsigned char [:] buffer_, int threshold=*)
cdef  float [:] buffer_normalized_c(unsigned char [:] buffer_)
cdef unsigned char[::1] stack_buffer_c(rgb_array_, alpha_, int w, int h, bint transpose=*)
cdef stack_object_c(unsigned char[:, :, :] rgb_array_,
                    unsigned char[:, :] alpha_, bint transpose=*)

cdef heatwave_array24_horiz_c(unsigned char [:, :, :] rgb_array,
                            unsigned char [:, :] mask_array,
                            float frequency, float amplitude, float attenuation=*,
                            unsigned char threshold=*)

cdef heatwave_array32_horiz_c(unsigned char [:, :, :] rgba_array,
                            unsigned char [:, :] mask_array,
                            float frequency, float amplitude, float attenuation=*,
                            unsigned char threshold=*)

cdef heatwave_buffer24_horiz_c(unsigned char [:] rgb_buffer,
                               unsigned char [:, :] mask_buffer,
                               int width, int height,
                               float frequency, float amplitude, float attenuation=*,
                               unsigned char threshold=*)

cdef greyscale_3d_to_2d_c(array)