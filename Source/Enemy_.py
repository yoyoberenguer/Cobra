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


import pygame
from Weapons import ShieldClass, TurretClass, Weapons

from Sprites import SPACE_FIGHTER_SPRITE, BURST_DOWN_RED, EXPLOSIONS, LAZER_FX, SHIELD_SOFT_RED, SHIELD_GLOW_RED, \
    SHIELD_HEATGLOW, RAPTOR_EXPLODE, SCOUT_SPRITE, INTERCEPTOR_SPRITE, BLAST1

from Sounds import IMPACT1, EXPLOSION_COLLECTION_SOUND, FIRE_BOLT_MICRO, FIRE_BOLT_MED, SHIELD_IMPACT_SOUND, \
    FORCE_FIELD_SOUND, SHIELD_DOWN_SOUND, SHIELD_IMPACT_SOUND_1, SHIELD_IMPACT_SOUND_2, IMPACT3, FIRE_BOLT_LONG, \
    INTERSTELLAR_GUN1

import numpy
from Constants import SCREENRECT, SOUND_LEVEL
from time import time


class EnemyWeapons:

    def __init__(self, name_: str, sprite_: (pygame.Surface, list), range_: int,
                 velocity_: pygame.math.Vector2, damage_: int,
                 sound_effect_: pygame.mixer.Sound, volume_: int, reloading_time_: float,
                 animation_: (pygame.Surface, list), offset_: tuple = (0, 0)):
        # Weapon system name
        self.name = name_

        # for compatibility with
        # other class
        self.type_ = 'LASER'

        # Sprite shot
        self.sprite = sprite_
        # Maximum range
        self.range = range_
        # shot magnitude (not direction)
        self.velocity = pygame.math.Vector2(0, velocity_)
        # maximum damage passed to the player
        self.damage = damage_
        # the shot's sound
        self.sound_effect = sound_effect_
        self.volume = volume_
        self.animation = animation_
        # Shooting timestamp
        self.timestamp = 0
        # Time for reloading the weapon in seconds.
        self.reloading_time = reloading_time_
        # Offset for laser shots
        self.offset = offset_

    def is_reloading(self):
        """ return True (reloading) or False ready to shoot
            Each weapon type have a specific reloading time, check
            Weapons.py to adjust the shooting rate for each weapon class.
        """
        if time() - self.timestamp >= self.reloading_time:

            # False equal not reloading
            self.timestamp = 0
            return False
        else:
            # True (reloading)
            return True

    def shooting(self):
        """ set the shooting timestamp """
        self.timestamp = time()


# Strategies (including fallback strategy).
_STRATEGY = [

    # search for direct collision with
    # the player spaceship.
    # Technique used by very light and fast enemy spaceships.
    'KAMIKAZE',

    # follow a pre-defined path in
    # group (bezier curves). No AI
    'PATH',

    # Keep out of range from secondary weapons like player turret(s).
    # spaceship with longer weapon range can also use this strategy.
    # Medium enemy ship with shield ability can also use that
    # technique
    'KEEP DISTANCE',

    # tactic used by heavy spaceships always facing player position
    # and protecting lighter enemy.
    # equipped with a powerful shield deflector for blocking
    # all player's attacks (including beam, proton, missiles)
    # Shield can be disrupted or deactivate with heavy missiles and nuke
    # (also super combo attacks and deathRay have a devastating effect on the
    # shield energy.
    'SHIELD',

    # Spaceship with cloaking abilities can deliver a powerful shot at short range
    # without being easily noticed by the player during the battle.
    # The spaceship has to disable the cloaking device before firing up.
    # Spaceship will usually withdraw during the cloaking re-activation process.
    'CLOAKING',

    # Light spaceship turning around a focal point (elliptically)
    'COSSACK',

    # This slow enemy spaceship will explode close to the player location releasing
    # a devastating blast wave that could potentially de-activate the player
    # shield or destroy the player spaceship.
    # Aim slowly to the player location and detonate in a short range.
    'CREEPER',

    # SpaceShips with mines capability.
    # Drops seismic charges behind its path.
    'SEISMIC',

    # DEFLECT proton's projectiles and missiles.
    # This magnetic field cannot deflects explosion blast.
    # Used by heavy cruiser placed in the center of the screen, facing
    # the player position.
    'GRAVITRON',

    # Crystal spaceship that have the ability to resonate.
    # Blind the player for a brief period of time.
    # The warm up is a long process whom makes this spaceship vulnerable.
    'RESONATE',

    # Repulsive electromagnetic field capable of deflecting player spaceship
    # away from their location.
    'REPULSIVE',

    # Drop small clister bombs at regular interval
    'BOMBER',

    # Repair only adjacent aircrafts. It is not equipped with weapons
    'REPAIR',

    # Do not shoot, good target
    'SCOUT'
]


class EnemyStrategy:

    def __init__(self):
        self.index = 0
        self.max = len(_STRATEGY)
        self.strategy = _STRATEGY

    def __contains__(self, item):
        return True if item in self.strategy else False

    def __iter__(self):
        for r in self.strategy:
            yield r

    def __next__(self):
        try:
            item = self.strategy[self.index]
        except IndexError:
            self.index = 0
            item = self.strategy[self.index]

        self.index += 1
        return item


class EnemyClass:

    def __init__(self,
                 spawn_: (int, None, float),
                 name_: str, type_: str, speed_: pygame.math.Vector2,
                 mass_: int, score_: int, collision_damage_: int,
                 hp_: int, max_hp_: int, disrupted_: bool,
                 spaceship_animation_: (pygame.Surface, list),
                 explosion_sprites_: (pygame.Surface, list),
                 impact_sprite_: (pygame.Surface, list),
                 shield_: (ShieldClass, None),
                 turret_: (Weapons, None),
                 strategy_: str,
                 fallback_strategy_: str,
                 missile_: (Weapons, None),
                 laser_: dict,
                 rotation_speed_: int,
                 explosion_sound_: pygame.mixer.Sound,
                 impact_sound_: pygame.mixer.Sound,
                 path_: numpy.array,
                 org_position: pygame.math.Vector2,
                 angle_follow_path: bool,
                 sprite_orientation: int,
                 sprite_size: tuple,
                 shield_sprite_size: tuple,
                 laser_accuracy: int,
                 weakness: (list, None),
                 disintegration_sprites: (list, None),
                 safe_distance: int,
                 fov: int,
                 shooting_restriction: (int, float),
                 refreshing_rate: int,
                 stop_: list):

        self.id = id(self)

        # Time when first called.
        # also called initialisation time
        self.timestamp = time()
        # spawn time in seconds
        self.spawn = spawn_

        # Enemy's name + unique id
        self.name = name_ + str(self.id)
        # Spaceship class description e.g frigate, cruiser
        # destroyer, corvettes etc
        self.description = type_

        # Speed vector
        self.speed = speed_
        # Ship mass for the elastic collision engine.
        # Object with more mass will be less
        # affected by explosion blast.
        self.mass = mass_

        # score given to the player after object destruction.
        self.score = score_
        # Damage passed to the player after collision.
        self.collision_damage = collision_damage_
        # Maximum health point
        assert hp_ != 0, '\n[-]Error - Instance variable hp_ cannot be equal to zero.'
        self.hp = hp_
        assert max_hp_ != 0, '\n[-]Error - Instance variable max_hp_ cannot be equal to zero.'
        assert max_hp_ >= hp_, '\n[-]Error - Instance variable max_hp_ cannot be < to variable hp.'
        self.max_hp = max_hp_

        # Determine if the object is disrupted.
        # Disrupted objects cannot shoot or move.
        self.disrupted = disrupted_
        # Sprites or single surface.
        self.spaceship_animation = spaceship_animation_
        # Explosion sprites.
        self.explosion_sprites = explosion_sprites_

        # Sprites when object his hit.
        self.impact_sprite = impact_sprite_
        # class pass as argument or NoneType
        # No shield if None
        self.shield = shield_
        # class pass as argument or NoneType
        # No mounted turret if None
        self.turret = turret_
        # Strategy class defining the enemy AI
        self.strategy = strategy_
        # fallback strategy if primary strategy is N/A
        self.fallback_strategy = fallback_strategy_

        # Weapons class or NoneType
        # No missile if None
        self.missile = missile_

        # dict containing laser mounted
        # location and weapon type
        self.laser = laser_

        # SpaceShip rotation speed (degrees / Frame)
        self.rotation_speed = rotation_speed_
        # Sound of the explosion
        self.explosion_sound = explosion_sound_
        # Sound when taking a hit or None (no sound)
        self.impact_sound = impact_sound_
        # original position (pygame.math.Vector2)
        self.pos = org_position

        # path to follow (list of reference points)
        # if the strategy is PATH then the spaceship will
        # follow automatically the reference point.
        # A Bezier curve will be automatically build from
        # those reference points.
        self.path = path_

        # boolean to determine if the enemy ship rotate
        # along its path. If False, the enemy ship will
        # keep always face the player position.
        self.angle_follow_path = angle_follow_path

        # how many degrees the sprite need to be rotated clockwise
        # in order to be oriented/align with a zero degree angle.
        self.sprite_orientation = sprite_orientation

        # sprite size (tuple x, y)
        self.sprite_size = sprite_size

        self.sprite_resize()

        # shield size
        self.shield_sprite_size = shield_sprite_size

        self.shield_resize()

        # laser accuracy in percentage
        # the value determine the shot spread in angle
        # 0% no spread (direct hit).
        # e.g True aiming point is 95 degrees, hit at 400 pixels,
        # 10%  / SCREENRECT.h = 0.097% spread per pixels.
        # At 400 pixels -> 3.9% of spread
        # Thus 91.1 deg(min) < shot_angle < 98.9 deg (max)
        self.laser_accuracy = laser_accuracy

        # Put here if the enemy spaceship
        # class has some specific weakness for
        # specific weapon types.
        self.weakness = weakness

        if disintegration_sprites:

            # spaceship pieces flying around after explosion
            self.disintegration_sprites = []
            i = 0
            for surface in disintegration_sprites:
                ratio_x, ratio_y = surface.get_width() / sprite_size[0], \
                                   surface.get_height() / sprite_size[1]

                self.disintegration_sprites.append(pygame.transform.smoothscale(surface,
                                                                                (int(surface.get_width() * ratio_x),
                                                                                 int(
                                                                                     surface.get_height() * ratio_y))))

                i += 1

        # When KEEP DISTANCE strategy is used
        # the aircraft will try to keep the distance
        # with the player.
        self.safe_distance = safe_distance

        # Field of view,
        # Maximum angle the enemy ship is allow
        # to see a target from its current angle
        self.fov = fov

        # Aircraft not allowed to shoot during 2 seconds after spawning
        self.shooting_restriction = shooting_restriction

        # Correspond to self.dt value
        # The value can be change here according
        # to the vessel speed (slower or static object can
        # have a higher refreshing_rate) without causing a lagging effect
        self.refreshing_rate = refreshing_rate

        # Waypoint stopping time
        self.stop = stop_

    def sprite_resize(self):
        if isinstance(self.spaceship_animation, list):
            i = 0
            for surface in self.spaceship_animation:
                self.spaceship_animation[i] = pygame.transform.smoothscale(surface, self.sprite_size)
                i += 1
        else:
            self.spaceship_animation = pygame.transform.smoothscale(self.spaceship_animation, self.sprite_size)

    def shield_resize(self):

        if self.shield:
            if isinstance(self.shield.sprite, list):
                i = 0
                for surface in self.shield.sprite:
                    self.shield.sprite[i] = pygame.transform.smoothscale(surface, self.shield_sprite_size)
                    i += 1
            else:
                self.shield.sprite = pygame.transform.smoothscale(self.shield.sprite, self.shield_sprite_size)

            # resize the shield indicator accoridng to the sprite size
            self.shield.smi = pygame.transform.smoothscale(self.shield.smi,
                                                           (self.sprite_size[0] // 2, self.shield.smi.get_height()))
            self.shield.sbi = pygame.transform.smoothscale(self.shield.sbi,
                                                           (self.sprite_size[0] // 2, self.shield.sbi.get_height()))


class Raptor(EnemyClass):

    def __init__(self):
        super().__init__(spawn_=None,
                         name_='RAPTOR',
                         type_='SPACE_FIGHTER',
                         speed_=pygame.math.Vector2(4, 4),
                         mass_=50,
                         score_=100,
                         collision_damage_=1800,
                         hp_=150,
                         max_hp_=150,
                         disrupted_=False,
                         spaceship_animation_=SPACE_FIGHTER_SPRITE,
                         explosion_sprites_=EXPLOSIONS[0],
                         impact_sprite_=BURST_DOWN_RED,
                         shield_=ShieldClass(name='SHIELD_CLASS_1_RED', energy=2000.0, max_energy=2000.0,
                                             operational_status=True,
                                             shield_up=False, overloaded=False, disrupted=False, sprite=SHIELD_SOFT_RED,
                                             recharge_speed=0.2, shield_sound=FORCE_FIELD_SOUND,
                                             shield_sound_down=SHIELD_DOWN_SOUND,
                                             shield_sound_impact=SHIELD_IMPACT_SOUND_2,
                                             shield_glow_sprite=SHIELD_GLOW_RED,
                                             impact_sprite=SHIELD_HEATGLOW),
                         turret_=None,
                         # follow path
                         strategy_=_STRATEGY[1],
                         fallback_strategy_=_STRATEGY[0],
                         missile_=None,
                         laser_={
                             'self.rect.midright': EnemyWeapons(name_='LZRFX084', sprite_=LAZER_FX[6],
                                                                range_=SCREENRECT.h, velocity_=-18,
                                                                damage_=100, sound_effect_=FIRE_BOLT_MICRO,
                                                                volume_=SOUND_LEVEL,
                                                                reloading_time_=2.2, animation_=None, offset_=(0, 0)),
                             'self.rect.midleft': EnemyWeapons(name_='LZRFX084', sprite_=LAZER_FX[6],
                                                               range_=SCREENRECT.h,
                                                               velocity_=-18,
                                                               damage_=100, sound_effect_=FIRE_BOLT_MICRO,
                                                               volume_=SOUND_LEVEL,
                                                               reloading_time_=2.2, animation_=None, offset_=(0, 0)),
                             'self.rect.center': EnemyWeapons(name_='LZRFX074', sprite_=LAZER_FX[5],
                                                              range_=SCREENRECT.h,
                                                              velocity_=-15,
                                                              damage_=200, sound_effect_=FIRE_BOLT_MED,
                                                              volume_=SOUND_LEVEL,
                                                              reloading_time_=3, animation_=None, offset_=(0, 0))},
                         rotation_speed_=2,
                         explosion_sound_=EXPLOSION_COLLECTION_SOUND[1],
                         impact_sound_=IMPACT1,
                         path_=numpy.array([[125, 100], [50, 50], [150, 200], [200, 200]]),
                         org_position=pygame.math.Vector2(50, -200),
                         angle_follow_path=True,
                         sprite_orientation=+90,
                         sprite_size=(80, 40),
                         shield_sprite_size=(80 + 20, 80 + 20),
                         laser_accuracy=6,
                         weakness=None,
                         disintegration_sprites=RAPTOR_EXPLODE,
                         safe_distance=450,
                         fov=50,
                         shooting_restriction=2,
                         refreshing_rate=20,
                         stop_=[0, 0, 0, 0])
        pass

    def override_attributes(self, variables_: dict):
        """ Override some instance variables after the instantiation of the class.
        """
        assert isinstance(variables_, dict), \
            'Expecting dict for argument variables, got %s ' % type(variables_)
        for attribute, value in variables_.items():
            if hasattr(self, str(attribute)):
                setattr(self, str(attribute), value)
            else:
                print('\n[-]WARNING - Attribute %s does not exist.' % attribute)
                # raise AttributeError


class Scout(Raptor):

    def __init__(self):
        # Scout class inherit from its parent
        Raptor.__init__(self)
        self.name = 'Scout' + str(id(self))
        self.laser = None
        self.description = 'SCOUT'
        self.speed = pygame.math.Vector2(5, 5)
        self.mass = 40
        self.score = 50
        self.collision_damage = 1000
        self.hp = 80
        self.max_hp = 80
        self.spaceship_animation = SCOUT_SPRITE
        self.explosion_sprites = EXPLOSIONS[1]
        self.impact_sprite = BURST_DOWN_RED
        self.shield = None
        self.laser = None
        self.explosion_sound = EXPLOSION_COLLECTION_SOUND[3]
        self.impact_sound = IMPACT1
        self.path = numpy.array([[125, 100], [50, 50], [150, 200], [200, 200]])
        self.pos = pygame.math.Vector2(SCREENRECT.w // 2, -200)
        self.sprite_orientation = +90
        self.sprite_size = (80, 40)
        self.shield_sprite_size = (80 + 20, 80 + 20)
        # self.disintegration_sprites = RAPTOR_EXPLODE
        self.refreshing_rate = 20
        self.sprite_resize()
        self.shield_resize()

        self.disintegration_sprites = BLAST1


class Interceptor(Raptor):

    def __init__(self):
        # Scout class inherit from its parent
        Raptor.__init__(self)
        self.name = 'Interceptor' + str(id(self))
        self.laser = None
        self.description = 'INTERCEPTOR'
        self.speed = pygame.math.Vector2(4, 5)
        self.strategy = 'PATH'
        self.mass = 60
        self.score = 120
        self.collision_damage = 1800
        self.hp = 350
        self.max_hp = 350
        self.spaceship_animation = INTERCEPTOR_SPRITE
        self.explosion_sprites = EXPLOSIONS[2]
        self.impact_sprite = BURST_DOWN_RED

        self.laser = None
        self.angle_follow_path = False
        self.explosion_sound = EXPLOSION_COLLECTION_SOUND[3]
        self.impact_sound = IMPACT1
        self.path = numpy.array([[125, 100], [50, 50], [150, 200], [200, 200]])
        self.pos = pygame.math.Vector2(SCREENRECT.w // 2, -200)
        self.sprite_orientation = 0
        self.sprite_size = (80, 101)
        self.shield_sprite_size = (101 + 20, 101 + 20)
        # self.disintegration_sprites = RAPTOR_EXPLODE
        self.refreshing_rate = 20
        if isinstance(self.spaceship_animation, list):
            i = 0
            for surface in self.spaceship_animation:
                self.spaceship_animation[i] = pygame.transform.smoothscale(surface, self.sprite_size)
                i += 1
        else:
            self.spaceship_animation = pygame.transform.smoothscale(self.spaceship_animation, self.sprite_size)

        self.disintegration_sprites = BLAST1
        self.laser = {
            'self.rect.midright': EnemyWeapons(name_='LZRFX084', sprite_=LAZER_FX[8],
                                               range_=SCREENRECT.h, velocity_=-25,
                                               damage_=150, sound_effect_=FIRE_BOLT_LONG,
                                               volume_=SOUND_LEVEL,
                                               reloading_time_=2.4, animation_=None, offset_=(20, 0)),
            'self.rect.midleft': EnemyWeapons(name_='LZRFX084', sprite_=LAZER_FX[8],
                                              range_=SCREENRECT.h,
                                              velocity_=-25,
                                              damage_=150, sound_effect_=FIRE_BOLT_LONG,
                                              volume_=SOUND_LEVEL,
                                              reloading_time_=2.4, animation_=None, offset_=(20, 0)),
            'self.rect.center': EnemyWeapons(name_='LZRFX074', sprite_=LAZER_FX[9],
                                             range_=SCREENRECT.h,
                                             velocity_=-20,
                                             damage_=20, sound_effect_=INTERSTELLAR_GUN1,
                                             volume_=SOUND_LEVEL,
                                             reloading_time_=0.4, animation_=None, offset_=(0, 0))}
        self.laser_accuracy = 10

        self.shield = ShieldClass(name='SHIELD_CLASS_1_RED', energy=3500.0, max_energy=3500.0,
                                  operational_status=True,
                                  shield_up=False, overloaded=False, disrupted=False, sprite=SHIELD_SOFT_RED,
                                  recharge_speed=0.2, shield_sound=FORCE_FIELD_SOUND,
                                  shield_sound_down=SHIELD_DOWN_SOUND,
                                  shield_sound_impact=SHIELD_IMPACT_SOUND_2,
                                  shield_glow_sprite=SHIELD_GLOW_RED,
                                  impact_sprite=SHIELD_HEATGLOW)
        self.sprite_resize()
        self.shield_resize()

if __name__ == '__main__':
    Enemy = Scout()
    print(hasattr(Enemy, 'override_attributes'))
