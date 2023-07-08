# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

# CYTHON IS REQUIRED
from math import fabs

import numpy

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

from numpy import empty, uint8, asarray

cdef extern from 'Include/randnumber.c':
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;

from libc.stdio cimport printf

DEF M_PI = 3.14159265358979323846

try:
    import pygame
    from pygame import freetype, Color, BLEND_RGB_ADD, RLEACCEL, Surface, Rect
    from pygame import freetype
    from pygame.freetype import STYLE_STRONG
    from pygame.transform import rotate, smoothscale
    from pygame.surfarray import pixels3d
    from pygame.image import frombuffer
    from pygame.math import Vector2

except ImportError:
    print("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")
    raise SystemExit

from Sprites import Sprite
from libc.math cimport atan2, sin, cos, sqrt


DEF SCHEDULE = 'static'

DEF OPENMP = True
# num_threads – The num_threads argument indicates how many threads the team should consist of.
# If not given, OpenMP will decide how many threads to use.
# Typically this is the number of cores available on the machine. However,
# this may be controlled through the omp_set_num_threads() function,
# or through the OMP_NUM_THREADS environment variable.
DEF THREAD_NUMBER = 1
if OPENMP is True:
    DEF THREAD_NUMBER = 8

pygame.init()
freetype.init(cache_size=64, resolution=72)
SCREENRECT = pygame.Rect(0, 0, 800, 800)
screen = pygame.display.set_mode(SCREENRECT.size, pygame.HWSURFACE, 32)



VERTEX_ARRAY_SUBSURFACE = []


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline unsigned char [:, :, ::1] pixel_block_rgb(
        unsigned char [:, :, :] array_, int start_x, int start_y,
        int w, int h, unsigned char [:, :, ::1] block) nogil:
    """
    EXTRACT A SPRITE FROM A SPRITE SHEET 

    * Method used by Sprite_Sheet_Uniform_RGB in order to extract all the sprites from 
    the sprite sheet
    * This method returns a memoryview type [:, :, ::1] contiguous of unsigned char 
    (sprite of size w x h)

    :param array_ : unsigned char; array of size w x h x 3 to parse into sub blocks
     (non contiguous)
    :param start_x: int; start of the block (x value) 
    :param start_y: int; start of the block (y value)
    :param w      : int; width of the block
    :param h      : int; height of the block
    :param block  : unsigned char; empty block of size w_n x h_n x 3 to fill up 
    :return       : Return 3d array of size (w_n x h_n x 3) of RGB pixels 
    """

    cdef:
        int x, y, xx, yy

    for x in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
        xx = start_x + x
        for y in range(h):
            yy = start_y + y
            block[x, y, 0] = array_[xx, yy, 0]
            block[x, y, 1] = array_[xx, yy, 1]
            block[x, y, 2] = array_[xx, yy, 2]

    return block

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef surface_split(surface_, int size_, int rows_, int columns_):

    cdef:
        unsigned int w, h
        int bitsize

    bitsize = surface_.get_bitsize()
    w, h = surface_.get_size()

    cdef:

        unsigned char [:, :, :] rgb_array = \
            pixels3d(surface_).transpose(1, 0, 2)
        list subsurface = []
        int rows, columns
        int start_x, end_x, start_y, end_y;
        int width = <object>rgb_array.shape[1]
        int height = <object>rgb_array.shape[0]

    cdef:
        unsigned char [:, :, ::1] empty_array = empty((size_, size_, 3), uint8)
        unsigned char [:, :, ::1] block_array = empty((size_, size_, 3), uint8)

    with nogil:
        for rows in range(rows_):
            start_y = rows * size_
            end_y   = (rows + 1) * size_
            for columns in range(columns_):
                start_x = columns * size_
                end_x   = start_x + size_
                block_array = pixel_block_rgb(
                    rgb_array, start_y, start_x, size_, size_, empty_array)
                with gil:
                    block_array_asarray = asarray(block_array)
                    sub_surface = frombuffer(
                        block_array_asarray.copy(order='C'), (size_, size_), 'RGB')
                    PyList_Append(subsurface, sub_surface.convert())
    return subsurface

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef burst(gl_, image_, list vertex_array_, int block_size_, int rows_,
          int columns_, int x_, int y_, int max_angle_=359, int type_=0):
    """
    EXPLODE A SURFACE IN MULTIPLE SUBSURFACE OR PIXELS

    :param gl_        : class; global constants/variables
    :param image_     : pygame.Surface; Surface to transform into multiple subsurface or pixels
    :param block_size_: integer; Size of the subsurface (square entity w x h) or size 1 for 
    a pixel entity
    :param rows_      : integer; number of rows
    :param columns_   : integer; number of columns
    :param x_         : integer; position x of the surface (top left corner) before the blast
    :param y_         : integer; position y of the surface (top left corner)
    :param max_angle_ : integer; Angle projection of the particle/pixel/subsurface in the
     2d cartesian plan
    :param type_      : integer; Type of projection :
     0 : RANDOM BURST (Random direction for each pixels/subsurface,
     1 : OMNI-DIRECTIONAL (Angle determine by the pixel position in the surface),
     2 : BURST IN SINGLE DIRECTION (Focus burst, all pixels /subsurface are flying in the
         same direction -1/2 angle; +1/2 angle
     3 : STATIC; Pixels/ subsurface are static for alpha processing instead (work in progress)
     4 : SKEW 
    :return           :
    """
    cdef:
        list subsurface = surface_split(image_, block_size_, rows_, columns_)
        int n = 0
        float a = max_angle_ >> 1
        float deg_to_rad = M_PI / <float>180.0
        int frame = gl_.FRAME

    r = Rect(x_, y_, columns_ * block_size_, rows_ * block_size_)

    # RANDOM BURST (ALL DIRECTIONS)
    if type_ == 0:

        for surf in subsurface:
            s = Sprite()
            s.image = surf

            s.rect = surf.get_rect(
                topleft=((n % columns_) * block_size_ + x_,
                         <int>(n / columns_) * block_size_ + y_))

            angle = randRangeFloat(<float>0.0, max_angle_)
            s.vector = Vector2(<float>cos(angle),
                               <float>sin(angle)) * randRangeFloat(<float>5.0, <float>10.0)
            n += 1
            s.org = (s.rect.topleft[0], s.rect.topleft[1])
            s.counter = 0
            s.stop = False
            s.rebuild_state = False

            vertex_array_.append(s)

    # OMNI-DIRECTIONAL BURST
    elif type_ == 1:

        for surf in subsurface:
            s = Sprite()
            s.image = surf
            s.rect = surf.get_rect(
                topleft=((n % columns_) * block_size_ + x_,
                         <int>(n / columns_) * block_size_ + y_))
            s.angle = <float>atan2(s.rect.centery - r.centery, s.rect.centerx - r.centerx)
            s.vector = Vector2(<float>cos(s.angle),
                               <float>sin(s.angle)) * randRangeFloat(<float>3.0, <float>5.0)
            s.start = frame  # + n >> 8
            s.end = s.start + randRange(<int>10, <int>80)
            s.org = (s.rect.topleft[0] - x_, s.rect.topleft[1] - y_)
            s.image_org = s.image.copy()
            vertex_array_.append(s)
            n += 1

    # BURST IN SINGLE DIRECTION
    elif type_ == 2:

        for surf in subsurface:
            s = Sprite()
            s.image = surf
            # RECT TOP LEFT POSITION THAT MATCH THE SUBSURFACE INDENT
            s.rect = surf.get_rect(
                topleft=((n % columns_) * block_size_ + x_,
                         <int>(n / columns_) * block_size_ + y_))

            # RANDOM ANGLE IN RADIAN
            s.angle = randRangeFloat(max_angle_ -a, max_angle_ + a) * deg_to_rad

            # VECTOR / DIRECTION IF THE SUBSURFACE
            s.vector = Vector2(cos(s.angle), sin(s.angle)) * randRange(<int>3, <int>10)
            s.vector.x = <int>s.vector.x
            s.vector.y = <int>s.vector.y
            s.start = frame  # + n >> 8
            s.end = s.start + randRange(<int>10, <int>80)
            s.org = (s.rect.topleft[0] - x_, s.rect.topleft[1] - y_)
            s.org_rect = Rect(s.rect.topleft[0] - x_,
                              s.rect.topleft[1] - y_, block_size_, block_size_)

            s.image_org = s.image.copy()
            vertex_array_.append(s)
            n += 1


    # STATIC
    elif type_ == 3:

        for surf in subsurface:
            s = Sprite()
            s.image = surf
            s.rect = surf.get_rect(
                topleft=((n % columns_) * block_size_ + x_,
                         <int>(n / columns_) * block_size_ + y_))
            s.angle = randRangeFloat(max_angle_ - a, max_angle_ + a) * deg_to_rad
            s.vector = Vector2(<float>cos(s.angle),
                               <float>sin(s.angle)) * randRangeFloat(<float>3.0, <float>10.0)
            s.start = frame  + n >> 2
            s.end = s.start + randRange(<int>10, <int>80)
            s.org = (s.rect.topleft[0] - x_, s.rect.topleft[1] - y_)
            s.image_org = s.image.copy()
            s.counter = 0
            n += 1
            s._blend = BLEND_RGB_ADD
            vertex_array_.append(s)


    # SKEW
    elif type_ == 4:
        for surf in subsurface:
            s = Sprite()
            s.image = surf
            s.rect = surf.get_rect(
                topleft=((n % columns_) * block_size_ + x_,
                         <int>(n / columns_) * block_size_ + y_))
            s.vector = Vector2(<float>10.0, <float>0.0)
            s.start = frame + n//columns_
            s.end = s.start + randRange(<int>10, <int>80)
            s.org = (s.rect.topleft[0] - x_, s.rect.topleft[1] - y_)
            s.image_org = s.image.copy()
            vertex_array_.append(s)
            n += 1
    return vertex_array_

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void display_burst(object screen_, list vertex_array_, unsigned char blend_=0):
    """
    DISPLAY AN EXPLODED IMAGE 
    
    This method decrement the pixels/blocks alpha value each frame
    Be aware that using blend_ (BLEND_RGB_ADD etc) will prevent the alpha channel to be modified
    
    :param screen_: Surface; game display  
    :param vertex_array_: python list containing objects (pixels or blocks of pixels) set with 
       pre-defined attributes and values.
    :param blend_: unsigned char; blend mode (additive mode)
    """

    cdef:
        screen_blit = screen_.blit
        screenrect  = screen_.get_rect()

    for s in vertex_array_:

        if s.rect.colliderect(screenrect):

            s_rect          = s.rect
            s_vector        = s.vector
            s_rect.centerx += s_vector.x
            s_rect.centery += s_vector.y

            screen_blit(s.image, s.rect, special_flags=blend_)

            s.image.set_alpha(max(<unsigned char>255 - s.counter, 0), RLEACCEL)
            s.counter += 2

        else:
            vertex_array_.remove(s)



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void rebuild_from_frame(
        object screen_,
        unsigned int current_frame_,
        unsigned int start_frame,
        list vertex_array_,
        unsigned char blend_ = 0
):
    """
    REBUILD AN EXPLODED IMAGE FROM A GIVEN FRAME NUMBER

    :param screen_ : Surface; game display
    :param current_frame_: unsigned int; Current frame value
    :param start_frame : unsigned int; Frame number when image is starting rebuilding
    :param vertex_array_: python list containing objects (pixels or blocks of pixels) set with 
       pre-defined attributes and values.
    :param blend_: unsigned char; blend mode (additive mode)
    :return: void
    """
    if start_frame == 0:
        raise ValueError("\nYou must specify a start frame number != 0")


    cdef:
        screen_blit = screen_.blit
        int s_org0, s_org1

    screenrect = screen_.get_rect()

    for s in vertex_array_:

        if current_frame_ > start_frame and not s.rebuild_state:
            # INVERT VECTOR TO REBUILD IMAGE
            s.vector = -s.vector
            s.rebuild_state = True

        s_rect          = s.rect
        s_vector        = s.vector
        s_rect.topleft += s_vector

        # START TO CHECK DISTANCE ONLY WHEN THE FRAME IS > START_FRAME
        # OTHERWISE THE DISTANCE WILL BE <2 WHEN THE PROCESS BEGIN
        if current_frame_ > start_frame and not s.stop:

            s_org0, s_org1 = s.org[0], s.org[1]

            if <float>sqrt((s_org0 - s.rect.topleft[0]) ** 2
                    + (s_org1 - s.rect.topleft[1]) ** 2) < <float>2.0:
                s.vector = Vector2(<float>0.0, <float>0.0)
                s.rect.topleft = (s_org0, s_org1)
                s.stop = True

        if screenrect.contains(s_rect):
            screen_blit(s.image, s.rect, special_flags=blend_)



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void burst_into_memory(
        unsigned int n_,
        list vertex_array_,
        object screenrect,
        bint warn_ = False,
        bint auto_n_ = False
):
    """
    BURST AN IMAGE INTO MEMORY AND MEMORIZED ITS LOCATION AFTER N ITERATIONS

    This method can be use in addition to the method rebuild_from_memory 
    to give the illusion of an image rebuilding from pixels or pixel's blocks.

    :param n_: Number of iterations. Each iteration, the pixels or the block of pixels 
       will be moved to a new locations given by the vector value. We are moving the pixels by
       incrementing the top left corner of the block. 

    :param vertex_array_: python list containing objects (pixels or blocks of pixels) set with 
       pre-defined attributes and values. Here we are using only two attributes, s.rect and 
       s.vector. The block rectangle limitations and the vector direction.
    
    :param screenrect: pygame.Rect object; Represent the display rectangle     
    
    :param warn_: bool; Default False, do not display a warning if one or more pixels are still 
        visible within the game display. This setting will be ignored if auto_n_ is True 
        
    :param auto_n_: bool; n_ value will be ignore. Auto check if pixels or pixels blocks are 
        still visible within the game space and increment n_ automatically (recursive), this 
        method is the best if you have no clue how many frames will be required to burst an image
        until all the pixels/blocks are outside the screen boundaries. It will also found the most
        effective frame number (lowest frame)
    
    :return: void
    """
    assert n_ > 0, "\nArgument n_ must be > 0"

    cdef bint contain_rect

    if auto_n_:
        n_ = 1
        warn_ = False

    # N ITERATIONS, MOVE THE PIXELS OR BLOCKS
    for _ in range(n_):

        # RESET THE VALUE
        contain_rect = False

        for s in vertex_array_:
            s.rect.topleft += s.vector
            if screenrect.contains(s.rect):
                contain_rect = True

    if contain_rect:
        if auto_n_:
            burst_into_memory(
                n_,
                vertex_array_,
                screenrect,
                warn_=warn_,
                auto_n_=auto_n_
            )

    # THROW AN ERROR MSG WHEN PIXELS ARE STILL VISIBLE
    # WITHIN THE GAME DISPLAY
    if warn_:
        if contain_rect:
            raise ValueError("\nburst_into_memory - At least "
                             "one or more pixels are still visible, increase n_.")


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void rebuild_from_memory(object screen_, list vertex_array_, unsigned char blend_=0):
    """
    REBUILD AN IMAGE FROM EXPLODED PIXELS OR PIXEL'S BLOCK (PIXELS 
    BEING OUTSIDE SCREEN BOUNDARIES)
    
    :param screen_: Pygame.Surface object; Game display 
    :param vertex_array_: list; python list containing objects (pixels or blocks of pixels) 
        set with pre-defined attributes and values.
    :param blend_: unsigned char; blend mode (additive mode)
    """

    cdef:
        screen_blit = screen_.blit
        int s_org0, s_org1

    screenrect = screen_.get_rect()

    # ITERATE OVER EVERY BLOCKS
    for s in vertex_array_:

        s.rect.topleft -= s.vector
        s_rect = s.rect

        # CHECK THE BLOCK STATUS,
        if not s.stop:

            s_org0, s_org1 = s.org[0], s.org[1]

            # DETERMINE THE DISTANCE FROM ORIGIN
            # AVOIDING SQUARE ROOT TO INCREASE PERFS
            if ((s_org0 - s_rect.topleft[0]) * (s_org0 - s_rect.topleft[0])
                    + (s_org1 - s_rect.topleft[1]) *(s_org1 - s_rect.topleft[1])) < <float>8.0:
                s.vector = Vector2(<float>0.0, <float>0.0)
                s_rect.topleft = (s_org0, s_org1)
                s.stop = True

        if screenrect.contains(s_rect):

            # DRAW THE PIXEL BLOCKs
            screen_blit(s.image, s.rect, special_flags=blend_)



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef skew_display(
        object screen_,
        unsigned int current_frame,
        vertex_array_,
        unsigned char blend_=0
):
    """
    DISPLAY A SKEW IMAGE (MOVING PIXEL BLOCKS TO THE RIGHT)  
    
    To use this method you need to call burst method with type=4 
    Using type 4 create the necessary attributes s.start to use 
    within skew_display
    
    :param screen_: pygame Surface; game display
    :param current_frame: unsigned int; current frame 
    :param vertex_array_: list; python list containing objects (pixels or blocks of pixels) 
        set with pre-defined attributes and values.
    :param blend_: unsigned char; blend (additive mode)
    
    """

    cdef:
        screen_blit = screen_.blit

    for s in vertex_array_:

        if current_frame > s.start:
            s_rect = s.rect
            s_vector = s.vector
            s_rect.centerx += s_vector.x
            s_rect.centery += s_vector.y

        screen_blit(s.image, s.rect, special_flags=blend_)
