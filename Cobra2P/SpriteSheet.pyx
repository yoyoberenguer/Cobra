# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8
from __future__ import print_function
import os

from Constants import GLOBAL

GL = GLOBAL()

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

cimport numpy as np


# CYTHON IS REQUIRED
try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject, PyObject_HasAttr, PyObject_IsInstance
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")


# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface, \
        blit_array
    from pygame.image import frombuffer
except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")


DEF SCHEDULE = 'static'

DEF OPENMP = True
# num_threads – The num_threads argument indicates how many threads the team should consist of.
# If not given, OpenMP will decide how many threads to use.
# Typically this is the number of cores available on the machine. However,
# this may be controlled through the omp_set_num_threads() function,
# or through the OMP_NUM_THREADS environment variable.
DEF THREAD_NUMBER = 1
if OPENMP is True:
    DEF THREAD_NUMBER = 10

from libc.stdio cimport printf
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef sprite_sheet_per_pixel(str file_, int chunk_, int rows_, int columns_):
    """
    VERSION FOR 32 BIT WITH TRANSPARENCY ALPHA LAYER
    METHOD EQUIVALENT TO Sprite_Sheet_Uniform_RGBA (SLIGHTLY FASTER)
    
    * Transform a uniform spritesheet into a python list containing the sprite animation
    * Compatible with 32-bit spritesheet containing layer alpha 
    * All sprites must be uniform (equivalent width and height)
    
    :param file_: string; full path to the SpriteSheet such as "C:\\directory\\file"
    :param chunk_: integer; Size in pixels of a single sprite (ex 200 pixels for a 
    sprite size 200x200).  
    :param rows_: integer; number of rows 
    :param columns_: integer; number of columns 
    :return: Returns a python list containing all the sprites converted to fast blit
     pygame.convert_alpha()
    """
    if not pygame.display.get_init():
        raise ValueError("Display module has not been initialized")

    if chunk_ == 0:
        raise ValueError("\nArgument chunk_ cannot be zero!")

    cdef:
        str path_to_surface = os.path.join("", "", file_)
        int w, h

    if not os.path.isfile(path_to_surface):
        raise FileNotFoundError("No such file or directory: %s " % file_)
    try:
        surface = pygame.image.load(file_)
        # buffer_ = surface.get_view('2')
        buffer_ = pygame.image.tobytes(surface, "RGBA")
        w, h = surface.get_size()
        source_array = numpy.frombuffer(buffer_, dtype=uint8).reshape((h, w, 4))

    except Exception as e:
        raise ValueError("Cannot load spritesheet %s.\n"
                         "Invalid file format or bitsize incompatible\nError %s\n"
                         "This version is compatible with 32-bit spritesheet with "
                         "layer alpha" % (file_, e))
    cdef:
        list sprite_animation = []
        int rows, columns

    with nogil:
        for rows in prange(rows_, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for columns in range(columns_):
                with gil:
                    array1 = source_array[rows * chunk_:(rows + 1) * chunk_,
                             columns * chunk_:(columns + 1) * chunk_, :]
                    sub_surface = frombuffer(array1.copy(order='C'), (chunk_, chunk_), 'RGBA')
                    PyList_Append(sprite_animation, sub_surface.convert_alpha())

    return sprite_animation

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef sprite_sheet(str file_, int chunk_, int rows_, int columns_):
    """
    VERSION 24 BIT WITH NO ALPHA LAYER
    METHOD EQUIVALENT TO Sprite_Sheet_Uniform_RGB (BUT SLOWER)

    * Transform a uniform spritesheet into a python list containing the sprite animation
    * Compatible with 24-bit spritesheet without per-pixel transparency
    * All sprites must be uniform (equivalent width and height)

    :param file_: string; full path to the SpriteSheet such as "C:\\directory\\file"
    :param chunk_: integer; Size in pixels of a single sprite (ex 200 pixels for a 
    sprite size 200x200).  
    :param rows_: integer; number of rows 
    :param columns_: integer; number of columns 
    :return: Returns a python list containing all the sprites converted to fast 
    blit pygame.convert()
    """

    if not pygame.display.get_init():
        raise ValueError("Display module has not been initialized")

    if chunk_ == 0:
        raise ValueError("\nArgument chunk_ cannot be zero!")

    cdef:
        str path_to_surface = os.path.join("", "", file_)
        int w, h

    if not os.path.isfile(path_to_surface):
        raise FileNotFoundError("No such file or directory: %s " % file_)
    try:
        surface = pygame.image.load(file_)
        # buffer_ = surface.get_view('2')
        buffer_ = pygame.image.tobytes(surface, "RGB")
        w, h = surface.get_size()
        source_array = numpy.frombuffer(buffer_, dtype=uint8).reshape((h, w, 3))

    except Exception as e:
        raise ValueError("Cannot load spritesheet %s.\n"
                         "Invalid file format or bitsize incompatible\nError %s\n"
                         "This version is compatible with 24-bit spritesheet without "
                         "layer alpha" % (file_, e))
    cdef:
        list sprite_animation = []
        int rows, columns

    with nogil:
        for rows in prange(rows_, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for columns in range(columns_):
                with gil:
                    array1 = source_array[rows * chunk_:(rows + 1) * chunk_,
                             columns * chunk_:(columns + 1) * chunk_, :]
                    sub_surface = frombuffer(array1.copy(order='C'), (chunk_, chunk_), 'RGB')
                    PyList_Append(sprite_animation, sub_surface.convert())

    return sprite_animation

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef Sprite_Sheet_Uniform_RGB(
        str file_, int size_, int rows_, int columns_):
    """
    VERSION 24 BIT 
    TRANSFORM A *UNIFORM SPRITE SHEET INTO A PYTHON LIST CONTAINING ALL SPRITE ANIMATION
    UNIFORM : All sprites in the sprite sheet must have equivalent width and height (square sprites)
    
    spritesheet (1536x1280) containing 30 sprites 
    rows = 5, columns = 6 and size = 1536 / columns = 1280 / rows for an uniform spritesheet     
    Call Sprite_Sheet_Uniform_RGB(file_, 256, 5, 6)
        
    * Use this method to unfold sprite animation from Raster 24 bit image ideally (compatible with 
      32 bit image with per pixel transparency)
    * All the sprite are converted for a fast blit (24 bit) without alpha transparency channel
    * If the sprite sheet is an RGBA image with per pixel information, the final sprites will 
    be trimmed of 
      the alpha channel (all the sprite will be converted to 24bit for fast blit) 
    * An incorrect size_ value will most likely raise a ValueError. 
    * The animation might also be incorrect if the variable rows_ and columns_ are not correct
    * This method will raise an exception for 32 or 8 bit surface (sprite sheet) 
    
    :param file_: string; full path to the SpriteSheet such as "C:\\directory\\file"
    :param size_: integer; Size in pixels of a single sprite (ex 200 pixels for a 
    sprite size 200x200).  
    :param rows_: integer; number of rows 
    :param columns_: integer; number of columns 
    :return: Returns a python list containing all the sprites converted for fast 
    blit (pygame.convert())
    """
    if not pygame.display.get_init():
        raise ValueError("Display module has not been initialized")

    cdef str path_to_surface = os.path.join("", "", file_)

    if not os.path.isfile(path_to_surface):
        raise FileNotFoundError("No such file or directory: %s " % file_)

    cdef:
        unsigned int w, h
        int bitsize

    try:
        surface = pygame.image.load(path_to_surface)
        bitsize = surface.get_bitsize()
        w, h = surface.get_size()
        # buffer_ = surface.get_view('2')
        buffer_ = pygame.image.tobytes(surface, "RGB")
        array_ = numpy.frombuffer(buffer_, uint8).reshape(h, w, 3)
    except Exception as e:
        raise ValueError("Cannot load spritesheet %s.\n "
                         "Invalid file format or bitsize incompatible\nError %s\n"
                         "This version is compatible with 24-bit spritesheet without layer "
                         "alpha only" % (file_, e))

    cdef:
        # rgb_array is flipped (h x w)
        unsigned char [:, :, :] rgb_array = array_
        list sprite_animation = []
        int rows, columns
        int start_x, end_x, start_y, end_y;
        # rgb_array is flipped (h x w)
        int width = <object>array_.shape[1]
        int height =  <object>array_.shape[0]

    if size_ == 0:
        raise ValueError("\nArgument size_ cannot be zero!")
    if width / size_ != columns_ or height / size_ != rows_:
        raise ValueError("\nAt least one arguments such as rows_, columns_ or size_ is incorrect\n"
                         "Below a spritesheet size (1536x1280) containing 30 sprites (x)\n"
    "rows = 5, columns = 6 and size = 1536 / columns = 1280 / rows for an uniform spritesheet\n"
    " * x x x x x x\n   x x x x x x\n   x x x x x x\n   x x x x x x\n   x x x x x x \n\n "
    "Call Sprite_Sheet_Uniform_RGB(file_, 256, 5, 6)")

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
                # rgb_array is flipped (h x w)
                block_array = pixel_block_rgb(rgb_array, start_y, start_x, size_,
                                              size_, empty_array)
                with gil:
                    block_array_asarray = asarray(block_array)
                    sub_surface = frombuffer(
                        block_array_asarray.copy(order='C'), (size_, size_), 'RGB')
                    PyList_Append(sprite_animation, sub_surface.convert())
    return sprite_animation



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

        unsigned char [:, :, :] rgb_array = pixels3d(surface_)
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
                block_array = pixel_block_rgb(rgb_array, start_y, start_x, size_,
                                              size_, empty_array)
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
            block[x, y, <unsigned short int>0] = array_[xx, yy, <unsigned short int>0]
            block[x, y, <unsigned short int>1] = array_[xx, yy, <unsigned short int>1]
            block[x, y, <unsigned short int>2] = array_[xx, yy, <unsigned short int>2]
    return block

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef Sprite_Sheet_Uniform_RGBA(
        str file_, int size_, int rows_, int columns_):
    """
    VERSION 32 BIT
    TRANSFORM A *UNIFORM SPRITE SHEET INTO A PYTHON LIST CONTAINING ALL SPRITE ANIMATION
    UNIFORM : All sprites in the sprite sheet must have equivalent width and height 
    (square sprites)

    spritesheet (1536x1280) containing 30 sprites (x)
    rows = 5, columns = 6 and size = 1536 / columns = 1280 / rows for an uniform spritesheet 
    Call Sprite_Sheet_Uniform_RGBA(file_, 256, 5, 6)

    * Use this method to unfold sprite animation from Raster 32 bit image with layer alpha
    * All the sprite are converted for a fast blit (32 bit) with alpha transparency channel
    * Not compatible with RGB image without layer alpha 
    * An incorrect size_ value will most likely raise a ValueError. 
    * The animation might also be incorrect if the variable rows_ and columns_ are not correct
    * This method will raise an exception for 24 or 8 bit surface (sprite sheet) 

    :param file_: string; full path to the SpriteSheet such as "C:\\directory\\file"
    :param size_: integer; Size in pixels of a single sprite (ex 200 pixels for a sprite
     size 200x200).  
    :param rows_: integer; number of rows 
    :param columns_: integer; number of columns 
    :return: Returns a python list containing all the sprites converted for fast blit 
    (pygame.convert_alpha())
    """
    cdef int bitsize

    if not pygame.display.get_init():
        raise ValueError("Display module has not been initialized")

    path_to_surface = os.path.join("", "", file_)

    if os.path.isfile(path_to_surface):

        try:
            spritesheet = pygame.image.load(path_to_surface)
            bitsize = spritesheet.get_bitsize()

        except Exception as e:
            raise ValueError("Spritesheet is not a valid surface or not supported by "
                             "Pygame\nError %s" %e)

    else:
        raise FileNotFoundError("No such file or directory: %s " % file_)

    try:
        # pixel_buffer = spritesheet.get_view('2')
        pixel_buffer = pygame.image.tobytes(spritesheet, "RGBA")

    except Exception as e:
        raise ValueError("Cannot convert the file %s into a numpy 3d array\nError %s \n"
                         "Images encoded in 8 bit format are not compatible, actual image "
                         "format = %s bit" % (file_, e, bitsize))
    cdef int w, h
    w, h = spritesheet.get_size()

    try:
        array_ = numpy.frombuffer(pixel_buffer, dtype=uint8).reshape((h, w, 4))
    except Exception as e:
        raise ValueError("Spritesheet cannot be converted into a 3d numpy array "
                         "shape (h, w, 4) RGBA"
                         "\nThe spritesheet is most likely 24 without layer alpha or 8 bit, image "
                         "bitesize = %s " % bitsize)

    cdef:
        # rgba_array is flipped h x w
        unsigned char [:, :, :] rgba_array = array_
        list sprite_animation = []
        int rows, columns
        int start_x, end_x, start_y, end_y;
        int x=size_, y=size_
        int width=w, height=h

    if size_ == 0:
        raise ValueError("\nArgument size_ cannot be zero!")
    if width / size_ != columns_ or height / size_ != rows_:
        raise ValueError("\nAt least one arguments such as rows_, columns_ or size_ is incorrect\n"
                         "Below a spritesheet size (1536x1280) containing 30 sprites (x)\n"
    "rows = 5, columns = 6 and size = 1536 / columns = 1280 / rows for an uniform spritesheet\n" 
    " * x x x x x x\n   x x x x x x\n   x x x x x x\n   x x x x x x\n   x x x x x x \n\n "
    "Call Sprite_Sheet_Uniform_RGBA(file_, 256, 5, 6)")

    cdef:
        unsigned char [:, :, ::1] empty_array = empty((size_, size_, 4), uint8)
        unsigned char [:, :, ::1] block_array = empty((size_, size_, 4), uint8)

    with nogil:
        for rows in range(rows_):
            start_y = rows * size_
            end_y   = (rows + 1) * size_
            for columns in range(columns_):
                start_x = columns * size_
                end_x   = start_x + size_
                # start_y and start_x are swapped (rgba_array is flipped)
                block_array = pixel_block_rgba(rgba_array, start_y, start_x, x, y, empty_array)
                with gil:
                    block_array_asarray = asarray(block_array)
                    sub_surface = frombuffer(
                        block_array_asarray.copy(order='C'), (size_, size_), 'RGBA')
                    PyList_Append(sprite_animation, sub_surface.convert_alpha())
    return sprite_animation

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef inline unsigned char [:, :, ::1] pixel_block_rgba(
        unsigned char [:, :, :] array_, int start_x, int start_y,
        int w, int h, unsigned char [:, :, ::1] block) nogil:
    """
    EXTRACT A SPRITE FROM A SPRITE SHEET (SPRITE WITH PER PIXEL INFORMATION)

    * Method used by Sprite_Sheet_Uniform_RGBA in order to extract all the sprites 
    from the sprite sheet
    * This method returns a memoryview type [:, :, ::1] contiguous of unsigned char
     (sprite of size w x h)

    :param array_ : unsigned char; array of size w x h x 4 to parse into sub blocks
     (non contiguous)
    :param start_x: int; start of the block (x value) 
    :param start_y: int; start of the block (y value)
    :param w      : int; width of the block
    :param h      : int; height of the block
    :param block  : unsigned char; empty block of size w_n x h_n x 4 to fill up 
    :return       : Return 3d array of size (w_n x h_n x 4) of RGBA pixels 
    """

    cdef:
        int x, y, xx, yy

    for x in prange(w, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
        xx = start_x + x
        for y in prange(h, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            yy = start_y + y
            block[x, y, <unsigned short int>0] = array_[xx, yy, <unsigned short int>0]
            block[x, y, <unsigned short int>1] = array_[xx, yy, <unsigned short int>1]
            block[x, y, <unsigned short int>2] = array_[xx, yy, <unsigned short int>2]
            block[x, y, <unsigned short int>3] = array_[xx, yy, <unsigned short int>3]
    return block

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef sprite_sheet_fs8(str file_, int chunk_, int columns_,
                       int rows_, tweak_= False, args=None, color_=pygame.Color((0, 0, 0))):
    """
    VERSION 24 BIT 
    THIS METHOD TRANSFORM A UNIFORM OR NON UNIFORM SPRITESHEET INTO A PYTHON LIST
     
    * Method using numpy arrays.
    * Spritesheet may contain non uniform sprites e.g size 320x200
    * Return sprite animation and sprite transparency is set with colorkey
     (black color is full transparency)
      The flag RLEACCEL is added to the texture
    * set color_ to None if you do not wish to set a transparency colorkey

    :param file_   : str,  full path to the texture
    :param chunk_  : int, size of a single sprite in bytes e.g 64x64
    :param rows_   : int, number of rows
    :param columns_: int, number of columns
    :param tweak_  : bool, modify the chunk sizes (in bytes) in order to process
                     data with non equal width and height e.g 320x200
    :param args    : tuple, used with tweak_, args is a tuple containing the new chunk size,
                     e.g (320, 200)
    :param color_  : pygame Color to set the transparency with colorkey default black 
    :return: list, Return textures (surface) containing colorkey transparency
     (black color is full transparency)

    """
    if not pygame.display.get_init():
        raise ValueError("Display module has not been initialized")

    path_to_surface = os.path.join("", "", file_)

    if os.path.isfile(path_to_surface):

        try:
            spritesheet = pygame.image.load(path_to_surface)
            bitsize = spritesheet.get_bitsize()

        except Exception as e:
            raise ValueError("Spritesheet is not a valid surface or not supported"
                             " by Pygame\nError %s" %e)

    else:
        raise FileNotFoundError("No such file or directory: %s " % file_)

    cdef int width, height
    width, height = spritesheet.get_size()

    if width==0 or height==0:
        raise ValueError("Invalid spritesheet dimension, width or height cannot be null!")

    try:
        rgb_array_ = pixels3d(spritesheet)

    except (pygame.error, ValueError):
        try:
            rgb_array_ = pygame.surfarray.array3d(spritesheet)
        except (pygame.error, ValueError):
            raise ValueError('\nIncompatible pixel format.')

    cdef:
        np.ndarray[np.uint8_t, ndim=3] rgb_array = rgb_array_
        np.ndarray[np.uint8_t, ndim=3] array1    = empty((chunk_, chunk_, 3), dtype=uint8)
        int chunkx, chunky, rows = 0, columns = 0

    # modify the chunk size
    if tweak_ and args is not None:

        if PyObject_IsInstance(args, tuple):
            try:
                chunkx = args[0]
                chunky = args[1]
            except IndexError:
                raise IndexError('Parse argument not understood.')
            if chunkx==0 or chunky==0:
                raise ValueError('Chunkx and chunky cannot be equal to zero.')
            if (width % chunkx) != 0:
                raise ValueError('Chunkx size value is not a correct fraction of %s ' % width)
            if (height % chunky) != 0:
                raise ValueError('Chunky size value is not a correct fraction of %s ' % height)
        else:
            raise ValueError('Parse argument not understood.')
    else:
        chunkx, chunky = chunk_, chunk_

    cdef:
        list sprite_animation = []
        make_surface = pygame.pixelcopy.make_surface

    with nogil:
        for rows in prange(rows_, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for columns in range(columns_):
                with gil:

                    array1   = rgb_array[columns * chunkx:(columns + 1)
                        * chunkx, rows * chunky:(rows + 1) * chunky, :]
                    surface_ = make_surface(array1).convert()
                    if color_ is not None:
                        surface_.set_colorkey(color_, RLEACCEL)
                    PyList_Append(sprite_animation, surface_)

    return sprite_animation




@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef sprite_sheet_fs8_alpha(str file_, int chunk_, int columns_,
                       int rows_, tweak_= False, args=None):
    """
    VERSION 32 BIT 
    THIS METHOD TRANSFORM A UNIFORM OR NON UNIFORM SPRITESHEET INTO A PYTHON LIST

    * Method using numpy arrays.
    * Spritesheet may contain non uniform sprites e.g size 320x200
    * Return sprite animation and sprite with per-pixel transparency

    :param file_   : str,  full path to the texture
    :param chunk_  : int, size of a single sprite in bytes e.g 64x64
    :param rows_   : int, number of rows
    :param columns_: int, number of columns
    :param tweak_  : bool, modify the chunk sizes (in bytes) in order to process
                     data with non equal width and height e.g 320x200
    :param args    : tuple, used with tweak_, args is a tuple containing the new chunk size,
                     e.g (320, 200)
    :return: list, Return textures (surface) containing per-pixel alpha transparency)

    """
    if not pygame.display.get_init():
        raise ValueError("Display module has not been initialized")

    path_to_surface = os.path.join("", "", file_)

    if os.path.isfile(path_to_surface):

        try:
            spritesheet = pygame.image.load(path_to_surface)
            bitsize = spritesheet.get_bitsize()

        except Exception as e:
            raise ValueError("Spritesheet is not a valid surface or not supported"
                             " by Pygame\nError %s" % e)

    else:
        raise FileNotFoundError("No such file or directory: %s " % file_)

    cdef int width, height
    width, height = spritesheet.get_size()

    if width == 0 or height == 0:
        raise ValueError("Invalid spritesheet dimension, width or height cannot be null!")

    try:
        # pixel_buffer = spritesheet.get_view('2')
        pixel_buffer = pygame.image.tobytes(spritesheet, "RGBA")
        array_ = numpy.frombuffer(pixel_buffer, dtype=uint8).reshape((height, width, 4))
    except Exception as e:
        raise ValueError("Spritesheet cannot be converted into a 3d numpy array "
                         "shape (h, w, 4) RGBA"
                         "\nThe spritesheet is most likely 24 without layer alpha or 8 bit, image "
                         "bitesize = %s " % bitsize)

    cdef:
        np.ndarray[np.uint8_t, ndim=3] rgba_array = array_
        int chunkx, chunky, rows = 0, columns = 0

    # modify the chunk size
    if tweak_ and args is not None:

        if PyObject_IsInstance(args, tuple):
            try:
                chunkx = args[0]
                chunky = args[1]
            except IndexError:
                raise IndexError('Parse argument not understood.')
            if chunkx == 0 or chunky == 0:
                raise ValueError('Chunkx and chunky cannot be equal to zero.')
            if (width % chunkx) != 0:
                raise ValueError('Chunkx size value is not a correct fraction of %s ' % width)
            if (height % chunky) != 0:
                raise ValueError('Chunky size value is not a correct fraction of %s ' % height)
        else:
            raise ValueError('Parse argument not understood.')
    else:
        chunkx, chunky = chunk_, chunk_

    cdef:
        list sprite_animation = []

    with nogil:
        for columns in prange(columns_, schedule=SCHEDULE, num_threads=THREAD_NUMBER):
            for rows in range(rows_):
                with gil:
                    block_array = rgba_array[
                                  rows * chunky:(rows + 1) * chunky,
                                  columns * chunkx:(columns + 1) * chunkx, :]
                    sub_surface = frombuffer(block_array.copy(order='C'), (chunkx, chunky), 'RGBA')
                    PyList_Append(sprite_animation, sub_surface.convert_alpha())

    return sprite_animation