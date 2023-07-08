

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, BLEND_RGB_ADD, Rect, freetype
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface, \
        blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame.time import Clock
    from pygame.transform import scale, smoothscale, rotate, flip, rotozoom
except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from Sprites cimport LayeredUpdates
from Sprites import Group

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
        asarray, ascontiguousarray, linspace, ndarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

import os
from os import environ
from math import cos, sin, pi
cimport cython
import multiprocessing


# todo rename GLOBAL -> CONSTANT

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class GLOBAL(object):

    cdef:
        public int FRAME, MAXFPS, PLAYER_NUMBER, WOBBLY, SHOCKWAVE_INDEX, \
            screendump, ACCELERATION, FPS_VALUE, DIFFICULTY_VALUE

        public object CLOCK, MANUAL_PAUSE, EVENT_QUEUE, TRANSITION_BACKGROUND, \
            SCREEN, JOYSTICK, VERTEX_DEBRIS, PLAYER_GROUP, RATIO, screenrect, screen, \
            bgd10_vector, bgd7_vector, bgd8_vector, bgd9_vector, bgd11_vector, bgd12_vector, \
            bgd13_vector, bgd14_vector, bgd15_vector, vector1, shots, enemyshots, \
            enemy_group, bonus, gems, missiles, follower, nuke_aiming_point, anomaly_group, \
            All, SC_spaceship, SC_explosion, player, player2, GROUP_UNION, SHOCKWAVE_RANGE, \
            bv, FIRE_PARTICLES_FX, BOMB_CONTAINER, BOMB_CONTAINER_ADD, \
            DEBRIS_CONTAINER, DEBRIS_CONTAINER_ADD, KEYS, joy, P2JNI, FLARE_EFFECT_CENTRE, \
            LENS_VECTOR, LENS_VERTICAL_SPEED, LENS_VECTOR_SPEED, SHIP_NAME

        public bint STOP_GAME, PAUSE, aircraft_lights, SHOCKWAVE, FAIL, recording
        public tuple MOUSE_POS,
        public float TIME_PASSED_SECONDS, SOUND_LEVEL, MUSIC_LEVEL, SPEED_FACTOR, PAUSE_TIMER, \
            PAUSE_TOTAL_TIME, GAME_START, nuke
        public list VERTEX_IMPACT, VideoBuffer, CURRENT_TARGET, FPS_AVG, SCREEN_MODE, \
            PARTICLES_, DIFFICULTY
        public str DRIVER, SCREEN_MODE_VALUE, PARTICLES_VALUE

    def __init__(self):
        # Track the frame number
        self.FRAME                = 0
        # Clock object
        self.CLOCK                = Clock()
        # Bool to stop the game
        self.STOP_GAME            = False
        # Bool to pause the game
        self.PAUSE                = False
        # Event to manually stop the game (use for GUI)
        self.MANUAL_PAUSE         = multiprocessing.Event()
        # Event queue flag used for GUI
        self.EVENT_QUEUE          = multiprocessing.Queue()

        # Reference the transition surface when the game is starting
        # pygame.Surface
        self.TRANSITION_BACKGROUND = None
        self.SCREEN               = None
        self.MOUSE_POS            = (0, 0)
        # Time between clock ticks in milli-secondes
        self.TIME_PASSED_SECONDS  = 0.0
        self.JOYSTICK             = None
        self.SPEED_FACTOR         = 1.0
        self.aircraft_lights      = True

        # VERTEX IMPACT is a pygame sprite group containing the laser impact
        self.VERTEX_IMPACT        = []
        self.VERTEX_DEBRIS        = Group()

        self.PLAYER_GROUP         = Group()

        self.RATIO                = Vector2(0, 0)
        self.screenrect           = Rect(0, 0, 800, 1024)
        self.SHIP_NAME            = None
        self.PLAYER_NUMBER        = 0
        self.screen               = None

        self.bgd10_vector         = Vector2(0, 0)
        self.bgd7_vector          = Vector2(0, 0)
        self.bgd8_vector          = Vector2(0, 0)
        self.bgd9_vector          = Vector2(0, 0)
        self.bgd11_vector         = Vector2(0, 0)
        self.bgd12_vector         = Vector2(0, 0)
        self.bgd13_vector         = Vector2(0, 0)
        self.bgd14_vector         = Vector2(0, 0)
        self.bgd15_vector         = Vector2(0, 0)
        self.vector1              = Vector2(0, 0)
        self.shots                = Group()
        self.enemyshots           = Group()
        self.enemy_group          = Group()
        self.bonus                = Group()
        self.gems                 = Group()
        self.missiles             = Group()
        self.follower             = Group()
        self.nuke_aiming_point    = Group()
        self.anomaly_group        = Group()
        self.All                  = LayeredUpdates()  # | LayeredUpdatesModified()

        self.SC_spaceship         = None
        self.SC_explosion         = None

        self.player               = None
        self.player2              = None

        self.GROUP_UNION          = Group()

        self.WOBBLY               = 0
        self.SHOCKWAVE            = False  # True move the screen with a dampening variation (left - right)
        self.SHOCKWAVE_RANGE      = numpy.arange(0.0, 5.0, 0.1)
        self.SHOCKWAVE_INDEX      = 0  # Shockwave index, when reach the end of SHOCKWAVE_RANGE,
        # deactivate the shockwave effect

        self.GAME_START           = 0.0
        self.PAUSE_TOTAL_TIME     = 0.0
        self.PAUSE_TIMER          = 0.0

        self.bv                   = Vector2(0, 0)

        self.FAIL                 = False

        self.FIRE_PARTICLES_FX    = Group()
        self.BOMB_CONTAINER       = Group()
        self.BOMB_CONTAINER_ADD   = self.BOMB_CONTAINER.add
        self.DEBRIS_CONTAINER     = Group()
        self.DEBRIS_CONTAINER_ADD = self.DEBRIS_CONTAINER.add

        self.KEYS                 = Vector2(0, 0)

        # TODO NOT SURE BELOW IS USED
        self.joy                  = None
        # SCREENDUMP VALUE (THIS VALUE WILL BE ADDED TO THE FILENAME)
        self.screendump           = 0
        self.recording            = False  # Allow capturing video frames
        self.VideoBuffer          = []

        self.P2JNI                = None
        self.nuke                 = 0

        self.ACCELERATION         = 1

        self.SOUND_LEVEL          = 1.0
        self.MUSIC_LEVEL          = 1.0
        self.DRIVER               = 'windib'

        self.FLARE_EFFECT_CENTRE  = Vector2(697, -800)   # Vector2(697, -350)
        self.LENS_VECTOR          = Vector2(-400, 800)
        self.LENS_VERTICAL_SPEED  = Vector2(0, 1)
        self.LENS_VECTOR_SPEED    = Vector2(0, 0)

        # LIST CONTAINING ONLY ONE SPRITE (TARGETING SYSTEM FOCUS)
        # DISPLAY A RED SQUARE / LOZENGE ON AN ENEMY
        self.CURRENT_TARGET       = []

        # CURRENT FPS VALUE & AVERAGE
        self.MAXFPS               = 65 # 65
        self.FPS_VALUE            = 0
        self.FPS_AVG              = []


        self.SCREEN_MODE = ['Windowed', 'Fullscreen']
        self.SCREEN_MODE_VALUE = self.SCREEN_MODE[0]
        self.PARTICLES_ = ['Low', 'Medium', 'High']
        self.PARTICLES_VALUE = self.PARTICLES_[0]


        self.DIFFICULTY = ['EASY', 'MEDIUM', 'HARD']
        self.DIFFICULTY_VALUE = 1





pygame.init()

GAMEPATH = ''
PLAYER_LIFE = 1
# Max player HP
MAX_PLAYER_HITPOINTS = 1000
# MAX player energy
MAX_PLAYER_ENERGY = 10000
NO_MORE_MUSIC = pygame.USEREVENT + 2
# Degree to radian conversion
DEG_TO_RAD = pi / <float>180.0
# radian to degree conversion
RAD_TO_DEG = <float>1.0 / DEG_TO_RAD

COS = []
SIN = []
COS_SIN = zeros(shape=(360, 2))
i = 0
for degrees in range(360):
    COS.append(round(<float>cos(degrees * DEG_TO_RAD), 5))
    SIN.append(round(<float>sin(degrees * DEG_TO_RAD), 5))
    COS_SIN[i] = (round(<float>cos(degrees * DEG_TO_RAD), 5),
                  round(<float>sin(degrees * DEG_TO_RAD), 5))
    i += 1

GL = GLOBAL()


try:
    pygame.display.set_mode(GL.screenrect.size)
except pygame.error:
    os.environ['SDL_VIDEODRIVER'] = ""
    SCREEN = pygame.display.set_mode(GL.screenrect.size)

