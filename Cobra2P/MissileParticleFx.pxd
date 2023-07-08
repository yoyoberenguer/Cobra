# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# CYTHON IS REQUIRED

cdef extern from 'Include/vector.c':

    struct vector2d:
        float x;
        float y;

    void vecinit(vector2d *v, float x, float y)nogil;
    float vlength(vector2d *v)nogil;
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;


cdef transparency(image_, int alpha_)

cdef float get_angle(vector2d object1, vector2d object2)nogil

cdef vector2d projection_radian(vector2d point_, vector2d rect_, float angle_)nogil

cdef class MissileParticleFx_improve:

    cdef:
        int length_1, alpha, _layer, index, _blend,
        last_frame, n
        object images, image, rect, vector, gl
        list VERTEX_ARRAY_MP
        float timing, dt, timer
        vector2d position


    cpdef update(self, screen, screen_rect)


cdef class MParticleFX(object):

    cdef:
        int length_1, alpha, _layer, index, _blend,
        last_frame, n
        object images, image, rect, vector, gl, rr
        float timing, dt, timer
        vector2d position

    cpdef update(self, screen)