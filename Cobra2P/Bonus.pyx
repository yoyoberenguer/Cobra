# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8
from Gems import Gems
from Sounds import CRYSTAL_SOUND
from Textures import ENERGY_BOOSTER1, NUKE_BONUS, COLLECTIBLES_AMMO, BonusLifeLeviathan,\
    BonusLifeNemesis

try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, linspace
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")


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

# CYTHON IS REQUIRED
try:
    cimport cython
    from cython.parallel cimport prange
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

from pygame.locals import K_PAUSE
# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy,\
        gfxdraw, BLEND_RGB_ADD, BLEND_RGB_SUB, freetype, \
    SWSURFACE, RESIZABLE, FULLSCREEN, HWSURFACE
    from pygame.freetype import STYLE_NORMAL
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d
    from pygame.image import frombuffer
    from pygame import Rect
    from pygame.time import get_ticks
    from operator import truth
    from pygame.draw import aaline
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotozoom

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")


from Sprites cimport Sprite, LayeredUpdates
from Sprites import Group


cdef extern from 'Include/randnumber.c':
    void init_clock()nogil;
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;

from libc.math cimport round

BONUS_INVENTORY = []

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Bonus(Sprite):

    cdef:
        object object_, gl, offset, images_copy, speed, ratio
        public object image, rect
        public int _layer, _blend
        public str event_name_, bonus_type
        int timing, index, energy, dt
        bint loop
        public long long int object_id

    def __init__(self, gl_, images_, object_, ratio_, int timing_= 16, offset_= None,
                 str event_name_=None, bint loop_=True, str bonus_type_=None, int layer_=-1):
        """

        :param gl_        : class; global variables/constants
        :param images_    : Surface list; Pygame surface list
        :param object_    : instance; Object generating the collectable (used for the rect position)
        :param ratio_     :
        :param timing_    : integer; CAP at 60 fps 16.67ms
        :param offset_    : Rect; Rect defining the position of the collectable
        :param event_name_: string; Name of the collectable
        :param loop_      : bool; True | False to loop the animation
        :param bonus_type_: string; Duplicate of event_name, determine the collectable type
        :param layer_     : integer; Layer used for this sprite

        """

        if object_ in BONUS_INVENTORY:
            return

        Sprite.__init__(self, (gl_.bonus, gl_.All))

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.images_copy = images_.copy()
        self.image       = <object>PyList_GetItem(self.images_copy, 0)

        if PyObject_IsInstance(ratio_, list):
            self.ratio = ratio_
        else:
            self.ratio = [ratio_] * len(self.images_copy)

        if offset_ is not None:
            # DISPLAY THE SPRITE AT A SPECIFIC LOCATION.
            self.rect = self.image.get_rect(center=offset_.center)
        else:
            # USE PLAYER LOCATION
            self.rect = self.image.get_rect(center=object_.rect.center)

        self.object_     = object_
        self.offset      = offset_
        self.gl          = gl_
        self.event_name_ = event_name_
        self.timing      = timing_
        self.speed       = Vector2(0, 4)
        self.loop        = loop_
        self.index       = 0
        self.energy      = randRange(5000, 10000)
        self.bonus_type  = bonus_type_
        self.object_id   = id(object_)
        self.dt          = 0
        self._blend      = 0

        BONUS_INVENTORY.append(object_)

    cdef void kill_sound(self):
        self.gl.SC_spaceship.stop_object(self.object_id)

    cdef void quit(self):
        try:
            if self.object_ in BONUS_INVENTORY:
               BONUS_INVENTORY.remove(self.object_)
        except:
            pass

        finally:
            self.kill_sound()
            self.kill()

    cpdef int get_energy(self):
        return self.energy

    cpdef update(self, args=None):

        cdef int index = self.index
        cdef int r     = <object>PyList_GetItem(self.ratio, index)

        if self.dt > self.timing:

            if self.gl.screenrect.contains(self.rect) and self.alive():

                self.image = <object>PyList_GetItem(self.images_copy, index)

                # IF RATION WAS NOT NULL DURING INSTANTIATION, TRANSFORM/SCALE THE OBJECT
                # WITH THE SPECIFIC RATION
                if r != 0:
                    self.image = \
                        scale(self.image, (<int>round(self.image.get_width()  * r),
                                           <int>round(self.image.get_height() * r)))

                if self.offset is None:
                    self.rect.move_ip(self.speed.x, self.speed.y)

                index += 1
                if index > len(self.images_copy) - 1:
                    if self.loop:
                        index = 0
                    else:
                        self.quit()
            else:
                self.quit()

            self.dt = 0
            self.index = index
        self.dt += self.gl.TIME_PASSED_SECONDS


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef bint bonus_energy(gl_, object_):
    """
    CREATE A COLLECTABLE ENERGY CELL
    
    * 92% chance to create a collectable
    
    :param gl_    : class; global variables / constants
    :param object_: instance; object instance used for the rect position 
    :return       : True|False Return True when a collectable is available   
    """

    cdef int count = 0
    for spr in gl_.bonus:

        if spr.bonus_type == 'ENERGY':
            count += 1
        # NO MORE THAN ONE ENERGY CELL ON THE SCREEN
        if count > 1:
            return False

    if count < 1:
        if randRange(0, 100) > 92:
            Bonus(gl_, images_=ENERGY_BOOSTER1, object_=object_, ratio_=0, timing_=15,
                  offset_=None, event_name_='ENERGY BONUS', loop_=True, bonus_type_='ENERGY')


            gl_.SC_spaceship.play(sound_=CRYSTAL_SOUND, loop_=True, priority_=0,
                                 volume_=gl_.SOUND_LEVEL, fade_out_ms=0, panning_=True,
                                 name_='CRYSTAL', x_=object_.rect.centerx, object_id_=id(object_))
            return True

    return False


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef bint bonus_bomb(gl_, object_):
    """
    CREATE A BOMB COLLECTABLE
    
    * 98% to create a collectable

    :param gl_    : class; global variables / constants
    :param object_: instance; object instance used for the rect position 
    :return       : True|False Return True when a collectable is available   
    """
    cdef int count = 0

    if 0 <= gl_.player.aircraft_specs.nukes_quantity < 3:

        for spr in gl_.bonus:

            if spr.bonus_type == 'BOMB':
                count += 1

            if count > 1:
                return False

        if count < 1:
            if randRange(0, 100) > 98:
                Bonus(gl_=gl_, images_=NUKE_BONUS, object_=object_, ratio_=0, timing_=15,
                      offset_=None, event_name_='BOMB BONUS', loop_=True, bonus_type_='BOMB')
                return True

    return False

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef bint bonus_ammo(gl_, object_):
    """
    CREATE AMMO COLLECTABLE 
    
    * 98% chance to create a collectable
    
    :param gl_    : class; global variables / constants
    :param object_: instance; object instance used for the rect position 
    :return       : True|False Return True when a collectable is available   
    """

    cdef int count = 0

    for spr in gl_.bonus:

        if spr.bonus_type == 'AMMO':
            count += 1

        if count > 1:
            return False

    if count < 1:
        if randRange(0, 100) > 98:
            instance_ = Bonus(gl_, images_=COLLECTIBLES_AMMO,
                              object_=object_, ratio_=0, timing_=15,
                              offset_=None, event_name_='AMMO BONUS',
                              loop_=True, bonus_type_='AMMO')

            if instance_ is not None:
                return True
    return False

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void bonus_gems(gl_, object_, player_, int min_, int max_, int chance_):
    """
    CREATE GEM COLLECTABLES
    
    * Create gems if gem quantity < 100
    * 50% chance to create gems
    * Random quantity between min_ - max_
    
    :param chance_: chance to create gems (100 always create gems)
    :param max_   : int; Maximum gems 
    :param min_   : int; Minimum gems 
    :param gl_    : class; global variables / constants
    :param object_: instance; object instance used for the rect position   
    :param player_: classs/instance; Player instance
    :return       : True|False Return True when a collectable is available   
    """

    # 50% chance to create a gem
    if randRange(0, 100) < chance_:

        for r in range(randRange(min_, max_)):

            Gems(gl_=gl_, player_=player_, object_=object_, timing_=15, offset_=Rect(object_.rect.centerx,
                 object_.rect.centery, randRange(-100, 100), randRange(-100, 20)))


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef int bonus_life(gl_, object_):
    """
    CREATE EXTRA LIFE COLLECTABLE

    :param gl_    : class; global variables / constants
    :param object_: instance; object instance used for the rect position 
    :return       : True|False Return True when a collectable is available   
    """

    cdef int count = 0
    for spr in gl_.bonus:

        if spr.bonus_type == 'LIFE':
            count += 1

        if count > 1:
            return False

    if randRange(0, 1000) > 998:
        Bonus(gl_=gl_, images_= BonusLifeLeviathan if
        gl_.player.name == 'LEVIATHAN' else BonusLifeNemesis,
              object_=object_, ratio_=0, timing_=15, offset_=None, event_name_='LIFE BONUS',
              loop_=True, bonus_type_='LIFE')
        return True
