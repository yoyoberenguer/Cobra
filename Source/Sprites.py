# encoding: utf-8
import numpy
import pygame
from Constants import *
from surface import make_surface, make_array, black_blanket, black_blanket_surface, \
    add_transparency, add_transparency_all, \
    blend_texture, mask_alpha
import os.path
import sys
from random import randint
import multiprocessing

# It is safe to call this init() more than once: repeated
# calls will have no effect.
pygame.display.init()
import os

position = 50, 25
os.environ['SDL_VIDEO_WINDOW_POS'] = str(position[0]) + "," + str(position[1])
os.environ['SDL_VIDEODRIVER'] = 'windib'
screen = pygame.display.set_mode(SCREENRECT.size, pygame.HWSURFACE | pygame.HWSURFACE, 32)

OBJECT_MEMORY = 0
BLACK = pygame.Color(0, 0, 0, 0)
WHITE = pygame.Color(255, 255, 255, 255)


# Todo need to clean unused surface + del data when assigned to a list


class ERROR(BaseException):
    pass


def load_surface_32bit_alpha(path: str, file: str) -> pygame.Surface:
    """
    Use only 32 bit surface with alpha transparency for this method.

    :param path: path to the image
    :param file: image to load
    :return: Return a 32-bit surface converted for fast blitting using method convert_alpha().
             If using convert() instead of convert_alpha(), The converted surface
             will have no pixel alphas transparency.
    """
    try:
        isinstance(path, str), 'Expecting string got %s ' % type(path)
        isinstance(file, str), 'Expecting string got %s ' % type(file)
        if not pygame.image.get_extended():
            print('\n[-] pygame is not built to support all image formats.\n')
        # Convert surface for fast blitting with alpha transparency
        surface_ = pygame.image.load(os.path.join(path, file)).convert_alpha()
        if surface_.get_bitsize() < 32:
            raise ERROR('\n[-] Loaded surface is not 32bit. got %s bit' % str(surface_.get_bitsize()))
    except pygame.error:
        raise SystemExit('\n[-] Error : Could not load image %s %s ' % (file, pygame.get_error()))
    return surface_


def convert_surface_to_24bit(file: str, colorkey: pygame.Color = BLACK) -> pygame.Surface:
    """
    The new 24 bit surface will be in a format suited for quick blitting to the
    given format with alpha transparency (colorkey set the transparency.)
    :param file: 24 bit image to load
    :param colorkey: colorkey ( color set transparency default black)
    :return: return a 24-bit surface with alpha transparency
    """
    try:
        isinstance(file, str), 'Expecting string got %s ' % type(file)
        isinstance(colorkey, pygame.Color), 'Expecting pygame.Color got %s ' % type(colorkey)
        # load the image and convert it to per-pixel alpha
        image_ = pygame.image.load(file).convert()
        rect = pygame.Rect(image_.get_rect())
        # create surface with source alpha | surface is in the video memory
        # The optional flags argument can be set to pygame.RLEACCEL to provide
        # better performance on non accelerated displays. An RLEACCEL Surface will be slower to modify,
        # but quicker to blit as a source.
        surface_ = pygame.Surface(rect.size, depth=24)
        surface_.blit(image_, (0, 0), rect)
        surface_.set_colorkey(colorkey, pygame.RLEACCEL)
        return surface_
    except pygame.error:
        raise SystemExit('\n[-] Error : Could not load image %s %s ' % (file, pygame.get_error()))


def load_per_pixel(file: str) -> pygame.Surface:
    """
    load a per-pixel image (32-24/8 bit)and return a per-pixel texture using frombuffer method
    pygame.image.frombuffer will display image with disproportional scaling (X&Y scale),
    however the image will be distorted.
    :param file: image/sprite to load
    :return: Return a 32-bit surface with per-pixels alpha transparency
    """
    assert isinstance(file, str), 'Expecting path for argument <file> got %s: ' % type(file)
    try:
        # The returned Surface will contain the same color format,
        # colorkey and alpha transparency as the file it came from.
        image_ = pygame.image.load(file)
        # Create a 3D arrays from a given surface.
        surface_ = pygame.surfarray.pixels3d(image_)  # 3d numpy array with RGB values
        if image_.get_bitsize() == 32:
            alpha_ = pygame.surfarray.pixels_alpha(image_)
        elif image_.get_bitsize() in (24, 8):
            alpha_ = pygame.surfarray.array_alpha(image_)
        else:
            raise ERROR('\n[-] Texture is not 32-24/8 bit surface, got %s bit' % image.get_bitsize())

        # Return a surface containing RGB and alpha values.
        return make_surface(make_array(surface_, alpha_))
    except pygame.error:
        raise SystemExit('\n[-] Error : Could not load image %s %s ' % (file, pygame.get_error()))


def spread_sheet_per_pixel(file: str, chunk: int, rows_: int, columns_: int, tweak_: bool = False, *args) -> list:
    """
    Works only for 32-24/8 bit
    # Return a python list containing all images (Surface) from a given sprite sheet
    # Every images/surface from the list have a per-pixels texture transparency.
    # Method set_colorkey and set_alpha will have no effect.
    :param file: Path to the file
    :param chunk: Pixel size of the chunk
    :param rows_: Number of rows in the sprite sheet
    :param columns_: Number of columns in the sprite sheet
    :param tweak_: Bool to adjust the block size to copy (disproportional chunk)
    :return: Return a list of sprite with per-pixels transparency.
    """
    """Return a python list containing all images from a given sprite sheet."""
    assert isinstance(file, str), 'Expecting string for argument file got %s: ' % type(file)
    assert isinstance(chunk, int), 'Expecting int for argument number got %s: ' % type(chunk)
    assert isinstance(rows_, int) and isinstance(columns_, int), 'Expecting int for argument rows_ and columns_ ' \
                                                                 'got %s, %s ' % (type(rows_), type(columns_))
    try:
        # The returned Surface will contain the same color format,
        #  colorkey and alpha transparency as the file it came from.
        image_ = pygame.image.load(file)
        # Create arrays from surface and alpha channel (numpy array)
        surface_ = pygame.surfarray.pixels3d(image_)  # 3d numpy array with RGB values

        if image_.get_bitsize() == 32:
            alpha_ = pygame.surfarray.pixels_alpha(image_)
        elif image_.get_bitsize() in (24, 8):
            alpha_ = pygame.surfarray.array_alpha(image_)
        else:
            raise ERROR('\n[-] Texture is not 32-24/8 bit surface, got %s bit' % image.get_bitsize())
        # Make a surface containing RGB and alpha values
        array = make_array(surface_, alpha_)
        animation = []
        # split sprite-sheet into many sprites
        for rows in range(rows_):
            for columns in range(columns_):
                if tweak_:
                    chunkx = args[0]
                    chunky = args[1]
                    array1 = array[columns * chunkx:(columns + 1) * chunkx, rows * chunky:(rows + 1) * chunky, :]
                else:
                    array1 = array[columns * chunk:(columns + 1) * chunk, rows * chunk:(rows + 1) * chunk, :]
                surface_ = make_surface(array1)
                animation.append(surface_)
        return animation
    except pygame.error:
        raise SystemExit('\n[-] Error : Could not load image %s %s ' % (file, pygame.get_error()))


class SpriteSheet:

    def __init__(self, path, filename, depth, keycolor=None):
        try:
            self.sheet = pygame.image.load(path + filename).convert_alpha()
            self.depth = depth
            self.keycolor = keycolor
        except pygame.error:
            print('\n[-] Error : Unable to load sprite sheet image:', filename)
            raise SystemExit

    def image_at(self, rectangle):
        rect = pygame.Rect(rectangle)
        if self.depth == 32:
            surface_ = pygame.Surface(rect.size, depth=self.depth, flags=(pygame.HWSURFACE | pygame.SRCALPHA))
        elif self.depth in (24, 8):
            surface_ = pygame.Surface(rect.size, depth=self.depth)

        surface_.blit(self.sheet, (0, 0), rect)

        if self.keycolor:
            surface_.set_colorkey(self.keycolor, pygame.RLEACCEL)
        else:
            self.keycolor = self.sheet.get_at((0, 0))
            print('COLOR KEY ', self.keycolor)
            surface_.set_colorkey(self.keycolor, pygame.RLEACCEL)

        return surface_

    def images_at(self, rects):
        return [self.image_at(rect) for rect in rects]

    def load_strip(self, rect, image_count):
        tuple_ = [(rect[0] + rect[2] * x, rect[1], rect[2], rect[3])
                  for x in range(image_count)]
        return self.images_at(tuple_)


# WAIT = spread_sheet_per_pixel(GAMEPATH + 'Flame_explosions\\TimeLineFx\\wait512x512.png', 512, 6, 6)

# ----------------------------------- SUPERSHOT WARMUPS -------------------------------------------------------------

SUPERSHOT_SPRITE_1 = \
    spread_sheet_per_pixel('Assets\\Graphics\\SpaceShip\\Warmups\\SuperShotRedWarmup.png', 64, 2, 7, True, 64, 72)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_SPRITE_1)

SUPERSHOT_SPRITE_2 = spread_sheet_per_pixel(
    'Assets\\Graphics\\SpaceShip\\Warmups\\SuperShotBlueWarmup.png', 64, 2, 7, True, 64, 72)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_SPRITE_2)

SUPERSHOT_SPRITE_3 = spread_sheet_per_pixel(
    'Assets\\Graphics\\SpaceShip\\Warmups\\SuperShotPurpleWarmup.png', 64, 2, 7, True, 64, 72)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_SPRITE_3)

SUPERSHOT_SPRITE_4 = spread_sheet_per_pixel(
    'Assets\\Graphics\\SpaceShip\\Warmups\\SuperShotGreenWarmup.png', 64, 2, 7, True, 64, 72)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_SPRITE_4)

SUPERSHOT_SPRITE_5 = spread_sheet_per_pixel(
    'Assets\\Graphics\\SpaceShip\\Warmups\\SuperShotYellowWarmup.png', 64, 2, 7, True, 64, 72)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_SPRITE_5)

SUPERSHOT_SPRITE_6 = spread_sheet_per_pixel(
    'Assets\\Graphics\\SpaceShip\\Warmups\\SuperShotGoldWarmup.png', 64, 2, 7, True, 64, 72)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_SPRITE_6)

# -------------------------------------------------------------------------------------------------------------------

# ----------------------------------------- SUPER SHOT LASER --------------------------------------------------------
PATH = 'Assets\\Graphics\\Laser_Fx\\png\\3 heavy\\'
# SUPERSHOT GREEN
SUPERSHOT_GREEN_LASER = load_surface_32bit_alpha(PATH, 'lzrfxHeavy01.png')
SUPERSHOT_GREEN_LASER = pygame.transform.rotozoom(SUPERSHOT_GREEN_LASER, 90, 1)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_GREEN_LASER)

# SUPERSHOT BLUE
SUPERSHOT_BLUE_LASER = load_surface_32bit_alpha(PATH, 'lzrfxHeavy02.png')
SUPERSHOT_BLUE_LASER = pygame.transform.rotozoom(SUPERSHOT_BLUE_LASER, 90, 1)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_BLUE_LASER)

# SUPERSHOT RED
SUPERSHOT_RED_LASER = load_surface_32bit_alpha(PATH, 'lzrfxHeavy03.png')
SUPERSHOT_RED_LASER = pygame.transform.rotozoom(SUPERSHOT_RED_LASER, 90, 1)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_RED_LASER)

# SUPERSHOT GOLD
SUPERSHOT_GOLD_LASER = load_surface_32bit_alpha(PATH, 'lzrfxHeavy05.png')
SUPERSHOT_GOLD_LASER = pygame.transform.rotozoom(SUPERSHOT_GOLD_LASER, 90, 1)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_GOLD_LASER)

# SUPERSHOT PURPLE
SUPERSHOT_PURPLE_LASER = load_surface_32bit_alpha(PATH, 'lzrfxHeavy06.png')
SUPERSHOT_PURPLE_LASER = pygame.transform.rotozoom(SUPERSHOT_PURPLE_LASER, 90, 1)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_PURPLE_LASER)

# SUPERSHOT YELLOW
SUPERSHOT_YELLOW_LASER = load_surface_32bit_alpha(PATH, 'lzrfxHeavy09.png')
SUPERSHOT_YELLOW_LASER = pygame.transform.rotozoom(SUPERSHOT_YELLOW_LASER, 90, 1)
OBJECT_MEMORY += sys.getsizeof(SUPERSHOT_YELLOW_LASER)
# --------------------------------------------------------------------------------------------------------------

# -------------------------------------------- PHOTON SHOT -----------------------------------------------------
PATH = 'Assets\\Graphics\\Laser_Fx\\png\\1 basic\\'
# GREEN
GREEN_PHOTON = load_surface_32bit_alpha(PATH, 'lzrfx004.png')
GREEN_PHOTON = pygame.transform.rotozoom(GREEN_PHOTON, 90, 1)
OBJECT_MEMORY += sys.getsizeof(GREEN_PHOTON)
# PURPLE
PURPLE_PHOTON = load_surface_32bit_alpha(PATH, 'lzrfx029.png')
PURPLE_PHOTON = pygame.transform.rotozoom(PURPLE_PHOTON, 90, 1)
OBJECT_MEMORY += sys.getsizeof(PURPLE_PHOTON)
# GOLD
GOLD_PHOTON = load_surface_32bit_alpha(PATH, 'lzrfx076.png')
GOLD_PHOTON = pygame.transform.rotozoom(GOLD_PHOTON, 90, 1)
OBJECT_MEMORY += sys.getsizeof(GOLD_PHOTON)
# YELLOW
YELLOW_PHOTON = load_surface_32bit_alpha(PATH, 'lzrfx077.png')
YELLOW_PHOTON = pygame.transform.rotozoom(YELLOW_PHOTON, 90, 1)
OBJECT_MEMORY += sys.getsizeof(YELLOW_PHOTON)
# BLUE
BLUE_PHOTON = load_surface_32bit_alpha(PATH, 'lzrfx089.png')
BLUE_PHOTON = pygame.transform.rotozoom(BLUE_PHOTON, 90, 1)
OBJECT_MEMORY += sys.getsizeof(BLUE_PHOTON)
# RED
RED_PHOTON = load_surface_32bit_alpha(PATH, 'lzrfx101.png')
RED_PHOTON = pygame.transform.rotozoom(RED_PHOTON, 90, 1)
OBJECT_MEMORY += sys.getsizeof(RED_PHOTON)
# ---------------------------------------------------------------------------------------------------------------

# -------------------------------------------SPACESHIP SPRITE --------------------------------------------------
# SPACESHIP
SPACESHIP_SPRITE = load_surface_32bit_alpha('Assets\\Graphics\\SpaceShip\\', 'SpaceShip.png')
OBJECT_MEMORY += sys.getsizeof(SPACESHIP_SPRITE)

# DAMAGED SPACESHIP
SPACESHIP_SPRITE_LAVA = load_surface_32bit_alpha('Assets\\Graphics\\SpaceShip\\', 'SpaceShip_LAVA_1.png')
# SPACESHIP_SPRITE = convert_surface_to_24bit(GAMEPATH + 'SpaceShip\\New\\SpaceShip.png', (0, 0, 0, 0))
OBJECT_MEMORY += sys.getsizeof(SPACESHIP_SPRITE_LAVA)

SPACESHIP_EXPLODE = [
    convert_surface_to_24bit('Assets\\Graphics\\SpaceShip\\Explosion\\p1.png', BLACK),
    convert_surface_to_24bit('Assets\\Graphics\\SpaceShip\\Explosion\\p2.png', BLACK),
    convert_surface_to_24bit('Assets\\Graphics\\SpaceShip\\Explosion\\p3.png', BLACK),
    convert_surface_to_24bit('Assets\\Graphics\\SpaceShip\\Explosion\\p4.png', BLACK),
    convert_surface_to_24bit('Assets\\Graphics\\SpaceShip\\Explosion\\p5.png', BLACK),
    convert_surface_to_24bit('Assets\\Graphics\\SpaceShip\\Explosion\\p6.png', BLACK)
]
OBJECT_MEMORY += sys.getsizeof(SPACESHIP_EXPLODE)
# ------------------------------------------------------------------------------------------------------------------

SHOOTING_SPRITE = [RED_PHOTON, SUPERSHOT_RED_LASER,
                   BLUE_PHOTON, SUPERSHOT_BLUE_LASER,
                   PURPLE_PHOTON, SUPERSHOT_PURPLE_LASER,
                   GREEN_PHOTON, SUPERSHOT_GREEN_LASER,
                   YELLOW_PHOTON, SUPERSHOT_YELLOW_LASER,
                   GOLD_PHOTON, SUPERSHOT_GOLD_LASER,
                   load_surface_32bit_alpha('Assets\\Graphics\\Laser_Fx\\png\\miscs\\', 'Green_laser_vertical.png'),
                   load_surface_32bit_alpha('Assets\\Graphics\\Bullets\\', 'bullet3.png'),
                   load_surface_32bit_alpha('Assets\\Graphics\\Bullets\\', 'bullet2.png')]
OBJECT_MEMORY += sys.getsizeof(SHOOTING_SPRITE)


# MISCELLANEOUS LASERS
LAZER_FX = [load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\1 basic\\lzrfx001.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\3 heavy\\lzrfxHeavy48.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\2 mixed\\lzrfxMixed047.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\2 mixed\\lzrfxMixed052.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\3 heavy\\lzrfxHeavy32.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\1 basic\\LZRFX074.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\1 basic\\LZRFX084.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\4 huge\\lzrfxHuge25.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\3 heavy\\lzrfxHeavy07.png'),
            load_per_pixel('Assets\\Graphics\\Laser_Fx\\png\\1 basic\\lzrfx018.png')
            ]
OBJECT_MEMORY += sys.getsizeof(LAZER_FX)

"""
SHOT_BULLET_DOUBLE = [load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_bullet_fx_double_1.png'),
                      load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_bullet_fx_double_2.png'),
                      load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_bullet_fx_double_3.png')]
SHOT_BULLET_SINGLE = [load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_bullet_fx_single_1.png'),
                      load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_bullet_fx_single_2.png'),
                      load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_bullet_fx_single_3.png')]


SHOT_GREEN_PHOTON = [load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_green_1.png'),
                     load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_green_2.png'),
                     load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_green_3.png')]

SHOT_RED_PHOTON = [load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_red_1.png'),
                   load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_red_2.png')]

SHOT_BLUE_PHOTON = [load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_blue_1.png'),
                    load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_blue_2.png')]

SHOT_PURPLE_PHOTON = [load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_purple_1.png'),
                      load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_purple_2.png')]

SHOT_YELLOW_PHOTON = [load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_yellow_1.png'),
                      load_surface_32bit_alpha(GAMEPATH + 'SpaceShip\\New\\', 'SpaceShip_fire_yellow_2.png')]
"""


COSMIC_DUST1 = convert_surface_to_24bit('Assets\\Graphics\\Background\\stars.png')
COSMIC_DUST1 = pygame.transform.smoothscale(COSMIC_DUST1, (2, 5))
OBJECT_MEMORY += sys.getsizeof(COSMIC_DUST1)

"""
PARTICLE_TRAIL_GREEN = [load_sprite(GAMEPATH + 'ParticleFX\\GREEN', 'Image1.png'),
                        load_sprite(GAMEPATH + 'ParticleFX\\GREEN', 'Image2.png'),
                        load_sprite(GAMEPATH + 'ParticleFX\\GREEN', 'Image3.png'),
                        load_sprite(GAMEPATH + 'ParticleFX\\GREEN', 'Image2.png'),
                        load_sprite(GAMEPATH + 'ParticleFX\\GREEN', 'Image3.png')]
i = 0
for surface in PARTICLE_TRAIL_GREEN:
    PARTICLE_TRAIL_GREEN[i] = pygame.transform.scale(surface, (50, 50))
    i += 1

PARTICLE_TRAIL_RED = [load_sprite(GAMEPATH + 'ParticleFX\\RED', 'Image1.png'),
                      load_sprite(GAMEPATH + 'ParticleFX\\RED', 'Image2.png'),
                      load_sprite(GAMEPATH + 'ParticleFX\\RED', 'Image3.png'),
                      load_sprite(GAMEPATH + 'ParticleFX\\RED', 'Image2.png'),
                      load_sprite(GAMEPATH + 'ParticleFX\\RED', 'Image3.png')]
i = 0
for surface in PARTICLE_TRAIL_RED:
    PARTICLE_TRAIL_RED[i] = pygame.transform.scale(surface, (50, 50))
    i += 1

PARTICLE_TRAIL_BLUE = [load_sprite(GAMEPATH + 'ParticleFX\\BLUE', 'Image1.png'),
                       load_sprite(GAMEPATH + 'ParticleFX\\BLUE', 'Image2.png'),
                       load_sprite(GAMEPATH + 'ParticleFX\\BLUE', 'Image3.png'),
                       load_sprite(GAMEPATH + 'ParticleFX\\BLUE', 'Image2.png'),
                       load_sprite(GAMEPATH + 'ParticleFX\\BLUE', 'Image3.png')]
i = 0
for surface in PARTICLE_TRAIL_BLUE:
    PARTICLE_TRAIL_BLUE[i] = pygame.transform.scale(surface, (50, 50))
    i += 1

PARTICLE_TRAIL_YELLOW = [load_sprite(GAMEPATH + 'ParticleFX\\YELLOW', 'Image1.png'),
                         load_sprite(GAMEPATH + 'ParticleFX\\YELLOW', 'Image2.png'),
                         load_sprite(GAMEPATH + 'ParticleFX\\YELLOW', 'Image3.png'),
                         load_sprite(GAMEPATH + 'ParticleFX\\YELLOW', 'Image2.png'),
                         load_sprite(GAMEPATH + 'ParticleFX\\YELLOW', 'Image3.png')]
i = 0
for surface in PARTICLE_TRAIL_YELLOW:
    PARTICLE_TRAIL_YELLOW[i] = pygame.transform.scale(surface, (50, 50))
    i += - 1

PARTICLE_TRAIL_PURPLE = [load_sprite(GAMEPATH + 'ParticleFX\\PURPLE', 'Image1.png'),
                         load_sprite(GAMEPATH + 'ParticleFX\\PURPLE', 'Image2.png'),
                         load_sprite(GAMEPATH + 'ParticleFX\\PURPLE', 'Image3.png'),
                         load_sprite(GAMEPATH + 'ParticleFX\\PURPLE', 'Image2.png'),
                         load_sprite(GAMEPATH + 'ParticleFX\\PURPLE', 'Image3.png')]
i = 0
for surface in PARTICLE_TRAIL_PURPLE:
    PARTICLE_TRAIL_PURPLE[i] = pygame.transform.scale(surface, (50, 50))
    i += 1

PARTICLE_TRAIL_GOLD = [load_sprite(GAMEPATH + 'ParticleFX\\GOLD', 'Image1.png'),
                       load_sprite(GAMEPATH + 'ParticleFX\\GOLD', 'Image2.png'),
                       load_sprite(GAMEPATH + 'ParticleFX\\GOLD', 'Image3.png'),
                       load_sprite(GAMEPATH + 'ParticleFX\\GOLD', 'Image2.png'),
                       load_sprite(GAMEPATH + 'ParticleFX\\GOLD', 'Image3.png')]
i = 0
for surface in PARTICLE_TRAIL_GOLD:
    PARTICLE_TRAIL_GOLD[i] = pygame.transform.scale(surface, (50, 50))
    i += 1
"""
"""
sheet = SpriteSheet(GAMEPATH + 'Fx\\', 'Blue_Sprite_FX2.png', 32, BLACK)
ELECTRIC_DISCHARGE = []
for column in range(8):
    ELECTRIC_DISCHARGE.append([column * 128, 0, 128, 512])
ELECTRIC_DISCHARGE_SPRITE_GREEN = sheet.images_at(ELECTRIC_DISCHARGE)
i = 0
for surface in ELECTRIC_DISCHARGE_SPRITE_GREEN:
    ELECTRIC_DISCHARGE_SPRITE_GREEN[i] = pygame.transform.smoothscale(surface, (20, SCREENRECT.h))
    i += 1
del i
sheet = SpriteSheet(GAMEPATH + 'Fx\\', 'Red_Sprite_FX2.png', 32, BLACK)
ELECTRIC_DISCHARGE = []
for column in range(8):
    ELECTRIC_DISCHARGE.append([column * 128, 0, 128, 512])
ELECTRIC_DISCHARGE_SPRITE_RED = sheet.images_at(ELECTRIC_DISCHARGE)
i = 0
for surface in ELECTRIC_DISCHARGE_SPRITE_RED:
    ELECTRIC_DISCHARGE_SPRITE_RED[i] = pygame.transform.smoothscale(surface, (20, SCREENRECT.h))
    i += 1
del i
sheet = SpriteSheet(GAMEPATH + 'Fx\\', 'Green_Sprite_FX2.png', 32, BLACK)
ELECTRIC_DISCHARGE = []
for column in range(8):
    ELECTRIC_DISCHARGE.append([column * 128, 0, 128, 512])
ELECTRIC_DISCHARGE_SPRITE_GREEN = sheet.images_at(ELECTRIC_DISCHARGE)
i = 0
for surface in ELECTRIC_DISCHARGE_SPRITE_GREEN:
    ELECTRIC_DISCHARGE_SPRITE_GREEN[i] = pygame.transform.smoothscale(surface, (20, SCREENRECT.h))
    i += 1
del i

"""

# ------------------------------------- ASTEROIDS --------------------------------------------
PATH = 'Assets\\Graphics\\Asteroids\\ANIMATED\\'
sheet = SpriteSheet(PATH, 'EPIMET_256x256.png', 24, BLACK)
EPIMET_ASTEROID_SPRITE = []
for row in range(5):
    for column in range(6):
        EPIMET_ASTEROID_SPRITE.append([column * 256, row * 256, 256, 256])
EPIMET_ASTEROID_SPRITE = sheet.images_at(EPIMET_ASTEROID_SPRITE)
OBJECT_MEMORY += sys.getsizeof(EPIMET_ASTEROID_SPRITE)

sheet = SpriteSheet(PATH, 'HYPERION_256x256.png', 24, BLACK)
HYPERION_ASTEROID_SPRITE = []
for row in range(5):
    for column in range(6):
        HYPERION_ASTEROID_SPRITE.append([column * 256, row * 256, 256, 256])
HYPERION_ASTEROID_SPRITE = sheet.images_at(HYPERION_ASTEROID_SPRITE)
OBJECT_MEMORY += sys.getsizeof(HYPERION_ASTEROID_SPRITE)

sheet = SpriteSheet(PATH, 'PROMETHEUS_256x256.png', 24, BLACK)
PROMETHEUS_ASTEROID_SPRITE = []
for row in range(5):
    for column in range(6):
        PROMETHEUS_ASTEROID_SPRITE.append([column * 256, row * 256, 256, 256])
PROMETHEUS_ASTEROID_SPRITE = sheet.images_at(PROMETHEUS_ASTEROID_SPRITE)
OBJECT_MEMORY += sys.getsizeof(PROMETHEUS_ASTEROID_SPRITE)

sheet = SpriteSheet(PATH, 'PROMETHEUS1_256x256.png', 24, BLACK)
PROMETHEUS1_ASTEROID_SPRITE = []
for row in range(5):
    for column in range(6):
        PROMETHEUS1_ASTEROID_SPRITE.append([column * 256, row * 256, 256, 256])
PROMETHEUS1_ASTEROID_SPRITE = sheet.images_at(PROMETHEUS1_ASTEROID_SPRITE)
OBJECT_MEMORY += sys.getsizeof(PROMETHEUS1_ASTEROID_SPRITE)

sheet = SpriteSheet(PATH, 'DEIMOS_512x512.png', 24, BLACK)
DEIMOS_ASTEROID_SPRITE = []
for row in range(5):
    for column in range(6):
        DEIMOS_ASTEROID_SPRITE.append([column * 512, row * 512, 512, 512])
DEIMOS_ASTEROID_SPRITE = sheet.images_at(DEIMOS_ASTEROID_SPRITE)
OBJECT_MEMORY += sys.getsizeof(DEIMOS_ASTEROID_SPRITE)

PATH = 'Assets\\Graphics\\Asteroids\\STATIC\\'
STATIC_ASTEROID_SPRITE = [convert_surface_to_24bit(PATH + 'Deimos.jpg', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'ENCELA.jpg', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'EPIMET.jpg', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'HYPERION.jpg', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'HYPERION1.jpg', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'JANUS.jpg', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'PROMETHE.jpg', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'DEIMOS_LAVA1.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'DEIMOS_LAVA2.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'DEIMOS_LAVA3.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'DEIMOS_LAVA4.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'DEIMOS_LAVA5.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'DEIMOS_LAVA6.png', pygame.Color(0, 0, 0, 0)),

                          convert_surface_to_24bit(PATH + 'ENCELA_LAVA1.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'ENCELA_LAVA2.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'ENCELA_LAVA3.png', pygame.Color(0, 0, 0, 0)),

                          convert_surface_to_24bit(PATH + 'EPIMET_LAVA1.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'EPIMET_LAVA2.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'EPIMET_LAVA3.png', pygame.Color(0, 0, 0, 0)),

                          convert_surface_to_24bit(PATH + 'HYPERION_LAVA1.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'HYPERION_LAVA2.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'HYPERION_LAVA3.png', pygame.Color(0, 0, 0, 0)),

                          convert_surface_to_24bit(PATH + 'HYPERION1_LAVA1.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'HYPERION1_LAVA2.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'HYPERION1_LAVA3.png', pygame.Color(0, 0, 0, 0)),

                          convert_surface_to_24bit(PATH + 'JANUS_LAVA1.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'JANUS_LAVA2.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'JANUS_LAVA3.png', pygame.Color(0, 0, 0, 0)),

                          convert_surface_to_24bit(PATH + 'PROMETHE_LAVA1.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'PROMETHE_LAVA2.png', pygame.Color(0, 0, 0, 0)),
                          convert_surface_to_24bit(PATH + 'PROMETHE_LAVA3.png', pygame.Color(0, 0, 0, 0))
                          ]
OBJECT_MEMORY += sys.getsizeof(STATIC_ASTEROID_SPRITE)
# ---------------------------------------------------------------------------------------------------------


# -------------------------------TIMELINE FX ---------------------------------------
# TimeLineFx explosions
PATH = 'Assets\\Graphics\\TimeLineFx\\Explosion\\'
EXPLOSION9 = spread_sheet_per_pixel(PATH + 'explosion1.png', 256, 7, 5)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION9)

# Player explosion
EXPLOSION10 = spread_sheet_per_pixel(PATH + 'explosion2_256x256_p.png', 256, 8, 8)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION10)

EXPLOSION11 = spread_sheet_per_pixel(PATH + 'small_explosion1_256x256.png', 256, 6, 6)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION11)

EXPLOSION12 = spread_sheet_per_pixel(PATH + 'Explosion1_256x256.png', 256, 8, 6)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION12)

EXPLOSION13 = spread_sheet_per_pixel(PATH + 'Explosion2_256x256.png', 256, 8, 6)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION13)

EXPLOSION14 = spread_sheet_per_pixel(PATH + 'Explosion3_256x256.png', 256, 8, 6)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION14)

EXPLOSION15 = spread_sheet_per_pixel(PATH + 'Explosion4_256x256.png', 256, 8, 6)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION15)

EXPLOSION16 = spread_sheet_per_pixel(PATH + 'Explosion5_256x256.png', 256, 8, 6)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION16)

# NOT IN USE
EXPLOSION17 = spread_sheet_per_pixel(PATH + 'Explosion6_256x256.png', 256, 4, 8)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION17)

EXPLOSION18 = spread_sheet_per_pixel(PATH + 'Explosion7_256x256.png', 256, 6, 3)
OBJECT_MEMORY += sys.getsizeof(EXPLOSION18)

SUPER_EXPLOSION = spread_sheet_per_pixel('Assets\\Graphics\\TimeLineFx\\Bomb\\SuperExplosion3_512x512.png', 512, 6, 6)
i_ = 0
for surface in SUPER_EXPLOSION:
    SUPER_EXPLOSION[i_] = pygame.transform.smoothscale(surface, (128, 128))
    i_ += 1
del i_
OBJECT_MEMORY += sys.getsizeof(SUPER_EXPLOSION)

EXPLOSIONS = []
EXPLOSIONS = [EXPLOSION9, EXPLOSION11, EXPLOSION12, EXPLOSION13, EXPLOSION14,
              EXPLOSION15, EXPLOSION16, EXPLOSION18]
del EXPLOSION9, EXPLOSION11, EXPLOSION12, EXPLOSION13, EXPLOSION14, EXPLOSION15, EXPLOSION16, EXPLOSION17, EXPLOSION18
OBJECT_MEMORY += sys.getsizeof(EXPLOSIONS)


MISSILE_EXPLOSION = spread_sheet_per_pixel(PATH + 'explosion3.png', 256, 4, 7)
i_ = 0
for surface in MISSILE_EXPLOSION:
    MISSILE_EXPLOSION[i_] = pygame.transform.smoothscale(surface, (128, 128))
    i_ += 1
del i_

# ------------------------------------------- LEVEL UP ----------------------------------------------------------------
# LEVEL UP
LEVEL_UP_5 = spread_sheet_per_pixel(
    'Assets\\Graphics\\TimeLineFx\\Level_up\\level_up_2_256x256.png', 256, rows_=6, columns_=6)
OBJECT_MEMORY += sys.getsizeof(LEVEL_UP_5)

# LEVEL UP MESSAGE
LEVEL_UP_MSG = load_per_pixel('Assets\\Graphics\\TimeLineFx\\Level_up\\levelup1.png')
LEVEL_UP_MSG = pygame.transform.smoothscale(LEVEL_UP_MSG,
                                            (LEVEL_UP_MSG.get_width() // 3, LEVEL_UP_MSG.get_height() // 3))
OBJECT_MEMORY += sys.getsizeof(LEVEL_UP_MSG)
# ---------------------------------------------------------------------------------------------------------------------

# -------------------------------------------- IMPACT /BURST ---------------------------------------------------------
# IMPACT BURST
BURST_DOWN_RED = spread_sheet_per_pixel('Assets\\Graphics\\TimeLineFx\\Burst\\BurstDown1_red_128x128.png', 128, 6, 6)
OBJECT_MEMORY += sys.getsizeof(BURST_DOWN_RED)

BURST_UP_RED = spread_sheet_per_pixel('Assets\\Graphics\\TimeLineFx\\Burst\\BurstUp2_128x128.png', 128, 7, 7)
OBJECT_MEMORY += sys.getsizeof(BURST_UP_RED)

# HOT MATTER WHEN OBJECT EXPLODE
BLAST1 = spread_sheet_per_pixel('Assets\\Graphics\\TimeLineFx\\Burst\\Blast2_128x128.png', 128, 6, 5)
i_ = 0
for surface in BLAST1:
    BLAST1[i_] = pygame.transform.smoothscale(surface, (16, 16))
    i_ += 1
del i_
OBJECT_MEMORY += sys.getsizeof(BLAST1)
# -------------------------------------------------------------------------------------------------------------------

# --------------------------------------------- RANKS ---------------------------------------------------------------
# RANKS = spread_sheet_per_pixel(GAMEPATH + 'Rank\\Ranks.png', 112, 10, 5)
# OBJECT_MEMORY += sys.getsizeof(RANKS)
# -------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------- ENERGY CELL ------------------------------------------------------
ENERGY_BOOSTER1 = spread_sheet_per_pixel('Assets\\Graphics\\TimeLineFx\\Energy cell\\EnergyBall4_64x64.png', 64, 6, 6)
OBJECT_MEMORY += sys.getsizeof(ENERGY_BOOSTER1)
# ------------------------------------------------------------------------------------------------------------------

# ----------------------------------------- SPACE ANOMALIES --------------------------------------------------------
PATH = 'Assets\\Graphics\\TimeLineFx\\Space Anomalies\\'
ANOMALY_1 = spread_sheet_per_pixel(PATH + 'AlienCloud1_256x256.png', 256, 6, 6)
ANOMALY_2 = spread_sheet_per_pixel(PATH + 'Anomaly_256x256.png', 256, 6, 6)
ANOMALY_3 = spread_sheet_per_pixel(PATH + 'Toxic_256x256.png', 256, 6, 6)
ANOMALY_4 = spread_sheet_per_pixel(PATH + 'ElectricArea_256x256.png', 256, 6, 6)
ANOMALY_5 = spread_sheet_per_pixel(PATH + 'SuperNova_128x128.png', 128, 12, 6)
OBJECT_MEMORY += sys.getsizeof(ANOMALY_1)
OBJECT_MEMORY += sys.getsizeof(ANOMALY_2)
OBJECT_MEMORY += sys.getsizeof(ANOMALY_3)
OBJECT_MEMORY += sys.getsizeof(ANOMALY_4)
OBJECT_MEMORY += sys.getsizeof(ANOMALY_5)
# ------------------------------------------------------------------------------------------------------------------

# ------------------------------------------- SUPER SHOT PARTICLES -------------------------------------------------
PATH = 'Assets\\Graphics\\TimeLineFx\\Particles\\'
PHOTON_PARTICLE_1 = spread_sheet_per_pixel(PATH + 'Particles_128x128.png', 128, 6, 6)
PHOTON_PARTICLE_2 = spread_sheet_per_pixel(PATH + 'Particles_7_128x128.png', 128, 6, 6)
PHOTON_PARTICLE_3 = spread_sheet_per_pixel(PATH + 'Particles_4_128x128.png', 128, 6, 6)
PHOTON_PARTICLE_4 = spread_sheet_per_pixel(PATH + 'Particles_2_128x128.png', 128, 6, 6)
PHOTON_PARTICLE_5 = spread_sheet_per_pixel(PATH + 'Particles_5_128x128.png', 128, 6, 6)
PHOTON_PARTICLE_6 = spread_sheet_per_pixel(PATH + 'Particles_8_128x128.png', 128, 6, 6)
PHOTON_PARTICLE_7 = spread_sheet_per_pixel(PATH + 'Particles_6_128x128.png', 128, 6, 6)
OBJECT_MEMORY += sys.getsizeof(PHOTON_PARTICLE_1)
OBJECT_MEMORY += sys.getsizeof(PHOTON_PARTICLE_2)
OBJECT_MEMORY += sys.getsizeof(PHOTON_PARTICLE_3)
OBJECT_MEMORY += sys.getsizeof(PHOTON_PARTICLE_4)
OBJECT_MEMORY += sys.getsizeof(PHOTON_PARTICLE_5)
OBJECT_MEMORY += sys.getsizeof(PHOTON_PARTICLE_6)
OBJECT_MEMORY += sys.getsizeof(PHOTON_PARTICLE_7)

# ------------------------------------------------------------------------------------------------------------------


NUKE_EXOLOSION = spread_sheet_per_pixel('Assets\\Graphics\\TimeLineFx\\Bomb\\Bomb_4_512x512.png', 512, 8, 11)
OBJECT_MEMORY += sys.getsizeof(NUKE_EXOLOSION)
"""
# NUKE BOMB with texture 8 bit, MUCH FASTER BUT DEGRADE QUALITY
# MIGHT BE WORSE CONSIDERING
sheet = SpriteSheet('Assets\\Graphics\\TimeLineFx\\Bomb\\', 'Bomb_4_512x512_8bit.png', 8)
NUKE_EXOLOSION = []
for row in range(8):
    for column in range(11):
        NUKE_EXOLOSION.append([column * 512, row * 512, 512, 512])
NUKE_EXOLOSION = sheet.images_at(NUKE_EXOLOSION)

i = 0
for r in NUKE_EXOLOSION:
    NUKE_EXOLOSION[i] = pygame.transform.scale(r, (int(r.get_width() * 1), int(r.get_height() * 1)))
    # NUKE_EXOLOSION[i].set_alpha(220)
    i += 1
del i
"""

# ----------------------------------------------- BONUS -------------------------------------------------------------
NUKE_BONUS = spread_sheet_per_pixel('Assets\\Graphics\\Bonus\\3ds\\NUKEBONUS_32x32.png', 32, 10, 10)
zoom1 = numpy.linspace(1, 1.2, len(NUKE_BONUS) // 2)
zoom2 = numpy.linspace(1.2, 1, len(NUKE_BONUS) // 2)
zoom = [*zoom1, *zoom2]
i = 0
for surface in NUKE_BONUS:
    NUKE_BONUS[i] = pygame.transform.rotozoom(surface, 0, zoom[i])
    i += 1
del (i, zoom, zoom1, zoom2)
OBJECT_MEMORY += sys.getsizeof(NUKE_BONUS)
# ---------------------------------------------------------------------------------------------------------------------

# ------------------------------- HALO --------------------------------------------------------------------------------
# ORANGE HALO
HALO_SPRITE8 = []
HALO_SPRITE8_ = load_per_pixel('Assets\\Graphics\\Halo\\halo6.png')
steps = numpy.arange(0, 1, 1 / 30)
for number in range(30):
    # Blend red
    surface = blend_texture(HALO_SPRITE8_, steps[number], pygame.Color(250, 10, 15, 255))
    rgb = pygame.surfarray.array3d(surface)
    alpha = pygame.surfarray.array_alpha(surface)
    surface = add_transparency_all(rgb, alpha, int(255 * steps[number] / 2))
    surface1 = pygame.transform.smoothscale(surface, (
        int(surface.get_width() * (1 + (number / 15))),
        int(surface.get_height() * (1 + (number / 15)))))
    HALO_SPRITE8.append(surface1)
del HALO_SPRITE8_
OBJECT_MEMORY += sys.getsizeof(HALO_SPRITE8)

# Red halo with blue color fading
HALO_SPRITE9 = []
HALO_SPRITE9_ = load_per_pixel('Assets\\Graphics\\Halo\\halo6.png')
for number in range(30):
    # Blend blue
    surface = blend_texture(HALO_SPRITE9_, steps[number], pygame.Color(0, 116, 255, 255))
    rgb = pygame.surfarray.array3d(surface)
    alpha = pygame.surfarray.array_alpha(surface)
    image = add_transparency_all(rgb, alpha, 0)
    surface1 = pygame.transform.smoothscale(image, (
        int(surface.get_width() * (1 + (number / 10))),
        int(surface.get_height() * (1 + (number / 10)))))
    HALO_SPRITE9.append(surface1)
del HALO_SPRITE9_
OBJECT_MEMORY += sys.getsizeof(HALO_SPRITE9)
"""
# Special effect for halo
HALO_SPRITE10 = spread_sheet_per_pixel(GAMEPATH + 'Flame_explosions\\TimeLineFX\\Halo\\halo2_512x512.png', 512, 5, 6)
for number in range(30):
    # Blend blue
    # surface = blend_texture(HALO_SPRITE10[number], steps[number], pygame.Color(0, 116, 255, 255))
    rgb = pygame.surfarray.array3d(HALO_SPRITE10[number])
    alpha = pygame.surfarray.array_alpha(HALO_SPRITE10[number])
    image = add_transparency_all(rgb, alpha, number)
    # image size is x2 (last sprite)
    surface1 = pygame.transform.smoothscale(image, (
        int(image.get_width() * (1 + (number / 30))),
        int(image.get_height() * (1 + (number / 30)))))
    HALO_SPRITE10[number] = surface1
"""

# ------------------------------------ EXPLOSION HALO-------------------------------------------------------------------
# YELLOWISH
HALO_SPRITE11 = [pygame.transform.smoothscale(
    load_per_pixel('Assets\\Graphics\\Halo\\Halo10.png'), (64, 64))] * 30
for number in range(len(HALO_SPRITE11)):
    rgb = pygame.surfarray.array3d(HALO_SPRITE11[number])
    alpha = pygame.surfarray.array_alpha(HALO_SPRITE11[number])
    image = add_transparency_all(rgb, alpha, int(255 * steps[number]))
    # image size is x2 (last sprite)
    surface1 = pygame.transform.smoothscale(image, (
        int(image.get_width() * (1 + (number / 10))),
        int(image.get_height() * (1 + (number / 10)))))
    HALO_SPRITE11[number] = surface1
OBJECT_MEMORY += sys.getsizeof(HALO_SPRITE11)

# REDISH
HALO_SPRITE12 = [pygame.transform.smoothscale(
    load_per_pixel('Assets\\Graphics\\Halo\\Halo11.png'), (64, 64))] * 30
for number in range(len(HALO_SPRITE12)):
    rgb = pygame.surfarray.array3d(HALO_SPRITE12[number])
    alpha = pygame.surfarray.array_alpha(HALO_SPRITE12[number])
    image = add_transparency_all(rgb, alpha, int(255 * steps[number]))
    # image size is x2 (last sprite)
    surface1 = pygame.transform.smoothscale(image, (
        int(image.get_width() * (1 + (number / 10))),
        int(image.get_height() * (1 + (number / 10)))))
    HALO_SPRITE12[number] = surface1
OBJECT_MEMORY += sys.getsizeof(HALO_SPRITE12)

# CLOUDLY YELLOWSH
HALO_SPRITE13 = [pygame.transform.smoothscale(
    load_per_pixel('Assets\\Graphics\\Halo\\Halo12.png'), (64, 64))] * 30
for number in range(len(HALO_SPRITE13)):
    rgb = pygame.surfarray.array3d(HALO_SPRITE13[number])
    alpha = pygame.surfarray.array_alpha(HALO_SPRITE13[number])
    image = add_transparency_all(rgb, alpha, int(255 * steps[number]))
    # image size is x2 (last sprite)
    surface1 = pygame.transform.smoothscale(image, (
        int(image.get_width() * (1 + (number / 10))),
        int(image.get_height() * (1 + (number / 10)))))
    HALO_SPRITE13[number] = surface1
OBJECT_MEMORY += sys.getsizeof(HALO_SPRITE13)

# PURPLE
HALO_SPRITE14 = [pygame.transform.smoothscale(
    load_per_pixel('Assets\\Graphics\\Halo\\Halo13.png'), (64, 64))] * 30
for number in range(len(HALO_SPRITE14)):
    rgb = pygame.surfarray.array3d(HALO_SPRITE14[number])
    alpha = pygame.surfarray.array_alpha(HALO_SPRITE14[number])
    image = add_transparency_all(rgb, alpha, int(255 * steps[number]))
    # image size is x2 (last sprite)
    surface1 = pygame.transform.smoothscale(image, (
        int(image.get_width() * (1 + (number / 10))),
        int(image.get_height() * (1 + (number / 10)))))
    HALO_SPRITE14[number] = surface1
OBJECT_MEMORY += sys.getsizeof(HALO_SPRITE14)

# ---------------------------------------------- HUD  ----------------------------------------------------------------
ENERGY_HUD = load_per_pixel('Assets\\Graphics\\Hud\\energyhud_275x80.png')
LIFE_HUD = load_per_pixel('Assets\\Graphics\\Hud\\lifehud_275x80.png')

# ENERGY_HUD = convert_surface_to_24bit(GAMEPATH + 'Hud\\energyhud_275x80.png', (0, 0, 0, 0))
# LIFE_HUD = convert_surface_to_24bit(GAMEPATH + 'Hud\\lifehud_275x80.png', (0, 0, 0, 0))
OBJECT_MEMORY += sys.getsizeof(ENERGY_HUD)
OBJECT_MEMORY += sys.getsizeof(LIFE_HUD)
# --------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------- MISSILES / NUKE ------------------------------------------------
# STINGER MISSILE
PATH = 'Assets\\Graphics\\Missiles\\Stinger\\'
STINGER_MISSILE_SPRITE = []
STINGER_MISSILE_SPRITE.append(load_per_pixel(PATH + 'MISSILE0.png'))
OBJECT_MEMORY += sys.getsizeof(STINGER_MISSILE_SPRITE)

# Hornet missile sprite
HORNET_MISSILE_SPRITE = load_per_pixel('Assets\\Graphics\\Missiles\\Hornet\\Hornet_32x32.png')
OBJECT_MEMORY += sys.getsizeof(HORNET_MISSILE_SPRITE)

# Nuke missile/bomb sprite
NUKE_BOMB_SPRITE = load_per_pixel('Assets\\Graphics\\Missiles\\Nuke\\Nuke_32x32.png')
NUKE_BOMB_INVENTORY = convert_surface_to_24bit('Assets\\Graphics\\Missiles\\Nuke\\3Nukes.png')
OBJECT_MEMORY += sys.getsizeof(NUKE_BOMB_SPRITE)
OBJECT_MEMORY += sys.getsizeof(NUKE_BOMB_INVENTORY)

MISSILE_INVENTORY = convert_surface_to_24bit('Assets\\Graphics\\Missiles\\Missile_inventory.png')
OBJECT_MEMORY += sys.getsizeof(MISSILE_INVENTORY)
# ---------------------------------------------------------------------------------------------------------------------

# Particle for missile trail
MISSILE_TRAIL = spread_sheet_per_pixel('Assets\\Graphics\\Missiles\\Particles_13_128x128.png', 128, 6, 5)
i = 0
for surface in MISSILE_TRAIL:
    MISSILE_TRAIL[i] = pygame.transform.smoothscale(surface, (20, 20))
    i += 1
del i
OBJECT_MEMORY += sys.getsizeof(MISSILE_TRAIL)

# Target sprite (circle surrounding an object)
MISSILE_TARGET_SPRITE = spread_sheet_per_pixel('Assets\\Graphics\\Missiles\\target_64x64.png', 64, 8, 12)
OBJECT_MEMORY += sys.getsizeof(MISSILE_TARGET_SPRITE)

# ----------------------------------------------- GEMS ----------------------------------------------------------------
x = 15
y = 15
# Size change according to value
GEM_SPRITES = []
for i in range(1, 21):

    GEM_SPRITES.append(pygame.transform.smoothscale(load_surface_32bit_alpha('Assets\\Graphics\\Gems\\',
                                                                             'Gem' + str(i) + '.png'), (x, y)))
    if i % 2:
        x += 1
        y += 1
del (x, y)
OBJECT_MEMORY += sys.getsizeof(GEM_SPRITES)

"""
# 24 bit version
GEM_SPRITES = []
for i in range(1, 21):

    GEM_SPRITES.append(pygame.transform.smoothscale(convert_surface_to_24bit(
        GAMEPATH + 'Gems\\Gem' + str(i) + '.png', BLACK), (x, y)))

    if i % 2:
        x += 1
        y += 1
del (x, y)
"""
# ---------------------------------------------------------------------------------------------------------------------

# EXHAUST_SPRITE = spread_sheet_per_pixel(GAMEPATH + 'Flame_explosions\\TimeLineFx\\Exhaust1_32x32.png', 32, 5, 8)

EXHAUST1_SPRITE = [load_per_pixel('Assets\\Graphics\\Exhaust\\1\\0001.png'),
                   load_per_pixel('Assets\\Graphics\\Exhaust\\1\\0002.png'),
                   load_per_pixel('Assets\\Graphics\\Exhaust\\1\\0003.png'),
                   load_per_pixel('Assets\\Graphics\\Exhaust\\1\\0004.png'),
                   load_per_pixel('Assets\\Graphics\\Exhaust\\1\\0005.png'),
                   load_per_pixel('Assets\\Graphics\\Exhaust\\1\\0006.png'),
                   load_per_pixel('Assets\\Graphics\\Exhaust\\1\\0007.png')]
i = 0
for surface in EXHAUST1_SPRITE:
    # flip the surfaces vertically
    surface = pygame.transform.smoothscale(surface, (35, 35))
    EXHAUST1_SPRITE[i] = pygame.transform.flip(surface, False, True)
    i += 1
del i
OBJECT_MEMORY += sys.getsizeof(EXHAUST1_SPRITE)


TURRET_SPRITE = load_per_pixel('Assets\\Graphics\\Turret\\turret3.png')
TURRET_SPRITE = pygame.transform.smoothscale(TURRET_SPRITE, (40, 40))
OBJECT_MEMORY += sys.getsizeof(TURRET_SPRITE)

TESLA_BLUE_SPRITE = spread_sheet_per_pixel(
    'Assets\\Graphics\\Tesla\\2\\teslaColor_blue_h.png', 101, 1, 12, True, 101, 228)
i = 0
for r in TESLA_BLUE_SPRITE:
    TESLA_BLUE_SPRITE[i] = pygame.transform.smoothscale(r, (40, 500))  # (20, 228)
    i += 1
del i
OBJECT_MEMORY += sys.getsizeof(TESLA_BLUE_SPRITE)

# Create a Tesla field around the target
BEAM_FIELD = load_per_pixel('Assets\\Graphics\\Shield\\subparts2\\8.png')
BEAM_FIELD = [BEAM_FIELD] * 200
# todo * 200 is a huge amount check why?

i = 0
rotation = 0
rotation_steps = 360 / len(BEAM_FIELD)
zoom1 = numpy.linspace(1, 2, len(BEAM_FIELD))
steps = numpy.linspace(0, 1, len(BEAM_FIELD))
for surface in BEAM_FIELD:
    surface = pygame.transform.smoothscale(surface, (250, 250))  # surface unchanged
    surface = blend_texture(surface, steps[i], pygame.Color(255, 10, 15, 255))
    BEAM_FIELD[i] = pygame.transform.rotozoom(surface, rotation, zoom1[i])
    i += 1
    rotation += rotation_steps
del (i, rotation)
OBJECT_MEMORY += sys.getsizeof(BEAM_FIELD)

# Create a Tesla impact sprite
TESLA_IMPACT = spread_sheet_per_pixel('Assets\\Graphics\\Tesla\\Eletric_Impact_128x128.png', 128, 5, 5)
OBJECT_MEMORY += sys.getsizeof(TESLA_IMPACT)

SHIELD_ELECTRIC_ARC = spread_sheet_per_pixel('Assets\\Graphics\\Tesla\\teslaColor_natural_h.png',
                                             101, 1, 12, True, 101, 228)
OBJECT_MEMORY += sys.getsizeof(SHIELD_ELECTRIC_ARC)

PATH = 'Assets\\Graphics\\Shield\\roundShield2\\'
ROUND_SHIELD_2 = [load_per_pixel(PATH + '001.png'),
                  load_per_pixel(PATH + '002.png'),
                  load_per_pixel(PATH + '003.png'),
                  load_per_pixel(PATH + '004.png'),
                  load_per_pixel(PATH + '005.png'),
                  load_per_pixel(PATH + '006.png'),
                  load_per_pixel(PATH + '007.png'),
                  load_per_pixel(PATH + '008.png')]
OBJECT_MEMORY += sys.getsizeof(ROUND_SHIELD_2)

PATH = 'Assets\\Graphics\\Shield\\roundShield1\\'
ROUND_SHIELD_1 = [*[load_per_pixel(PATH + '001.png')] * 10,
                  *[load_per_pixel(PATH + '002.png')] * 10,
                  *[load_per_pixel(PATH + '003.png')] * 10,
                  *[load_per_pixel(PATH + '004.png')] * 10,
                  *[load_per_pixel(PATH + '005.png')] * 10,
                  *[load_per_pixel(PATH + '006.png')] * 10,
                  *[load_per_pixel(PATH + '007.png')] * 10,
                  *[load_per_pixel(PATH + '008.png')] * 10]
OBJECT_MEMORY += sys.getsizeof(ROUND_SHIELD_1)

SHIELD_SOFT_GREEN = load_per_pixel('Assets\\Graphics\\Shield\\ShieldSoft\\shieldSoft1.png')
rgb = pygame.surfarray.array3d(SHIELD_SOFT_GREEN)
alpha = pygame.surfarray.array_alpha(SHIELD_SOFT_GREEN)
SHIELD_SOFT_GREEN = add_transparency_all(rgb, alpha, 15)
OBJECT_MEMORY += sys.getsizeof(SHIELD_SOFT_GREEN)
del rgb, alpha

SHIELD_SOFT_RED = load_per_pixel('Assets\\Graphics\\Shield\\shield_pattern\\shield1.png')
SHIELD_SOFT_RED = black_blanket_surface(SHIELD_SOFT_RED, 0, 3)
rgb = pygame.surfarray.array3d(SHIELD_SOFT_RED)
alpha = pygame.surfarray.array_alpha(SHIELD_SOFT_RED)
SHIELD_SOFT_RED = add_transparency_all(rgb, alpha, 15)
OBJECT_MEMORY += sys.getsizeof(SHIELD_SOFT_RED)
del rgb, alpha

# shield glow
SHIELD_GLOW = []
SHIELD_GLOW_ = load_per_pixel('Assets\\Graphics\\Shield\\ShieldSoft\\shieldSoft9.png')

steps = numpy.arange(0, 1, 1 / 30)
for number in range(30):
    # Blend green
    surface = blend_texture(SHIELD_GLOW_, steps[number], pygame.Color(0, 255, 10, 255))
    rgb = pygame.surfarray.array3d(surface)
    alpha = pygame.surfarray.array_alpha(surface)
    image = add_transparency_all(rgb, alpha, int(255 * steps[number]))
    surface1 = pygame.transform.smoothscale(image, (
        int((surface.get_width() // 7) * (1 + (number / 10))),
        int((surface.get_height() // 7) * (1 + (number / 10)))))
    SHIELD_GLOW.append(surface1)
OBJECT_MEMORY += sys.getsizeof(SHIELD_GLOW)
del SHIELD_GLOW_

SHIELD_GLOW_RED = []
SHIELD_GLOW_RED_ = load_per_pixel('Assets\\Graphics\\Shield\\ShieldHard\\shieldhard5.png')
steps = numpy.arange(0, 1, 1 / 30)
for number in range(30):
    rgb = pygame.surfarray.array3d(SHIELD_GLOW_RED_)
    alpha = pygame.surfarray.array_alpha(SHIELD_GLOW_RED_)
    image = add_transparency_all(rgb, alpha, int(255 * steps[number]))
    surface1 = pygame.transform.smoothscale(image, (
        int((SHIELD_GLOW_RED_.get_width() // 7) * (1 + (number / 10))),
        int((SHIELD_GLOW_RED_.get_height() // 7) * (1 + (number / 10)))))
    SHIELD_GLOW_RED.append(surface1)
OBJECT_MEMORY += sys.getsizeof(SHIELD_GLOW_RED)
del SHIELD_GLOW_RED_


def rot_center(image_: pygame.Surface, angle_: (int, float), rect_) -> (pygame.Surface, pygame.Rect):
    """rotate an image while keeping its center and size (only for symmetric surface)"""
    assert isinstance(image_, pygame.Surface), \
        ' Expecting pygame surface for argument image_, got %s ' % type(image_)
    assert isinstance(angle_, (int, float)), \
        'Expecting int or float for argument angle_ got %s ' % type(angle_)
    new_image = pygame.transform.rotozoom(image_, angle_, 1)
    return new_image, new_image.get_rect(center=rect_.center)


zoom1 = numpy.linspace(1, 1.2, len(ROUND_SHIELD_1) // 2)
zoom2 = numpy.linspace(1.2, 1, len(ROUND_SHIELD_1) // 2)
zoom = [*zoom1, *zoom2]
rotation_steps = 4.5
rotation = 0
i = 0
# Re-scale to 150x150
for surface in ROUND_SHIELD_1:
    # surface = pygame.transform.flip(surface, False, True)
    ROUND_SHIELD_1[i] = pygame.transform.smoothscale(surface,
                                                     (150, 150))
    i += 1
del i

transparency1 = numpy.linspace(50, 120, len(ROUND_SHIELD_1) // 2)
transparency2 = numpy.linspace(119, 50, len(ROUND_SHIELD_1) // 2)
transparency = [*transparency1, *transparency2]
i = 0
# variable transparency and scaling
for surface in ROUND_SHIELD_1:
    # ROUND_SHIELD_1[i] = rot_center(surface, rotation, surface.get_rect())
    rgb = pygame.surfarray.array3d(surface)
    alpha = pygame.surfarray.array_alpha(surface)
    image = add_transparency_all(rgb, alpha, int(transparency[i]))
    ROUND_SHIELD_1[i] = pygame.transform.smoothscale(image,
                                                     (int(surface.get_width() * zoom[i]),
                                                      int(surface.get_height() * zoom[i])))

    rotation += rotation_steps
    i += 1
del (i, rotation_steps, rotation)

PATH ='Assets\\Graphics\\Shield\\Impact\\'
ROUND_SHIELD_IMPACT = [
    *[load_per_pixel(PATH + 'waves.png')] * 10,
    *[load_per_pixel(PATH + 'waves1.png')] * 10,
    *[load_per_pixel(PATH + 'waves2.png')] * 10,
    *[load_per_pixel(PATH + 'waves3.png')] * 10,
    *[load_per_pixel(PATH + 'waves4.png')] * 10,
    *[load_per_pixel(PATH + 'waves5.png')] * 10,
    *[load_per_pixel(PATH + 'waves6.png')] * 10]
i = 0
for surface in ROUND_SHIELD_IMPACT:
    ROUND_SHIELD_IMPACT[i] = pygame.transform.smoothscale(surface, (150, 150))
    i += 1
OBJECT_MEMORY += sys.getsizeof(ROUND_SHIELD_IMPACT)
del i

"""
SHIELD_BORDER_INDICATOR = pygame.transform.smoothscale(
    load_per_pixel(GAMEPATH + 'ShieldFx\\shieldFX2\\png\\chargebar\\border.png'), (130, 16))
SHIELD_METER_INDICATOR = pygame.transform.smoothscale(
    load_per_pixel(GAMEPATH + 'ShieldFx\\shieldFX2\\png\\chargebar\\meter.png'), (126, 12))
SHIELD_METER_MAX = pygame.transform.smoothscale(
    load_per_pixel(GAMEPATH + 'ShieldFx\\shieldFX2\\png\\chargebar\\txtMax.png'), (126, 12))
"""
# SHIELD_BORDER_INDICATOR = load_per_pixel(GAMEPATH + 'ShieldFx\\shieldFX2\\png\\chargebar\\border.png')

SHIELD_BORDER_INDICATOR = pygame.image.load('Assets\\Graphics\\Shield\\chargebar\\border1.png')
SHIELD_BORDER_INDICATOR = pygame.transform.smoothscale(SHIELD_BORDER_INDICATOR,
                                                       (SHIELD_BORDER_INDICATOR.get_width() // 2,
                                                        SHIELD_BORDER_INDICATOR.get_height() // 2))
OBJECT_MEMORY += sys.getsizeof(SHIELD_BORDER_INDICATOR)

SHIELD_METER_INDICATOR = load_per_pixel('Assets\\Graphics\\Shield\\chargebar\\meter.png')
SHIELD_METER_INDICATOR = pygame.transform.smoothscale(SHIELD_METER_INDICATOR,
                                                      (SHIELD_METER_INDICATOR.get_width() // 2,
                                                       SHIELD_METER_INDICATOR.get_height() // 2))
OBJECT_MEMORY += sys.getsizeof(SHIELD_METER_INDICATOR)

SHIELD_METER_MAX = load_per_pixel('Assets\\Graphics\\Shield\\chargebar\\txtMax.png')
OBJECT_MEMORY += sys.getsizeof(SHIELD_METER_MAX)

FIRE = PHOTON_PARTICLE_1.copy()
i = 0
for surface in FIRE:
    FIRE[i] = pygame.transform.scale(surface, (24, 24))
    i += 1
OBJECT_MEMORY += sys.getsizeof(FIRE)

# ---------------------------------------------------- SHIELD HEAT GLOW -----------------------------------------------

SHIELD_HEATGLOW = load_per_pixel('Assets\\Graphics\\Shield\\HeatGlow\\heatglow.png')
# adjust size
SHIELD_HEATGLOW = pygame.transform.smoothscale(SHIELD_HEATGLOW, (128, 128))
SHIELD_HEATGLOW = [SHIELD_HEATGLOW] * 35
# transparency1 = numpy.linspace(255, 0, 10)
# transparency2 = numpy.linspace(0, 255, 10)
# transparency = [*transparency1, *[0] * 15, *transparency2]
# print (transparency)
transparency = numpy.linspace(255, 0, 35)
i = 0
# add transparency effect
for surface in SHIELD_HEATGLOW:
    rgb = pygame.surfarray.array3d(surface)
    alpha = pygame.surfarray.array_alpha(surface)
    SHIELD_HEATGLOW[i] = add_transparency_all(rgb, alpha, int(transparency[i]))
    i += 1
del i
size0 = numpy.linspace(10, 128, 10)
size1 = numpy.linspace(128, 5, 10)
size = [*size0, *[128] * 15, *size1]
i = 0
# change size overtime
for surface in SHIELD_HEATGLOW:
    SHIELD_HEATGLOW[i] = pygame.transform.smoothscale(surface, (int(size[i]), int(size[i])))
    i += 1
del i
OBJECT_MEMORY += sys.getsizeof(SHIELD_HEATGLOW)

# ------------------------------------------- SHIELD DISRUPTION -------------------------------- ---------------------

SHIELD_DISTUPTION_1 = spread_sheet_per_pixel(
    'Assets\\Graphics\\Shield\\Disruption\\disruption1_128x128.png', 128, 6, 6)
OBJECT_MEMORY += sys.getsizeof(SHIELD_DISTUPTION_1)

# ---------------------- DAMAGE CONTROL -----------------------
DAMAGE_CONTROL_128x128 = spread_sheet_per_pixel('Assets\\Graphics\\Hud\\control2_128x128.png', 128, 5, 6)
DAMAGE_CONTROL_64x64 = spread_sheet_per_pixel('Assets\\Graphics\\Hud\\control3_64x64.png', 64, 5, 6)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_CONTROL_128x128)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_CONTROL_64x64)

PATH = 'Assets\\Graphics\\SpaceShip\\Damages\\'
DAMAGE_LEFT_WING = spread_sheet_per_pixel(PATH + 'Left_wing\\SpaceShip.png', 64, 1, 3, True, 64, 72)
DAMAGE_LEFT_WING_YELLOW = DAMAGE_LEFT_WING[0]
DAMAGE_LEFT_WING_ORANGE = DAMAGE_LEFT_WING[1]
DAMAGE_LEFT_WING_RED = DAMAGE_LEFT_WING[2]
OBJECT_MEMORY += sys.getsizeof(DAMAGE_LEFT_WING_YELLOW)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_LEFT_WING_ORANGE)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_LEFT_WING_RED)
del DAMAGE_LEFT_WING

DAMAGE_RIGHT_WING = spread_sheet_per_pixel(PATH + 'Right_wing\\SpaceShip.png', 64, 1, 3, True, 64, 72)
DAMAGE_RIGHT_WING_YELLOW = DAMAGE_RIGHT_WING[0]
DAMAGE_RIGHT_WING_ORANGE = DAMAGE_RIGHT_WING[1]
DAMAGE_RIGHT_WING_RED = DAMAGE_RIGHT_WING[2]
OBJECT_MEMORY += sys.getsizeof(DAMAGE_RIGHT_WING_YELLOW)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_RIGHT_WING_ORANGE)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_RIGHT_WING_RED)
del DAMAGE_RIGHT_WING

DAMAGE_NOSE = spread_sheet_per_pixel(PATH + 'Nose\\SpaceShip.png', 64, 1, 3, True, 64, 72)
DAMAGE_NOSE_YELLOW = DAMAGE_NOSE[0]
DAMAGE_NOSE_ORANGE = DAMAGE_NOSE[1]
DAMAGE_NOSE_RED = DAMAGE_NOSE[2]
OBJECT_MEMORY += sys.getsizeof(DAMAGE_NOSE_YELLOW)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_NOSE_ORANGE)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_NOSE_RED)
del DAMAGE_NOSE

DAMAGE_LEFT_ENGINE = spread_sheet_per_pixel(PATH + 'Engine_left\\SpaceShip.png', 64, 1, 3, True, 64, 72)
DAMAGE_LEFT_ENGINE_YELLOW = DAMAGE_LEFT_ENGINE[0]
DAMAGE_LEFT_ENGINE_ORANGE = DAMAGE_LEFT_ENGINE[1]
DAMAGE_LEFT_ENGINE_RED = DAMAGE_LEFT_ENGINE[2]
OBJECT_MEMORY += sys.getsizeof(DAMAGE_LEFT_ENGINE_YELLOW)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_LEFT_ENGINE_ORANGE)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_LEFT_ENGINE_RED)
del DAMAGE_LEFT_ENGINE

DAMAGE_RIGHT_ENGINE = spread_sheet_per_pixel(PATH + 'Engine_right\\SpaceShip.png', 64, 1, 3, True, 64, 72)
DAMAGE_RIGHT_ENGINE_YELLOW = DAMAGE_RIGHT_ENGINE[0]
DAMAGE_RIGHT_ENGINE_ORANGE = DAMAGE_RIGHT_ENGINE[1]
DAMAGE_RIGHT_ENGINE_RED = DAMAGE_RIGHT_ENGINE[2]
OBJECT_MEMORY += sys.getsizeof(DAMAGE_RIGHT_ENGINE_YELLOW)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_RIGHT_ENGINE_ORANGE)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_RIGHT_ENGINE_RED)
del DAMAGE_RIGHT_ENGINE

DAMAGE_NONE = load_per_pixel(PATH + 'SpaceShip_green.png')
DAMAGE_ALL = load_per_pixel(PATH + 'SpaceShip_red.png')
OBJECT_MEMORY += sys.getsizeof(DAMAGE_NONE)
OBJECT_MEMORY += sys.getsizeof(DAMAGE_ALL)
# -------------------------------------------------------------------------------------------------------

# Red rectangle (Turret target)
TURRET_TARGET_SPRITE = load_per_pixel('Assets\\Graphics\\Turret\\square.png')
TURRET_TARGET_SPRITE = pygame.transform.smoothscale(TURRET_TARGET_SPRITE, (256, 256))
OBJECT_MEMORY += sys.getsizeof(TURRET_TARGET_SPRITE)

COLLECTIBLES_AMMO = pygame.image.load('Assets\\Graphics\\Bullets\\Amunitions_icon.png').convert_alpha()
COLLECTIBLES_AMMO = pygame.transform.smoothscale(COLLECTIBLES_AMMO, (32, 32))
COLLECTIBLES_AMMO = [COLLECTIBLES_AMMO] * 60
zoom1 = numpy.linspace(1, 1.2, len(COLLECTIBLES_AMMO) // 2)
zoom2 = numpy.linspace(1.2, 1, len(COLLECTIBLES_AMMO) // 2)
zoom = [*zoom1, *zoom2]
angle = 0
i = 0
for surface in COLLECTIBLES_AMMO:
    COLLECTIBLES_AMMO[i] = pygame.transform.rotozoom(surface, 0, zoom[i])
    # angle += 12
    i += 1
del (i, angle, zoom, zoom1, zoom2)
OBJECT_MEMORY += sys.getsizeof(COLLECTIBLES_AMMO)


MUZZLE_FLASH = spread_sheet_per_pixel('Assets\\Graphics\\Muzzle flash\\MuzzleFlash_64x64.png', 64, 2, 4)
i = 0
for surface in MUZZLE_FLASH:
    MUZZLE_FLASH[i] = pygame.transform.smoothscale(surface, (32, 32))
    i += 1
del i
OBJECT_MEMORY += sys.getsizeof(MUZZLE_FLASH)


BRIGHT_LIGHT_BLUE = load_per_pixel('Assets\\Graphics\\Muzzle flash\\flareFX.png')
BRIGHT_LIGHT_BLUE = pygame.transform.smoothscale(BRIGHT_LIGHT_BLUE, (20, 20))
OBJECT_MEMORY += sys.getsizeof(BRIGHT_LIGHT_BLUE)

BRIGHT_LIGHT_RED = blend_texture(BRIGHT_LIGHT_BLUE, 0.8, (0, 255, 0, 255))
OBJECT_MEMORY += sys.getsizeof(BRIGHT_LIGHT_RED)

PATH = 'Assets\\Graphics\\Enemy\\'
# size 138x68
SPACE_FIGHTER_SPRITE = load_per_pixel(PATH + 'illumDefault11.png')
OBJECT_MEMORY += sys.getsizeof(SPACE_FIGHTER_SPRITE)

SCOUT_SPRITE = load_per_pixel(PATH + 'scout.png')
# INTERCEPTOR_SPRITE = load_per_pixel(GAMEPATH + '\\Shield_FX\\bonus\\illumRed19.png')
OBJECT_MEMORY += sys.getsizeof(SCOUT_SPRITE)

INTERCEPTOR_SPRITE = spread_sheet_per_pixel(PATH + 'illumRed.png', 106, 1, 5, True, 106, 135)
OBJECT_MEMORY += sys.getsizeof(INTERCEPTOR_SPRITE)

RAPTOR_EXPLODE = [
    load_per_pixel(PATH + '\\RaptorExplosion\\RaptorPart1_alpha.png'),
    load_per_pixel(PATH + '\\RaptorExplosion\\RaptorPart2_alpha.png'),
    load_per_pixel(PATH + '\\RaptorExplosion\\RaptorPart3_alpha.png'),
    load_per_pixel(PATH + '\\RaptorExplosion\\RaptorPart4_alpha.png'),
    load_per_pixel(PATH + '\\RaptorExplosion\\RaptorPart5_alpha.png')
]
OBJECT_MEMORY += sys.getsizeof(RAPTOR_EXPLODE)

NANO_BOTS_CLOUD = spread_sheet_per_pixel('Assets\\Graphics\\NanoBots\\NanoBots1_128x128_9_deg_elec.png', 128, 5, 8)
OBJECT_MEMORY += sys.getsizeof(NANO_BOTS_CLOUD)

# --------------------------------------------- SCREEN BLOOD STAINS -------------------------------------------------
blood_top = pygame.image.load('Assets\\Graphics\\BloodStain\\top.png').convert_alpha()
blood_left = pygame.image.load('Assets\\Graphics\\BloodStain\\left.png').convert_alpha()
blood_right = pygame.image.load('Assets\\Graphics\\BloodStain\\right.png').convert_alpha()
blood_bottom = pygame.image.load('Assets\\Graphics\\BloodStain\\bottom.png').convert_alpha()

BLOOD_SURFACE = [blood_top, blood_left, blood_right, blood_bottom]
del (blood_top, blood_left, blood_right, blood_bottom)
OBJECT_MEMORY += sys.getsizeof(BLOOD_SURFACE)


#-------------------------------- --------------- LASER BEAM  ---------------------------------------------------------
DEATHRAY_SPRITE_BLUE_ = []
for r in range(32):
    if r < 10:
        r = '0' + str(r)
    else:
        r = str(r)
    surface = pygame.Surface.convert_alpha(
        load_per_pixel(os.path.join('Assets\\Graphics\\Beam\\13\\' + r + '.png')))
    DEATHRAY_SPRITE_BLUE_.append(surface)


DEATHRAY_SPRITE_BLUE = []
for surface in DEATHRAY_SPRITE_BLUE_:
    s = pygame.transform.smoothscale(surface, (32, 14))
    DEATHRAY_SPRITE_BLUE.extend((s, s, s))
OBJECT_MEMORY += sys.getsizeof(DEATHRAY_SPRITE_BLUE)
del DEATHRAY_SPRITE_BLUE_

DEATHRAY_SHAFT = spread_sheet_per_pixel('Assets\\Graphics\\Beam\\Shaft2_128x128.png', 128, 8, 8)
OBJECT_MEMORY += sys.getsizeof(DEATHRAY_SHAFT)

print('MEMORY ', OBJECT_MEMORY)

if __name__ == '__main__':

    pass
