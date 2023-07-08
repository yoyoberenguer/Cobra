
from Sounds import HEAVY_LASER1, TX0_FIRE1
from Textures import SPACESHIP_SPRITE, LASER_FX, LEVIATHAN, SHOOTING_SPRITE
import ctypes
import numpy
import pygame
from Enemy_ import ShieldClass, Scout, Interceptor,\
    GroundEnemyTurretSentinel, Raider, EnemyWeapons
from Constants import GL
from random import randint
from pygame.math import Vector2

from Enemy_ import Raptor, Scout, ScoutKamikaze, ColonyShipI, \
        Interceptor, GroundEnemyTurretSentinel, Raider, GroundEnemyDroneClass, \
    ShieldGeneratorClass

if not (__name__ == '__main__'):
    ...
else:


    class Raptor:
        """ Raptor class for testing purpose """

        def __init__(self):
            self.spawn = 1
            self.path = []
            self.stop = []
            pass

        def override_attributes(self, variables_: dict):
            """ override class attributes after instantiation """
            assert isinstance(variables_, dict), \
                'Expecting dict for argument variables, got %s ' % type(variables_)

            for attribute, value in variables_.items():
                if hasattr(self, str(attribute)):
                    setattr(self, str(attribute), value)
                else:
                    print('\n[-]WARNING - Attribute %s does not exist.' % attribute)

                    # raise AttributeError

#--------------------------------------------------------------------------------------------------


ENEMIES_RAPTOR = [Raptor() for r in range(100)]
ENEMIES_SCOUT = [Scout() for r in range(100)]
ENEMIES_SCOUT_KAMIKAZE = [ScoutKamikaze() for r in range(20)]
ENEMIES_COLONY_SHIP = [ColonyShipI() for r in range(20)]

ENEMIES_INTERCEPTOR = [Interceptor() for r in range(10)]
ENEMIES_TURRET_SENTINEL = [GroundEnemyTurretSentinel() for r in range(10)]
ENEMIES_DRONE = [GroundEnemyDroneClass() for r in range(50)]
ENEMIES_GENERATOR = [ShieldGeneratorClass() for r in range(2)]

ENEMIES_RAIDER = [Raider() for r in range(2)]

# Add 10 seconds delay
DELAY = 25

# Waves creation
# python dictionary containing enemies instances and specifics attributes
# like spawning time and Bezier curves.
# spawn : spawning time in the level (time in milli-seconds)
# path : specific path for the enemy instance
# Other attributes of the class can also be changed if necessary.

scout = 0
raptor = 0
interceptor = 0
colonyship = 0
kamikaze = 0
raider = 0

# 6 scouts in a single wave (V shape)
LEVEL1_WAVE0 = {
    # ENEMIES_DRONE[0]: {'spawn': 6,
    #                   'path': numpy.array([[207, 440], [390, 440], [390, 60], [1200, 60]]),
    #                   'pos': Vector2(125, -200),
    #                   'refreshing_rate': 0,
    #                   },

    ENEMIES_SCOUT[scout]: {'spawn': 6,
                           'path': numpy.array([[125, 100],
                                                [125, 300],
                                                [125, 600],
                                                [125, 1200]]),
                           'pos': Vector2(125, -200),
                           'speed': Vector2(4, 4),
                           # 'acceleration': numpy.array([1, 1, 1.1, 1.1, 1.2, 1.2,
                           # 1.3, 1.3, 1.4, 1.4,
                           #                             1.2, 1.2, 1.0, 1.0, 0.8, 0.7
                           #                             , 0.5, 0.4, 0.2, 0.1]),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 1]: {'spawn': 5.5,
                               'path': numpy.array([[220, 100],
                                                    [220, 300],
                                                    [220, 600],
                                                    [220, 1200]]),
                               'pos': Vector2(220, -200),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0
                               },
    ENEMIES_SCOUT[scout + 2]: {'spawn': 5,
                               'path': numpy.array([[315, 100],
                                                    [315, 300],
                                                    [315, 600],
                                                    [315, 1200]]),
                               'pos': Vector2(315, -200),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0
                               },
    ENEMIES_SCOUT[scout + 3]: {'spawn': 5,
                               'path': numpy.array([[485, 100],
                                                    [485, 300],
                                                    [485, 600],
                                                    [485, 1200]]),
                               'pos': Vector2(485, -200),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0
                               },
    ENEMIES_SCOUT[scout + 4]: {'spawn': 5.5,
                               'path': numpy.array([[580, 100],
                                                    [580, 300],
                                                    [580, 600],
                                                    [580, 1200]]),
                               'pos': Vector2(580, -200),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0
                               },
    ENEMIES_SCOUT[scout + 5]: {'spawn': 6,
                               'path': numpy.array([[675, 100],
                                                    [675, 300],
                                                    [675, 600],
                                                    [675, 1200]]),
                               'pos': Vector2(675, -200),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0
                               },
    ENEMIES_SCOUT[scout + 6]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -200),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 7]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -260),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 8]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -320),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 9]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -380),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 10]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -440),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 11]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -500),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 12]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -560),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 13]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -620),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 14]: {'spawn': 8,
                           'path': numpy.array([[700, 160],
                                                [500, 480],
                                                [320, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -680),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
   ENEMIES_SCOUT[scout + 15]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -200),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 16]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -260),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 17]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -320),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 18]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -380),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 19]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -440),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 20]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -500),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 21]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -560),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 22]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -620),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           },
    ENEMIES_SCOUT[scout + 23]: {'spawn': 11,
                           'path': numpy.array([[700, 320],
                                                [300, 480],
                                                [160, 200],
                                                [0, -200]]),
                           'pos': Vector2(850, -680),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           }

}
scout += 24


GROUND_WAVE1 = {
    ENEMIES_TURRET_SENTINEL[0]: {'pos': Vector2(492, +534),  # A1
                                 'speed': Vector2(0, 1)},
    ENEMIES_TURRET_SENTINEL[1]: {'pos': Vector2(200, +316),  # A1
                                 'speed': Vector2(0, 1)},
    ENEMIES_TURRET_SENTINEL[2]: {'pos': Vector2(170, +598 - GL.screenrect.h),  # A2
                                 'speed': Vector2(0, 1)},
    ENEMIES_TURRET_SENTINEL[3]: {'pos': Vector2(471, +598 - GL.screenrect.h),  # A2
                                 'speed': Vector2(0, 1)},
    ENEMIES_TURRET_SENTINEL[4]: {'pos': Vector2(300, +185 - GL.screenrect.h),  # A2
                                 'speed': Vector2(0, 1)},
    ENEMIES_TURRET_SENTINEL[5]: {'pos': Vector2(515, +202 - GL.screenrect.h),  # A2
                                 'speed': Vector2(0, 1)},
    ENEMIES_TURRET_SENTINEL[6]: {'pos': Vector2(297, +418 - 2 * GL.screenrect.h),  # A3
                                 'speed': Vector2(0, 1)},
    ENEMIES_TURRET_SENTINEL[7]: {'pos': Vector2(303, +237 - 4 * GL.screenrect.h),  # A5
                                 'speed': Vector2(0, 1)},
    ENEMIES_TURRET_SENTINEL[8]: {'pos': Vector2(600, +456 - 4 * GL.screenrect.h),  # A5
                                 'speed': Vector2(0, 1)}

}


GROUND_WAVE1_1 = {
    ENEMIES_GENERATOR[0]: {'pos': Vector2(250, +400),
                           'speed': Vector2(0, 1)}

}
"""
GROUND_WAVE2 = {
    ENEMIES_DRONE[0]: {
        'pos': Vector2(-20, 430),
        'path': numpy.array([[-20, 430], [390, 430], [390, 40], [1200, 40]])}
}
"""

GROUND_WAVE2 = {
    ENEMIES_DRONE[0]: {
        'pos': Vector2(120, 430)},
    ENEMIES_DRONE[1]: {
        'pos': Vector2(50, 430)},
    ENEMIES_DRONE[2]: {
        'pos': Vector2(-20, 430),
        'path': numpy.array([[-20, 430], [390, 430], [390, 40], [1200, 40]])},
    ENEMIES_DRONE[3]: {
        'pos': Vector2(900, 450),
        'path': numpy.array([[730, 450], [730, 200], [620, 200], [620, 100]])},
    ENEMIES_DRONE[4]: {
        'pos': Vector2(1000, 450),
        'path': numpy.array([[730, 450], [730, 200], [620, 200], [690, 100]])},
}


GROUND_WAVE3 = {
    ENEMIES_DRONE[5]: {
        'pos': Vector2(27, 291 -GL.screenrect.h),
        'path': numpy.array([[27, 291 - GL.screenrect.h], [187, 291 - GL.screenrect.h],
                             [250, 380 -GL.screenrect.h], [320, 490 -GL.screenrect.h]])},

    ENEMIES_DRONE[6]: {
        'pos': Vector2(715, 665 - GL.screenrect.h),
        'path': numpy.array([[715, 665 - GL.screenrect.h], [715, 330 - GL.screenrect.h],
                             [440, 330 -GL.screenrect.h], [320, 400 -GL.screenrect.h]])},
    ENEMIES_DRONE[7]: {
        'pos': Vector2(425, 100 - GL.screenrect.h),
        'path': numpy.array([[425, 100 - GL.screenrect.h], [726, 100 - GL.screenrect.h],
                             [726, 685 - GL.screenrect.h], [60, 685 - GL.screenrect.h]])},

    ENEMIES_DRONE[8]: {
        'pos': Vector2(120, 180 - 2 * GL.screenrect.h),
        'path': numpy.array([[120, 180 - 2 * GL.screenrect.h], [120, 498 - 2 * GL.screenrect.h],
                             [60, 650 - 2 * GL.screenrect.h], [60, 880 - 2 * GL.screenrect.h]])},
    ENEMIES_DRONE[9]: {
        'pos': Vector2(450, 508 - 2 * GL.screenrect.h),
        'path': numpy.array([[450, 508 - 2 * GL.screenrect.h], [715, 508 - 2 * GL.screenrect.h],
                             [715, 800 - 2 * GL.screenrect.h], [508, 800 - 2 * GL.screenrect.h]])},
    ENEMIES_DRONE[10]: {
        'pos': Vector2(70, 50 - 2 * GL.screenrect.h),
        'path': numpy.array([[70, 50 - 2 * GL.screenrect.h], [255, 50 - 2 * GL.screenrect.h],
                             [375, 50 - 2 * GL.screenrect.h], [375, 190 - 2 * GL.screenrect.h]])},
}


# 4 raptors in two waves
LEVEL1_WAVE1 = {
    ENEMIES_RAPTOR[raptor]: {'spawn': 10,
                             'path': numpy.array([[125, 100],
                                                  [250, 300],
                                                  [300, 600],
                                                  [300, 1200]]),
                             'pos': Vector2(125, -200),
                             'speed': Vector2(4, 4),
                             'shield': None,
                             'refreshing_rate': 0
                             },
    ENEMIES_RAPTOR[raptor + 1]: {'spawn': 12,
                                 'path': numpy.array([[500, 100],
                                                      [600, 300],
                                                      [550, 600],
                                                      [600, 1200]]),
                                 'pos': Vector2(500, -200),
                                 'speed': Vector2(4, 4),
                                 'shield': None,
                                 'refreshing_rate': 0
                                 },
    ENEMIES_RAPTOR[raptor + 2]: {'spawn': 10,
                                 'path': numpy.array([[500, 100],
                                                      [600, 300],
                                                      [550, 600],
                                                      [600, 1200]]),
                                 'pos': Vector2(500, -200),
                                 'speed': Vector2(4, 4),
                                 'refreshing_rate': 0,
                                 'shield': None
                                 },
    ENEMIES_RAPTOR[raptor + 3]: {'spawn': 12,
                                 'path': numpy.array([[125, 100],
                                                      [250, 300],
                                                      [300, 600],
                                                      [300, 1200]]),
                                 'pos': Vector2(125, -200),
                                 'speed': Vector2(4, 4),
                                 'refreshing_rate': 0,
                                 'shield': None
                                 }
}
raptor += 4

# 2 Interceptor flying straight  down
# 4 scouts flying to the left mid screen and 4 scouts flying to the right mid screen
LEVEL1_WAVE2 = {
    ENEMIES_INTERCEPTOR[interceptor]: {'spawn': 15,
                                       'path': numpy.array([[0, 55],
                                                            [61, 65],
                                                            [117, 91],
                                                            [180, 1800],
                                                            ]),
                                       'pos': Vector2(0, -200),
                                       # 'shield': None,
                                       'angle_follow_path': True,
                                       'speed': Vector2(2, 3),
                                       'refreshing_rate': 0
                                       },
    ENEMIES_INTERCEPTOR[interceptor + 1]: {'spawn': 18,
                                           'path': numpy.array([[800, 55],
                                                                [739, 65],
                                                                [683, 91],
                                                                [625, 1800],
                                                                ]),
                                           'pos': Vector2(800, -200),
                                           # 'shield': None,
                                           'angle_follow_path': True,
                                           'speed': Vector2(2, 3),
                                           'refreshing_rate': 0
                                           },

    ENEMIES_SCOUT[scout]: {'spawn': 15,
                           'path': numpy.array([[350, 100],
                                                [340, 300],
                                                [200, 450],
                                                [-200, 1200]]),
                           'pos': Vector2(350, -250),
                           'speed': Vector2(4, 4),
                           'refreshing_rate': 0,
                           'shield': None
                           },
    ENEMIES_SCOUT[scout + 1]: {'spawn': 16,
                               'path': numpy.array([[350, 100],
                                                    [340, 300],
                                                    [200, 450],
                                                    [-200, 1200]]),
                               'pos': Vector2(350, -250),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 2]: {'spawn': 17,
                               'path': numpy.array([[350, 100],
                                                    [340, 300],
                                                    [200, 450],
                                                    [-200, 1200]]),
                               'pos': Vector2(350, -250),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 3]: {'spawn': 18,
                               'path': numpy.array([[350, 100],
                                                    [340, 300],
                                                    [200, 450],
                                                    [-200, 1200]]),
                               'pos': Vector2(350, -250),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'shield': None
                               },

    ENEMIES_SCOUT[scout + 4]: {'spawn': 15,
                               'path': numpy.array([[450, 100],
                                                    [460, 300],
                                                    [580, 450],
                                                    [1000, 1200]]),
                               'pos': Vector2(450, -250),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 5]: {'spawn': 16,
                               'path': numpy.array([[450, 100],
                                                    [460, 300],
                                                    [580, 450],
                                                    [1000, 1200]]),
                               'pos': Vector2(450, -250),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 6]: {'spawn': 17,
                               'path': numpy.array([[450, 100],
                                                    [460, 300],
                                                    [580, 450],
                                                    [1000, 1200]]),
                               'pos': Vector2(450, -250),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 7]: {'spawn': 18,
                               'path': numpy.array([[450, 100],
                                                    [460, 300],
                                                    [580, 450],
                                                    [1000, 1200]]),
                               'pos': Vector2(450, -250),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'shield': None}

}
scout += 8
interceptor += 2

# 4 Raptors flying left to right mid screen
LEVEL1_WAVE3 = {
    ENEMIES_RAPTOR[raptor]: {'spawn': 24,
                             'path': numpy.array([[0, 160],
                                                  [200, 400],
                                                  [400, 720],
                                                  [1000, 880]]),
                             'pos': Vector2(0, -200),
                             'speed': Vector2(3, 3),
                             'refreshing_rate': 0,
                             'shield': None
                             },
    ENEMIES_RAPTOR[raptor + 1]: {'spawn': 25,
                                 'path': numpy.array([[0, 160],
                                                      [200, 400],
                                                      [400, 720],
                                                      [1000, 880]]),
                                 'pos': Vector2(0, -200),
                                 'speed': Vector2(3, 3),
                                 'refreshing_rate': 0,
                                 'shield': None
                                 },
    ENEMIES_RAPTOR[raptor + 2]: {'spawn': 26,
                                 'path': numpy.array([[0, 160],
                                                      [200, 400],
                                                      [400, 720],
                                                      [1000, 880]]),
                                 'pos': Vector2(0, -200),
                                 'speed': Vector2(3, 3),
                                 'refreshing_rate': 0,
                                 'shield': None,
                                 },
    ENEMIES_RAPTOR[raptor + 3]: {'spawn': 27,
                                 'path': numpy.array([[0, 160],
                                                      [200, 400],
                                                      [400, 720],
                                                      [1000, 880]]),
                                 'pos': Vector2(0, -200),
                                 'speed': Vector2(3, 3),
                                 'refreshing_rate': 0,
                                 'shield': None
                                 }
}
raptor += 4

# 4 raptors flying right to left mid screen
LEVEL1_WAVE4 = {
    ENEMIES_RAPTOR[raptor]: {'spawn': 29,
                             'path': numpy.array([[800, 160],
                                                  [600, 400],
                                                  [400, 720],
                                                  [-200, 880]]),
                             'pos': Vector2(800, -200),
                             'speed': Vector2(3, 3),
                             'refreshing_rate': 0,
                             'shield': None
                             },
    ENEMIES_RAPTOR[raptor + 1]: {'spawn': 30,
                                 'path': numpy.array([[800, 160],
                                                      [600, 400],
                                                      [400, 720],
                                                      [-200, 880]]),
                                 'pos': Vector2(800, -200),
                                 'speed': Vector2(3, 3),
                                 'refreshing_rate': 0,
                                 'shield': None
                                 },
    ENEMIES_RAPTOR[raptor + 2]: {'spawn': 31,
                                 'path': numpy.array([[800, 160],
                                                      [600, 400],
                                                      [400, 720],
                                                      [-200, 880]]),
                                 'pos': Vector2(800, -200),
                                 'speed': Vector2(3, 3),
                                 'refreshing_rate': 0,
                                 'shield': None,
                                 },
    ENEMIES_RAPTOR[raptor + 3]: {'spawn': 32,
                                 'path': numpy.array([[800, 160],
                                                      [600, 400],
                                                      [400, 720],
                                                      [-200, 880]]),
                                 'pos': Vector2(800, -200),
                                 'speed': Vector2(3, 3),
                                 'refreshing_rate': 0,
                                 'shield': None
                                 }
}
raptor += 4

# 2 scouts and 1 raptor V formation flying straight down
LEVEL1_WAVE5 = {
    ENEMIES_SCOUT[scout]: {'spawn': 34.4,
                           'path': numpy.array([[100, 200],
                                                [100, 400],
                                                [100, 720],
                                                [100, 1600]]),
                           'pos': Vector2(100, -200),
                           'refreshing_rate': 0,
                           'speed': Vector2(4, 4),
                           'shield': None
                           },
    ENEMIES_RAPTOR[raptor]: {'spawn': 34,
                             'path': numpy.array([[200, 200],
                                                  [200, 400],
                                                  [200, 720],
                                                  [200, 1600]]),
                             'pos': Vector2(200, -200),
                             'refreshing_rate': 0,
                             'speed': Vector2(3, 3),
                             'shield': None
                             },
    ENEMIES_SCOUT[scout + 1]: {'spawn': 34.4,
                               'path': numpy.array([[300, 200],
                                                    [300, 400],
                                                    [300, 720],
                                                    [300, 1600]]),
                               'pos': Vector2(300, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'shield': None
                               },
    # 2 scouts and 1 raptor V formation flying straight down
    ENEMIES_SCOUT[scout + 2]: {'spawn': 37.4,
                               'path': numpy.array([[200, 200],
                                                    [200, 400],
                                                    [200, 720],
                                                    [200, 1600]]),
                               'pos': Vector2(200, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'shield': None
                               },
    ENEMIES_RAPTOR[raptor + 1]: {'spawn': 37,
                                 'path': numpy.array([[300, 200],
                                                      [300, 400],
                                                      [300, 720],
                                                      [300, 1600]]),
                                 'pos': Vector2(300, -200),
                                 'refreshing_rate': 0,
                                 'speed': Vector2(3, 3),
                                 'shield': None
                                 },
    ENEMIES_SCOUT[scout + 3]: {'spawn': 37.4,
                               'path': numpy.array([[400, 200],
                                                    [400, 400],
                                                    [400, 720],
                                                    [400, 1600]]),
                               'pos': Vector2(400, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'shield': None
                               },
    # 2 scouts and 1 raptor V formation flying straight down
    ENEMIES_SCOUT[scout + 4]: {'spawn': 40.4,
                               'path': numpy.array([[300, 200],
                                                    [300, 400],
                                                    [300, 720],
                                                    [300, 1600]]),
                               'pos': Vector2(300, -200),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_RAPTOR[raptor + 2]: {'spawn': 40,
                                 'path': numpy.array([[400, 200],
                                                      [400, 400],
                                                      [400, 720],
                                                      [400, 1600]]),
                                 'pos': Vector2(400, -200),
                                 'speed': Vector2(3, 3),
                                 'refreshing_rate': 0,
                                 # 'shield': None
                                 },
    ENEMIES_SCOUT[scout + 5]: {'spawn': 40.4,
                               'path': numpy.array([[500, 200],
                                                    [500, 400],
                                                    [500, 720],
                                                    [500, 1600]]),
                               'pos': Vector2(500, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'shield': None
                               }
}
scout += 6
raptor += 3

LEVEL1_WAVE6 = {
    ENEMIES_SCOUT[scout]: {'spawn': 43,
                           'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                           'pos': Vector2(100, -200),
                           'speed': Vector2(4, 4),
                           'angle_follow_path': True,
                           'refreshing_rate': 0,
                           'shield': None
                           },
    ENEMIES_SCOUT[scout + 1]: {'spawn': 43.5,
                               'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                               'pos': Vector2(100, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 2]: {'spawn': 44,
                               'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                               'pos': Vector2(100, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               },

    ENEMIES_SCOUT[scout + 3]: {'spawn': 45.5,
                               'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                               'pos': Vector2(100, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 4]: {'spawn': 46,
                               'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                               'pos': Vector2(100, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 5]: {'spawn': 47.5,
                               'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                               'pos': Vector2(100, -200),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'angle_follow_path': True,
                               'shield': None
                               },

    ENEMIES_SCOUT[scout + 6]: {'spawn': 48,
                               'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                               'pos': Vector2(100, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 7]: {'spawn': 48.5,
                               'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                               'pos': Vector2(100, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 8]: {'spawn': 49,
                               'path': numpy.array([[100, 320], [100, 640], [250, 800], [1000, 320]]),
                               'pos': Vector2(100, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               }
}
scout += 9

LEVEL1_WAVE7 = {
    ENEMIES_SCOUT[scout]: {'spawn': 52,
                           'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                           'pos': Vector2(700, -200),
                           'speed': Vector2(4, 4),
                           'angle_follow_path': True,
                           'refreshing_rate': 0,
                           'shield': None
                           },
    ENEMIES_SCOUT[scout + 1]: {'spawn': 52.5,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'speed': Vector2(4, 4),
                               'refreshing_rate': 0,
                               'angle_follow_path': True,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 2]: {'spawn': 53,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'shield': None
                               },

    ENEMIES_SCOUT[scout + 3]: {'spawn': 53.5,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 4]: {'spawn': 54,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 5]: {'spawn': 54.5,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'shield': None
                               },

    ENEMIES_SCOUT[scout + 6]: {'spawn': 55,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 7]: {'spawn': 55.5,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 8]: {'spawn': 56,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'shield': None
                               },
    ENEMIES_SCOUT[scout + 9]: {'spawn': 56.5,
                               'path': numpy.array([[700, 320], [700, 640], [550, 800], [-200, 320]]),
                               'pos': Vector2(700, -200),
                               'refreshing_rate': 0,
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'shield': None
                               }
}
scout += 10

LEVEL1_WAVE8 = {
    ENEMIES_SCOUT[scout]: {'spawn': 58,
                           'path': numpy.array([[300, 160], [400, 320], [300, 480], [-200, 640]]),
                           'pos': Vector2(300, -200),
                           'speed': Vector2(4, 4),
                           'angle_follow_path': True,
                           'refreshing_rate': 0,
                           'shield': None
                           },

    ENEMIES_RAPTOR[raptor]: {'spawn': 58.5,
                             'path': numpy.array([[300, 160], [400, 320], [300, 480], [-200, 640]]),
                             'pos': Vector2(300, -200),
                             'speed': Vector2(3, 3),
                             'angle_follow_path': True,
                             'refreshing_rate': 0
                             # 'shield': None
                             },
    ENEMIES_SCOUT[scout + 1]: {'spawn': 59,
                               'path': numpy.array([[300, 160], [400, 320], [300, 480], [-200, 640]]),
                               'pos': Vector2(300, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0
                               # 'shield': None
                               },

    ENEMIES_SCOUT[scout + 2]: {'spawn': 59.5,
                               'path': numpy.array([[300, 160], [400, 320], [300, 480], [-200, 640]]),
                               'pos': Vector2(300, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0
                               # 'shield': None
                               },
    ENEMIES_SCOUT[scout + 3]: {'spawn': 60,
                               'path': numpy.array([[300, 160], [400, 320], [300, 480], [-200, 640]]),
                               'pos': Vector2(300, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0
                               # 'shield': None
                               },

    ENEMIES_SCOUT[scout + 4]: {'spawn': 60.5,
                               'path': numpy.array([[550, 320], [600, 480], [700, 600], [1000, 720]]),
                               'pos': Vector2(550, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               }
}
scout += 5
raptor += 1

LEVEL1_WAVE9 = {
    ENEMIES_SCOUT[scout]: {'spawn': 63,
                           'path': numpy.array([[125, 100],
                                                [125, 300],
                                                [125, 600],
                                                [125, 1200]]),
                           'pos': Vector2(125, -200),
                           'speed': Vector2(4, 4),
                           'angle_follow_path': True,
                           'refreshing_rate': 0,
                           'shield': None
                           },
    ENEMIES_RAPTOR[raptor]: {'spawn': 62.5,
                             'path': numpy.array([[220, 100],
                                                  [220, 300],
                                                  [220, 600],
                                                  [220, 1200]]),
                             'pos': Vector2(220, -200),
                             'speed': Vector2(3, 3),
                             'angle_follow_path': True,
                             'refreshing_rate': 0,
                             'shield': None
                             },
    ENEMIES_INTERCEPTOR[interceptor]: {'spawn': 62,
                                       'path': numpy.array([[315, 100],
                                                            [315, 300],
                                                            [315, 600],
                                                            [315, 1200]]),
                                       'pos': Vector2(315, -200),
                                       'speed': Vector2(2, 3),
                                       'angle_follow_path': True,
                                       'shield': None,
                                       'refreshing_rate': 0
                                       },
    ENEMIES_INTERCEPTOR[interceptor + 1]: {'spawn': 66,
                                           'path': numpy.array([[550, 100],
                                                                [550, 300],
                                                                [550, 600],
                                                                [550, 1200]]),
                                           'pos': Vector2(485, -200),
                                           'speed': Vector2(2, 3),
                                           'shield': None,
                                           'angle_follow_path': True,
                                           'refreshing_rate': 0
                                           },
    ENEMIES_RAPTOR[raptor + 1]: {'spawn': 66.5,
                                 'path': numpy.array([[580, 100],
                                                      [580, 300],
                                                      [580, 600],
                                                      [580, 1200]]),
                                 'pos': Vector2(580, -200),
                                 'speed': Vector2(3, 3),
                                 'angle_follow_path': True,
                                 'refreshing_rate': 0,
                                 'shield': None
                                 },
    ENEMIES_SCOUT[scout + 1]: {'spawn': 67,
                               'path': numpy.array([[675, 100],
                                                    [675, 300],
                                                    [675, 600],
                                                    [675, 1200]]),
                               'pos': Vector2(675, -200),
                               'speed': Vector2(4, 4),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None
                               }

}

scout += 2
interceptor += 2
raptor += 2

LEVEL1_WAVE10 = \
    {
        ENEMIES_RAIDER[raider]: {
            'spawn': 70,    # default 70
            'path': numpy.array([[200, 320],
                                 [250, 480],
                                 [350, 240],
                                 [350, 80]]),
            'pos': Vector2(450, -200),
            'speed': Vector2(3, 3),
            'refreshing_rate': 0,
            'angle_follow_path': False,

        },
        ENEMIES_RAIDER[raider+1]: {
            'spawn': 70,    # default 70
            'path': numpy.array([[400, 320],
                                 [450, 480],
                                 [350, 240],
                                 [550, 110]]),
            'pos': Vector2(450, -200),
            'speed': Vector2(3, 3),
            'refreshing_rate': 0,
            'angle_follow_path': False,
    }}

raider += 1

colonyship = 0
LEVEL1_WAVE11 = {
    ENEMIES_COLONY_SHIP[colonyship + 1]: {'spawn': 70,
                                          'path': numpy.array([[400, 160], [350, 320], [250, 400], [-200, 480]]),
                                          'pos': Vector2(400, -200),
                                          'angle_follow_path': True,
                                          'refreshing_rate': 0,
                                          'shield': None
                                          },

    ENEMIES_COLONY_SHIP[colonyship + 2]: {'spawn': 71,
                                          'path': numpy.array([[400, 160], [450, 320], [550, 400], [1000, 480]]),
                                          'pos': Vector2(400, -200),
                                          'angle_follow_path': True,
                                          'refreshing_rate': 0
                                          # 'shield': None
                                          },
    ENEMIES_COLONY_SHIP[colonyship + 3]: {'spawn': 72,
                                          'path': numpy.array([[400, 160], [350, 320], [250, 400], [-200, 480]]),
                                          'pos': Vector2(400, -200),
                                          'angle_follow_path': True,
                                          'refreshing_rate': 0
                                          # 'shield': None
                                          },

    ENEMIES_COLONY_SHIP[colonyship + 4]: {'spawn': 73,
                                          'path': numpy.array([[400, 160], [450, 320], [550, 400], [1000, 480]]),
                                          'pos': Vector2(400, -200),
                                          'angle_follow_path': True,
                                          'refreshing_rate': 0
                                          # 'shield': None
                                          },
    ENEMIES_COLONY_SHIP[colonyship + 5]: {'spawn': 74,
                                          'path': numpy.array([[400, 160], [350, 320], [250, 400], [-200, 480]]),
                                          'pos': Vector2(400, -200),
                                          'angle_follow_path': True,
                                          'refreshing_rate': 0
                                          # 'shield': None
                                          },
    ENEMIES_COLONY_SHIP[colonyship + 6]: {'spawn': 75,
                                          'path': numpy.array([[400, 160], [450, 320], [550, 400], [1000, 480]]),
                                          'pos': Vector2(400, -200),
                                          'angle_follow_path': True,
                                          'refreshing_rate': 0
                                          # 'shield': None
                                          },
    ENEMIES_COLONY_SHIP[colonyship + 7]: {'spawn': 76,
                                          'path': numpy.array([[400, 160], [350, 320], [250, 400], [-200, 480]]),
                                          'pos': Vector2(400, -200),
                                          'angle_follow_path': True,
                                          'refreshing_rate': 0
                                          # 'shield': None
                                          },
    ENEMIES_COLONY_SHIP[colonyship + 8]: {'spawn': 77,
                                          'path': numpy.array([[400, 160], [450, 320], [550, 400], [1000, 480]]),
                                          'pos': Vector2(400, -200),
                                          'angle_follow_path': True,
                                          'refreshing_rate': 0
                                          # 'shield': None
                                          },
}
colonyship += 8
t = 83
LEVEL1_WAVE12 = {
    ENEMIES_SCOUT_KAMIKAZE[kamikaze]: {'spawn': t,
                                       'path': numpy.array([[125, 100],
                                                            [125, 300],
                                                            [125, 600],
                                                            [125, 1200]]),
                                       'pos': Vector2(125, -200),
                                       'speed': Vector2(10, 10),
                                       'refreshing_rate': 0,
                                       'strategy': 'KAMIKAZE',
                                       'kamikaze_lock': False
                                       },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 1]: {'spawn': t + 1,
                                           'path': numpy.array([[220, 100],
                                                                [220, 300],
                                                                [220, 600],
                                                                [220, 1200]]),
                                           'pos': Vector2(220, -200),
                                           'speed': Vector2(10, 10),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 2]: {'spawn': t + 2,
                                           'path': numpy.array([[315, 100],
                                                                [315, 300],
                                                                [315, 600],
                                                                [315, 1200]]),
                                           'pos': Vector2(315, -200),
                                           'speed': Vector2(10, 10),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 3]: {'spawn': t + 3,
                                           'path': numpy.array([[485, 100],
                                                                [485, 300],
                                                                [485, 600],
                                                                [485, 1200]]),
                                           'pos': Vector2(485, -200),
                                           'speed': Vector2(15, 15),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 4]: {'spawn': t + 3.5,
                                           'path': numpy.array([[580, 100],
                                                                [580, 300],
                                                                [580, 600],
                                                                [580, 1200]]),
                                           'pos': Vector2(580, -200),
                                           'speed': Vector2(15, 15),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 5]: {'spawn': t + 4,
                                           'path': numpy.array([[675, 100],
                                                                [675, 300],
                                                                [675, 600],
                                                                [675, 1200]]),
                                           'pos': Vector2(675, -200),
                                           'speed': Vector2(15, 15),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 6]: {'spawn': t + 4.4,
                                           'path': numpy.array([[125, 100],
                                                                [125, 300],
                                                                [125, 600],
                                                                [125, 1200]]),
                                           'pos': Vector2(125, -200),
                                           'speed': Vector2(20, 20),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 7]: {'spawn': t + 4.8,
                                           'path': numpy.array([[220, 100],
                                                                [220, 300],
                                                                [220, 600],
                                                                [220, 1200]]),
                                           'pos': Vector2(220, -200),
                                           'speed': Vector2(20, 20),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 8]: {'spawn': t + 5.2,
                                           'path': numpy.array([[315, 100],
                                                                [315, 300],
                                                                [315, 600],
                                                                [315, 1200]]),
                                           'pos': Vector2(315, -200),
                                           'speed': Vector2(20, 20),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 9]: {'spawn': t + 5.7,
                                           'path': numpy.array([[485, 100],
                                                                [485, 300],
                                                                [485, 600],
                                                                [485, 1200]]),
                                           'pos': Vector2(485, -200),
                                           'speed': Vector2(20, 20),
                                           'refreshing_rate': 0,
                                           'strategy': 'KAMIKAZE',
                                           'kamikaze_lock': False
                                           },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 10]: {'spawn': t + 6.4,
                                            'path': numpy.array([[580, 100],
                                                                 [580, 300],
                                                                 [580, 600],
                                                                 [580, 1200]]),
                                            'pos': Vector2(580, -200),
                                            'speed': Vector2(20, 20),
                                            'refreshing_rate': 0,
                                            'strategy': 'KAMIKAZE',
                                            'kamikaze_lock': False
                                            },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 11]: {'spawn': t + 6.9,
                                            'path': numpy.array([[675, 100],
                                                                 [675, 300],
                                                                 [675, 600],
                                                                 [675, 1200]]),
                                            'pos': Vector2(675, -200),
                                            'speed': Vector2(20, 20),
                                            'refreshing_rate': 0,
                                            'strategy': 'KAMIKAZE',
                                            'kamikaze_lock': False
                                            },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 12]: {'spawn': t + 7.4,
                                            'path': numpy.array([[125, 100],
                                                                 [125, 300],
                                                                 [125, 600],
                                                                 [125, 1200]]),
                                            'pos': Vector2(125, -200),
                                            'speed': Vector2(20, 20),
                                            'refreshing_rate': 0,
                                            'strategy': 'KAMIKAZE',
                                            'kamikaze_lock': False
                                            },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 13]: {'spawn': t + 7.9,
                                            'path': numpy.array([[700, 100],
                                                                 [700, 300],
                                                                 [700, 600],
                                                                 [700, 1200]]),
                                            'pos': Vector2(700, -200),
                                            'speed': Vector2(20, 20),
                                            'refreshing_rate': 0,
                                            'strategy': 'KAMIKAZE',
                                            'kamikaze_lock': False
                                            },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 14]: {'spawn': t + 8.4,
                                            'path': numpy.array([[315, 100],
                                                                 [315, 300],
                                                                 [315, 600],
                                                                 [315, 1200]]),
                                            'pos': Vector2(315, -200),
                                            'speed': Vector2(20, 20),
                                            'refreshing_rate': 0,
                                            'strategy': 'KAMIKAZE',
                                            'kamikaze_lock': False
                                            },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 15]: {'spawn': t + 8.9,
                                            'path': numpy.array([[485, 100],
                                                                 [485, 300],
                                                                 [485, 600],
                                                                 [485, 1200]]),
                                            'pos': Vector2(485, -200),
                                            'speed': Vector2(20, 20),
                                            'refreshing_rate': 0,
                                            'strategy': 'KAMIKAZE',
                                            'kamikaze_lock': False
                                            },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 16]: {'spawn': t + 9.4,
                                            'path': numpy.array([[-200, 100],
                                                                 [-200, 300],
                                                                 [-200, 600],
                                                                 [-200, 1200]]),
                                            'pos': Vector2(-200, 100),
                                            'speed': Vector2(20, 20),
                                            'refreshing_rate': 0,
                                            'strategy': 'KAMIKAZE',
                                            'kamikaze_lock': False
                                            },
    ENEMIES_SCOUT_KAMIKAZE[kamikaze + 17]: {'spawn': t + 9.9,
                                            'path': numpy.array([[1200, 100],
                                                                 [1200, 300],
                                                                 [1200, 600],
                                                                 [1200, 1200]]),
                                            'pos': Vector2(1200, 100),
                                            'speed': Vector2(20, 20),
                                            'refreshing_rate': 0,
                                            'strategy': 'KAMIKAZE',
                                            'kamikaze_lock': False
                                            },

}

kamikaze += 17
# t+=9.9
t = 5

sprite = SHOOTING_SPRITE[6]
sprite1 = pygame.transform.rotate(sprite, -90)
sprite = LASER_FX[16]
sprite2 = pygame.transform.rotate(sprite, -90)
LEVEL1_WAVE13 = {
    ENEMIES_SCOUT[scout + 1]: {'spawn': t + 1,
                               'path': numpy.array([[200, GL.screenrect.h],
                                                    [200, 960],
                                                    [200, 560],
                                                    [-200, -200]]),
                               'pos': Vector2(200, GL.screenrect.h + 100),

                               'acceleration': numpy.array([1, 1, 1, 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.2,
                                                            0.3, 0.45, 0.65, 0.8, 1, 1, 1]),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None,
                               'object_animation': SPACESHIP_SPRITE,
                               'sprite_orientation': -90,
                               'invincible': True,
                               'collision_damage': 0,
                               'category': 'friend',
                               'laser': {'self.rect.center':
                                             EnemyWeapons(name_='GREEN_PHOTON_SINGLE', sprite_=sprite1,
                                                          range_=GL.screenrect.h,
                                                          velocity_=-25,
                                                          damage_=0, sound_effect_=HEAVY_LASER1,
                                                          volume_=GL.SOUND_LEVEL,
                                                          reloading_time_=0.4, animation_=None,
                                                          offset_=(0, -15))}
                               },

    ENEMIES_SCOUT[scout + 3]: {'spawn': t + 1,
                               'path': numpy.array([[600, GL.screenrect.h],
                                                    [600, 960],
                                                    [600, 560],
                                                    [GL.screenrect.w + 200, -200]]),
                               'pos': Vector2(600, GL.screenrect.h + 100),

                               'acceleration': numpy.array([1, 1, 1, 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.2,
                                                            0.3, 0.45, 0.65, 0.8, 1, 1, 1]),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None,
                               'object_animation': SPACESHIP_SPRITE,
                               'sprite_orientation': -90,
                               'invincible': True,
                               'collision_damage': 0,
                               'category': 'friend',
                               'laser': {'self.rect.center':
                                             EnemyWeapons(name_='GREEN_PHOTON_SINGLE', sprite_=sprite1,
                                                          range_=GL.screenrect.h,
                                                          velocity_=-25,
                                                          damage_=0, sound_effect_=HEAVY_LASER1,
                                                          volume_=GL.SOUND_LEVEL,
                                                          reloading_time_=0.4, animation_=None,
                                                          offset_=(0, -15))}
                               },
    ENEMIES_SCOUT[scout + 2]: {'spawn': t + 2,
                               'path': numpy.array([[300, GL.screenrect.h],
                                                    [300, 960],
                                                    [300, 560],
                                                    [-200, -200]]),
                               'pos': Vector2(300, GL.screenrect.h + 100),

                               'acceleration': numpy.array([1, 1, 1, 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.2,
                                                            0.3, 0.45, 0.65, 0.8, 1, 1, 1]),
                               'angle_follow_path': True,
                               'refreshing_rate': 0,
                               'shield': None,
                               'object_animation': LEVIATHAN,
                               'sprite_orientation': -90,
                               'invincible': True,
                               'collision_damage': 0,
                               'category': 'friend',
                               'laser': {'self.rect.center': EnemyWeapons(
                                    name_='GREEN_LASER_SINGLE', sprite_=sprite2,
                                  range_=GL.screenrect.h,
                                  velocity_=-25,
                                  damage_=0, sound_effect_=TX0_FIRE1,
                                  volume_=GL.SOUND_LEVEL,
                                  reloading_time_=0.4, animation_=None,
                                  offset_=(0, -15))}
                               },
    ENEMIES_SCOUT[scout + 4]: {
       'spawn': t + 2,
       'path': numpy.array([[500, GL.screenrect.h],
                            [500, 960],
                            [500, 560],
                            [GL.screenrect.w + 200, -200]]),
       'pos': Vector2(500, GL.screenrect.h + 100),

       'acceleration': numpy.array([1, 1, 1, 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.2,
                                    0.3, 0.45, 0.65, 0.8, 1, 1, 1]),
       'angle_follow_path': True, 'refreshing_rate': 0, 'shield': None,
       'object_animation': LEVIATHAN, 'sprite_orientation': -90, 'invincible': True,
       'collision_damage': 0, 'category': 'friend',
       'laser': {'self.rect.center': EnemyWeapons(name_='GREEN_LASER_SINGLE', sprite_=sprite2,
                                                  range_=GL.screenrect.h,
                                                  velocity_=-25,
                                                  damage_=0, sound_effect_=TX0_FIRE1,
                                                  volume_=GL.SOUND_LEVEL,
                                                  reloading_time_=0.4, animation_=None,
                                                  offset_=(0, -15))}
       }
}
scout += 4

del sprite, sprite1, sprite2


def combine_waves(gl_, enemyclass_, enemy_group_, wave_, layer_):

    for i, j in wave_.items():
        enemy = ctypes.cast(id(i), ctypes.py_object).value
        enemy.override_attributes(j)

        """
        # override all values of refreshing_rate
        if hasattr(enemy, 'refreshing_rate'):
            enemy.refreshing_rate = 10
        # override all the speed value to math the refreshing rate value
        if hasattr(enemy, 'speed'):
            enemy.speed *= 0.8
        """

        if hasattr(enemy, 'shield'):
            if enemy.shield is not None:
                """
                Initialise all the shield values 
                """
                enemy.shield.default()

        # Reset the timer for all weapons otherwise enemy won't shoot after being
        # destroyed by player (timestamp will stick to the previous GL.FRAME value)
        if hasattr(enemy, 'laser'):
            if enemy.laser is not None:
                for position, laser_type in enemy.laser.items():
                    laser_type.timestamp = 0

        # Add a delay to all instances before spawning
        if hasattr(enemy, 'spawn'):
            if DELAY and enemy.spawn:
                enemy.spawn += DELAY                    # Add the delay
                enemy.spawn = int(enemy.spawn * 60)     # Convert spawning time into a frame number

        # Choose an explosion sprite from a list of explosion
        if hasattr(enemy, 'explosion_sprites'):
            if isinstance(enemy.explosion_sprites, list):
                nsprite = len(enemy.explosion_sprites)
                sprite = enemy.explosion_sprites[randint(0, nsprite) - 1]
                if not isinstance(sprite, pygame.Surface):
                    enemy.explosion_sprites = sprite
            else:
                # Rotate and return all the surface's animation
                # print(enemy.name)
                # enemy.explosion_sprites = rotate(sprite, randint(0, 360))
                ...

        if enemyclass_.__name__ == 'Enemy':
            enemy_group_.add(
                enemyclass_(
                    gl_,
                    enemy.object_animation,
                    enemy,
                    enemy.refreshing_rate,
                    layer_))

        elif enemyclass_.__name__ == 'GroundEnemyTurret':
            enemy_group_.add(
                enemyclass_(
                    gl_,
                    enemy,
                    enemy.refreshing_rate,
                    layer_))

        elif enemyclass_.__name__ == 'GroundEnemyDrone':
            enemy_group_.add(
                enemyclass_(
                    gl_,
                    enemy,
                    enemy.refreshing_rate,
                    layer_))

    return enemy_group_


def level1(gl_, Enemy, GroundEnemyTurret, GroundEnemyDrone, GroundEnemyGenerator, enemy_group):
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE0, -4)  # V x 6 SCOUTS attach

    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE1, -4)  # 2 X 2 RAPTORS attach

    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE2, -4)
    # 2 INTERCEPTORS with shields

    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE3, -4)  # V shape attach 2
    # scouts, 1 raptor in front
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE4, -4)  # V shape attach 2
    # scouts, 1 raptor in front
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE5, -4)  # V shape attach 2
    # scouts, 1 raptor in front
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE6, -4)  # SCOUT U move (right
    # to left)
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE7, -4)  # SCOUT U move (Left
    # to right)
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE8, -4)  # Mixed of SCOUTS and
    # RAPTORS
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE9, -4)  # 2 INTERCEPTORS, 2
    # SCOUTS, 2 RAPTORS
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE10, -4)  # 2 INTERCEPTORS, 2
    # SCOUTS, 2 RAPTORS

    enemy_group = combine_waves(gl_, GroundEnemyTurret, enemy_group, GROUND_WAVE1, -5)
    # enemy_group = combine_waves(gl_, GroundEnemyGenerator, enemy_group, GROUND_WAVE1_1, -5)
    enemy_group = combine_waves(gl_, GroundEnemyDrone, enemy_group, GROUND_WAVE2, -5)
    enemy_group = combine_waves(gl_, GroundEnemyDrone, enemy_group, GROUND_WAVE3, -5)

    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE11, -4)  # scout parade
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE12, -4)  # Kamikaze
    enemy_group = combine_waves(gl_, Enemy, enemy_group, LEVEL1_WAVE13, -4)  # Player allies


    return enemy_group


if __name__ == '__main__':

    # -------------- testing --------------------
    import ctypes

    for i, j in LEVEL1_WAVE1.items():
        enemy = ctypes.cast(id(i), ctypes.py_object).value
        enemy.override_attributes(j)

    for i, j in LEVEL1_WAVE1.items():
        enemy = ctypes.cast(id(i), ctypes.py_object).value
        print(enemy.path, enemy.spawn)

    for i, j in GROUND_WAVE1.items():
        print(i, j)
        enemy = ctypes.cast(id(i), ctypes.py_object).value

    # -------------------------------------------
