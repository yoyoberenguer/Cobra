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
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface,\
        blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL
    from pygame.transform import scale, smoothscale, rotate

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:
   from Sprites cimport Sprite, LayeredUpdates, LayeredUpdatesModified
   from Sprites import Group
except ImportError:
    raise ImportError("\nCannot import library Sprites.")


cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;

FOLLOWER_INVENTORY = []


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Follower(Sprite):

    cdef:
        public int _layer, _blend
        public object image, rect, images_copy, images_
        object object_, vector, gl
        int dt, timing, x, y, index
        tuple offset
        bint loop
        public str event

    def __init__(self, gl_, containers_, list images_, tuple offset_, int timing_= 16,
                 bint loop_= False, str event_= None, object_=None, int layer_= -1,
                 vector_=None, int blend_=0):
        """
        PLAY A SPRITE ANIMATION

        * The sprite can be play at the offset location or play at the object centre location when
          object argument is not None
        * A vector can be passed to the method in order to create a dynamic sprite animation following
          a vector velocity
        * Event name can be passed to be identify from somewhere else in the program

        :param gl_        : class; global variables and constants
        :param containers_: Sprite group; Sprite group this sprite belong
        :param images_    : list; surface list
        :param offset_    : tuple; offset x, y
        :param timing_    : integer; default timing is 16ms (60fps)
        :param loop_      : bool; True|False True loop the animation, False kill the animation after playing
        :param event_     : string; Name of the event
        :param object_    : instance; optional object to refer to for its center coordinates
        :param layer_     : integer; Layer to use for this sprite (default -1)
        :param vector_    : Vector; Optional Vector to use for sprite location adjustment (ex explosion following a
        vector velocity.
        :param blend_     : integer; Blending mode default None
        """

        self._layer = layer_

        if object_ is None:
            object_ = gl_.player

        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.dt = 0
        self.timing = timing_

        self.images_copy = images_.copy()
        self.image = <object>PyList_GetItem(images_, 0) if \
            PyObject_IsInstance(images_, list) else self.images_copy

        self.offset = offset_

        if offset_:
            self.x = object_.rect.centerx - self.offset[0]
            self.y = object_.rect.centery - self.offset[1]
            self.rect = self.image.get_rect(center=offset_)
        else:
            self.rect = self.image.get_rect(center=object_.rect.center)

        self.loop   = loop_
        self.index  = 0
        self.event  = event_
        self.object = object_
        self.vector = vector_
        self.gl     = gl_
        self._blend = blend_

        FOLLOWER_INVENTORY.append(self)

    cdef void quit(self):
        """
        
        
        :return: void
        """
        if self in FOLLOWER_INVENTORY:
            FOLLOWER_INVENTORY.remove(self)

        if PyObject_HasAttr(self, 'kill'):
            self.kill()

    @classmethod
    def kill_instance(cls, instance_):
        """
        KILL A GIVEN INSTANCE AND REMOVE IT FROM THE INVENTORY

        :param instance_: object; Instance to kill
        :return: void
        """

        if PyObject_IsInstance(instance_, Follower):
            if instance_ in FOLLOWER_INVENTORY:
                FOLLOWER_INVENTORY.remove(instance_)

            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()


    cpdef update(self, args=None):

        cdef:
            str type_name = type(self.object).__name__
            screenrect    = self.gl.screenrect

        if type_name in ('GroundEnemyTurret', 'GroundEnemyDrone'):
            self.rect.center += Vector2(<float>0.0, <float>1.0)

        if self.dt > self.timing:

            if self.object.alive() and not type_name in ('GroundEnemyTurret', 'GroundEnemyDrone', 'EnemyShot'):

                if self.rect.colliderect(screenrect) or type_name == 'Player':

                    self.image = (<object>PyList_GetItem(self.images_copy, self.index)).copy() if \
                        PyObject_IsInstance(self.images_copy, list) else self.images_copy.copy()

                    if self.offset:
                        self.rect = self.image.get_rect()
                        self.rect.center = (self.object.rect.centerx - self.x,
                                            self.object.rect.centery - self.y)
                    else:
                        self.rect = self.image.get_rect()
                        self.rect.center = self.object.rect.center

                    # Increase the engine sprite light intensity
                    if self.event == 'ENGINE_ON':
                        self.image.blit(
                            self.images_copy[randRange(<int>0,
                            <int>len(self.images_copy) - <unsigned char>1)],
                                        (0, 0), special_flags=BLEND_RGB_ADD)

                    if PyObject_IsInstance(self.images_copy, list):

                        self.index += <unsigned char>1
                        if self.index > len(self.images_copy) - <unsigned char>1:
                            if self.loop:
                                self.index = 0
                            else:
                                self.quit()


                else:
                    self.quit()

            # below has to be part of
            # GroundEnemyTurret, GroundEnemyDrone, EnemyShot
            else:
                # turret?

                if type_name in ('GroundEnemyTurret', 'GroundEnemyDrone', 'EnemyShot'):
                    if screenrect.colliderect(self.rect):

                        if PyObject_IsInstance(self.images_copy, list):

                            self.image = <object>PyList_GetItem(self.images_copy, self.index)
                            if self.index >= len(self.images_copy) - <unsigned char>1:
                                if self.loop:
                                    self.index = 0
                                else:
                                    self.quit()
                        else:
                            self.image = self.images_copy

                        # Effect direction is align with a vector
                        if self.vector:
                            self.rect.center += self.vector * 3

                        self.index += 1
                    else:
                        self.quit()

                else:
                    self.quit()

            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS