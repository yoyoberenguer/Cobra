#cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
import pygame

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


try:
   from Sprites cimport Sprite
   from Sprites cimport LayeredUpdates
except ImportError:
    raise ImportError("\nSprites.pyd missing!.Build the project first.")


cdef list COUNTDOWN = []

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindDefault(Sprite):
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
                 float timing_         = 16.0,
                 int layer_            = 0,
                 int blend_            = 0,
                 int start_            = 1400
                 ):
        """

        :param containers_:
        :param gl_:
        :param timing_:
        :param layer_:
        :param blend_:
        """
        if len(COUNTDOWN)>1:
            return

        Sprite.__init__(self, containers_)

        self._blend = blend_
        self._layer = layer_

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)
        assert PyObject_IsInstance(images_, list), \
            '\nArgument images must be a python list'

        self.images = images_
        self.length = <int> PyList_Size(images_)
        self.image = <object> PyList_GetItem(images_, 0)
        surface = pygame.Surface((10, 10), pygame.SRCALPHA)
        surface.fill((0, 0, 0, 0))
        surface.convert_alpha()
        self.image = surface
        self.rect  = self.image.get_rect(center=(pos_x, pos_y))
        if not self.rect.colliderect(gl_.screenrect):
            self.kill()
            return
        self.dt = 0
        self.gl = gl_
        self.index = 0
        self.start = start_

        # IF THE FPS IS ABOVE SELF.TIMING THEN
        # SLOW DOWN THE UPDATE
        self.timing = timing_
        COUNTDOWN.append(self)

    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindDefault):
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    cpdef update(self, args=None):

        cdef:
            float dt = self.dt

        if self.gl.FRAME < self.start:
            return

        if dt > self.timing:

            if self.index == len(self.images):
                self.kill()
                global COUNTDOWN
                COUNTDOWN = []
                return

            self.image = <object> PyList_GetItem(self.images, self.index % len(self.images))

            self.index += 1

            dt = 0
        else:
            dt += self.gl.TIME_PASSED_SECONDS

        self.dt = dt

