# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# CYTHON IS REQUIRED
from PygameShader.shader import brightness

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
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, \
        array3d, make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotate, rotozoom

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from Sprites cimport Sprite
from Sprites cimport LayeredUpdates

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void nuke_flash(gl_):
    """ CREATE A RED FLASH EFFECT AFTER A NUKE EXPLOSION  """
    b = gl_.nuke / <float>20.0 - <float>0.4
    if b < 0: b = 0
    brightness(gl_.screen, b)
    gl_.screen.convert()
    gl_.nuke -= <float>0.5

GENERIC_ANIMATION_INVENTORY = []
GENERIC_ANIMATION_INVENTORY_APPEND = GENERIC_ANIMATION_INVENTORY.append
GENERIC_ANIMATION_INVENTORY_REMOVE = GENERIC_ANIMATION_INVENTORY.remove

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class GenericAnimation(Sprite):


    def __init__(self, group_, images_, object_, ratio_,float timing_, offset_,
                 str event_name_, bint loop_, gl_, score_, int layer_= -1, int blend_=0):
        """

        :param group_   : pygame sprite Group; Group where the sprite belongs
        :param images_  : pygame surface or list; Animation (list of surfaces)
        :param object_  :
        :param ratio_   :
        :param timing_  : float; Cap the max fps to 60 fps
        :param offset_  :
        :param event_name_: string; Event name
        :param loop_    : bool; True | False to loop indefinitely
        :param gl_      : class/ instance; Global Variable/constants
        :param score_   :
        :param layer_   : integer; Layer used for the sprite default -1
        :param blend_   : integer; Blend mode (default None)
        """

        if id(object_) in GENERIC_ANIMATION_INVENTORY:
            return

        Sprite.__init__(self, group_)

        self.GL = gl_
        gl_all = gl_.All

        if PyObject_IsInstance(gl_all, LayeredUpdates):

            if event_name_ == 'SPACE_ANOMALY':
                gl_all.change_layer(self, -8)
            else:
                gl_all.change_layer(self, layer_)

        self.object      = object_
        self.event_name  = event_name_
        self.timing      = timing_
        self.offset      = offset_
        self._layer      = layer_
        self._blend      = blend_
        self.images_copy = images_.copy()
        self.image       = <object>PyList_GetItem(images_, 0) \
            if PyObject_IsInstance(images_, list) else images_

        if ratio_ is not None:
            if PyObject_IsInstance(ratio_, list):
                self.ratio = ratio_
            else:
                if PyObject_IsInstance(images_, list):
                    self.ratio = [ratio_] * PyList_Size(images_)
        else:
            self.ratio = None

        self.rect = self.image.get_rect()
        # adjust rect
        if self.offset is not None:
            self.rect = self.image.get_rect(center=self.offset.center)
        else:
            if PyObject_HasAttr(self.object, 'rect'):
                self.rect = self.image.get_rect(center=self.object.rect.center)

        self.loop   = loop_
        self.index  = 0
        self.score  = score_
        self.theta  = 0
        self.dt     = 0
        # LOGIC COMPILATION
        self.l1     = self.object in self.GL.GROUP_UNION and PyObject_HasAttr(self.object, 'alive')

        GENERIC_ANIMATION_INVENTORY_APPEND(id(object_))

    cpdef int get_animation_index(self):
        return self.index

    cdef void quit(self):
        if id(self.object) in GENERIC_ANIMATION_INVENTORY:
                GENERIC_ANIMATION_INVENTORY_REMOVE(id(self.object))
        self.kill()

    cpdef void kill_instance(cls, instance_):

        if PyObject_IsInstance(instance_, GenericAnimation):

            if instance_ in cls.gl.All:
                if PyObject_HasAttr(instance_, 'kill'):
                    instance_.kill()

            if id(instance_) in GENERIC_ANIMATION_INVENTORY:
                GENERIC_ANIMATION_INVENTORY_REMOVE(id(instance_))

    cpdef update(self, args=None):

        index      = self.index
        event_name = self.event_name
        obj        = self.object
        obj_rect_x = obj.rect.centerx if PyObject_HasAttr(obj, 'rect') else None
        obj_rect_y = obj.rect.centery if PyObject_HasAttr(obj, 'rect') else None

        if self.dt > self.timing:

            if isinstance(self.images_copy, list):
                self.image = <object>PyList_GetItem(self.images_copy, index)

            if self.ratio is not None:
                if self.ratio[index] != 1:
                    images_copy = <object>PyList_GetItem(self.images_copy, index)
                    ratio       = <object>PyList_GetItem(self.ratio, index)
                    self.image = scale(images_copy, (<int>(images_copy.get_width() * ratio),
                        <int>(images_copy.get_height() * ratio)))

            # PLAYER CLASS ONLY (LEVEL UP)
            if PyObject_IsInstance(obj, type(self.GL.player)):

                if obj.alive():
                    # DISPLAY THE MESSAGE LEVEL UP
                    if event_name == 'LEVEL_UP':
                        self.rect = self.image.get_rect(center=(obj_rect_x, obj_rect_y))
                else:
                    self.quit()


            # CREATE A SUPER EXPLOSION
            elif event_name == 'EXPLOSION':
                self.rect = self.image.get_rect(center=(obj_rect_x, obj_rect_y))


            # NUKE MISSILE
            elif event_name == 'NUCLEAR_EXPLOSION':
                self.rect = self.image.get_rect(center=self.offset.center)
                pass

            # DISPLAY A CIRCLE AROUND AN ENEMY
            elif event_name == 'TARGET':
                if self.l1:
                    # DISPLAY THE CIRCLE ONLY IF THE TARGET EXIST AND PLAYER STILL ALIVE
                    if obj.alive() and self.GL.player.alive():
                        self.rect = self.image.get_rect(center=(obj_rect_x, obj_rect_y))
                    else:
                        self.quit()
                else:
                    self.quit()


            # TESLA effect field
            elif event_name == 'BEAM_FIELD':

                if not (obj.alive() and self.GL.player.alive()):
                    self.quit()

                self.image = smoothscale(self.images_copy[index],
                                         (<int>(obj.image.get_width() * <float>1.5),
                    <int>(obj.image.get_height() * <float>1.5)))
                self.rect = self.image.get_rect(center=(obj_rect_x, obj_rect_y))

            elif event_name == 'MISSILE EXPLOSION':
                self.rect = self.image.get_rect(center=(obj_rect_x, obj_rect_y))

            else:
                # BONUS
                if self.GL.screenrect.colliderect(self.rect):
                    self.rect.move_ip(0, 2)

            self.index = index + 1
            self.dt = 0

            if index >= len(self.images_copy) - <unsigned char>1:
                if self.loop:
                    self.index = 0
                else:
                    if self.event_name == 'LEVEL_UP':
                        self.score.level_up_state = False
                    self.quit()

        self.dt += self.GL.TIME_PASSED_SECONDS

