# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


# CYTHON IS REQUIRED
try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject_CallFunctionObjArgs, PyObject, \
        PyList_SetSlice, PyObject_HasAttr, PyObject_IsInstance, \
        PyObject_CallMethod, PyObject_CallObject
    from cpython.dict cimport PyDict_DelItem, PyDict_Clear, PyDict_GetItem, PyDict_SetItem, \
        PyDict_Values, PyDict_Keys, PyDict_Items
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size
    from cpython.object cimport PyObject_SetAttr

except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
                      "\nTry: \n   C:\\pip install cython on a window command prompt.")

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, BLEND_RGB_ADD, Rect
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface, \
        blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import freetype
    from pygame.freetype import STYLE_STRONG, STYLE_NORMAL, Font
    from pygame.transform import scale, smoothscale, rotate, scale2x
    from pygame.font import Font, SysFont

except ImportError:
    print("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")
    raise SystemExit

from Sprites cimport Sprite
from libc.math cimport round as round_c

cdef list INVENTORY = []
INVENTORY_REMOVE = INVENTORY.remove
freetype.init(cache_size=64, resolution=72)
pygame.font.init()
FONT = Font("Assets/Fonts/ARCADE_R.TTF", 18)
FONT1 = SysFont("arial", 10, 'normal')
FONT2 = SysFont("calibri", 11, 'bold')

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class DamageDisplay(Sprite):

    cdef:
        int damages
        tuple color
        public rect, image, _blend

    def __init__(self, group_, object_, int damages_, event_= None):

        if id(object_) in INVENTORY:
            return

        Sprite.__init__(self, group_)

        if damages_ <= 100:
            color =  (255, 255, 255)
        elif 100 < damages_ < 200:
            color = (255, 255, 0)
        else:
            color = (255, 0, 0)

        self.image = Surface((10, 10))
        self.object = object_

        self.event = event_

        self.rect = self.image.get_rect(center=(-100, -100))
        self.index = 0

        image = self.image
        if event_ == 'EXP':
            image = FONT1.render(<str>'+' + str(damages_ / <float>10.0), True, (255, 255, 255))
            image = scale2x(image)

        else:
            if image.get_bitsize() != 8:
                image = FONT2.render(str(damages_), True, color)
            else:
                image = FONT2.render(str(damages_), False, color)
        self.image = image

        INVENTORY.append(id(object_))

    cpdef int get_animation_index(self):
        return self.index

    cdef void quit(self):
        if id(self.object) in INVENTORY:
            INVENTORY_REMOVE(id(self.object))
        self.kill()

    cpdef update(self, args=None):

        cdef:
            object_position = self.object.location() if \
            PyObject_HasAttr(self.object, "location") else None
            int index = self.index
            int ind
            rect_center = self.rect.center

        if self.event == 'EXP':
            self.rect.center = (object_position.midtop[0] +
                                <unsigned char>10, object_position.midtop[1])
            if index > 8:
                self.quit()
        else:
            if self.object is not None:
                rect_center = object_position.midright
                if index > 8:
                    self.quit()
            else:

                self.image = FONT.render(str(self.event), True, (255, 255, 0))
                self.image =smoothscale(self.image,
                                        (int(round_c(self.image.get_width() + self.index *
                                                     <unsigned char>4)),
                    int(round_c(self.image.get_height() + self.index * <unsigned char>4))))
                rect_center = (10, 150)
                if index > 24:
                    self.quit()

        self.index += 1
        self.rect.center = rect_center




