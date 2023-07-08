# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

cdef extern from 'Include/vector.c':
    struct vector2d:
        float x;
        float y;

    cdef float M_PI;


cdef struct coefficients:
    float m;
    float b;

cdef float RAD_TO_DEG = 180.0 / M_PI

cdef class Entity:
    cdef:
        public object parent, position
        public str name, category
        public int distance_to_player, deadly
        public long long int _id

cdef class Entity
cpdef tuple GetNearestTarget(dict stack_)
cpdef tuple GetFarthestTarget(dict stack_)
cpdef list SortByDistance(dict stack_)
cpdef list SortByDeadliestTarget(dict stack_)
cpdef list SortByHarmlessTarget(dict stack_)
cpdef float slope_from_point(point1_, point2_)
cpdef float slope_from_vector(vector_)
cpdef float intersection_c(float x_value_, equation_)
cpdef float theta_degree_c(p1_, p2_)
cpdef coefficients get_object_coefficients_c(object obj_)
cpdef tuple get_impact_coordinates_c(object1_, object2_)
cpdef float get_distance_c(p1_, p2_)
cpdef bint is_colliding_c(vector, p1, p2, rect1, rect2)
cpdef list colliders_c(screenrect_, stack_, player_rect_)

