import pygame
from pygame.transform import smoothscale

from Tools import reshape
from Weapons import ShieldClass, TurretClass, Weapons

from Textures import SPACE_FIGHTER_SPRITE, BURST_DOWN_RED, EXPLOSIONS, LASER_FX, SHIELD_SOFT_RED, \
    SHIELD_HEATGLOW1, RAPTOR_EXPLODE, SCOUT_SPRITE, INTERCEPTOR_SPRITE, BLAST1, SHIELD_GLOW, \
    TURRET_SPRITE_SENTINEL, \
    RAIDER_SPRITE, SCOUT_KAMIKAZE, COLONY_SHIP_I, DRONE7, \
    MUZZLE1, FIREBOLT, MUZZLE2, HORNET_IMAGE, GROUND_EXPLOSION_SPRITES, GENERATOR, \
    SHIELD_GENERATOR, EXPLOSION19, SHIELD_ELECTRIC_ARC_1
# G5V200_SHADOW, RADIAL, HALO_SPRITE9_, SHIELD, TESLA_BLUE_SPRITE_blended, PHOTON_PARTICLE_1,
# MISSILE_EXPLOSION, HALO_SPRITE12, G5V200_EXPLOSION_DEBRIS, COLONY_SHIP_II, SHIELD_GLOW_BLUE

from Sounds import IMPACT1, EXPLOSION_COLLECTION_SOUND, FIRE_BOLT_MICRO, FIRE_BOLT_MED, \
    SHIELD_IMPACT_SOUND, \
    FORCE_FIELD_SOUND, SHIELD_DOWN_SOUND, SHIELD_IMPACT_SOUND_1, SHIELD_IMPACT_SOUND_2, \
    IMPACT3, FIRE_BOLT_LONG, \
    INTERSTELLAR_GUN1, FIRE_PARTICLE3, GROUND_EXPLOSION, WEAK_LASER, HEAVY_LASER1, \
    HEAVY_LASER2, FIRE_BOLT_SHORT, \
    PHOTON, MISSILE_FLIGHT_SOUND, EXPLOSION_SOUND_2

from Constants import GL, DEG_TO_RAD
import time
from time import time
# from math import ceil, exp, cos, pi, sin
# from random import randint, uniform

from BindSprite import *


# ALL BULLET and LASER SPRITE HAVE TO BE ORIENTED AT 0 DEGREES

# SHIELD_ELECTRIC_ARC_1_ = reshape(SHIELD_ELECTRIC_ARC_1, (120, 120))

class EnemyWeapons:

    def __init__(self, name_: str, sprite_: (pygame.Surface, list), range_: int,
                 velocity_: (int, float), damage_: int,
                 sound_effect_: pygame.mixer.Sound, volume_: int, reloading_time_: float,
                 animation_: (pygame.Surface, list), offset_: tuple = (0, 0), detonation_dist_: int = None,
                 timestamp_=0, max_rotation_=None):

        self.name = name_                                       # Weapon system name (str)
        self.type_ = 'LASER'                                    
        # for compatibility with other class (str)
        self.sprite = sprite_                                   # Sprite shot (pygame.Surface)
        self.range = range_                                     # Maximum range (int)
        self.velocity = Vector2(0, velocity_)       # shot speed (Vector2)
        self.damage = damage_                                   # Damage given to the player (int)
        self.sound_effect = sound_effect_                       
        # Shot sound effect (pygame.mixer.Sound)
        self.volume = volume_                                   # Sound FX volume (int)
        self.animation = animation_                             
        # Shot animation (pygame.Surface, list)
        self.timestamp = timestamp_                             # Shooting timestamp (int)
        self.reloading_time = reloading_time_ * GL.MAXFPS       
        # time(in secs) x fps = (number of frames)
        self.offset = offset_                                   # Offset for laser shots (tuple)
        self.detonation_dist = detonation_dist_                 
        # detonation distance (for ground turret)
        self.max_rotation = max_rotation_                       
        # Missile max_rotation (maximal angular
        # deviation in degrees)

    def is_reloading(self, frame_):
        if frame_ - self.timestamp > self.reloading_time:
            # ready to shoot
            self.timestamp = 0
            return False
        # reloading
        else:
            return True

    def shooting(self, frame_):
        self.timestamp = frame_     # GL.FRAME


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
    # spaceship with longer super_laser range can also use this strategy.
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

    # Drop small cluster bombs at regular interval
    'BOMBER',

    # Repair only adjacent aircrafts. It is not equipped with weapons
    'REPAIR',

    # Unarmed aircraft scoot, good target
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


class EnemyBaseClass:
    def __init__(self, name_, description_, speed_, score_, hp_, max_hp_, object_animation_,
                 explosion_sprites_,
                 impact_sprite_, missile_, laser_, rotation_speed_, explosion_sound_, 
                 impact_sound_, org_position,
                 sprite_orientation, laser_accuracy, weakness, fov, refreshing_rate):

        self.id = id(self)
        self.name = name_ + str(self.id)                # Enemy's name + unique id (str)
        self.description = description_                 
        # Spaceship class description e.g frigate, cruiser. (str)
        self.speed = speed_                             # Speed vector (Vector2)
        self.score = score_                             # Enemy value (int)
        assert hp_ != 0, '\n[-]Error - Instance variable hp_ cannot be equal to zero.'
        self.hp = hp_                                   # Enemy health point (int)
        assert max_hp_ != 0, '\n[-]Error - Instance variable max_hp_ cannot be equal to zero.'
        assert max_hp_ >= hp_, '\n[-]Error - Instance variable max_hp_ cannot be < to variable hp.'
        self.max_hp = max_hp_                           # Enemy maximum health point (int)
        self.object_animation = object_animation_       # Sprite(s) (pygame.Surface or list)
        self.explosion_sprites = explosion_sprites_     # Explosion sprites. (pygame.Surface, list)
        self.impact_sprite = impact_sprite_             
        # Sprites when enemy his hit. (pygame.Surface, list)
        self.missile = missile_                         # Weapons class or NoneType --> no missile
        self.laser = laser_                             
        # python dict containing mounted lasers and locations
        self.rotation_speed = rotation_speed_           
        # Enemy spaceship rotate_inplace speed (degrees / Frame)
        self.explosion_sound = explosion_sound_         # Sound of the explosion
        self.impact_sound = impact_sound_               
        # Sound when taking a hit or None --> no sound
        self.pos = org_position                         # original position (Vector2)
        self.sprite_orientation = sprite_orientation    
        # how many degrees the sprite need to be rotated anticlockwise
        # in order to be oriented/align with a zero degree angle.

        # laser accuracy in percentage
        # the value determine the shot spread in angle
        # 0% no spread (direct hit).
        # e.g True aiming point is 95 degrees, hit at 400 pixels,
        # 10% / GL.screenrect.h = 0.097% spread per pixels.
        # At 400 pixels -> 3.9% of spread
        # Thus 91.1 DEG(min) < shot_angle < 98.9 DEG (max)
        self.laser_accuracy = laser_accuracy
        self.weakness = weakness                        
        # List here any weakness to a specific weapon system
        self.fov = fov                                  # Field of view,
        self.refreshing_rate = refreshing_rate          # Refreshing rate in ms
        self.invincible = False  # Raise the invincible flag (true not taking any damages)
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


class EnemyClass:

    def __init__(self,
                 spawn_: (int, None, float),

                 mass_: int, collision_damage_: int,
                 disrupted_: bool,
                 shield_: (ShieldClass, None),
                 turret_: (Weapons, None),
                 strategy_: (str, type(None)),
                 fallback_strategy_: str,
                 path_: numpy.array,
                 acceleration_: numpy.array,
                 angle_follow_path: bool,
                 sprite_size: tuple,
                 shield_sprite_size: tuple,
                 disintegration_sprites: (list, None),
                 safe_distance: int,
                 shooting_restriction: (int, float),
                 stop_: list,
                 category_: str = 'aircraft'):

        self.timestamp = time()                         
        # Time when first called (initialisation time)
        self.spawn = spawn_                             # spawn time in seconds (starting time)
        self.mass = mass_                               # Mass for the elastic collision engine.
        self.collision_damage = collision_damage_       
        # Damage passed to the player after collision.
        self.disrupted = disrupted_                     
        # Determine if the object is disrupted (cannot shoot or move).
        self.shield = shield_                           
        # class pass as argument or NoneType --> no shield
        self.turret = turret_                           # Turret class, None --> no turret
        self.strategy = strategy_                       # Strategy class defining the enemy AI
        self.fallback_strategy = fallback_strategy_     
        # fallback strategy if primary strategy is N/A

        # path to follow (list of reference points)
        # if the strategy is PATH then the spaceship will
        # follow automatically the reference point.
        # A Bezier curve will be automatically build from
        # those reference points.
        self.path = path_

        self.acceleration = acceleration_               # Pause in ms for each waypoint

        # Bool to determine if the enemy ship rotate along its path.
        # If False, the enemy ship is always facing toward the player position.
        self.angle_follow_path = angle_follow_path
        self.sprite_size = sprite_size                  # sprite size (tuple x, y)
        self.sprite_resize()                            # Function to resize

        self.shield_sprite_size = shield_sprite_size    # shield size
        self.shield_resize()                            # Resize the shield

        if disintegration_sprites:

            # spaceship pieces flying around after explosion
            self.disintegration_sprites = []
            i = 0
            for surface in disintegration_sprites:
                ratio_x, ratio_y = surface.get_width() / sprite_size[0], \
                                   surface.get_height() / sprite_size[1]

                self.disintegration_sprites.append(
                    smoothscale(surface,
                                                 (int(surface.get_width() * ratio_x),
                                                  int(surface.get_height() * ratio_y))))
                i += 1

        self.safe_distance = safe_distance               
        # keep distance with the player when strategy is KEEP DISTANCE
        self.shooting_restriction = shooting_restriction 
        # Aircraft not allowed to shoot during x seconds after spawning
        self.stop = stop_                                # Waypoint stopping time
        self.kamikaze_lock = False                       # Kamikaze action mode
        self.category = category_                        
        # Radar category e.g aircraft, ground, boss, missile

    # todo explosion resizing ?
    def sprite_resize(self):
        if self.object_animation is not None:
            if isinstance(self.object_animation, list):
                i = 0
                for surface in self.object_animation:
                    self.object_animation[i] = smoothscale(
                        surface, self.sprite_size)
                    i += 1
            else:
                self.object_animation = smoothscale\
                    (self.object_animation, self.sprite_size)

    def shield_resize(self):

        if self.shield:
            if isinstance(self.shield.sprite, list):
                i = 0
                for surface in self.shield.sprite:
                    self.shield.sprite[i] = smoothscale(
                        surface, self.shield_sprite_size)
                    i += 1
            else:
                self.shield.sprite = smoothscale(
                    self.shield.sprite, self.shield_sprite_size)

            # resize the shield indicator according to the sprite size
            self.shield.smi = smoothscale(self.shield.smi,
               ((self.sprite_size[0] >> 1),
                self.shield.smi.get_height()))
            self.shield.sbi = smoothscale(self.shield.sbi,
               ((self.sprite_size[0] >> 1),
                self.shield.sbi.get_height()))


class Raptor(EnemyBaseClass, EnemyClass):

    def __init__(self):
        EnemyBaseClass.__init__(
            self, name_='RAPTOR', description_='SPACE_FIGHTER', speed_=Vector2(4, 4),
            score_=100, hp_=700, max_hp_=700, object_animation_=SPACE_FIGHTER_SPRITE,
            explosion_sprites_=EXPLOSIONS.copy(), impact_sprite_=BURST_DOWN_RED, missile_=None,
            laser_={
                'self.rect.midright': EnemyWeapons(name_='LZRFX084', sprite_=LASER_FX[6],
                                                   range_=GL.screenrect.h, velocity_=-21,
                                                   damage_=100, sound_effect_=FIRE_BOLT_MICRO,
                                                   volume_=GL.SOUND_LEVEL,
                                                   reloading_time_=1.5, animation_=None,
                                                   offset_=(-10, -20)),
                'self.rect.midleft': EnemyWeapons(name_='LZRFX084', sprite_=LASER_FX[6],
                                                  range_=GL.screenrect.h,
                                                  velocity_=-21,
                                                  damage_=100, sound_effect_=FIRE_BOLT_MICRO,
                                                  volume_=GL.SOUND_LEVEL,
                                                  reloading_time_=1.5, animation_=None,
                                                  offset_=(+10, -15)),
                'self.rect.center': EnemyWeapons(name_='LZRFX074', sprite_=LASER_FX[5],
                                                 range_=GL.screenrect.h,
                                                 velocity_=-19,
                                                 damage_=200, sound_effect_=FIRE_BOLT_MED,
                                                 volume_=GL.SOUND_LEVEL,
                                                 reloading_time_=3, animation_=None,
                                                 offset_=(0, -20))},
            rotation_speed_=2,
            explosion_sound_=EXPLOSION_COLLECTION_SOUND[1], impact_sound_=IMPACT1,
            org_position=Vector2(50, -200), sprite_orientation=+90,
            laser_accuracy=6, weakness=None, fov=50, refreshing_rate=20)

        EnemyClass.__init__(self, spawn_=None,
                            mass_=50,
                            collision_damage_=1800,
                            disrupted_=False,
                            shield_=ShieldClass(name='SHIELD_CLASS_1_RED', energy=2000.0, 
                                                max_energy=2000.0,
                                                operational_status=True,
                                                shield_up=False, overloaded=False, disrupted=False,
                                                sprite=SHIELD_SOFT_RED,
                                                recharge_speed=0.2, shield_sound=FORCE_FIELD_SOUND,
                                                shield_sound_down=SHIELD_DOWN_SOUND,
                                                shield_sound_impact=SHIELD_IMPACT_SOUND_2,
                                                shield_glow_sprite=SHIELD_GLOW,
                                                impact_sprite=SHIELD_HEATGLOW1,
                                                shield_electric=SHIELD_ELECTRIC_ARC_1),
                            turret_=None,
                            # follow path
                            strategy_=_STRATEGY[1],
                            fallback_strategy_=_STRATEGY[0],
                            path_=numpy.array([[125, 100], [50, 50], [150, 200], [200, 200]]),
                            acceleration_=numpy.array([1 for _ in range(20)]),
                            angle_follow_path=True,
                            sprite_size=(80, 40),
                            shield_sprite_size=(80 + 20, 80 + 20),
                            disintegration_sprites=RAPTOR_EXPLODE,
                            safe_distance=450,
                            shooting_restriction=2,
                            stop_=[0, 0, 0, 0])
        pass

    """
    def override_attributes(self, variables_: dict):
        # Override some instance variables after the instantiation of the class.
        
        assert isinstance(variables_, dict), \
            'Expecting dict for argument variables, got %s ' % type(variables_)
        for attribute, value in variables_.items():
            if hasattr(self, str(attribute)):
                setattr(self, str(attribute), value)
            else:
                print('\n[-]WARNING - Attribute %s does not exist.' % attribute)
                # raise AttributeError
    """


class Scout(Raptor):
    """ illumDefault10"""

    def __init__(self):
        # Scout class inherit from its parent
        Raptor.__init__(self)
        # ********** Override values ****************
        # **********                 ****************
        self.name = 'Scout' + str(id(self))
        self.laser = None
        self.description = 'SCOUT'
        self.speed = Vector2(5, 5)
        self.mass = 40
        self.score = 50
        self.collision_damage = 1000
        self.hp = 300
        self.max_hp = 300
        self.object_animation = SCOUT_SPRITE
        self.explosion_sprites = EXPLOSIONS.copy()
        self.impact_sprite = BURST_DOWN_RED
        self.shield = None
        self.explosion_sound = EXPLOSION_COLLECTION_SOUND[3]
        self.impact_sound = IMPACT1
        self.path = numpy.array([[125, 100], [50, 50], [150, 200], [200, 200]])
        self.pos = Vector2(GL.screenrect.w // 2, -200)
        self.sprite_orientation = +90
        self.sprite_size = (70, 32)  # image real 140x63 ratio 2.2
        self.shield_sprite_size = (self.sprite_size[0] + 20, self.sprite_size[0] + 20)
        # self.disintegration_sprites = RAPTOR_EXPLODE
        self.refreshing_rate = 15
        self.sprite_resize()
        self.shield_resize()
        self.laser = {'self.rect.center': EnemyWeapons(name_='lzrfx039', sprite_=LASER_FX[14],
                                                       range_=GL.screenrect.h,
                                                       velocity_=-18,
                                                       damage_=50, sound_effect_=FIRE_BOLT_SHORT,
                                                       volume_=GL.SOUND_LEVEL,
                                                       reloading_time_=0.2, animation_=None,
                                                       offset_=(0, -15))}
        self.disintegration_sprites = BLAST1


class ScoutKamikaze(Raptor):
    """ illumDefault03 """

    def __init__(self):
        # Scout class inherit from its parent
        Raptor.__init__(self)
        # ********** Override values ****************
        # **********                 ****************
        self.name = 'ScoutKamikaze' + str(id(self))
        self.laser = None
        self.description = 'SCOUT KAMIKAZE'
        self.speed = Vector2(20, 20)
        self.mass = 45
        self.score = 65
        self.collision_damage = 1200
        self.hp = 50
        self.max_hp = 50
        self.object_animation = SCOUT_KAMIKAZE
        self.explosion_sprites = EXPLOSIONS.copy()
        self.impact_sprite = BURST_DOWN_RED
        self.shield = None
        self.laser = None
        self.explosion_sound = EXPLOSION_COLLECTION_SOUND[2]
        self.impact_sound = IMPACT1
        self.path = numpy.array([[125, 100], [50, 50], [150, 200], [200, 200]])
        self.pos = Vector2(GL.screenrect.w // 2, -200)
        self.sprite_orientation = +90
        self.sprite_size = (70, 45)
        self.shield_sprite_size = (self.sprite_size[0] + 20, self.sprite_size[0] + 20)
        # self.disintegration_sprites = RAPTOR_EXPLODE
        self.refreshing_rate = 20
        self.sprite_resize()
        self.shield_resize()
        self.disintegration_sprites = BLAST1


class ColonyShipI(Scout):
    """ illumDefault03 """

    def __init__(self):
        # Scout class inherit from its parent
        Scout.__init__(self)
        # ********** Override values ****************
        # **********                 ****************
        self.name = 'COLONY' + str(id(self))
        self.laser = None
        self.description = 'COLONY SHIP'
        self.speed = Vector2(5, 5)
        self.mass = 80
        self.score = 200
        self.collision_damage = 800
        self.hp = 60
        self.max_hp = 60
        self.object_animation = COLONY_SHIP_I
        self.explosion_sprites = EXPLOSIONS.copy()
        self.impact_sprite = BURST_DOWN_RED
        self.shield = None
        self.laser = None
        self.explosion_sound = EXPLOSION_COLLECTION_SOUND[3]
        self.impact_sound = IMPACT1
        self.sprite_size = (66, 42)
        self.shield_sprite_size = (self.sprite_size[0] + 20, self.sprite_size[0] + 20)
        # self.disintegration_sprites = RAPTOR_EXPLODE
        self.refreshing_rate = 20
        self.sprite_resize()
        self.shield_resize()
        self.disintegration_sprites = BLAST1


class Interceptor(Raptor):

    def __init__(self):
        # Scout class inherit from its parent
        Raptor.__init__(self)
        # ********** Override values ****************
        # **********                 ****************
        self.name = 'Interceptor' + str(id(self))
        self.laser = None
        self.description = 'INTERCEPTOR'
        self.speed = Vector2(4, 5)
        self.strategy = 'PATH'
        self.mass = 100
        self.score = 200
        self.collision_damage = 1800
        self.hp = 900
        self.max_hp = 900
        self.object_animation = INTERCEPTOR_SPRITE
        self.explosion_sprites = EXPLOSION19  # EXPLOSIONS.copy()
        self.impact_sprite = BURST_DOWN_RED
        self.laser = None
        self.angle_follow_path = True
        self.explosion_sound = EXPLOSION_COLLECTION_SOUND[3]
        self.impact_sound = IMPACT1
        self.path = numpy.array([[125, 100], [50, 50], [150, 200], [200, 200]])
        self.pos = Vector2(GL.screenrect.w // 2, -200)
        self.sprite_orientation = 0
        self.sprite_size = (80, 101)
        self.shield_sprite_size = (101 + 20, 101 + 20)
        # self.disintegration_sprites = RAPTOR_EXPLODE
        self.refreshing_rate = 20
        if isinstance(self.object_animation, list):
            i = 0
            for surface in self.object_animation:
                self.object_animation[i] = smoothscale(surface, self.sprite_size)
                i += 1
        else:
            self.object_animation = smoothscale(
                self.object_animation, self.sprite_size)

        self.disintegration_sprites = BLAST1
        self.laser = {
            'self.rect.midright': EnemyWeapons(name_='LZRFX084', sprite_=LASER_FX[8],
                                               range_=GL.screenrect.h, velocity_=-25,
                                               damage_=300, sound_effect_=FIRE_BOLT_LONG,
                                               volume_=GL.SOUND_LEVEL,
                                               reloading_time_=1.0, animation_=None,
                                               offset_=(-20, 0)),
            'self.rect.midleft': EnemyWeapons(name_='LZRFX084', sprite_=LASER_FX[8],
                                              range_=GL.screenrect.h,
                                              velocity_=-25,
                                              damage_=300, sound_effect_=FIRE_BOLT_LONG,
                                              volume_=GL.SOUND_LEVEL,
                                              reloading_time_=1.0, animation_=None,
                                              offset_=(+20, 0)),
            'self.rect.center': EnemyWeapons(name_='LZRFX074', sprite_=LASER_FX[9],
                                             range_=GL.screenrect.h,
                                             velocity_=-20,
                                             damage_=40, sound_effect_=INTERSTELLAR_GUN1,
                                             volume_=GL.SOUND_LEVEL,
                                             reloading_time_=0.2, animation_=None, offset_=(0, 0))}
        self.laser_accuracy = 10

        self.shield = ShieldClass(name='SHIELD_CLASS_1_RED', energy=3500.0, max_energy=3500.0,
                                  operational_status=True,
                                  shield_up=False, overloaded=False, disrupted=False, 
                                  sprite=SHIELD_SOFT_RED,
                                  recharge_speed=0.2, shield_sound=FORCE_FIELD_SOUND,
                                  shield_sound_down=SHIELD_DOWN_SOUND,
                                  shield_sound_impact=SHIELD_IMPACT_SOUND_2,
                                  shield_glow_sprite=SHIELD_GLOW,
                                  impact_sprite=SHIELD_HEATGLOW1,
                                  shield_electric=SHIELD_ELECTRIC_ARC_1)

        self.sprite_resize()
        self.shield_resize()


class Raider(Raptor):

    def __init__(self):
        # Raider class inherit from its parent Raptor
        Raptor.__init__(self)
        # ********** Override values ****************
        # **********                 ****************
        self.name = 'Raider' + str(id(self))
        self.laser = None
        self.description = 'RAIDER'
        self.speed = Vector2(4, 4)
        self.strategy = 'PATH'
        self.mass = 85
        self.score = 300
        self.collision_damage = 1500
        self.hp = 2200
        self.max_hp = 2200
        self.object_animation = RAIDER_SPRITE
        self.explosion_sprites = EXPLOSION19
        self.impact_sprite = BURST_DOWN_RED
        self.angle_follow_path = False
        self.explosion_sound = EXPLOSION_COLLECTION_SOUND[3]
        self.impact_sound = IMPACT1
        self.path = numpy.array([[125, 100], [50, 50], [150, 200], [200, 200]])
        self.pos = Vector2(GL.screenrect.w // 2, -200)
        self.sprite_orientation = 90
        self.sprite_size = (94, 82)
        self.shield_sprite_size = (self.sprite_size[0] + 20, self.sprite_size[0] + 20)
        # self.disintegration_sprites = RAPTOR_EXPLODE
        self.refreshing_rate = 20
        if isinstance(self.object_animation, list):
            i = 0
            for surface in self.object_animation:
                self.object_animation[i] = smoothscale(surface, self.sprite_size)
                i += 1
        else:
            self.object_animation = smoothscale\
                (self.object_animation, self.sprite_size)

        self.disintegration_sprites = BLAST1
        self.laser = \
            {
                '(self.rect.center[0], self.rect.center[1] - 10)':
                    EnemyWeapons(name_='lzrfx089', sprite_=LASER_FX[12],
                                 range_=GL.screenrect.h,
                                 velocity_=-20,
                                 damage_=66, sound_effect_=INTERSTELLAR_GUN1,
                                 volume_=GL.SOUND_LEVEL,
                                 reloading_time_=0.4, animation_=None, offset_=(0, 0)),
                '(self.rect.center[0], self.rect.center[1] - 11)':
                    EnemyWeapons(name_='lzrfxMixed052', sprite_=LASER_FX[3],
                                 range_=GL.screenrect.h,
                                 velocity_=-24,
                                 damage_=50, sound_effect_=HEAVY_LASER2,
                                 volume_=GL.SOUND_LEVEL,
                                 reloading_time_=1.2, animation_=None, offset_=(0, 0)),
                '(self.rect.midleft[0], self.rect.midleft[1])':
                    EnemyWeapons(name_='lzrfxHeavy12', sprite_=LASER_FX[13],
                                 range_=GL.screenrect.h,
                                 velocity_=-28,
                                 damage_=160, sound_effect_=HEAVY_LASER1,
                                 volume_=GL.SOUND_LEVEL,
                                 reloading_time_=0.8, animation_=None, offset_=(20, -10)),
                '(self.rect.midright[0], self.rect.midright[1])':
                    EnemyWeapons(name_='lzrfxHeavy12', sprite_=LASER_FX[13],
                                 range_=GL.screenrect.h,
                                 velocity_=-28,
                                 damage_=160, sound_effect_=HEAVY_LASER1,
                                 volume_=GL.SOUND_LEVEL,
                                 reloading_time_=0.8, animation_=None, offset_=(-20, -10))
            }
        # 5% deviation from a direct hit.
        self.laser_accuracy = 5

        self.shield = ShieldClass(name='SHIELD_CLASS_1_RED', energy=2000.0, max_energy=2000.0,
                                  operational_status=True,
                                  shield_up=False, overloaded=False, disrupted=False,
                                  sprite=SHIELD_SOFT_RED,
                                  recharge_speed=0.2, shield_sound=FORCE_FIELD_SOUND,
                                  shield_sound_down=SHIELD_DOWN_SOUND,
                                  shield_sound_impact=SHIELD_IMPACT_SOUND_2,
                                  shield_glow_sprite=SHIELD_GLOW,
                                  impact_sprite=SHIELD_HEATGLOW1,
                                  shield_electric=SHIELD_ELECTRIC_ARC_1)
        self.sprite_resize()
        self.shield_resize()


class GroundEnemyTurretSentinel(EnemyBaseClass):
    def __init__(self):
        EnemyBaseClass.__init__(self, name_='SENTINEL', description_='DEFENCE TURRET',
                                # Speed equal zero, in fact the turret will follow the
                                # background speed (in that case, the speed will be set later)
                                # during the instantiation.
                                speed_=Vector2(0, 0),
                                score_=160, hp_=1000, max_hp_=1000,
                                object_animation_=TURRET_SPRITE_SENTINEL,
                                explosion_sprites_=GROUND_EXPLOSION_SPRITES.copy(),
                                impact_sprite_=BURST_DOWN_RED,
                                # Only one shot
                                laser_={'(self.rect.center[0], self.rect.center[1] - 20)'
                                        : EnemyWeapons(name_='LZRFX025', sprite_=LASER_FX[11],
                                                       range_=GL.screenrect.h,
                                                       velocity_=-12,
                                                       damage_=250, sound_effect_=FIRE_PARTICLE3,
                                                       volume_=GL.SOUND_LEVEL,
                                                       reloading_time_=1.2, animation_=MUZZLE2,
                                                       offset_=(0, 0), detonation_dist_=60)},
                                missile_={'(self.rect.center[0], self.rect.center[1])'
                                          : EnemyWeapons(name_='Missile', sprite_=HORNET_IMAGE,
                                                         range_=GL.screenrect.h,
                                                         velocity_=-14,
                                                         damage_=1050, sound_effect_=
                                                         MISSILE_FLIGHT_SOUND,
                                                         volume_=GL.SOUND_LEVEL,
                                                         reloading_time_=5, animation_=MUZZLE1,
                                                         offset_=(0, 0), detonation_dist_=None,
                                                         max_rotation_=6)},
                                rotation_speed_=2,
                                explosion_sound_=GROUND_EXPLOSION, impact_sound_=IMPACT1,
                                org_position=Vector2(50, -200), sprite_orientation=+90,
                                laser_accuracy=6, weakness=None, fov=50, refreshing_rate=22
                                )
        self.category = 'ground'
        self.disintegration_sprites = BLAST1


class GroundEnemyDroneClass(EnemyBaseClass):
    def __init__(self):
        EnemyBaseClass.__init__(self, name_='DRONE', description_='DRONE CLASS I',

                                speed_=Vector2(1, 1),
                                score_=60, hp_=300, max_hp_=300, object_animation_=DRONE7,
                                explosion_sprites_=GROUND_EXPLOSION_SPRITES.copy(),
                                impact_sprite_=BURST_DOWN_RED, missile_=None,
                                # Only one shot
                                laser_={'(self.rect.center[0], self.rect.center[1])'
                                        : EnemyWeapons(name_='DronePlasma', sprite_=FIREBOLT,
                                                       # LASER_FX[15],
                                                       range_=GL.screenrect.h,
                                                       velocity_=-12,
                                                       damage_=200, sound_effect_=PHOTON,
                                                       volume_=GL.SOUND_LEVEL,
                                                       reloading_time_=2, animation_=MUZZLE1,
                                                       offset_=(0, 0), detonation_dist_=None)},
                                rotation_speed_=10,
                                explosion_sound_=GROUND_EXPLOSION, impact_sound_=IMPACT1,
                                org_position=Vector2(50, -200), sprite_orientation=+90,
                                laser_accuracy=2, weakness=None, fov=180, refreshing_rate=35
                                )
        self.disintegration_sprites = BLAST1
        self.path = numpy.array([[207, 430], [390, 430], [390, 40], [1200, 40]])
        self.strategy = 'PATH'
        self.angle_follow_path = True
        # This is the speed of the background.
        # Update the value accordingly
        self.speed = Vector2(0, 1)
        self.category = 'ground'


class ShieldGeneratorClass(EnemyBaseClass, EnemyClass):
    def __init__(self):
        EnemyBaseClass.__init__(self, name_='ShieldGenerator', description_='Shield Generator',
                                speed_=Vector2(0, 0),
                                score_=135, hp_=250, max_hp_=250, object_animation_=GENERATOR,
                                explosion_sprites_=GROUND_EXPLOSION_SPRITES.copy(),
                                impact_sprite_=BURST_DOWN_RED, missile_=None,
                                laser_=None,
                                rotation_speed_=None,
                                explosion_sound_=GROUND_EXPLOSION, impact_sound_=IMPACT1,
                                org_position=Vector2(50, -200), sprite_orientation=0,
                                laser_accuracy=None, weakness=None, fov=None, refreshing_rate=1
                                )

        EnemyClass.__init__(self, spawn_=None,
                            mass_=50,
                            collision_damage_=0,
                            disrupted_=False,
                            shield_=ShieldClass(name='SHIELD_CLASS_1_RED', energy=4000.0,
                                                max_energy=4000.0,
                                                operational_status=True,
                                                shield_up=False, overloaded=False, disrupted=False,
                                                sprite=SHIELD_GENERATOR,
                                                recharge_speed=0.2, shield_sound=FORCE_FIELD_SOUND,
                                                shield_sound_down=SHIELD_DOWN_SOUND,
                                                shield_sound_impact=SHIELD_IMPACT_SOUND_2,
                                                shield_glow_sprite=SHIELD_GLOW,
                                                impact_sprite=SHIELD_HEATGLOW1,
                                                shield_electric=SHIELD_ELECTRIC_ARC_1),
                            turret_=None,
                            # follow path
                            strategy_=None,
                            fallback_strategy_=_STRATEGY[0],
                            path_=None,
                            acceleration_=numpy.array([1 for r in range(20)]),
                            angle_follow_path=False,
                            sprite_size=(80, 80),
                            shield_sprite_size=(80 + 50, 80 + 50),
                            disintegration_sprites=None,
                            safe_distance=450,
                            shooting_restriction=0,
                            stop_=[0, 0, 0, 0])

        self.disintegration_sprites = BLAST1
        self.path = numpy.array([[207, 430], [390, 430], [390, 40], [1200, 40]])
        self.strategy = 'PATH'
        self.angle_follow_path = True
        # This is the speed of the background.
        # Update the value accordingly
        self.speed = Vector2(0, 1)
        self.category = 'ground'
        self.sprite_resize()
        self.shield_resize()


if __name__ == '__main__':
    Enemy = Raptor()
    print(Enemy.name, Enemy.refreshing_rate, Enemy.collision_damage)
    print(hasattr(Enemy, 'override_attributes'))
    a = ShieldGeneratorClass()

