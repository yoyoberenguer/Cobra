# encoding: utf-8
import pygame
from pygame import Rect
from math import cos, sin, pi
from threading import Lock
import numpy

"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """
__author__ = "Yoann Berenguer"
__copyright__ = "Copyright 2007, Cobra Project"
__credits__ = ["Yoann Berenguer"]
__license__ = "GPL"
__version__ = "1.0.0"
__maintainer__ = "Yoann Berenguer"
__email__ = "yoyoberenguer@hotmail.com"
__status__ = "Alpha Demo"

# --------------- Constant -------------

# Screen size
SCREENRECT = Rect(0, 0, 800, 1024)  # Screen dimension
WORD = 65535
# Difficulty level
DIFFICULTY = 'MEDIUM'

# Null variable
NULL = 0
# Null vector
NULLV = (0, 0)

RATIO = 1

GAMEPATH = ''

# Maximum shots display on the screen
MAX_SHOTS = 30
SUPERSHOT = False
# Maximum FPS
MAXFPS = 60
# Maximum space dust
SPACE_DUST = 100
# Stop the game
STOP_GAME = False
# Pause the game
PAUSE = False
PAUSE_TIMER = 0
PAUSE_TOTAL_TIME = 0
GAME_START = 0
# Frame number
FRAME = 0
# Max player HP
MAX_PLAYER_HITPOINTS = 1000
# Time constant
TIME_PASSED_SECONDS = 0
# variable used for space anomalies
SPACE_ANOMALY = False
# Music sound level
MUSIC_LEVEL = 0.3
# Sound level
SOUND_LEVEL = 1.0
# events
ELECTRICAL_BEAM_END = pygame.USEREVENT + 1
NO_MORE_MUSIC = pygame.USEREVENT + 2
# Degree to radian conversion
DEG_TO_RAD = pi / 180
# radian to degree conversion
RAD_TO_DEG = 1 / DEG_TO_RAD

# radius (in pixels) used for collision check
# object center distance from player < COLLISION_RANGE will be
# checked for collision
COLLISION_RADIUS = 200
# Collision group,
# All objects in the collision radius will be pushed into the
# collision group for an automated collision check (every frames)
COLLISION_GROUP = pygame.sprite.Group()

COS = []
SIN = []
COS_SIN = numpy.zeros(shape=(360, 2))
i = 0
for degrees in range(360):
    COS.append(round(cos(degrees * DEG_TO_RAD), 5))
    SIN.append(round(sin(degrees * DEG_TO_RAD), 5))
    COS_SIN[i] = (round(cos(degrees * DEG_TO_RAD), 5), round(sin(degrees * DEG_TO_RAD), 5))
    i += 1

del i



