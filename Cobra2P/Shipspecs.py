# encoding: utf-8


from Weapons import Weapons, STINGER_MISSILE, GREEN_PHOTON_1, GREEN_LASER_1,\
    BEAM, NUCLEAR_MISSILE, SHIELD_ACHILLES, \
    SHIELD_ANCILE, TURRET_GALATINE
from Textures import EXHAUST2_SPRITE, EXHAUST3_SPRITE, STINGER_IMAGE, MISSILE_TARGET_SPRITE, \
    NUKE_BOMB_TARGET, EXHAUST1_SPRITE, SPACESHIP_EXPLODE_NEMESIS, SPACESHIP_EXPLODE_LEVIATHAN, \
    NUKE_EXPLOSION_NEMESIS, NUKE_EXOLOSION_LEVIATHAN, TURRET_SHARK_DEPLOYMENT_RED, \
    LEVIATHAN_SHADOW, \
    COBRA_SHADOW

from Constants import MAX_PLAYER_HITPOINTS, \
    MAX_PLAYER_ENERGY, \
    PLAYER_LIFE


class MicroBotsClass:

    def __init__(self, name, hp_per_frame, max_hp_restoration):
        self.name = name
        self.hp_per_frame = hp_per_frame
        self.max_hp_restoration = max_hp_restoration


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


class ShipSpecs:
    status = {'LW': (True, 100),  # Left wing, all super_laser system located on the left
              # wing will stop working
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
    # Military ranks
    RANKS = {'RECRUIT': 0, 'RECRUIT GR-1': 5e3, 'RECRUIT-GR-2': 10e3, 'RECRUIT-GR-3': 20e3,
             'RECRUIT-GR4': 30e3,
             'PRIVATE': 32e3, 'PRIVATE-GR-1': 34e3, 'PRIVATE-GR2': 36e3, 'PRIVATE-GR-3': 38e3,
             'PRIVATE 1ST CLASS:': 40e3,
             'CORPORAL': 64e3, 'CORPORAL-GR-1': 70e3, 'CORPORAL-GR-2': 80e3, 'CORPORAL-GR-3': 90e3,
             'SPECIALIST': 100e3,
             'SERGEANT': 128e3, 'SERGEANT-GR-1': 40e3, 'SERGEANT-GR-2': 60e3,
             'SERGEANT-GR-3': 180e3,
             'MASTER SERGEANT': 200e3,
             'LIEUTENANT': 256e3, 'LIEUTENANT-GR-1': 280e3, 'LIEUTENANT-GR-2': 310e3,
             'LIEUTENANT-GR-3': 350e3,
             'WARRANT OFFICER': 400e3,
             'CAPTAIN': 512e3, 'CAPTAIN-GR-1': 600e3, 'CAPTAIN-GR-2': 650e3, 'CAPTAIN-GR-3': 750e3,
             'STAFF CAPTAIN': 850e3,
             'MAJOR': 1024e3, 'MAJOR-GR-1': 250e3, 'MAJOR-GR-2': 1450e3, 'MAJOR-GR-3': 1650e3,
             'FIELD MAJOR': 1850e3,
             'COLONEL': 2048e3, 'COLONEL-GR-1': 2400e3, 'COLONEL-GR-2': 2800e3,
             'COLONEL-GR-3': 3200e3,
             'COMMANDER': 4096e3, 'GENERAL': 6e6, 'MAJOR GENERAL': 9e6, 'LT.GENERAL': 12e6,
             'FLEET ADMIRAL': 24e6}

    # WHEN ADDING MORE ATTRIBUTES DON'T FORGET TO UPDATE METHOD __COPY__
    def __init__(self, name_: str, speed_x_: int, speed_y_: int, max_health_: int,
                 life_: int, current_weapon_: Weapons, max_energy_: int,
                 energy_: int, max_ammo_: int, ammo_: int, score_: int,
                 experience_: int, level_: int, missiles_quantity_: int,
                 max_missiles_quantity_: int, nukes_quantity_: int, max_nukes_quantity_: int,
                 microbots_quantity_: int, microbotsclass_: MicroBotsClass = MICROBOTS_CLOUD,
                 exhaust_sprite_=None,
                 exhaust_turbo_sprite_=EXHAUST2_SPRITE,
                 beam_=None, missiles_class_=None, missile_sprite_=None,
                 missile_target_sprite_=None,
                 missile_nuke_class_=None, nuke_target_sprite_=None, life_number_=None,
                 shield_=None, gems_=0,
                 gems_value_=0, turret_=None, debris_=None, nuke_explosion_sprite_=None,
                 wing_turret_number_=0, wing_turret_name_='SHARK',
                 wing_turret_sprite_=TURRET_SHARK_DEPLOYMENT_RED,
                 shadow_=None, collision_damage_=2000
                 ):

        """

        :param exhaust_turbo_sprite_:
        :param name_: String, Spaceship name.
        :param speed_x_: Integer, speed along the x axis
        :param speed_y_: Integer, speed along the y axis
        :param current_weapon_: Weapon in use
        :param max_energy_: Maximum energy when fully charged
        :param energy_: Energy available right now
        :param max_ammo_: Maximum ammunition available when fully loaded
        :param ammo_: Ammunition available right now
        :param score_: Player score
        :param experience_: Player experience
        :param level_: Player level
        :param missiles_quantity_: missiles on-board the ship
        :param max_missiles_quantity_: maximum missiles loaded onboard
        :param nukes_quantity_: Number of nukes
        :param max_nukes_quantity_: Max nukes
        :param microbots_quantity_: quantity of micro-bots
        :param microbotsclass_: MicroBots class
        :param gems_ : Number of gems gathered
        :param gems_value_: Total value of all gems
        :param turret_ : Turret class
        :param debris_ : Debris surface
        :param nuke_explosion_sprite_ : Nuke explosion sprites
        :param wing_turret_number_ : number of wing turret
        :param wing_turret_name_: name (SHARK etc)
        :param wing_turret_sprite_: turret sprite
        :param shadow_: shadow surface
        :param collision_damage_: amount of damage after collision (int)

        """
        assert isinstance(name_, str), 'Expecting string for argument name got: %s ' % type(name_)

        assert (isinstance(speed_x_, int) and isinstance(speed_y_, int) and
                isinstance(max_energy_, int)
                and isinstance(energy_, int) and isinstance(max_ammo_, int)
                and isinstance(ammo_, int)
                and isinstance(score_, int) and isinstance(experience_, int)
                and isinstance(level_, int)), \
            'Expecting integer only got: speed_x:%s, speed_y:%s, ' \
            'current_weapon:%s,\n ' \
            'max_energy:%s, energy:%s, max_ammo:%s, ammo:%s,\n score:%s, ' \
            'experience:%s,' \
            'level:%s ' % (type(speed_x_), type(speed_y_), type(current_weapon_),
                           type(max_energy_),
                           type(energy_), type(max_ammo_),
                           type(ammo_), type(score_),
                           type(experience_), type(level_))

        assert isinstance(current_weapon_, Weapons), \
            'Expecting Weapons class for argument current_weapon ' \
                                                     'got: %s ' % type(current_weapon_)
        assert isinstance(missiles_quantity_, int), \
            'Expecting int for argument missiles got: %s ' % type(missiles_quantity_)
        assert isinstance(max_missiles_quantity_, int), \
            'Expecting int for argument max_missiles got: %s ' % type(max_missiles_quantity_)
        assert isinstance(nukes_quantity_, int), 'Expecting int for argument nukes got: %s '\
                                                 % type(nukes_quantity_)
        assert isinstance(max_nukes_quantity_, int), \
            'Expecting int for argument max_nukes got: %s ' % type(max_nukes_quantity_)
        assert isinstance(microbots_quantity_, int), \
            'Expecting int for argument microbots_quantity got: %s ' % type(microbots_quantity_)
        assert isinstance(microbotsclass_, MicroBotsClass), \
            'Expecting MicroBotsClass for argument microbotsclass got: %s ' % type(microbotsclass_)
        self.name = name_

        self.speed_x = speed_x_
        self.speed_y = speed_y_

        self.max_health = max_health_
        self.life = life_

        self.current_weapon = current_weapon_

        self.max_energy = max_energy_
        self.energy = energy_

        self.max_ammo = max_ammo_
        self.ammo = ammo_
        self.__ammo = 0

        self.score = score_
        self.experience = experience_

        self.level = level_
        self.__level = 0

        self.ranks = ShipSpecs.RANKS
        self.rank = list(ShipSpecs.RANKS.keys())[self.level]

        self.max_missiles = max_missiles_quantity_
        self.missiles_quantity = missiles_quantity_

        self.max_nukes = max_nukes_quantity_
        self.nukes_quantity = nukes_quantity_

        self.system_status = ShipSpecs.status.copy()

        self.microbots_quantity = microbots_quantity_
        self.microbots = microbotsclass_
        self.wing_turret_sprite = wing_turret_sprite_

        assert exhaust_sprite_ is not None, 'exhaust_sprite should not be NoneType'
        self.exhaust_sprite = exhaust_sprite_
        self.beam = beam_
        self.missiles_class = missiles_class_
        self.missile_sprite = missile_sprite_
        self.missile_target_sprite = missile_target_sprite_
        self.missile_nuke_class = missile_nuke_class_
        self.nuke_target_sprite = nuke_target_sprite_
        self.life_number = life_number_
        self.shield = shield_
        self.exhaust_turbo_sprite = exhaust_turbo_sprite_
        self.gems = gems_
        self.gems_value = gems_value_
        self.turret = turret_
        self.debris = debris_
        self.nuke_explosion_sprite = nuke_explosion_sprite_
        self.wing_turret_number = wing_turret_number_
        self.wing_turret_name = wing_turret_name_
        self.shadow = shadow_
        self.collision_damage = collision_damage_

    @property
    def level(self):
        return self.__level

    @level.setter
    def level(self, level):
        # LEVEL CANNOT BE <0
        self.__level = level
        if level < 0:
            self.__level = 0
        # CAP THE LEVEL TO THE MAX RANK FLEET ADMIRAL
        elif level >= len(ShipSpecs.RANKS):
            self.__level = len(ShipSpecs.RANKS)

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
        # return self.__nukes

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
        # return self.__energy

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
        # return self.__life

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
        # return self.__ammo

    @property
    def missiles_quantity(self):
        return self.__missiles_quantity

    @missiles_quantity.setter
    def missiles_quantity(self, missiles):
        self.__missiles_quantity = missiles
        if missiles < 0:
            self.__missiles_quantity = 0
        elif missiles > self.max_missiles:
            self.__missiles_quantity = self.max_missiles
        # return self.__missiles_quantity

    def init(self):
        self.system_status = ShipSpecs.status.copy()
        self.life = MAX_PLAYER_HITPOINTS
        self.energy = MAX_PLAYER_ENERGY

    def __copy__(self):
        return ShipSpecs(self.name, self.speed_x, self.speed_y, self.max_health,
                         self.life, self.current_weapon,
                         self.max_energy, self.energy, self.max_ammo, self.ammo,
                         self.score, self.experience,
                         self.level, self.missiles_quantity, self.max_missiles,
                         self.nukes_quantity, self.max_nukes,
                         self.microbots_quantity, self.microbots, self.exhaust_sprite,
                         self.exhaust_turbo_sprite,
                         self.beam, self.missiles_class,
                         self.missile_sprite, self.missile_target_sprite, self.missile_nuke_class,
                         self.nuke_target_sprite, self.life_number, self.shield,
                         self.gems, self.gems_value,
                         self.turret, self.debris, self.nuke_explosion_sprite,
                         self.wing_turret_number,
                         self.wing_turret_name, self.wing_turret_sprite, self.shadow,
                         self.collision_damage)


NEMESIS_SPECS = ShipSpecs(name_='NEMESIS', speed_x_=500, speed_y_=500,
                          max_health_=MAX_PLAYER_HITPOINTS,
                          life_=MAX_PLAYER_HITPOINTS, current_weapon_=GREEN_PHOTON_1,
                          max_energy_=MAX_PLAYER_ENERGY, energy_=MAX_PLAYER_ENERGY,
                          max_ammo_=5000, ammo_=5000,
                          score_=0, experience_=0, level_=0, missiles_quantity_=24,
                          max_missiles_quantity_=24,
                          nukes_quantity_=3, max_nukes_quantity_=3, microbots_quantity_=3,
                          microbotsclass_=MICROBOTS_CLOUD, exhaust_sprite_=EXHAUST1_SPRITE,
                          exhaust_turbo_sprite_=EXHAUST2_SPRITE, beam_=BEAM['NEMESIS'],
                          missiles_class_=STINGER_MISSILE, missile_sprite_=STINGER_IMAGE,
                          missile_target_sprite_=MISSILE_TARGET_SPRITE,
                          missile_nuke_class_=NUCLEAR_MISSILE,
                          nuke_target_sprite_=NUKE_BOMB_TARGET, life_number_=PLAYER_LIFE,
                          shield_=SHIELD_ACHILLES.__copy__(), gems_=0, gems_value_=0,
                          turret_=TURRET_GALATINE.__copy__(), debris_=SPACESHIP_EXPLODE_NEMESIS,
                          nuke_explosion_sprite_=NUKE_EXPLOSION_NEMESIS,
                          wing_turret_number_=2, wing_turret_name_='SHARK',
                          wing_turret_sprite_=TURRET_SHARK_DEPLOYMENT_RED,
                          shadow_=COBRA_SHADOW, collision_damage_=1800)

LEVIATHAN_SPECS = ShipSpecs(name_='LEVIATHAN', speed_x_=500, speed_y_=500,
                            max_health_=MAX_PLAYER_HITPOINTS,
                            life_=MAX_PLAYER_HITPOINTS, current_weapon_=GREEN_LASER_1,
                            max_energy_=MAX_PLAYER_ENERGY, energy_=MAX_PLAYER_ENERGY,
                            max_ammo_=5000,
                            ammo_=5000, score_=0, experience_=0, level_=0, missiles_quantity_=24,
                            max_missiles_quantity_=24, nukes_quantity_=3, max_nukes_quantity_=3,
                            microbots_quantity_=3, microbotsclass_=MICROBOTS_SWARM,
                            exhaust_sprite_=EXHAUST3_SPRITE,
                            exhaust_turbo_sprite_=EXHAUST2_SPRITE,
                            beam_=BEAM['LEVIATHAN'], missiles_class_=STINGER_MISSILE,
                            missile_sprite_=STINGER_IMAGE,
                            missile_target_sprite_=MISSILE_TARGET_SPRITE,
                            missile_nuke_class_=NUCLEAR_MISSILE,
                            nuke_target_sprite_=NUKE_BOMB_TARGET, life_number_=PLAYER_LIFE,
                            shield_=SHIELD_ANCILE.__copy__(), gems_=0, gems_value_=0,
                            turret_=TURRET_GALATINE.__copy__(),
                            debris_=SPACESHIP_EXPLODE_LEVIATHAN,
                            nuke_explosion_sprite_=NUKE_EXOLOSION_LEVIATHAN,
                            wing_turret_number_=2, wing_turret_name_='SHARK',
                            wing_turret_sprite_=TURRET_SHARK_DEPLOYMENT_RED,
                            shadow_=LEVIATHAN_SHADOW, collision_damage_=2000)

if __name__ == '__main__':
    a = NEMESIS_SPECS.__copy__()
