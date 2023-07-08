# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8
try:
    cimport cython
    from cpython cimport PyObject, PyObject_IsInstance
    from cpython.list cimport PyList_GetItem, PyList_Size

except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, BLEND_RGB_ADD, Rect
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, \
        make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL
    from pygame.transform import scale, smoothscale, rotate

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:
   from Sprites cimport Sprite
   from Sprites cimport LayeredUpdates
except ImportError:
    raise ImportError("\nCannot import library Sprites.")


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
# DISPLAY A SPRITE AT A LOCATION (X, Y)
cdef class Halo(Sprite):

    cdef:
        object images_copy
        public object image, rect, _name
        tuple center
        int index
        public int _blend


    def __init__(self, gl_, containers_, images_, int x, int y, timing_=0.0, int layer_=-3,
                 int blend_=0):
        """
        DISPLAY A SPRITE AT A LOCATION (X, Y)

        * The sprite is automatically re-centre (around x, y values) if the sprite size is changing (Rect size).
        * when the location x, y is outside the screen area, the sprite will be disregarded
        * You can use an optional blend mode for a special effect if needed
        * The update method will be called from the main loop of your program. If your game is running
          at 60fps, the update method will be called every 16.6 ms. This method do not use any delay

        :param gl_        : object; class containing all the constant/variables
        :param containers_: pygame.group(s); group where the sprite will be added
        :param images_    : list; list of surfaces
        :param x          : int; Center position x of the sprite
        :param y          : int; Center position y of the sprite
        :param layer_     : int; layer where the sprite will be display default is -3
        :param blend_     : int; Blend value, Optional special_flags: BLEND_RGBA_ADD, BLEND_RGBA_SUB,
        BLEND_RGBA_MULT, BLEND_RGBA_MIN, BLEND_RGBA_MAX BLEND_RGB_ADD, BLEND_RGB_SUB, BLEND_RGB_MULT,
        BLEND_RGB_MIN, BLEND_RGB_MAX. Default is None
        """

        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.images_copy = images_

        if PyObject_IsInstance(images_, list):
            self.image   = <object>PyList_GetItem(images_,0)
            self.length1 = <int>PyList_Size(self.images_copy) - 1

        else:
            self.image   = images_
            self.length1 = 0

        self.center      = (x, y)
        self.rect        = self.image.get_rect(center=(x, y))

        if not gl_.screenrect.collidepoint(self.center):
            self.kill()
            return

        self._blend      = blend_
        self.index       = 0

        self._name = 'HALO'
        self.gl     = gl_
        self.dt     = 0
        self.timing = timing_

    cpdef update(self, args=None):

        cdef:
            int index = self.index
            int length1   = self.length1

        if self.dt >= self.timing:

            self.image = <object>PyList_GetItem(self.images_copy, index)
            # RE-CENTER THE SPRITE POSITION (SPRITE SURFACE CAN HAVE DIFFERENT SIZES)
            self.rect  = self.image.get_rect(center=(self.center[0], self.center[1]))
            if index < length1:
                index += 1
            else:
                self.kill()

            self.index = index

            self.dt = 0
        else:
            self.dt += self.gl.TIME_PASSED_SECONDS
