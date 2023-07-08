# cython: boundscheck=False, wraparound=False, nonecheck=False, optimize.use_switch=True, optimize.unpack_method_calls=True, cdivision=True
# encoding: utf-8

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE
    from pygame.surfarray import pixels3d, array_alpha, \
        pixels_alpha, array3d, make_surface, blit_array
    from pygame.image import frombuffer

except ImportError:
    print("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")
    raise SystemExit


cdef sprite_sheet_per_pixel(str file_, int chunk_, int rows_, int columns_)
cpdef sprite_sheet(str file_, int chunk_, int rows_, int columns_)

cpdef Sprite_Sheet_Uniform_RGB(
        str file_, int size_, int rows_, int columns_)
cdef unsigned char [:, :, ::1] pixel_block_rgb(
        unsigned char [:, :, :] array_, int start_x, int start_y,
        int w, int h, unsigned char [:, :, ::1] block) nogil
cpdef surface_split(surface_, int size_, int rows_, int columns_)

cpdef Sprite_Sheet_Uniform_RGBA(
        str file_, int size_, int rows_, int columns_)
cdef unsigned char [:, :, ::1] pixel_block_rgba(
        unsigned char [:, :, :] array_, int start_x, int start_y,
        int w, int h, unsigned char [:, :, ::1] block) nogil

cdef sprite_sheet_fs8(str file_, int chunk_, int columns_,
                       int rows_, tweak_=*, args=*, color_=*)
cdef sprite_sheet_fs8_alpha(str file_, int chunk_, int columns_,
                       int rows_, tweak_=*, args=*)
