# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8




# CYTHON IS REQUIRED

try:
    cimport cython
    from cpython.dict cimport PyDict_DelItem, PyDict_Clear, PyDict_GetItem, PyDict_SetItem, \
        PyDict_Values, PyDict_Keys, PyDict_Items, PyDict_SetItemString
    from cpython cimport PyObject, PyObject_HasAttr, PyObject_IsInstance
    from cpython.list cimport PyList_GetItem
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

import xml.etree.ElementTree as XML_ET

from pygame.math import Vector2
import pygame
from pygame import BLEND_RGB_ADD

# DO NOT REMOVE THE LINE BELOW
from Textures import G5V200_LASER_FX074, G5V200_FX074_ROTATE_BUFFER, \
    G5V200_LASER_FX086, G5V200_FX086_ROTATE_BUFFER, \
    G5V200_ANIMATION, G5V200_SHADOW, G5V200_SHADOW_ROTATION_BUFFER, LIFE_HUD,\
    STINGER_IMAGE, STINGER_ROTATE_BUFFER, MISSILE_TRAIL_DICT2, BUMBLEBEE_IMAGE,\
BUMBLEBEE_ROTATE_BUFFER, MISSILE_TRAIL_DICT3, WASP_IMAGE, WASP_ROTATE_BUFFER, \
MISSILE_TRAIL_DICT2, HORNET_IMAGE, HORNET_ROTATE_BUFFER, MISSILE_TRAIL_DICT1,\
NUKE_BOMB_SPRITE

# DO NOT REMOVE THE LINE BELOW
from Sounds import MISSILE_FLIGHT_SOUND

import numpy


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef list xml_remove_weapon(str filename, str name_, gl_):
    """
    THE XML FILE MUST HAVE A SPECIFIC FORMAT, TAGS AND ATTRIBUTES.
    REFER TO THE XML FILE 'WEAPON.XML' FOR MORE DETAILS
    LOAD AN XML FILE AND REMOVE A SPECIFIC WEAPON CLASS

    :param filename : string; XML file to load
    :param name_    : string; weapon name to remove
    :return         : list;
    """
    tree = XML_ET.parse(filename)
    root = tree.getroot()

    cdef:
        list m_list = []
        m_list_append = m_list.append
        m_list_pop = m_list.pop
        int c=0
        str attribute, value

    for child in root.iter('weapon'):
        m_list_append(child.items())

    for weapon in list(m_list):
        attribute, value = <object>PyList_GetItem(weapon, 0)
        if attribute == 'name' and value == name_:
            m_list_pop(c)
        c += 1

    return m_list


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef xml_get_weapon(str filename, str weapon_name_):
    """
    Return a unique weapon class
    The xml file must have a specific format, tags and attributes.
    Refer to the XML file 'Weapon.xml' for more details

    :param filename      : string; xml file to load
    :param weapon_name_ : list; weapon to extract
    :return: list or None
    """
    tree = XML_ET.parse(filename)
    root = tree.getroot()
    cdef:
        list weapon_list = []
        weapon_list_append = weapon_list.append
        str attribute, value

    for child in root.iter('weapon'):
        weapon_list_append(child.items())

    cdef bint found = False
    for weapon in weapon_list:
        attribute, attribute_value = <object>PyList_GetItem(weapon,0)
        if attribute == 'name' and attribute_value == weapon_name_:
            found = True
            break
    if found:
        return weapon

    return None


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef xml_parsing(xml_features):
    weapon_features = {}
    for key, value in xml_features.items():
        if key in ('name', 'type'):
            continue

        if key == "image":
            try:
                weapon_features[key] = eval(value)
            except NameError:
                raise NameError('\nSprite %s image %s not loaded into memory!' % (key, value))

        elif key == "sprite_rotozoom":
            try:
                weapon_features[key] = eval(value)
            except NameError:
                raise NameError('\nSprite %s image %s not loaded into memory!' % (key, value))

        elif key == 'range':
            weapon_features[key] = eval(value)

        elif key == 'velocity':
            weapon_features[key] = Vector2(float(value), float(value))

        else:
            try:
                weapon_features[key] = int(value)
            except ValueError:
                try:
                    weapon_features[key] = float(value)
                except ValueError:
                    raise ValueError('\nData not understood: %s %s ' % (key, value))
    return weapon_features


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef xml_parsing_G5V200(xml_features):
    aircraft_features = {}
    for key, value in xml_features.items():
        if key in ('name', 'type'):
            continue

        if key == "image":
            try:
                aircraft_features[key] = eval(value)
            except NameError:
                raise NameError('\nSprite %s image %s not loaded into memory!' % (key, value))

        elif key == "sprite_orientation":
            aircraft_features[key] = int(value)

        elif key == 'shadow':
            aircraft_features[key] = eval(value)

        elif key == 'shadow_buffer':
            aircraft_features[key] = eval(value)

        elif key == 'life':
            aircraft_features[key] = int(value)

        elif key == 'max_life':
            aircraft_features[key] = int(value)

        elif key == 'score':
            aircraft_features[key] = int(value)

        elif key == 'strategy':
            aircraft_features[key] = value

        elif key == 'path':
            aircraft_features[key] = eval(value)

        elif key == 'start_frame':
            aircraft_features[key] = int(value)

        elif key == 'damage':
            aircraft_features[key] = int(value)

        else:
            try:
                aircraft_features[key] = int(value)
            except ValueError:
                try:
                    aircraft_features[key] = float(value)
                except ValueError:
                    raise ValueError('\nData not understood: %s %s ' % (key, value))
    return aircraft_features



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef xml_get_background(str filename, str background_name_, object gl_):
    """
    Return a unique background class
    The xml file must have a specific format, tags and attributes.
    Refer to the XML file 'Backgrounds.xml' for more details

    :param filename         : string; xml file to load
    :param background_name_ : list; weapon to extract
    :param gl_              : class; global variables 
    :return: list or None
    """
    tree = XML_ET.parse(filename)
    root = tree.getroot()

    cdef:
        list background_list = []
        background_list_append = background_list.append
        str attribute, value

    for child in root.iter('background'):
        background_list_append(child.items())

    cdef bint found = False

    for background in background_list:
        attribute, attribute_value = <object>PyList_GetItem(background,0)
        if attribute == 'name' and attribute_value == background_name_:
            found = True
            break
    if found:
        return background

    return None


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef xml_parsing_background(xml_features, object gl_, screenrect_):

    """
     <background name             ="ASTEROID3"
                container         ="gl_.All"
                variables         ="gl_"
                v_pos             ="(600, -1950)"
                speed_            ="Vector2(0.0, 1.25)"
                final_            ='(200, screenrect_h)'
                comeback_to_      ='Vector2(200, -screenrect_h)'
                layer_            ='0'
                event_            ='ASTEROID3'
                blend_            ='0'>
        </background>

    :param screenrect_:
    :param xml_features:
    :param gl_:
    :return:
    """
    cdef int screenrect_w = screenrect_.w
    cdef int screenrect_h = screenrect_.h

    cdef float ratio_x, ratio_y
    ratio_x = screenrect_w / <float>800.0
    ratio_y = screenrect_h / <float>1024.0

    cdef dict background_options = {}

    for key, value in xml_features.items():

        if key == "name":
            try:
                background_options[key] = str(value)
            except NameError:
                raise NameError('\n key %s, value %s' % (key, value))

        elif key == "container":
            background_options[key] = eval(value)

        elif key == 'variables':
            background_options[key] = eval(value)

        elif key == 'v_pos':
            background_options[key] = eval(value)

        elif key == 'speed_':
            vec = eval(value)
            background_options[key] = vec

        elif key == 'final_':
            background_options[key] = eval(value)

        elif key == 'comeback_to_':
            vec = eval(value)
            background_options[key] = vec

        elif key == 'layer_':
            background_options[key] = int(value)

        elif key == 'event_':
            background_options[key] = str(value)

        elif key == 'blend_':
            background_options[key] = eval(value)

        elif key == 'loop_':
            background_options[key] = eval(value)

        else:
            try:
                background_options[key] = int(value)
            except ValueError:
                try:
                    background_options[key] = float(value)
                except ValueError:
                    raise ValueError('\nData not understood: %s %s ' % (key, value))
    return background_options



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef xml_parsing_missile(xml_features):
    weapon_features = {}
    for key, value in xml_features.items():

        if key == "image":
            try:
                weapon_features[key] = eval(value)
            except NameError:
                raise NameError('\nSprite %s image %s not loaded into memory!' % (key, value))

        elif key == "sprite_rotozoom":
            try:
                weapon_features[key] = eval(value)
            except NameError:
                raise NameError('\nSprite %s image %s not loaded into memory!' % (key, value))

        elif key == "propulsion_sound_fx":
            try:
                weapon_features[key] = eval(value)
            except NameError:
                raise NameError('Pygame %s sound %s not loaded into memory!' % (key, value))
        elif key == "missile_trail_fx":
            try:
                weapon_features[key] = eval(value).copy()
            except NameError:
                raise NameError('Pygame %s is %s not loaded into memory!' % (key, value))

        elif key == "missile_trail_fx_blend":
            try:
                weapon_features[key] = eval(value)
            except NameError:
                raise NameError('Pygame %s is %s cannot be evaluated!' % (key, value))

        elif key == 'animation':
            try:
                value = int(value)
            except (ValueError, TypeError):
                value = None
            weapon_features[key] = value

        elif key == "bingo_range":
            weapon_features[key] = tuple(eval(value))

        elif key == 'range':
            weapon_features[key] = eval(value)

        elif key in ("name", "type"):
            weapon_features[key] = str(value)

        elif key == 'velocity':
            weapon_features[key] = Vector2(float(value), float(value))

        elif key == 'detonation_dist':
            try:
                det = int(key)
            except ValueError:
                det = None
            weapon_features[key] = det
        else:
            try:
                weapon_features[key] = int(value)
            except ValueError:
                try:
                    weapon_features[key] = float(value)
                except ValueError:
                    raise ValueError('\nData not understood %s %s ' % (key, value))
    return weapon_features
