# cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from Sprites cimport Sprite


cdef extern from 'Include/vector.c':
    struct vector2d:
        float x
        float y

    struct rect_p:
        int x
        int y

    struct mla_pack:
        vector2d vector
        vector2d collision

    void vecinit(vector2d *v, float x, float y)nogil;
    float vlength(vector2d *v)nogil;
    void scale_inplace(float c, vector2d *v)nogil;
    vector2d addcomponents(vector2d v1, vector2d v2)nogil;
    vector2d subcomponents(vector2d v1, vector2d v2)nogil;
    vector2d scalevector2d(float c, vector2d *v)nogil;
    float distance_to(vector2d v1, vector2d v2)nogil;
    float dot(vector2d *v1, vector2d *v2)nogil;
    int randRange(int lower, int upper)nogil;
    float randRangeFloat(float lower, float upper)nogil;


cdef class ExtraAttributes(object):
    cdef dict __dict__


cdef int get_angle(rect_p target_centre, rect_p missile_centre)nogil

cdef vector2d get_vector(int heading_, float magnitude_)nogil

cdef rot_center(
        dict rotate_buffer_,
        int angle_,
        int rect_centre_x,
        int rect_centre_y
)


cdef int missile_guidance(
        int predictive_angle,
        int heading,
        int max_rotation,
        int angle
)nogil

cdef vector2d get_line_coefficient(
        float vx,
        float vy,
        float posx,
        float posy
)nogil


cdef class Homing(Sprite):

    cdef:
        public object gl, rect, image
        float magnitude, timing, dt, timer, c
        bint ignition
        public int layer, heading, angle, bingo, start
        long long int _id

    cdef void sound_fx(self)
    cdef void sound_fx_stop(self)
    cpdef location(self)
    cdef void hit(self)
    cpdef update(self, args=*)


cdef vector2d fast_lead_collision(
        float p1_x, float p1_y,
        float p2_x, float p2_y,
        float v1_x, float v1_y,
        float v2_x, float v2_y)nogil

cdef mla_pack lead_collision(
        float p1_x, float p1_y,
        float p2_x, float p2_y,
        float v1_x, float v1_y,
        float v2_x, float v2_y)nogil


cdef class Intercept(Sprite):

    cdef:
        object gl,
        float magnitude, timing, dt, timer, c
        bint ignition
        int layer, heading, angle, bingo, start, _blend
        long long int _id

    cdef void sound_fx(self)
    cdef void sound_fx_stop(self)
    cpdef location(self)
    cdef void hit(self)
    cpdef update(self, args=*)


cdef class Adaptive(Sprite):
    cdef:
        object gl,
        float magnitude, min_magnitude, timing, dt, timer, c
        bint ignition
        int layer, heading, angle, bingo, start, _blend
        long long int _id

    cdef void sound_fx(self)
    cdef void sound_fx_stop(self)
    cpdef location(self)
    cdef void hit(self)
    cpdef update(self, args=*)



cdef class Nuke(Sprite):

    cdef:
        public object gl, rect, image
        float magnitude, timing, dt, timer, c
        bint ignition
        public int layer, heading, angle, bingo, start
        long long int _id

    cdef void sound_fx(self)
    cdef void sound_fx_stop(self)
    cpdef location(self)
    cdef void hit(self)
    cpdef update(self, args=*)



