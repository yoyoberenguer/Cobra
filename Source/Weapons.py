# encoding: utf-8


from Sprites import SUPERSHOT_SPRITE_1, SHOOTING_SPRITE, SUPERSHOT_SPRITE_3, \
    SUPERSHOT_SPRITE_2, SUPERSHOT_SPRITE_5, SUPERSHOT_SPRITE_6, \
    SUPERSHOT_SPRITE_4, SUPERSHOT_GREEN_LASER, \
    STINGER_MISSILE_SPRITE, NUKE_BOMB_SPRITE, TESLA_BLUE_SPRITE, TURRET_SPRITE, SHIELD_BORDER_INDICATOR, \
    SHIELD_METER_INDICATOR, SHIELD_METER_MAX, ROUND_SHIELD_1, LAZER_FX, TURRET_TARGET_SPRITE, PHOTON_PARTICLE_7, \
    PHOTON_PARTICLE_4, PHOTON_PARTICLE_3, PHOTON_PARTICLE_5, PHOTON_PARTICLE_2, PHOTON_PARTICLE_6, SPACESHIP_SPRITE, \
    SHIELD_SOFT_GREEN, SHIELD_SOFT_RED, SHIELD_GLOW, SHIELD_HEATGLOW, DEATHRAY_SPRITE_BLUE

from Constants import SCREENRECT, SOUND_LEVEL

from Sounds import SUPERSHOT_WARMUP_1, FIRE_PLASMA, HEAVY_LASER2, HEAVY_LASER1, TX0_FIRE1, TX0_FIRE2, TX0_FIRE3, \
    CANNON_1, CANNON_2, CANNON_3, PLAMA_SOUND_1, BEAM_ELECTRIC_1, MISSILE_FLIGHT_SOUND, BOMB_RELEASE, \
    BEAM_FUSION_MED, SD_LASER_LARGE_ALT_03, SD_LASER_BURST, FORCE_FIELD_SOUND, SHIELD_DOWN_SOUND, SHIELD_IMPACT_SOUND, \
    FIRE_BOLT_MICRO

import time
import pygame

SHOT_CONFIGURATION = {'SINGLE': 1, 'DOUBLE': 2, 'QUADRUPLE': 4, 'SEXTUPLE': 6}
# Assign a particle color according to the weapon.
WEAPON_COLOR = {'RED': PHOTON_PARTICLE_7, 'BLUE': PHOTON_PARTICLE_4, 'YELLOW': PHOTON_PARTICLE_3, \
                'PURPLE': PHOTON_PARTICLE_5, 'GREEN': PHOTON_PARTICLE_2, 'GOLD': PHOTON_PARTICLE_6}

WEAPON_OFFSET_X = {0: 'self.rect.move_ip(0, speed_.y)',
                   -17: 'self.rect.move_ip(-1, speed_.y)',
                   17: 'self.rect.move_ip(1, speed_.y)',
                   -30: 'self.rect.move_ip(-4, speed_.y)',
                   30: 'self.rect.move_ip(4, speed_.y)',
                   -45: 'self.rect.move_ip(-7, speed_.y)',
                   45: 'self.rect.move_ip(7, speed_.y)'}

WEAPON_ROTOZOOM = {0: 'pygame.transform.rotate(surface_, 0)',
                   -17: 'pygame.transform.rotate(surface_, 5)',
                   17: 'pygame.transform.rotate(surface_, -5)',
                   -30: 'pygame.transform.rotate(surface_, 10)',
                   30: 'pygame.transform.rotate(surface_, -10)',
                   -45: 'pygame.transform.rotate(surface_, 17)',
                   45: 'pygame.transform.rotate(surface_, -17)'}
"""
# MULTI-THREAD only
# todo need to complete the strategy
TURRET_STRATEGY = \
    {'NEAREST': 'Threat(C.PLAYER.rect).single_sorted_by_distance_nearest(objects)',
     'FARTHEST': 'Threat(C.PLAYER.rect).single_sorted_by_distance_farthest(objects)',
     'LOW_DEADLINESS': 'Threat(C.PLAYER.rect).sort_by_low_deadliness(objects)',
     'HIGH_DEADLINESS': 'Threat(C.PLAYER.rect).sort_by_high_deadliness(objects)',
     'NEAR_COLLISION': 'Threat(C.PLAYER.rect).sort_by_nearest_collider(C.ia.colliders(C.asteroids, C.PLAYER.rect))',
     'FAR_COLLISION': 'Threat(C.PLAYER.rect).sort_by_farthest_collider(C.ia.colliders(C.asteroids, C.PLAYER.rect))'
     }
"""

TURRET_STRATEGY = \
    {'NEAREST': 'Threat(player.rect).single_sorted_by_distance_nearest(objects)',
     'FARTHEST': 'Threat(player.rect).single_sorted_by_distance_farthest(objects)',
     'LOW_DEADLINESS': 'Threat(player.rect).sort_by_low_deadliness(objects)',
     'HIGH_DEADLINESS': 'Threat(player.rect).sort_by_high_deadliness(objects)',
     'NEAR_COLLISION': 'Threat(player.rect).sort_by_nearest_collider(ia.colliders(group_, player.rect))',
     'FAR_COLLISION': 'Threat(player.rect).sort_by_farthest_collider(ia.colliders(group_, player.rect))'
     }


class SuperWeapon:
    def __init__(self, name_: str, sprite_: list, sound_: pygame.mixer.Sound, volume_: int):
        assert isinstance(name_, str), 'Expecting python string got %s ' % type(name_)
        assert isinstance(sprite_, list), 'Expecting python list got %s ' % type(sprite_)
        assert isinstance(sound_, pygame.mixer.Sound), 'Expecting pygame.mixer.Sound class got %s ' % type(sound_)
        assert isinstance(volume_, (int, float)), 'Expecting python integer or foat got %s ' % type(volume_)
        self.name = name_
        self.sprite = sprite_
        self.sound_effect = sound_
        self.volume = volume_


class Weapons:

    def __init__(self, name_: str, sprite_: (pygame.Surface, list), range_: (int, None),
                 velocity_: (int, None), damage_: int,
                 energy_: int, sound_effect_: pygame.mixer.Sound, volume_: (int, float), shooting_: bool = False,
                 reloading_: float = 1000.0, elapsed_: object = float, super_: (None, SuperWeapon) = None,
                 super_warm_up_: (SuperWeapon, None) = None, animation_: (pygame.Surface, list) = None,
                 level_up_: (pygame.Surface, None) = None, blast_radius: int = 0, mass_: (float, int) = 0.0):

        assert len(name_) > 1, 'Error weapon name is not correct.'
        if len(name_.split('_')) > 2:
            self.units = name_.split('_')[2]
        else:
            self.units = 'SINGLE'
        self.type_ = name_.split('_')[1]  # ex Laser, Photon etc
        self.color_ = name_.split('_')[0]
        self.name = name_  # ex GREEN_LASER_DOUBLE

        assert isinstance(sprite_, (list, pygame.Surface, type(None))), \
            'Expecting a list, pygame.Surface or NoneType got %s ' % type(sprite_)
        assert isinstance(range_, (int, type(None))), \
            'Expecting a python int or NoneType got %s ' % type(range_)
        # assert isinstance(velocity_, math.Vector2), 'Expecting a python math.Vector2 got %s ' % type(velocity_)
        assert isinstance(velocity_, (int, type(None))), \
            'Expecting a python int or NoneType got %s ' % type(velocity_)
        # todo continue with the assert statements
        self.sprite = sprite_  # images_
        self.range = range_  # define the maximal range of a projectile
        if velocity_:
            self.velocity = pygame.math.Vector2(0, velocity_)  # Projectile velocity (pixels/cycle)
        self.damage = damage_  # Maximal damage
        self.energy = energy_  # Energy cost
        self.sound_effect = sound_effect_
        self.volume = volume_
        self.shooting = shooting_  # Status shooting(True)/not shooting(False)
        self.reloading = reloading_  # Reloading time in seconds
        self.elapsed = elapsed_  # Remaining time before next shot
        self.super = super_  # pointing to the super weapon
        self.super_warm_up = super_warm_up_
        self.animation = animation_
        self.level_up = level_up_  # next weapon
        self.blast_radius = blast_radius
        self.mass = mass_  # projectile mass or shock_wave max force in kg

    def weapon_reloading_std(self):
        # check if the reloading time is over for the standard shot
        # print(self.reloading, ' < ', time.time(), self.elapsed, time.time() - self.elapsed,)
        if self.reloading < time.time() - self.elapsed:
            # weapon ready to fire again
            self.shooting = False
            self.elapsed = 0
            return False
        else:
            self.shooting = True
            return True

    def weapon_reloading_super(self):
        if self.super is not None:
            # check if the reloading time is over for the super shot
            if self.get_super().reloading < time.time() - self.get_super().elapsed:
                # weapon ready to fire again
                self.get_super().shooting = False
                self.get_super().elapsed = 0
                return False
            else:
                self.get_super().shooting = True
                return True

    def get_super_warmup(self):
        if self.super_warm_up is not None:
            return self.super_warm_up
        else:
            return None

    def get_super(self):
        if self.super is not None:
            return eval(self.super)
        else:
            return None


# ------------------------------------- Weapon definition -----------------------------------------

# NAME, SPRITE, RANGE, VELOCITY, DAMAGE, ENERGY, SOUND, VOLUME, SHOOTING, RELOADING, ELAPSED, SUPER, SUPER WARMUP

# Red photon -------------------------------------------------------------------------------------------------------
# todo level up is incomplete
WARM_UP_RED = SuperWeapon(name_='WARM_UP_RED_1', sprite_=SUPERSHOT_SPRITE_1, sound_=SUPERSHOT_WARMUP_1,
                          volume_=SOUND_LEVEL)
RED_PHOTON_5 = Weapons(name_='RED_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[1], range_=SCREENRECT.h, velocity_=-30,
                       damage_=12000, energy_=60, sound_effect_=FIRE_PLASMA, volume_=SOUND_LEVEL, shooting_=False,
                       reloading_=1.2, elapsed_=0, super_=None, super_warm_up_=WARM_UP_RED)
RED_PHOTON_4 = Weapons(name_='RED_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[0], range_=SCREENRECT.h, velocity_=-28,
                       damage_=600, energy_=22, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                       reloading_=0.2, elapsed_=0, super_='RED_PHOTON_5', super_warm_up_=WARM_UP_RED,
                       animation_=None, level_up_=None)
RED_PHOTON_3 = Weapons(name_='RED_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[0], range_=SCREENRECT.h, velocity_=-28,
                       damage_=600, energy_=20, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                       reloading_=0.22, elapsed_=0, super_='RED_PHOTON_5', super_warm_up_=WARM_UP_RED,
                       animation_=None, level_up_=None)
RED_PHOTON_2 = Weapons(name_='RED_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[0], range_=SCREENRECT.h, velocity_=-28,
                       damage_=600, energy_=15, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                       reloading_=0.25, elapsed_=0, super_='RED_PHOTON_5', super_warm_up_=WARM_UP_RED,
                       animation_=None, level_up_=None)
RED_PHOTON_1 = Weapons(name_='RED_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[0], range_=SCREENRECT.h, velocity_=-28,
                       damage_=600, energy_=6, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                       reloading_=0.3, elapsed_=0, super_='RED_PHOTON_5', super_warm_up_=WARM_UP_RED,
                       animation_=None, level_up_=None)
# ---------------------------------------------------------------------------------------------------------------------

# Purple photon -------------------------------------------------------------------------------------------------------
WARM_UP_PURPLE = SuperWeapon(name_='WARM_UP_PURPLE', sprite_=SUPERSHOT_SPRITE_3, sound_=SUPERSHOT_WARMUP_1,
                             volume_=SOUND_LEVEL)

PURPLE_PHOTON_5 = Weapons(name_='PURPLE_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[5], range_=SCREENRECT.h, velocity_=-30,
                          damage_=6000, energy_=50, sound_effect_=FIRE_PLASMA, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=1.1, elapsed_=0, super_=None, super_warm_up_=WARM_UP_PURPLE)
PURPLE_PHOTON_4 = Weapons(name_='PURPLE_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[4], range_=SCREENRECT.h,
                          velocity_=-28,
                          damage_=500, energy_=20, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.2, elapsed_=0, super_='PURPLE_PHOTON_5', super_warm_up_=WARM_UP_PURPLE,
                          animation_=None, level_up_=RED_PHOTON_4)
PURPLE_PHOTON_3 = Weapons(name_='PURPLE_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[4], range_=SCREENRECT.h,
                          velocity_=-28,
                          damage_=500, energy_=14, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.25, elapsed_=0, super_='PURPLE_PHOTON_5', super_warm_up_=WARM_UP_PURPLE,
                          animation_=None, level_up_=RED_PHOTON_3)
PURPLE_PHOTON_2 = Weapons(name_='PURPLE_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[4], range_=SCREENRECT.h, velocity_=-28,
                          damage_=500, energy_=10, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.3, elapsed_=0, super_='PURPLE_PHOTON_5', super_warm_up_=WARM_UP_PURPLE,
                          animation_=None, level_up_=RED_PHOTON_2)
PURPLE_PHOTON_1 = Weapons(name_='PURPLE_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[4], range_=SCREENRECT.h, velocity_=-28,
                          damage_=500, energy_=5, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.35, elapsed_=0, super_='PURPLE_PHOTON_5', super_warm_up_=WARM_UP_PURPLE,
                          animation_=None, level_up_=RED_PHOTON_1)
# --------------------------------------------------------------------------------------------------------------------

# Blue photon --------------------------------------------------------------------------------------------------------
WARM_UP_BLUE = SuperWeapon(name_='WARM_UP_BLUE', sprite_=SUPERSHOT_SPRITE_2, sound_=SUPERSHOT_WARMUP_1,
                           volume_=SOUND_LEVEL)
BLUE_PHOTON_5 = Weapons(name_='BLUE_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[3], range_=SCREENRECT.h, velocity_=-30,
                        damage_=4000, energy_=40, sound_effect_=FIRE_PLASMA, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=1.0, elapsed_=0, super_=None, super_warm_up_=WARM_UP_BLUE)
BLUE_PHOTON_4 = Weapons(name_='BLUE_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[2], range_=SCREENRECT.h, velocity_=-28,
                        damage_=400, energy_=18, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.25, elapsed_=0, super_='BLUE_PHOTON_5', super_warm_up_=WARM_UP_BLUE,
                        animation_=None, level_up_=PURPLE_PHOTON_4)
BLUE_PHOTON_3 = Weapons(name_='BLUE_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[2], range_=SCREENRECT.h, velocity_=-28,
                        damage_=400, energy_=12, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.3, elapsed_=0, super_='BLUE_PHOTON_5', super_warm_up_=WARM_UP_BLUE,
                        animation_=None, level_up_=PURPLE_PHOTON_3)
BLUE_PHOTON_2 = Weapons(name_='BLUE_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[2], range_=SCREENRECT.h, velocity_=-28,
                        damage_=400, energy_=8, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.35, elapsed_=0, super_='BLUE_PHOTON_5', super_warm_up_=WARM_UP_BLUE,
                        animation_=None, level_up_=PURPLE_PHOTON_2)
BLUE_PHOTON_1 = Weapons(name_='BLUE_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[2], range_=SCREENRECT.h, velocity_=-28,
                        damage_=400, energy_=4, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.40, elapsed_=0, super_='BLUE_PHOTON_5', super_warm_up_=WARM_UP_BLUE,
                        animation_=None, level_up_=PURPLE_PHOTON_1)
# ------------------------------------------------------------------------------------------------------------------

# Gold photon ------------------------------------------------------------------------------------------------------
WARM_UP_GOLD = SuperWeapon(name_='WARM_UP_PURPLE', sprite_=SUPERSHOT_SPRITE_6, sound_=SUPERSHOT_WARMUP_1,
                           volume_=SOUND_LEVEL)
GOLD_PHOTON_5 = Weapons(name_='GOLD_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[11], range_=SCREENRECT.h, velocity_=-30,
                        damage_=2000, energy_=30, sound_effect_=FIRE_PLASMA, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.8, elapsed_=0, super_=None, super_warm_up_=WARM_UP_GOLD)
GOLD_PHOTON_4 = Weapons(name_='GOLD_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[10], range_=SCREENRECT.h, velocity_=-28,
                        damage_=300, energy_=10, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.3, elapsed_=0, super_='GOLD_PHOTON_5', super_warm_up_=WARM_UP_GOLD,
                        animation_=None, level_up_=BLUE_PHOTON_4)
GOLD_PHOTON_3 = Weapons(name_='GOLD_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[10], range_=SCREENRECT.h, velocity_=-28,
                        damage_=300, energy_=6, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.35, elapsed_=0, super_='GOLD_PHOTON_5', super_warm_up_=WARM_UP_GOLD,
                        animation_=None, level_up_=BLUE_PHOTON_3)
GOLD_PHOTON_2 = Weapons(name_='GOLD_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[10], range_=SCREENRECT.h, velocity_=-28,
                        damage_=300, energy_=4, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GOLD_PHOTON_5', super_warm_up_=WARM_UP_GOLD,
                        animation_=None, level_up_=BLUE_PHOTON_2)
GOLD_PHOTON_1 = Weapons(name_='GOLD_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[10], range_=SCREENRECT.h, velocity_=-28,
                        damage_=300, energy_=2, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.45, elapsed_=0, super_='GOLD_PHOTON_5', super_warm_up_=WARM_UP_GOLD,
                        animation_=None, level_up_=BLUE_PHOTON_1)
# -------------------------------------------------------------------------------------------------------------------


# Yellow photon -----------------------------------------------------------------------------------------------------
WARM_UP_YELLOW = SuperWeapon(name_='WARM_UP_PURPLE', sprite_=SUPERSHOT_SPRITE_5, sound_=SUPERSHOT_WARMUP_1,
                             volume_=SOUND_LEVEL)

YELLOW_PHOTON_5 = Weapons(name_='YELLOW_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[9], range_=SCREENRECT.h, velocity_=-30,
                          damage_=1000, energy_=20, sound_effect_=FIRE_PLASMA, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.6, elapsed_=0, super_=None, super_warm_up_=WARM_UP_YELLOW)
YELLOW_PHOTON_4 = Weapons(name_='YELLOW_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[8], range_=SCREENRECT.h,
                          velocity_=-28,
                          damage_=200, energy_=10, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.30, elapsed_=0, super_='YELLOW_PHOTON_5', super_warm_up_=WARM_UP_YELLOW,
                          animation_=None, level_up_=GOLD_PHOTON_4)
YELLOW_PHOTON_3 = Weapons(name_='YELLOW_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[8], range_=SCREENRECT.h,
                          velocity_=-28,
                          damage_=200, energy_=6, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.35, elapsed_=0, super_='YELLOW_PHOTON_5', super_warm_up_=WARM_UP_YELLOW,
                          animation_=None, level_up_=GOLD_PHOTON_3)
YELLOW_PHOTON_2 = Weapons(name_='YELLOW_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[8], range_=SCREENRECT.h, velocity_=-28,
                          damage_=200, energy_=4, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.40, elapsed_=0, super_='YELLOW_PHOTON_5', super_warm_up_=WARM_UP_YELLOW,
                          animation_=None, level_up_=GOLD_PHOTON_2)
YELLOW_PHOTON_1 = Weapons(name_='YELLOW_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[8], range_=SCREENRECT.h, velocity_=-28,
                          damage_=200, energy_=2, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                          reloading_=0.45, elapsed_=0, super_='YELLOW_PHOTON_5', super_warm_up_=WARM_UP_YELLOW,
                          animation_=None, level_up_=GOLD_PHOTON_1)
# -------------------------------------------------------------------------------------------------------------------

# Green photon ------------------------------------------------------------------------------------------------------
WARM_UP_GREEN = SuperWeapon(name_='WARM_UP_PURPLE', sprite_=SUPERSHOT_SPRITE_4, sound_=SUPERSHOT_WARMUP_1,
                            volume_=SOUND_LEVEL)

GREEN_PHOTON_5 = Weapons(name_='GREEN_PHOTON_SUPER', sprite_=SHOOTING_SPRITE[7], range_=SCREENRECT.h, velocity_=-28,
                         damage_=500, energy_=10, sound_effect_=FIRE_PLASMA, volume_=SOUND_LEVEL, shooting_=False,
                         reloading_=0.5, elapsed_=0, super_=None, super_warm_up_=WARM_UP_GREEN, level_up_=None)
GREEN_PHOTON_4 = Weapons(name_='GREEN_PHOTON_SEXTUPLE', sprite_=SHOOTING_SPRITE[6], range_=SCREENRECT.h, velocity_=-30,
                         damage_=100, energy_=6, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                         reloading_=0.35, elapsed_=0, super_='GREEN_PHOTON_5', super_warm_up_=WARM_UP_GREEN,
                         animation_=None, level_up_=YELLOW_PHOTON_4)
GREEN_PHOTON_3 = Weapons(name_='GREEN_PHOTON_QUADRUPLE', sprite_=SHOOTING_SPRITE[6], range_=SCREENRECT.h,
                         velocity_=-30,
                         damage_=100, energy_=4, sound_effect_=HEAVY_LASER2, volume_=SOUND_LEVEL, shooting_=False,
                         reloading_=0.40, elapsed_=0, super_='GREEN_PHOTON_5', super_warm_up_=WARM_UP_GREEN,
                         animation_=None, level_up_=YELLOW_PHOTON_3)
GREEN_PHOTON_2 = Weapons(name_='GREEN_PHOTON_DOUBLE', sprite_=SHOOTING_SPRITE[6], range_=SCREENRECT.h, velocity_=-30,
                         damage_=100, energy_=2, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                         reloading_=0.45, elapsed_=0, super_='GREEN_PHOTON_5', super_warm_up_=WARM_UP_GREEN,
                         animation_=None, level_up_=YELLOW_PHOTON_2)
GREEN_PHOTON_1 = Weapons(name_='GREEN_PHOTON_SINGLE', sprite_=SHOOTING_SPRITE[6], range_=SCREENRECT.h, velocity_=-30,
                         damage_=100, energy_=1, sound_effect_=HEAVY_LASER1, volume_=SOUND_LEVEL, shooting_=False,
                         reloading_=0.15, elapsed_=0, super_='GREEN_PHOTON_5', super_warm_up_=WARM_UP_GREEN,
                         animation_=None, level_up_=YELLOW_PHOTON_1)
# --------------------------------------------------------------------------------------------------------------------


GREEN_LASER_1 = Weapons(name_='GREEN_LASER_SINGLE', sprite_=SHOOTING_SPRITE[12], range_=SCREENRECT.h, velocity_=-28,
                        damage_=80, energy_=20, sound_effect_=TX0_FIRE1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.2, elapsed_=0, super_='GREEN_LASER_9', super_warm_up_=None)
GREEN_LASER_2 = Weapons(name_='GREEN_LASER_DOUBLE', sprite_=SHOOTING_SPRITE[12], range_=SCREENRECT.h, velocity_=-28,
                        damage_=90, energy_=20, sound_effect_=TX0_FIRE2, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GREEN_LASER_9', super_warm_up_=None)
GREEN_LASER_3 = Weapons(name_='GREEN_LASER_QUADRUPLE', sprite_=SHOOTING_SPRITE[12], range_=SCREENRECT.h, velocity_=-28,
                        damage_=120, energy_=20, sound_effect_=TX0_FIRE2, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GREEN_LASER_9', super_warm_up_=None)
GREEN_LASER_4 = Weapons(name_='GREEN_LASER_SEXTUPLE', sprite_=SHOOTING_SPRITE[12], range_=SCREENRECT.h, velocity_=-28,
                        damage_=150, energy_=20, sound_effect_=TX0_FIRE2, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GREEN_LASER_9', super_warm_up_=None)
"""
GREEN_LASER_5 = Weapons(name_='GREEN_LASER_SINGLE', sprite_=GREEN_LASER_WAVE, range_=SCREENRECT.h, velocity_=-28,
                        damage_=200, energy_=20, sound_effect_=TX0_FIRE1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GREEN_LASER_9', super_warm_up_=None)
GREEN_LASER_6 = Weapons(name_='GREEN_LASER_DOUBLE', sprite_=GREEN_LASER_WAVE, range_=SCREENRECT.h, velocity_=-28,
                        damage_=300, energy_=20, sound_effect_=TX0_FIRE1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GREEN_LASER_9', super_warm_up_=None)
GREEN_LASER_7 = Weapons(name_='GREEN_LASER_QUADRUPLE', sprite_=GREEN_LASER_WAVE, range_=SCREENRECT.h, velocity_=-28,
                        damage_=350, energy_=20, sound_effect_=TX0_FIRE1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GREEN_LASER_9', super_warm_up_=None)
GREEN_LASER_8 = Weapons(name_='GREEN_LASER_SEXTUPLE', sprite_=GREEN_LASER_WAVE, range_=SCREENRECT.h, velocity_=-28,
                        damage_=380, energy_=20, sound_effect_=TX0_FIRE1, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=0.4, elapsed_=0, super_='GREEN_LASER_9', super_warm_up_=None)
"""
GREEN_LASER_9 = Weapons(name_='GREEN_LASER_SINGLE', sprite_=SUPERSHOT_GREEN_LASER, range_=SCREENRECT.h, velocity_=-30,
                        damage_=600, energy_=40, sound_effect_=TX0_FIRE3, volume_=SOUND_LEVEL, shooting_=False,
                        reloading_=1.1, elapsed_=0, super_=None, super_warm_up_=None)

# NAME, SPRITE, RANGE, VELOCITY, DAMAGE, ENERGY, SOUND, VOLUME, SHOOTING, RELOADING, ELAPSED, SUPER, SUPER WARMUP
BULLET_4 = Weapons(name_='WHITE_BULLET_SEXTUPLE', sprite_=SHOOTING_SPRITE[14],
                   range_=SCREENRECT.h, velocity_=-35, damage_=50, energy_=0, sound_effect_=CANNON_1,
                   volume_=SOUND_LEVEL, shooting_=False, reloading_=0.22, elapsed_=0, super_=None, super_warm_up_=None,
                   animation_=None, level_up_=None)
BULLET_3 = Weapons(name_='WHITE_BULLET_QUADRUPLE', sprite_=SHOOTING_SPRITE[14],
                   range_=SCREENRECT.h, velocity_=-35, damage_=50, energy_=0, sound_effect_=CANNON_3,
                   volume_=SOUND_LEVEL, shooting_=False, reloading_=0.18, elapsed_=0, super_=None, super_warm_up_=None,
                   animation_=None, level_up_=BULLET_4)
BULLET_2 = Weapons(name_='WHITE_BULLET_DOUBLE', sprite_=SHOOTING_SPRITE[14],
                   range_=SCREENRECT.h, velocity_=-35, damage_=50, energy_=0, sound_effect_=CANNON_2,
                   volume_=SOUND_LEVEL, shooting_=False, reloading_=0.14, elapsed_=0, super_=None, super_warm_up_=None,
                   animation_=None, level_up_=BULLET_3)
BULLET_1 = Weapons(name_='WHITE_BULLET_SINGLE', sprite_=SHOOTING_SPRITE[14],
                   range_=SCREENRECT.h, velocity_=-35, damage_=50, energy_=0, sound_effect_=CANNON_1,
                   volume_=SOUND_LEVEL, shooting_=False, reloading_=0.1, elapsed_=0, super_=None, super_warm_up_=None,
                   animation_=None, level_up_=BULLET_2)

"""
BLUE_ELECTRIC_SINGLE = Weapons(name_='BLUE_ELECTRIC_SINGLE', sprite_=ELECTRIC_DISCHARGE_SPRITE_GREEN,
                               range_=SCREENRECT.h, velocity_=0, damage_=1, energy_=0, sound_effect_=BEAM_ELECTRIC_1,
                               volume_=SOUND_LEVEL,
                               shooting_=False, reloading_=1, elapsed_=0, super_=None, super_warm_up_=None,
                               animation_=SPACESHIP_SPRITE)

BLUE_ELECTRIC_DOUBLE = Weapons(name_='BLUE_ELECTRIC_DOUBLE', sprite_=ELECTRIC_DISCHARGE_SPRITE_GREEN,
                               range_=SCREENRECT.h, velocity_=0, damage_=1, energy_=0, sound_effect_=BEAM_ELECTRIC_1,
                               volume_=SOUND_LEVEL,
                               shooting_=False, reloading_=1, elapsed_=0, super_=None, super_warm_up_=None,
                               animation_=SPACESHIP_SPRITE)

RED_ELECTRIC_SINGLE = Weapons(name_='RED_ELECTRIC_SINGLE', sprite_=ELECTRIC_DISCHARGE_SPRITE_RED,
                              range_=SCREENRECT.h, velocity_=0, damage_=1, energy_=0, sound_effect_=BEAM_ELECTRIC_1,
                              volume_=SOUND_LEVEL,
                              shooting_=False, reloading_=1, elapsed_=0, super_=None, super_warm_up_=None,
                              animation_=SPACESHIP_SPRITE)

GREEN_ELECTRIC_SINGLE = Weapons(name_='GREEN_ELECTRIC_SINGLE', sprite_=ELECTRIC_DISCHARGE_SPRITE_GREEN,
                                range_=SCREENRECT.h, velocity_=0, damage_=1, energy_=0, sound_effect_=BEAM_ELECTRIC_1,
                                volume_=SOUND_LEVEL,
                                shooting_=False, reloading_=1, elapsed_=0, super_=None, super_warm_up_=None,
                                animation_=SPACESHIP_SPRITE)

GREEN_ELECTRIC_DOUBLE = Weapons(name_='GREEN_ELECTRIC_DOUBLE', sprite_=ELECTRIC_DISCHARGE_SPRITE_GREEN,
                                range_=SCREENRECT.h, velocity_=0, damage_=1, energy_=0, sound_effect_=BEAM_ELECTRIC_1,
                                volume_=SOUND_LEVEL,
                                shooting_=False, reloading_=2, elapsed_=0, super_=None, super_warm_up_=None,
                                animation_=SPACESHIP_SPRITE)
"""

DEBRIS = Weapons(name_='RED_DEBRIS_SINGLE', sprite_=None, range_=None, velocity_=None,
                 damage_=150, energy_=None, sound_effect_=None, volume_=None,
                 shooting_=None, reloading_=None, elapsed_=None, super_=None, super_warm_up_=None,
                 animation_=None, level_up_=None)


class HALO:
    def __init__(self, name: str, min_radius: int, radius: int, velocity: pygame.math.Vector2,
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


HALO_NUCLEAR_BOMB = HALO(name='NUCLEAR_HALO', min_radius=200, radius=900, velocity=0.57, mass=10000.0,
                         damage=820)  # 100
HALO_STINGER_MISSILE = HALO(name='STINGER_HALO', min_radius=50, radius=300, velocity=0.57, mass=300, damage=150)  # 50
HALO_EXPLOSION = HALO(name='GENERIC HALO', min_radius=50, radius=400, velocity=0.57, mass=400, damage=80)  # 65

STINGER_MISSILE = Weapons(name_='STINGER_SINGLE', sprite_=STINGER_MISSILE_SPRITE, range_=SCREENRECT.h, velocity_=-19,
                          damage_=HALO_STINGER_MISSILE.damage, energy_=0, sound_effect_=MISSILE_FLIGHT_SOUND,
                          volume_=SOUND_LEVEL, shooting_=False, reloading_=2, elapsed_=0, super_=None,
                          super_warm_up_=None, animation_=SPACESHIP_SPRITE,
                          blast_radius=HALO_STINGER_MISSILE.blast_radius, mass_=HALO_STINGER_MISSILE.mass)

NUCLEAR_MISSILE = Weapons(name_='NUCLEAR_SINGLE', sprite_=NUKE_BOMB_SPRITE, range_=SCREENRECT.h, velocity_=-10,
                          damage_=HALO_NUCLEAR_BOMB.damage, energy_=0, sound_effect_=BOMB_RELEASE,
                          volume_=SOUND_LEVEL, shooting_=False, reloading_=5, elapsed_=0, super_=None,
                          super_warm_up_=None, animation_=SPACESHIP_SPRITE,
                          blast_radius=HALO_NUCLEAR_BOMB.blast_radius, mass_=HALO_NUCLEAR_BOMB.mass)

TESLA_BLUE = Weapons(name_='BLUE_TESLA_SINGLE', sprite_=TESLA_BLUE_SPRITE, range_=SCREENRECT.h // 2, velocity_=0,
                     damage_=4, energy_=5, sound_effect_=BEAM_FUSION_MED,
                     volume_=SOUND_LEVEL, shooting_=False, reloading_=2, elapsed_=0, super_=None,
                     super_warm_up_=None, animation_=SPACESHIP_SPRITE)

LZRFX001 = Weapons(name_='GREEN_LAZER_SINGLE', sprite_=LAZER_FX[4], range_=SCREENRECT.h // 2, velocity_=-33,
                   damage_=65, energy_=12, sound_effect_=TX0_FIRE1, volume_=SOUND_LEVEL,
                   shooting_=False, reloading_=0.2, elapsed_=0, super_=None, super_warm_up_=None,
                   animation_=SPACESHIP_SPRITE, level_up_=None)

LASER_BEAM_BLUE = Weapons(name_='LASER_BEAM_BLUE', sprite_=DEATHRAY_SPRITE_BLUE, range_=SCREENRECT.h,
                          velocity_=None, damage_=80, energy_=15, sound_effect_=BEAM_FUSION_MED, volume_=SOUND_LEVEL,
                          shooting_=False, reloading_=5, elapsed_=0, super_=None, super_warm_up_=None,
                          animation_=None, level_up_=None)


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

    def __init__(self, name: str, fov: int, rotation_speed: int, max_rotation: int, sprite: pygame.Surface,
                 operational_status: bool, mounted_weapon: Weapons, laser_orientation: int,
                 overheating: bool, rest_angle: int, aim_assist: bool, target_sprite: pygame.Surface, strategy: int,
                 fallback_strategy: int):
        """

        :param name: Name of the turret Galatine, Secace or Almace.
                     3 different types with different characteristics
        :param fov: Field of view. Target outside the FOV will be ignore.
        :param rotation_speed: Turret angular speed
        :param max_rotation: : Tolerance for target angle (Target in angle +/- Tolerance is considered locked)
        :param sprite: Single sprite or animation
        :param operational_status: Turret Operational status
        :param mounted_weapon: Weapon system mounted with the Turret
        :param laser_oriantiation: laser facing 0 degrees
        :param overheating: self explanatory
        :param rest_angle: Turret facing rest_angle (degrees) direction when initialize or resting position
        :param aim_assist: Aiming assisted with pre-calculation to give a nothch to the laser to get a direct hit.
        :param target_sprite: Target sprite (aim)
        :param strategy: Turret strategy. The strategy define what the turret will aim and shoot first.
                         If no target exist in the present strategy mode, the turret strategy will fall back
                        to the fallback_strategy mode below.
        :param fallback_strategy: Turret fallback method, emergency strategy mode.
                        e.g strategy mode selected -> nearest colliders (but no targets are in collision course,
                        the mode will fall back to fallback_strategy mode (less specific)
        """
        assert isinstance(name, str), 'Expecting string for argument name got %s ' % type(name)
        assert isinstance(fov, int), 'Expecting int for argument fov got %s ' % type(fov)
        assert isinstance(rotation_speed, int), \
            'Expecting int for argument rotation_speed got %s ' % type(rotation_speed)
        assert isinstance(max_rotation, int), 'Expecting int for argument max_rotation got %s ' % type(max_rotation)
        assert isinstance(sprite, pygame.Surface), \
            'Expecting pygame.Surface for argument sprite got %s ' % type(sprite)
        assert isinstance(operational_status, bool), \
            'Expecting bool for argument operational_status got %s ' % type(operational_status)
        assert isinstance(mounted_weapon, Weapons), \
            'Expecting Weapons for argument mounted_weapon got %s ' % type(mounted_weapon)
        assert isinstance(laser_orientation, int), \
            'Expecting int for argument laser_orientation got %s ' % type(laser_orientation)
        assert isinstance(overheating, bool), 'Expecting bool for argument overheating got %s ' % type(overheating)
        assert isinstance(rest_angle, int), 'Expecting int for argument rest_angle got %s ' % type(rest_angle)
        assert isinstance(aim_assist, bool), 'Expecting bool for argument aim_assist got %s ' % type(aim_assist)
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


TURRET_GALATINE = TurretClass(name='Galatine', fov=270, rotation_speed=4, max_rotation=10, sprite=TURRET_SPRITE,
                              operational_status=True, mounted_weapon=LZRFX001, laser_orientation=0, overheating=False,
                              rest_angle=270, aim_assist=True, target_sprite=TURRET_TARGET_SPRITE,
                              strategy=0, fallback_strategy=9)  # strategy NEAR_COLLISION, fallback to LOW_DEADLINESS
TURRET_SECACE = TurretClass(name='Secace', fov=315, rotation_speed=6, max_rotation=10, sprite=TURRET_SPRITE,
                            operational_status=True, mounted_weapon=LZRFX001, laser_orientation=0, overheating=False,
                            rest_angle=270, aim_assist=False, target_sprite=TURRET_TARGET_SPRITE,
                            strategy=0, fallback_strategy=2)  # strategy NEAR_COLLISION, fallback to LOW_DEADLINESS
TURRET_ALMACE = TurretClass(name='Almace', fov=360, rotation_speed=4, max_rotation=10, sprite=TURRET_SPRITE,
                            operational_status=True, mounted_weapon=TESLA_BLUE, laser_orientation=0, overheating=False,
                            rest_angle=270, aim_assist=False, target_sprite=TURRET_TARGET_SPRITE, strategy=0,
                            fallback_strategy=2)  # strategy NEAR_COLLISION, fallback to LOW_DEADLINESS


class ShieldClass:
    def __init__(self, name: str, energy: float, max_energy: float, operational_status: bool,
                 shield_up: bool, overloaded: bool, disrupted: bool, sprite: pygame.Surface,
                 recharge_speed: float, shield_sound, shield_sound_down, shield_sound_impact,
                 shield_glow_sprite, impact_sprite, disruption_time=5000):

        assert isinstance(name, str), 'Expecting string for argument name got %s ' % type(name)
        assert isinstance(energy, float), 'Expecting float for argument energy got %s ' % type(energy)
        assert isinstance(max_energy, float), 'Expecting float for argument max_energy got %s ' % type(max_energy)
        assert isinstance(operational_status, bool), \
            'Expecting bool for argument operational_status got %s ' % type(operational_status)
        assert isinstance(shield_up, bool), 'Expecting bool for argument shield_up got %s ' % type(shield_up)
        assert isinstance(overloaded, bool), 'Expecting bool for argument overloaded got %s ' % type(overloaded)
        assert isinstance(disrupted, bool), 'Expecting bool for argument disrupted got %s ' % type(disrupted)
        assert isinstance(sprite, (pygame.Surface, list)), \
            'Expecting pygame.surface or list for argument sprite got %s ' % type(sprite)
        assert isinstance(recharge_speed, float), \
            'Expecting float for argument recharge_speed got %s ' % type(recharge_speed)

        assert isinstance(shield_sound, pygame.mixer.Sound), \
            'Expecting pygame.mixer.Sound for argument shield_sound got %s ' % type(shield_sound)
        assert isinstance(shield_sound_down, pygame.mixer.Sound), \
            'Expecting pygame.mixer.Sound for argument shield_sound_down got %s ' % type(shield_sound_down)
        assert isinstance(shield_sound_impact, pygame.mixer.Sound), \
            'Expecting pygame.mixer.Sound for argument shield_sound_impact got %s ' % type(shield_sound_impact)
        assert isinstance(shield_glow_sprite, list), \
            'Expecting list for argument shield_glow_sprite got %s ' % type(shield_glow_sprite)
        assert isinstance(disruption_time, int), \
            'Expecting list for argument disruption_time got %s ' % type(disruption_time)

        self.name = name
        self.max_energy = max_energy
        # s.m.i (shield meter indicator)
        self.smi = SHIELD_METER_INDICATOR
        # s.b.i (shield border indicator)
        self.sbi = SHIELD_BORDER_INDICATOR
        # self.ratio = self.ratio_calculator()
        self.energy = energy
        self.operational_status = operational_status
        self.shield_up = shield_up
        self.overloaded = overloaded
        self.disrupted = disrupted
        self.sprite = sprite
        self.__energy = energy
        self.recharge_speed = recharge_speed
        self.shield_sound = shield_sound
        self.shield_sound_down = shield_sound_down
        self.shield_sound_impact = shield_sound_impact
        self.shield_glow_sprite = shield_glow_sprite
        self.impact_sprite = impact_sprite
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
        return self.__energy

    def ratio_calculator(self):
        assert self.max_energy > 0, 'max_energy should not be equal to zero'
        return self.energy * self.smi.get_width() / self.max_energy


# Player shield names
# Aegis, Ancile, Achilles
# todo create different sprite for shield Ancile and Aegis
SHIELD_ACHILLES = ShieldClass(name='Achilles', energy=2000.0, max_energy=2000.0, operational_status=True,
                              shield_up=False, overloaded=False, disrupted=False, sprite=ROUND_SHIELD_1,
                              recharge_speed=0.2,
                              shield_sound=FORCE_FIELD_SOUND, shield_sound_down=SHIELD_DOWN_SOUND,
                              shield_sound_impact=SHIELD_IMPACT_SOUND, shield_glow_sprite=SHIELD_GLOW,
                              impact_sprite=SHIELD_HEATGLOW)

SHIELD_ANCILE = ShieldClass(name='Ancile', energy=4000.0, max_energy=4000.0, operational_status=True,
                            shield_up=False, overloaded=False, disrupted=False, sprite=ROUND_SHIELD_1,
                            recharge_speed=0.4, shield_sound=FORCE_FIELD_SOUND, shield_sound_down=SHIELD_DOWN_SOUND,
                            shield_sound_impact=SHIELD_IMPACT_SOUND, shield_glow_sprite=SHIELD_GLOW,
                            impact_sprite=SHIELD_HEATGLOW)

SHIELD_AEGIS = ShieldClass(name='Aegis', energy=10000.0, max_energy=10000.0, operational_status=True,
                           shield_up=False, overloaded=False, disrupted=False, sprite=ROUND_SHIELD_1,
                           recharge_speed=0.8, shield_sound=FORCE_FIELD_SOUND, shield_sound_down=SHIELD_DOWN_SOUND,
                           shield_sound_impact=SHIELD_IMPACT_SOUND, shield_glow_sprite=SHIELD_GLOW,
                           impact_sprite=SHIELD_HEATGLOW)

DEFAULT_WEAPON = GREEN_PHOTON_3

CURRENT_WEAPON = GREEN_PHOTON_3

CURRENT_TURRET = TURRET_GALATINE

CURRENT_SHIELD = SHIELD_ACHILLES
