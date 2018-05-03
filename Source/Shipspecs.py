# encoding: utf-8

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

from Constants import RATIO, MAX_PLAYER_HITPOINTS
from Weapons import DEFAULT_WEAPON, Weapons
import numpy
from numpy import clip


class MicroBotsClass:

    def __init__(self, name, hp_per_frame, max_hp_restoration):
        self.name = name
        self.hp_per_frame = hp_per_frame
        self.max_hp_restoration = max_hp_restoration


class ShipSpecs:
    # Military ranks
    # todo need to do a non-linear model
    RANKS = ['RECRUIT', 'RECRUIT GR-1', 'RECRUIT-GR-2', 'RECRUIT-GR-3', 'RECRUIT-GR4',
             'APPRENTICE', 'APPRENTICE-GR-1', 'APPRENTICE-GR-2', 'APPRENTICE-GR-3', 'APPRENTICE-GR-4',
             'PRIVATE', 'PRIVATE-GR-1', 'PRIVATE-GR2', 'PRIVATE-GR-3', 'PRIVATE 1ST CLASS',
             'CORPORAL', 'CORPORAL-GR-1', 'CORPORAL-GR-2', 'CORPORAL-GR-3', 'SPECIALIST',
             'SERGEANT', 'SERGEANT-GR-1', 'SERGEANT-GR-2', 'SERGEANT-GR-3', 'MASTER SERGEANT',
             'LIEUTENANT', 'LIEUTENANT-GR-1', 'LIEUTENANT-GR-2', 'LIEUTENANT-GR-3', 'WARRANT OFFICER',
             'CAPTAIN', 'CAPTAIN-GR-1', 'CAPTAIN-GR-2', 'CAPTAIN-GR-3', 'STAFF CAPTAIN',
             'MAJOR', 'MAJOR-GR-1', 'MAJOR-GR-2', 'MAJOR-GR-3', 'FIELD MAJOR',
             'COLONEL', 'COLONEL-GR-1', 'COLONEL-GR-2', 'COLONEL-GR-3', 'COMMANDER',
             'GENERAL', 'MAJOR GENERAL', 'LT.GENERAL', 'FLEET ADMIRAL', 'FIELD MARSHALL'
             ]

    def __init__(self, name: str, speed_x: int, speed_y: int, current_weapon: Weapons, max_energy: int,
                 energy: int, max_ammo: int, ammo: int, score: int, experience: int, level: int, missiles: int,
                 max_missiles: int, nukes: int, max_nukes: int,
                 microbots_quantity: int, microbotsclass: MicroBotsClass):
        """

        :param name: String, Spaceship name.
        :param speed_x: Integer, speed along the x axis
        :param speed_y: Integer, speed along the y axis
        :param current_weapon: Weapon in use
        :param max_energy: Maximum energy when fully charged
        :param energy: Energy available right now
        :param max_ammo: Maximum ammunition available when fully loaded
        :param ammo: Ammunition available right now
        :param score: Player score
        :param experience: Player experience
        :param level: Player level
        :param missiles: missiles on-board the ship
        :param max_missiles: maximum missiles loaded onboard
        :param nukes: Number of nukes
        :param max_nukes: Max nukes
        :param microbots_quantity: quantity of micro-bots
        :param microbots: MicroBots class
        """
        assert isinstance(name, str), 'Expecting string for argument name got: %s ' % type(name)

        assert (isinstance(speed_x, int) and isinstance(speed_y, int) and isinstance(max_energy, int)
                and isinstance(energy, int) and isinstance(max_ammo, int) and isinstance(ammo, int)
                and isinstance(score, int) and isinstance(experience, int) and isinstance(level, int)), \
            'Expecting integer only got: speed_x:%s, speed_y:%s, ' \
            'current_weapon:%s,\n ' \
            'max_energy:%s, energy:%s, max_ammo:%s, ammo:%s,\n score:%s, ' \
            'experience:%s,' \
            'level:%s ' % (type(speed_x), type(speed_y), type(current_weapon),
                           type(max_energy),
                           type(energy), type(max_ammo),
                           type(ammo), type(score),
                           type(experience), type(level))

        assert isinstance(current_weapon, Weapons), 'Expecting Weapons class for argument current_weapon ' \
                                                    'got: %s ' % type(Weapons)
        assert isinstance(missiles, int), 'Expecting int for argument missiles got: %s ' % type(missiles)
        assert isinstance(max_missiles, int), 'Expecting int for argument max_missiles got: %s ' % type(max_missiles)
        assert isinstance(nukes, int), 'Expecting int for argument nukes got: %s ' % type(nukes)
        assert isinstance(max_nukes, int), 'Expecting int for argument max_nukes got: %s ' % type(max_nukes)
        assert isinstance(microbots_quantity, int), \
            'Expecting int for argument microbots_quantity got: %s ' % type(microbots_quantity)
        assert isinstance(microbotsclass, MicroBotsClass), \
            'Expecting MicroBotsClass for argument microbotsclass got: %s ' % type(microbotsclass)
        self.name = name  # name of the player ship
        self.speed_x = speed_x  # Ship speed at 500 px/seconds along x axis
        self.speed_y = speed_y  # y speed is proportional to the screen size
        self.max_health = MAX_PLAYER_HITPOINTS  # Hard coded maximum hit a player can take
        self.life = MAX_PLAYER_HITPOINTS  # Player life
        # self.__life = 0
        self.current_weapon = current_weapon  # weapon in use
        self.max_energy = max_energy
        self.energy = energy  # in Megawatts
        # self.__energy = 0
        self.max_ammo = max_ammo  # Max ammo
        self.ammo = ammo  # Ammo bullets left
        self.__ammo = 0
        self.score = score  # player score
        self.experience = experience  # player experience for level up.
        self.level = level
        self.__level = 0
        self.ranks = ShipSpecs.RANKS[level]  # military ranks corresponding to the player level
        self.max_missiles = max_missiles
        self.missiles = missiles
        self.max_nukes = max_nukes
        self.nukes = nukes
        self.system_status = {'LW': (True, 100),
                              # Left wing, all weapon system located on the left wing will stop working
                              'RW': (True, 100),  # same on the right
                              'LE': (True, 100),  # Left engine, speed altered
                              'RE': (True, 100),  # speed altered
                              'T': (True, 100),  # Centre Turret, centre turret stop working
                              'N': (True, 100),  # Nuke Bombs. no bombs
                              'M': (True, 100),  # Missiles. No missiles
                              'S': (True, 100),  # Shield. Shield is down
                              'AA': (True, 100),  # Auto - Aim. this system is shutdown
                              'SUPER': (True, 100),  # Super
                              'COMBO': (True, 100)  # Combo shot
                              }
        self.microbots_quantity = microbots_quantity
        self.microbots = microbotsclass

    @property
    def level(self):
        return self.__level

    @level.setter
    def level(self, level):

        self.__level = level
        if level < 0:
            self.__level = 0
        elif level >= len(ShipSpecs.RANKS):
            self.__level = len(ShipSpecs.RANKS)
        # better method but very slow
        # self.__level = numpy.clip(level, 0, ShipSpecs.RANKS)
        return self.__level

    @property
    def nukes(self):
        return self.__nukes

    @nukes.setter
    def nukes(self, nukes):
        self.__nukes = nukes
        if nukes < 0:
            self.__nukes = 0
        elif nukes > self.max_nukes:
            self.__nukes = self.max_nukes
        return self.__nukes

    @property
    def energy(self):
        return self.__energy

    @energy.setter
    def energy(self, energy):
        self.__energy = energy
        if energy < 1:
            self.__energy = 0
        elif energy > self.max_energy:
            self.__energy = self.max_energy
        return self.__energy

    @property
    def life(self):
        return self.__life

    @life.setter
    def life(self, life):
        self.__life = life
        if life <= 0:
            self.__life = 0
        elif life > self.max_health:
            self.__life = self.max_health
        return self.__life

    @property
    def ammo(self):
        return self.__ammo

    @ammo.setter
    def ammo(self, ammo):
        self.__ammo = ammo
        if ammo < 0:
            self.__ammo = 0
        elif ammo > self.max_ammo:
            self.__ammo = self.max_ammo
        return self.__ammo

    @property
    def missiles(self):
        return self.__missiles

    @missiles.setter
    def missiles(self, missiles):
        self.__missiles = missiles
        if missiles < 0:
            self.__missiles = 0
        elif missiles > self.max_missiles:
            self.__missiles = self.max_missiles
        return self.__missiles


# restore 25% of player health
MICROBOTS_CLOUD = MicroBotsClass(name='CLOUD',
                                 hp_per_frame=2,
                                 max_hp_restoration=int(25 * MAX_PLAYER_HITPOINTS / 100))
# restore 50%
MICROBOTS_SWARM = MicroBotsClass(name='SWARM',
                                 hp_per_frame=2,
                                 max_hp_restoration=int(50 * MAX_PLAYER_HITPOINTS / 100))
# restore 75%
MICROBOTS_HIVE = MicroBotsClass(name='HIVE',
                                hp_per_frame=2,
                                max_hp_restoration=int(75 * MAX_PLAYER_HITPOINTS / 100))
# restore 100%
MICROBOTS_HORDE = MicroBotsClass(name='HORDE',
                                 hp_per_frame=2,
                                 max_hp_restoration=int(MAX_PLAYER_HITPOINTS))

# todo need to include life hp etc into the class
SHIP_SPECS = ShipSpecs(name='NEMESIS', speed_x=500, speed_y=round(500 * RATIO), current_weapon=DEFAULT_WEAPON,
                       max_energy=10000, energy=10000, max_ammo=5000, ammo=5000, score=0, experience=0, level=0,
                       missiles=24, max_missiles=24, nukes=3, max_nukes=3,
                       microbots_quantity=20, microbotsclass=MICROBOTS_CLOUD)
