# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

import numpy
from pygame.surfarray import pixels_alpha

from Sounds import BROKEN_GLASS, SCREEN_IMPACT_SOUND
from Sprites cimport Sprite
from Sprites cimport LayeredUpdates
from Textures import BROKENGLASS_IMAGES
from Tools cimport make_transparent32, make_transparent32_inplace

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

cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BrokenGlass(Sprite):

    cdef:
        int glass, length, dt, timing, index
        public object image, rect
        object images_copy, gl
        public int _blend, _layer

    def __init__(self, gl_, tuple location_, int timing_=60, int layer_=0):
        """
        DISPLAY BROKEN GLASS ON THE DISPLAY

        :param gl_      : class; global variables/constants
        :param location_: tuple; position (x, y)
        :param timing_  : integer; CAP fps to 60 (16ms) by default
        :param layer_   : integer; default 0 (top level)
        """

        Sprite.__init__(self, gl_.All)

        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.glass      = randRange(0, 1)
        self.image_copy = BROKENGLASS_IMAGES[self.glass]
        self.image      = self.image_copy[0]
        self.length     = PyList_Size(self.image_copy) - 1
        self.rect       = self.image.get_rect(center=location_)
        self.dt         = 0
        self.timing     = timing_
        self.index      = 0
        self.gl         = gl_
        self._blend     = 0

        mixer = gl_.SC_spaceship
        if not mixer.get_identical_sounds(BROKEN_GLASS):
            mixer.play(sound_=BROKEN_GLASS, loop_=False, priority_=0,
                       volume_=gl_.SOUND_LEVEL, fade_out_ms=0, panning_=True,
                       name_='BROKEN_GLASS', x_=self.rect.centerx,
                       object_id_=id(BROKEN_GLASS))


    @classmethod
    def kill_instance(cls, instance_):
        if PyObject_IsInstance(instance_, BrokenGlass):

            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    cdef void quit(self):
        """
        STOP THE BROKEN GLASS SOUND AND REMOVE THE INSTANCE FROM THE INVENTORY
        
        * kill the sprite
         
        :return: void  
        """
        mixer = self.gl.SC_spaceship

        if mixer.get_identical_sounds(BROKEN_GLASS):
            mixer.stop_object(id(BROKEN_GLASS))

        self.kill()

    cpdef update(self, args=None):

        if self.dt > self.timing:

            self.image = <object>PyList_GetItem(self.image_copy, self.index % self.length)

            if self.index > self.length:
                self.quit()

            self.dt = 0
            self.index += 1

        self.dt += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BrokenScreen(Sprite):

    cdef:
        public object image, rect
        public int _blend, _layer
        bint force_kill
        int dt, timing
        object gl


    def __init__(self, image_, gl_, int timing_=16, int layer_=0):
        """
        DISPLAY BULLET IMPACT ON THE DISPLAY

        :param image_  : Surface; Surface to display
        :param gl_     : class; constants/variables
        :param timing_ : integer; default 16ms (60 fps)
        :param layer_  : integer; default level 0 (top level)
        """

        Sprite.__init__(self, gl_.All)

        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        cdef int x, y
        x, y = randRange(0, gl_.screenrect.w), randRange(0, gl_.screenrect.h)
        self.image  = image_.copy()
        self.rect   = self.image.get_rect(center=(x, y))
        self.force_kill = False
        self.dt     = 0
        self.gl     = gl_
        self.timing = timing_
        self._blend = 0

        mixer = gl_.SC_spaceship
        if not mixer.get_identical_sounds(SCREEN_IMPACT_SOUND):
            mixer.play(sound_=SCREEN_IMPACT_SOUND, loop_=False, priority_=0,
                       volume_=gl_.SOUND_LEVEL, fade_out_ms=0, panning_=True,
                       name_='SCREEN_IMPACT_SOUND', x_=self.rect.centerx,
                       object_id_=id(SCREEN_IMPACT_SOUND))

        BrokenGlass(gl_, (x, y))

    @classmethod
    def kill_instance(cls, instance_):

        if PyObject_IsInstance(instance_, BrokenScreen):

            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    cdef void quit(self):
        """
        KILL THE SPRITE AND REMOVE IT FROM THE INVENTORY 
        
        :return: void
        """
        mixer = self.gl.SC_spaceship

        if mixer.get_identical_sounds(SCREEN_IMPACT_SOUND):
            mixer.stop_object(id(SCREEN_IMPACT_SOUND))

        self.kill()

    cpdef update(self, args=None):


        if self.force_kill:
            self.quit()
            return

        if self.dt > self.timing:

            # self.image = make_transparent32(self.image, 4)
            make_transparent32_inplace(self.image, 4)

            alpha = pixels_alpha(self.image)

            if numpy.average(alpha) < 1:
                self.force_kill = True

            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS
