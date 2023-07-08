# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True
# encoding: utf-8


try:
    import pygame
    from pygame.surfarray import pixels3d, pixels_alpha
    from pygame import Surface
    from pygame.image import frombuffer

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

cpdef hsv_surface24(surface_, float shift_)
cpdef void hsv_surface24_inplace(surface_, float shift_)
cdef hsv_surface24c(surface_, float shift_)
cpdef void hsv_surface24c_inplace(surface_, float shift_)

cpdef hsv_surface32(surface_: Surface, float shift_)
cdef hsv_surface32c(surface_: Surface, float shift_)
cpdef void hsv_surface32c_inplace(surface_: Surface, float shift_)

