# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, full_like, add, putmask
except ImportError:
    print("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")
    raise SystemExit


cdef float damped_oscillation(float t)nogil
cdef blend_texture_32c(surface_, final_color_, float percentage)
cdef blend_texture_24c(surface_, final_color_, float percentage)
cdef make_transparent32(image_, int alpha_)
cdef void make_transparent32_inplace(image_, int alpha_)
cpdef reshape(sprite_, factor_=*)
cdef mask_shadow(surface_, mask_)
cdef wave_xy_c(texture, float rad, int size)
cdef blend_to_textures_24c(source_, destination_, float percentage_)
cdef blend_to_textures_32c(source_, destination_, float percentage_)
cdef unsigned char[:, :] alpha_mask(image_, int threshold_alpha_=*)
cdef unsigned char[:, :] mask_alpha32_inplace(
        image_, unsigned char[:, :] mask_alpha, unsigned char value_)


