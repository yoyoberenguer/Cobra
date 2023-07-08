# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


from PygameShader.shader import blur

from Background import create_stars, Background
from Dialogs import DialogBox
from Flares import polygon, TEXTURE2, second_flares, make_vector2d, TEXTURE, \
    TEXTURE1, create_flare_sprite, TEXTURE3, \
    STAR_BURST
from Follower import Follower
from GaussianBlur5x5 cimport blur5x5_array24_inplace_c, blur5x5_surface24_inplace_c
from GenericAnimation import GenericAnimation
from Shot import LIGHTS_VERTEX
from ShowDamage import DamageDisplay
from Sounds import LEVEL_UP
from SpriteSheet cimport sprite_sheet_fs8
from Textures import LEVEL_UP_MSG, LEVEL_UP_6, NUKE_BOMB_INVENTORY, \
    MISSILE_INVENTORY, RADIAL_LASER, PARALLAX_PART3, \
    PARALLAX_PART4, CLOUD_2, CLOUD_3, PLATFORM_0, PLATFORM, \
    PLATFORM_2, PLATFORM_3, PLATFORM_4, PLATFORM_5, PLATFORM_6, \
    PLATFORM_7, STATION, DIALOG, NAMIKO, HALO_SPRITE_WHITE
from XML_parsing import xml_get_background, xml_parsing_background

try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, linspace
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



from pygame.locals import K_PAUSE
# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, gfxdraw, \
        BLEND_RGB_ADD, BLEND_RGB_SUB, freetype, \
    SWSURFACE, RESIZABLE, FULLSCREEN, HWSURFACE, SCALED
    from pygame.freetype import STYLE_NORMAL
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d
    from pygame.image import frombuffer
    from pygame import Rect
    from pygame.time import get_ticks
    from pygame.draw import aaline
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotozoom
    from pygame.mixer import music

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from Sprites cimport Sprite, LayeredUpdates
from Sprites import Group
from libc.math cimport round as round_c

import time
import os
cimport numpy as np

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef toggle_fullscreen(gl_):
    # if already in FullScreen
    # When game goes into full screen, all object with alpha blend mode, will
    # be shifted toward the right side of the screen in 800x 1024 screen mode.
    # This issue seems to happen for screen dimension that are not natural or not
    # included into the pygame.display.list_modes list of available screens dimensions
    # When assigning a mode, pygame will try to match the closest screen dimension.
    # So for (800, 1024), the nearest match is (1280, 1024). The resulting offset is :
    # 1280 - 800 = 480 / 2 = 240 ( divide by to to center the Rect)
    # The total offset is then 240 from the left corner, this is why we can see am area of
    # x between 0, 240 that are not supporting the blending mode (offset +240 and not display
    # for x < 240. By changing the screen mode the display rectangle remains unchanged (width = 800,
    # height = 1024) but the screen has changed and all other sprites that are not using a blend
    # mode will match the new screen dimension.

    screenrect = gl_.screenrect
    screen_ = pygame.display.get_surface()

    if screen_.get_flags() & pygame.FULLSCREEN:
        pygame.display.set_mode(screenrect.size, HWSURFACE | SCALED, 32)
    else:
        try:
            print('\n[+]INFO - Current display information. %s ' % pygame.display.Info())
            print('\n[+]INFO - Available fullscreen mode: %s ' % pygame.display.list_modes())
            # pygame.display.set_mode((1024, 768), FULLSCREEN, 32)
            screen_     = pygame.display.set_mode((800, 1024), FULLSCREEN | SCALED,
                                                  32)

            screen_.set_alpha(None)
            screenrect = screen_.get_rect()
            print('\n[+]INFO - Screen flags %s ' % hex(screen_.get_flags()))
            print('\n[+]INFO - New display information\n %s ' % pygame.display.Info())
            print('\n[+]INFO - Surface size equivalent %s ' % screenrect)
            gl_.screen = screen_
        except pygame.error as e:
            print('\n[-] Error %s ' % e)
    gl_.PAUSE = False
    gl_.PAUSE_TOTAL_TIME += (time.time() - gl_.PAUSE_TIMER)
    print('game is not paused.')



PAUSE_FONT = freetype.Font(os.path.join('Assets/Fonts/', 'ARCADE_R.ttf'), size=14)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef game_pause(gl_, bint blur_=True):

    gl_screen = gl_.screen

    cdef:
        int w, h

    if blur_:
        scr = pygame.display.get_surface()
        w, h = scr.get_size()
        scr = smoothscale(scr, (w >> 1, h >> 1))
        # blur5x5_array24_inplace_c(pixels3d(scr))
        blur(scr)
        scr = smoothscale(scr, (w, h))
        gl_screen.blit(scr, (0, 0))
        rect1 = PAUSE_FONT.get_rect("Game is pause", style=STYLE_NORMAL, size=30)
        rect1.center = (gl_.screenrect.centerx - (rect1.w >> 1),
                        gl_.screenrect.centery - (rect1.h >> 1))
        PAUSE_FONT.render_to(gl_screen, rect1.center,
                             "Game is paused", fgcolor=Color(255, 255, 255), size=30)
    pygame.display.flip()

    pause_timer = gl_.PAUSE_TIMER
    cdef int t

    while gl_.PAUSE:

        pygame.event.pump()
        for event in pygame.event.get():

            keys = pygame.key.get_pressed()

            if keys[K_PAUSE]:
                t = (time.time() - pause_timer)
                gl_.PAUSE = False
                print('Pause : ', t)
                gl_.PAUSE_TOTAL_TIME += t
                print('Total time : ', gl_.PAUSE_TOTAL_TIME)
                pygame.event.clear()
                break
        pygame.time.wait(15)

    music.unpause()
    gl_.PAUSE = False

freetype.init(cache_size=64, resolution=72)
QUIT_MENU_FONT = freetype.SysFont('ARIALBLACK', size=18)


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class ShowFps(Sprite):

    cdef public object image, rect
    cdef float timing, fps
    cdef int layer, _blend, dt, size
    cdef object font, gl, white
    cdef tuple pos

    def __init__(self, gl_, float fps_, int layer_=0, int blend_=0, float timing_=60.0):
        """
        DISPLAY THE CURRENT FPS VALUE ON THE TOP LEFT CORNER OF THE DISPLAY

        :param gl_    : class; global constants/variables
        :param fps_   : float; Actual FPS value
        :param groups_: group; FPS sprite will be placed into that group
        :param layer_ : integer; Layer to (use default 0)
        :param blend_ : integer; Blending effect (Default no blending)
        :param timing_: float; Refreshing rate (default 60.0 FPS)
        """
        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.timing     = timing_
        self.fps        = fps_
        self.layer_     = layer_
        self._blend     = blend_
        self.image      = Surface((10, 10))
        self.pos        = 20, 350
        self.rect       = self.image.get_rect(topleft=self.pos)
        self.font       = QUIT_MENU_FONT
        self.font.antialiased = True
        self.gl         = gl_
        self.white      = Color(255, 255, 255, 255)
        self.dt         = 0
        self.size       = 10

    cpdef update(self, args=None):

        cdef int l

        if self.dt > self.timing:
            l    = <int>len(self.gl.FPS_AVG)
            avg  = round(sum(self.gl.FPS_AVG) / <float>l, 2) if l != 0 else 0.0
            text = 'fps : ' + str(round(self.gl.FPS_VALUE, 3)) + \
                   'avg : ' + str(avg)
            self.image, rect = self.font.render(
                text, fgcolor=self.white, style=STYLE_NORMAL, size=self.size)
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class ShowMousePosition(Sprite):

    cdef public object rect, image
    cdef float timing, layer_, _blend
    cdef tuple pos
    cdef object gl, white, font
    cdef int dt, size

    def __init__(self, gl_, int layer_=0, int blend_=0, float timing_=60.0):
        """
        DISPLAY THE CURRENT MOUSE POSITION VALUES (X, Y) ON THE TOP LEFT CORNER OF THE DISPLAY

        :param gl_        : class; global constants/variables
        :param groups_    : group; FPS sprite will be placed into that group
        :param layer_     : integer; Layer to (use default 0)
        :param blend_     : integer; Blending effect (Default no blending)
        :param timing_    : float; Refreshing rate (default 60.0 FPS)
        """
        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.timing     = timing_
        self.layer_     = layer_
        self._blend     = blend_
        self.image      = Surface((10, 10))
        self.pos        = 20, 400
        self.rect       = self.image.get_rect(topleft=self.pos)
        self.font       = QUIT_MENU_FONT
        self.font.antialiased = True
        self.gl         = gl_
        self.white      = Color(255, 255, 255, 255)
        self.dt         = 0
        self.size       = 10

    cpdef update(self, args=None):
        cdef gl = self.gl
        if self.dt > self.timing:
            text = 'pos (x, y) %s : frame: %s  display %s '  \
                   % (str(gl.MOUSE_POS),  gl.FRAME,
                      gl.screen.get_rect() if gl.screen is not None else 0)
            self.image, rect = self.font.render(
                text, fgcolor=self.white, style=STYLE_NORMAL, size=self.size)
            self.dt = 0

        self.dt += gl.TIME_PASSED_SECONDS


cdef list IMPACTBURST_INVENTORY = []

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class ImpactBurst(Sprite):

    cdef:
        long long int id
        bint loop, override_method
        int timing, index, dt, length, length2
        cdef object gl, object_, images
        public int _layer, _blend
        public object image, rect

    def __init__(self, gl_, containers_, object_, images_=None,
                 bint loop_=False, int timing_=33, int layer_=-3, blend_=0):
        """

        :param gl_:
        :param containers_:
        :param object_:
        :param images_:
        :param loop_:
        :param timing_:
        :param layer_:
        :param blend_:
        """

        if object_ in IMPACTBURST_INVENTORY:
            return

        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)


        self.override_method = False
        if images_ is None:
            self.override_method = True
            self.images          = object_.impact_sprite
            self.image           = object_.impact_sprite[0]
        else:
            self.images = images_
            self.image  = images_[0] if PyObject_IsInstance(images_, list) else images_

        self.rect   = self.image.get_rect(center=object_.rect.center)
        self.index  = 0
        self.id     = id(self)
        self.loop   = loop_
        self.timing = timing_
        self.dt     = 0
        self.gl     = gl_
        self._layer = layer_
        self.object_= object_
        self.length = len(self.images)
        self.lenght2= self.length >> 1

        IMPACTBURST_INVENTORY.append(object_)

    @classmethod
    def kill_event(cls, instance_):
        if instance_ in cls.gl.All:
            instance_.kill()

    cdef void quit(self):
        try:
            if self.object_ in IMPACTBURST_INVENTORY:
                IMPACTBURST_INVENTORY.remove(self.object_)
        except:
            pass

        finally:
            if hasattr(self, 'kill'):
                self.kill()

    cpdef update(self, args=None):

        if self.object_.alive():

            if self.dt > self.timing:

                obj_rect = self.object_.rect

                if self.length2 - 1 < self.index < self.length2 + 1:
                    DamageDisplay(self.gl.All, self.object_, 100, 'EXP')

                self.image = <object>PyList_GetItem(self.images, self.index)

                if self.override_method:
                    self.rect = self.image.get_rect(center=obj_rect.center)
                # OTHER
                else:
                    self.rect = self.image.get_rect(
                        center=(obj_rect.midbottom[0],
                                obj_rect.midbottom[1] - <unsigned char>10))

                self.index += 1

                if self.index >= self.length:
                    if self.loop:
                        self.index = 0
                    else:
                        self.quit()

                self.dt = 0

            self.dt += self.gl.TIME_PASSED_SECONDS

        else:
            self.quit()


EXPLOSION_INVENTORY = []

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Explosion1(Sprite):

    cdef:
        int index, dt, timing, len2
        object vector, images, object_, gl
        public int _layer, _blend
        public image, rect

    def __init__(self, gl_, containers_, object_,
                 int timing_= 33, int layer_= -1, vector_=None, int blend_=0):

        if object_ in EXPLOSION_INVENTORY:
            return

        if PyObject_HasAttr(object_, 'hp') and \
                PyObject_HasAttr(object_, 'explosion_sprites'):
            if object_.hp < 1:
                self.images = object_.explosion_sprites.copy()
                self.image  = self.images[0] if \
                    PyObject_IsInstance(self.images, list) else self.images
            else:
                return
        else:
            return

        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.rect   = self.image.get_rect(center=object_.rect.center)
        self.index  = 0
        self.dt     = 0
        self.timing = timing_
        self.vector = vector_
        self.len2   = len(self.images) >> 1
        self._layer = layer_
        self._blend = blend_
        self.gl     = gl_
        self.object_= object_

        EXPLOSION_INVENTORY.append(object_)

    cdef quit(self):
        try:
            if self.object_ in EXPLOSION_INVENTORY:
                EXPLOSION_INVENTORY.remove(self.object_)
        except:
            pass
        finally:
            if PyObject_HasAttr(self, 'kill'):
                self.kill()

    cpdef update(self, args=None):

        obj       = self.object_
        type_name = type(obj).__name__

        if self.dt > self.timing:

            # LOAD THE IMAGE
            self.image = <object>PyList_GetItem(self.images, self.index)

            if type_name in ("GroundEnemyTurret", "GroundEnemyDrone"):
                # EXPLOSION DO NOT FOLLOW THE OBJECT VELOCITY
                # THE EXPLOSION EFFECT WILL BE STATIC AT THE OBJ LOCATION AT THE TIME
                # OF THE EXPLOSION
                self.rect = self.image.get_rect(center=obj.rect.center)
            else:
                # EXPLOSION POSITION FOLLOW THE OBJECT VELOCITY
                if self.vector is not None:
                    self.rect.move_ip(self.vector)
                else:
                    # EXPLOSION DO NOT FOLLOW THE OBJECT VELOCITY
                    # THE EXPLOSION EFFECT WILL BE STATIC AT THE OBJ LOCATION AT THE TIME
                    # OF THE EXPLOSION
                    self.rect.center = obj.rect.center

            # Create a screen wobbly effect when destroying a turret
            if type_name == "GroundEnemyTurret":
                self.gl.WOBBLY = 5 if self.gl.WOBBLY in (0, -5) else -5
                self.gl.SHOCKWAVE = False

            if self.len2 - 1 < self.index < self.len2 + 1:
                DamageDisplay(self.gl.All, obj, 100, 'EXP')


            if self.index >= len(self.images) - 1:
                self.gl.WOBBLY = 0
                self.gl.SHOCKWAVE = False
                ComboKill(self.gl)
                self.quit()
                return

            self.index += 1
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
class ComboKill:
    _kill = 0
    _start = time.time()
    _watch = False

    def __init__(self, gl_):

        self.gl = gl_

        ComboKill._kill += 1

        # initialise variables
        if not ComboKill._watch:
            ComboKill._start = time.time()
            ComboKill._watch = True

        # todo finalize the bonus given to the player
        # checking the number of kills after 4 seconds
        # A Killstreak is earned when a player acquires a
        # certain number of kills in a row without dying
        if time.time() - ComboKill._start > 2:

            if ComboKill._kill > 11:
                self.bonus()
                self.message('Killing Streak X12')
            # 8 kills
            elif ComboKill._kill > 7:
                self.bonus()
                self.message('Fury X8')
            # 6 kills
            elif ComboKill._kill > 5:
                self.bonus()
                self.message('Rage X6')
            # 4 kills
            elif ComboKill._kill > 3:
                self.bonus()
                self.message('Aggressive X4')
            self.reset()

    def reset(self):
        """ Reset the variable """
        ComboKill._kill = 0
        ComboKill._watch = False

    def message(self, msg):
        """ Display a combo message """

        DamageDisplay(self.gl.All, None, 10, msg)
        pass

    def bonus(self):
        """
        Give extra life, experience, weapons, shield
        etc
        """
        pass



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
class Score:

    level_up_state = False

    def __init__(self, gl_, player_):
        """
        DISTRIBUTE POINTS TO PLAYER AFTER ENEMY KILLS

        :param gl_: Global constant instance
        :param player_: Player that must receive the bonus / points for destroying enemies
        """

        self.player = player_
        self.gl     = gl_

    def update(self, int score_):
        """
        UPDATE THE PLAYER SCORE AND EXPERIENCE.
        AND INITIATE A LEVEL UP IF ANY AVAILABLE

        :param score_: integer; Value of a destroyed target
        :return: void
        """
        cdef:
            player_specs = self.player.aircraft_specs  # get all the player specs
            sc = player_specs.score                    # get the current player score (sc)
            int i = 0
            int scores

        # increase the player score variable
        sc += score_

        # get the list of level up score corresponding to the different ranks
        cdef list level_score = list(player_specs.ranks.values())

        # going through all the ranks to check if the current score
        # is higher (inc a variable i to determine the max rank achieve after
        # player score retribution)
        for scores in level_score:
            if sc > scores:
                i += 1
                continue
            else:
                break

        # assign the score to the player
        self.player.aircraft_specs.score = sc

        # Assign the new player rank and run an level-up animation
        # level and int type variable (currently an index position for the
        # list RANKS list)
        if i > player_specs.level:
            self.player.aircraft_specs.level = i
            self.level_up()

    def level_up_animation(self):
        """
        PLAY A LEVEL UP ANIMATION

        :return:
        """

        if not Score.level_up_state:

            self.gl.SC_spaceship.stop_name('LEVEL_UP')

            self.gl.SC_spaceship.play(
                sound_      = LEVEL_UP,
                loop_       = False,
                priority_   = 0,
                volume_     = self.gl.SOUND_LEVEL,
                fade_out_ms = 0,
                panning_    = False,
                name_       = 'LEVEL_UP',
                x_          = 0)
            Score.level_up_state = False

            GenericAnimation(
                group_      = self.gl.All,
                images_     = LEVEL_UP_MSG,
                object_     = self.player,
                ratio_      = None,
                timing_     = 15,
                offset_     = None,
                event_name_ = 'LEVEL_UP',
                gl_         = self.gl,
                score_      = Score,
                loop_       = False,
                blend_      = 1
            )

            Follower(
                self.gl,
                self.gl.All,
                LEVEL_UP_6,
                offset_  = None,
                timing_  = 30,
                loop_    = False,
                event_   = 'level up',
                object_  = self.player,
                layer_   = -1,
                blend_   = 1)

    def level_up(self):

        cdef:
            int level = self.player.aircraft_specs.level
            dict ranks = self.player.aircraft_specs.ranks

        if self.player is not None:

            if self.player.alive():

                self.level_up_animation()

                if level < len(ranks):
                    self.player.aircraft_specs.rank = list(ranks.keys())[level]

                if self.player.current_weapon.level_up is not None:
                    self.player.current_weapon = self.player.current_weapon.level_up


SCORE_FONT = pygame.font.Font(os.path.join("Assets/Fonts", 'ARCADE_R.ttf'), 15)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class DisplayScore(Sprite):

    cdef:
        int dt, timing, old_score, i
        public object image, rect
        font, gl
        list cache_animation
        public int _layer, _blend

    def __init__(self, int timing_, gl_, int layer_=1, blend_=0):
        """

        :param timing_:
        :param gl_:
        """

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.dt              = 0
        self.image           = Surface((1,1))
        self.rect            = Rect(10, 10, 10, 10).move(300, 10)
        self.timing          = timing_
        self.font            = SCORE_FONT
        self.gl              = gl_
        self.old_score       = 0
        self.cache_animation = []
        self.i               = 0
        self._blend          = blend_
        self._layer          = layer_

    cpdef update(self, args=None):

        cdef:
            int len_cache = 0, score = 0, j =0
            list cache          = self.cache_animation

            int index           = self.i

        if self.dt > self.timing:

            if self.gl.player is not None:
                score += self.gl.player.aircraft_specs.score

            if self.gl.player2 is not None:
                score += self.gl.player2.aircraft_specs.score

            if self.old_score == self.gl.player.aircraft_specs.score:
                index += 1
            else:
                cache = [*[self.font.render('Score ' + str(score), True, (255, 255, 0))] * 32]

                len_cache = len(cache) >> 1
                zoom1 = linspace(1, 2, len_cache)
                zoom2 = linspace(2, 1, len_cache)
                zoom = [*zoom1, *zoom2]

                for surface in cache:
                    cache[j] = rotozoom(surface, 0, zoom[j])
                    j += 1

            self.image = cache[index] if len(cache) > 0 else \
                self.font.render('Score ' + str(score), True, (255, 255, 0))

            self.rect = self.image.get_rect()
            self.rect.topleft = ((pygame.display.get_surface().get_width() >> 1)
                                 - self.image.get_width() // 2, 15)

            if index >= len(cache) - 1:
                index = 0
                cache = []

            self.dt              = 0
            self.cache_animation = cache
            self.i               = index

        self.old_score = self.gl.player.aircraft_specs.score
        self.dt        += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class DisplayLife(Sprite):

    cdef:
        int dt, timing
        public object image, rect
        object image_copy, gl
        public int _blend, _layer


    def __init__(self, gl_, images_, int timing_= 33, int layer_=1, int blend_=0):

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        cdef int screenrect_w, screenrect_h
        cdef float ratio_x, ratio_y
        screenrect_w, screenrect_h = gl_.screenrect.size

        ratio_x = screenrect_w / <float>800.0
        ratio_y = screenrect_h / <float>1024.0

        self.dt         = 0
        self.image      = images_
        self.image_copy = self.image.copy()
        self.rect       = Rect(int(580 * ratio_x), int(85 * ratio_y),
                               self.image.get_width(), self.image.get_height())
        self.timing     = timing_
        self.gl         = gl_
        self._layer     = layer_
        self._blend     = blend_

    cpdef update(self, args=None):

        if self.dt > self.timing:

            new_image = Surface(self.image_copy.get_size()).convert()
            new_image.blit(self.image_copy, (0, 0),
                           (0, 0, 24 * (self.gl.player.aircraft_specs.life_number - 1), 32))
            new_image.set_colorkey((0, 0, 0, 0), RLEACCEL)
            self.image = new_image
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class DisplayNukesLeft(Sprite):

    cdef:
        int dt, timing
        public object image, rect
        object image_copy
        object gl
        public int _blend, _layer

    def __init__(self, gl_, int timing_= 33, int layer_=1, int blend_=0):

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.dt         = 0
        self.image      = NUKE_BOMB_INVENTORY.copy()
        self.image_copy = self.image.copy()
        self.rect       = Rect(120, 85, self.image.get_width(), self.image.get_height())
        self.timing     = timing_
        self.gl         = gl_

    cpdef update(self, args=None):

        if self.dt > self.timing:

            new_image = Surface(self.image_copy.get_size()).convert()
            new_image.blit(self.image_copy, (0, 0),
                           (0, 0, 32 * self.gl.player.aircraft_specs.nukes_quantity, 32))
            new_image.set_colorkey((0, 0, 0, 0), RLEACCEL)
            self.image = new_image
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS


MISSILE_FONT = freetype.Font(os.path.join('Assets/Fonts/', 'ARCADE_R.ttf'), size=12)


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class DisplayMissilesLeft(Sprite):

    cdef:
        int dt, h_, timing, prev_value
        object gl, font_, image_copy
        public object image, rect
        public int _blend, _layer

    def __init__(self, gl_, int timing_=33, int layer_=1, blend_=0):

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.dt         = 0
        self.image      = MISSILE_INVENTORY
        self.image_copy = self.image.copy()
        self.rect       = self.image.get_rect(
            topleft=(gl_.screenrect.w - self.image.get_width(), 85))
        self.font_      = MISSILE_FONT
        self.h_         = self.font_.get_sized_height()
        self.timing     = timing_
        self.prev_value = 0
        self.gl         = gl_
        self._layer     = layer_
        self._blend     = blend_

    cpdef update(self, args=None):

        if self.gl.player.aircraft_specs.missiles_quantity == self.prev_value:
            return

        if self.dt > self.timing:
            self.image = self.image_copy.copy()
            self.font_.render_to(self.image,
                                 (0, int(self.image_copy.get_height() - self.h_) >> 1),
                                 str(self.gl.player.aircraft_specs.missiles_quantity) + 'x',
                                 fgcolor=(220, 198, 12, 255))

            self.image.set_colorkey((0, 0, 0, 0), RLEACCEL)
            self.prev_value = self.gl.player.aircraft_specs.missiles_quantity
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void display_lights(screen_):
    """
    
    :param screen_: Surface; screen 
    :return: void
    """
    cdef:
        int w, h, w2, h2
        tuple r
    screen_blit = screen_.blit

    w, h = RADIAL_LASER.get_size()
    w2 = w >> 1
    h2 = h >> 1
    for sprite in LIGHTS_VERTEX:
        r = (sprite.rect.centerx - w2, sprite.rect.centery - h2)
        PyObject_CallFunctionObjArgs(
            screen_blit,
            <PyObject*> RADIAL_LASER,
            <PyObject*> r,
            <PyObject*> None,
            <PyObject*> BLEND_RGB_ADD,
            NULL)



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef laser_impact_fx(gl_):
    """
    
    :param gl_: 
    :return: 
    """
    cdef int x, y
    gl_screen   = gl_.screen
    screen_blit = gl_screen.blit
    cdef tuple r

    for sprite in gl_.VERTEX_IMPACT:

        sprite_rect = sprite.rect

        sprite.image = (<object>(PyList_GetItem(sprite.images, sprite.index))).convert()
        sprite.rect = sprite.image.get_rect(center=sprite.object.rect.center)

        if sprite.offset:
            x = sprite.offset[0]
            y = sprite.offset[1]
            r = (sprite_rect.centerx - x - (sprite_rect.w >> 1),
                 sprite_rect.centery - y - (sprite_rect.h >> 1))
            PyObject_CallFunctionObjArgs(
                screen_blit,
                <PyObject*> sprite.image,
                <PyObject*> r,
                <PyObject*> None,
                <PyObject*> BLEND_RGB_ADD,
                NULL)

        # CENTERED
        else:
            r = (sprite_rect.centerx - (sprite_rect.w >> 1),
                 sprite_rect.centery - (sprite_rect.h >> 1))
            PyObject_CallFunctionObjArgs(
                screen_blit,
                <PyObject*> sprite.image,
                <PyObject*> r,
                <PyObject*> None,
                <PyObject*> BLEND_RGB_ADD,
                NULL)


        sprite.index += 1

        if sprite.index > len(sprite.images) - 1:
            gl_.VERTEX_IMPACT.remove(sprite)

            if PyObject_HasAttr(sprite, 'kill'):
                sprite.kill()



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef background_layers(screenrect_, gl_):

    cdef int screenrect_w, screenrect_h
    cdef float ratio_x, ratio_y
    screenrect_w, screenrect_h = screenrect_.size

    # Game was designed for a display 800x1024
    # Any change in the screen resolution will modify the image ratio
    ratio_x = screenrect_w / <float>800.0
    ratio_y = screenrect_h / <float>1024.0

    if screenrect_w == 800 and screenrect_h ==600:
        background_surfaces = sprite_sheet_fs8(
            'Assets/Graphics/Background/SpaceBackground_800x1200_2.png',
            800, 1, 2, True, (800, 600), color_=None)

    if screenrect_w == 1024 and screenrect_h ==768:
        background_surfaces = sprite_sheet_fs8(
            'Assets/Graphics/Background/SpaceBackground_1024x1536_2.png',
            1024, 1, 2, True, (1024, 768), color_=None)

    else:
        # LOAD THE BACKGROUND (2 BLOCK OF 800x1024 WITH NO COLORKEY; color_=None)
        background_surfaces = sprite_sheet_fs8(
            'Assets/Graphics/Background/SpaceBackground_800x2048_3.png',
            screenrect_w, 1, 2, True, (screenrect_w, screenrect_h), color_=None)

    # ADD PIXEL TO THE BACKGROUND SURFACES (INPLACE)
    create_stars(background_surfaces[0])
    create_stars(background_surfaces[1])

    # RESCALE SPACE PARALLAX 1
    background       = background_surfaces[1].convert()
    background       = smoothscale(background,
                                   (int(background.get_width() * ratio_x),
                                    int(background.get_height() * ratio_y)))
    background       = smoothscale(background, (screenrect_w, screenrect_h))

    # RESCALE SPACE PARALLAX 2
    background_part2 = background_surfaces[0].convert()
    background_part2 = smoothscale(background_part2,
                             (int(background_part2.get_width() * ratio_x),
                              int(background_part2.get_height() * ratio_y)))
    background_part2 = smoothscale(background_part2, (screenrect_w, screenrect_h))

    # RESCALE THE CLOUDS
    cloud_2 = smoothscale(CLOUD_2, (int(CLOUD_2.get_width() * ratio_x),
                                    int(CLOUD_2.get_height() * ratio_y)))
    cloud_2 = smoothscale(cloud_2, (screenrect_w, screenrect_h))

    cloud_3 = smoothscale(CLOUD_3, (int(CLOUD_3.get_width() * ratio_x),
                                    int(CLOUD_3.get_height() * ratio_y)))
    cloud_3 = smoothscale(cloud_3, (screenrect_w, screenrect_h))

    # RESCALE ALL THE PARALLAX
    platform_0 = smoothscale(PLATFORM_0,
                             (int(PLATFORM_0.get_width() * ratio_x),
                              int(PLATFORM_0.get_height() * ratio_y)))
    platform_0 = smoothscale(platform_0, (screenrect_w, screenrect_h))

    platform_1 = smoothscale(PLATFORM,
                             (int(PLATFORM.get_width() * ratio_x),
                              int(PLATFORM.get_height() * ratio_y)))
    platform_1 = smoothscale(platform_1, (screenrect_w, screenrect_h))

    platform_2 = smoothscale(PLATFORM_2,
                             (int(PLATFORM_2.get_width() * ratio_x),
                              int(PLATFORM_2.get_height() * ratio_y)))
    platform_2 = smoothscale(platform_2, (screenrect_w, screenrect_h))

    platform_3 = smoothscale(PLATFORM_3,
                             (int(PLATFORM_3.get_width() * ratio_x),
                              int(PLATFORM_3.get_height() * ratio_y)))
    platform_3 = smoothscale(platform_3, (screenrect_w, screenrect_h))

    platform_4 = smoothscale(PLATFORM_4,
                             (int(PLATFORM_4.get_width() * ratio_x),
                              int(PLATFORM_4.get_height() * ratio_y)))
    platform_4 = smoothscale(platform_4, (screenrect_w, screenrect_h))

    platform_5 = smoothscale(PLATFORM_5,
                             (int(PLATFORM_5.get_width() * ratio_x),
                              int(PLATFORM_5.get_height() * ratio_y)))
    platform_5 = smoothscale(platform_5, (screenrect_w, screenrect_h))

    platform_6 = smoothscale(PLATFORM_6,
                             (int(PLATFORM_6.get_width() * ratio_x),
                              int(PLATFORM_6.get_height() * ratio_y)))
    platform_6 = smoothscale(platform_6, (screenrect_w, screenrect_h))

    platform_7 = smoothscale(PLATFORM_7,
                             (int(PLATFORM_7.get_width() * ratio_x),
                              int(PLATFORM_7.get_height() * ratio_y)))
    platform_7 = smoothscale(platform_7, (screenrect_w, screenrect_h))

    # SET THE BACKGROUND VECTOR
    bv = Vector2(0, 1)
    gl_.bv = bv

    s = -4072
    # SET THE VECTORS
    gl_.bgd10_vector = Vector2(0, s + screenrect_h)
    gl_.bgd7_vector  = Vector2(0, s)                     # platform     -4072
    gl_.bgd8_vector  = Vector2(0, s - 1 * screenrect_h)  # platform_2   -5096
    gl_.bgd9_vector  = Vector2(0, s - 2 * screenrect_h)  # platform_3   -6120
    gl_.bgd11_vector = Vector2(0, s - 3 * screenrect_h)  # 4
    gl_.bgd12_vector = Vector2(0, s - 4 * screenrect_h)  # 5
    gl_.bgd13_vector = Vector2(0, s - 5 * screenrect_h)  # 6
    gl_.bgd14_vector = Vector2(0, s - 6 * screenrect_h)  # 7
    # gl_.bgd15_vector = Vector2(0, -4072 - 7 * screenrect_h)  # 8
    gl_.bgd15_vector = Vector2(100, -screenrect_h * 2)

    gl_.vector1 = Vector2(gl_.bgd7_vector.x, gl_.bgd7_vector.y)

    im = pygame.image.load('Assets/Graphics/Asteroids/STATIC/ENCELA.png').convert()
    im.set_colorkey((0, 0, 0), RLEACCEL)
    im = smoothscale(im, (int((screenrect_h >> 1) * ratio_x), int(screenrect_h * ratio_y)))

    asteroid3_xml = xml_get_background('xml/Backgrounds.xml', 'ASTEROID3', gl_)
    if asteroid3_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted "
                                  "or xml entry for ASTEROID3 is missing")
    asteroid3_xml_dict = xml_parsing_background(dict(asteroid3_xml), gl_, screenrect_)
    Background(im, *list(asteroid3_xml_dict.values())[1:])

    asteroid1_xml = xml_get_background('xml/Backgrounds.xml', 'ASTEROID1', gl_)
    if asteroid1_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or "
                                  "xml entry for ASTEROID1 is missing")
    asteroid1_xml_dict = xml_parsing_background(dict(asteroid1_xml), gl_, screenrect_)
    Background(PARALLAX_PART3, *list(asteroid1_xml_dict.values())[1:])

    asteroid2_xml = xml_get_background('xml/Backgrounds.xml', 'ASTEROID2', gl_)
    if asteroid2_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or "
                                  "xml entry for ASTEROID2 is missing")
    asteroid2_xml_dict = xml_parsing_background(dict(asteroid2_xml), gl_, screenrect_)
    Background(PARALLAX_PART4, *list(asteroid2_xml_dict.values())[1:])

    # CLOUD PARALLAX 1
    cloud_xml = xml_get_background('xml/Backgrounds.xml', 'CLOUD', gl_)
    if cloud_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or "
                                  "xml entry for CLOUD is missing")
    cloud_xml_dict = xml_parsing_background(dict(cloud_xml), gl_, screenrect_)
    Background(cloud_3, *list(cloud_xml_dict.values())[1:])

    # CLOUD PARALLAX 2 (purple cloud)
    cloud2_xml = xml_get_background('xml/Backgrounds.xml', 'CLOUD1', gl_)
    if cloud2_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for CLOUD1 is missing")
    cloud2_xml_dict = xml_parsing_background(dict(cloud2_xml), gl_, screenrect_)
    Background(cloud_2, *list(cloud2_xml_dict.values())[1:])

    # SPACE BACKGROUND 1
    # FIRST PART
    back1_xml = xml_get_background('xml/Backgrounds.xml', 'back1', gl_)
    if back1_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for back1 is missing")
    back1_xml_dict = xml_parsing_background(dict(back1_xml), gl_, screenrect_)
    Background(background, *list(back1_xml_dict.values())[1:])

    # SPACE BACKGROUND 2
    # SECOND PART
    back2_xml = xml_get_background('xml/Backgrounds.xml', 'back2', gl_)
    if back2_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for back2 is missing")
    back2_xml_dict = xml_parsing_background(dict(back2_xml), gl_, screenrect_)
    Background(background_part2, *list(back2_xml_dict.values())[1:])

    # ENERGY HUD
    energy_xml = xml_get_background('xml/Backgrounds.xml', 'ENERGY', gl_)
    if energy_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or "
                                  "xml entry for ENERGY is missing")
    energy_xml_dict = xml_parsing_background(dict(energy_xml), gl_, screenrect_)
    Background(pygame.Surface((2, 2)), *list(energy_xml_dict.values())[1:])

    # LIFE HUD
    life_xml = xml_get_background('xml/Backgrounds.xml', 'LIFE', gl_)
    if life_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for LIFE is missing")
    life_xml_dict = xml_parsing_background(dict(life_xml), gl_, screenrect_)
    Background(pygame.Surface((2, 2)), *list(life_xml_dict.values())[1:])

    platform_0_xml = xml_get_background('xml/Backgrounds.xml', 'PLATFORM_0', gl_)
    if platform_0_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for PLATFORM_0 is missing")
    platform_0_xml_dict = xml_parsing_background(dict(platform_0_xml), gl_, screenrect_)
    Background(platform_0, *list(platform_0_xml_dict.values())[1:])

    # PLATFORM 1
    platform_1_xml = xml_get_background('xml/Backgrounds.xml', 'PLATFORM', gl_)
    if platform_1_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for PLATFORM is missing")
    platform_1_xml_dict = xml_parsing_background(dict(platform_1_xml), gl_, screenrect_)
    Background(platform_1, *list(platform_1_xml_dict.values())[1:])

    # PLATFORM 2
    platform_2_xml = xml_get_background('xml/Backgrounds.xml', 'PLATFORM_2', gl_)
    if platform_2_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for PLATFORM_2 is missing")
    platform_2_xml_dict = xml_parsing_background(dict(platform_2_xml), gl_, screenrect_)
    Background(platform_2, *list(platform_2_xml_dict.values())[1:])

    # PLATFORM 3
    platform_3_xml = xml_get_background('xml/Backgrounds.xml', 'PLATFORM_3', gl_)
    if platform_3_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for PLATFORM_3 is missing")
    platform_3_xml_dict = xml_parsing_background(dict(platform_3_xml), gl_, screenrect_)
    Background(platform_3, *list(platform_3_xml_dict.values())[1:])

    platform_4_xml = xml_get_background('xml/Backgrounds.xml', 'PLATFORM_4', gl_)
    if platform_4_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  "xml entry for PLATFORM_4 is missing")
    platform_4_xml_dict = xml_parsing_background(dict(platform_4_xml), gl_, screenrect_)
    Background(platform_4, *list(platform_4_xml_dict.values())[1:])

    platform_5_xml = xml_get_background('xml/Backgrounds.xml', 'PLATFORM_5', gl_)
    if platform_5_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for PLATFORM_5 is missing")
    platform_5_xml_dict = xml_parsing_background(dict(platform_5_xml), gl_, screenrect_)
    Background(platform_5, *list(platform_5_xml_dict.values())[1:])

    platform_6_xml = xml_get_background('xml/Backgrounds.xml', 'PLATFORM_6', gl_)
    if platform_6_xml is None:
        raise NotImplementedError("\nBackground XML file is corrupted or"
                                  " xml entry for PLATFORM_6 is missing")
    platform_6_xml_dict = xml_parsing_background(dict(platform_6_xml), gl_, screenrect_)
    Background(platform_6, *list(platform_6_xml_dict.values())[1:])

    platform_7_xml = xml_get_background('xml/Backgrounds.xml', 'PLATFORM_7', gl_)
    if platform_7_xml is None:
        raise NotImplementedError("\nxml/Background XML file is corrupted or "
                                  "xml entry for PLATFORM_7 is missing")
    platform_7_xml_dict = xml_parsing_background(dict(platform_7_xml), gl_, screenrect_)
    Background(platform_7, *list(platform_7_xml_dict.values())[1:])

    # # STATION
    # platform_8_xml = xml_get_background('Backgrounds.xml', 'PLATFORM_8', gl_)
    # if platform_8_xml is None:
    #     raise NotImplementedError("\nBackground XML file is corrupted or
    #     xml entry for PLATFORM_8 is missing")
    # platform_8_xml_dict = xml_parsing_background(dict(platform_8_xml), gl_, screenrect_)
    # Background(PLATFORM_8, *list(platform_8_xml_dict.values())[1:])

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef start_flare_effect(object gl_):

    cdef np.ndarray[np.int_t, ndim=2] octagon = polygon()
    cdef list exclude = [TEXTURE2]
    cdef list flare_inventory = []

    # BUILD FLARE INVENTORY
    flare_inventory_append = flare_inventory.append
    cdef int r = 0
    for r in range(10):
        flare_inventory_append(second_flares(
            TEXTURE, octagon.copy(), make_vector2d(gl_.FLARE_EFFECT_CENTRE), 0.8, 3, exclude))

    for r in range(8):
        flare_inventory_append(
            second_flares(TEXTURE1, octagon.copy(),
                          make_vector2d(gl_.FLARE_EFFECT_CENTRE), 0.8, 1.5, exclude))
    # DRAW GLARES
    for r in range(8):
        flare_inventory_append(
            second_flares(TEXTURE2, octagon.copy(),
                          make_vector2d(gl_.FLARE_EFFECT_CENTRE), 0.8, 1.5, exclude))

    for flares in flare_inventory:
        create_flare_sprite(gl_=gl_, images_=flares[0], distance_=flares[1],
                            vector_=gl_.LENS_VECTOR,
                            position_=gl_.FLARE_EFFECT_CENTRE, layer_=1,
                            blend_=BLEND_RGB_ADD, event_type='CHILD', delete_=False)

    create_flare_sprite(gl_=gl_, images_=TEXTURE3, distance_=2.0, vector_=gl_.LENS_VECTOR,
                        position_=gl_.FLARE_EFFECT_CENTRE, layer_=1,
                        blend_=BLEND_RGB_ADD, event_type='CHILD', delete_=False)

    create_flare_sprite(gl_=gl_, images_=STAR_BURST, distance_=0.5, vector_=gl_.LENS_VECTOR,
                        position_=gl_.FLARE_EFFECT_CENTRE, layer_=1,
                        blend_=BLEND_RGB_ADD, event_type='PARENT', delete_=False)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef start_dialog(object gl_):

    # MASAKO
    DialogBox(
        gl_         =gl_,
        location_   =(-DIALOG.get_width(), 150),
        scan_image  =pygame.image.load(
            "Assets/Graphics/Hud/icon_glareFx_blue - Copy.png").convert(),
        character   =NAMIKO,
        speed_      =15,
        layer_      =-3,
        voice_      =True,
        scan_       =True,
        direction_  ='RIGHT',
        text_color_ =(149, 119, 236, 245),
        fadein_     =0,
        fadeout_    =900,
        text        =["Protect the transport and",
                      "reach out  Altera the green",
                      "planet outside the asteroid",
                      "belt.",
                      "Over and out!.",
                      "Masako"],
        text_max_string_="planet outside the asteroid")

    # images = smoothscale(DIALOG, (370, 200))
    # COBRA
    DialogBox(
        gl_         =gl_,
        location_   =(-400, 450),
        scan_image  =pygame.image.load("Assets/Graphics/Hud/icon_glareFx_blue - Copy.png").convert(),
        character   =[pygame.image.load('Assets/Graphics/Characters/Cobra.png').convert(),
                      pygame.image.load('Assets/Graphics/Characters/Cobra1.png').convert()],
        speed_      =15,
        layer_      =-3,
        voice_      =True,
        scan_       =True,
        start_      =700,
        direction_  ='RIGHT',
        text_color_ =(249, 254, 56, 245),
        fadein_     =700,
        fadeout_    =1200,
        text        =["Green planet! uh?",
                      "hopefully I am not expecting",
                      "too much trouble on the way?"],
        text_max_string_="too much trouble on the way?")