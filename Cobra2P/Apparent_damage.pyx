# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# LOAD ALL THE TEXTURES
from Textures import DAMAGE_NONE, DAMAGE_LEFT_WING_RED, DAMAGE_LEFT_WING_YELLOW, \
    DAMAGE_LEFT_WING_ORANGE, \
    DAMAGE_RIGHT_WING_RED, DAMAGE_RIGHT_WING_YELLOW, DAMAGE_RIGHT_WING_ORANGE, DAMAGE_NOSE_RED, \
    DAMAGE_NOSE_YELLOW, DAMAGE_NOSE_ORANGE, DAMAGE_LEFT_ENGINE_RED, DAMAGE_LEFT_ENGINE_YELLOW, \
    DAMAGE_LEFT_ENGINE_ORANGE, DAMAGE_RIGHT_ENGINE_RED, DAMAGE_RIGHT_ENGINE_YELLOW, \
    DAMAGE_RIGHT_ENGINE_ORANGE, \
    DAMAGE_ALL

try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject_CallFunctionObjArgs, PyObject, \
        PyList_SetSlice, PyObject_HasAttr, PyObject_IsInstance, \
        PyObject_CallMethod, PyObject_CallObject
    from cpython.dict cimport PyDict_DelItem, PyDict_Clear, PyDict_GetItem, PyDict_SetItem, \
        PyDict_Values, PyDict_Keys, PyDict_Items
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size, PyList_SetItem
    from cpython.object cimport PyObject_SetAttr

except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

try:
    import pygame
except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")


@cython.binding(False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef apparent_damage(player, life_hud_copy, life):
    """
    status = {'LW': (True, 100),       # Left wing, all super_laser system located on the left 
    wing will stop working
              'RW': (True, 100),       # same on the right
              'LE': (True, 100),       # Left engine, speed altered
              'RE': (True, 100),       # speed altered
              'T': (True, 100),        # Centre Turret, centre turret stop working
              'N': (True, 100),        # Nuke Bombs. no bombs
              'M': (True, 100),        # Missiles. No missiles
              'S': (True, 100),        # Shield. Shield is down
              'AA': (True, 100),       # Auto - Aim. this system is shutdown
              'SUPER': (True, 100),    # Super
              'COMBO': (True, 100)     # Combo shot
              }
    
    :param player: class/instance; Player class 
    :param life_hud_copy: pygame.Surface;
    :param life: pygame.Surface; 
    :return: 
    """
    cdef:
        dict status  = player.aircraft_specs.system_status
        tuple lw     = <object>PyDict_GetItem(status, 'LW')
        tuple rw     = <object>PyDict_GetItem(status, 'RW')
        tuple super_ = <object>PyDict_GetItem(status, 'SUPER')
        tuple le     = <object>PyDict_GetItem(status, 'LE')
        tuple re     = <object>PyDict_GetItem(status, 'RE')
        s_blit       = life_hud_copy.blit
        bint lw_0          = lw[0]
        unsigned char lw_1 = lw[1]
        bint rw_0          = rw[0]
        unsigned char rw_1 = rw[1]
        bint super_0       = super_[0]
        unsigned char super_1 = super_[1]
        bint le_0          = le[0]
        unsigned char le_1 = le[1]
        bint re_0          = re[0]
        unsigned char re_1 = re[1]

    if player.alive():

        # SYSTEM ALL OK
        s_blit(DAMAGE_NONE, (12, 0))

        if lw_0:
            if 50 < lw_1 < 75:
                s_blit(DAMAGE_LEFT_WING_YELLOW, (12, 0))
            elif 0 < lw_1 < 50:
                s_blit(DAMAGE_LEFT_WING_ORANGE, (12, 0))
        else:
            s_blit(DAMAGE_LEFT_WING_RED, (12, 0))

        if rw_0:
            if 50 < rw_1 < 75:
                s_blit(DAMAGE_RIGHT_WING_YELLOW, (12, 0))
            elif 0 < rw_1 < 50:
                s_blit(DAMAGE_RIGHT_WING_ORANGE, (12, 0))
        else:
            s_blit(DAMAGE_RIGHT_WING_RED, (12, 0))

        if super_0:
            if 50 < super_1 < 75:
                s_blit(DAMAGE_NOSE_YELLOW, (12, 0))
            elif 0 < super_1 < 50:
                s_blit(DAMAGE_NOSE_ORANGE, (12, 0))
        else:
            s_blit(DAMAGE_NOSE_RED, (12, 0))

        if le_0:
            if 50 < le_1 < 75:
                s_blit(DAMAGE_LEFT_ENGINE_YELLOW, (12, 0))
            elif 0 < le_1 < 50:
                s_blit(DAMAGE_LEFT_ENGINE_ORANGE, (12, 0))
        else:
            s_blit(DAMAGE_LEFT_ENGINE_RED, (12, 0))

        if re_0:
            if 50 < re_1 < 75:
                s_blit(DAMAGE_RIGHT_ENGINE_YELLOW, (12, 0))
            elif 0 < re_1 < 50:
                s_blit(DAMAGE_RIGHT_ENGINE_ORANGE, (12, 0))
        else:
            s_blit(DAMAGE_RIGHT_ENGINE_RED, (12, 0))

    else:
        s_blit(DAMAGE_ALL, (12, 0))

    if life:
        s_blit(life, (83, 20))


    return life_hud_copy


