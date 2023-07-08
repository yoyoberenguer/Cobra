# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from pygame import freetype, RLEACCEL, BLEND_RGBA_ADD, BLEND_RGB_ADD, \
    BLEND_RGB_SUB, BLEND_RGB_MULT, BLEND_RGB_MAX
from Sprites cimport Sprite
cimport cython

from Textures import FINAL_MISSION, DIALOGBOX_READOUT_RED

TEXT_FONT = freetype.Font('ASSETS/FONTS/GTEK TECHNOLOGY.TTF', size=14)
NUMBER_FONT = freetype.Font('ASSETS/FONTS/ARCADE_R.TTF', size=14)

cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;

@cython.binding(True)
@cython.boundscheck(True)
@cython.wraparound(True)
@cython.nonecheck(True)
@cython.cdivision(True)
@cython.profile(True)
cdef class PlayerLost(Sprite):

    cdef:
        public object image_copy, image, rect
        public int _layer
        object screen, screenrect, gl, font, rect1,\
            rect2, rect3
        int w2, h2, inc, r_w2, r_h2, _blend
        float dt, timing


    def __init__(self, gl_, int layer_=0, float timing_=16.67):


        Sprite.__init__(self, gl_.All)

        # self._layer     = layer_
        self.screen     = gl_.screen
        self.screenrect = self.screen.get_rect()
        self.image      = FINAL_MISSION.copy()
        self.image_copy = FINAL_MISSION.copy()
        self.w2, self.h2 = self.screenrect.w >> 1, \
                           self.screenrect.h >> 1
        self.rect = self.image.get_rect(
            topleft=(self.w2 - (self.image.get_width() >> 1),
                     (self.h2 - (self.image.get_height() >> 1))))
        self.inc         = 0
        self.dt          = 0.0
        self.timing      = timing_
        self.gl          = gl_
        self.font        = TEXT_FONT
        self._blend      = 0

        self.r_w2, self.r_h2 = self.rect.w >> 1, self.rect.h >> 1

        # Check the font characters that can be display.
        # Each fonts have their own number upper/lower case letters etc, some fonts
        # doesn't show number such as GTEK TECHNOLOGY.TTF

        # DISPLAY THE SKULL
        # self.image.blit(SKULL_1,
        #     (self.r_w2 - (SKULL_1.get_width() >> 1) ,
        #     self.r_h2  - (SKULL_1.get_height() >> 1)), special_flags=BLEND_RGBA_ADD)

        # DISPLAY GAME OVER
        rect1 = self.font.get_rect("game over", style=freetype.STYLE_NORMAL, size=35)
        self.font.render_to(self.image,
            (self.r_w2 - (rect1.w >> 1), 100), "game over", fgcolor=(220, 30, 25), size=35)

        # DISPLAY MISSION FAIL
        rect2 = self.font.get_rect("mission failed", style=freetype.STYLE_NORMAL, size=35)
        self.font.render_to(self.image,
            (self.r_w2 - (rect2.w >> 1), 155), "mission failed",
            fgcolor=(220, 30, 25), size=35)

        self.l = len(DIALOGBOX_READOUT_RED) - 1

        if gl_.player is not None:

            surf, rect3 = NUMBER_FONT.render(
                "player 1:",
                fgcolor=(220, 215, 25), size=16, style=freetype.STYLE_UNDERLINE)

            self.image.blit(surf, (85, 200), special_flags=0)

            if hasattr(gl_.player, 'aircraft_specs'):

                surf, rect3 = NUMBER_FONT.render(
                    "score:" + str(gl_.player.aircraft_specs.score),
                    fgcolor=(220, 215, 25), size=14, style=freetype.STYLE_STRONG)

                self.image.blit(surf, (85, 225), special_flags=0)

                surf, rect3 = NUMBER_FONT.render(
                    "gems:" + str(gl_.player.aircraft_specs.gems),
                    fgcolor=(220, 215, 25), size=14, style=freetype.STYLE_STRONG)

                self.image.blit(surf, (85, 250), special_flags=0)

        if gl_.player2 is not None:

            surf, rect4 = NUMBER_FONT.render(
                "player 2:",
                 fgcolor=(10, 222, 25), size=16, style=freetype.STYLE_UNDERLINE)

            self.image.blit(surf, (85, 300), special_flags=0)

            if hasattr(gl_.player2, 'aircraft_specs'):
                surf, rect4 = NUMBER_FONT.render(
                    "score:" + str(gl_.player2.aircraft_specs.score),
                    fgcolor=(10, 222, 25), size=14, style=freetype.STYLE_STRONG)

                self.image.blit(surf, (85, 325), special_flags=0)

                surf, rect4 = NUMBER_FONT.render(
                    "gems:" + str(gl_.player2.aircraft_specs.gems),
                    fgcolor=(10, 222, 25), size=14, style=freetype.STYLE_STRONG)

                self.image.blit(surf, (85, 350), special_flags=0)

        del rect1, rect2, rect3, rect4

        self.image_copy = self.image


    cpdef update(self, args=None):


        if self.dt > self.timing:

            self.image = self.image_copy.copy()

            self.image.blit(DIALOGBOX_READOUT_RED[self.inc % self.l],
                (80, 140), special_flags=BLEND_RGB_ADD)

            self.inc += 1

            self.dt = 0.0

        self.dt += self.gl.TIME_PASSED_SECONDS


#
# @cython.binding(False)
# @cython.boundscheck(False)
# @cython.wraparound(False)
# @cython.nonecheck(False)
# @cython.cdivision(True)
# @cython.profile(False)
# class PlayerWin(pygame.sprite.Sprite):
#     containers = None
#
#     def __init__(self, font_, image_, layer_=0):
#
#         self._layer = layer_
#         pygame.sprite.Sprite.__init__(self, PlayerWin.containers)
#
#         self.screen = pygame.display.get_surface()
#         self.screenrect = self.screen.get_rect()
#         self.image = image_
#         self.image_copy = image_
#         self.rect = self.image.get_rect(
#             topleft=((self.screenrect.w >> 1) - (self.image.get_width() >> 1),
#                      (self.screenrect.h >> 1) - (self.image.get_height() >> 1)))
#         self.inc = 0
#         self.green = pygame.Color(25, 124, 88, 0)
#         self.red_rect = self.rect.copy()
#         self.red_rect1 = self.rect.copy()
#         self.red_rect1.inflate_ip(-100, -100)
#         self.red_rect2 = self.rect.copy()
#         self.red_rect2.inflate_ip(-200, -200)
#         self.red_rect_default = self.red_rect1.copy()
#         self.font = font_
#         self.w2, self.h2 = self.screenrect.w >> 1, self.screenrect.h >> 1
#
#     def update(self):
#
#         self.image = self.image_copy.copy()
#
#         self.image.blit(DIALOGBOX_READOUT[self.inc % len(DIALOGBOX_READOUT) - 1],
#                         (80, 105), special_flags=pygame.BLEND_RGB_ADD)
#
#         pygame.draw.rect(self.screen, self.green, self.red_rect, 2)
#         pygame.draw.rect(self.screen, self.green, self.red_rect1, 2)
#         pygame.draw.rect(self.screen, self.green, self.red_rect2, 2)
#
#         if not self.screenrect.contains(self.red_rect):
#             self.red_rect = self.red_rect_default.copy()
#
#         if not self.screenrect.contains(self.red_rect1):
#             self.red_rect1 = self.red_rect_default.copy()
#
#         if not self.screenrect.contains(self.red_rect2):
#             self.red_rect2 = self.red_rect_default.copy()
#
#         self.red_rect.inflate_ip(4, 4)
#         self.red_rect1.inflate_ip(4, 4)
#         self.red_rect2.inflate_ip(4, 4)
#
#         rect1 = self.font.get_rect("stage clear", style=freetype.STYLE_NORMAL, size=35)
#         self.font.render_to(self.image,
#             (self.rect.w // <unsigned char>2 - rect1.w // <unsigned char>2, 125), "stage clear",
#             fgcolor=pygame.Color(60, 205, 64), size=35)
#
#         frame = self.gl.FRAME
#         xx = 200
#         x = self.rect.left + 100
#         self.font.render_to(self.image, (100, xx), "clear bonus",
#                             fgcolor=pygame.Color(247, 255, frame % 156), size=18)
#         xx += 50
#         self.font.render_to(self.image, (100, xx), "kill ratio",
#                             fgcolor=pygame.Color(247, 255, frame % 156), size=18)
#         xx += 50
#         self.font.render_to(self.image, (100, xx), "gems collected",
#                             fgcolor=pygame.Color(247, 255, frame % 156), size=18)
#         xx += 50
#         self.font.render_to(self.image, (100, xx), "life remaining",
#                             fgcolor=pygame.Color(247, 255, frame % 156), size=18)
#         xx += 50
#         self.font.render_to(self.image, (100, xx), "bombs remaining",
#                             fgcolor=pygame.Color(247, 255, frame % 156), size=18)
#         xx += 50
#         # self.image.blit(GR_LINE, (100, xx))
#         xx += 50
#         self.font.render_to(self.image, (100, xx), "total",
#                             fgcolor=pygame.Color(247, 255, frame % 156), size=18)
#
#         # self.image = hge(self.image, 0.1, 0.1, 20).convert()
#         self.image.set_colorkey((0, 0, 0, 0), pygame.RLEACCEL)
#
#         self.inc += 1
#
#
