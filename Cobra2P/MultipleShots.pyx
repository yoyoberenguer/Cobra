
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
        QUIT, K_SPACE, Rect, BLEND_RGB_ADD
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL
    from pygame.transform import scale, smoothscale, rotate, rotozoom

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

import numpy
from numpy import array, int8, int16
cimport numpy as np
from Weapons import SHOT_CONFIGURATION, WEAPON_OFFSET_X
from Shot import Shot

cdef float SIXTY_FPS = <float>1.0/<float>60.0

ADJUST = numpy.array([0, -4, -4, 10, 10, 25, 25], dtype=int16)

# ALLOW COMBO SHOTS
# SINGLE SHOT, DOUBLE, QUADRUPLE, SEXTUPLET
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void multiple_shots(str unit_, object player_, object gl_):
    """
    DETERMINE HOW MANY BULLETS/LASERS WILL BE SHOT BY THE PLAYER 
    
    :param unit_  : string; represent the number of shots e.g unit_ = 'DOUBLE' means 3 lasers (left, centre, right) 
        {'SINGLE': 1, 'DOUBLE': 3, 'QUADRUPLE': 5, 'SEXTUPLE': 7}
    :param player_: Instance; Player instance 
    :param gl_    : class; Global variables /constants 
    :return       : void 
    """
    cdef:
        bint mute = False

    # offset_x = [0, -17, 17, -30, 30, -45, 45]
    cdef np.ndarray[np.int16_t, ndim=1] offset_x = \
        array(list(WEAPON_OFFSET_X[player_.name].keys()), dtype=int16)
    cdef np.ndarray[np.int16_t, ndim=1] offset_y = \
        array([player_.rect.midtop[1]] * len(offset_x), dtype=int16)

    if unit_ == 'SINGLE':
        if player_.current_weapon.type_ == 'BULLET':
            offset_x = array([-6], dtype=int16)
        else:
            offset_x = array([0], dtype=int16)

    # KEEP THE FIRST 3 ELEMENTS
    if unit_ == 'DOUBLE':
        offset_x = offset_x[:3]

    # load quantity of shots
    cdef int quantity = <object>PyDict_GetItem(SHOT_CONFIGURATION, unit_)
    cdef system_status = player_.aircraft_specs.system_status

    # LEFT WING IS DAMAGED.
    # DISABLE ALL GUNS ON PORT SIDE
    if not system_status['RW'][0]:
        offset_x = offset_x[0::2]
        quantity = len(offset_x)

    # SAME FOR RIGHT WING
    if not system_status['LW'][0]:
        if len(offset_x) < <object>PyDict_GetItem(SHOT_CONFIGURATION, unit_):
            offset_x = array([], dtype=int16)
            quantity = 0
        else:
            offset_x = offset_x[1::2]
            quantity = len(offset_x)

    cdef:
        int index = 0
        tuple groups = (gl_.shots, gl_.All)
        tuple pos = player_.gun_position()
        weapon    = player_.current_weapon


    for index in range(quantity):

        s = Shot(group_         = groups,
                 pos_           = pos,
                 current_weapon_= weapon,
                 player_        = player_,
                 mute_          = mute,
                 offset_        = (offset_x[index], offset_y[index] + ADJUST[index]),
                 timing_        = 0,
                 gl_            = gl_,
                 layer_         = -2)

        # MUTE THE OTHER MULTIPLE SHOTS (ONE SOUND IS ENOUGH)
        mute = True

    if player_.current_weapon.type_ == 'BULLET':
        player_.aircraft_specs.ammo -= quantity
    else:
        player_.aircraft_specs.energy -= quantity * player_.current_weapon.energy
