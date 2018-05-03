import numpy
import pygame


class ERROR(BaseException):
    pass

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
    """
    assert isinstance(rgb_array_, numpy.ndarray), \
        'Expecting numpy.ndarray for argument rgb_array_ got %s ' % type(rgb_array_)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray for argument alpha_ got %s ' % type(alpha_)
    """
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

    # assert isinstance(rgba_array, numpy.ndarray), 'Expecting numpy.ndarray for ' \
    #                                              'argument rgb_array got %s ' % type(rgba_array)
    return pygame.image.frombuffer((rgba_array.transpose(1, 0, 2)).copy(order='C').astype(numpy.uint8),
                                   (rgba_array.shape[:2][0], rgba_array.shape[:2][1]), 'RGBA')


def blend_texture(surface_, interval_, color_) -> pygame.Surface:
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
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(interval_, (int, float)), \
        'Expecting float for argument interval_ got %s ' % type(interval_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)
    """
    source_array = pygame.surfarray.pixels3d(surface_)
    alpha_channel = pygame.surfarray.pixels_alpha(surface_)
    diff = (numpy.full_like(source_array.shape, color_[:3]) - source_array) * interval_

    rgba_array  = numpy.dstack((numpy.add(source_array, diff), alpha_channel)).astype(dtype=numpy.uint8)
    return pygame.image.frombuffer((rgba_array.transpose(1, 0, 2)).copy(order='C').astype(numpy.uint8),
                                   (rgba_array.shape[:2][0], rgba_array.shape[:2][1]), 'RGBA')



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


def blend_texture_alpha(surface_: pygame.Surface, interval_, color_) -> pygame.Surface:
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
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(interval_, (int, float)), \
        'Expecting float for argument interval_ got %s ' % type(interval_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)
    """
    w, h = surface_.get_width(), surface_.get_height()
    # todo need to implement some test for 24bit texture (without transparency)
    # return the buffer.view(Bufferproxy)
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


def blink_surface(rgb_array: numpy.ndarray, alpha_: numpy.ndarray, value: int) -> pygame.Surface:
    """
    Create a blinking effect by altering all alpha values (subtracting alpha channel by an amount)
    without restricting the data between 0 - 255. (e.g alpha 10 - 25 ->  new alpha value 240 not 0)
    :param rgb_array:
    :param alpha_:
    :param value:
    :return:
    """
    """
    assert isinstance(rgb_array, numpy.ndarray), \
        'Expecting numpy.array got %s ' % type(rgb_array)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray got %s ' % type(alpha_)
    assert isinstance(value, int), 'Expecting int got %s ' % type(value)
    """
    if not 0 <= value <= 255:
        raise ERROR('\n[-] invalid value for argument value, should be 0 < value <=255 got %s '
                    % value)
    # values are not cap deliberately
    alpha_[:] -= value
    return make_surface(make_array(rgb_array, alpha_))


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
    """
    assert isinstance(rgb_array, numpy.ndarray), \
        'Expecting numpy.array got %s ' % type(rgb_array)
    assert isinstance(alpha_, numpy.ndarray), \
        'Expecting numpy.ndarray got %s ' % type(alpha_)
    assert isinstance(value, int), 'Expecting int got %s ' % type(value)
    """
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



def blend_texture_24bit(surface_: pygame.Surface, interval_,
                        color_, colorkey=(0, 0, 0, 0)) -> pygame.Surface:
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
    """
    assert isinstance(surface_, pygame.Surface), \
        'Expecting Surface for argument surface_ got %s ' % type(surface_)
    assert isinstance(interval_, (int, float)), \
        'Expecting float for argument interval_ got %s ' % type(interval_)
    assert isinstance(color_, (pygame.Color, tuple)), \
        'Expecting tuple for argument color_ got %s ' % type(color_)
    assert isinstance(colorkey, (pygame.Color, tuple)), \
        'Expecting tuple for argument colorkey got %s ' % type(colorkey)
    """
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
