# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from __future__ import print_function

from PygameShader.shader import tunnel_render32, tunnel_modeling32, saturation, blur

def bytes_conversion(value_)->tuple:
    i = 0
    sc = { 0: "Bytes", 1: "KB", 2: "MB", 3: "GB", 4: "TB", 5: "PB"}
    sc_name = list(sc.values())
    while value_ >= 1000:
        value_ //= 1000
        i += 1
    return value_, sc_name[i]

from psutil import virtual_memory as vm
mem = vm().available
min_memory = 1.7 * 1e9
mem_diff = min_memory - mem
print('Mem available    : %s %s' % (bytes_conversion(vm().available)))
if mem < min_memory:
    raise MemoryError("\nInsufficient memory.\nCobra needs at least %s %s bytes of RAM to works."
                      "\nPlease try to release some memory from your system and try again.\n"
                      "You need at least %s %s to free.\n" %
                      (*bytes_conversion(min_memory), *bytes_conversion(mem_diff)))
    pygame.event.clear()
    pygame.display.quit()
    pygame.Quit()

from GaussianBlur5x5 cimport blur5x5_surface24_inplace_c

from bloom cimport bloom_effect_buffer32_c, bloom_effect_buffer24_c, bloom_effect_buffer32_c


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

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, linspace, ndarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

cimport numpy
from numpy cimport float64_t

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
    QUIT, K_SPACE, BLEND_RGB_ADD, Rect, BLEND_RGB_MAX
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha,\
        array3d, make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotate, flip, rotozoom
except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:/pip install pygame on a window command prompt.")


from SpriteSheet cimport sprite_sheet_fs8_alpha, sprite_sheet_per_pixel, sprite_sheet_fs8
from Tools cimport blend_texture_32c, make_transparent32, reshape, blend_texture_24c
from hsv_surface cimport hsv_surface32c
from libc.math cimport round
from Sounds import LOADING_SOUND
from pygame import fastevent
import time
import os
from os import path
import threading
from Constants import GL
from HorizontalBar import HorizontalBar


LOADING_SOUND.play(-1)
TIME = time.time()
pygame.display.init()
fastevent.init()

LOADING_BAR = HorizontalBar(start_color_=numpy.array([207, 161, 81, 0], dtype=uint8),
                            end_color_=numpy.array([203, 129, 0, 0], dtype=uint8),
                            maximum_=475,
                            minimum_=0,
                            current_value_=0,
                            alpha_=False, h_=30, w_=475, scan_=False)
LOADING_BAR.current_value = 0

cdef tuple BLACK = (0, 0, 0, 0)
cdef tuple WHITE = (255, 255, 255, 255)
cdef image_load = pygame.image.load
cdef str PATH = "Assets/Graphics/Laser_Fx/png/3 heavy/"

class LoadScreen(threading.Thread):
    my_event = None

    def __init__(self, sprite_, gl_):
        threading.Thread.__init__(self)

        # Set mode 800x800 for Tunnel rendering
        pygame.display.set_mode((800, 800))
        self.screen = pygame.display.get_surface()
        self.sprite = sprite_   # sprite to display
        self.index = 0          # sprite index
        self.event = LoadScreen.my_event     # event to stop the thread
        self.gl    = gl_

    def run(self):
        clock = pygame.time.Clock()
        # control the sharing of input devices with other applications
        # Lock all input into your program.
        # pygame.event.set_grab(False)
        pygame.display.init()
        frame = 0
        surf = pygame.image.load("Assets/space1.jpg")
        # BUILD THE TUNNEL 32BIT
        width, height = self.screen.get_width(), self.screen.get_height()
        distances, angles, shades, scr_data = tunnel_modeling32(width, height, surf) # compatible
        # version 1.0.9 only, surf)
        dest_array = numpy.empty((width * height * 4), numpy.uint8)

        while not LoadScreen.my_event.is_set():
            self.screen = pygame.display.get_surface()
            fastevent.pump()
            fastevent.get()
            pygame.event.get()
            # self.screen.fill((0, 0, 0))
            self.screen.blit(LOADING_IMAGE, (0, 0))
            im = self.sprite[self.index % (len(self.sprite) - 1)]
            _w, _h = im.get_size()
            self.screen.blit(im, (self.gl.screenrect.centerx - _w / 2,
                                  self.gl.screenrect.centery - _h / 2))
            self.index += 1
            bar = LOADING_BAR.display_gradient()

            _w, _h = LOADING_BAR_B.get_size()
            self.screen.blit(LOADING_BAR_B, (
                self.gl.screenrect.centerx - _w / 2 - 5, self.gl.screenrect.centery + 5 * _h - 2))
            self.screen.blit(bar, (self.gl.screenrect.centerx - _w / 2,
                                   self.gl.screenrect.centery + 5 * _h + 1))

            # Display the tunnel
            surface_ = tunnel_render32(
                frame * 25,
                width,
                height,
                width >> 1,
                height >> 1,
                distances,
                angles,
                shades,
                scr_data,
                dest_array
            )

            self.screen.blit(surface_, (0, 0), special_flags=BLEND_RGB_ADD)

            pygame.display.flip()
            clock.tick(self.gl.MAXFPS)
            frame += 1

        pygame.image.save(self.screen.convert(), 'Assets/Transition.png')
        del surf
        del self.screen
        del self.sprite

    def update(self):
        pygame.event.get()
        LOADING_BAR.current_value += 5 if LOADING_BAR.current_value < 470 else 0

        im = self.sprite[self.index % (len(self.sprite) - 1)]

        _w, _h = im.get_size()
        self.screen.blit(im, (self.gl.screenrect.centerx - _w / 2,
                              self.gl.screenrect.centery - _h / 2))
        self.index += 1




WAIT = sprite_sheet_per_pixel('Assets/Graphics/GUI/wait256x256.png', 256, 8, 8)
i =0
# Reduce size of the texture to save memory during loading
for image in WAIT:
    WAIT[i] = smoothscale(image, (128, 128))
    i += 1

LOADING_IMAGE = image_load('Assets/Graphics/background/space1.jpg').convert()
LOADING_IMAGE = smoothscale(LOADING_IMAGE, (800, 800))

LOADING_BAR_B = image_load('Assets/Graphics/GUI/Device/Loading_background.png').convert_alpha()
LOADING_BAR_B = pygame.transform.scale(LOADING_BAR_B, (475, 34))

LOADING_BAR.current_value   = 2
LoadScreen.my_event = threading.Event()
LoadScreen.my_event.clear()
THREAD2 = LoadScreen(WAIT, GL)
THREAD2.start()


SHOOTING_STAR = image_load('Assets/Graphics/Background/shooting_star.png').convert()
SHOOTING_STAR = pygame.transform.scale(SHOOTING_STAR, (25, 80))


cdef path_join = os.path.join
# SUPER SHOT 24-BIT IMAGE WITHOUT PER-PIXEL TRANSPARENCY
SUPERSHOT_GREEN_LASER  = image_load(path_join(PATH, 'lzrfxHeavy01_.png')).convert()
SUPERSHOT_GREEN_LASER  = rotozoom(SUPERSHOT_GREEN_LASER, 90, 1)
SUPERSHOT_BLUE_LASER   = image_load(path_join(PATH, 'lzrfxHeavy02_.png')).convert()
SUPERSHOT_BLUE_LASER   = rotozoom(SUPERSHOT_BLUE_LASER, 90, 1)
SUPERSHOT_RED_LASER    = image_load(path_join(PATH, 'lzrfxHeavy03_.png')).convert()
SUPERSHOT_RED_LASER    = rotozoom(SUPERSHOT_RED_LASER, 90, 1)
SUPERSHOT_GOLD_LASER   = image_load(path_join(PATH, 'lzrfxHeavy05_.png')).convert()
SUPERSHOT_GOLD_LASER   = rotozoom(SUPERSHOT_GOLD_LASER, 90, 1)
SUPERSHOT_PURPLE_LASER = image_load(path_join(PATH, 'lzrfxHeavy06_.png')).convert()
SUPERSHOT_PURPLE_LASER = rotozoom(SUPERSHOT_PURPLE_LASER, 90, 1)
SUPERSHOT_YELLOW_LASER = image_load(path_join(PATH, 'lzrfxHeavy09_.png')).convert()
SUPERSHOT_YELLOW_LASER = rotozoom(SUPERSHOT_YELLOW_LASER, 90, 1)

PATH = "Assets/Graphics/Laser_Fx/png/1 basic/"

# PHOTON SHOT 24-BIT IMAGE WITHOUT PER-PIXEL TRANSPARENCY
GREEN_PHOTON  = image_load(path_join(PATH, 'lzrfx004_1.png')).convert()
GREEN_PHOTON  = rotozoom(GREEN_PHOTON, 90, 1)
PURPLE_PHOTON = image_load(path_join(PATH, 'lzrfx029_.png')).convert()
PURPLE_PHOTON = rotozoom(PURPLE_PHOTON, 90, 1)
GOLD_PHOTON   = image_load(path_join(PATH, 'lzrfx076_.png')).convert()
GOLD_PHOTON   = rotozoom(GOLD_PHOTON, 90, 1)
YELLOW_PHOTON = image_load(path_join(PATH, 'lzrfx077_.png')).convert()
YELLOW_PHOTON = rotozoom(YELLOW_PHOTON, 90, 1)
BLUE_PHOTON   = image_load(path_join(PATH, 'lzrfx089_.png')).convert()
BLUE_PHOTON   = rotozoom(BLUE_PHOTON, 90, 1)
RED_PHOTON    = image_load(path_join(PATH, 'lzrfx101_.png')).convert()
RED_PHOTON    = rotozoom(RED_PHOTON, 90, 1)

THREAD2.update()

PATH = 'Assets/Graphics/SpaceShip/'
SPACESHIP_SPRITE = image_load(path_join(PATH, 'SpaceShip.png')).convert_alpha()

LEVIATHAN        = image_load(path_join(PATH, 'Leviathan80x80.png')).convert_alpha()

if LEVIATHAN.get_height() == 0:
    raise ValueError("Surface Leviathan80x80.png is some way corrupted !")

ratio = LEVIATHAN.get_width() / LEVIATHAN.get_height()
LEVIATHAN        = smoothscale(LEVIATHAN, (<int>(<float>80.0 * ratio), 80))




ALL_SPACE_SHIP = {'NEMESIS': SPACESHIP_SPRITE, 'LEVIATHAN': LEVIATHAN}

# TODO REPLACE BY IMAGE BURST PROCESS ?
PATH = 'Assets/Graphics/SpaceShip/Explosion/Nemesis/'
SPACESHIP_EXPLODE_NEMESIS = [image_load(path_join(PATH, 'p1.png')).convert_alpha(),
                             image_load(path_join(PATH, 'p2.png')).convert_alpha(),
                             image_load(path_join(PATH, 'p3.png')).convert_alpha(),
                             image_load(path_join(PATH, 'p4.png')).convert_alpha(),
                             image_load(path_join(PATH, 'p5.png')).convert_alpha(),
                             image_load(path_join(PATH, 'p6.png')).convert_alpha()]
# TODO REPLACE BY IMAGE BURST PROCESS ?
PATH = 'Assets/Graphics/SpaceShip/Explosion/Nemesis/'
SPACESHIP_EXPLODE_LEVIATHAN = [image_load(path_join(PATH, 'p1.png')).convert_alpha(),
                               image_load(path_join(PATH, 'p2.png')).convert_alpha(),
                               image_load(path_join(PATH, 'p3.png')).convert_alpha(),
                               image_load(path_join(PATH, 'p4.png')).convert_alpha(),
                               image_load(path_join(PATH, 'p5.png')).convert_alpha()]

THREAD2.update()

SHOOTING_SPRITE = [RED_PHOTON, SUPERSHOT_RED_LASER,
                   BLUE_PHOTON, SUPERSHOT_BLUE_LASER,
                   PURPLE_PHOTON, SUPERSHOT_PURPLE_LASER,
                   GREEN_PHOTON, SUPERSHOT_GREEN_LASER,
                   YELLOW_PHOTON, SUPERSHOT_YELLOW_LASER,
                   GOLD_PHOTON, SUPERSHOT_GOLD_LASER,
                   image_load(
                       'Assets/Graphics/Laser_Fx/png/miscs/Green_laser_vertical.png'
                   ).convert_alpha(),
                   image_load("Assets/Graphics/Bullets/bullet3.png").convert_alpha(),
                   image_load("Assets/Graphics/Bullets/bullet2.png").convert_alpha()]

LEVIATHAN_SUPER_SHOT = sprite_sheet_fs8(
    'Assets/Graphics/Laser_Fx/png/miscs/Leviathan_super_64x128_growing_.png',
    64, 8, 4, True, (64, 128))


# MISCELLANEOUS LASERS
LASER_FX = [image_load('Assets/Graphics/Laser_Fx/png/1 basic/lzrfx001_.png').convert(),  # 0
            image_load('Assets/Graphics/Laser_Fx/png/3 heavy/lzrfxHeavy48_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/2 mixed/lzrfxMixed047_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/2 mixed/lzrfxMixed052_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/3 heavy/lzrfxHeavy32_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/1 basic/LZRFX074_1.png').convert(),  # 5
            image_load('Assets/Graphics/Laser_Fx/png/1 basic/LZRFX084_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/4 huge/lzrfxHuge25_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/3 heavy/lzrfxHeavy07_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/1 basic/lzrfx018_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/1 basic/lzrfx029_.png').convert(),  # 10
            image_load('Assets/Graphics/Laser_Fx/png/1 basic/lzrfx101_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/1 basic/lzrfx089_.png').convert(),  # 12
            image_load('Assets/Graphics/Laser_Fx/png/3 heavy/lzrfxHeavy12_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/1 basic/lzrfx039_.png').convert(),  # 14
            image_load('Assets/Graphics/Laser_Fx/png/miscs/DronePlasma_.png').convert(),
            image_load('Assets/Graphics/Laser_Fx/png/3 heavy/lzrfxHeavy31_.png').convert(),
            # green
            LEVIATHAN_SUPER_SHOT,  # 17
            image_load('Assets/Graphics/Laser_Fx/png/miscs/LongBlueLaser2_.png').convert(),
            # 18
            image_load('Assets/Graphics/Laser_Fx/png/3 heavy/lzrfxHeavy06_.png').convert()
            # 19
            ]



THREAD2.update()

PATH = "Assets/Graphics/Background/"
COSMIC_DUST1 = image_load(path_join(PATH, 'stars_.png')) # .convert_alpha()
COSMIC_DUST1 = smoothscale(COSMIC_DUST1, (2, 5))
COSMIC_DUST1.set_colorkey((0, 0, 0), RLEACCEL)

COSMIC_DUST2 = image_load(path_join(PATH, 'fx_.png')) # .convert_alpha()
COSMIC_DUST2 = smoothscale(COSMIC_DUST2, (4, 10))
COSMIC_DUST2.set_colorkey((0, 0, 0), RLEACCEL)

THREAD2.update()

PATH = 'Assets/Graphics/TimeLineFx/Explosion/'
EXPLOSION9 = sprite_sheet_fs8(path_join(PATH, 'explosion1_512x512m.png'), 512, 5, 7)
EXPLOSION1 = sprite_sheet_fs8(path_join(PATH, 'Explosion8_512x512_m.png'), 512, 6, 6)
EXPLOSION2 = sprite_sheet_fs8(path_join(PATH, 'Explosion9_512x512_m.png'), 512, 8, 6)

THREAD2.update()

EXPLOSION3 = sprite_sheet_fs8(path_join(PATH, 'Explosion10_256x256_.png'), 256, 7, 6)
EXPLOSION4 = sprite_sheet_fs8(path_join(PATH, 'Explosion11_256x256_.png'), 256, 7, 6)
EXPLOSION5 = sprite_sheet_fs8(path_join(PATH, 'Explosion12_256x256_.png'), 256, 7, 6)

THREAD2.update()

EXPLOSION6 = sprite_sheet_fs8(path_join(PATH, 'Explosion13_512x512_m.png'), 512, 7, 6)
EXPLOSION10 = sprite_sheet_fs8(path_join(PATH, 'explosion2_512x512_pm_.png'), 512, 8, 8)
EXPLOSION11 = sprite_sheet_fs8(path_join(PATH, 'small_explosion1_512x512_m.png'), 512, 6, 6)

THREAD2.update()

EXPLOSION12 = sprite_sheet_fs8(path_join(PATH, 'Explosion1_512x512m_.png'), 512, 6, 8)
EXPLOSION13 = sprite_sheet_fs8(path_join(PATH, 'Explosion2_512x512m_.png'), 512, 6, 8)
EXPLOSION14 = sprite_sheet_fs8(path_join(PATH, 'Explosion3_512x512m_.png'), 512, 6, 8)
THREAD2.update()

EXPLOSION15 = sprite_sheet_fs8(path_join(PATH, 'Explosion4_512x512m_.png'), 512, 6, 8)
EXPLOSION16 = sprite_sheet_fs8(path_join(PATH, 'Explosion5_512x512m_.png'), 512, 6, 8)

# EXPLOSION17 = sprite_sheet_fs8(path_join(PATH, 'Explosion6_256x256_.png'), 256, 8, 4)
EXPLOSION18 = sprite_sheet_fs8(path_join(PATH, 'Explosion7_512x512m_.png'), 512, 3, 4)


THREAD2.update()



SUPER_EXPLOSION = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Bomb/SuperExplosion3_512x512m_.png', 512, 6, 6)
SUPER_EXPLOSION = reshape(SUPER_EXPLOSION, (128, 128))

EXPLOSIONS = [EXPLOSION1, EXPLOSION2, EXPLOSION3, EXPLOSION4, EXPLOSION5, EXPLOSION6,
              EXPLOSION9, EXPLOSION11, EXPLOSION12, EXPLOSION13, EXPLOSION14,
              EXPLOSION15, EXPLOSION16, EXPLOSION18]


THREAD2.update()

EXPLOSION19 = sprite_sheet_fs8(path_join(PATH, 'Explosion16_512x512m_.png'), 512, 8, 6)

THREAD2.update()

MISSILE_EXPLOSION = sprite_sheet_fs8(path_join(PATH, 'explosion3m_.png'), 512, 7, 4)

THREAD2.update()

CRATERS = []
CRATERS0 = image_load("Assets/Graphics/TimeLineFx/Explosion/Crater3_.png").convert()
CRATERS0.set_colorkey((0, 0, 0, 0), RLEACCEL)
CRATERS0 = scale(CRATERS0, (90, 90))
CRATERS1 = image_load("Assets/Graphics/TimeLineFx/Explosion/Crater2_.png").convert()
CRATERS1.set_colorkey((0, 0, 0, 0), RLEACCEL)
CRATERS1 = scale(CRATERS1, (90, 90))
CRATERS2 = image_load("Assets/Graphics/TimeLineFx/Explosion/Crater1_.png").convert()
CRATERS2 = scale(CRATERS2, (90, 90))
CRATERS2.set_colorkey((0, 0, 0, 0), RLEACCEL)
a = [CRATERS0] * 1
b = [CRATERS1] * 2
c = [CRATERS2] * 5
CRATERS.extend([*a, *b, *c])

CRATER = image_load("Assets/Graphics/TimeLineFx/Explosion/Crater2_.png")
CRATER = smoothscale(CRATER, (32, 32)).convert_alpha()
CRATER_MASK = pygame.mask.from_surface(CRATER)
CRATER_COLD = image_load("Assets/Graphics/TimeLineFx/Explosion/Crater3_.png").convert()
CRATER_COLD = smoothscale(CRATER_COLD, (32, 32))


CRATER_SMOKE = sprite_sheet_fs8(
    "Assets/Graphics/TimeLineFx/Lava/Laval1_256_6x6_.png", 256, 6, 6)
CRATER_SMOKE = reshape(CRATER_SMOKE, (32, 32))

SMOKE = sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/smoke_.png', 128, 8, 8)
THREAD2.update()

# LEVEL UP MESSAGE
LEVEL_UP_MSG = image_load('Assets/Graphics/TimeLineFx/Level_up/levelup1_24.png').convert()
# LEVEL_UP_MSG = smoothscale(LEVEL_UP_MSG,
#                            (LEVEL_UP_MSG.get_width(), LEVEL_UP_MSG.get_height()))
LEVEL_UP_MSG_ = []
LEVEL_UP_MSG_APPEND = LEVEL_UP_MSG_.append

w, h = LEVEL_UP_MSG.get_size()
f = linspace(1, 4, 36)
for r in range(36):
    surface = smoothscale(LEVEL_UP_MSG, (int(w * f[r]), int(h * f[r])))
    LEVEL_UP_MSG_APPEND(surface)
LEVEL_UP_MSG = LEVEL_UP_MSG_

THREAD2.update()



LEVEL_UP_6 = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Level_up/Levelup_256x256_4x8_24_improved.png', 256, 8, 4)
i = 0
for im in LEVEL_UP_6:
    LEVEL_UP_6[i] = smoothscale(im, (512, 512)).convert()
    i += 1

THREAD2.update()

# IMPACT BURST
BURST_DOWN_RED = sprite_sheet_per_pixel(
    'Assets/Graphics/TimeLineFx/Burst/BurstDown1_red_128x128.png', 128, 6, 6)

THREAD2.update()

BURST_UP_RED = sprite_sheet_per_pixel(
    'Assets/Graphics/TimeLineFx/Burst/BurstUp2_128x128.png', 128, 7, 7)

BLAST1 = sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Burst/Blast2_128x128_.png', 128, 5, 6)
BLAST1 = reshape(BLAST1, (16, 16))

THREAD2.update()

SUPERLASER_BURST = sprite_sheet_per_pixel(
    'Assets/Graphics/TimeLineFx/Burst/Burst_SuperLaser1_128x128.png', 128, 4, 4)

SUPERLASER_BURST1 = sprite_sheet_fs8_alpha(
    'Assets/Graphics/TimeLineFx/Burst/Burst_SuperLaser2_128x128.png', 128, 8, 4)

THREAD2.update()

ENERGY_BOOSTER1 = sprite_sheet_per_pixel(
    'Assets/Graphics/TimeLineFx/Energy cell/EnergyBall4_64x64.png', 64, 6, 6)

ENERGY_SUPPLY_ASSIMILATION = sprite_sheet_per_pixel(
    'Assets/Graphics/TimeLineFx/Energy cell/EnergyBallAssimilation_256x256_6x6.png', 256, 6, 6)

THREAD2.update()

THREAD2.update()

THREAD2.update()

PATH = 'Assets/Graphics/TimeLineFx/Particles/'
PHOTON_PARTICLE_1     = sprite_sheet_fs8(path_join(PATH, 'Particles_128x128_.png'), 128, 6, 6)
PHOTON_PARTICLE_1_NEG = sprite_sheet_fs8(path_join(PATH, 'Particles_128x128_neg.png'), 128, 6, 6)


NUKE_EXPLOSION_NEMESIS = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Bomb/Bomb_4_512x512_2m.png', 512, 11, 4)

i = 0
for s in NUKE_EXPLOSION_NEMESIS:
    NUKE_EXPLOSION_NEMESIS[i] = smoothscale(s, (<int>((<float>512.0/<float>256.0)*i +512) ,
                                                <int>((<float>512.0/<float>256.0)*i +512)))
    i += 1


THREAD2.update()

NUKE_EXOLOSION_LEVIATHAN = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Bomb/Bomb_5_512x512_4x11_.png', 512, 11, 4)
i = 0
for s in NUKE_EXOLOSION_LEVIATHAN:
    NUKE_EXOLOSION_LEVIATHAN[i] = smoothscale(s, (<int>((<float>512.0/<float>44.0)*i +512) ,
                                                <int>((<float>512.0/<float>44.0)*i +512)))
    i += 1



THREAD2.update()

NUKE_BONUS = sprite_sheet_per_pixel(
    'Assets/Graphics/Bonus/3ds/NUKEBONUS_32x32.png', 32, 10, 10)

zoom1 = linspace(1, 1.2, len(NUKE_BONUS) >> 1)
zoom2 = linspace(1.2, 1, len(NUKE_BONUS) >> 1)
zoom = [*zoom1, *zoom2]
i = 0
for surface in NUKE_BONUS:
    NUKE_BONUS[i] = rotozoom(surface, 0, zoom[i])
    i += 1

THREAD2.update()

BonusLifeLeviathan_ = image_load(
    "Assets/Graphics/SpaceShip/Leviathan80x80.png").convert_alpha()

BonusLifeLeviathan_ = smoothscale(BonusLifeLeviathan_, (30, 30))
BonusLifeLeviathan = [*[BonusLifeLeviathan_] * 32]

zoom1 = linspace(1, 1.2, len(BonusLifeLeviathan) >> 1)
zoom2 = linspace(1.2, 1, len(BonusLifeLeviathan) >> 1)
zoom = [*zoom1, *zoom2]
i = 0
for surface in BonusLifeLeviathan:
    BonusLifeLeviathan[i] = rotozoom(surface, 0, zoom[i])
    i += 1

THREAD2.update()


BonusLifeNemesis_ = image_load("Assets/"
        "Graphics/SpaceShip/SpaceShip.png").convert_alpha()

BonusLifeNemesis_ = smoothscale(BonusLifeNemesis_, (30, 30))
BonusLifeNemesis = [*[BonusLifeNemesis_] * 32]

zoom1 = linspace(1, 1.2, len(BonusLifeNemesis) >> 1)
zoom2 = linspace(1.2, 1, len(BonusLifeNemesis) >> 1)
zoom = [*zoom1, *zoom2]
i = 0
for surface in BonusLifeNemesis:
    BonusLifeNemesis[i] = rotozoom(surface, 0, zoom[i])
    i += 1

THREAD2.update()

cdef list create_halo_surface(surface_, tuple color_, float f1_, float f2_, blend_=True):

    if f1_ == 0.0:
        raise ValueError("Argument f1_ cannot be zero!")

    if f2_ == 0.0:
        raise ValueError("Argument f2_ cannot be zero!")

    cdef:
        int number_ = 0
        float s_ = 0.0
        surface_list = []
        surface_append = surface_list.append
        numpy.ndarray[float64_t, ndim=1] steps = linspace(0.0, 1.0, 30)

    for number_ in range(30):
        s_ = steps[number_]
        if blend_:
            blend_surface = blend_texture_32c(surface_, color_, <int>(s_ * 100.0))
        else:
            blend_surface = surface_
        surface = make_transparent32(blend_surface, <int> (255 * s_ / f1_))
        size = Vector2(surface.get_size())
        size *= (1.0 + number_ / f2_)
        output = smoothscale(surface, (<int> size.x, <int> size.y))
        surface_append(output)
    return surface_list


HALO_SPRITE_WHITE_ = image_load('Assets/Graphics/Halo/WhiteHalo_.png').convert_alpha()
HALO_SPRITE_WHITE = []
steps = linspace(0.0, 1.0, 30)
for number in range(30):

    surface = blend_texture_32c(HALO_SPRITE_WHITE_, (4, 255, 245), steps[number] * <float>100.0)
    surface = make_transparent32(surface, <int>(<float>255.0 * steps[number]/<float>1.5))
    size = Vector2(surface.get_size())
    size *= (number / <float>25.0)
    surface1 = smoothscale(surface, (int(size.x), int(size.y)))
    HALO_SPRITE_WHITE.append(surface1)



THREAD2.update()

# RED (NUKE EXPLOSION_)
HALO_SPRITE8_ = image_load('Assets/Graphics/Halo/halo6.png').convert_alpha()
HALO_SPRITE8 = create_halo_surface(HALO_SPRITE8_, (250, 10, 15), 8.0, 15.0)
i = 0
for surf in HALO_SPRITE8:
    surf = bloom_effect_buffer32_c(surf, 64-i, 1)
    HALO_SPRITE8[i] = surf
    i += 1


THREAD2.update()

# PLAYER EXPLOSION (RED HALO)
HALO_SPRITE9_ = []
HALO_SPRITE9_APPEND = HALO_SPRITE9_.append
HALO_SPRITE9__ = pygame.image.load('Assets/Graphics/Halo/halo12_.png').convert()
for number in range(30):
    surface1 = smoothscale(HALO_SPRITE9__, (
        int(surface.get_width() * (1 + (number / <float>5.0))),
        int(surface.get_height() * (1 + (number / <float>5.0)))))
    HALO_SPRITE9_APPEND(surface1.convert())


THREAD2.update()


HALO_SPRITE11 = smoothscale(image_load('Assets/Graphics/Halo/Halo10.png'), (64, 64))
HALO_SPRITE11 = create_halo_surface(HALO_SPRITE11, (250, 10, 15), 1.0, 5.0, blend_=False)

THREAD2.update()

HALO_SPRITE12 = smoothscale(image_load('Assets/Graphics/Halo/Halo11.png'), (64, 64))
HALO_SPRITE12 = create_halo_surface(HALO_SPRITE12, (250, 10, 15), 1.0, 5.0, blend_=False)

THREAD2.update()

HALO_SPRITE13 = smoothscale(image_load('Assets/Graphics/Halo/Halo12.png'), (64, 64))
HALO_SPRITE13 = create_halo_surface(HALO_SPRITE13, (250, 10, 15), 1.0, 5.0, blend_=False)

THREAD2.update()

# PURPLE
HALO_SPRITE14 = smoothscale(image_load('Assets/Graphics/Halo/Halo13.png'), (64, 64))
HALO_SPRITE14 = create_halo_surface(HALO_SPRITE14, (250, 10, 15), 1.0, 5.0, blend_=False)

THREAD2.update()


ENERGY_HUD = image_load('Assets/Graphics/Hud/energyhud_275x80.png').convert_alpha()
LIFE_HUD = image_load('Assets/Graphics/Hud/lifehud_275x80.png').convert_alpha()


# NUKE MISSILE/BOMB SPRITE
NUKE_BOMB_SPRITE         = image_load(
    'Assets/Graphics/Missiles/Nuke/Nuke_32x32.png').convert_alpha()
NUKE_BOMB_INVENTORY      = image_load(
    'Assets/Graphics/Missiles/Nuke/3Nukes_.png').convert()
MISSILE_INVENTORY        = image_load(
    'Assets/Graphics/Missiles/Missile_inventory.png').convert()
NEMESIS_LIFE_INVENTORY   = image_load(
    'Assets/Graphics/Hud/Life number/Slife.png').convert()
LEVIATHAN_LIFE_INVENTORY = image_load(
    'Assets/Graphics/Hud/Life number/Llife.png').convert()

THREAD2.update()


THREAD2.update()

# MISSILE_EXHAUST =
# sprite_sheet_per_pixel('Assets/Graphics/Exhaust/2/Smoke_trail_128x128.png', 128, 5, 5)
# MISSILE_EXHAUST = reshape(MISSILE_EXHAUST, (10, 10))

# Target sprite (circle surrounding an player)
MISSILE_TARGET_SPRITE = \
    sprite_sheet_per_pixel('Assets/Graphics/Missiles/target_64x64.png', 64, 8, 12)

NUKE_BOMB_TARGET = image_load('Assets/Graphics/Missiles/nuke0.png').convert_alpha()
NUKE_BOMB_TARGET = [NUKE_BOMB_TARGET] * 35

THREAD2.update()

x = 20
y = 20

GEM_SPRITES = []
for i in range(1, 21):

    try:
        im = image_load('Assets/Graphics/Gems/Gem' + str(i) + '_.png').convert()
    except:
        continue
    im = smoothscale(im, (x, y))
    #blur(im, t_=2)
    #bloom_effect_buffer32_c(im, 64, 1)
    GEM_SPRITES.append(im)
    if i % 2:
        x += 1
        y += 1

GEM_ASSIMILATION = sprite_sheet_per_pixel(
    'Assets/Graphics/Gems/GemAssimilation_128x128_9x2.png', 128, 2, 9)

THREAD2.update()

EXHAUST2_SPRITE_ = sprite_sheet_fs8('Assets/Graphics/Exhaust/2/Exhaust2_.png', 128, 8, 8)
EXHAUST2_SPRITE = []
EXHAUST2_SPRITE_APPEND = EXHAUST2_SPRITE.append
i = 0
for surface in EXHAUST2_SPRITE_:
    surface = smoothscale(surface, (50, 60))
    EXHAUST2_SPRITE_APPEND(surface)
    i += 1


EXHAUST1_SPRITE = [image_load('Assets/Graphics/Exhaust/1/0001_.png').convert(),
                   image_load('Assets/Graphics/Exhaust/1/0002_.png').convert(),
                   image_load('Assets/Graphics/Exhaust/1/0003_.png').convert(),
                   image_load('Assets/Graphics/Exhaust/1/0004_.png').convert(),
                   image_load('Assets/Graphics/Exhaust/1/0005_.png').convert(),
                   image_load('Assets/Graphics/Exhaust/1/0006_.png').convert(),
                   image_load('Assets/Graphics/Exhaust/1/0007_.png').convert()]
i = 0
for surface in EXHAUST1_SPRITE:
    surface = smoothscale(surface, (35, 35))
    EXHAUST1_SPRITE[i] = flip(surface, False, True)
    i += 1

THREAD2.update()

EXHAUST3_SPRITE = sprite_sheet_fs8(
    'Assets/Graphics/Exhaust/2/Exhaust6_.png', 32, 8, 4, True, (32, 64))

# EXHAUST4 = sprite_sheet_fs8('Assets/Graphics/Exhaust/2/Exhaust7_.png', 256, 6, 6)
# EXHAUST4 = reshape(EXHAUST4, (128, 128))

DRONE = image_load('Assets/Graphics/Enemy/GroundTroups/DroneGrouped9.png').convert_alpha()
DRONE = smoothscale(DRONE, (50, 36))


DRONE7 = []
DRONE7_APPEND = DRONE7.append
for r in range(36):
    DRONE7_APPEND(hsv_surface32c(DRONE, <float>r/<float>36.0))

THREAD2.update()

GENERATOR = image_load(
    'Assets/Graphics/Enemy/GroundTroups/ShieldGenerator.png').convert_alpha()
GENERATOR = smoothscale(GENERATOR, (80, 80))
GENERATOR_ = []
GENERATOR_APPEND = GENERATOR_.append
for r in range(36):
    GENERATOR_APPEND(hsv_surface32c(GENERATOR, <float>r/36.0))
GENERATOR = GENERATOR_

THREAD2.update()

TURRET_SPRITE = image_load('Assets/Graphics/Turret/turret3.png').convert_alpha()
TURRET_SPRITE = smoothscale(TURRET_SPRITE, (40, 40))
TURRET_SPRITE_ = []
TURRET_SPRITE_APPEND = TURRET_SPRITE_.append
for r in range(36):
    TURRET_SPRITE_APPEND(hsv_surface32c(TURRET_SPRITE, <float>r/36.0))
TURRET_SPRITE = TURRET_SPRITE_

THREAD2.update()

TURRET_SPRITE_SENTINEL = image_load('Assets/Graphics/Turret/Turret3.png').convert_alpha()
TURRET_SPRITE_SENTINEL = smoothscale(TURRET_SPRITE_SENTINEL, (100, 100))
TURRET_SPRITE_SENTINEL_ = []
TURRET_SPRITE_SENTINEL_APPEND = TURRET_SPRITE_SENTINEL_.append
for r in range(36):
    TURRET_SPRITE_SENTINEL_APPEND(hsv_surface32c(TURRET_SPRITE_SENTINEL, <float>r/36.0))
TURRET_SPRITE_SENTINEL = TURRET_SPRITE_SENTINEL_

THREAD2.update()

GROUND_EXPLOSION_SPRITES =[
    sprite_sheet_fs8(
        'Assets/Graphics/TimeLineFx/Explosion/Ground_explosion1_256x256_.png', 256, 9, 6),
    sprite_sheet_fs8(
        'Assets/Graphics/TimeLineFx/Explosion/Ground_explosion2_256x256_.png', 256, 8, 8),
    sprite_sheet_fs8(
        'Assets/Graphics/TimeLineFx/Explosion/Ground_explosion3_256x256_.png', 256, 8, 8),
    sprite_sheet_fs8(
        'Assets/Graphics/TimeLineFx/Explosion/Explosion14_256x256_.png', 256, 8, 6),
    sprite_sheet_fs8(
        'Assets/Graphics/TimeLineFx/Explosion/Explosion15_256x256_.png', 256, 8, 8)
    ]

THREAD2.update()

LASER_EX = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Explosion/LaserExplosion128x128_.png', 128, 8, 6)

TESLA_BLUE_SPRITE = sprite_sheet_fs8_alpha(
    'Assets/Graphics/Tesla/teslaColor_blue_h.png', 101, 12, 1, True, (101, 220))

TESLA_BLUE_SPRITE = reshape(sprite_=TESLA_BLUE_SPRITE, factor_=(40, 500))

# TESLA_BLUE_SPRITE_blended = sprite_sheet_fs8(
#     'Assets/Graphics/Tesla/teslaColor_natural_h_.png', 101, 12, 1, True, (101, 220))
# TESLA_BLUE_SPRITE_blended = reshape(sprite_=TESLA_BLUE_SPRITE_blended, factor_=(30, 90))

ELECTRIC = sprite_sheet_fs8('Assets/Graphics/Tesla/teslaColor_natural_h_modified.png', 280,
                            1, 12,
                            True, (280, 126))
# i = 0
# for surface in ELECTRIC:
#     s = rotozoom(surface, 90, 1)
#     ELECTRIC[i] = smoothscale(s, (280, 80))
#     i += 1


#
# BEAM_FIELD = image_load('Assets/Graphics/Shield/subparts2/8.png').convert_alpha()
# BEAM_FIELD = [BEAM_FIELD] * 10
#
# THREAD2.update()
#
# i = 0
# rotation = 0
# # todo assert BEAM_FIELD != 0
#
# rotation_steps = 360 / len(BEAM_FIELD)
# zoom1 = linspace(1, 2, len(BEAM_FIELD))
# steps = linspace(0, 1, len(BEAM_FIELD))
# for surface in BEAM_FIELD:
#     surface = smoothscale(surface, (250, 250))
#     surface = blend_texture_32c(surface, (255, 10, 15), <int>(steps[i] * 100.0))
#     BEAM_FIELD[i] = rotozoom(surface, rotation, zoom1[i])
#     i += 1
#     rotation += rotation_steps

THREAD2.update()

# TESLA_IMPACT = sprite_sheet_per_pixel(
# 'Assets/Graphics/Tesla/Eletric_Impact_128x128.png', 128, 5, 5)

THREAD2.update()

# SHIELD_ELECTRIC_ARC = sprite_sheet_fs8(
#     'Assets/Graphics/Tesla/teslaColor_natural_h_.png', 101, 12, 1, True, (101, 220))
#
# i = 0
# for r in SHIELD_ELECTRIC_ARC:
#     SHIELD_ELECTRIC_ARC[i] = smoothscale(r, (r.get_width() >> 1, r.get_height() >> 1))
#     i += 1
THREAD2.update()

SHIELD_ELECTRIC_ARC_1 = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Electric/Electric_effect_256x256_6x6_3.png', 256, 6, 6)
SHIELD_ELECTRIC_ARC_1_ = reshape(SHIELD_ELECTRIC_ARC_1, (150, 150))


# NEMESIS SHIELD
ROUND_SHIELD_1 = image_load('Assets/Graphics/Shield/roundShield1/001.png').convert_alpha()
ROUND_SHIELD_1_ = []
ROUND_SHIELD_1_APPEND = ROUND_SHIELD_1_.append
for r in range(36):
    ROUND_SHIELD_1_APPEND(hsv_surface32c(ROUND_SHIELD_1, <float>r/<float>36.0))
ROUND_SHIELD_1 = ROUND_SHIELD_1_

del ROUND_SHIELD_1_

# LEVIATHAN
ROUND_SHIELD_2 = image_load('Assets/Graphics/Shield/roundShield2/001.png').convert_alpha()
ROUND_SHIELD_2_ = []
ROUND_SHIELD_2_APPEND = ROUND_SHIELD_2_.append
for r in range(36):
    ROUND_SHIELD_2_APPEND(hsv_surface32c(ROUND_SHIELD_2, <float>r/<float>36.0))
ROUND_SHIELD_2 = ROUND_SHIELD_2_

del ROUND_SHIELD_2_APPEND

THREAD2.update()

SHIELD_SOFT_RED = image_load(
    'Assets/Graphics/Shield/ShieldSoft/ShieldSoft9.png').convert_alpha()
SHIELD_SOFT_RED = make_transparent32(SHIELD_SOFT_RED, 15)

SHIELD_GENERATOR_ = []
# apply hue shifting
for r in range(36):
    SHIELD_GENERATOR_.append(hsv_surface32c(SHIELD_SOFT_RED, <float>r/<float>36.0))
SHIELD_GENERATOR = SHIELD_GENERATOR_

del SHIELD_GENERATOR_

THREAD2.update()

SHIELD_GLOW = []
SHIELD_GLOW_APPEND = SHIELD_GLOW.append
SHIELD_GLOW_ = image_load('Assets/Graphics/Shield/ShieldSoft/shieldSoft9.png').convert_alpha()
steps = linspace(0, 1, 30)

for number in range(30):
    # Blend green
    surface = blend_texture_32c(SHIELD_GLOW_, (255, 20, 10), <int>(steps[number] * <unsigned
    char>100))
    image = make_transparent32(surface, 25)
    surface1 = smoothscale(image, (
        <int>((surface.get_width() // 7) * (<unsigned
    char>1 + (number / <float>10.0))),
        <int>((surface.get_height() // 7) * (<unsigned
    char>1 + (number / <float>10.0)))))
    SHIELD_GLOW_APPEND(surface1.convert_alpha())

del steps
del SHIELD_GLOW_APPEND
del SHIELD_GLOW_

THREAD2.update()

SHIELD_GLOW_BLUE = []
SHIELD_GLOW_BLUE_APPEND = SHIELD_GLOW_BLUE.append
SHIELD_GLOW_BLUE_ = image_load('Assets/Graphics/Shield/ShieldHard/shieldhard5_.png').convert()
for number in range(30):
    surface1 = smoothscale(SHIELD_GLOW_BLUE_, (
        <int>((SHIELD_GLOW_BLUE_.get_width() // 7) * (<unsigned char>1 + (number / <float>10.0))),
        <int>((SHIELD_GLOW_BLUE_.get_height() // 7) * (<unsigned char>1 + (number / <float>10.0)))))
    SHIELD_GLOW_BLUE_APPEND(surface1)

del SHIELD_GLOW_BLUE_APPEND
del SHIELD_GLOW_BLUE_


THREAD2.update()


zoom1 = linspace(1, 1.2, len(ROUND_SHIELD_1) >> 1)
zoom2 = linspace(1.2, 1, len(ROUND_SHIELD_1) >> 1)
zoom = [*zoom1, *zoom2]
rotation_steps = 4.5
rotation = 0
ROUND_SHIELD_1 = reshape(ROUND_SHIELD_1, (120, 120))
transparency1 = linspace(10, 80, len(ROUND_SHIELD_1) >> 1)
transparency2 = linspace(80, 10, len(ROUND_SHIELD_1) >> 1)
transparency = [*transparency1, *transparency2]
i = 0

for surface in ROUND_SHIELD_1:
    image = make_transparent32(surface, <int>transparency[i])
    ROUND_SHIELD_1[i] = \
        smoothscale(image, (<int>(surface.get_width() * zoom[i]),
                            <int>(surface.get_height() * zoom[i])))
    rotation += rotation_steps
    i += 1

del zoom1, zoom2, zoom
del transparency1, transparency2, transparency


THREAD2.update()

zoom1 = linspace(1, 1.2, len(ROUND_SHIELD_2) >> 1)
zoom2 = linspace(1.2, 1, len(ROUND_SHIELD_2) >> 1)
zoom = [*zoom1, *zoom2]
rotation_steps = 4.5
rotation = 0
ROUND_SHIELD_2 = reshape(ROUND_SHIELD_2, (150, 150))
transparency1 = linspace(10, 80, len(ROUND_SHIELD_2) >> 1)
transparency2 = linspace(80, 10, len(ROUND_SHIELD_2) >> 1)
transparency = [*transparency1, *transparency2]
i = 0

for surface in ROUND_SHIELD_2:
    image = make_transparent32(surface, <int>transparency[i])
    ROUND_SHIELD_2[i] = smoothscale(
        image, (int(surface.get_width() * zoom[i]), int(surface.get_height() * zoom[i])))
    rotation += rotation_steps
    i += 1


del zoom1, zoom2, zoom
del transparency1, transparency2, transparency

THREAD2.update()

PATH = 'Assets/Graphics/Shield/Impact/'
ROUND_SHIELD_IMPACT = [*[image_load(path_join(PATH, 'waves.png')).convert_alpha()] * 5,
                       *[image_load(path_join(PATH, 'waves1.png')).convert_alpha()] * 5,
                       *[image_load(path_join(PATH, 'waves2.png')).convert_alpha()] * 5,
                       *[image_load(path_join(PATH, 'waves3.png')).convert_alpha()] * 5,
                       *[image_load(path_join(PATH, 'waves4.png')).convert_alpha()] * 5,
                       *[image_load(path_join(PATH, 'waves5.png')).convert_alpha()] * 5,
                       *[image_load(path_join(PATH, 'waves6.png')).convert_alpha()] * 5]

ROUND_SHIELD_IMPACT = reshape(ROUND_SHIELD_IMPACT, (150, 150))

SHIELD_BORDER_INDICATOR = image_load('Assets/Graphics/Shield/chargebar/border1.png').convert()
SHIELD_BORDER_INDICATOR = smoothscale(SHIELD_BORDER_INDICATOR,
    (SHIELD_BORDER_INDICATOR.get_width() >> 1, SHIELD_BORDER_INDICATOR.get_height() >> 1))

SHIELD_METER_INDICATOR = \
    image_load('Assets/Graphics/Shield/chargebar/meter.png').convert_alpha()
SHIELD_METER_INDICATOR = \
    smoothscale(SHIELD_METER_INDICATOR, (SHIELD_METER_INDICATOR.get_width() >> 1,
    SHIELD_METER_INDICATOR.get_height() >> 1))

SHIELD_METER_MAX = image_load('Assets/Graphics/Shield/chargebar/txtMax.png').convert_alpha()

FIRE = PHOTON_PARTICLE_1.copy()
FIRE = reshape(FIRE, (24, 24))

THREAD2.update()

CLUSTER_EXPLOSION = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Explosion/Cluster_explosion22.png', 64, 6, 6)

THREAD2.update()

SHIELD_HEATGLOW1 = sprite_sheet_fs8(
    'Assets/Graphics/Shield/HeatGlow/heatglow11_.png', 64, 6, 6)

THREAD2.update()

SHIELD_DISTUPTION_1 = \
    sprite_sheet_fs8(
        'Assets/Graphics/Shield/Disruption/disruption1_128x128_1.png', 128, 6, 6)

# DAMAGE_CONTROL_128x128 =
# sprite_sheet_per_pixel('Assets/Graphics/Hud/control2_128x128.png', 128, 5, 6)

THREAD2.update()

# DAMAGE_CONTROL_64x64 =
# sprite_sheet_per_pixel('Assets/Graphics/Hud/control3_64x64.png', 64, 5, 6)

THREAD2.update()

PATH = 'Assets/Graphics/SpaceShip/Damages/'
DAMAGE_LEFT_WING = sprite_sheet_fs8_alpha(
    path_join(PATH, 'Left_wing/SpaceShip.png'), 64, 3, 1, True, (64, 72))
DAMAGE_LEFT_WING_YELLOW = DAMAGE_LEFT_WING[0]
DAMAGE_LEFT_WING_ORANGE = DAMAGE_LEFT_WING[1]
DAMAGE_LEFT_WING_RED = DAMAGE_LEFT_WING[2]

del DAMAGE_LEFT_WING

DAMAGE_RIGHT_WING = sprite_sheet_fs8_alpha(
    path_join(PATH, 'Right_wing/SpaceShip.png'), 64, 3, 1, True, (64, 72))
DAMAGE_RIGHT_WING_YELLOW = DAMAGE_RIGHT_WING[0]
DAMAGE_RIGHT_WING_ORANGE = DAMAGE_RIGHT_WING[1]
DAMAGE_RIGHT_WING_RED = DAMAGE_RIGHT_WING[2]
del DAMAGE_RIGHT_WING

DAMAGE_NOSE = sprite_sheet_fs8_alpha(
    path_join(PATH, 'Nose/SpaceShip.png'), 64, 3, 1, True, (64, 72))
DAMAGE_NOSE_YELLOW = DAMAGE_NOSE[0]
DAMAGE_NOSE_ORANGE = DAMAGE_NOSE[1]
DAMAGE_NOSE_RED = DAMAGE_NOSE[2]

del DAMAGE_NOSE

THREAD2.update()
DAMAGE_LEFT_ENGINE = sprite_sheet_fs8_alpha(
    path_join(PATH, 'Engine_left/SpaceShip.png'), 64, 3, 1, True, (64, 72))
DAMAGE_LEFT_ENGINE_YELLOW = DAMAGE_LEFT_ENGINE[0]
DAMAGE_LEFT_ENGINE_ORANGE = DAMAGE_LEFT_ENGINE[1]
DAMAGE_LEFT_ENGINE_RED = DAMAGE_LEFT_ENGINE[2]

del DAMAGE_LEFT_ENGINE

DAMAGE_RIGHT_ENGINE = sprite_sheet_fs8_alpha(
    path_join(PATH, 'Engine_right/SpaceShip.png'), 64, 3, 1, True, (64, 72))
DAMAGE_RIGHT_ENGINE_YELLOW = DAMAGE_RIGHT_ENGINE[0]
DAMAGE_RIGHT_ENGINE_ORANGE = DAMAGE_RIGHT_ENGINE[1]
DAMAGE_RIGHT_ENGINE_RED = DAMAGE_RIGHT_ENGINE[2]

del DAMAGE_RIGHT_ENGINE

DAMAGE_NONE = image_load(path_join(PATH, 'SpaceShip_green.png')).convert_alpha()
DAMAGE_ALL = image_load(path_join(PATH, 'SpaceShip_red.png')).convert_alpha()

surface = image_load('Assets/Graphics/Hud/broken_screen_overlay.png').convert_alpha()
SCREEN_IMPACT = scale(surface, (128, 128))

del surface

surface = image_load('Assets/Graphics/Hud/Broken glass.png').convert_alpha()
SCREEN_IMPACT1 = scale(surface, (128, 128))

del surface

THREAD2.update()

TURRET_TARGET_SPRITE = image_load('Assets/Graphics/Turret/square.png').convert_alpha()
TURRET_TARGET_SPRITE = smoothscale(TURRET_TARGET_SPRITE, (256, 256))

COLLECTIBLES_AMMO = image_load('Assets/Graphics/Bullets/Amunitions_icon.png').convert_alpha()
COLLECTIBLES_AMMO = smoothscale(COLLECTIBLES_AMMO, (32, 32))
COLLECTIBLES_AMMO = [COLLECTIBLES_AMMO] * 60
zoom1 = linspace(1, 1.2, len(COLLECTIBLES_AMMO) >> 1)
zoom2 = linspace(1.2, 1, len(COLLECTIBLES_AMMO) >> 1)
zoom = [*zoom1, *zoom2]
angle = 0
i = 0
for surface in COLLECTIBLES_AMMO:
    COLLECTIBLES_AMMO[i] = rotozoom(surface, 0, zoom[i])
    i += 1

del zoom1, zoom2, zoom,

THREAD2.update()

MUZZLE_FLASH = sprite_sheet_per_pixel(
    'Assets/Graphics/Muzzle flash/MuzzleFlash1_64x64.png', 64, 2, 4)
MUZZLE_FLASH = reshape(MUZZLE_FLASH, (32, 32))


MUZZLE1 = sprite_sheet_per_pixel('Assets/Graphics/Muzzle flash/Muzzle1_64x64.png', 64, 2, 2)
MUZZLE2 = sprite_sheet_per_pixel(
    'Assets/Graphics/Muzzle flash/MuzzleFlash1_128x128.png', 128, 2, 4)

# BRIGHT_LIGHT_BLUE = image_load('Assets/Graphics/Muzzle flash/flareFX.png').convert_alpha()
# BRIGHT_LIGHT_BLUE = smoothscale(BRIGHT_LIGHT_BLUE, (20, 20))

THREAD2.update()

# BRIGHT_LIGHT_RED = blend_texture_32c(BRIGHT_LIGHT_BLUE, (0, 255, 0), 80)

# TODO remove alpha channel
PATH = 'Assets/Graphics/Enemy/'
SPACE_FIGHTER_SPRITE = image_load(
    path_join(PATH, 'interceptors/illumDefault11.png')).convert_alpha()

SCOUT_SPRITE   = image_load(path_join(PATH, 'Scouts/illumGreen10.png')).convert_alpha()
SCOUT_KAMIKAZE = image_load(path_join(PATH, 'Scouts/illumDefault03.png')).convert_alpha()
COLONY_SHIP_I  = image_load(path_join(PATH, 'ColonyShip/illumDefault09.png')).convert_alpha()
COLONY_SHIP_II = image_load(path_join(PATH, 'ColonyShip/illumDefault12.png')).convert_alpha()

THREAD2.update()
INTERCEPTOR = image_load(path_join(PATH, 'illumGreen19.png')).convert_alpha()
INTERCEPTOR_SPRITE = []
for i in range(36):
    INTERCEPTOR_SPRITE.append(hsv_surface32c(INTERCEPTOR, i/<float>36.0))

del INTERCEPTOR

RAIDER_SPRITE = image_load(path_join(PATH, 'Fighters/illumDefault17.png')).convert_alpha()

# TODO TO REMOVE WITH IMAGE BURST
RAPTOR_EXPLODE = [image_load(path_join(PATH, 'RaptorExplosion/RaptorPart1.png')).convert_alpha(),
                 image_load(path_join(PATH, 'RaptorExplosion/RaptorPart2.png')).convert_alpha(),
                 image_load(path_join(PATH, 'RaptorExplosion/RaptorPart3.png')).convert_alpha(),
                 image_load(path_join(PATH, 'RaptorExplosion/RaptorPart4.png')).convert_alpha(),
                 image_load(path_join(PATH, 'RaptorExplosion/RaptorPart5.png')).convert_alpha()]

THREAD2.update()

NANO_BOTS_CLOUD = sprite_sheet_fs8('Assets/Graphics/NanoBots/NanoBots1_128x128_9_deg_elec_1'
                                   '.png', 128, 8, 5)


THREAD2.update()

DEATHRAY_SPRITE_BLUE = []
DEATHRAY_SPRITE_BLUE_EXTEND = DEATHRAY_SPRITE_BLUE.extend
for r in range(32):
    if r < 10:
        r = '0' + str(r)
    else:
        r = str(r)
    surface = image_load(path_join('Assets/Graphics/Beam/blue_13_/' + r + '.png'))
    surface = smoothscale(surface, (surface.get_width() * 4, surface.get_height() * 4))
    surface = bloom_effect_buffer24_c(surface.convert(24), 64, 1)
    s = smoothscale(surface, (64, 14))
    DEATHRAY_SPRITE_BLUE_EXTEND((s, s, s, s))


THREAD2.update()

DEATHRAY_SPRITE_BLUE_16_ = []
DEATHRAY_SPRITE_BLUE_16_APPEND = DEATHRAY_SPRITE_BLUE_16_.append
for r in range(20):
    if r < 10:
        r = '0' + str(r)
    else:
        r = str(r)
    surface = image_load(path_join('Assets/Graphics/Beam/blue_16/' + r + '.png')).convert()
    surface = smoothscale(surface, (surface.get_width() * 4, surface.get_height() * 4))
    surface = bloom_effect_buffer24_c(surface.convert(24), 64, 1)
    DEATHRAY_SPRITE_BLUE_16_APPEND(surface)

DEATHRAY_SPRITE_BLUE_16 = []
DEATHRAY_SPRITE_BLUE_16_EXTEND = DEATHRAY_SPRITE_BLUE_16.extend
for surface in DEATHRAY_SPRITE_BLUE_16_:
    s = smoothscale(surface, (32, 14))
    DEATHRAY_SPRITE_BLUE_16_EXTEND((s, s, s, s))

DEATHRAY_SHAFT = sprite_sheet_fs8('Assets/Graphics/Beam/Shaft2_128x128_2.png', 128, 8, 8)

THREAD2.update()

COBRA = image_load('Assets/Graphics/Icon/Cobra.jpg').convert()
COBRA = smoothscale(COBRA, (32, 32))

COBRA_SHADOW = smoothscale(image_load('Assets/Graphics/SpaceShip/SpaceShip_shadow_.png'),
    (<int>(SPACESHIP_SPRITE.get_width() * <float>1.2),
     <int>(SPACESHIP_SPRITE.get_height() * <float>1.2))).convert()

LEVIATHAN_SHADOW = smoothscale(image_load(
    'Assets/Graphics/SpaceShip/Leviathan80x80_shadow_.png'),
    (<int>(LEVIATHAN.get_width() * <float>1.2), <int>(LEVIATHAN.get_height() * 1.2))).convert()

DEATHRAY_LEVIATHAN = sprite_sheet_fs8(
    'Assets/Graphics/Beam/DeathRay-fs8_.png', 44, 8, 4, True, (44, 512))

i = 0
for surface in DEATHRAY_LEVIATHAN:
    DEATHRAY_LEVIATHAN[i] = scale(surface, (surface.get_width(), surface.get_height()))
    i += 1

DEATHRAY_LEVIATHAN = DEATHRAY_LEVIATHAN * 4

THREAD2.update()

DEATHRAY_LEVIATHAN_SHAFT = sprite_sheet_fs8(
    'Assets/Graphics/Beam/FireEye_.png', 64, 8, 4, True, (64, 128))

# RED DEATHRAY BOSS 1
DEATHRAY_RED_B1 = []
for r in range(41):
    surface = image_load('Assets/Graphics/Beam/18_/'+ '0' + str(r) + '.png' if r < 10 else
                                   'Assets/Graphics/Beam/18_/' + str(r) + '.png').convert()
    surface = smoothscale(surface, (60, surface.get_height()))
    DEATHRAY_RED_B1.extend([*[surface] * 4])

THREAD2.update()

NAMIKO = [smoothscale(image_load(
    'Assets/Graphics/Characters/Namiko1_.png').convert(), (80, 180)),
          smoothscale(image_load(
              'Assets/Graphics/Characters/Namiko6_.png').convert(), (80, 180)),
          smoothscale(image_load(
              'Assets/Graphics/Characters/Namiko2_.png').convert(), (80, 180)),
          smoothscale(image_load(
              'Assets/Graphics/Characters/Namiko7_.png').convert(), (80, 180)),
          smoothscale(image_load(
              'Assets/Graphics/Characters/Namiko3_.png').convert(), (80, 180)),
          smoothscale(image_load(
              'Assets/Graphics/Characters/Namiko5_.png').convert(), (80, 180)),
          smoothscale(image_load(
              'Assets/Graphics/Characters/Namiko4_.png').convert(), (80, 180))]


RADAR_INTERFACE = sprite_sheet_fs8(
    'Assets/Graphics/GUI/Device/radar_animated1_150x150_.png', 150, 6, 6)
# RADAR_INTERFACE=RADAR_INTERFACE[32:]


THREAD2.update()

size = 18
R_GROUND_TARGET = sprite_sheet_fs8(
    'Assets/Graphics/GUI/Device/RedSquare32x32_4x8_.png', 32, 8, 4)
R_GROUND_TARGET = reshape(R_GROUND_TARGET, (size -4, size -4))

THREAD2.update()

R_BOSS_TARGET = sprite_sheet_fs8(
    'Assets/Graphics/GUI/Device/BrightDot_16x16_4x8_.png', 16, 8, 2)
R_BOSS_TARGET = reshape(R_BOSS_TARGET, (size, size))



R_AIRCRAFT_TARGET = sprite_sheet_fs8(
    'Assets/Graphics/GUI/Device/BrightDot_16x16_4x8_red_.png', 16, 8, 2)
R_AIRCRAFT_TARGET = reshape(R_AIRCRAFT_TARGET, (size, size))



R_MISSILE_TARGET = sprite_sheet_fs8(
    'Assets/Graphics/GUI/Device/BrightDot_16x16_4x8_purple_.png', 16, 8, 2)
R_MISSILE_TARGET = reshape(R_MISSILE_TARGET, (size, size))

THREAD2.update()

R_FRIEND = sprite_sheet_fs8(
    'Assets/Graphics/GUI/Device/BrightDot_16x16_4x8_green_.png', 16, 8, 2)
R_FRIEND = reshape(R_FRIEND, (size, size))

IMPACT_GLASS = sprite_sheet_per_pixel(
    'Assets/Graphics/Hud/Impact_glass5_256x256-fs8.png', 256, 4, 6)
IMPACT_GLASS = reshape(IMPACT_GLASS, (128, 128))

THREAD2.update()

IMPACT_GLASS1 = sprite_sheet_per_pixel(
    'Assets/Graphics/Hud/Impact_glass1_512x512-fs8.png', 512, 3, 8)
IMPACT_GLASS1 = reshape(IMPACT_GLASS1, (128, 128))

THREAD2.update()

BROKENGLASS_IMAGES = [IMPACT_GLASS, IMPACT_GLASS1]
del IMPACT_GLASS, IMPACT_GLASS1

FRAMEBORDER = image_load('Assets/Graphics/GUI/FrameBorder_.png').convert()
FRAMEBORDER.set_colorkey((0, 0, 0, 0), RLEACCEL)
FRAMEBORDER = smoothscale(FRAMEBORDER, (500, 250))
FRAMEBORDER = smoothscale(FRAMEBORDER, (FRAMEBORDER.get_width(), FRAMEBORDER.get_height() - 40))
FRAMESURFACE = Surface((FRAMEBORDER.get_width() - 20,
                        FRAMEBORDER.get_height() - 20), RLEACCEL).convert()
FRAMESURFACE.fill((10, 10, 18, 200))
FRAMEBORDER.blit(FRAMESURFACE, (15, 15))
DIALOG = FRAMEBORDER

del FRAMEBORDER, FRAMESURFACE

DIALOGBOX_READOUT = sprite_sheet_fs8(
    'Assets/Graphics/GUI/Device/Readout_256x256_.png', 256, 6, 6)
i = 0
for surface in DIALOGBOX_READOUT:
    surface.set_colorkey((0, 0, 0, 0), RLEACCEL)
    surface = flip(surface, True, True)
    DIALOGBOX_READOUT[i] = smoothscale(surface, (400, 250))
    i += 1

THREAD2.update()

VOICE_MODULATION = []
VOICE_MODULATION.extend((image_load('Assets/Graphics/Hud/techAudio_.png').convert(),
                         image_load('Assets/Graphics/Hud/techAudio1_.png').convert(),
                         image_load('Assets/Graphics/Hud/techAudio2_.png').convert(),
                         image_load('Assets/Graphics/Hud/techAudio3_.png').convert(),
                         image_load('Assets/Graphics/Hud/techAudio4_.png').convert()))

for surface in VOICE_MODULATION:
    surface.set_colorkey((0, 0, 0, 0), RLEACCEL)

HOTFURNACE = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Explosion/Burning/HotFurnace_256x256_.png', 256, 6, 6)
HOTFURNACE = reshape(HOTFURNACE, (100, 100))

THREAD2.update()


HOTFURNACE2 = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Explosion/Burning/Burning1_256x256_.png', 256, 6, 6)
HOTFURNACE2 = reshape(HOTFURNACE2, (100, 100))

FIREBOLT = sprite_sheet_fs8(
    'Assets/Graphics/Laser_Fx/png/miscs/FireBolt_128x128_.png', 128, 6, 6)
FIREBOLT = reshape(FIREBOLT, (30, 30))

BULLET_4 = image_load('Assets/Graphics/Laser_Fx/png/miscs/bull3.png').convert()
BULLET_4.set_colorkey((255, 255, 255, 255), RLEACCEL)
BULLET_4 = scale(BULLET_4, (16, 16))

THREAD2.update()

TURRET_SHARK_DEPLOYMENT_RED = \
    sprite_sheet_fs8_alpha(
        'Assets/Graphics/Turret/SharkTurretRed.png', 181, 6, 10, True, (181, 238))


i = 0
for r in TURRET_SHARK_DEPLOYMENT_RED:
    surface = flip(r, 0, 1)
    surface = hsv_surface32c(surface, i/<float>len(TURRET_SHARK_DEPLOYMENT_RED))
    TURRET_SHARK_DEPLOYMENT_RED[i] = smoothscale(surface, (48, 64))
    i += 1

THREAD2.update()

TURRET_SHARK_FULLY_RED_OPEN = TURRET_SHARK_DEPLOYMENT_RED[len(TURRET_SHARK_DEPLOYMENT_RED) - 1]
TURRET_SHARK_FULLY_RED_OPEN = smoothscale(TURRET_SHARK_FULLY_RED_OPEN, (48, 64))

TURRET_SHARK = []
TURRET_SHARK_APPEND = TURRET_SHARK.append
for r in range(60):
    surface = flip(TURRET_SHARK_FULLY_RED_OPEN.copy(), 0, 1)
    TURRET_SHARK_APPEND(hsv_surface32c(surface, <float>r/<float>60.0))

del TURRET_SHARK_FULLY_RED_OPEN

# BLUE_IMPACT = sprite_sheet_fs8(
#     'Assets/Graphics/Laser_Fx/impact_blue_64x64_5x2.png', 64, 2, 5, False)

THREAD2.update()

# BLUE_IMPACT1 = sprite_sheet_fs8(
#     'Assets/Graphics/Laser_Fx/impact_blue_128x128_4x4.png',  128, 4, 4, False)

# cdef int hx, hy
# hx, hy = (BLUE_IMPACT1[0].get_size()[0] >> 3, BLUE_IMPACT1[0].get_size()[1] >> 3)
# BLUE_IMPACT1 = reshape(BLUE_IMPACT1, (hx, hy))

BLUE_IMPACT2 = sprite_sheet_fs8(
    'Assets/Graphics/Laser_Fx/impact_blue_128x128_6x3.png', 128, 3, 6, False)



# TODO BELOW


THREAD2.update()
#
# # ------------------------------------------------------------------------------------
#
#
# PATH = 'Assets/Graphics/SpaceShip/Original/Boss7Debris/'
# G5V200_DEBRIS = [image_load(path_join(PATH, 'Boss7Debris1.png')).convert_alpha(),
#                  image_load(path_join(PATH, 'Boss7Debris2.png')).convert_alpha(),
#                  image_load(path_join(PATH, 'Boss7Debris3.png')).convert_alpha(),
#                  image_load(path_join(PATH, 'Boss7Debris4.png')).convert_alpha(),
#                  image_load(path_join(PATH, 'Boss7Debris5.png')).convert_alpha()]
#
# PATH = 'Assets/Graphics/SpaceShip/Original/Boss7Debris/'
# G5V200_DEBRIS_HOT = [image_load(path_join(PATH, 'debris1.png')).convert_alpha(),
#                      image_load(path_join(PATH, 'debris2.png')).convert_alpha(),
#                      image_load(path_join(PATH, 'debris3.png')).convert_alpha(),
#                      image_load(path_join(PATH, 'debris4.png')).convert_alpha(),
#                      image_load(path_join(PATH, 'debris5.png')).convert_alpha()]
#
#
# G5V200_DEBRIS     = reshape(G5V200_DEBRIS, factor_=(16, 16))
# G5V200_DEBRIS_HOT = reshape(G5V200_DEBRIS_HOT, factor_=(16, 16))
# EXPLOSION_DEBRIS  = [*G5V200_DEBRIS_HOT, *G5V200_DEBRIS]
#
# G5V200_SPRITE = image_load('Assets/Graphics/SpaceShip/Original/Boss7.png').convert_alpha()
# G5V200_SPRITE = smoothscale(G5V200_SPRITE, (200, 200))
# G5V200_SPRITE = [G5V200_SPRITE] * 30
# i = 0
# for surface in G5V200_SPRITE:
#     G5V200_SPRITE[i] = hsv_surface32c(surface, <float>i/30.0)
#     i += 1
#
# G5V200_SHADOW = scale(image_load('Assets/Graphics/SpaceShip/Original/Boss7_shadow_.png'),
#     (<int>(G5V200_SPRITE[0].get_width() * 1.2), <int>(G5V200_SPRITE[0].get_height() * 1.2)))
#
#
#
#
#
# SHIELD_ = image_load('Assets/Graphics/Shield/shield part 1 mixed/008_.png').convert_alpha()
# SHIELD_ = smoothscale(SHIELD_, (
# <int>round(G5V200_SPRITE[0].get_width()), <int>round(G5V200_SPRITE[0].get_height())))

THREAD2.update()

BLURRY_WATER1 = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Water/Blurry_Water1_256x256_6x6.png', 256, 6, 6)

THREAD2.update()

BLURRY_WATER2 = sprite_sheet_fs8(
    'Assets/Graphics/TimeLineFx/Water/Blurry_Water2_256x256_6x6.png', 256, 6, 6)
#
# SHIELD_ = image_load('Assets/Graphics/Shield/shield part 1 mixed/008_.png').convert_alpha()
#
# SHIELD = [SHIELD_] * 30
# SHIELD_ = smoothscale(SHIELD_, (200, 200))
#
# i = 0
# for surface in SHIELD:
#      SHIELD[i] = hsv_surface32c(surface, <float>i/30.0)
#      i += 1

THREAD2.update()

RADIAL = [image_load("Assets/Radial5_.png").convert()] * <unsigned char>10
w, h = RADIAL[0].get_size()
i = 0
j = 0
for surface in RADIAL:
    if j != 0:
        RADIAL[j] = smoothscale(surface, (<int>(w / i), <int>(h / i)))
    else:
        RADIAL[0] = surface
    i +=0.2
    j += 1

WING_LIGHT = image_load("Assets/Radial7_.png").convert()
WING_LIGHT = smoothscale(WING_LIGHT, (WING_LIGHT.get_width() >> 2,
                                WING_LIGHT.get_height() >> 2))
WING_LIGHT = [WING_LIGHT] * 3





RADIAL_LASER = image_load("Assets/Radial7_.png").convert()
RADIAL_LASER = smoothscale(RADIAL_LASER, (RADIAL_LASER.get_width() >> 2,
                                RADIAL_LASER.get_height() >> 2))


FINAL_MISSION = image_load('Assets/Graphics/GUI/Device/container.png').convert_alpha()

THREAD2.update()

DIALOGBOX_READOUT_RED = sprite_sheet_fs8(
    'Assets/Graphics/GUI/Device/Readout_512x512_6x6_red_.png', 512, 6, 6)
i = 0
for surface in DIALOGBOX_READOUT_RED:
    surface = smoothscale(surface,
                          (FINAL_MISSION.get_width() - <unsigned char>150,
                           FINAL_MISSION.get_height() - <unsigned char>150))
    DIALOGBOX_READOUT_RED[i] = flip(surface, True, True)
    i += 1



BOMB = image_load('Assets/Graphics/Missiles/MISSILE3.png').convert_alpha()
w, h = BOMB.get_size()
BOMB = smoothscale(BOMB, (<int>(w / <float>30.0), <int>(h / <float>30.0)))



FLARE = [*[image_load('Assets/Graphics/TimeLineFx/Flares/flare5_.png').convert()]*10,
         *[image_load('Assets/Graphics/TimeLineFx/Flares/flare4_.png').convert()]*10]
w, h = FLARE[0].get_size()
i = 1
j = 0
for surface in FLARE:
    if j < 10:
        w, h = FLARE[0].get_size()
    else:
        w, h = FLARE[11].get_size()
    FLARE[j] = smoothscale(surface, (<int>(w / i), <int>(h / i)))
    i += 0.1
    j += 1

PARTICLES_SPRITES = sprite_sheet_fs8('Assets/Graphics/GUI/Particles_128x128_.png', 128, 6, 6)
PARTICLES_SPRITES = reshape(PARTICLES_SPRITES, (28, 28))

SOUND_ICON = image_load('Assets/Graphics/GUI/sound_icon1.png').convert_alpha()
SOUND_ICON = smoothscale(SOUND_ICON, (64, 64))
LEVEL_ICON = image_load('Assets/Graphics/GUI/device/switchGreen04.png').convert_alpha()
LEVEL_ICON = rotozoom(LEVEL_ICON, 90, 0.7)
MUSIC_ICON = image_load('Assets/Graphics/GUI/music_icon.png').convert_alpha()


# ------------------------------------------------------------------------------

i = 0

G5V200_SURFACE   = pygame.image.load(
    "Assets/Graphics/SpaceShip/Original/Boss7.png").convert_alpha()

G5V200_SURFACE   = smoothscale(G5V200_SURFACE, (200, 200))
# USE ADDITIVE MODE FOR BETTER APPEARANCE
G5V200_SURFACE.blit(G5V200_SURFACE, (0, 0), special_flags=BLEND_RGB_ADD)
G5V200_ANIMATION = [G5V200_SURFACE] * 30

THREAD2.update()
s = pygame.display.get_surface()
for surf in G5V200_ANIMATION:
    image = hsv_surface32c(surf, <double>(i * <float>12.0)/<float>360.0).convert_alpha()
    # image = bloom_effect_buffer32_c(image, 200, smooth_=1)
    G5V200_ANIMATION[i] = image.convert_alpha()
    i += 1

w = G5V200_SURFACE.get_width()
h = G5V200_SURFACE.get_height()
G5V200_SHADOW = smoothscale(
    pygame.image.load('Assets/Graphics/SpaceShip/Original/Boss7_shadow_.png'),
    (120, 120)).convert()

G5V200_SHADOW_ROTATION_BUFFER = []
for angle in range(360):
    PyList_Append(G5V200_SHADOW_ROTATION_BUFFER,
                  rotozoom(G5V200_SHADOW, angle, 1.0))

FIRE_PARTICLE_1 = sprite_sheet_fs8(
    "Assets/Graphics/TimeLineFx/Explosion/Boss_explosion1_6x8_512_.png", 512, 8, 6)

FIRE_PARTICLE_1 = reshape(FIRE_PARTICLE_1, (64, 64))
THREAD2.update()


HALO_SPRITE_G5V200  = []
TMP_SURFACE = image_load('Assets/Graphics/Halo/halo12_.png').convert()
w = TMP_SURFACE.get_width()
h = TMP_SURFACE.get_height()

for number in range(16):
    surface1 = smoothscale(TMP_SURFACE, (
        <int>(w * (<unsigned char>1 + (number / <float>2.0))),
        <int>(h * (<unsigned char>1 + (number / <float>2.0)))))
    surface1 = bloom_effect_buffer24_c(surface1, <unsigned char>160
                                       - number * <unsigned char>10, 2)
    HALO_SPRITE_G5V200.append(surface1)

del TMP_SURFACE


STATION_IMPULSE  = []
TMP_SURFACE = image_load('Assets/Graphics/Halo/Halo15_.png').convert()
w = TMP_SURFACE.get_width()
h = TMP_SURFACE.get_height()

for number in range(16):
    surface1 = smoothscale(TMP_SURFACE, (
        <int>(w * (<unsigned char>1 + (number / <float>2.0))),
        <int>(h * (<unsigned char>1 + (number / <float>2.0)))))
    surface1 = bloom_effect_buffer24_c(
        surface1, <unsigned char>160 - number * <unsigned char>2, <unsigned char>1)
    surface1.set_colorkey((0, 0, 0), RLEACCEL)
    STATION_IMPULSE.append(surface1)
del TMP_SURFACE

THREAD2.update()

G5V200_DEBRIS = [
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/Boss7Debris1.png').convert(),
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/Boss7Debris2.png').convert(),
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/Boss7Debris3.png').convert(),
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/Boss7Debris4.png').convert(),
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/Boss7Debris5.png').convert()
    ]

G5V200_DEBRIS_HOT = [
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/debris1.png').convert(),
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/debris2.png').convert(),
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/debris3.png').convert(),
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/debris4.png').convert(),
    pygame.image.load(
        'Assets/Graphics/SpaceShip/Original/G5V200_DEBRIS_/debris5.png').convert()
    ]
THREAD2.update()
G5V200_DEBRIS = reshape(G5V200_DEBRIS, factor_=(16, 16))
G5V200_DEBRIS_HOT = reshape(G5V200_DEBRIS_HOT, factor_=(16, 16))
G5V200_EXPLOSION_DEBRIS = [*G5V200_DEBRIS_HOT, *G5V200_DEBRIS]

del G5V200_DEBRIS, G5V200_DEBRIS_HOT

G5V200_LASER_FX074 = image_load(
    'Assets/Graphics/Laser_Fx/png/1 basic/lzrfx074_1.png').convert()
# G5V200_LASER_FX074.blit(G5V200_LASER_FX074, (0, 0), special_flags=BLEND_RGB_ADD)

w = G5V200_LASER_FX074.get_width()
h = G5V200_LASER_FX074.get_height()
G5V200_LASER_FX074 = scale(G5V200_LASER_FX074, (<int>(w * <float>0.85) , <int>(h *<float>0.85)))
G5V200_FX074_ROTATE_BUFFER = []
for angle in range(0, 361):
    G5V200_FX074_ROTATE_BUFFER.append(rotate(G5V200_LASER_FX074, angle).convert())


G5V200_LASER_FX086 = image_load(
    'Assets/Graphics/Laser_Fx/png/1 basic/lzrfx086_.png').convert()
# blur5x5_surface24_inplace_c(G5V200_LASER_FX086)
w = G5V200_LASER_FX086.get_width()
h = G5V200_LASER_FX086.get_height()
G5V200_LASER_FX086 = scale(G5V200_LASER_FX086, (<int>(w * <float>0.65) , <int>(h * <float>0.65)))
# G5V200_LASER_FX086.blit(G5V200_LASER_FX086, (0, 0), special_flags=BLEND_RGB_ADD)
G5V200_LASER_FX086.set_colorkey((0, 0, 0, 0), RLEACCEL)
THREAD2.update()
G5V200_FX086_ROTATE_BUFFER = []
for angle in range(0, 361):
    s = rotate(G5V200_LASER_FX086, angle)
    s.set_colorkey((0, 0, 0, 0), RLEACCEL)
    G5V200_FX086_ROTATE_BUFFER.append(s)


STATION_LASER_LZRFX029 = image_load(
    'Assets/Graphics/Laser_Fx/png/1 basic/lzrfx029_.png').convert()
blur5x5_surface24_inplace_c(STATION_LASER_LZRFX029)
w = STATION_LASER_LZRFX029.get_width()
h = STATION_LASER_LZRFX029.get_height()
STATION_LASER_LZRFX029.set_colorkey((0, 0, 0, 0), RLEACCEL)

STATION_LASER_LZRFX029_ROTATE_BUFFER = []
for angle in range(0, 361):
    s = rotate(STATION_LASER_LZRFX029, angle)
    s.set_colorkey((0, 0, 0, 0), RLEACCEL)
    STATION_LASER_LZRFX029_ROTATE_BUFFER.append(s)

# TODO STOP HERE

G5V200_EXHAUST4 = sprite_sheet_per_pixel('Assets/Graphics/Exhaust/2/Exhaust8.png', 256, 6, 6)
G5V200_EXHAUST4 = reshape(G5V200_EXHAUST4, (128, 128))

G5V200_HALO_SPRITE12 = [smoothscale(
    pygame.image.load('Assets/Graphics/Halo/Halo11.png').convert_alpha(), (64, 64))] * 30

THREAD2.update()

STEPS = numpy.array([0., 0.03333333, 0.06666667, 0.1, 0.13333333,
             0.16666667, 0.2, 0.23333333, 0.26666667, 0.3,
             0.33333333, 0.36666667, 0.4, 0.43333333, 0.46666667,
             0.5, 0.53333333, 0.56666667, 0.6, 0.63333333,
             0.66666667, 0.7, 0.73333333, 0.76666667, 0.8,
             0.83333333, 0.86666667, 0.9, 0.93333333, 0.96666667])
i = 0
for surface in G5V200_HALO_SPRITE12:
    image = make_transparent32(surface, int(255 * STEPS[i]))
    surface1 =smoothscale(image, (
        int(surface.get_width()  * (<float>1.0 + (i / <float>4.0))),
        int(surface.get_height() * (<float>1.0 + (i / <float>4.0)))))
    G5V200_HALO_SPRITE12[i] = surface1.convert_alpha()
    i += 1

del STEPS

G5V200_EXPLOSION_LIST = \
    [reshape(MISSILE_EXPLOSION, <float>1/<float>2),
    reshape(MISSILE_EXPLOSION, <float>2/<float>3),
    MISSILE_EXPLOSION,
    reshape(MISSILE_EXPLOSION, 2)]


NUMBERS = sprite_sheet_fs8("Assets/Numbers0_4_improved.png", 62, 5, 1)

THREAD2.update()
COUNTDOWN_NUMBER_256x256 = []
for s in NUMBERS[::-1]:
    #s.set_colorkey((0, 0, 0, 0), RLEACCEL)
    COUNTDOWN_NUMBER_256x256.append(smoothscale(s, (256, 256)))

del NUMBERS

# --------------------------------------------------------------------------------------------------
# CREATE ALL THE PARALLAX AND BACKGROUND SURFACE
# Asteroids
PARALLAX_PART3 = image_load('Assets/Graphics/Background/parallax3_part3.png')
blur5x5_surface24_inplace_c(PARALLAX_PART3)
PARALLAX_PART3.set_colorkey((0, 0, 0), RLEACCEL)
# Asteroids
PARALLAX_PART4 = image_load('Assets/Graphics/Background/parallax3_part4.png')
blur5x5_surface24_inplace_c(PARALLAX_PART4)
PARALLAX_PART4.set_colorkey((0, 0, 0), RLEACCEL)

CLOUD_2 = image_load('Assets/Graphics/Background/cloud22_.png').convert()
# create_stars(cloud_2, dark_zone_exclusion=True)
THREAD2.update()
CLOUD_3 = image_load('Assets/Graphics/Background/cloud11_.png').convert()
PLATFORM_0 = image_load('Assets/Graphics/Background/A0.png').convert_alpha()
PLATFORM = image_load('Assets/Graphics/Background/A1.png').convert()
PLATFORM_2 = image_load('Assets/Graphics/Background/A2.png').convert()
PLATFORM_3 = image_load('Assets/Graphics/Background/A3.png').convert()
PLATFORM_4 = image_load('Assets/Graphics/Background/A4.png').convert()
PLATFORM_5 = image_load('Assets/Graphics/Background/A5.png').convert()
PLATFORM_6 = image_load('Assets/Graphics/Background/A6.png').convert()
PLATFORM_7 = image_load('Assets/Graphics/Background/A7.png').convert_alpha()
blur5x5_surface24_inplace_c(PLATFORM_7)  # blur the edges

# todo calculate the memory used looks hudge
STATION = image_load('Assets/Graphics/Background/Station1.png')
STATION = rotozoom(STATION, 0, 0.50)
# PLATFORM_8.set_colorkey((0, 0, 0, 0), RLEACCEL)
STATION.convert_alpha()
STATION_BUFFER = []
for i in range(0, 359):
    STATION_BUFFER.append(rotozoom(STATION, i, 1.0))




GROUND_CRACK1 = image_load('Assets/Graphics/Missiles/ground_cracks1.png').convert_alpha()
GROUND_CRACK2 = image_load('Assets/Graphics/Missiles/ground_cracks2.png').convert_alpha()
GROUND_CRACK3 = image_load('Assets/Graphics/Missiles/ground_cracks3.png').convert_alpha()
THREAD2.update()

G5V200_LIFE = image_load("Assets/Graphics/GUI/Device/switchGreen03.png")
G5V200_LIFE = pygame.transform.smoothscale(G5V200_LIFE, (84, 35))
G5V200_LIFE.convert()



SKULL = image_load("Assets/Graphics/Skull/skull.png")
SKULL.convert_alpha()
SKULL_1 = image_load("Assets/Graphics/Skull/toxigineSkull_.png")
SKULL_1.convert()

cdef float ONE_255 = <float>1.0 / <float>255.0

# BELOW USED BY THE LIGHT ENGINE (CURRENTLY NOT USED)
JETLIGHTCOLOR = numpy.array([<float>127.0 * ONE_255,
                             <float>173.0 * ONE_255, <float>249.0 * ONE_255], float32, copy=False)
JETLIGHT = image_load("Assets/display1.png").convert_alpha()
JETLIGHT = rotozoom(JETLIGHT, 180, 0.5)
JETLIGHT_ARRAY = pixels_alpha(JETLIGHT)
JETLIGHT_ARRAY_FAST = pixels_alpha(
    smoothscale(JETLIGHT, (JETLIGHT.get_width() >> 1, JETLIGHT.get_height() >> 1)))


WING_WARNING_LIGHT = numpy.array([<float>223.0 * <float>ONE_255,
                                  <float>17.0 * <float>ONE_255,
                                  <float>17.0 * <float>ONE_255], float32, copy=False)
WING_STANDBY_LIGHT = numpy.array([<float>250.0 * <float>ONE_255,
                                  <float>250.0 * <float>ONE_255,
                                  <float>250.0 * <float>ONE_255], float32, copy=False)
RADIAL3_621x621 = image_load("Assets/Radial4.png").convert_alpha()
RADIAL3_64x64 = smoothscale(RADIAL3_621x621, (128, 128))
RADIAL3_ARRAY_64x64 = pixels_alpha(RADIAL3_64x64)
RADIAL3_ARRAY_32x32_FAST = pixels_alpha(smoothscale(RADIAL3_64x64, (64, 64)))
#
#
#
# RADIAL4_128x128 = image_load("Assets/Radial4.png").convert_alpha()
# RADIAL4_128x128 = smoothscale(RADIAL4_128x128, (128, 128))
# RADIAL4_ARRAY_128x128 = pixels_alpha(RADIAL4_128x128)
# RADIAL4_ARRAY_64x64_FAST = pixels_alpha(smoothscale(RADIAL4_128x128, (64, 64)))
# RADIAL4_ARRAY_32x32_FAST = pixels_alpha(smoothscale(RADIAL4_128x128, (32, 32)))
#
# RADIAL4_256x256 = image_load("Assets/Radial4.png").convert_alpha()
# RADIAL4_256x256 = smoothscale(RADIAL4_256x256, (256, 256))
# RADIAL4_ARRAY_256x256 = pixels_alpha(RADIAL4_256x256)
#
# RADIAL4_512x512 = image_load("Assets/Radial4.png").convert_alpha()
# RADIAL4_512x512 = smoothscale(RADIAL4_512x512, (512, 512))
# RADIAL4_ARRAY_512x512 = pixels_alpha(RADIAL4_512x512)
# RADIAL4_ARRAY_256x256_FAST = pixels_alpha(RADIAL4_256x256)



BLOOD_SURFACE = image_load("Assets/redvignette1.png").convert_alpha()

# ------------------------------------------------------------------------------------------
MISSILE_TRAIL = []
MISSILE_TRAIL = sprite_sheet_fs8(
    'Assets/Graphics/Missiles/Smoke_trail_2_64x64.png', 64, 6, 6)

MISSILE_TRAIL_DICT = {}
w, h = MISSILE_TRAIL[0].get_size()

i = 0
b = -1.0
for image in MISSILE_TRAIL:
    f = i / <float>20.0

    saturation(image, b)
    if b < <float>1.0 - <float>0.038:
        b += <float>0.038
    else:
        b = <float>1.0
    blur(image, t_=i + <unsigned char>1)

    image = smoothscale(
        image, (int(w * (<unsigned char>1 + f)), int(h * (<unsigned char>1 + f)))).convert()
    MISSILE_TRAIL_DICT[i] = [image, image.get_rect()]
    i += <unsigned char>1

del MISSILE_TRAIL

MISSILE_TRAIL1 = []
MISSILE_TRAIL1 = sprite_sheet_per_pixel(
    'Assets/Graphics/Missiles/Smoke_trail_2_64x64_alpha.png', 64, 6, 6)


MISSILE_TRAIL_DICT1 = {}
w, h = MISSILE_TRAIL1[0].get_size()
i = 0
for image in MISSILE_TRAIL1:
    f = i / <float>20.0
    image = smoothscale(image, (int(w * (1 + f)), int(h * (1 + f))))
    MISSILE_TRAIL_DICT1[i] = [image, image.get_rect()]
    i += <unsigned char>1

del MISSILE_TRAIL1

MISSILE_TRAIL2 = []
MISSILE_TRAIL2 = sprite_sheet_fs8(
    'Assets/Graphics/Missiles/Smoke_trail_3_256x256_.png', 256, 7, 6)


# REMOVING THE FIRST 5 SPRITES
MISSILE_TRAIL2 = MISSILE_TRAIL2[4:]

w, h = MISSILE_TRAIL2[4].get_size()
w /= <float>3.0
h /= <float>3.0

MISSILE_TRAIL_DICT2 = {}

i = <int>0
b = <float>1.0
for image in MISSILE_TRAIL2:
    f = i / <float>20.0
    saturation(image, b)
    if b > -<float>0.035:
        b += -<float>0.035
    else:
        b = -<float>1.0

    blur(image, t_=i + <unsigned char>1)

    image = smoothscale(
        MISSILE_TRAIL2[i], (int(w * (<unsigned char>1 + f)),
                            int(h * (<unsigned char>1 + f)))).convert()
    MISSILE_TRAIL_DICT2[i] = [image, image.get_rect()]
    i += <unsigned char>1

del MISSILE_TRAIL2



MISSILE_TRAIL3 = []
MISSILE_TRAIL3 = sprite_sheet_fs8(
    'Assets/Graphics/Missiles/Smoke_trail_4_128x128_.png', 128, 8, 6)


w, h = MISSILE_TRAIL3[0].get_size()
w /= <float>2.0
h /= <float>2.0
MISSILE_TRAIL_DICT3 = {}
i = 0
b = <float>1.0
for image in MISSILE_TRAIL3:
    f = i / <float>20.0
    saturation(image, b)
    if b > -<float>0.035:
        b += -<float>0.035
    else:
        b = -<float>1.0

    blur(image, t_=i + <unsigned char>1)

    image = \
        smoothscale(
            image, (int(w * (<unsigned char>1 + f)),
                    int(h * (<unsigned char>1 + f)))).convert()
    MISSILE_TRAIL_DICT3[i] = [image, image.get_rect()]
    i += 1

del MISSILE_TRAIL3


STINGER_IMAGE         = pygame.image.load(
    'Assets/Graphics/Missiles/stinger/MISSILE1.png').convert_alpha()
BUMBLEBEE_IMAGE       = pygame.image.load(
    'Assets/Graphics/Missiles/Bumblebee/MISSILE2_.png')
BUMBLEBEE_IMAGE.set_colorkey((0, 0, 0), pygame.RLEACCEL)
WASP_IMAGE            = pygame.image.load(
    'Assets/Graphics/Missiles/Wasp/MISSILE3.png').convert_alpha()
HORNET_IMAGE          = pygame.image.load(
    'Assets/Graphics/Missiles/Hornet/MISSILE4.png').convert_alpha()


# MISSILE PRE-CALCULATED ROTATION
STINGER_ROTATE_BUFFER = {}
for a in range(360):
    image = rotozoom(STINGER_IMAGE, a, <float>0.9)
    rect  = image.get_rect()
    STINGER_ROTATE_BUFFER[a] = [image, rect]

BUMBLEBEE_ROTATE_BUFFER = {}
for a in range(360):
    image = rotozoom(BUMBLEBEE_IMAGE, a, <float>0.8)
    rect  = image.get_rect()
    BUMBLEBEE_ROTATE_BUFFER[a] = [image, rect]

WASP_ROTATE_BUFFER = {}
for a in range(360):
    image = rotozoom(WASP_IMAGE, a, <float>0.9)
    rect = image.get_rect()
    WASP_ROTATE_BUFFER[a] = [image, rect]

HORNET_ROTATE_BUFFER = {}
for a in range(360):
    image = rotozoom(HORNET_IMAGE, a, <float>0.9)
    rect = image.get_rect()
    HORNET_ROTATE_BUFFER[a] = [image, rect]



BLURRY_WATER1_ = reshape(BLURRY_WATER1, (100, 100))




# ---------------------------------------------------------------------------------------

print('Texture loading time (s) : ', round(time.time() - TIME))

THREAD2.update()

LoadScreen.my_event.set()

LOADING_SOUND.stop()


# ---------------------------------------------------------------------------------------

del WAIT
del LOADING_IMAGE