# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# Call from the main loop
# display_flare_sprite(CHILD_FLARE_INVENTORY, STAR_BURST, STAR_BURST3x, GL, VECTOR)

# NUMPY IS REQUIRED
from bloom cimport bloom_effect_array24_c

try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
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

# CYTHON IS REQUIRED
try:
    cimport cython
    from cython.parallel cimport prange
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, gfxdraw, \
        BLEND_RGB_ADD, BLEND_RGB_SUB
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d
    from pygame.image import frombuffer
    from pygame import Rect
    from pygame.time import get_ticks
    from operator import truth
    from pygame.draw import aaline
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from Sprites cimport Sprite, LayeredUpdates
from Sprites import Group

from libc.math cimport atan2, fabs, sqrt

cimport numpy as np

cdef extern from 'Include/library.c' nogil:
    float Q_rsqrt( float number )


from hsv_surface cimport hsv_surface24, hsv_surface24c

cdef extern from 'Include/wavelength.c' nogil:
    struct rgba_color:
        int r;
        int g;
        int b;
        int a;

    struct vector2d:
        float x;
        float y;

    struct angle_vector:
        float rad_angle;
        vector2d vector;

    rgba_color wavelength_to_rgba(int wavelength, float gamma)nogil
    void scale_to_length(vector2d *v, float length)nogil
    void normalize (vector2d *v)nogil
    float v_length(vector2d *vector)nogil
    angle_vector get_angle_c(vector2d *object1, vector2d *object2)nogil


cdef extern from 'Include/randnumber.c':
    void init_clock()nogil;
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;

DEF HALF = 1.0/2.0

image_load = pygame.image.load

# TODO TEST IF BELOW TEXTURES ARE IN THE LIBRARY
# SUB FLARES
TEXTURE = image_load('Assets/Untitled3.png').convert()  # 3
TEXTURE = smoothscale(TEXTURE, (100, 100))
TEXTURE.set_colorkey((0, 0, 0, 0), RLEACCEL)

TEXTURE1 = image_load('Assets/Untitled1.png').convert()  # 1
TEXTURE1 = smoothscale(TEXTURE1, (100, 100))
TEXTURE1.set_colorkey((0, 0, 0, 0), RLEACCEL)

# GLARE SPRITE
TEXTURE2 = image_load('Assets/untitled7.png').convert()  # 7
TEXTURE2 = smoothscale(TEXTURE2, (256, 256))
TEXTURE2.set_colorkey((0, 0, 0, 0), RLEACCEL)

# SPRITE DISPLAY AT THE END OF THE VECTOR

TEXTURE3 = image_load('Assets/flares.png').convert()  # 8
TEXTURE3 = smoothscale(TEXTURE3, (512, 512))
TEXTURE3.set_colorkey((0, 0, 0, 0), RLEACCEL)

# SPRITE OF THE STAR CAUSING THE FLARE EFFECT
STAR_BURST = image_load('Assets/Untitled5.png').convert(24)  # 5
STAR_BURST.set_colorkey((0, 0, 0, 0), RLEACCEL)
w, h = STAR_BURST.get_size()

# STAR SIZE TIME 4 TO INCREASE BRIGHTNESS
STAR_BURST3x = smoothscale(STAR_BURST.copy(), (w * 3, h * 3)).convert(24)

# CREATE A BLOOM EFFECT (INCREASE BRIGHTNESS)
A = smoothscale(STAR_BURST3x, (w * 3, h * 3))

STAR_BURST3x = bloom_effect_array24_c(A, 0, smooth_=1)

CHILD_FLARE_INVENTORY = []
CHILD_FLARE_INVENTORY_REMOVE = CHILD_FLARE_INVENTORY.remove
CHILD_FLARE_INVENTORY_APPEND = CHILD_FLARE_INVENTORY.append

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef make_vector2d(v):
    """
    CONVERT PYGAME.MATH.VECTOR2 OBJECT INTO A C TYPE VECTOR2D
    
    :param v: pygame.math.Vector2, vector to convert
    :return: return a C vector2d equivalent
    """
    assert PyObject_IsInstance(v, Vector2),\
        '\nIncorrect type for argument v got % ' % type(v)
    cdef vector2d v2d;
    v2d.x, v2d.y = v.x, v.y
    return v2d

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef v_surface():
    """
    CREATE A SURFACE WITH LIGHT SPECTRUM
    
    :return: Return a pygame Surface
    """

    cdef rgba_color color1
    s = Surface((370, 370))
    for r in range(380, 750):
        color1 = wavelength_to_rgba(r, 0.8)
        aaline(s, (color1.r, color1.g, color1.b, color1.a),
                           (r - 380, 0) , (r - 380, 370))
    return s

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef get_angle(vector2d obj1, vector2d obj2):
    """
    RETURN A PYGAME.MATH.VECTOR2 REPRESENTING A VECTOR 
    THIS ANGLE REPRESENT THE BEAM LENS DIRECTION
     
    :param obj1: vector2d; object 1 vector
    :param obj2: vector2d; object 2 vector
    :return: pygame.math.Vector2; Return pygame Vector2d 
    """
    cdef angle_vector av;
    av = get_angle_c(&obj1, &obj2)
    return Vector2(av.vector.x, av.vector.y)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef np.ndarray[np.int_t, ndim=2] polygon():
    """
    CREATE A FLARE POLYGON OCTAGON (REFERENCE) 
    POLYGON SHAPE IS HARD ENCODED WITH VARIABLES _a, _b, center_x, center_y  
    
    :return: Return a numpy.ndarray shape (w, h) numpy.int32
    """
    cdef short int _a = 10                      # Octagon parameter
    cdef short int _b = 30                      # Octagon parameter
    cdef int center_x = 50, center_y = 50       # Octagon's center

    # OCTAGON SIDES (OCTAGON SECOND FLARES)
    return numpy.array([[center_x - _a, center_y - _b],
                        [center_x + _a, center_y - _b],
                        [center_x + _b, center_y - _a],
                        [center_x + _b, center_y + _a],
                        [center_x + _a, center_y + _b],
                        [center_x - _a, center_y + _b],
                        [center_x - _b, center_y + _a],
                        [center_x - _b, center_y - _a]], dtype=numpy.int32, copy=False)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef list second_flares(
        object texture_,
        np.ndarray[np.int_t, ndim=2] polygon_,
        vector2d light_position_,
        float min_size,
        float max_size,
        list exception_
        ):
    """
    CREATE A FLARE POLYGON ALONG THE FLARE VECTOR DIRECTION 
    SECOND FLARE(S) ARE BUILD OFFLINE BEFORE THE MAIN LOOP 
    THE POLYGON IS THEN FILLED WITH THE GIVEN TEXTURE (variable TEXTURE)
    
    :param polygon_: numpy.ndarray; polygon (octagon) This is the shape used for sub-flares.
      see python method polygon for more details
    :param max_size: float; Max factor for resizing the polygon 
    :param min_size: float; Min factor for resizing the polygon 
    :param texture_: pygame.Surface; Flare textures optional (TEXTURE 100x100, TEXTURE1 100x100,
     TEXTURE2 256x256, TEXTURE3 256x256 TEXTURE4 120x120). Note that TEXTURE2 and TEXTURE4 are 
     finalized textures, they will be blit onto the background. 
     Pygame surface compatible 24 bit without per-pixel transparency. This surface is converted for 
     fast blit and RLEACCEL 
    :param light_position_: vector2d; Vector position for the second flare
    :param exception_: list; List containing TEXTURE(s) that do not require to be blit onto 
      the polygon object.
    :return: Return a python list object containing flares (TEXTURE, distance). 
    with TEXTURE : pygame.Surface, position vector2d (x, y), distance (float) 
    """

    cdef:
        int w = texture_.get_width()
        int h = texture_.get_height()

        # -0.8 NEGATIVE DISTANCE (BEHIND FOCAL POINT)
        # +2 AFTER FOCAL POINT
        float dist = randRangeFloat(<float>-0.8, <float>2.0)

        float a_dist = <float>fabs(dist)
        float s_, v1, v2, size_
        int v
        rgba_color color1;
        vector2d s_2

    cdef list flare = []

    # FAST C UNIFORM (FASTER THAT PYTHON RANDOM.UNIFORM METHOD)
    size_ = randRangeFloat(min_size, max_size)

    # CHECK IF THE TEXTURE CAN
    # BE BLIT DIRECTLY ONTO THE SCREEN WITHOUT
    # BEING DRAWN ONTO THE POLYGON.
    if texture_ not in exception_:

        # EMPTY SURFACE with RLEACCEL and fast blit
        texture = Surface((w, h))


        # WAVELENGTH V
        # Red     620-750        484-400
        # Orange  590-620        508-484
        # Yellow  570-590        526-508
        # Green   495-570        606-526
        # Blue    450-495        668-606
        # Violet  380-450        789-668
        v = <int>((dist * HALF) * <float>370.0 + <float>380.0)
        # GET RGBA color corresponding to the given wavelength v
        color1 = wavelength_to_rgba(v, <float>0.8)

        # FILL the TEXTURE and set_alpha
        texture.fill((color1.r, color1.g, color1.b, color1.a))
        texture.set_alpha(randRange(30, 50), RLEACCEL)   # default 30, 50

        # RESIZE
        v1 = <float>(size_ * a_dist)
        texture_ = scale(texture, (<int>(w * v1), <int>(h * v1)))

        w, h = texture_.get_size()
        s_2.x = <float> (w >> 1)
        s_2.y = <float> (h >> 1)

        # APPLY TEXTURE to polygon
        surface_ = Surface((w, h)).convert()
        gfxdraw.textured_polygon(surface_, polygon_ * v1, texture_, 0, 0)

        flare = [surface_, dist]

    # DIRECT BLIT
    else:
        s_ = randRangeFloat(<float>0.2, size_)
        v2 = <float>(s_ * a_dist)
        texture_ = scale(texture_, (<int>(w * v2), <int>(h * v2)))
        w, h = texture_.get_size()
        s_2.x, s_2.y = <float>(w >> 1), <float>(h >> 1)

        flare = [texture_, dist] #pos_, dist]

    return flare

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef float vector_length(x, y):
    return <float>sqrt(x * x + y * y)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef display_flare_sprite(object vector, object vector1):
    """
    Display all the flares sprites onto the background image
    
    :param vector1: pygame.math.Vector2 
    :param vector: pygame.math.Vector2 
 
    """
    cdef:
        vector2d v1
        float length, dx, dy, spr_pos_x, spr_pos_y
        int w, h

    if vector.x < -30:

        for spr in CHILD_FLARE_INVENTORY:

            spr_pos_x  = spr.position.x
            spr_pos_y  = spr.position.y
            spr.vector = vector
            dx = spr_pos_x + vector1.x
            dy = spr_pos_y + vector1.y

            if spr.event_type == 'PARENT':

                if 0 < vector_length(spr.vector.x, spr.vector.y) < 80:
                    spr.image = STAR_BURST3x
                    spr.rect = spr.image.get_rect(center=(dx, dy))

                else:
                    w, h = STAR_BURST.get_size()
                    spr.image = scale(STAR_BURST, (w, h))
                    spr.rect = spr.image.get_rect(center=(dx, dy))
            else:
                v1.x = spr.vector.x
                v1.y = spr.vector.y
                length = v_length(&v1)

                if length != 0:
                    scale_to_length(&v1, length * spr.alpha)
                    spr.rect.center = spr_pos_x + v1.x + vector1.x, spr_pos_y + v1.y + vector1.y

    else:
        for spr in CHILD_FLARE_INVENTORY:
            spr.kill()
            CHILD_FLARE_INVENTORY_REMOVE(spr)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef create_flare_sprite(object gl_,
                          object images_,
                          float distance_,
                          object vector_,
                          object position_, # Vector2
                          int layer_,
                          int blend_   = BLEND_RGB_ADD,
                          str event_type   = 'CHILD',
                          bint delete_ = False,
                          ):

    # CREATE A PYGAME SPRITE OBJECT
    flare_spr            = Sprite()

    Sprite.__init__(flare_spr, gl_.All)
    if PyObject_IsInstance(gl_.All, LayeredUpdates):
        gl_.All.change_layer(flare_spr, layer_)

    flare_spr.image      = <object>PyList_GetItem(images_, 0) \
        if PyObject_IsInstance(images_, list) else images_
    flare_spr.alpha      = distance_
    flare_spr.vector     = vector_
    flare_spr.rect       = flare_spr.image.get_rect(
        center=(vector_.x + position_.x, vector_.y + position_.y))
    flare_spr.position   = position_
    flare_spr._blend     = blend_
    flare_spr.event_type = event_type
    flare_spr.delete     = delete_
    flare_spr.index      = 0

    CHILD_FLARE_INVENTORY_APPEND(flare_spr)



