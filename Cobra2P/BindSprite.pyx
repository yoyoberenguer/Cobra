# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


# CYTHON IS REQUIRED
from Tools cimport make_transparent32

try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject, PyObject_HasAttr, PyObject_IsInstance
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, linspace, ndarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, BLEND_RGB_ADD, Rect
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, \
        make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotate, flip, rotozoom
except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from math import copysign
from Sprites cimport Sprite
from Sprites cimport LayeredUpdates


cdef struct c_tuple:
    int primary;
    int secondary;


cdef float RAD_TO_DEG=<float>(180.0/3.14159265359)
cdef float DEG_TO_RAD=<float>(3.14159265359/180.0)




from libc.math cimport sqrt, atan, cos ,sin

@cython.binding(False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindSprite(Sprite):

    cdef:
        public object image, rect
        public int _blend, _layer
        object images, object_, offset, gl
        float dt, timing
        int index
        bint loop, dependency, follow
        str event

    def __init__(self, group_, images_, object_, gl_, offset_=None,
                 float timing_=16.67, int layer_=0, bint loop_=False,
                 bint dependency_ = False, bint follow_ = False,
                 blend_ = None, event_ =None):

        Sprite.__init__(self, group_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.images_copy = images_.copy()

        if PyObject_IsInstance(images_, list):
            self.image  = <object>PyList_GetItem(images_, 0)
            self.length = <object>PyList_Size(images_) - 2
        else:
            self.image  = images_
            self.length = 0

        self._blend     = blend_
        self._layer     = layer_
        self.object_    = object_
        self.offset     = offset_

        self.off_t      = 0
        cdef:
            tuple center
            obj_rect = object_.rect

        if offset_ is not None:
            center = (obj_rect.centerx + offset_[0],
                      obj_rect.centery + offset_[1])
            if offset_[0] != 0:
                self.off_t = <int> (RAD_TO_DEG * <float> atan(
                    <float> offset_[1] / <float> offset_[0]))
            else:
                self.off_t = 0
        else:
            center = obj_rect.center

        self.rect = self.image.get_rect(
            center=(center[0], center[1]))

        self.dt         = 0
        self.timing     = timing_
        self.index      = 0
        self.loop       = loop_
        self.gl         = gl_
        self.dependency = dependency_
        self.event      = event_
        self.follow     = follow_

        # RECORD LAST VALUE (OBJECT ANGLE)
        # ALGORITHMS SPEED CAN BE IMPROVED
        # WHEN OBJECT ANGLE IS CONSTANT FROM
        # ONE FRAME TO ANOTHER.
        self.previous_rotation = 1

    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindSprite):
            if hasattr(instance_, 'kill'):
                instance_.kill()

    cdef int get_angle(self, int off_x, int off_y):
        """
        RETURN THE ANGLE OF THE OFFSET POINT RELATIVE TO THE PARENT CENTER

        :param off_x: integer; Offset x coordinate 
        :param off_y: integer; Offset y coordinate
        :return: integer; return an integer, angle of the offset relative to the parent center 
        """

        if off_x == 0:
            # ATAN(OFF_Y/ OFF_X WITH OFFS_X = 0) -> INF
            # AVOID DIVISION BY ZERO AND DETERMINE ANGLE -90 OR 90 DEGREES
            return <int> (90 * copysign(1, off_x))
        else:
            return self.off_t

    cdef c_tuple get_offset(self, int angle, float hypo, int object_rotation)nogil:
        """
        RECALCULATE THE OFFSET POSITION (COORDINATES) WHEN PARENT OBJECT IS ROTATING

        :param angle          : integer; correspond to the offset's angle like tan(offset_y/offset_x), 
                                offset is equivalent to a single point of coordinate (offset_x, offset_y) or, 
                                (obj center_x + offset_x, obj center_y + offset_y). 
                                Angle between the center of the object and the offset coordinates.    
        :param hypo           : float; Distance between the object's center and the offset coordinates
        :param object_rotation: integer; Actual sprite angle (orientation) 
        :return               : Return a tuple of coordinates (new offset position) / projection
        """

        cdef:
            float a
            c_tuple ctuple

        a = DEG_TO_RAD * (-180.0 + object_rotation)
        ctuple.primary   = int(cos(a) * hypo)
        ctuple.secondary = int(-sin(a) * hypo)

        return ctuple

    cdef tuple rot_center(self, image_, int angle_, rect_):
        """
        RETURN A ROTATED SURFACE AND ITS CORRESPONDING RECT SHAPE

        :param image_: pygame Surface; 
        :param angle_: integer; angle in degrees 
        :param rect_ : Rect; rectangle shape
        :return      : tuple 
        """
        new_image = rotozoom(image_, angle_, 1.0)
        return new_image, new_image.get_rect(center=rect_.center)

    cdef clocking_device(self, image, clock_value):
        """
        CONTROL IMAGE OPACITY 

        :param image      : Surface; image to modify  
        :param clock_value: Alpha value to use 
        :return           : return a pygame surface 
        """
        return make_transparent32(image, clock_value).convert_alpha()


    cpdef update(self, args=None):

            if self.dependency and not self.object_.alive():
                self.kill()
                self.gl.All.remove(self)

            cdef:
                images_copy = self.images_copy
                image = self.image
                int index = self.index
                object_ = self.object_
                object_rect = object_.rect
                int length = self.length
                rect = self.rect
                int obj_x = object_rect.centerx
                int obj_y = object_rect.centery
                int off_x = self.offset[0] if self.offset is not None else 0
                int off_y = self.offset[1] if self.offset is not None else 0
                bint loop = not self.loop
                float hypo
                c_tuple convert_tuple

            if PyObject_HasAttr(object_, '_rotation'):
                object_rotation = object_._rotation

            if self.dt > self.timing:

                if PyObject_IsInstance(images_copy, list):

                    image = <object> PyList_GetItem(images_copy, index)

                    if PyObject_HasAttr(object_, "clocking_status"):
                        if object_.clocking_status:
                            image = self.clocking_device(image, object_.clocking_index * 2)

                    if self.follow:
                        # TODO change 90 to a variable corresponding to the image orientation
                        image, rect = self.rot_center(
                            image, object_rotation + 90, rect)

                if index > length:
                    if loop:
                        self.kill()
                    index = 0
                else:
                    index += 1

                self.index = index

                # SPRITE HAS OFFSET FROM THE CENTER
                if self.offset is not None:

                    # SPRITE FOLLOW PARENT ROTATE_INPLACE
                    if self.follow and PyObject_HasAttr(object_, '_rotation'):

                        hypo = <float> sqrt(off_x * off_x + off_y * off_y)
                        angle = self.get_angle(off_x, off_y) % 360
                        convert_tuple = self.get_offset(angle, hypo, object_rotation)
                        # ADJUST THE OBJECT CENTER COORDINATES AFTER PARENT OBJECT ROTATION.
                        rect = image.get_rect(
                            center=(obj_x + convert_tuple.primary,
                                    obj_y + convert_tuple.secondary))

                    else:
                        rect = image.get_rect(
                            center=(obj_x + off_x,
                                    obj_y + off_y))
                else:
                    rect = image.get_rect(
                        center=object_rect.center)

                self.rect = rect
                self.image = image
                self.dt = 0

            self.dt += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindShadow(Sprite):
    cdef:
        public int _blend, _layer
        public object image, rect
        object gl,
        float timing, dt
        bint dependency
        tuple offset
        list rotation_buffer

    def __init__(self,
                 containers_,
                 object_,
                 gl_,
                 offset_               = None,
                 list rotation_buffer_ = None,
                 float timing_         = 16.67,
                 int layer_            = 0,
                 bint dependency_      = False,
                 int blend_            = 0,
                 ):
        """
        DROP SHADOW AT A GIVEN OFFSET (BELOW OBJECT)

        :param containers_      : Sprite container
        :param object_          : Parent object (class)
        :param gl_              : Constants / variables class
        :param offset_          : tuple, offset (x, y) from parent rect.center
        :param rotation_buffer_ : Buffer containing rotated shadow surface, 0 to 360 degrees.
        :param timing_          : Timer
        :param layer_           : Layer
        :param dependency_      : Kill the sprite if parent is destroyed
        :param blend_           : Additive mode
        """

        Sprite.__init__(self, containers_)

        self._blend = blend_
        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.offset = offset_

        cdef:
            tuple center
            obj_rect = object_.rect

        if offset_ is not None:
            center = (obj_rect.centerx + offset_[0],
                      obj_rect.centery + offset_[1])
        else:
            center = obj_rect.center

        self.rect = self.image.get_rect(
            center=(center[0], center[1]))

        self.dt = 0
        self.gl = gl_
        self.dependency = dependency_
        self.rotation_buffer = rotation_buffer_


        self.last_rotation = 0

    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindShadow):
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    cdef rot_center(self, int angle_):
        """
        ROTATE THE ENEMY SPACESHIP IMAGE  

        :param angle_: integer; Angle in degrees 
        :return: Return a tuple (surface, rect)
        """
        return <object> PyList_GetItem(self.rotation_buffer, (angle_ + 360) % 360)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    cpdef update(self, args=None):

        cdef:

            image = self.image
            int obj_x = self.object_.rect.centerx
            int obj_y = self.object_.rect.centery
            int off_x = self.offset[0] if self.offset is not None else 0
            int off_y = self.offset[1] if self.offset is not None else 0
            object_ = self.object_
            float dt = self.dt

        if self.dependency and not self.object_.alive():
            self.kill()

        if dt > self.timing:

            # ONLY UPDATE IMAGE IF PARENT IMAGE HAS ROTATED
            if self.rotation_buffer:
                if self.last_rotation != object_._rotation:
                    image = self.rot_center(object_._rotation)
                self.last_rotation = object_._rotation
            dt = 0

        self.rect = image.get_rect(center=(obj_x + off_x, obj_y + off_y))
        self.image = image

        dt += self.gl.TIME_PASSED_SECONDS
        self.dt = dt

@cython.binding(False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindExplosion(Sprite):
    cdef:
        public int _blend, _layer
        public object image, rect
        object gl,
        float timing, dt
        int pos_x, pos_y, index
        list images

    def __init__(self,
                 containers_,
                 list images_,
                 gl_,
                 int pos_x,
                 int pos_y,
                 float timing_         = 16.67,
                 int layer_            = 0,
                 int blend_            = 0,
                 ):
        """

        :param containers_:
        :param gl_:
        :param offset_:
        :param timing_:
        :param layer_:
        :param blend_:
        """

        Sprite.__init__(self, containers_)

        self._blend = blend_
        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)
        assert PyObject_IsInstance(images_, list), \
            '\nArgument images must be a python list'

        self.images = images_
        self.length = <int> PyList_Size(images_) - 1
        self.image = <object> PyList_GetItem(images_, 0)
        self.rect = self.image.get_rect(center=(pos_x, pos_y))
        if not self.rect.colliderect(gl_.SCREENRECT):
            self.kill()
            return
        self.dt = 0
        self.gl = gl_
        self.index = 0


    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindExplosion):
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    @cython.binding(False)
    @cython.binding(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    @cython.profile(False)
    cpdef update(self, args=None):

        cdef:
            float dt = self.dt

        if dt > self.timing:

            self.image = <object> PyList_GetItem(self.images, self.index)
            self.index += 1
            if self.index >= self.length:
                self.kill()

            dt = 0
        dt += self.gl.TIME_PASSED_SECONDS
        self.dt = dt




@cython.binding(False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindJetLight(Sprite):
    cdef:
        public int _blend, _layer
        public object image, rect
        object gl,
        float timing, dt
        int pos_x, pos_y, index
        list images

    def __init__(self,
                 containers_,
                 object image_,
                 gl_,
                 object object_,
                 float timing_         = 16.67,
                 int layer_            = 0,
                 int blend_            = BLEND_RGB_ADD,
                 ):

        Sprite.__init__(self, containers_)
        self._blend = blend_
        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)
        self.image = image_
        self.rect = self.image.get_rect(midbottom=(object_.rect.midbottom[0], object_.rect.midbottom[1]))
        self.obj = object_
        self.dt = 0
        self.gl = gl_
        self.index = 0


    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindJetLight):
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    @cython.binding(False)
    @cython.binding(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    @cython.profile(False)
    cpdef update(self, args=None):

        cdef:
            float dt = self.dt

        self.rect = self.image.get_rect(midbottom=(self.obj.rect.midbottom[0], self.obj.rect.midbottom[1]))

        if dt > self.timing:
            dt = 0

        dt += self.gl.TIME_PASSED_SECONDS
        self.dt = dt