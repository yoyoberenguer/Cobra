import numpy
import pygame
from Enemy_ import ShieldClass
from Sprites import SHIELD_SOFT_RED, SHIELD_GLOW_RED, SHIELD_HEATGLOW
from Sounds import FORCE_FIELD_SOUND, SHIELD_DOWN_SOUND, SHIELD_IMPACT_SOUND_2


if not (__name__ == '__main__'):
    from Enemy_ import Raptor, Scout, Interceptor
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

ENEMIES_RAPTOR = [Raptor() for r in range(10)]
ENEMIES_SCOUT = [Scout() for r in range(14)]
ENEMIES_INTERCEPTOR = [Interceptor() for r in range(4)]

# Waves creation
# python dictionary containing enemies instances and specifics attributes like spawning time and Bezier curves.
# spawn : spawning time in the level (time in milli-seconds)
# path : specific path for the enemy instance
# Other attributes of the class can also be changed if necessary.

LEVEL1_WAVE0 = {
    ENEMIES_SCOUT[0]: {'spawn': 6,
                       'path': numpy.array([[125, 100], [125, 300], [125, 600], [125, 1200]]),
                       'pos': pygame.math.Vector2(125, -200)
                       },
    ENEMIES_SCOUT[1]: {'spawn': 5.5,
                       'path': numpy.array([[220, 100], [220, 300], [220, 600], [220, 1200]]),
                       'pos': pygame.math.Vector2(220, -200)
                       },
    ENEMIES_SCOUT[2]: {'spawn': 5,
                       'path': numpy.array([[315, 100], [315, 300], [315, 600], [315, 1200]]),
                       'pos': pygame.math.Vector2(315, -200)
                       },
    ENEMIES_SCOUT[3]: {'spawn': 5,
                       'path': numpy.array([[485, 100], [485, 300], [485, 600], [485, 1200]]),
                       'pos': pygame.math.Vector2(485, -200)
                       },
    ENEMIES_SCOUT[4]: {'spawn': 5.5,
                       'path': numpy.array([[580, 100], [580, 300], [580, 600], [580, 1200]]),
                       'pos': pygame.math.Vector2(580, -200)
                       },
    ENEMIES_SCOUT[5]: {'spawn': 6,
                       'path': numpy.array([[675, 100], [675, 300], [675, 600], [675, 1200]]),
                       'pos': pygame.math.Vector2(675, -200)
                       }

}
LEVEL1_WAVE1 = {
    ENEMIES_RAPTOR[0]: {'spawn': 10,
                        'path': numpy.array([[125, 100], [250, 300], [300, 600], [300, 1200]]),
                        'pos': pygame.math.Vector2(125, -200),
                        'shield': None
                        },
    ENEMIES_RAPTOR[1]: {'spawn': 12,
                        'path': numpy.array([[500, 100], [600, 300], [550, 600], [600, 1200]]),
                        'pos': pygame.math.Vector2(500, -200),
                        'shield': None
                        },
    ENEMIES_RAPTOR[2]: {'spawn': 10,
                        'path': numpy.array([[500, 100], [600, 300], [550, 600], [600, 1200]]),
                        'pos': pygame.math.Vector2(500, -200),
                        'shield': None,
                        },
    ENEMIES_RAPTOR[3]: {'spawn': 12,
                        'path': numpy.array([[125, 100], [250, 300], [300, 600], [300, 1200]]),
                        'pos': pygame.math.Vector2(125, -200),
                        'shield': None
                        }
}

LEVEL1_WAVE2 = {
    ENEMIES_INTERCEPTOR[0]: {'spawn': 15,
                        'path': numpy.array([[0, 55], [61, 65], [117, 91], [175, 150]]),
                        'pos': pygame.math.Vector2(0, -200),
                        #'shield': None
                        },
    ENEMIES_INTERCEPTOR[1]: {'spawn': 15,
                        'path': numpy.array([[800, 55], [739, 65], [683, 91], [625, 150]]),
                        'pos': pygame.math.Vector2(800, -200),
                        #'shield': None
                        },

    ENEMIES_SCOUT[6]: {'spawn': 15,
                        'path': numpy.array([[350, 100], [340, 300], [200, 450], [-200, 1200]]),
                        'pos': pygame.math.Vector2(350, -250),
                        'shield': None,
                        },
    ENEMIES_SCOUT[7]: {'spawn': 16,
                        'path': numpy.array([[350, 100], [340, 300], [200, 450], [-200, 1200]]),
                        'pos': pygame.math.Vector2(350, -250),
                        'shield': None
                        },
    ENEMIES_SCOUT[8]: {'spawn': 17,
                        'path': numpy.array([[350, 100], [340, 300], [200, 450], [-200, 1200]]),
                        'pos': pygame.math.Vector2(350, -250),
                        'shield': None
                       },
    ENEMIES_SCOUT[9]: {'spawn': 18,
                        'path': numpy.array([[350, 100], [340, 300], [200, 450], [-200, 1200]]),
                        'pos': pygame.math.Vector2(350, -250),
                        'shield': None},

    ENEMIES_SCOUT[10]: {'spawn': 15,
                        'path': numpy.array([[450, 100], [460, 300], [580, 450], [1000, 1200]]),
                        'pos': pygame.math.Vector2(450, -250),
                        'shield': None,
                        },
    ENEMIES_SCOUT[11]: {'spawn': 16,
                        'path': numpy.array([[450, 100], [460, 300], [580, 450], [1000, 1200]]),
                        'pos': pygame.math.Vector2(450, -250),
                        'shield': None
                        },
    ENEMIES_SCOUT[12]: {'spawn': 17,
                        'path': numpy.array([[450, 100], [460, 300], [580, 450], [1000, 1200]]),
                        'pos': pygame.math.Vector2(450, -250),
                        'shield': None
                       },
    ENEMIES_SCOUT[13]: {'spawn': 18,
                        'path': numpy.array([[450, 100], [460, 300], [580, 450], [1000, 1200]]),
                        'pos': pygame.math.Vector2(450, -250),
                        'shield': None}

                }


if __name__ == '__main__':
    # -------------- testing --------------------
    import ctypes

    for i, j in LEVEL1_WAVE1.items():
        enemy = ctypes.cast(id(i), ctypes.py_object).value
        enemy.override_attributes(j)

    for i, j in LEVEL1_WAVE1.items():
        enemy = ctypes.cast(id(i), ctypes.py_object).value
        print(enemy.path, enemy.spawn)
    # -------------------------------------------
