# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# PYGAME IS REQUIRED
import numpy as np
cimport numpy as np

try:
    import pygame
    from pygame.surfarray import pixels3d, pixels_alpha, array_alpha
    from pygame.math import Vector2
    from pygame.transform import smoothscale
    from pygame import RLEACCEL, BLEND_RGB_ADD
    # from pygame.sprite import Sprite

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from Sprites cimport Sprite

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

from Textures import COSMIC_DUST1, COSMIC_DUST2


cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;

# VERTEX ARRAY FOR DUST PARTICLES
VERTEX_ARRAY_DUST = []
cdef:
    VERTEX_APPEND = VERTEX_ARRAY_DUST.append
    VERTEX_REMOVE = VERTEX_ARRAY_DUST.remove

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
# FOR 24 BIT TEXTURES
cdef void dust_alpha(image):
    """
    CREATE A BLINKING EFFECT ON 24 BIT SURFACE (WITHOUT PER-PIXEL INFORMATION)

    * Apply alpha inplace

    :param image: Surface; Pygame.Surface 24-bit without per-pixel transparency
    :return: Surface; Return the surface (24-bit) with new alpha layer (previous alpha value - 5)
    """
    cdef int alpha = image.get_alpha()
    cdef unsigned char new_alpha = alpha - <unsigned char>5
    image.set_alpha(new_alpha, RLEACCEL)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void cosmic_dust_display(gl_):
    """
    DISPLAY ALL THE DUST PARTICLES

    * When the dust particle rect is > screenrect_h, the algorithm assign a new random position
      to the particle within (-10, -screenrect_h) outside the display and reset alpha

    :param gl_: class; global variables/constants
    :return: void
    """
    cdef:
        screen_blit         = gl_.screen.blit
        player_vector       = gl_.player.vector
        screenrect          = gl_.screenrect
        int screenrect_h    = screenrect.h
        int screenrect_w    = screenrect.w
        float acceleration  = gl_.ACCELERATION
        float vector_length = player_vector.length()
        bint availability   = gl_.JOYSTICK.availability
        bint compile_logic  = availability and vector_length == 0
        joystick_axis_1     = gl_.player.joystick_axis_1

    for sprite in VERTEX_ARRAY_DUST:

        sprite_image  = sprite.image
        sprite_rect   = sprite.rect
        sprite_vector = sprite.vector

        # DISPLAY THE PARTICLE
        if sprite_rect.colliderect(screenrect):
            PyObject_CallFunctionObjArgs(
                screen_blit,
                <PyObject*> sprite_image,
                <PyObject*> sprite_rect.center,
                <PyObject*> None,
                <PyObject*> sprite._blend,     # BLEND EFFECT None
                NULL)

            # PyObject_CallFunctionObjArgs(
            #     dust_alpha,
            #     <PyObject*> sprite_image,
            #     NULL)

        # RESPAWN THE PARTICLE
        elif sprite_rect.top > screenrect_h:
            sprite_rect.center = randRange(<int>0, screenrect_w),\
                                 randRange(<int>-10, -screenrect_h)
            sprite_image.set_alpha(randRange(<int>0, <int>255))


        if sprite.stars:
            sprite_vector = player_vector * <float>0.3
            if compile_logic:
                sprite_vector = joystick_axis_1 * <float>0.3

        # MOVE THE PARTICLE
        sprite_rect.move_ip(sprite.speed * acceleration + sprite_vector)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void cosmic_dust(gl_):
    """
    CREATE A DUST SPRITE AND PLACE IT IN THE VERTEX ARRAY

    Use randomly two different images for dust sprite (COSMIC_DUST2, COSMIC_DUST1)

    :param gl_: class; Global variable/constants
    :return: void
    """

    dust        = Sprite()
    # NO COPY FOR COSMIC_DUST1 & COSMIC_DUST2 SINCE
    # THE IMAGE IS NOT MODIFIED
    if bool(randRange(<int> 0, <int> 1)):
        dust.image  = COSMIC_DUST2
    else: dust.image = COSMIC_DUST1
    dust.rect   = dust.image.get_rect(midtop=(randRange(<int>0, gl_.screenrect.w),
                                              randRange(<int>-10, -gl_.screenrect.h)))
    dust._layer = <int>0
    dust.stars  = True if bool(randRange(<int>0, <int>1)) else False
    dust.vector = Vector2(<float>0.0, <float>0.0)
    dust.speed  = Vector2(<int>0, randRange(<int>10,<int> 15)) if dust.stars else \
        Vector2(<int>0, randRange(<int>15, <int>25))
    dust._blend = BLEND_RGB_ADD

    VERTEX_APPEND(dust)
