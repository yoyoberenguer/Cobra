# encoding: utf-8
import pygame
from Constants import GAMEPATH
import numpy
import multiprocessing
import threading
from multiprocessing import *
from multiprocessing import sharedctypes
import ctypes


# ------------------------------------------- INTERFACE --------------------------------------------------------------

def make_array(rgb_array_: numpy.ndarray, alpha_: numpy.ndarray) -> numpy.ndarray:
    """ This method is compatible with 32-bit or 24-bit surface only.
    Create a new 3d numpy array with RGBA values (concatenated from RGB array and
    alpha array."""
    pass


def make_surface(rgba_array: numpy.ndarray) -> pygame.Surface:
    """ Create a new surface from a 3d numpy array containing transparency values
    This function is use for 32-24 bit texture with pixel alphas transparency """
    pass


def mask_alpha(rgba_array: numpy.ndarray, alpha_: int) -> numpy.ndarray:
    """ mask_alpha(RGBA array, alpha int) -> RGBA array """
    pass


def create_solid_rgb_array(shape_: tuple, color_: (tuple, pygame.Color)) -> numpy.ndarray:
    """ Return a 3D numpy array (uint8) formed with a single pixel color
    (RGB colors only) with no transparency values. """
    pass


def create_solid_rgba_array(shape_: tuple, color_: (tuple, pygame.Color)) -> numpy.ndarray:
    """ Return a 3D numpy array (uint8) formed with a single color (RGB colors).
    The final array will hold a pixel transparency value given by color_ (tuple, pygame.Color RGBA) """
    pass


def surface_add_array(surface1: pygame.Surface, add_array: numpy.ndarray):
    """ Extract RGB array from a given surface and add another RGB array to it. """
    pass


def combine_texture_add_1(surface1: pygame.Surface, diff: numpy.ndarray):
    pass


def surface_subtract_array(surface: pygame.Surface, subtract_array: numpy.ndarray):
    pass


def add_color_to_rgba_array(surface_, color_: (pygame.Color, tuple)) -> numpy.ndarray:
    """ Blend a 3d RGBA array with RGBA pixel color
    This method is faster than add_color_to_array (the texture is passed as argument, and
    does not need to be converted into pixel3d array or pixel_alpha array. """
    pass


def add_color_to_array(rgb_array_: numpy.ndarray,
                       alpha_: numpy.ndarray, color_: (pygame.Color, tuple)) -> numpy.ndarray:
    """ Add a specific color to an entire array (RGB array) while keeping the original alpha values. """
    pass


def add_color_to_surface_alpha(surface_: pygame.Surface, color_: (tuple, pygame.Color)) -> pygame.Surface:
    """ Return a surface blended with a specific color.
    Texure transparency will be mixed with the pixel alpha transparency. """
    pass


def add_color_to_surface(surface_: pygame.Surface, color_: (tuple, pygame.Color), **kwargs) -> pygame.Surface:
    """ Add a specific color to a per-pixel alpha surface (keeping the original alpha values).
    Blending 32-bit depth texture will always be faster than blending 24-8 bit textures (referenced array). """
    pass


def subtract_color_from_rgba_array(surface_: pygame.Surface,
                                   color_: (pygame.Color, tuple)) -> numpy.ndarray:
    """ Return a 3d numpy array subtracted with a specific color (alpha values are also subtracted)"""
    pass


def subtract_color_from_array(rgb_array_: numpy.ndarray,
                              alpha_: numpy.ndarray, color_: (pygame.Color, tuple)) -> numpy.ndarray:
    """ Subtract a specific color from an entire array (RGB array) while keeping the original alpha values."""
    pass


def subtract_color_from_surface_alpha(surface_: pygame.Surface,
                                      color_: (tuple, pygame.Color)) -> pygame.Surface:
    """ Create a new surface subtracting original surface with a model (RGBA pixel color) """
    pass


def subtract_color_from_surface(surface_: pygame.Surface, color_: (tuple, pygame.Color)):
    """ Subtract a specific color from a per-pixel alpha surface (keeping the original alpha values)."""
    pass


def diff_from_array(source_array: numpy.ndarray, color_: pygame.Color, interval_: float) -> numpy.ndarray:
    """ Calculate the amount of color the source array needs to lerp to for a given interval. """
    pass


def diff_from_array_alpha(source_array: numpy.ndarray, color_: pygame.Color, interval_: float) -> numpy.ndarray:
    """ Calculate the amount of color the source array needs to lerp to for a given interval. """
    pass


def diff_from_surface(surface_, color_, interval_):
    pass


def blend_texture_alpha(surface_: pygame.Surface, interval_: (int, float),
                        color_: (pygame.Color, tuple)) -> pygame.Surface:
    """ Compatible with 32-bit pixel alphas texture.
    Blend two colors together to produce a third color.
    Alpha channel of the source image will be blended with the pixel transparency color_
    This method is slightly faster than blend_texture_24bit and blend_texture """
    pass


def blend_texture_24bit(surface_: pygame.Surface, interval_: (int, float),
                        color_: (pygame.Color, tuple),
                        colorkey: pygame.Color = (0, 0, 0, 0)) -> pygame.Surface:
    """ Compatible with 32 and 24 bit even though it is no convenient to use that method for 32 bit surface with
    per-pixels transparency (prefer the classic method blend_texture for 32bit).
    This method is slightly slower than blend_texture.
    It is used for 24bit surface with alpha transparency controlled by keycolor.
    All black pixel will remain unchanged while the rest of the pixels will blend with a new color.
    This method return a new surface with transparency set to colorkey. """
    pass


def blend_texture(surface_: pygame.Surface, interval_: (int, float),
                  color_: (pygame.Color, tuple)) -> pygame.Surface:
    """
    Compatible with 32-24 bit pixel alphas texture.
    Blend two colors together to produce a third color.
    Alpha channel of the source image will be transfer to the destination surface (no alteration
    of the alpha channel) """
    pass


def green_mask_alpha(surface_: pygame.Surface, threshold_: int, alpha_value: int) -> pygame.Surface:
    """ Change alpha values for all green pixels (except green pixels with value above color threshold). """
    pass


def red_mask_alpha(surface_: pygame.Surface, threshold_: int, alpha_value: int) -> pygame.Surface:
    """ Change alpha values for all red pixels (except red pixels with value above color threshold). """
    pass


def blue_mask_alpha(surface_: pygame.Surface, threshold_: int, alpha_value: int) -> pygame.Surface:
    """ Change alpha values for all blue pixels (except blue pixels with value above color threshold). """
    pass


def black_blanket_surface(surface_: pygame.Surface, new_alpha_: int, threshold_: int) -> pygame.Surface:
    """
    Force all colors (R+G+B) under a certain value (threshold) to be transparent or partially
    transparent (depends on new_alpha).
    This method is equivalent to black_blanket but twice as fast """
    pass


def black_blanket(rgb_array: numpy.ndarray, alpha_array: numpy.ndarray, new_alpha: int,
                  threshold: int) -> pygame.Surface:
    """ Force all colors (R+G+B) under a certain value (threshold) to be transparent or partially
    transparent (depends on new_alpha). """
    pass


def add_transparency_all(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    Increase transparency of a surface
    This method is equivalent to pygame.Surface.set_alpha() but conserve the per-pixel properties of a texture
    All pixels will be update with a new transparency value.
    If you need to increase transparency on visible pixels only, prefer the method add_transparency instead. """
    pass


def add_transparency(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    This method increase transparency of per-pixel texture updating only pixels with alpha values > 0
    Transparent pixels (with alpha value =0) will remain unchanged (unlike  add_transparency_all
    that will change all alpha values). """
    pass


def blink_surface(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    Create a blinking effect by altering all alpha values (subtracting alpha channel by an amount)
    without restricting the data between 0 - 255. (e.g alpha 10 - 25 ->  new alpha value 240 not 0)
    """
    pass


def sub_transparency(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    This method decrease transparency of per-pixel texture updating only pixels with alpha values > 0
    Transparent pixels (with alpha value =0) will remain unchanged. """
    pass


def sub_transparency_all(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    This method decrease transparency of a surface by subtracting the current alpha value of all pixels by
    a specific value passed as an argument (value).
    Return the a new surface with alpha transparency changed. """
    pass


# ---------------------------------------------------------------------------------------------------------------------

class ERROR(BaseException):
    pass


def color_check(color_: (tuple, pygame.Color)) -> pygame.Color:
    """
    Convert a color tuple into a pygame.Color value
    :param color_: tuple representing RGB or RGBA color values e.g WHITE (255,255,255) or (255,255,255,255)
                   if the color tuple has no alpha value, then full opacity will be given (255).
                   No change if color_ is a pygame.Color
    :return: pygame.Color class (RGBA) e.g (128,128,128,128)
    :rtype: pygame.Color

    >>> color_check(pygame.Color(255,0,0))
    (255, 0, 0, 255)
    >>> color_check(pygame.Color(255, 0, 0, 0))
    (255, 0, 0, 0)
    >>> color_check((255,0,0,0))
    (255, 0, 0, 0)
    >>> color_check((255, 0, 0))
    (255, 0, 0, 255)
    """
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting a tuple or pygame.Color got, %s ' % type(color_)
    if isinstance(color_, tuple):
        try:
            color_ = pygame.Color(*color_)
            return color_
        except ValueError:
            raise ERROR('\n[-]color_check error : Invalid color argument.')
    else:
        return color_


def make_array(rgb_array_: numpy.ndarray, alpha_: numpy.ndarray) -> numpy.ndarray:
    """
    This function is use for 32-24 bit texture with pixel alphas transparency

    make_array(RGB array, alpha array) -> RGBA array

    Return a 3D numpy array representing (R, G, B, A) values of a pixel alphas texture (numpy.uint8).
    Argument surface_ is a pixels3d containing RGB values and alpha is a 2D pixels_alpha array.

    :param rgb_array_: 3D numpy array created with pygame.surfarray_pixels3d() representing the
                       RGB values of the pixel alphas texture.
    :param alpha_:     2D numpy array created with pygame.surfarray.pixels_alpha() representing
                       the alpha pixels texture layer
    :return:           Return a numpy 3D array (numpy.uint8) storing a transparency value for every pixel
                       This allow the most precise transparency effects, but it is also the slowest.
                       Per pixel alphas cannot be mixed with surface alpha colorkeys (this will have
                       no effect).
    """
    assert isinstance(rgb_array_, numpy.ndarray), \
        'Expecting numpy.ndarray for argument rgb_array_ got %s ' % type(rgb_array_)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray for argument alpha_ got %s ' % type(alpha_)

    return numpy.dstack((rgb_array_, alpha_)).astype(dtype=numpy.uint8)


def make_surface(rgba_array: numpy.ndarray) -> pygame.Surface:
    """
    This function is use for 32-24 bit texture with pixel alphas transparency only

    make_surface(RGBA array) -> Surface

    Return a Surface created with the method frombuffer
    Argument rgba_array is a numpy array containing RGB values + alpha channel.
    This method create a texture with per-pixel alpha values.
    'frombuffer' can display image with disproportional scaling (X&Y scale),
    but the image will be distorted. Use array = original_array.copy(order='C') to
    force frombuffer to accept disproportional image.
    Another method is to scale the original image with irregular X&Y values
    before processing the image with frombuffer (therefore this could create
    undesirable effect in sprite animation, sprite deformation etc).

    :param rgba_array: 3D numpy array created with the method surface.make_array.
                       Combine RGB values and alpha values.
    :return:           Return a pixels alpha texture.This texture contains a transparency value
                       for each pixels.
    """
    assert rgba_array.shape[:2][0] != 0, 'ValueError: Resolution must be positive values '
    assert rgba_array.shape[:2][1] != 0, 'ValueError: Resolution must be positive values '

    assert isinstance(rgba_array, numpy.ndarray), 'Expecting numpy.ndarray for ' \
                                                  'argument rgb_array got %s ' % type(rgba_array)
    return pygame.image.frombuffer((rgba_array.transpose(1, 0, 2)).copy(order='C').astype(numpy.uint8),
                                   (rgba_array.shape[:2][0], rgba_array.shape[:2][1]), 'RGBA')


def mask_alpha(rgba_array: numpy.ndarray, alpha_: int) -> numpy.ndarray:
    """
    mask_alpha(RGBA array, alpha int) -> RGBA array

    Function for changing alpha values of a per-pixels alpha texture 32-24 bit.
    change alpha values for all pixels, except fully transparent pixels.
    fully transparent pixels are often borders or frames. Partially changing
    alpha values will obscure the background and create an undesirable border
    or frame effect in the sprite animation.
    :param rgba_array: RGBA 3D numpy array created with the method surface.make_array or
                       pygame.surfarray.pixels3d.
    :param alpha_: swap array transparency values with alpha_ if transparency pixel > 0
    :return: RGBA array with transparency adjusted (transparent pixel > 0 = alpha_)
    """
    assert isinstance(rgba_array, numpy.ndarray), 'Expecting numpy.ndarray for ' \
                                                  'argument rgba_array got %s ' % type(rgba_array)
    assert isinstance(alpha_, int), 'Expecting int for argument alpha_ got %s ' % type(alpha_)
    assert rgba_array.shape[2] > 3, \
        'Expecting RGBA (%s,%s,4) array, got shape %s ' \
        % (str(rgba_array.shape[0]), str(rgba_array.shape[1]), str(rgba_array.shape))

    # check if the value given for alpha is between 0 and 255
    if not (0 <= alpha_ <= 256):
        raise ERROR(f'\n[-] invalid value for argument alpha_, should be between[0, 255], got {alpha_} ')

    # update alpha value with new alpha_ if alpha>0
    # change alpha values for all pixels, except fully transparent pixels.
    # numpy.putmask is faster than numpy.place
    numpy.putmask(rgba_array[:, :, 3], rgba_array[:, :, 3] > 0, alpha_)
    return rgba_array.astype(numpy.uint8)


def create_solid_rgb_array(shape_: tuple, color_: (tuple, pygame.Color)) -> numpy.ndarray:
    """
    Return a 3D numpy array (uint8) formed with a single pixel color
    (RGB colors only) with no transparency values.

    create_solid_rgb_array((100,100,3), (255,255,255)) -> array

    :param color_: Color can be a tuple or a pygame.Color class
                 : a tuple will be converted to a pygame.Color class
    :param shape_: Shape of the final array (destination array)
    :return: 3D numpy array (uint8) formed with a single pixel color (RGB colors only), no
             transparency values (equivalent to pygame.surfarray.array3d array)
    """
    # The Color class represents RGBA color values using a value range of 0-255
    # Alpha defaults to 255 when not given.
    assert isinstance(shape_, tuple), \
        'Expecting a list for argument shape_ got %s ' % type(shape_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting pygame.Color or tuple for argument color_ got %s ' % type(color_)

    color_check(color_)

    if len(shape_) > 2:
        assert shape_[2] < 4, \
            'Expecting 3d numpy array RGB (without transparency values), got shape %s ' % str(shape_)
    else:
        raise ERROR('Expecting 3d numpy array RGB with shapes (row, column, colors), got shape %s ' % str(shape_))
    # color_[:3] only RGB colors are passed onto the final array, no transparency values
    # numpy.full_like is faster than numpy.full
    return numpy.full(shape_, color_[:3], dtype=numpy.uint8)


def create_solid_rgba_array(shape_: tuple, color_: (tuple, pygame.Color)) -> numpy.ndarray:
    """
    Return a 3D numpy array (uint8) formed with a single color (RGB colors).
    The final array will hold a pixel transparency value given by color_ (tuple, pygame.Color RGBA)

    create_solid_rgba_array((100,100,4), (255,255,255)) -> array

    :param color_: Color can be a tuple or a pygame.Color class
                 : a tuple will be converted to a pygame.Color class
    :param shape_: Shape of the final array (destination array)
    :return: 3D numpy array (uint8) formed with a single pixel color (RGBA values)
    """
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting pygame.Color or tuple for argument color_ got %s ' % type(color_)
    assert isinstance(shape_, tuple), \
        'Expecting a tuple for argument shape_ got %s ' % type(shape_)

    color_ = color_check(color_)

    if len(shape_) > 2:
        assert shape_[2] > 3, \
            'Expecting 3d numpy array RGBA, got shape %s ' % str(shape_)
    else:
        raise ERROR('Expecting 3d numpy array RGB with shapes (row, column, colors), got shape %s ' % str(shape_))

    return numpy.full(shape_, color_, dtype=numpy.uint8)


def surface_add_array(surface1: pygame.Surface, add_array: numpy.ndarray):
    """
    Extract RGB array from a given surface and add another RGB array to it.
    :param surface1: Surface
    :param add_array: numpy.ndarray with RGB values
    :return: New surface with added RGB values and transparency values untouched
    """
    assert isinstance(surface1, pygame.Surface), \
        'Expecting Surface got %s ' % type(surface1)
    assert isinstance(add_array, numpy.ndarray), \
        'Expecting numpy.ndarray for argument diff got %s ' % type(add_array)

    # todo : this can be faster with array = surface.get_view() instead
    # todo : surface_ = numpy.frombuffer(array, dtype=numpy.uint8)

    # todo implement checks for 32 - 24 bit surface
    source_array = pygame.surfarray.pixels3d(surface1)
    alpha_channel = pygame.surfarray.pixels_alpha(surface1)

    add_ = numpy.add(source_array, add_array)
    numpy.putmask(add_, add_ > 255, 255)
    rgba_array = make_array(add_, alpha_channel)

    return make_surface(rgba_array)


def combine_texture_add_1(surface1: pygame.Surface, diff: numpy.ndarray):
    layer = pygame.Surface((surface1.get_width(), surface1.get_height()), flags=pygame.SRCALPHA)
    pygame.surfarray.blit_array(layer, diff)
    layer.blit(surface1, (0, 0), special_flags=pygame.BLEND_RGBA_MIN)
    return layer


def surface_subtract_array(surface: pygame.Surface, subtract_array: numpy.ndarray):
    assert isinstance(surface, pygame.Surface), \
        'Expecting Surface got %s ' % type(surface)
    assert isinstance(subtract_array, numpy.ndarray), \
        'Expecting tuple for argument color_ got %s ' % type(subtract_array)
    # todo : this can be faster with array = surface.get_view() instead
    # todo : surface_ = numpy.frombuffer(array, dtype=numpy.uint8)
    # todo implement checks for 32 - 24 bit surface
    source_array = pygame.surfarray.pixels3d(surface)
    alpha_channel = pygame.surfarray.pixels_alpha(surface)
    sub_ = numpy.subtract(source_array, subtract_array)
    numpy.putmask(sub_, sub_ < 0, 0)
    rgba_array = make_array(sub_, alpha_channel)

    return make_surface(rgba_array)


def add_color_to_rgba_array(surface_, color_: (pygame.Color, tuple)) -> numpy.ndarray:
    """
    Blend a 3d RGBA array with RGBA pixel color
    This method is faster than add_color_to_array (the texture is passed as argument, and
    does not need to be converted into pixel3d array or pixel_alpha array.

    :param surface_: Texture used for retrieving RGBA array structure
    :param color_: Pixel color to use to compose a solid 3d RGBA array
    :return: Return a 3d RGBA array representing a new texture (added to a RGBA pixel color)
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting pygame.Surface for argument surface, got %s ' % type(surface_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting pygame.Color or tuple for argument color_ got %s ' % type(color_)
    # image sizes
    w, h = surface_.get_width(), surface_.get_height()
    # Convert the tuple into a pygame.Color class
    color_ = color_check(color_)
    # create RGBA array with a single pixel (with alpha value)
    array_color = create_solid_rgba_array((w, h, 4), color_).astype(numpy.uint16)
    # create a bufferproxy of the surface
    buffer_ = surface_.get_view('2')
    # convert a buffer into a 3d numpy array (with transparency color)
    source_array = numpy.frombuffer(buffer_, dtype=numpy.uint8).reshape((w, h, 4))
    # add solid RGBA color array(from color_ pixel) to RGBA array (texture).
    new_array_ = numpy.add(source_array.astype(numpy.uint16), array_color)
    # cap all the values over 255
    numpy.putmask(new_array_, new_array_ > 255, 255)
    return new_array_.transpose(1, 0, 2)


def add_color_to_array(rgb_array_: numpy.ndarray,
                       alpha_: numpy.ndarray, color_: (pygame.Color, tuple)) -> numpy.ndarray:
    """
    Add a specific color to an entire array (RGB array) while keeping the original alpha values.
    :param rgb_array_: RGB array (source array)
    :param alpha_: Original alpha values, these values will remain the same.
    :param color_: tuple or pygame.Color class representing the color to add
    :return: Return a RGBA array blended with a specific color (alpha values unchanged).
    """

    assert isinstance(rgb_array_, numpy.ndarray), \
        'Expecting numpy array got %s ' % type(rgb_array_)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy array for argument alpha_ got %s ' % type(alpha_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)

    # Convert the tuple into a pygame.Color class
    color_ = color_check(color_)

    # Create a RGB array (color_[:3]) formed with a single color with shapes identical
    # to the source RGB array.
    array_color = create_solid_rgb_array(rgb_array_.shape, color_).astype(numpy.uint16)
    # slowest method : array_color = numpy.full_like(rgb_array_.shape, color_[:3])

    # return a new RGBA array with added color.
    # Alpha values are given by color_ and should be replaced by alpha_ in the final step
    # by invoking make_array
    new_array_ = numpy.add(rgb_array_.astype(numpy.uint16), array_color)

    # place a limit at 255 (capping values)
    numpy.putmask(new_array_, new_array_ > 255, 255)

    # Create an RGBA array and return the result
    # Replacing all alpha values with original ones (alpha_)
    return make_array(new_array_, alpha_)


def add_color_to_surface_alpha(surface_: pygame.Surface, color_: (tuple, pygame.Color)) -> pygame.Surface:
    """
    Return a surface blended with a specific color.
    Texure transparency will be mixed with the pixel alpha transparency.

    This method is slightly faster than add_color_to_surface and
    buffer creation speed will stay the same for any type of textures (32, 24, 8 bit).
    get_view BufferProxy is faster than the set pixels3d(24 -32) and pixels_alpha(32) used for referencing pixels for
    32-24 bits texture, and much faster than array3d, array_alpha (copy of pixels).

    :param surface_: Pygame.Surface
    :param color_: pygame.Color or tuple representing a color to blend with the texture(surface)
    :return: return a 32-24 bit texture blended with the pixel color (color_).
            The final transparency will be mixed with the pixel alpha channel.
    """

    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface got %s ' % type(surface_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)

    # Convert the tuple into a pygame.Color class (RGBA)
    # default transparency is 255
    color_ = color_check(color_)

    # BufferProxy of the surface
    source_array = numpy.frombuffer(surface_.get_view(), dtype=numpy.uint8)
    # Reshape the BufferProxy into a 3d array RGBA and swap row and column
    source_array = source_array.reshape((surface_.get_width(), surface_.get_height(), 4))

    # Create a RGBA array
    array_color = create_solid_rgba_array(source_array.shape, color_)

    # return a new RGBA array with added color.
    # Note: alpha values are mixed with the color
    new_array_ = numpy.add(source_array, array_color, dtype=numpy.uint16)

    # place a limit at 255 (capping values)
    numpy.putmask(new_array_, new_array_ > 255, 255)

    # return a new texture (RGBA) with added color.
    return pygame.image.frombuffer(new_array_.copy(order='C').astype(numpy.uint8),
                                   (surface_.get_width(), surface_.get_height()), 'RGBA')


def add_color_to_surface(surface_: pygame.Surface, color_: (tuple, pygame.Color), **kwargs) -> pygame.Surface:
    """
    Add a specific color to a per-pixel alpha surface (keeping the original alpha values).

    Blending 32-bit depth texture will always be faster than blending 24-8 bit textures (referenced array).

    :param surface_:  Pygame.Surface, surface with per pixel alpha transparency
    :param color_: tuple or pygame.Color class
    :return:  Return a new surface blended with a specific color
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface got %s ' % type(surface_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)

    # Convert the tuple into a pygame.Color class
    # default alpha transparency is 255
    color_ = color_check(color_)

    # check if arrays are already build
    # and passed as argument.
    if kwargs:
        try:
            source_array = numpy.array(kwargs['source_array'])
            alpha_channel = numpy.array(kwargs['alpha_channel'])
        except Exception:
            raise ERROR('\n[-]add_color_to_surface error : Incorrect values for kwargs')
    else:
        # creating arrays for texture
        if surface_.get_bitsize() is 32:
            # 32 bit texture used referenced array (faster)
            source_array = pygame.surfarray.pixels3d(surface_)
            alpha_channel = pygame.surfarray.pixels_alpha(surface_)
        elif surface_.get_bitsize() in (24, 8):
            # copy of pixels (slower)
            source_array = pygame.surfarray.array3d(surface_)
            alpha_channel = pygame.surfarray.array_alpha(surface_)
        else:
            raise ERROR('\n[-] Expecting 32-24 bit depth surface, got %s ' % surface_.get_bitsize())

    # Create a RGB array (color_[:3]) formed with a single color with shapes identical
    # to the original surface.
    # Alpha values are ignore
    array_color = create_solid_rgb_array(source_array.shape, color_).astype(numpy.uint16)

    # return a new RGBA array with added color.
    # Note that the alpha values are taken from color_ and should be replaced in
    # the final step by invoking make_array
    new_array_ = numpy.add(source_array.astype(numpy.uint16), array_color)

    # place a limit at 255 (capping values)
    numpy.putmask(new_array_, new_array_ > 255, 255)

    # return a new array (RGBA) with added color.
    # Alpha values are replaced by the originals.
    rgba_array = make_array(new_array_.astype(numpy.uint8), alpha_channel)

    return make_surface(rgba_array)


def subtract_color_from_rgba_array(surface_: pygame.Surface,
                                   color_: (pygame.Color, tuple)) -> numpy.ndarray:
    """
    Return a 3d numpy array subtracted with a specific color (alpha values are also subtracted)
    :param surface_: Surface used to extract RGBA array
    :param color_: color used for array subtraction
    :return: return a 3d numpy array subtracted with a pixel color (alpha channel subtracted)
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting pygame.Surface for argument surface_, got %s ' % type(surface_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting pygame.Color or tuplefor for argument color_, got %s ' % type(color_)
    # image sizes
    w, h = surface_.get_width(), surface_.get_height()
    # Convert the tuple into a pygame.Color class
    color_ = color_check(color_)
    # create RGBA array with a single pixel (with alpha value)
    array_color = create_solid_rgba_array((w, h, 4), color_).astype(numpy.uint16)
    # create a bufferproxy of the surface
    buffer_ = surface_.get_view('2')
    # convert a buffer into a 3d numpy array (with transparency color)
    source_array = numpy.frombuffer(buffer_, dtype=numpy.uint8).reshape((w, h, 4))
    # subtract source_array with array_color
    new_array_ = numpy.subtract(source_array, array_color, dtype=numpy.int16)
    # cap all the values over 255
    numpy.putmask(new_array_, new_array_ < 0, 0)
    return new_array_.transpose(1, 0, 2)


def subtract_color_from_array(rgb_array_: numpy.ndarray,
                              alpha_: numpy.ndarray, color_: (pygame.Color, tuple)) -> numpy.ndarray:
    """
    Subtract a specific color from an entire array (RGB array) while keeping the original alpha values.
    :param rgb_array_: RGB array (source array)
    :param alpha_: Original alpha values, these values will remain the same.
    :param color_: tuple or pygame.Color class representing the color to add
    :return: Return the source array subtracted from a specific color (alpha values unchanged).
    """

    assert isinstance(rgb_array_, numpy.ndarray), \
        'Expecting numpy array got %s ' % type(rgb_array_)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy array for argument alpha_ got %s ' % type(alpha_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)

    # Convert the tuple into a pygame.Color class
    color_ = color_check(color_)

    # Create a RGB array (color_[:3]) formed with a single color with shapes identical
    # to the source RGB array.
    array_color = create_solid_rgb_array(rgb_array_.shape, color_)
    # slowest method : array_color = numpy.full_like(rgb_array_.shape, color_[:3])

    # return a new RGBA array with subtracted color.
    # Note the alpha values have to be replaced by invoking new_array
    new_array_ = numpy.subtract(rgb_array_, array_color, dtype=numpy.int16)

    # place a limit for value < 0 (capping values)
    numpy.putmask(new_array_, new_array_ < 0, 0)

    # Alpha values are replaced by the original ones
    return make_array(new_array_.astype(numpy.uint8), alpha_)


def subtract_color_from_surface_alpha(surface_: pygame.Surface,
                                      color_: (tuple, pygame.Color)) -> pygame.Surface:
    """
    Create a new surface subtracting original surface with a model (RGBA pixel color)
    :param surface_: Surface to use for subtracting pixel color array
    :param color_:  pixel color used for building a 3d array
    :return: return a new surface with pixels and alpha transparency subtracted from a model (RGBA pixel color)
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting pygame.Surface for argument surface_, got %s ' % type(surface_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)

    # Convert the tuple into a pygame.Color class
    color_ = color_check(color_)

    w, h = surface_.get_width(), surface_.get_height()
    buffer_ = surface_.get_view('2')
    # create a 3d numpy array (RGBA)
    source_array = numpy.frombuffer(buffer_, dtype=numpy.uint8).reshape((w, h, 4))

    # create RGBA array with a single pixel (with alpha value)
    array_color = create_solid_rgba_array((w, h, 4), color_).astype(numpy.uint16)

    # return a new RGBA array with subtracted color.
    new_array_ = numpy.subtract(source_array, array_color, dtype=numpy.int16)
    numpy.putmask(new_array_, new_array_ < 0, 0)

    # return a new surface
    return pygame.image.frombuffer(new_array_.copy(order='C').astype(numpy.uint8),
                                   (surface_.get_width(), surface_.get_height()), 'RGBA')


def subtract_color_from_surface(surface_: pygame.Surface, color_: (tuple, pygame.Color)) -> pygame.Surface:
    """
    Subtract a specific color from a per-pixel alpha surface (keeping the original alpha values).
    :param surface_:  Pygame.Surface, surface with per pixel alpha transparency
    :param color_: tuple or pygame.Color class
    :return:  Return the source surface subtracted from a specific color (alpha values unchanged).
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting pygame.Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)

    # Convert the tuple into a pygame.Color class
    color_ = color_check(color_)

    if surface_.get_bitsize() is 32:
        # 32 bit texture used referenced array (faster)
        source_array = pygame.surfarray.pixels3d(surface_)
        alpha_channel = pygame.surfarray.pixels_alpha(surface_)
    elif surface_.get_bitsize() in (24, 8):
        # copy of pixels (slower)
        source_array = pygame.surfarray.array3d(surface_)
        alpha_channel = pygame.surfarray.array_alpha(surface_)
    else:
        raise ERROR('\n[-] Expecting 32-24 bit depth surface, got %s ' % surface_.get_bitsize())

    # Create a RGB array (color_[:3]) formed with a single color with shapes identical
    # to the original surface. Alpha values ignore
    array_color = create_solid_rgb_array(source_array.shape, color_).astype(numpy.uint8)

    # return a new RGBA array with subtracted color.
    # Note alpha values have to be replaced by the original ones later
    new_array_ = numpy.subtract(source_array, array_color, dtype=numpy.int16)
    numpy.putmask(new_array_, new_array_ < 0, 0)

    # Create a new array (RGBA)
    # Alpha values are unchanged.
    rgba_array = make_array(new_array_.astype(numpy.uint8), alpha_channel)

    # Replacing alpha values by the original ones
    return make_surface(rgba_array)


def diff_from_array(source_array: numpy.ndarray, color_: pygame.Color, interval_: float) -> numpy.ndarray:
    """
    Calculate the amount of color the source array needs to lerp to for a given interval.
    :param source_array: Source array (RGB array)
    :param color_: color to lerp to
    :param interval_: given interval for lerping calculation
    :return: 3d numpy array with no transparency values (RGB array)
    """
    # model = numpy.full(source_array.shape, color_[:3])
    # numpy.subtract(model, source_array)
    # return numpy.multiply(model,  interval_)
    return (numpy.full_like(source_array.shape, color_[:3]) - source_array) * interval_


def diff_from_array_alpha(source_array: numpy.ndarray, color_: pygame.Color, interval_: float) -> numpy.ndarray:
    """
    Calculate the amount of color the source array needs to lerp to for a given interval.
    :param source_array: Source array (RGBA array with transparency channel)
    :param color_: pixel color RGBA
    :param interval_: lerp factor
    :return: a 3d numpy array (RGBA) with alpha channel
    """
    return (numpy.full_like(range(len(color_)), color_[:4]) - source_array) * interval_


def diff_from_surface(surface_, color_, interval_):
    # todo need to create docstring
    source_array = pygame.surfarray.pixels3d(surface_)
    diff_array = ((numpy.full_like(source_array.shape, color_[:3]) - source_array) * interval_)
    return diff_array


def blend_texture_alpha(surface_: pygame.Surface, interval_: (int, float),
                        color_: (pygame.Color, tuple)) -> pygame.Surface:
    """
    Compatible with 32-bit pixel alphas texture.
    Blend two colors together to produce a third color.
    Alpha channel of the source image will be blended with the pixel transparency color_
    This method is slightly faster than blend_texture_24bit and blend_texture

    :param surface_: pygame surface
    :param interval_: number of steps or intervals, int value
    :param color_: Destination color. Can be a pygame.Color or a tuple
    :return: return a pygame.surface supporting per-pixels transparency only if the surface passed
                    as an argument has been created with convert_alpha() method
    """

    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(interval_, (int, float)), \
        'Expecting float for argument interval_ got %s ' % type(interval_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)
    w, h = surface_.get_width(), surface_.get_height()
    # todo need to implement some test for 24bit texture (without transparency)
    # return the buffer.view (Bufferproxy)
    buffer_ = surface_.get_view('2')
    # create 1d numpy array from buffer
    array_ = numpy.frombuffer(buffer_, dtype=numpy.uint8)
    # convert 1d array into 3d array, swap row and column to adjust the surface
    array_ = array_.reshape((w, h, 4))
    new_array_ = numpy.add(array_, diff_from_array_alpha(array_, color_, interval_))
    # cap the values to 255
    numpy.putmask(new_array_, new_array_ > 255, 255)

    return pygame.image.frombuffer(new_array_.copy(order='C').astype(numpy.uint8),
                                   (w, h), 'RGBA')


def blend_texture_24bit(surface_: pygame.Surface, interval_: (int, float),
                        color_: (pygame.Color, tuple), colorkey: pygame.Color = (0, 0, 0, 0)) -> pygame.Surface:
    """
    Compatible with 32 and 24 bit even though it is no convenient to use that method for 32 bit surface with
    per-pixels transparency (prefer the classic method blend_texture for 32bit).
    This method is slightly slower than blend_texture.
    It is used for 24bit surface with alpha transparency controlled by keycolor.
    All black pixel will remain unchanged while the rest of the pixels will blend with a new color.
    This method return a new surface with transparency set to colorkey.
    :param surface_: Texture 32-24 bit
    :param interval_:
    :param color_: color to blend with the texture
    :param colorkey: transparent pixel
    :return: return a surface with transparency controlled via a keycolor
    """

    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(interval_, (int, float)), \
        'Expecting float for argument interval_ got %s ' % type(interval_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)
    assert isinstance(colorkey, (pygame.Color, tuple)), \
        'Expecting tuple for argument colorkey got %s ' % type(colorkey)

    if surface_.get_bitsize() in (32, 24):
        source_array = pygame.surfarray.pixels3d(surface_)
    else:
        raise ERROR('\n[-] Method blend_texture_24bit works only for 24-32 bit surface.')

    # create a mask for all black pixels
    mask = (source_array == 0)
    # create an array build with a specific color
    diff_array = diff_from_array(source_array, color_, interval_)
    # add color to the texture (color RGB without transparency values, alpha channel ignored)
    new_array = numpy.add(source_array.astype(numpy.uint8), diff_array.astype(numpy.uint8))
    # all black pixel stays black
    new_array[mask] = numpy.zeros(source_array.shape)[mask]
    # blit array directly into the surface (array RGB without the alpha values)
    # array with alpha values will produce an error code.
    # new_surface = pygame.Surface((surface_.get_width(), surface_.get_height()), 24)
    pygame.surfarray.blit_array(surface_, new_array)
    # set pixels transparency with a specific color
    surface_.set_colorkey(colorkey)

    return surface_.convert()


def blend_texture(surface_: pygame.Surface, interval_: (int, float), color_: (pygame.Color, tuple)) -> pygame.Surface:
    """
    Compatible with 32-24 bit pixel alphas texture.
    Blend two colors together to produce a third color.
    Alpha channel of the source image will be transfer to the destination surface (no alteration
    of the alpha channel)

    :param surface_: pygame surface
    :param interval_: number of steps or intervals, int value
    :param color_: Destination color. Can be a pygame.Color or a tuple
    :return: return a pygame.surface supporting per-pixels transparency only if the surface passed
                    as an argument has been created with convert_alpha() method.
                    Pixel transparency of the source array will be unchanged.
    """

    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(interval_, (int, float)), \
        'Expecting float for argument interval_ got %s ' % type(interval_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)

    # Get all the pixels into a 3d numpy array
    source_array = pygame.surfarray.pixels3d(surface_)
    # get the alpha channel transparency into a 2d numpy array
    if surface_.get_bitsize() == 32:
        # pixels_alpha works only for 32bit
        alpha_channel = pygame.surfarray.pixels_alpha(surface_)
    elif surface_.get_bitsize() == 24:
        alpha_channel = pygame.surfarray.array_alpha(surface_)
    else:
        raise ERROR('\n[-] Method blend_texure works only for 24-32 bit surface.')

    # blend texture with a given color (Texture transparency will remains unchanged)
    # pixel color_ transparency is ignored.
    rgba_array = make_array(numpy.add(source_array,
                                      diff_from_array(source_array, color_, interval_)), alpha_channel)
    return make_surface(rgba_array)


def green_mask_alpha(surface_: pygame.Surface, threshold_: int, alpha_value: int) -> pygame.Surface:
    """
    Change alpha values for all green pixels (except green pixels with value above color threshold).
    :param surface_: 32-bit Surface
    :param threshold_: integer representing the threshold.
    :param alpha_value: new alpha value
    :return: pygame.Surface
    """

    assert isinstance(alpha_value, int), \
        'Expecting int for argument alpha_value got %s ' % type(alpha_value)
    assert isinstance(threshold_, int), \
        'Expecting int for argument threshold got %s ' % type(threshold_)
    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface got %s ' % type(surface_)

    if not 0 <= alpha_value <= 255:
        raise ERROR('\n[-] invalid value for argument alpha_value, should be 0 <= alpha_value <=255 got %s '
                    % alpha_value)
    if not 0 <= threshold_ <= 255:
        raise ERROR('\n[-] invalid value for argument threshold_, should be 0 <= threshold_ <=255 got %s '
                    % threshold_)

    if surface_.get_bitsize() is not 32:
        raise ERROR('\n[-]green_mask_alpha error : Only compatible with 32-bits surface, got %s '
                    % surface_.get_bitsize())

    # Extract all the pixel colors into a numpy array
    rgba_array = pygame.surfarray.pixels3d(surface_)

    # Extract all the alpha values into a numpy array
    alpha_channel = pygame.surfarray.pixels_alpha(surface_)

    # Make a RGBA array with both array above (RGB + alpha)
    new_array = make_array(rgba_array, alpha_channel)
    numpy.putmask(new_array[:, :, 3:], new_array[:, :, 1:2] > threshold_, alpha_value)
    return make_surface(new_array)


def red_mask_alpha(surface_: pygame.Surface, threshold_: int, alpha_value: int) -> pygame.Surface:
    """
    Change alpha values for all red pixels (except red pixels with value above color threshold).
    :param surface_: 32-bit Surface with alpha transparency
    :param threshold_: integer representing the threshold.
    :param alpha_value: new alpha value
    :return: pygame.Surface
    """

    assert isinstance(alpha_value, int), \
        'Expecting int for argument alpha_value got %s ' % type(alpha_value)
    assert isinstance(threshold_, int), \
        'Expecting int for argument threshold got %s ' % type(threshold_)
    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface got %s ' % type(surface_)

    if not 0 <= alpha_value <= 255:
        raise ERROR('\n[-] invalid value for argument alpha_value, should be 0 <= alpha_value <=255 got %s '
                    % alpha_value)
    if not 0 <= threshold_ <= 255:
        raise ERROR('\n[-] invalid value for argument threshold_, should be 0 <= threshold_ <=255 got %s '
                    % threshold_)

    if surface_.get_bitsize() is not 32:
        raise ERROR('\n[-]red_mask_alpha error : Only compatible with 32-bits surface, got %s '
                    % surface_.get_bitsize())

    # Extract all the pixel colors into a numpy array
    rgba_array = pygame.surfarray.pixels3d(surface_)
    # Extract all the alpha values into a numpy array
    alpha_channel = pygame.surfarray.pixels_alpha(surface_)

    # Make a RGBA array with both array above (RGB + alpha)
    new_array = make_array(rgba_array, alpha_channel)
    numpy.putmask(new_array[:, :, 3:], new_array[:, :, :1] > threshold_, alpha_value)
    return make_surface(new_array)


def blue_mask_alpha(surface_: pygame.Surface, threshold_: int, alpha_value: int) -> pygame.Surface:
    """
    Change alpha values for all blue pixels (except blue pixels with value above color threshold).
    :param surface_: 32-bit Surface
    :param threshold_: integer representing the threshold.
    :param alpha_value: new alpha value
    :return: pygame.Surface
    """

    assert isinstance(alpha_value, int), \
        'Expecting int for argument alpha_value got %s ' % type(alpha_value)
    assert isinstance(threshold_, int), \
        'Expecting int for argument threshold got %s ' % type(threshold_)
    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface got %s ' % type(surface_)
    if not 0 <= alpha_value <= 255:
        raise ERROR('\n[-] invalid value for argument alpha_value, should be 0 <= alpha_value <=255 got %s '
                    % alpha_value)
    if not 0 <= threshold_ <= 255:
        raise ERROR('\n[-] invalid value for argument threshold_, should be 0 <= threshold_ <=255 got %s '
                    % threshold_)

    if surface_.get_bitsize() is not 32:
        raise ERROR('\n[-]blue_mask_alpha error : Only compatible with 32-bits surface, got %s '
                    % surface_.get_bitsize())

    # Extract all the pixel colors into a numpy array
    rgba_array = pygame.surfarray.pixels3d(surface_)
    # Extract all the alpha values into a numpy array
    alpha_channel = pygame.surfarray.pixels_alpha(surface_)

    # Make a RGBA array with both array above (RGB + alpha)
    new_array = make_array(rgba_array, alpha_channel)
    numpy.putmask(new_array[:, :, 3:], new_array[:, :, 2:3] > threshold_, alpha_value)
    return make_surface(new_array)


def black_blanket_surface(surface_: pygame.Surface, new_alpha_: int, threshold_: int) -> pygame.Surface:
    """
    Force all colors (R+G+B) under a certain value (threshold) to be transparent or partially
    transparent (depends on new_alpha).
    This method is equivalent to black_blanket but twice as fast

    :param surface_: Surface
    :param new_alpha_: new alpha value for the array
    :param threshold_: treshold value for updating alpha transparency channel (any row of pixel that
    have a colors values < threshold, will be set an for alpha update.
    :return: return a new surface whom pixels colors under a certain threshold have been force to a degree
    of transparency ( new alpha value)
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting pygame.Surface for argument surface_, got %s ' % type(surface_)
    assert isinstance(new_alpha_, int), \
        'Expecting numpy.array for argument new_alpha, got %s ' % type(new_alpha_)
    assert isinstance(threshold_, int), 'Expecting int for argument threshold_ got %s ' % type(threshold_)

    if not 0 <= new_alpha_ <= 255:
        raise ERROR('\n[-] invalid value for argument new_alpha_, should be 0 <= new_alpha_ <=255 got %s '
                    % new_alpha_)
    if not 0 <= threshold_ <= 255:
        raise ERROR('\n[-] invalid value for argument threshold_, should be 0 <= threshold_ <=255 got %s '
                    % threshold_)
    buffer_ = surface_.get_view('2')
    w, h = surface_.get_width(), surface_.get_height()
    source_array = numpy.frombuffer(buffer_, dtype=numpy.uint8).reshape((w, h, 4))
    # split the 3d array into many for color triage
    red, green, blue, alpha = source_array[:, :, 0], source_array[:, :, 1], \
                              source_array[:, :, 2], source_array[:, :, 3]
    # create a mask for color value < threshold
    # e.g True if Red < 20 and Green < 20 and Blue < 20
    mask1 = (red < threshold_) & (green < threshold_) & (blue < threshold_)
    # create a mask for alpha > 0
    mask2 = alpha > 0
    # combine the masks, here all pixels < 20 and alpha > 0
    mask = mask1 & mask2
    # change the pixels with the mask
    source_array[:, :, :][mask] = new_alpha_
    return pygame.image.frombuffer(source_array.copy(order='C').astype(numpy.uint8),
                                   (w, h), 'RGBA')


def black_blanket(rgb_array: numpy.ndarray, alpha_array: numpy.ndarray, new_alpha: int,
                  threshold: int) -> pygame.Surface:
    """
    Force all colors (R+G+B) under a certain value (threshold) to be transparent or partially
    transparent (depends on new_alpha).
    :param rgb_array: 3d RGB array representing all pixel color
    :param alpha_array: 2d array representing alpha channel transparency
    :param new_alpha: new alpha value to insert into the array
    :param threshold: Threshold
    :return: return a new surface with pixel color under a certain value to be transparent or partially
    transparent.
    """
    assert isinstance(rgb_array, numpy.ndarray), \
        'Expecting numpy.array got %s ' % type(rgb_array)
    assert isinstance(alpha_array, numpy.ndarray), \
        ' Expecting numpy.array got %s ' % type(alpha_array)
    assert isinstance(new_alpha, int), 'Expecting int got %s ' % type(new_alpha)
    assert isinstance(threshold, int), 'Expecting int got %s ' % type(threshold)

    if not 0 <= new_alpha <= 255:
        raise ERROR('\n[-] invalid value for argument new_alpha, should be 0 <= alpha_value <=255 got %s '
                    % new_alpha)
    if not 0 <= threshold <= 255:
        raise ERROR('\n[-] invalid value for argument threshold, should be 0 <= threshold <=255 got %s '
                    % threshold)

    rgba = make_array(rgb_array, alpha_array)
    red, green, blue, alpha_ = rgba[:, :, 0], rgba[:, :, 1], rgba[:, :, 2], rgba[:, :, 3]
    mask1 = (red < threshold) & (green < threshold) & (blue < threshold)
    mask2 = alpha_ > 0
    mask = mask1 & mask2
    rgba[:, :, :][mask] = new_alpha

    return make_surface(rgba.astype(dtype=numpy.uint8))


# Add transparency value to all pixels including black pixels
def add_transparency_all(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    Increase transparency of a surface
    This method is equivalent to pygame.Surface.set_alpha() but conserve the per-pixel properties of a texture
    All pixels will be update with a new transparency value.
    If you need to increase transparency on visible pixels only, prefer the method add_transparency instead.
    :param rgb_array:
    :param alpha_:
    :param value:
    :return:
    """
    assert isinstance(rgb_array, numpy.ndarray), \
        'Expecting numpy.array got %s ' % type(rgb_array)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray got %s ' % type(alpha_)
    assert isinstance(value, int), 'Expecting int got %s ' % type(value)

    if not 0 <= value <= 255:
        raise ERROR('\n[-] invalid value for argument value, should be 0 < value <=255 got %s '
                    % value)
    # method 1
    """
    mask = (alpha_ >= value)
    mask_zero = (alpha_ < value)
    alpha_[:][mask_zero] = 0
    alpha_[:][mask] -= value
    return make_surface(make_array(rgb_array, alpha_.astype(numpy.uint8)))
    """
    # method 2
    alpha_ = alpha_.astype(numpy.int16)
    alpha_ -= value
    numpy.putmask(alpha_, alpha_ < 0, 0)

    return make_surface(make_array(rgb_array, alpha_.astype(numpy.uint8)))


def add_transparency(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    This method increase transparency of per-pixel texture updating only pixels with alpha values > 0
    Transparent pixels (with alpha value =0) will remain unchanged (unlike  add_transparency_all
    that will change all alpha values).

    :param rgb_array:
    :param alpha_:
    :param value:
    :return:
    """
    assert isinstance(rgb_array, numpy.ndarray), \
        'Expecting numpy.array got %s ' % type(rgb_array)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray got %s ' % type(alpha_)
    assert isinstance(value, int), 'Expecting int got %s ' % type(value)

    if not 0 <= value <= 255:
        raise ERROR('\n[-] invalid value for argument value, should be 0 < value <=255 got %s '
                    % value)
    mask = (alpha_ > 0)
    alpha_ = alpha_.astype(numpy.int16)
    alpha_[:][mask] -= value
    numpy.putmask(alpha_[:][mask], alpha_[:][mask] < 0, 0)
    # todo need to investigate does not do what is suppose to do
    return make_surface(make_array(rgb_array, alpha_.astype(numpy.uint8)))


def blink_surface(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    Create a blinking effect by altering all alpha values (subtracting alpha channel by an amount)
    without restricting the data between 0 - 255. (e.g alpha 10 - 25 ->  new alpha value 240 not 0)
    :param rgb_array:
    :param alpha_:
    :param value:
    :return:
    """
    assert isinstance(rgb_array, numpy.ndarray), \
        'Expecting numpy.array got %s ' % type(rgb_array)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray got %s ' % type(alpha_)
    assert isinstance(value, int), 'Expecting int got %s ' % type(value)

    if not 0 <= value <= 255:
        raise ERROR('\n[-] invalid value for argument value, should be 0 < value <=255 got %s '
                    % value)
    # values are not cap deliberately
    alpha_[:] -= value
    return make_surface(make_array(rgb_array, alpha_))


def sub_transparency(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    This method decrease transparency of per-pixel texture updating only pixels with alpha values > 0
    Transparent pixels (with alpha value =0) will remain unchanged.

    :param rgb_array: 3d numpy array RGB
    :param alpha_: 2d numpy array with alpha values
    :param value: amount of transparency
    :return: return a new surface with alpha value partially changed.
     Transparent pixels (with alpha value =0) will remain unchanged.
    """
    assert isinstance(rgb_array, numpy.ndarray), \
        'Expecting numpy.array got %s ' % type(rgb_array)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray got %s ' % type(alpha_)
    assert isinstance(value, int), 'Expecting int got %s ' % type(value)

    if not 0 <= value <= 255:
        raise ERROR('\n[-] invalid value for argument value, should be 0 < value <=255 got %s '
                    % value)
    # todo consider using numpy.putmask instead
    # mask1 select all values > 0 and <= 255 - value
    # No transparent pixel selected.
    mask1 = (alpha_ <= 255 - value) & alpha_ > 0
    # mask for value above 255 - value
    mask_255 = (alpha_ > 255 - value)
    alpha_[:][mask1] += value
    # fully opaque
    alpha_[:][mask_255] = 255

    return make_surface(make_array(rgb_array, alpha_.astype(numpy.uint8)))


def sub_transparency_all(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    This method decrease transparency of a surface by subtracting the current alpha value of all pixels by
    a specific value passed as an argument (value).
    return a new surface with all pixel alpha subtracted.

    :param rgb_array: 3d numpy array with RGB values
    :param alpha_: alpha transparency channel (2d numpy array)
    :param value: transparency amount
    :return: return a new surface with all pixel alpha subtracted
    """
    assert isinstance(rgb_array, numpy.ndarray), \
        'Expecting numpy.array got %s ' % type(rgb_array)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray got %s ' % type(alpha_)
    assert isinstance(value, int), 'Expecting int got %s ' % type(value)

    if not 0 <= value <= 255:
        raise ERROR('\n[-] invalid value for argument value, should be 0 < value <=255 got %s '
                    % value)
    # todo consider using numpy.putmask instead
    mask = (alpha_ <= 255 - value)
    mask_255 = (alpha_ > 255 - value)
    alpha_[:][mask] += value
    alpha_[:][mask_255] = 255
    return make_surface(make_array(rgb_array, alpha_.astype(numpy.uint8)))


def blend_texture_add(surface1: pygame.Surface, surface2: pygame.Surface,
                      set_alpha1: float, set_alpha2: float, mask: bool) -> pygame.Surface:
    """

    :param surface1:
    :param surface2:
    :param set_alpha1:
    :param set_alpha2:
    :param mask:
    :return:
    """

    """
    WIKIPEDIA
    Assuming that the pixel color is expressed using straight (non-premultiplied) RGBA tuples,
    a pixel value of (0, 0.7, 0, 0.5) implies a pixel that has 70% of the maximum green intensity
    and 50% opacity. If the color were fully green, its RGBA would be (0, 1, 0, 0.5).
    However, if this pixel uses premultiplied alpha, all of the RGB values (0, 0.7, 0)
    are multiplied by 0.5 and then the alpha is appended to the end to yield (0, 0.35, 0, 0.5).
    In this case, the 0.35 value for the G channel actually indicates 70% green intensity (with 50% opacity).
    Fully green would be encoded as (0, 0.5, 0, 0.5). For this reason, knowing whether a file uses straight
    or premultiplied alpha is essential to correctly process or composite it.


    Formula to apply to each pixels:
    OutA = SrcA + DstA(1 - SrcA)
    outRGB = (SrcRGB x SrcA + DstRGB x DstA x (1 - SrcA) / ( SrcA + DstA(1 - SrcA))

    if pre-multiplied  alpha is used, the above equations are simplified to:
    outA = SrcA + DstA(1 - SrcA)
    outRGB = SrcRGB + DstRGB(1 - SrcA)

    Surface 1 is png format with alpha transparency channel (image created with alpha channel)
    Compatible with 32 bit only
    """

    assert isinstance(surface1, pygame.Surface), \
        'Expecting Surface for argument surface got %s ' % type(surface1)
    assert isinstance(surface2, pygame.Surface), \
        'Expecting Surface for argument surface2 got %s ' % type(surface2)
    assert isinstance(set_alpha1, float), \
        'Expecting float for argument set_alpha1 got %s ' % type(set_alpha1)
    assert isinstance(set_alpha2, float), \
        'Expecting float for argument set_alpha2 got %s ' % type(set_alpha2)

    # sizes
    w, h = surface1.get_width(), surface1.get_height()

    # Create a BufferProxy for surface1 and 2
    buffer1 = surface1.get_view('3')
    buffer2 = surface2.get_view('3')

    # create arrays representing surface1 and 2,
    # swap row and column and normalize.
    rgb1= numpy.array(buffer1, dtype=numpy.uint8).transpose(1, 0, 2) / 255
    rgb2 = numpy.array(buffer2, dtype=numpy.uint8).transpose(1, 0, 2) / 255

    # create an array with only alpha channel of surface1, transpose and normalize
    alpha1_ = numpy.array(surface1.get_view('a'), dtype=numpy.uint8).transpose(1, 0) / 255
    # alpha2_ = numpy.array(surface2.get_view('a'), dtype=numpy.uint8).transpose(1, 0) / 255

    # Create a mask for black pixel (texture 1)
    mask_alpha1 = alpha1_ <= 0

    # Create alpha channels alpha1 and alpha2
    alpha1 = numpy.full((w, h, 1), set_alpha1).transpose(1, 0, 2)
    alpha2 = numpy.full((w, h, 1), set_alpha2).transpose(1, 0, 2)

    # alpha channels
    # alpha1[:, :, 0] = numpy.array(surface1.get_view('a'), dtype=numpy.uint8).transpose(1, 0) / 255
    # alpha2[:, :, 0] = numpy.array(surface1.get_view('a'), dtype=numpy.uint8).transpose(1, 0) / 255

    # create the output array
    new = numpy.zeros((w, h, 4)).transpose(1, 0, 2)

    # Calculations for alpha & RGB values
    new[:, :, :3] = numpy.add(rgb1[:, :, :3], rgb2[:, :, :3] * (1 - alpha1[:, :, :]))
    new[:, :, 3] = numpy.add(alpha1[:, :, 0],  alpha2[:, :, 0] * (1 - alpha1[:, :, 0]))

    # De-normalization
    new = numpy.multiply(new, 255)

    # Capping all the values over 255
    numpy.putmask(new, new > 255, 255)

    # Apply the mask to the new surface
    if mask:
        new[mask_alpha1] = 0
    return pygame.image.frombuffer(new.copy('C').astype(numpy.uint8),
                                   (w, h), 'RGBA')


def test_mode_init():
    done = False

    while not done:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                done = True

        pygame.display.flip()
    screen.fill((0, 0, 0, 0))
    screen.blit(background, (0, 0))


if __name__ == '__main__':
    import doctest

    doctest.testmod()

    pygame.init()
    numpy.set_printoptions(threshold=numpy.nan)

    x = 800
    y = 1024
    path = "C:\\Users\\yoyob\\Desktop\\Python New programs\\"
    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (x, y))

    screen = pygame.display.set_mode((image.get_width(), image.get_height()), 0, 32)

    # Blit first the background picture
    background = pygame.image.load(path + 'test transparency\\background.png')
    background = pygame.transform.scale(background, (image.get_width(), image.get_height()))
    screen.blit(background, (0, 0))

    size = (x, y)
    surface1 = '\\test transparency\\blending\\bck1.png'
    texture1 = pygame.image.load(path + surface1).convert_alpha()
    texture1 = pygame.transform.smoothscale(texture1, size)

    surface2 = '\\test transparency\\blending\\blood2.png'
    texture2 = pygame.image.load(path + surface2).convert_alpha()
    texture2 = pygame.transform.smoothscale(texture2, size)

    image = blend_texture_add(texture1, texture2, 238 / 255, 255 / 255, mask=False)

    pygame.image.save(image, path + '\\test transparency\\blending\\Test1.png')
    screen.blit(image, (0, 0))
    test_mode_init()

    import timeit

    N = 10

    print('blend_texture_add ',
          timeit.timeit("blend_texture_add(texture1, image, 50/255, 12/255, mask=False)",
                        "from __main__ import blend_texture_add, texture1, image", number=N) / N)




    image = blend_texture_24bit(image, 0.2, (128, 0, 0, 0), colorkey=(0, 0, 0, 0))
    screen.blit(image, (0, 0))
    test_mode_init()
    print('blend_texture_24bit ',
          timeit.timeit("blend_texture_24bit(image, 0.8, (255, 0, 0, 0))",
                        "from __main__ import blend_texture_24bit, image", number=N) / N)

    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (256, 256))
    image = blend_texture(image, 0.2, (255, 10, 10, 0))
    pygame.display.set_caption("blend texture with (255, 0, 0, 0)")
    screen.blit(image, (0, 0))
    test_mode_init()

    print('blend_texture ',
          timeit.timeit("blend_texture(image, 0.8, (255, 0, 0, 0))",
                        "from __main__ import blend_texture, image", number=N) / N)

    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (256, 256))
    image = blend_texture_alpha(image, 0.2, (255, 10, 10, 0))
    pygame.display.set_caption("blend_texture_alpha with (255, 0, 0, 0)")
    screen.blit(image, (0, 0))
    test_mode_init()
    print('blend_texture_alpha',
          timeit.timeit("blend_texture_alpha(image, 0.8, (255, 0, 0, 0))",
                        "from __main__ import blend_texture_alpha, image", number=N) / N)

    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    # test black_blanket method
    image = black_blanket(rgb, alpha, 0, 20)
    screen.blit(image, (0, 0))
    pygame.display.set_caption("black_blanket")
    test_mode_init()
    print('black_blanket',
          timeit.timeit("black_blanket(rgb, alpha, 0, 20)",
                        "from __main__ import black_blanket,rgb, alpha, image", number=N) / N)

    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (256, 256))
    # test black_blanket method
    image = black_blanket_surface(image, new_alpha_=0, threshold_=20)
    screen.blit(image, (0, 0))
    pygame.display.set_caption("black_blanket_surface")
    test_mode_init()
    print('black_blanket_surface',
          timeit.timeit("black_blanket_surface(image, 0, 20)",
                        "from __main__ import black_blanket_surface, image", number=N) / N)

    # test transparency method
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    image = add_transparency_all(rgb, alpha, 128)
    screen.blit(image, (0, 0))
    pygame.display.set_caption("add_transparency_all : -100")
    test_mode_init()

    # test transparency method sub_transparency
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    image = sub_transparency_all(rgb, alpha, 128)
    screen.blit(image, (0, 0))
    pygame.display.set_caption("sub_transparency_all +100")
    test_mode_init()

    # test  create_solid_rgb_array method sub_transparency
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    solid = create_solid_rgb_array(rgb.shape, pygame.Color(255, 255, 255, 0))
    new_array = make_array(solid, alpha)
    image = make_surface(new_array)
    screen.blit(image, (0, 0))
    pygame.display.set_caption("create_solid_rgb_array (255,255,255,0)")
    test_mode_init()

    # test  create_solid_rgba_array
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    solid = create_solid_rgba_array((rgb.shape[0], rgb.shape[1], rgb.shape[2] + 1), pygame.Color(255, 0, 0, 128))
    image = make_surface(solid)
    screen.blit(image, (0, 0))
    pygame.display.set_caption("create_solid_rgba_array (255,0,0,128)")
    test_mode_init()

    # test add_color_to_rgba_array
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (256, 256))
    solid = add_color_to_rgba_array(image, pygame.Color(25, 100, 0, 2))
    image = make_surface(solid)
    screen.blit(image, (0, 0))
    pygame.display.set_caption("add_color_to_rgba_array (25, 100, 0, 2)")
    test_mode_init()
    print('add_color_to_rgba_array ',
          timeit.timeit("add_color_to_rgba_array(image, (25, 100, 0, 2))",
                        "from __main__ import add_color_to_rgba_array, image", number=N) / N)

    # test add_color_to_array
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(path + 'ph-10047.png')
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    solid = add_color_to_array(rgb, alpha, pygame.Color(25, 100, 0, 2))
    image = make_surface(solid)
    screen.blit(image, (0, 0))
    pygame.display.set_caption("add_color_to_array (25, 100, 0, 2)")
    test_mode_init()
    print('add_color_to_array ',
          timeit.timeit("add_color_to_array(rgb, alpha, pygame.Color(25, 100, 0, 2))",
                        "from __main__ import add_color_to_array, rgb, alpha, pygame", number=N) / N)

    # test add_color_to_surface
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    new_surface = add_color_to_surface(image, pygame.Color(100, 0, 0, 0), source_array=rgb, alpha_channel=alpha)
    screen.blit(new_surface, (0, 0))
    pygame.display.set_caption("add_color_to_surface (100, 0, 0, 0)")
    test_mode_init()
    print('add_color_to_surface with arrays',
          timeit.timeit("add_color_to_surface(image, pygame.Color(100, 0, 0, 0), "
                        "source_array=rgb, alpha_channel=alpha)",
                        "from __main__ import add_color_to_surface, pygame, image, rgb, alpha", number=N) / N)

    print('add_color_to_surface without arrays',
          timeit.timeit("add_color_to_surface(image, pygame.Color(100, 0, 0, 0))",
                        "from __main__ import add_color_to_surface, pygame, image", number=N) / N)

    # test add_color_to_surface_alpha
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    new_surface = add_color_to_surface_alpha(image, pygame.Color(100, 0, 0, 0))
    screen.blit(new_surface, (0, 0))
    pygame.display.set_caption("add_color_to_surface_alpha (100, 0, 0, 0)")
    test_mode_init()
    print('add_color_to_surface_alpha',
          timeit.timeit("add_color_to_surface_alpha(image, pygame.Color(100, 0, 0, 0))",
                        "from __main__ import add_color_to_surface_alpha, image, pygame", number=N) / N)

    # test subtract_color_from_array
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(new_surface)
    alpha = pygame.surfarray.array_alpha(new_surface)
    new_surface = subtract_color_from_array(rgb, alpha, pygame.Color(100, 0, 0, 2))
    new_surface = make_surface(new_surface)
    screen.blit(new_surface, (0, 0))
    pygame.display.set_caption("subtract_color_from_array (100, 0, 0, 2)")
    test_mode_init()
    print('subtract_color_from_array',
          timeit.timeit("subtract_color_from_array(rgb, alpha, pygame.Color(100, 0, 0, 0))",
                        "from __main__ import subtract_color_from_array, rgb, alpha, pygame", number=N) / N)

    # test subtract_color_from_rgba_array
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    new_surface = subtract_color_from_rgba_array(image, pygame.Color(100, 0, 0, 2))
    new_surface = make_surface(new_surface)
    screen.blit(new_surface, (0, 0))
    pygame.display.set_caption("subtract_color_from_rgba_array (100, 0, 0, 2)")
    test_mode_init()
    print('subtract_color_from_rgba_array',
          timeit.timeit("subtract_color_from_rgba_array(image, pygame.Color(100, 0, 0, 0))",
                        "from __main__ import subtract_color_from_rgba_array, image, pygame", number=N) / N)

    # test subtract_color_from_surface
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    new_surface = subtract_color_from_surface(image, pygame.Color(125, 25, 13, 2))
    screen.blit(new_surface, (0, 0))
    pygame.display.set_caption("subtract_color_from_surface (125, 25, 13, 2)")
    test_mode_init()
    print('subtract_color_from_surface',
          timeit.timeit("subtract_color_from_surface(image, pygame.Color(125, 25, 13, 2))",
                        "from __main__ import subtract_color_from_surface, image, pygame", number=N) / N)

    # test subtract_color_from_surface_alpha
    screen.fill((0, 0, 0))
    screen.blit(background, (0, 0))
    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    new_surface = subtract_color_from_surface_alpha(image, pygame.Color(125, 25, 13, 2))
    screen.blit(new_surface, (0, 0))
    pygame.display.set_caption("subtract_color_from_surface_alpha (125, 25, 13, 2)")
    test_mode_init()
    print('subtract_color_from_surface_alpha',
          timeit.timeit("subtract_color_from_surface_alpha(image, pygame.Color(125, 25, 13, 2))",
                        "from __main__ import subtract_color_from_surface_alpha, image, pygame", number=N) / N)

    # -------------------------------------------------------------------------------------------------------
    N = 10000
    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    import timeit

    print('make_array copy',
          timeit.timeit("make_array(rgb, alpha)", "from __main__ import make_array, rgb, alpha ", number=N) / N)

    rgb1 = pygame.surfarray.pixels3d(image)
    alpha1 = pygame.surfarray.pixels_alpha(image)

    print('make_array reference', timeit.timeit("make_array(rgb1, alpha1)",
                                                "from __main__ import make_array, rgb1, alpha1 ", number=N) / N)

    array = make_array(rgb, alpha)
    print('make_surface copy ', timeit.timeit("make_surface(array)",
                                              "from __main__ import make_surface, array", number=N) / N)

    array1 = make_array(rgb1, alpha1)
    print('make_surface reference', timeit.timeit("make_surface(array1)",
                                                  "from __main__ import make_surface, array1", number=N) / N)

    print('mask_alpha ', timeit.timeit("mask_alpha(array, 10)",
                                       "from __main__ import mask_alpha, array", number=N) / N)

    print('mask_alpha ', timeit.timeit("mask_alpha(array1, 10)",
                                       "from __main__ import mask_alpha, array1", number=N) / N)

    print('blend_texture ', timeit.timeit("blend_texture(image, 0.1, (255, 255, 255, 0))",
                                          "from __main__ import blend_texture, image", number=N) / N)
    print('blend_texture alpha',
          timeit.timeit("blend_texture_alpha(image, 0.1, (255, 255, 255, 0))",
                        "from __main__ import blend_texture_alpha, image", number=N) / N)
    print('blend_texture 24bit',
          timeit.timeit("blend_texture_24bit(image, 0.1, (255, 255, 255, 0))",
                        "from __main__ import blend_texture_24bit, image", number=N) / N)

    print('green_mask_alpha_texture ', timeit.timeit("green_mask_alpha(image, 100, 0)",
                                                     "from __main__ import green_mask_alpha, image", number=N) / N)

    print('black_blanket ', timeit.timeit("black_blanket(rgb, alpha, 0, 100)",
                                          "from __main__ import black_blanket, rgb, alpha", number=N) / N)

    print('add_transparency ', timeit.timeit("add_transparency(rgb, alpha, 25)",
                                             "from __main__ import add_transparency, rgb, alpha", number=N) / N)

    print('add_transparency_all ', timeit.timeit("add_transparency_all(rgb, alpha, 25)",
                                                 "from __main__ import add_transparency_all, rgb, alpha", number=N) / N)

    print('sub_transparency_all ', timeit.timeit("sub_transparency_all(rgb, alpha, 100)",
                                                 "from __main__ import sub_transparency_all, rgb, alpha", number=N) / N)

    print('sub_transparency', timeit.timeit("sub_transparency(rgb, alpha, 100)",
                                            "from __main__ import sub_transparency, rgb, alpha", number=N) / N)

    print('create_solid_rgb_array', timeit.timeit("create_solid_rgb_array(rgb.shape, (255, 255, 255, 0))",
                                                  "from __main__ import create_solid_rgb_array, rgb", number=N) / N)

    print('create_solid_rgba_array',
          timeit.timeit("create_solid_rgba_array((rgb.shape[0], rgb.shape[1], rgb.shape[2] + 1), "
                        "(255, 0, 0, 128))",
                        "from __main__ import create_solid_rgba_array, rgb", number=N) / N)

    print('add_color_to_array', timeit.timeit("add_color_to_array(rgb, alpha, (25, 100, 0, 2))",
                                              "from __main__ import add_color_to_array, rgb, alpha", number=N) / N)

    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    print('add_color_to_surface', timeit.timeit("add_color_to_surface(image, (25, 100, 0, 2),"
                                                " source_array=rgb, alpha_channel=alpha)",
                                                "from __main__ import add_color_to_surface,"
                                                " image, rgb, alpha", number=N) / N)

    image = pygame.image.load(GAMEPATH + 'ph-10047.png').convert_alpha()
    image = pygame.transform.smoothscale(image, (256, 256))
    rgb = pygame.surfarray.array3d(image)
    alpha = pygame.surfarray.array_alpha(image)
    # subtract_color_from_array
    print('subtract_color_from_array', timeit.timeit("subtract_color_from_array(rgb, alpha, (100, 0, 0, 2))",
                                                     "from __main__ import subtract_color_from_array,"
                                                     "rgb, alpha", number=N) / N)
    # subtract_color_from_surface
    print('subtract_color_from_surface', timeit.timeit("subtract_color_from_surface(image, (100, 0, 0, 2))",
                                                       "from __main__ import subtract_color_from_surface,"
                                                       "image", number=N) / N)


    def combo_method(image):
        diff = diff_from_surface(image, (220, 10, 11, 0), 1 / 30)
        image = surface_add_array(image, diff)


    # alternative method for blend_texture
    print('alternative method for blend_texture', timeit.timeit("combo_method(image)",
                                                                "from __main__ import combo_method,"
                                                                "image", number=N) / N)

    """
    blend_texture_24bit  0.009992595186743256
    blend_texture  0.006326818424480557
    blend_texture_alpha 0.007374824147430011
    black_blanket 0.002142113220440322
    black_blanket_surface 0.0005431471951141305
    add_color_to_rgba_array  0.002265708855623643
    add_color_to_array  0.0028346405005445375
    add_color_to_surface with arrays 0.0033991872557603245
    add_color_to_surface without arrays 0.0040205795554036855
    add_color_to_surface_alpha 0.002334264237972178
    subtract_color_from_array 0.0024341681436716557
    subtract_color_from_rgba_array 0.002444299045463282
    subtract_color_from_surface 0.0038353904631745193
    subtract_color_from_surface_alpha 0.0028307420615430773
    make_array copy 0.0005951824723995856
    make_array reference 0.0006295082107241398
    make_surface copy  0.0005573072241559771
    make_surface reference 7.582224689829786e-05
    mask_alpha  0.0003993094022934542
    mask_alpha  0.0006051169147323208
    blend_texture  0.006202765380426655
    blend_texture alpha 0.007221817677080423
    blend_texture 24bit 0.008944807704627465
    green_mask_alpha_texture  0.0013164773964850838
    black_blanket  0.002709268615601445
    add_transparency  0.0018976142988319396
    add_transparency_all  0.0015231305387687257
    sub_transparency_all  0.0013758487262166739
    sub_transparency 0.0016313211898609835
    create_solid_rgb_array 0.0005684469025603676
    create_solid_rgba_array 0.000512808729633349
    add_color_to_array 0.002573558265177553
    add_color_to_surface 0.003113892673343429
    subtract_color_from_array 0.0025822725234363303
    subtract_color_from_surface 0.0038533216596553644
    alternative method for blend_texture 0.009393821777103937
    """