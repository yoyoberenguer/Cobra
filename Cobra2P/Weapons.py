# encoding: utf-8

from Textures import SHOOTING_SPRITE, \
    STINGER_IMAGE, NUKE_BOMB_SPRITE, TESLA_BLUE_SPRITE, TURRET_SPRITE, SHIELD_BORDER_INDICATOR, \
    SHIELD_METER_INDICATOR, SHIELD_METER_MAX, ROUND_SHIELD_1, LASER_FX, TURRET_TARGET_SPRITE, \
    DEATHRAY_SPRITE_BLUE, DEATHRAY_LEVIATHAN, \
    DEATHRAY_LEVIATHAN_SHAFT, DEATHRAY_SHAFT, SUPERLASER_BURST, SUPERLASER_BURST1, ROUND_SHIELD_2, \
    DEATHRAY_SPRITE_BLUE_16, DEATHRAY_RED_B1, SPACESHIP_SPRITE, SHIELD_GLOW_BLUE, \
    CLUSTER_EXPLOSION, \
    SHIELD_ELECTRIC_ARC_1, BLURRY_WATER2, BOMB, BLURRY_WATER1_, SHIELD_ELECTRIC_ARC_1_


from Constants import GL

from Sounds import SUPERSHOT_WARMUP_1, FIRE_PLASMA, HEAVY_LASER2, HEAVY_LASER1, TX0_FIRE1,\
    TX0_FIRE2, TX0_FIRE3, \
    MISSILE_FLIGHT_SOUND, BOMB_RELEASE, \
    BEAM_FUSION_MED, FORCE_FIELD_SOUND, SHIELD_DOWN_SOUND, SHIELD_IMPACT_SOUND, \
    BEAM_PLASMA_SMALL, BEAM_FUSION_SMALL, BEAM_ION_MED

import time
import pygame


SHOT_CONFIGURATION = {'SINGLE': 1, 'DOUBLE': 3, 'QUADRUPLE': 5, 'SEXTUPLE': 7}

# Assign a particle color according to the super_laser.
# WEAPON_COLOR =
# {'RED': PHOTON_PARTICLE_7, 'BLUE': PHOTON_PARTICLE_4, 'YELLOW': PHOTON_PARTICLE_3, \
#  'PURPLE': PHOTON_PARTICLE_5, 'GREEN': PHOTON_PARTICLE_2, 'GOLD': PHOTON_PARTICLE_6}

WEAPON_OFFSET_X = {
    'NEMESIS':
        {0: compile('Vector2(   0,        -1)', '', 'eval'),
         -17: compile('Vector2(-0.087155, -0.99619)', '', 'eval'),  # 5 degrees to the left
         17: compile('Vector2(  0.087155, -0.99619)', '', 'eval'),  # 5 degrees to the right
         -30: compile('Vector2(-0.173648, -0.984807)', '', 'eval'),  # 10 degrees to the left
         30: compile('Vector2(  0.173648, -0.984807)', '', 'eval'),  # 10 degrees to the right
         -45: compile('Vector2(-0.258819, -0.965925)', '', 'eval'),  # 15 degrees to the left
         45: compile('Vector2(  0.258819, -0.965925)', '', 'eval')
         },
    'LEVIATHAN':
        {0: compile('Vector2(    0,        -1)', '', 'eval'),  # 0
         -40: compile('Vector2( -0.173648, -0.984807)', '', 'eval'),  # 10
         +40: compile('Vector2(  0.173648, -0.984807)', '', 'eval'),
         -60: compile('Vector2( -0.342020, -0.939692)', '', 'eval'),  # 20
         +60: compile('Vector2(  0.342020, -0.939692)', '', 'eval'),
         -80: compile('Vector2( -0.5,      -0.866025)', '', 'eval'),  # 30
         +80: compile('Vector2(  0.5,      -0.866025)', '', 'eval')
         }
}

WEAPON_ROTOZOOM = {
    'NEMESIS':
        {0: 'surface_',
         -17: 'rotozoom(surface_, 5, 1)',
         17: 'rotozoom(surface_, -5, 1)',
         -30: 'rotozoom(surface_, 10, 1)',
         30: 'rotozoom(surface_, -10, 1)',
         -45: 'rotozoom(surface_, 15, 1)',
         45: 'rotozoom(surface_, -15, 1)'},
    'LEVIATHAN':
        {0: 'surface_',
         -40: 'rotozoom(surface_, 10, 1)',
         +40: 'rotozoom(surface_, -10, 1)',
         -60: 'rotozoom(surface_, 20, 1)',
         +60: 'rotozoom(surface_, -20, 1)',
         -80: 'rotozoom(surface_, 30, 1)',
         +80: 'rotozoom(surface_, -30, 1)'
         }
}

# MULTI-THREAD only
TURRET_STRATEGY = \
    {'NEAREST': compile('GetNearestTarget(stack)', '', 'eval'),
     'FARTHEST': compile('GetFarthestTarget(stack)', '', 'eval'),
     'LOW_DEADLINESS': compile('SortByHarmlessTarget(stack)', '', 'eval'),
     'HIGH_DEADLINESS': compile('SortByDeadliestTarget(stack)', '', 'eval'),
     'NEAR_COLLISION': compile(
         'Threat(self.player.rect).GetNearestCollider('
         'colliders_c(self.gl.screenrect, group_, self.player.rect))', '', 'eval'),
     'FAR_COLLISION': compile(
         'Threat(self.player.rect).SortByFarthestCollider(colliders_c('
         'self.gl.screenrect, group_, self.player.rect))', '', 'eval')
     }


class SuperWeapon:
    def __init__(self, name_: str, sprite_: list, sound_: pygame.mixer.Sound, volume_: int):
        assert isinstance(name_, str), 'Expecting python string got %s ' % type(name_)
        assert sprite_ is None, 'Expecting NoneType got %s ' % type(sprite_)
        assert isinstance(sound_, pygame.mixer.Sound), \
            'Expecting pygame.mixer.Sound class got %s ' % type(sound_)
        assert isinstance(volume_, (int, float)),\
            'Expecting python integer or foat got %s ' % type(volume_)
        self.name = name_
        self.sprite = sprite_
        self.sound_effect = sound_
        self.volume = volume_


class Weapons:

    def __init__(self,
                 name_,                 # Weapon name (string)
                 sprite_,               # Bitmap to use (pygame.Surface)
                 range_,                # weapon range (shot will not be trigger below)
                 velocity_,
                 # projectile velocity (resultant velocity will be initialised to
                                        # pygame.Vector2(0, velocity). pygame.math.Vector2
                 damage_,               # Damage transfer to the target after collision. Integer
                 energy_,
                 # Energy used to generate the projectile (e.g 0 for missile). Integer
                 sound_effect_,         # Projectile sounds (pygame.mixer)
                 volume_,               # Volume (float <= 1.0)
                 shooting_,             # Weapon status (shooting True | False). Boolean
                 reloading_,
                 # Reloading time in seconds (Integer).Value will be converted into frames later)
                 elapsed_,              # Counter (frame number check since last shot). Integer
                 super_=None,           # Point to the super instance (evaluate string)
                 super_warm_up_=None,   # OBSOLETE
                 animation_=None,       # list of pygame.Surface
                 max_rotation_=None,
                 # Missile max_rotation (maximal angular deviation in degrees)
                 level_up_=None,        # Point to tbe next weapon inline (player level up)
                 blast_radius=0,
                 # Blast radius to be consider after impact, this is used by the elastic
                                        # collision engine (if enabled)
                 mass_=0.0
                 # Missile physical mass (used by elastic collision engine if enabled)
                 ):

        assert len(name_) > 1, 'Error super_laser name is not correct.'

        if len(name_.split('_')) > 2:
            self.units = name_.split('_')[2]
        else:
            self.units = 'SINGLE'

        self.type_ = name_.split('_')[1]                        # ex Laser, Photon etc
        self.color_ = name_.split('_')[0]
        self.name = name_                                       # ex GREEN_LASER_DOUBLE

        self.sprite = sprite_                                   # bitmap
        self.range = range_
        # define the maximal range of a projectile
        if velocity_:
            self.velocity = pygame.math.Vector2(0, velocity_)
        self.damage = damage_                                   # Maximal damage
        self.energy = energy_                                   # Energy cost
        self.sound_effect = sound_effect_
        self.volume = volume_
        self.shooting = shooting_
        # Status shooting(True)/not shooting(False)
        self.reloading = reloading_                             # Reloading time in seconds
        self.elapsed = elapsed_
        self.super = str(super_)                                # pointing to the super super_laser.
        self.super_warm_up = super_warm_up_
        self.animation = animation_
        self.max_rotation = max_rotation_

        self.level_up = level_up_
        # next weapon after power up or level up
        self.blast_radius = blast_radius
        self.mass = mass_
        # projectile mass or shock_wave max force in kg
        self.compiled = compile(self.super, '<string>', 'eval')

    def weapon_reloading_std(self, frame_):
        # check if the reloading time is over for the standard shot
        if self.reloading * GL.MAXFPS < frame_ - self.elapsed:
            # super_laser ready to fire again
            self.shooting = False
            self.elapsed = 0
            return False
        else:
            self.shooting = True
            return True

    def get_super(self):
        """ Return the super shot instance if defined
        else return None, no super shot available """
        if self.super != 'None':
            # Expression is compiled to improve performances
            return eval(self.compiled)
        else:
            return None

    def __copy__(self):
        """ copy the instance """
        return Weapons(self.name, self.sprite, self.range,
                       self.velocity.y if hasattr(self, 'velocity') else None, self.damage,
                       self.energy, self.sound_effect, self.volume, self.shooting,
                       self.reloading, self.elapsed, self.super,
                       self.super_warm_up, self.animation, self.max_rotation,
                       self.level_up, self.blast_radius, self.mass)


# ------------------------------------- Weapon definition -----------------------------------------

# NAME, SPRITE, RANGE, VELOCITY, DAMAGE, ENERGY, SOUND,
# VOLUME, SHOOTING, RELOADING, ELAPSED, SUPER, SUPER WARMUP

# Red photon -------------------------------------------------------------------------------------
WARM_UP_RED = SuperWeapon(name_='WARM_UP_RED_1', sprite_=None, sound_=SUPERSHOT_WARMUP_1,
                          volume_=GL.SOUND_LEVEL)

RED_PHOTON_5 = Weapons(name_='RED_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[1],
                       range_=GL.screenrect.h, velocity_=-30,
                       damage_=12000, energy_=60, sound_effect_=FIRE_PLASMA,
                       volume_=GL.SOUND_LEVEL, shooting_=False,
                       reloading_=1.2, elapsed_=0, super_=None, super_warm_up_=WARM_UP_RED)

RED_PHOTON_4 = Weapons(name_='RED_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[0],
                       range_=GL.screenrect.h, velocity_=-28,
                       damage_=600, energy_=22, sound_effect_=HEAVY_LASER2,
                       volume_=GL.SOUND_LEVEL, shooting_=False,
                       reloading_=0.2, elapsed_=0, super_='RED_PHOTON_5',
                       super_warm_up_=WARM_UP_RED,
                       animation_=None, level_up_=None)
RED_PHOTON_3 = Weapons(name_='RED_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[0],
                       range_=GL.screenrect.h, velocity_=-28,
                       damage_=600, energy_=20, sound_effect_=HEAVY_LASER2,
                       volume_=GL.SOUND_LEVEL, shooting_=False,
                       reloading_=0.22, elapsed_=0, super_='RED_PHOTON_4',
                       super_warm_up_=WARM_UP_RED,
                       animation_=None, level_up_=None)
RED_PHOTON_2 = Weapons(name_='RED_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[0],
                       range_=GL.screenrect.h, velocity_=-28,
                       damage_=600, energy_=15, sound_effect_=HEAVY_LASER1,
                       volume_=GL.SOUND_LEVEL, shooting_=False,
                       reloading_=0.25, elapsed_=0, super_='RED_PHOTON_3',
                       super_warm_up_=WARM_UP_RED,
                       animation_=None, level_up_=None)
RED_PHOTON_1 = Weapons(name_='RED_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[0],
                       range_=GL.screenrect.h, velocity_=-28,
                       damage_=600, energy_=6, sound_effect_=HEAVY_LASER1,
                       volume_=GL.SOUND_LEVEL, shooting_=False,
                       reloading_=0.3, elapsed_=0, super_='RED_PHOTON_2',
                       super_warm_up_=WARM_UP_RED,
                       animation_=None, level_up_=None)
# -------------------------------------------------------------------------------------------------

# Purple photon -----------------------------------------------------------------------------------
WARM_UP_PURPLE = SuperWeapon(name_='WARM_UP_PURPLE', sprite_=None, sound_=SUPERSHOT_WARMUP_1,
                             volume_=GL.SOUND_LEVEL)

PURPLE_PHOTON_5 = Weapons(name_='PURPLE_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[5],
                          range_=GL.screenrect.h, velocity_=-30,
                          damage_=6000, energy_=50, sound_effect_=FIRE_PLASMA,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=1.1, elapsed_=0, super_=None, super_warm_up_=WARM_UP_PURPLE)

PURPLE_PHOTON_4 = Weapons(name_='PURPLE_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[4],
                          range_=GL.screenrect.h,
                          velocity_=-28,
                          damage_=500, energy_=20, sound_effect_=HEAVY_LASER2,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.2, elapsed_=0, super_='PURPLE_PHOTON_5',
                          super_warm_up_=WARM_UP_PURPLE,
                          animation_=None, level_up_=None)
PURPLE_PHOTON_3 = Weapons(name_='PURPLE_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[4],
                          range_=GL.screenrect.h,
                          velocity_=-28,
                          damage_=500, energy_=14, sound_effect_=HEAVY_LASER2,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.25, elapsed_=0, super_='PURPLE_PHOTON_5',
                          super_warm_up_=WARM_UP_PURPLE,
                          animation_=None, level_up_=PURPLE_PHOTON_4)
PURPLE_PHOTON_2 = Weapons(name_='PURPLE_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[4],
                          range_=GL.screenrect.h, velocity_=-28,
                          damage_=500, energy_=10, sound_effect_=HEAVY_LASER1,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.3, elapsed_=0, super_='PURPLE_PHOTON_5',
                          super_warm_up_=WARM_UP_PURPLE,
                          animation_=None, level_up_=PURPLE_PHOTON_3)
PURPLE_PHOTON_1 = Weapons(name_='PURPLE_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[4],
                          range_=GL.screenrect.h, velocity_=-28,
                          damage_=500, energy_=5, sound_effect_=HEAVY_LASER1,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.35, elapsed_=0, super_='PURPLE_PHOTON_5',
                          super_warm_up_=WARM_UP_PURPLE,
                          animation_=None, level_up_=PURPLE_PHOTON_2)
# -------------------------------------------------------------------------------------------------

# Blue photon -------------------------------------------------------------------------------------
WARM_UP_BLUE = SuperWeapon(name_='WARM_UP_BLUE', sprite_=None, sound_=SUPERSHOT_WARMUP_1,
                           volume_=GL.SOUND_LEVEL)

BLUE_PHOTON_5 = Weapons(name_='BLUE_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[3],
                        range_=GL.screenrect.h, velocity_=-30,
                        damage_=4000, energy_=40, sound_effect_=FIRE_PLASMA,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=1.0, elapsed_=0, super_=None, super_warm_up_=WARM_UP_BLUE)

BLUE_PHOTON_4 = Weapons(name_='BLUE_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[2],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=400, energy_=18, sound_effect_=HEAVY_LASER2,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.25, elapsed_=0, super_='BLUE_PHOTON_5',
                        super_warm_up_=WARM_UP_BLUE,
                        animation_=None, level_up_=None)
BLUE_PHOTON_3 = Weapons(name_='BLUE_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[2],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=400, energy_=12, sound_effect_=HEAVY_LASER2,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.3, elapsed_=0, super_='BLUE_PHOTON_5',
                        super_warm_up_=WARM_UP_BLUE,
                        animation_=None, level_up_=BLUE_PHOTON_4)
BLUE_PHOTON_2 = Weapons(name_='BLUE_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[2],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=400, energy_=8, sound_effect_=HEAVY_LASER1,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.35, elapsed_=0, super_='BLUE_PHOTON_5',
                        super_warm_up_=WARM_UP_BLUE,
                        animation_=None, level_up_=BLUE_PHOTON_3)
BLUE_PHOTON_1 = Weapons(name_='BLUE_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[2],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=400, energy_=4, sound_effect_=HEAVY_LASER1,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.40, elapsed_=0, super_='BLUE_PHOTON_5',
                        super_warm_up_=WARM_UP_BLUE,
                        animation_=None, level_up_=BLUE_PHOTON_2)
# -------------------------------------------------------------------------------------------------

# Gold photon -------------------------------------------------------------------------------------
WARM_UP_GOLD = SuperWeapon(name_='WARM_UP_GOLD', sprite_=None, sound_=SUPERSHOT_WARMUP_1,
                           volume_=GL.SOUND_LEVEL)

GOLD_PHOTON_5 = Weapons(name_='GOLD_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[11],
                        range_=GL.screenrect.h, velocity_=-30,
                        damage_=2000, energy_=30, sound_effect_=FIRE_PLASMA,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.8, elapsed_=0, super_=None, super_warm_up_=WARM_UP_GOLD)

GOLD_PHOTON_4 = Weapons(name_='GOLD_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[10],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=300, energy_=10, sound_effect_=HEAVY_LASER2,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.3, elapsed_=0, super_='GOLD_PHOTON_5',
                        super_warm_up_=WARM_UP_GOLD,
                        animation_=None, level_up_=None)
GOLD_PHOTON_3 = Weapons(name_='GOLD_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[10],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=300, energy_=6, sound_effect_=HEAVY_LASER2,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.35, elapsed_=0, super_='GOLD_PHOTON_5',
                        super_warm_up_=WARM_UP_GOLD,
                        animation_=None, level_up_=GOLD_PHOTON_4)
GOLD_PHOTON_2 = Weapons(name_='GOLD_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[10],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=300, energy_=4, sound_effect_=HEAVY_LASER1,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GOLD_PHOTON_5',
                        super_warm_up_=WARM_UP_GOLD,
                        animation_=None, level_up_=GOLD_PHOTON_3)
GOLD_PHOTON_1 = Weapons(name_='GOLD_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[10],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=300, energy_=2, sound_effect_=HEAVY_LASER1,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.45, elapsed_=0, super_='GOLD_PHOTON_5',
                        super_warm_up_=WARM_UP_GOLD,
                        animation_=None, level_up_=GOLD_PHOTON_2)
# -------------------------------------------------------------------------------------------------


# Yellow photon -----------------------------------------------------------------------------------
WARM_UP_YELLOW = SuperWeapon(name_='WARM_UP_YELLOW', sprite_=None, sound_=SUPERSHOT_WARMUP_1,
                             volume_=GL.SOUND_LEVEL)

YELLOW_PHOTON_5 = Weapons(name_='YELLOW_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[9],
                          range_=GL.screenrect.h, velocity_=-30,
                          damage_=1000, energy_=20, sound_effect_=FIRE_PLASMA,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.6, elapsed_=0, super_=None, super_warm_up_=WARM_UP_YELLOW)

YELLOW_PHOTON_4 = Weapons(name_='YELLOW_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[8],
                          range_=GL.screenrect.h,
                          velocity_=-28,
                          damage_=200, energy_=10, sound_effect_=HEAVY_LASER2,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.30, elapsed_=0, super_='YELLOW_PHOTON_5',
                          super_warm_up_=WARM_UP_YELLOW,
                          animation_=None, level_up_=None)
YELLOW_PHOTON_3 = Weapons(name_='YELLOW_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[8],
                          range_=GL.screenrect.h,
                          velocity_=-28,
                          damage_=200, energy_=6, sound_effect_=HEAVY_LASER2,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.35, elapsed_=0, super_='YELLOW_PHOTON_5',
                          super_warm_up_=WARM_UP_YELLOW,
                          animation_=None, level_up_=YELLOW_PHOTON_4)
YELLOW_PHOTON_2 = Weapons(name_='YELLOW_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[8],
                          range_=GL.screenrect.h, velocity_=-28,
                          damage_=200, energy_=4, sound_effect_=HEAVY_LASER1,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.40, elapsed_=0, super_='YELLOW_PHOTON_5',
                          super_warm_up_=WARM_UP_YELLOW,
                          animation_=None, level_up_=YELLOW_PHOTON_3)
YELLOW_PHOTON_1 = Weapons(name_='YELLOW_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[8],
                          range_=GL.screenrect.h, velocity_=-28,
                          damage_=200, energy_=2, sound_effect_=HEAVY_LASER1,
                          volume_=GL.SOUND_LEVEL, shooting_=False,
                          reloading_=0.45, elapsed_=0, super_='YELLOW_PHOTON_5',
                          super_warm_up_=WARM_UP_YELLOW,
                          animation_=None, level_up_=YELLOW_PHOTON_2)
# --------------------------------------------------------------------------------------------------

# Green photon -------------------------------------------------------------------------------------
WARM_UP_GREEN = SuperWeapon(name_='WARM_UP_GREEN', sprite_=None, sound_=SUPERSHOT_WARMUP_1,
                            volume_=GL.SOUND_LEVEL)

GREEN_PHOTON_5 = Weapons(name_='GREEN_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[7],
                         range_=GL.screenrect.h, velocity_=-20,
                         damage_=500, energy_=25, sound_effect_=FIRE_PLASMA,
                         volume_=GL.SOUND_LEVEL, shooting_=False,
                         reloading_=0.22, elapsed_=0, super_=None, super_warm_up_=WARM_UP_GREEN,
                         level_up_=None)

GREEN_PHOTON_4 = Weapons(name_='GREEN_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[6],
                         range_=GL.screenrect.h, velocity_=-30,
                         damage_=100, energy_=6, sound_effect_=HEAVY_LASER2,
                         volume_=GL.SOUND_LEVEL, shooting_=False,
                         reloading_=0.12, elapsed_=0, super_='GREEN_PHOTON_5',
                         super_warm_up_=WARM_UP_GREEN,
                         animation_=None, level_up_=None)
GREEN_PHOTON_3 = Weapons(name_='GREEN_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[6],
                         range_=GL.screenrect.h,
                         velocity_=-30,
                         damage_=100, energy_=4, sound_effect_=HEAVY_LASER2,
                         volume_=GL.SOUND_LEVEL, shooting_=False,
                         reloading_=0.10, elapsed_=0, super_='GREEN_PHOTON_5',
                         super_warm_up_=WARM_UP_GREEN,
                         animation_=None, level_up_=GREEN_PHOTON_4)
GREEN_PHOTON_2 = Weapons(name_='GREEN_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[6],
                         range_=GL.screenrect.h, velocity_=-30,
                         damage_=100, energy_=2, sound_effect_=HEAVY_LASER1,
                         volume_=GL.SOUND_LEVEL, shooting_=False,
                         reloading_=0.09, elapsed_=0, super_='GREEN_PHOTON_5',
                         super_warm_up_=WARM_UP_GREEN,
                         animation_=None, level_up_=GREEN_PHOTON_3)
GREEN_PHOTON_1 = Weapons(name_='GREEN_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[6],
                         range_=GL.screenrect.h, velocity_=-30,
                         damage_=100, energy_=1, sound_effect_=HEAVY_LASER1,
                         volume_=GL.SOUND_LEVEL, shooting_=False,
                         reloading_=0.08, elapsed_=0, super_='GREEN_PHOTON_5',
                         super_warm_up_=WARM_UP_GREEN,
                         animation_=None, level_up_=GREEN_PHOTON_2)


# LEVIATHAN
GREEN_LASER_5 = Weapons(name_='GREEN_LASER_SUPER', sprite_=LASER_FX[17],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=500, energy_=10, sound_effect_=FIRE_PLASMA,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.8, elapsed_=0, super_=None,
                        super_warm_up_=None, level_up_=None)

GREEN_LASER_4 = Weapons(name_='GREEN_LASER_SEXTUPLE', sprite_=LASER_FX[16],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=160, energy_=6, sound_effect_=TX0_FIRE3,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.26, elapsed_=0, super_='GREEN_PHOTON_5',
                        super_warm_up_=None,
                        animation_=None, level_up_=None)

GREEN_LASER_3 = Weapons(name_='GREEN_LASER_QUADRUPLE', sprite_=LASER_FX[16],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=140, energy_=6, sound_effect_=TX0_FIRE2,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.24, elapsed_=0, super_='GREEN_LASER_5',
                        super_warm_up_=None,
                        animation_=None, level_up_=GREEN_LASER_4)

GREEN_LASER_2 = Weapons(name_='GREEN_LASER_DOUBLE', sprite_=LASER_FX[16],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=130, energy_=4, sound_effect_=TX0_FIRE2,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.22, elapsed_=0, super_='GREEN_LASER_5',
                        super_warm_up_=None,
                        animation_=None, level_up_=GREEN_LASER_3)

GREEN_LASER_1 = Weapons(name_='GREEN_LASER_SINGLE', sprite_=LASER_FX[16],
                        range_=GL.screenrect.h, velocity_=-28,
                        damage_=120, energy_=3, sound_effect_=TX0_FIRE1,
                        volume_=GL.SOUND_LEVEL, shooting_=False,
                        reloading_=0.2, elapsed_=0, super_='GREEN_LASER_5',
                        super_warm_up_=None,
                        animation_=None, level_up_=GREEN_LASER_2)

DEBRIS = Weapons(name_='RED_DEBRIS_SINGLE', sprite_=None, range_=None, velocity_=10,
                 damage_=150, energy_=None, sound_effect_=None, volume_=None,
                 shooting_=False, reloading_=1.0, elapsed_=0, super_=None, super_warm_up_=None,
                 animation_=None, level_up_=None)


class HALO:
    def __init__(self, name: str, min_radius: int, radius: int, velocity: (int, float),
                 mass: (int, float), damage: int):
        """
        :param name: Name
        :param min_radius: Minimum radius
        :param radius:  Max blast radius prior collapsing
        :param velocity: blast speed
        :param mass: Virtual mass used for elastic collision engine
        :param damage: Maximal damage caused by the explosion halo
        """
        assert isinstance(name, str), \
            'Expecting str for argument name got %s ' % type(name)
        assert isinstance(min_radius, int), \
            'Expecting int for argument min_radius got %s ' % type(min_radius)
        assert isinstance(radius, int), \
            'Expecting int for argument radius got %s ' % type(radius)
        assert isinstance(velocity, (int, float)), \
            'Expecting int or float for argument velocity got %s ' % type(velocity)
        assert isinstance(mass, (int, float)), \
            'Expecting int or float for argument mass got %s ' % type(mass)
        assert isinstance(damage, int), \
            'Expecting int for argument damage got %s ' % type(damage)

        assert velocity != 0, "\n[-]ERROR - Halo velocity cannot be equal to zero."

        self.name = name
        # Minimum blast radius
        self.min_radius = min_radius
        # Max blast radius prior collapsing
        self.blast_radius = radius
        # blast speed
        self.velocity = velocity
        # Virtual mass used for elastic collision engine
        self.mass = mass
        # Maximal damage
        self.damage = damage


HALO_NUCLEAR_BOMB = HALO(name='NUCLEAR_HALO', min_radius=200, radius=900, velocity=0.57,
                         mass=10000.0,
                         damage=15000)

HALO_STINGER_MISSILE = HALO(name='STINGER_HALO', min_radius=50, radius=300, velocity=0.57,
                            mass=300, damage=1050)

HALO_EXPLOSION = HALO(name='GENERIC HALO', min_radius=50, radius=400, velocity=0.57,
                      mass=400, damage=80)

STINGER_MISSILE = Weapons(
    name_='STINGER_SINGLE',
    sprite_=STINGER_IMAGE,
    range_=GL.screenrect.h,
    velocity_=-15,
    damage_=HALO_STINGER_MISSILE.damage,
    energy_=0,
    sound_effect_=MISSILE_FLIGHT_SOUND,
    volume_=GL.SOUND_LEVEL,
    shooting_=False,
    reloading_=2,
    elapsed_=0,
    super_=None,
    super_warm_up_=None,
    animation_=SPACESHIP_SPRITE,
    max_rotation_=10,
    blast_radius=HALO_STINGER_MISSILE.blast_radius,
    mass_=HALO_STINGER_MISSILE.mass
)

NUCLEAR_MISSILE = Weapons(
    name_='NUCLEAR_SINGLE',
    sprite_=NUKE_BOMB_SPRITE,
    range_=GL.screenrect.h,
    velocity_=-15,
    damage_=HALO_NUCLEAR_BOMB.damage,
    energy_=0,
    sound_effect_=BOMB_RELEASE,
    volume_=GL.SOUND_LEVEL,
    shooting_=False,
    reloading_=3,
    elapsed_=0,
    super_=None,
    super_warm_up_=None,
    animation_=SPACESHIP_SPRITE,
    max_rotation_=0,
    blast_radius=HALO_NUCLEAR_BOMB.blast_radius,
    mass_=HALO_NUCLEAR_BOMB.mass
)

CLUSTER_BOMB_1 = Weapons(
    name_='CLUSTER_BOMB', sprite_=BOMB, range_=GL.screenrect.h,
    velocity_=None,
    damage_=HALO_NUCLEAR_BOMB.damage, energy_=0, sound_effect_=BOMB_RELEASE,
    volume_=GL.SOUND_LEVEL, shooting_=False, reloading_=5,
    elapsed_=0, super_=None,
    super_warm_up_=None, animation_=SPACESHIP_SPRITE, max_rotation_=0,
    blast_radius=HALO_NUCLEAR_BOMB.blast_radius,
    mass_=HALO_NUCLEAR_BOMB.mass)

TESLA_BLUE = Weapons(name_='BLUE_TESLA_SINGLE', sprite_=TESLA_BLUE_SPRITE,
                     range_=(GL.screenrect.h >> 1), velocity_=0,
                     damage_=4, energy_=5, sound_effect_=BEAM_FUSION_MED,
                     volume_=GL.SOUND_LEVEL, shooting_=False, reloading_=2, elapsed_=0, super_=None,
                     super_warm_up_=None, animation_=SPACESHIP_SPRITE)

LZRFX001 = Weapons(name_='GREEN_LAZER_SINGLE', sprite_=LASER_FX[4],
                   range_=GL.screenrect.h, velocity_=-33,
                   damage_=65, energy_=12, sound_effect_=TX0_FIRE1, volume_=GL.SOUND_LEVEL,
                   shooting_=False, reloading_=0.2, elapsed_=0, super_=None, super_warm_up_=None,
                   animation_=SPACESHIP_SPRITE, level_up_=None)
# wing turret sound
LZRFX109 = Weapons(name_='BLUE_LAZER_SINGLE', sprite_=LASER_FX[18],
                   range_=(GL.screenrect.h >> 1), velocity_=-38,
                   damage_=22, energy_=5, sound_effect_=TX0_FIRE1, volume_=GL.SOUND_LEVEL,
                   shooting_=False, reloading_=0.2, elapsed_=0, super_=None, super_warm_up_=None,
                   animation_=None, level_up_=None)


LASER_BEAM_BLUE = Weapons(name_='C_DEATHRAY_SINGLE', sprite_=DEATHRAY_SPRITE_BLUE,
                          range_=GL.screenrect.h,
                          velocity_=None, damage_=80, energy_=15, sound_effect_=BEAM_FUSION_MED,
                          volume_=GL.SOUND_LEVEL,
                          shooting_=False, reloading_=5, elapsed_=0, super_=None,
                          super_warm_up_=None,
                          animation_=None, level_up_=None)
LASER_BEAM_BLUE_SMALL = Weapons(name_='C_DEATHRAY_SINGLE', sprite_=DEATHRAY_SPRITE_BLUE_16,
                                range_=GL.screenrect.h,
                                velocity_=None, damage_=30, energy_=7,
                                sound_effect_=BEAM_FUSION_SMALL,
                                volume_=GL.SOUND_LEVEL,
                                shooting_=False, reloading_=5, elapsed_=0, super_=None,
                                super_warm_up_=None,
                                animation_=None, level_up_=None)

LEVIATHAN_DEATHRAY_RAY = Weapons(name_='C_DEATHRAY_SINGLE', sprite_=DEATHRAY_LEVIATHAN,
                                 range_=GL.screenrect.h,
                                 velocity_=None, damage_=100, energy_=17,
                                 sound_effect_=BEAM_PLASMA_SMALL,
                                 volume_=GL.SOUND_LEVEL, shooting_=False, reloading_=5, elapsed_=0,
                                 super_=None, super_warm_up_=None, animation_=None, level_up_=None)

DEATH_RAY_RED_B1 = Weapons(name_='C_DEATHRAY_SINGLE', sprite_=DEATHRAY_RED_B1,
                           range_=(GL.screenrect.h >> 1), velocity_=None, damage_=100, energy_=25,
                           sound_effect_=BEAM_ION_MED, volume_=GL.SOUND_LEVEL, shooting_=False,
                           reloading_=10,
                           elapsed_=0, super_=None, super_warm_up_=None, animation_=None,
                           level_up_=None)

BEAM = {'NEMESIS': [LASER_BEAM_BLUE, DEATHRAY_SHAFT, SUPERLASER_BURST],
        'LEVIATHAN': [LEVIATHAN_DEATHRAY_RAY, DEATHRAY_LEVIATHAN_SHAFT, SUPERLASER_BURST1]}


# Turret names
# Galatine, Secace, Almace
class TurretClass:
    # Turret strategy and fallback strategy
    STRATEGY = ['NEAR_COLLISION',
                # near objects in collision course
                # with the player (closest got highest priority)
                'FAR_COLLISION',
                # far objects in collision course with the player got highest priority)
                'LOW_DEADLINESS',
                # least deadliest objects got highest priority
                # (based on damage points send to player)
                'HIGH_DEADLINESS',
                # Deadliest objects got highest priority
                # (based on damage points send to player)
                'FRONT',
                # Object located at the front of the player center
                'BEHIND',
                'SIDE',
                'SLOWEST',
                'FASTEST',
                'NEAREST',
                'FARTHEST',
                'ENEMY']

    def __init__(self, name: str,
                 fov: int,
                 rotation_speed: int,
                 max_rotation: int,
                 sprite: pygame.Surface,
                 operational_status: bool,
                 mounted_weapon: Weapons,
                 laser_orientation: int,
                 overheating: bool,
                 rest_angle: int,
                 aim_assist: bool,
                 target_sprite: pygame.Surface,
                 strategy: int,
                 fallback_strategy: int):
        """

        :param name: Name of the turret Galatine, Secace or Almace.
                     3 different types with different characteristics
        :param fov: Field of view. Target outside the FOV will be ignore.
        :param rotation_speed: Turret angular speed
        :param max_rotation: : Tolerance for target angle (Target in angle +/-
        Tolerance is considered locked)
        :param sprite: Single sprite or animation
        :param operational_status: Turret Operational deployed
        :param mounted_weapon: Weapon system mounted with the Turret
        :param laser_orientation: laser facing 0 degrees
        :param overheating: self explanatory
        :param rest_angle: Turret facing rest_angle (degrees) direction when initialize or
         resting position
        :param aim_assist: Aiming assisted with pre-calculation to give a nothch to the laser
         to get a direct hit.
        :param target_sprite: Target sprite (aim)
        :param strategy: Turret strategy. The strategy define what the turret will aim and
         shoot first.
                         If no target exist in the present strategy mode, the turret strategy
                          will fall back
                        to the fallback_strategy mode below.
        :param fallback_strategy: Turret fallback method, emergency strategy mode.
                        e.g strategy mode selected -> nearest colliders (but no targets are
                         in collision course,
                        the mode will fall back to fallback_strategy mode (less specific)
        """
        assert isinstance(name, str), 'Expecting string for argument name got %s ' % type(name)
        assert isinstance(fov, int), 'Expecting int for argument fov got %s ' % type(fov)
        assert isinstance(rotation_speed, int), \
            'Expecting int for argument rotation_speed got %s ' % type(rotation_speed)
        assert isinstance(max_rotation, int), 'Expecting int for argument max_rotation got %s '\
                                              % type(max_rotation)
        assert isinstance(sprite, (pygame.Surface, list)), \
            'Expecting pygame.Surface or list for argument sprite got %s ' % type(sprite)
        assert isinstance(operational_status, bool), \
            'Expecting bool for argument operational_status got %s ' % type(operational_status)
        assert isinstance(mounted_weapon, Weapons), \
            'Expecting Weapons for argument mounted_weapon got %s ' % type(mounted_weapon)
        assert isinstance(laser_orientation, int), \
            'Expecting int for argument laser_orientation got %s ' % type(laser_orientation)
        assert isinstance(overheating, bool), 'Expecting bool for argument overheating got %s '\
                                              % type(overheating)
        assert isinstance(rest_angle, int), 'Expecting int for argument rest_angle got %s '\
                                            % type(rest_angle)
        assert isinstance(aim_assist, bool), 'Expecting bool for argument aim_assist got %s '\
                                             % type(aim_assist)
        assert isinstance(target_sprite, pygame.Surface), \
            'Expecting pygame.Surface for argument target_sprite got %s ' % type(target_sprite)
        assert isinstance(strategy, int), \
            'Expecting int for argument strategy got %s ' % type(strategy)
        assert isinstance(fallback_strategy, int), \
            'Expecting int for argument fallback_strategy got %s ' % type(fallback_strategy)
        self.name = name
        self.fov = fov
        self.rotation_speed = rotation_speed
        self.sprite = sprite
        self.operational_status = operational_status
        self.mounted_weapon = mounted_weapon
        self.overheating = overheating
        self.rest_angle = rest_angle
        self.max_rotation = max_rotation
        self.aim_assist = aim_assist
        self.laser_orientation = laser_orientation
        self.target_sprite = target_sprite
        self.strategy = TurretClass.STRATEGY[strategy]
        self.fallback_strategy = TurretClass.STRATEGY[fallback_strategy]

    def __copy__(self):
        return TurretClass(self.name,
                           self.fov,
                           self.rotation_speed,
                           self.max_rotation,
                           self.sprite,
                           self.operational_status,
                           self.mounted_weapon,
                           self.laser_orientation,
                           self.overheating,
                           self.rest_angle,
                           self.aim_assist,
                           self.target_sprite,
                           TurretClass.STRATEGY.index(self.strategy),
                           TurretClass.STRATEGY.index(self.fallback_strategy))


TURRET_GALATINE = TurretClass(name='Galatine', fov=270, rotation_speed=6,
                              max_rotation=20, sprite=TURRET_SPRITE,
                              operational_status=True, mounted_weapon=LZRFX001,
                              laser_orientation=0, overheating=False,
                              rest_angle=90, aim_assist=True, target_sprite=TURRET_TARGET_SPRITE,
                              strategy=0, fallback_strategy=9)
# strategy NEAREST fallback to FAR_COLLISION

TURRET_SECACE = TurretClass(name='Secace', fov=315, rotation_speed=6, max_rotation=10,
                            sprite=TURRET_SPRITE,
                            operational_status=True, mounted_weapon=LZRFX001,
                            laser_orientation=0, overheating=False,
                            rest_angle=270, aim_assist=True, target_sprite=TURRET_TARGET_SPRITE,
                            strategy=0, fallback_strategy=9)
# strategy NEAR_COLLISION, fallback to LOW_DEADLINESS

TURRET_ALMACE = TurretClass(name='Almace', fov=360, rotation_speed=4, max_rotation=10,
                            sprite=TURRET_SPRITE,
                            operational_status=True, mounted_weapon=TESLA_BLUE,
                            laser_orientation=0, overheating=False,
                            rest_angle=270, aim_assist=True, target_sprite=TURRET_TARGET_SPRITE,
                            strategy=0,
                            fallback_strategy=2)
# strategy NEAR_COLLISION, fallback to LOW_DEADLINESS


class ShieldClass:
    def __init__(self, name: str, energy: float, max_energy: float, operational_status: bool,
                 shield_up: bool, overloaded: bool, disrupted: bool, sprite: pygame.Surface,
                 recharge_speed: float, shield_sound, shield_sound_down, shield_sound_impact,
                 shield_glow_sprite, impact_sprite, shield_disrupted_sprite=BLURRY_WATER2,
                 shield_electric=SHIELD_ELECTRIC_ARC_1.copy(), disruption_time=5000):

        assert isinstance(name, str), 'Expecting string for argument name got %s ' % type(name)
        assert isinstance(energy, float), 'Expecting float for argument energy got %s '\
                                          % type(energy)
        assert isinstance(max_energy, float), 'Expecting float for argument max_energy got %s '\
                                              % type(max_energy)
        assert isinstance(operational_status, bool), \
            'Expecting bool for argument operational_status got %s ' % type(operational_status)
        assert isinstance(shield_up, bool), 'Expecting bool for argument shield_up got %s ' %\
                                            type(shield_up)
        assert isinstance(overloaded, bool), 'Expecting bool for argument overloaded got %s ' %\
                                             type(overloaded)
        assert isinstance(disrupted, bool), 'Expecting bool for argument disrupted got %s ' %\
                                            type(disrupted)
        assert isinstance(sprite, (pygame.Surface, list)), \
            'Expecting pygame.surface or list for argument sprite got %s ' % type(sprite)
        assert isinstance(recharge_speed, float), \
            'Expecting float for argument recharge_speed got %s ' % type(recharge_speed)

        assert isinstance(shield_sound, pygame.mixer.Sound), \
            'Expecting pygame.mixer.Sound for argument shield_sound got %s ' %\
            type(shield_sound)
        assert isinstance(shield_sound_down, pygame.mixer.Sound), \
            'Expecting pygame.mixer.Sound for argument shield_sound_down got %s ' %\
            type(shield_sound_down)
        assert isinstance(shield_sound_impact, pygame.mixer.Sound), \
            'Expecting pygame.mixer.Sound for argument shield_sound_impact got %s ' %\
            type(shield_sound_impact)
        assert isinstance(shield_glow_sprite, list), \
            'Expecting list for argument shield_glow_sprite got %s ' % type(shield_glow_sprite)
        assert isinstance(disruption_time, int), \
            'Expecting list for argument disruption_time got %s ' % type(disruption_time)
        assert isinstance(shield_disrupted_sprite, (pygame.Surface, list)), \
            'Expecting pygame.surface or list for argument disruption_time got %s ' %\
            type(shield_disrupted_sprite)
        assert isinstance(shield_electric, (pygame.Surface, list)), \
            'Expecting pygame.surface or list for argument disruption_time got %s ' %\
            type(shield_electric)
        self.name = name
        self.max_energy = max_energy
        # s.m.i (shield meter indicator)
        self.smi = SHIELD_METER_INDICATOR
        # s.b.i (shield border indicator)
        self.sbi = SHIELD_BORDER_INDICATOR
        # self.ratio = self.ratio_calculator()

        self.energy = energy
        self.__energy = energy

        self.operational_status = operational_status
        self.shield_up = shield_up
        self.overloaded = overloaded
        self.disrupted = disrupted
        self.sprite = sprite
        self.recharge_speed = recharge_speed
        self.shield_sound = shield_sound
        self.shield_sound_down = shield_sound_down
        self.shield_sound_impact = shield_sound_impact
        self.shield_glow_sprite = shield_glow_sprite
        self.impact_sprite = impact_sprite
        self.shield_disrupted_sprite = shield_disrupted_sprite
        self.shield_electric = shield_electric
        self.disruption_time = disruption_time

        # s.m.m (shield meter max)
        self.smm = SHIELD_METER_MAX

    @property
    def energy(self):
        return self.__energy

    @energy.setter
    def energy(self, energy):
        self.__energy = energy
        if energy <= 0:
            self.__energy = 0
        elif energy > self.max_energy:
            self.__energy = self.max_energy
        # Ratio calculator for each impact.
        self.ratio = self.ratio_calculator()

    def ratio_calculator(self):
        assert self.max_energy > 0, 'max_energy should not be equal to zero'
        return self.energy * self.smi.get_width() / self.max_energy

    def default(self):
        """
        Re-initialised the shield default values when enemy re-spawn on the level.
        :return:
        """
        self.energy = self.max_energy  # shield energy full up
        self.operational_status = True  # deployed back to operational
        self.shield_up = False  # Shield is down
        self.overloaded = False  # overload is False
        self.disrupted = False  # disrupted is False

    def __copy__(self):
        return ShieldClass(self.name, self.energy, self.max_energy, self.operational_status,
                           self.shield_up, self.overloaded, self.disrupted, self.sprite,
                           self.recharge_speed, self.shield_sound, self.shield_sound_down,
                           self.shield_sound_impact,
                           self.shield_glow_sprite, self.impact_sprite,
                           self.shield_disrupted_sprite,
                           self.shield_electric, self.disruption_time)


# Player shield names
# Aegis, Ancile, Achilles

SHIELD_ACHILLES = ShieldClass(name='Achilles', energy=2000.0, max_energy=2000.0,
                              operational_status=True,
                              shield_up=False, overloaded=False, disrupted=False,
                              sprite=ROUND_SHIELD_1,
                              recharge_speed=1.0,
                              shield_sound=FORCE_FIELD_SOUND, shield_sound_down=SHIELD_DOWN_SOUND,
                              shield_sound_impact=SHIELD_IMPACT_SOUND,
                              shield_glow_sprite=SHIELD_GLOW_BLUE,
                              impact_sprite=CLUSTER_EXPLOSION,
                              shield_disrupted_sprite=BLURRY_WATER1_,
                              shield_electric=SHIELD_ELECTRIC_ARC_1_)

SHIELD_ANCILE = ShieldClass(name='Ancile', energy=4000.0, max_energy=4000.0,
                            operational_status=True,
                            shield_up=False, overloaded=False, disrupted=False,
                            sprite=ROUND_SHIELD_2,
                            recharge_speed=2.0, shield_sound=FORCE_FIELD_SOUND,
                            shield_sound_down=SHIELD_DOWN_SOUND,
                            shield_sound_impact=SHIELD_IMPACT_SOUND,
                            shield_glow_sprite=SHIELD_GLOW_BLUE,
                            impact_sprite=CLUSTER_EXPLOSION,
                            shield_disrupted_sprite=BLURRY_WATER1_,
                            shield_electric=SHIELD_ELECTRIC_ARC_1_)

SHIELD_AEGIS = ShieldClass(name='Aegis', energy=10000.0, max_energy=10000.0,
                           operational_status=True,
                           shield_up=False, overloaded=False, disrupted=False,
                           sprite=ROUND_SHIELD_1,
                           recharge_speed=3.0, shield_sound=FORCE_FIELD_SOUND,
                           shield_sound_down=SHIELD_DOWN_SOUND,
                           shield_sound_impact=SHIELD_IMPACT_SOUND,
                           shield_glow_sprite=SHIELD_GLOW_BLUE,
                           impact_sprite=CLUSTER_EXPLOSION,
                           shield_disrupted_sprite=BLURRY_WATER1_,
                           shield_electric=SHIELD_ELECTRIC_ARC_1_)

CURRENT_TURRET = TURRET_GALATINE

if __name__ == '__main__':

    print(NUCLEAR_MISSILE.name)
    print(NUCLEAR_MISSILE.units)
    print(NUCLEAR_MISSILE.type_)
    print(NUCLEAR_MISSILE.color_)

    a = GREEN_PHOTON_4.__copy__()
    print(hasattr(a, 'compiled'))

    print(a.name)
    print(a.units)
    print(a.type_)
    print(a.color_)
    print(a.super, type(a.super))
    a.shooting = True
    a.reloading = True
    a.elapsed = 0.5
    b = a.get_super()
    print(b.shooting, b.reloading, b.elapsed)
    print(b.super, type(b.super))
    b.elapsed = time.time()
    while 1:
        if a.get_super() is not None:
            a.weapon_reloading_super()
        print(a.shooting, a.reloading, a.elapsed, b.shooting, b.reloading, b.elapsed)
