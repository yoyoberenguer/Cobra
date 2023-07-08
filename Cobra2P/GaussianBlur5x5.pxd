# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


try:
    cimport cython
    from cython.parallel cimport prange

except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")



cdef blur5x5_array24_inplace_c(unsigned char [:, :, :] rgb_array_, mask=*)
cdef blur5x5_surface24_inplace_c(surface_, mask=*)
cdef canny_blur5x5_surface24_c(surface_)
cdef canny_blur5x5_surface32_c(surface_)
