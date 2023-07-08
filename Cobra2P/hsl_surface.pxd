# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True
# encoding: utf-8
import warnings

cdef hsl_surface24c(surface_, float shift_)
cdef void hsl_surface24c_inplace(surface_, float shift_)
cdef hsl_surface32c(surface_, float shift_)
cdef void hsl_surface32c_inplace(surface_, float shift_)
