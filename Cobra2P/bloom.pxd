# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True
# encoding: utf-8

cpdef blur5x5_buffer24(rgb_buffer, width, height, depth, mask=*)
cdef blur5x5_buffer24_c(unsigned char [::1] rgb_buffer, int width, int height, int depth, mask=*)

cpdef blur5x5_buffer32(rgba_buffer, width, height, depth, mask=*)
cdef blur5x5_buffer32_c(unsigned char [:] rgba_buffer, int width, int height, int depth, mask=*)

cpdef blur5x5_array24(rgb_array_, mask=*)
cdef unsigned char [:, :, ::1] blur5x5_array24_c(unsigned char [:, :, :] rgb_array_, mask=*)

cpdef blur5x5_array32(rgb_array_, mask=*)
cdef unsigned char [:, :, ::1] blur5x5_array32_c(unsigned char [:, :, :] rgb_array_, mask=*)


cpdef bpf24_c(image, int threshold=*, bint transpose=*)
cdef bpf24_b_c(image, int threshold=*, bint transpose=*)
cdef unsigned char [:, :, ::1] bpf32_c(image, int threshold=*)
cdef bpf32_b_c(image, int threshold=*)

cpdef bloom_effect_buffer24(object surface_, unsigned char threshold_,
                            int smooth_, mask_=*, bint fast_=*)
cdef bloom_effect_buffer24_c(object surface_, unsigned char threshold_,
                             int smooth_=*, mask_=*, bint fast_=*)

cpdef bloom_effect_buffer32(
        object surface_, unsigned char threshold_, int smooth_, mask_=*, bint fast_=*)
cdef bloom_effect_buffer32_c(object surface_, unsigned char threshold_,
                             int smooth_=*, mask_=*, bint fast_=*)


cpdef bloom_effect_array24(
        object surface_, unsigned char threshold_, int smooth_, mask_=*, bint fast_=*)
cdef bloom_effect_array24_c(object surface_, unsigned char threshold_,
                            int smooth_=*, mask_=*, bint fast_=*)

cpdef bloom_effect_array32(
        object surface_, unsigned char threshold_, int smooth_, mask_=*, bint fast_=*)
cdef bloom_effect_array32_c(object surface_, unsigned char threshold_,
                            int smooth_=*, mask_=*, bint fast_=*)
