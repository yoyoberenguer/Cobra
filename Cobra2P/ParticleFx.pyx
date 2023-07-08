# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


from pygame.math import Vector2
from pygame.transform import scale
from pygame import BLEND_RGB_ADD

from Constants import COS, SIN

from libc.math cimport round

from Sprites cimport Sprite

cdef extern from 'Include/randnumber.c':
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;

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


VERTEX_PARTICLEFX = []
VERTEX_PARTICLEFX_APPEND = VERTEX_PARTICLEFX.append
VERTEX_PARTICLEFX_REMOVE = VERTEX_PARTICLEFX.remove

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Point:

    cdef:
        public float lifetime, spawn
        public object vector
        public bint set_
        public int start

    def __init__(self, int frame, list lifetime, list spawn):
        """
        CLASS POINT REGROUP IMPORTANT DATA FOR PARTICLEFX CLASS

        :param lifetime: List, Lifetime of a particle, time to live etc (in ms)
        :param spawn:    List, Time when the particle start to be display (delay in ms)
        """
        # Remove for gaining few ms
        # assert isinstance(lifetime, list) and isinstance(spawn, list), \
        #    '\n[-] Error: Expecting List only, got: lifetime:%s, spawn:%s ' % (type(lifetime), type(spawn))

        self.lifetime = randRangeFloat(<object>PyList_GetItem(lifetime, 0),
                                       <object>PyList_GetItem(lifetime, 1))
        self.spawn    = randRangeFloat(<object>PyList_GetItem(spawn, 0),
                                       <object>PyList_GetItem(spawn, 1))
        self.vector   = Vector2()
        self.set_     = False
        self.start    = frame

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef scale_particle(spr_, image_, float factor_):

    cdef tuple rescale = (image_.get_width()  - factor_,
                         (image_.get_height() - factor_))
    try:
        im = scale(image_, rescale)
        return im
    except:
        spr_.kill()
        return image_

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef void remove_particle(spr_):
    if spr_ in VERTEX_PARTICLEFX:
        VERTEX_PARTICLEFX_REMOVE(spr_)
    spr_.kill()


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef display_particlefx(gl_):

    cdef:
        screen          = gl_.screen
        screen_blit     = screen.blit
        screen_collide  = gl_.screenrect.colliderect
        int frame       = gl_.FRAME
        int start, spawn, index
        tuple r
        float speed_y


    for particles_ in VERTEX_PARTICLEFX:

        pp      = particles_.particle
        start   = pp.start
        spawn   = pp.spawn
        index   = particles_.index
        speed_y = particles_.speed.y
        p_rect  = particles_.rect


        if particles_.initialised:

            if (frame - start) < spawn:
                return
            else:
                particles_.initialised = False
                if not pp.set_:
                        pp.vector = Vector2(
                            randRange(-<int>10, <int>10) + particles_.rectangle.midbottom[0],
                            particles_.rectangle.midbottom[1])
                        p_rect.centerx = pp.vector.x
                        p_rect.centery = pp.vector.y
                        pp.set_ = True

        if (frame - start) - spawn > pp.lifetime:
            remove_particle(particles_)
        else:
            particles_.image              = <object>PyList_GetItem(particles_.images_copy, index)
            particles_.images_copy[index] = scale_particle(particles_,
                                                           particles_.image, round(index * particles_.reduce_factor))
            pp.vector                    += (eval(particles_.compiled) * <float>4.0, speed_y)
            p_rect.center                 = (pp.vector.x + round(index * particles_.reduce_factor), pp.vector.y)
            particles_.angle             += <int>(<unsigned char>2 * speed_y)

            if index < PyList_Size(particles_.images_copy) - <unsigned char>1:
                particles_.index = index + <unsigned char>1
            else:
                remove_particle(particles_)


            if not screen_collide(p_rect):
                remove_particle(particles_)
            else:

                r = (p_rect.centerx - (p_rect.w >> 1),
                     p_rect.centery - (p_rect.h >> 1))

                PyObject_CallFunctionObjArgs(
                    screen_blit,
                    <PyObject*> particles_.image,
                    <PyObject*> r,
                    <PyObject*> None,
                    <PyObject*> BLEND_RGB_ADD,
                    NULL)



# TODO RENAME CPDEF ParticleFx (THIS IS THE SAME NAME THAT THE LIBRARY)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef ParticleFx(gl_, image_, rect_, int layer_):
    spr              = Sprite()
    spr._layer       = layer_
    spr.images_copy  = image_.copy()
    spr.image        = <object>PyList_GetItem(spr.images_copy, 0) \
        if PyObject_IsInstance(image_, list) else spr.images_copy
    spr.rect         = spr.image.get_rect(midbottom = (-100, 100))
    spr.rectangle    = rect_
    spr.particle     = Point(gl_.FRAME, lifetime=[<float>6.25, 50], spawn=[4, 9.4])
    spr.speed        = Vector2(0, randRangeFloat(<float>5.0, <float>15.0))
    spr.equation     = ['COS[particles_.angle % 360] * 2.0', '-1', '1', 'SIN[particles_.angle % 360]'][randRange(0, 3)]
    spr.compiled     = compile(spr.equation,'','eval')
    spr.index        = 0
    spr.initialised  = True
    spr.reduce_factor = <float>0.9
    spr.angle        = 0
    VERTEX_PARTICLEFX_APPEND(spr)

