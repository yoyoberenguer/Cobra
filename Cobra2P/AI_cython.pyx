# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False

# encoding: utf-8

# NUMPY IS REQUIRED

try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, linspace
except ImportError:
    raise ValueError("\n<numpy> library is missing on your system."
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

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, Rect, BLEND_RGB_ADD
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, \
        make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL
    from pygame.transform import scale, smoothscale, rotate

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from libc.math cimport atan, sqrt, INFINITY

from HomingMissile import Homing

DEF M_PI = 3.14159265358979323846
# Degree to radian conversion
DEG_TO_RAD = M_PI / 180.0
# radian to degree conversion
RAD_TO_DEG = 1.0 / DEG_TO_RAD


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Entity:
    # cdef:
    #     public object parent, position
    #     public str name, category
    #     public int distance_to_player, deadly
    #     public long long int _id

    def __init__(self,
                 object parent_,
                 str name_,
                 object position_,
                 int distance_to_player_,
                 int deadly_,
                 str category_=None
                 ):
        """
        CREATE AN OBJECT (ENTITY) WITH THE FOLLOWING ATTRIBUTES

        :param parent_  : object;  Target instance
        :param name_    : string; target name or id
        :param position_: Vector2 (x, y) target coordinates
        :param distance_to_player_: Scalar value, distance between the player and target
        :param deadly_: How deadly a target can be (maximum damage)
        :param category_: string optional argument (Aircraft, ground, boss, missile)
        """

        self.parent             = parent_
        self.name               = name_
        self.position           = position_
        self.distance_to_player = distance_to_player_
        self.deadly             = deadly_
        self.category           = category_
        self._id                = id(self)


# The stack is a dictionary containing the sprite name and an entities objects
# (Entity class object)
# such as {'name0' : Entity0, 'name1: Entity1 ... 'nameN : EntityN}
# The stack dictionary keys are the sprite's names list and the dictionary values are the
# instances (Entity)
# The Sprite object is converted to an Entity model to parse only the attributes required to create
# a new object (threat object model). Those attributes are the following:
# parent, name, position, distance_to_player, deadly, category, _id
#
# parent : is the Sprite instance (containing all the attributes and methods)
# name : Name given to the sprite
# position : Sprite position tuple like (self.rect.center)
# deadly : integer value representing the deadliness of the sprite (enemy firepower)
# category : string value defining the sprite category (can be Aircraft, ground, boss,
# missile, friend)
# ---------------------------- STACK OPERATIONS -------------------------------

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline tuple GetNearestTarget(dict stack_):
    """
    RETURN THE NEAREST TARGET FROM THE STACK (CONVERTED SPRITE GROUP)
      
    The stack is created with the method create_entities by passing a Sprite group the this method
     such as 
    create_entities(screenrect, Sprite_group). 
    
    * The output returns the sprite instance (entity.parent) and the sprite name (entity name) 
      into a list in addition to the distance from the player rect center.See below for the 
      output format
    
    * Return a single sprite (if two objects are near and equidistant to the player location,
     only one
      of them will be returned (first sprite to be inserted into the sprite group) 
      
    * Use the following code to get the values : 
      nearest_sprite = GetNearestTarget(stack)
      distance, sprite_instance, sprite_name = nearest_sprite[0], *nearest_sprite[1]
    
    :param stack_: list containing consecutive tuples such as ('2068380074392', Entity object>).
     The first
    index represent the sprite name/entity name and the second, the Entity object (instance)
    :return: Return the nearest target as a tuple : (distance, [Sprite_instance, 'sprite_name'])
    """
    cdef:
        dict ordered_distances = {}

    if stack_:
        for entity_id, entity in stack_.items():
            PyDict_SetItem(ordered_distances, entity.distance_to_player, [entity.parent, entity_id])
        return sorted(ordered_distances.items(), reverse=False)[0]
    else:
        return None


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline tuple GetFarthestTarget(dict stack_):
    """
    RETURN THE FARTHEST TARGET FROM A STACK (CONVERTED SPRITE GROUP)
    
    The stack is created with the method create_entities by passing a Sprite group the this method such as 
    create_entities(screenrect, Sprite_group). 
    
    * The output returns the sprite instance (entity.parent) and the sprite name (entity name) 
      into a list in addition to the distance from the player rect center.See below for the output format
    
    * Return a single sprite (if two objects are near and equidistant to the player location, only one
      of them will be returned (first sprite to be inserted into the sprite group) 
      
    * Use the following code to get the values : 
      nearest_sprite = GetFarthestTarget(stack)
      distance, sprite_instance, sprite_name = farthest_sprite[0], *farthest_sprite[1]
    
    :param stack_: list containing consecutive tuples such as ('2068380074392', Entity object>). The first
    index represent the sprite name/entity name and the second, the Entity object (instance)
    :return: Return the nearest target as a tuple : (distance, [Sprite_instance, 'sprite_name'])
    
    :param stack_: list containing consecutive tuples such as ('2068380074392', Entity object>). The first
    index represent the id number and the second, the Entity object (instance)
    :return: Return the farthest target tuple (id, <entity object>) 
    """
    cdef:
        dict ordered_distances = {}

    if stack_:
        for entity_id, entity in stack_.items():
            PyDict_SetItem(ordered_distances, entity.distance_to_player, [entity.parent, entity_id])
        return sorted(ordered_distances.items(), reverse=True)[0]
    else:
        return None


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline list SortByDistance(dict stack_):
    """
    SORT THE STACK BY DISTANCES NEAREST TO FARTHEST
    
    :param stack_: list containing consecutive tuples such as ('2068380074392', Entity object>). The first
    index represent the sprite name and the second, the Entity object (sprite instance)
    :return: Return the stack sorted from nearest target to farthest (list)
    e.g 
    [(30, [<DummyObjects sprite(in 1 groups)>, '2093693768320']), ... 
     (50, [<DummyObjects sprite(in 1 groups)>, '2093693710464'])]
    """
    cdef:
        dict ordered_distances = {}

    if stack_:
        for entity_id, entity in stack_.items():
            PyDict_SetItem(ordered_distances, entity.distance_to_player, [entity.parent, entity_id])
        return sorted(ordered_distances.items(), reverse=False)
    else:
        return None


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline list SortByDeadliestTarget(dict stack_):
    """
    SORT THE STACK BY TARGET DEADLINESS ORDER (DEADLIEST TO HARMLESS)
    
    :param stack_: list containing consecutive tuples such as ('2068380074392', Entity object>). 
    The first index represent the sprite name and the second, the Entity object (sprite instance)
    :return: Return the stack sorted by deadliest to harmless (list)
    """
    cdef:
        dict ordered_deadliness = {}

    if stack_:
        for entity_id, entity in stack_.items():
            PyDict_SetItem(ordered_deadliness, entity.deadly, [entity.parent, entity_id])
        return sorted(ordered_deadliness.items(), reverse=True)
    else:
        return None

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline list SortByHarmlessTarget(dict stack_):
    """
    SORT THE STACK FROM HARMLESS TO DEADLIEST TARGET (HARMLESS AT THE BOTTOM)
    
    :param stack_: list containing consecutive tuples such as ('2068380074392', Entity object>). The first
    index represent the sprite name and the second, the Entity object (sprite instance)
    :return: Return the stack sorted from harmless to deadliest targets (list)
    """
    cdef:
        dict ordered_by_harmless = {}

    if stack_:
        for entity_id, entity in stack_.items():
            PyDict_SetItem(ordered_by_harmless, entity.deadly, [entity.parent, entity_id])
        return sorted(ordered_by_harmless.items(), reverse=False)
    else:
        return None


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
# DETERMINE THE GRADIENT OF A STRAIGHT LINE
cpdef inline float slope_from_point(point1_, point2_):
    """
    DETERMINE THE GRADIENT OF A STRAIGHT LINE GIVEN TWO POINTS IN A 2D CARTESIAN PLAN

    :param point1_: Vector2; Coordinates (p1_.x, p1_.y) 
    :param point2_: Vector2; Coordinates (p2_.x, p2_.y)
    :return: float; Returns the line gradient or None when p2_.x = p1_.x 
    (The slope of a vertical line is undefined)
    """
    cdef float slope
    try:
        slope = (point2_.y - point1_.y) / (point2_.x - point1_.x)
    except ZeroDivisionError:
        # The slope of a vertical line is undefined
        return INFINITY

    return slope


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline float slope_from_vector(vector_):
    """
    DETERMINE THE GRADIENT OF A STRAIGHT LINE GIVEN AN ABJECT 
    LINEAR TRAJECTORY (VECTOR DIRECTION) IN A 2D CARTESIAN PLAN
    
    :param vector_: Vector2; object vector direction (v.x, v.y)
    :return: float; Return the slope scalar value of the linear equation 
    """
    cdef slope
    try:
        slope = vector_.y / vector_.x
    except ZeroDivisionError:
        # The slope of a vertical line is undefined
        return INFINITY

    return slope


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline float intersection_c(float x_value_, equation_):
    """
    RETURN Y COORDINATE OF AN INTERSECTION KNOWING X AND ONE OF THE EQUATION MX + B

    :param x_value_  : float; x coordinate of the intersection 
    :param equation_ : Vector2; containing (M, B) values of one of the equation  
    :return: 
    """
    cdef float x = equation_.x
    cdef float y = equation_.y
    return <float> (y - x_value_ * x)


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline float theta_degree_c(p1_, p2_):
    """
    RETURN THE ANGLE OF A LINE IN DEGREES 
    
    :param p1_: Vector2; First point of the line (x, y)
    :param p2_: Vector2; Second point (x, y)
    :return: 
    """
    return <float>atan(slope_from_point(p1_, p2_)) * <float>RAD_TO_DEG


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline coefficients get_object_coefficients_c(object obj_):
    """
    DETERMINE THE SLOPE AND INTERCEPT OF A OBJECT FROM ITS (POSITION AND VELOCITY) 
    
    * Unfolding the coefficients from python : 
      result = get_object_coefficients(obj)
      m = result['m']
      b = result['b']
    
    :param obj_: object; object or instance containing attributes position and vector. The vector position indicates
    cartesian coordinates of the object in the 2d plan and the vector represent its velocity along x&y axis. 
    :return: Return a structure from cython or dict from python containing the slope and Intercept values (m,b). 
    return m=inf, and b=inf if the line is vertical
    """

    cdef coefficients mb

    # GET THE GRADIENT VALUE M (y = Mx + B)
    if PyObject_HasAttr(obj_, "vector"):
        mb.m = slope_from_vector(obj_.vector)
    else:
        raise AttributeError('Argument obj_ is missing one or more attribute (position, vector)')

    # GET THE INTERCEPT B (y = Mx + B)
    mb.b = intersection_c(mb.m, obj_.position)
    if (mb.m != INFINITY) and (mb.b!=INFINITY):
        return mb
    else:
        # The slope of a vertical line is undefined
        mb.m = INFINITY
        mb.b = INFINITY
        return mb

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline tuple get_impact_coordinates_c(object1_, object2_):
    """
    DETERMINE THE INTERSECTION POINT BETWEEN TWO OBJECTS KNOWING 
    THEIR RESPECTIVE POSITION VECTOR AND SPEED VECTOR. 
    
    * Return tuple (inf, inf) if no collision exist between two objects 
      in the 2d plan or the speed vector is length zero
    
    :param object1_: object; Python object or instance that must contains the attributes 
    position & vector 
    :param object2_: object; Python object or instance that must contains the attributes 
    position & vector 
    :return: Return the intersection point coordinates (x, y) in a 2d cartesian plan
    """

    cdef coefficients c1, c2
    cdef float x_coordinate, y_coordinate
    c1 = get_object_coefficients_c(object1_)
    c2 = get_object_coefficients_c(object2_)

    if c1.m == INFINITY or c2.m == INFINITY:
        return INFINITY, INFINITY
    else:
        try:
            x_coordinate = (c2.b - c1.b) / (c1.m - c2.m)
        except ZeroDivisionError:
            # no intersection between two lines
            return INFINITY, INFINITY

        y_coordinate = c1.m * x_coordinate + c1.b

    return x_coordinate, y_coordinate


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline float get_distance_c(p1_, p2_):
    """
    DETERMINE THE DISTANCE (LENGTH) BETWEEN TWO VECTORS (SCALAR VALUE)
     
    :param p1_: Vector2; First vector (non normalized)
    :param p2_: Vector2; Second vector (non normalized)
    :return:  Return the length between both vectors (scalar value, float)
    """
    cdef:
        float p1x = p1_.x, p1y = p1_.y, p2x = p2_.x, p2y = p2_.y
    with nogil:
        return sqrt((p1x - p2x) * (p1x - p2x) + (p1y - p2y) * (p1y - p2y))


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline bint is_colliding_c(vector, p1, p2, rect1, rect2):
    """
    DETERMINE IF A TARGET(OBJECT) COLLIDE WITH THE PLAYER RECT. 
    
    Given both the player rect and target rect and target trajectory/ speed, project the 
    target rectangle to the length |(p1 - p2)| to check if both rectangles collide. 
    
    :param vector: Vector2; Target direction and speed vector e.g vector=Vector2(-10, 5)
    .Represent the velocity along
    x and y axis in a 2d cartesian plan. Vector is not normalized. Vx, vy represent the 
    target direction and 
    the vector length represent the speed of the target. 
    :param p1: Vector2; Player rect center 
    :param p2: Vector2; Target rect center
    :param rect1: Player rect 
    :param rect2: Target rect
    :return: Return a tuple(True|False, clip) True when the target is in collision course
     False otherwise. 
    """
    # Both vector components must be null for a vector length zero
    if vector.x == 0 and vector.y == 0:
        return tuple((False, rect1))

    # Determine the respective distance between player rect center and target rect center.
    # Then scale to length the target vector (projection)
    vector.scale_to_length((p2 - p1).length())
    # Target vector is stretched to the player rect center to check if both rect collides
    # Note also that rect2 center is adjust (target rect) this is why rect2 is a copy of the
    # original rect obj.rect
    rect2.center = vector + p2
    return bool(rect1.colliderect(rect2))


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef inline list colliders_c(screenrect_, stack_, player_rect_):
    """
    FIND ALL SPRITES IN COLLISION COURSE WITH PLAYER 1 OR PLAYER 2

    * Only objects(sprites) display on screen are checked for collision
    :param screenrect_ : pygame.Rect; represent the size of the current display 
    :param stack_: Pygame sprite group; Sprite group containing all the object to check for 
    collision
    :param player_rect_: Player rectangle, For player1 or player2
    :return: return a list of objects in collision course with current player (player 1 or
     player 2)
    """

    cdef:
        list colliders_ = []
        colliders_append = colliders_.append
        float prect_centerx = player_rect_.centerx
        float prect_centery = player_rect_.centery

    for obj in stack_:

        obj_rect = obj.rect

        if screenrect_.contains(obj_rect):

            if PyObject_HasAttr(obj, 'rect') and PyObject_HasAttr(obj, 'vector'):
                # Note also that rect2 center will be adjust/moved this is why rect2
                # is a copy of the
                # original rect obj.rect
                rect2        = obj_rect.copy()
                rect2_center = Vector2(rect2.center)
                vector_copy  = Vector2(obj.vector.x, obj.vector.y)

                if is_colliding_c(vector    = vector_copy,
                                p1          = Vector2(prect_centerx, prect_centery),
                                p2          = rect2_center,
                                rect1       = player_rect_,
                                rect2       = rect2):
                    colliders_append(obj)

    return colliders_


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
class Threat(Rect):
    inventory = []

    def __init__(self, player_rect_):
        """

        :param player_rect_: Player Rectangle (pygame.Rect)
        """
        Rect.__init__(self, player_rect_)
        self.rect_vector=Vector2(self.center)

    def get_point_distance(self, point_):
        """
        DISTANCE BETWEEN PLAYER RECT CENTER AND A SPACIAL COORDINATES (X, Y)

        :param point_: tuple or Vector2; coordinates (x, y)
        :return: integer; distance between player rect center and given point
        """
        cdef:
            float pos_x = self.rect_vector.x
            float pos_y = self.rect_vector.y
            float xx = point_.x if PyObject_IsInstance(point_, Vector2) else point_[0]
            float yy = point_.y if PyObject_IsInstance(point_, Vector2) else point_[1]
        return <int>sqrt((pos_x - xx) * (pos_x - xx) + (pos_y - yy) * (pos_y - yy))

    def get_rect_distance(self, rect_):
        """
        RETURN THE DISTANCE BETWEEN PLAYER RECT CENTER AND ANOTHER RECT OF CENTER (X, Y)

        :param rect_: Rect; object rect (pygame.Rect)
        :return: integer; Return the distance between both rectangle centers
        """
        cdef:
            int pos_x = self.rect_vector.x
            int pos_y = self.rect_vector.y
            int rcx   = rect_.centerx
            int rcy   = rect_.centery
        return <int>sqrt((pos_x - rcx) * (pos_x - rcx) + (pos_y - rcy) * (pos_y - rcy))

    def get_all_rect_distances(self, screenrect_,  list stack_):
        """
        :param screenrect_: Pygame.Rect; represent the size of the current display
        :param stack_: List; containing all the enemy objects
        :return:
        """
        cdef dict distances = {}

        for obj in stack_:
            obj_rect = obj.rect
            if screenrect_.contains(obj_rect):
                PyDict_SetItem(distances, obj._id, <int>(
                    self.rect_vector.distance_to(Vector2(obj_rect.center))))
        return distances


    def create_entities(self, screenrect_, stack_):
        """
        TAKE A SPRITE GROUP AS ARGUMENT AND CONVERT THE SPRITE GROUP INTO AN ENTITY MODEL

        Sprite objects are converted to an Entity model to parse only the attributes
        required to create
        a new object (threat object model). Those attributes are the following:
        parent, name, position, distance_to_player, deadly, category, _id.

        The Entity model allow to focus only on certain attributes such as distance to the
        player and deadliness of an object. Used in conjunction to the following methods:

        GetNearestTarget(dict stack_)
        GetFarthestTarget(dict stack_)
        SortByDistance(dict stack_)
        SortByDeadliestTarget(dict stack_)
        SortByHarmlessTarget(dict stack_)

        and you have some very powerful tools for AI decision making

        parent : is the Sprite instance (containing all the attributes and methods)
        name : Name given to the sprite
        position : Sprite position tuple like (self.rect.center)
        deadly : integer value representing the deadliness of the sprite (enemy firepower)
        category : string value defining the sprite category (can be Aircraft, ground, boss,
        missile, friend)

        * Only object display on the screen (if screenrect.colliderect(obj_rect)) are checked
          and placed into the inventory

        :param screenrect_: Pygame.Rect; Pygame current display size
        :param stack_: pygame sprite group
        :return: Return the entity model (python dictionary)
        """

        cdef:
            dict entities = {}
            center_pos = self.rect_vector

        for obj in stack_:

            obj_rect = obj.rect
            obj_rect_center = Vector2(obj_rect.center)

            if screenrect_.colliderect(obj_rect):

                if PyObject_HasAttr(obj, 'enemy_'):
                    # FRIENDLY OBJECT IS NO THREAT TO THE PLAYER
                    if PyObject_HasAttr(obj.enemy_, 'category') and \
                            obj.enemy_.category is 'friend':
                        continue
                    else:
                        PyDict_SetItem(entities, obj.enemy_.id, Entity(
                            obj, obj.enemy_.name, obj.position, <int>(center_pos.distance_to(
                                obj_rect_center)), obj.damage, obj.enemy_.category))

                # MISSILE OBJECT
                elif PyObject_IsInstance(obj, Homing):
                    if PyObject_HasAttr(obj, 'enemy_'):
                        PyDict_SetItem(entities, obj.enemy_.id, Entity(
                            obj, obj.enemy_.name, obj.position, <int>(center_pos.distance_to(
                                obj_rect_center)), obj.damage, 'missile'))
                    # MISSILE WITHOUT ATTR ENEMY_ ARE PLAYER'S MISSILES
                    else:
                        continue

                # ASTEROID LIKE OBJECT
                elif PyObject_HasAttr(obj, 'asteroids'):
                    PyDict_SetItem(entities, obj._id, Entity(
                        obj, obj.asteroids.name, obj.position,
                        <int>(center_pos.distance_to(obj_rect_center)), obj.damage))

                # DUMMY RECTANGLE ARE NOT A THREAT OBJECT (NUKE DUMMY RECT)
                else:
                    if PyObject_HasAttr(obj, 'dummy'):
                        continue

        Threat.inventory = entities
        return entities


    def GetNearestCollider(self, stack_):
        """
        RETURN THE NEAREST OBJECT ON COLLISION COURSE TO THE PLAYER RECT CENTER

        * stack_ can be a pygame sprite group

        :param stack_: Sprite group; dict containing all the object to sort such as
        {int id: object}
        :return: Return a tuple such as (12.727922439575195, [<DummyObjects sprite(in 1 groups)>,
         2670298795520])
        containing the distance from the player rect center, the object class instance and the object name
        """

        cdef:
            dict sort_by_distance = {}


        if stack_:
            for obj in stack_:
                PyDict_SetItem(
                    sort_by_distance, get_distance_c(
                        Vector2(self.rect_vector), Vector2(obj.rect.center)), [obj, id(obj)])
            return sorted(sort_by_distance.items(), reverse=False)[0]
        else:
            return None

    def SortByFarthestCollider(self, stack_):
        """
        RETURN THE FARTHEST OBJECT ON COLLISION COURSE TO THE PLAYER RECT CENTER

        * stack_ can be a pygame sprite group

        :param stack_: Sprite group; Sprite group containing all the object to sort
        :return: Return a tuple such as (12.727922439575195, [<DummyObjects sprite(in 1 groups)>,
         2670298795520])
        containing the distance from the player rect center, the object class instance and the
         object name
        """
        cdef:
            dict sort_by_distance = {}

        if stack_:
            for obj in stack_:
                PyDict_SetItem(
                    sort_by_distance, get_distance_c(
                        self.rect_vector, Vector2(obj.rect.center)), [obj, id(obj)])
            return sorted(sort_by_distance.items(), reverse=True)[0]
        else:
            return None

    # BELOW CONVENIENT HOOKS FOR STATIC METHODS DEFINE ABOVE AND TO KEEP THE SOURCE CODE
    # RUNNING FROM THE MAIN LIBRARIES
    # ULTIMATELY THESE HOOKS WILL BE REMOVED WHEN THE SOURCE CODE.
    @staticmethod
    def single_sorted_by_distance_nearest(stack_):
        return GetNearestTarget(stack_)

    @staticmethod
    def single_sorted_by_distance_farthest(stack_):
        return GetFarthestTarget(stack_)

    @staticmethod
    def sort_by_distance(stack_):
        return SortByDistance(stack_)

    @staticmethod
    def sort_by_high_deadliness(stack_):
        return SortByDeadliestTarget(stack_)

    @staticmethod
    def sort_by_low_deadliness(stack_):
        return SortByHarmlessTarget(stack_)

    @staticmethod
    def slope(p1_, p2_):
        return slope_from_point(p1_, p2_)

    @staticmethod
    def intersection(slope_, point_):
        return intersection_c(slope_, point_)

    @staticmethod
    def theta_degree(p1_, p2_):
        return theta_degree_c(p1_, p2_)

    @staticmethod
    def get_object_coefficients(obj_):
        return get_object_coefficients_c(obj_)

    @staticmethod
    def get_impact_coordinates(object1_, object2_):
        return get_impact_coordinates_c(object1_, object2_)

    @staticmethod
    def get_distance(p1_, p2_):
        return get_distance_c(p1_, p2_)

    def sort_by_nearest_collider(self, stack_):
        return self.GetNearestCollider(stack_)

    def sort_by_farthest_collider(self, stack_):
       return self.SortByFarthestCollider(stack_)

    def colliders(self, screenrect_, stack_, player_rect_):
        return colliders_c(screenrect_, stack_, player_rect_)

    @staticmethod
    def is_colliding(vector, p1, p2, rect1, rect2):
        return is_colliding_c(vector, p1, p2, rect1, rect2)
