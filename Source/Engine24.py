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

try:
    from pygame import *
except ImportError as error:
    print('\n[-] Cannot import module pygame.')
    print('\n[-] Error description : %s ' % str(error))
else:
    print('pygame version : %s ' % str(get_sdl_version()))

try:
    import pygame.freetype as freetype
except ImportError as error:
    print('\n[-] Cannot import module freetype.')
    print('\n[-] Error description : %s ' % str(error))
else:
    print('Freetype version : %s ' % str(freetype.get_version()))

import time as time_time

import threading
import multiprocessing

from Weapons import *
from Constants import *
from random import choice, randrange
# from surface import blink_surface, blend_texture, add_transparency_all, add_transparency, \
#    blend_texture_24bit, blend_texture_add, sub_transparency, sub_transparency_all
from surface_cython import blend_texture, blend_texture_alpha, blink_surface, \
    add_transparency_all, blend_texture_24bit
from surface import red_mask_alpha
from math import ceil, atan2
from Asteroids import Asteroids, asteroids_list
from Anomaly import anomalies_list, Anomaly

import unittest
import numpy
from numpy import linspace, array, arange, repeat, newaxis

from Sprites import EXPLOSION10, SPACESHIP_SPRITE, LEVEL_UP_MSG, ENERGY_BOOSTER1, HALO_SPRITE8, PHOTON_PARTICLE_2, \
    BURST_UP_RED, MISSILE_EXPLOSION, LEVEL_UP_5, PHOTON_PARTICLE_1, PHOTON_PARTICLE_6, \
    PHOTON_PARTICLE_5, PHOTON_PARTICLE_3, PHOTON_PARTICLE_4, PHOTON_PARTICLE_7, COSMIC_DUST1, \
    ENERGY_HUD, BLAST1, SUPER_EXPLOSION, LIFE_HUD, MISSILE_TRAIL, HORNET_MISSILE_SPRITE, \
    NUKE_BOMB_SPRITE, NUKE_EXOLOSION, HALO_SPRITE9, HALO_SPRITE11, HALO_SPRITE12, HALO_SPRITE13, \
    HALO_SPRITE14, MISSILE_TARGET_SPRITE, NUKE_BONUS, GEM_SPRITES, \
    EXHAUST1_SPRITE, TURRET_SPRITE, BEAM_FIELD, ROUND_SHIELD_2, ROUND_SHIELD_1, ROUND_SHIELD_IMPACT, \
    FIRE, TESLA_IMPACT, SHIELD_HEATGLOW, SHIELD_ELECTRIC_ARC, load_per_pixel, COLLECTIBLES_AMMO, MUZZLE_FLASH, \
    SHIELD_GLOW, BRIGHT_LIGHT_BLUE, BRIGHT_LIGHT_RED, NUKE_BOMB_INVENTORY, MISSILE_INVENTORY, SPACESHIP_SPRITE_LAVA, \
    SPACESHIP_EXPLODE, DAMAGE_CONTROL_128x128, DAMAGE_CONTROL_64x64, \
    DAMAGE_LEFT_WING_YELLOW, DAMAGE_LEFT_WING_ORANGE, DAMAGE_LEFT_WING_RED, \
    DAMAGE_RIGHT_WING_YELLOW, DAMAGE_RIGHT_WING_ORANGE, DAMAGE_RIGHT_WING_RED, \
    DAMAGE_NOSE_YELLOW, DAMAGE_NOSE_ORANGE, DAMAGE_NOSE_RED, DAMAGE_NONE, DAMAGE_ALL, \
    DAMAGE_RIGHT_ENGINE_RED, DAMAGE_RIGHT_ENGINE_ORANGE, DAMAGE_RIGHT_ENGINE_YELLOW, \
    DAMAGE_LEFT_ENGINE_RED, DAMAGE_LEFT_ENGINE_ORANGE, DAMAGE_LEFT_ENGINE_YELLOW, \
    NANO_BOTS_CLOUD, SHIELD_DISTUPTION_1, BLOOD_SURFACE, DEATHRAY_SHAFT

import os
from Sounds import MISSILE_EXPLOSION_SOUND, EXPLOSION_SOUND_1, LEVEL_UP, IMPACT2, IMPACT1, ENERGY_SUPPLY, ENGINE_ON, \
    MUSIC_PLAYLIST, DENIED_SOUND, HEART_SOUND, BOMB_CATCH_SOUND, CRYSTAL_SOUND, ALARM_DESTRUCTION, \
    FORCE_FIELD_SOUND, SHIELD_IMPACT_SOUND, SHIELD_DOWN_SOUND, AMMO_RELOADING_SOUND, SUPER_EXPLOSION_SOUND, \
    NANOBOTS_SOUND

from Enemy_ import EnemyClass, EnemyWeapons, Raptor

# pyinstaller --onefile test.py --hidden-import scipy._lib.messagestream --paths
# "C:\Users\yoyob\AppData\Local\Programs\Python\Python36\Lib\site-packages\scipy\extra-dll"
import scipy
from scipy.special.basic import comb

from Waves import LEVEL1_WAVE1, LEVEL1_WAVE0, LEVEL1_WAVE2

# *** ------------ cython modules ---------------------
from ParticleFx import ParticleFx
from Shot import Shot
from Apparent_damage import apparent_damage
from CosmicDust import CosmicDust
from HorizontalBar import HorizontalBar
import ElasticCollision as Physics
from IA_cython import *
from MissileParticleFx import MissileParticleFx
from MultipleShots import *
from SoundControl_cython import SoundControl
from DamageDisplay_cython import DamageDisplay
from HomingMissile_cython import HomingMissile
from SuperLaser_cython import SuperLaser

# todo test xrange to check if it is faster than range
# from scipy._lib.six import xrange


class ERROR(BaseException):
    pass


# Blending color
def lerp(value1: int, value2: int, factor: float) -> int:
    """
    Basic lerping method to lerp from one color to another.
    :param value1: int [0, 255], source color
    :param value2: int [0, 255], destination color
    :param factor: float [0, 1], interval(s) correspond to 1/n
    :return: int [0, 255]

    >>>lerp(255, 20, 1/3)
    177
    >>>lerp(10, 255, 1/3)
    98
    """

    assert isinstance(value1, int) and isinstance(value2, int), \
        '\n[-] Error : Expecting integer only, ' \
        'got: value1:%s, value2:%s, factor:%s' % (type(value1), type(value2))
    assert isinstance(factor, float), 'Expecting a float for argument factor, got %s ' % type(factor)
    value1 = numpy.clip(value1, 0, 255)
    value2 = numpy.clip(value2, 0, 255)
    factor = numpy.clip(factor, 0, 1)

    return round(value1 + (value2 - value1) * factor)


# Blending color same than above but different approach
def lerp_(vector1: pygame.math.Vector3, vector2: pygame.math.Vector3, factor: float) -> pygame.math.Vector3:
    """
    :param vector1: math.Vector3 class.  a color can be represented by a vector whose magnitude is proportional
                    to the light level (value) and whose orientation in space is related to the color tone itself.
                    Original RGB color values
    :param vector2: math.Vector3 class, RGB colors to lerp to.
    :param factor:  float representing the number of intervals
    :return:        math.Vector3 class. progressive linear approximation of a color (transitional color)
                    represented with a 3D vector RGB.

    >>> source = pygame.math.Vector3(255, 255, 255)
    >>> destination = pygame.math.Vector3(20, 20, 20)
    >>> lerp_(source, destination, 1/3)
    <Vector3(176.667, 176.667, 176.667)>

    """
    assert issubclass(pygame.math.Vector3, type(vector1)) and issubclass(pygame.math.Vector3, type(vector2)), \
        '\n[-] Error: Expecting math.vector3 got: Vector1:%s, Vector2:%s ' % (type(vector1), type(vector2))
    assert isinstance(factor, float), '\n[-] Error: Expecting a float, got %s ' % type(factor)
    vector1.x = numpy.clip(vector1.x, 0, 255)
    vector1.y = numpy.clip(vector1.y, 0, 255)
    vector1.z = numpy.clip(vector1.z, 0, 1)
    return vector1.lerp(vector2, factor)


class Point:

    def __init__(self, lifetime: list, spawn: list):
        """
        Class Point regroup important data for the particle class
        :param lifetime: List, Lifetime of a particle, time to live etc (in ms)
        :param spawn:    List, Time when the particle start to be display (delay in ms)
        """
        # assert isinstance(lifetime, list) and isinstance(spawn, list), \
        #    '\n[-] Error: Expecting List only, got: lifetime:%s, spawn:%s ' % (type(lifetime), type(spawn))

        # Unique id for the particle
        # self.name = id(self)
        self.lifetime = uniform(lifetime[0], lifetime[1])
        self.spawn = uniform(spawn[0], spawn[1])
        self.vector = pygame.math.Vector2()  # Vector 2D for the particle coordinates
        self.set_ = False
        # get a timestamp when initialised
        self.start = time_time.time()


class Player(pygame.sprite.Sprite):
    gun_offset = 0
    SPACESHIP_STATUS = None
    super_ready = False
    super_started = False
    images = []
    containers = None

    # Player constructor
    def __init__(self, timing_, layer_=-1):
        pygame.sprite.Sprite.__init__(self, self.containers)
        # assert isinstance(self.images, (pygame.Surface, list)), \
        #    'Expecting pygame.Surface or list for argument self.images, got: %s ' % type(self.images)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_:
                All.change_layer(self, layer_)

        self.image = Player.images[0].copy() if isinstance(Player.images, list) else Player.images.copy()

        self.rect = self.image.get_rect(midbottom=SCREENRECT.midbottom)
        # aircraft position
        self.position = pygame.math.Vector2()
        # direction vector
        self.vector = pygame.math.Vector2()
        self.index = 0
        # time constant
        self.dt = 0
        self.timing = timing_

    def standby(self):
        # vector direction is null
        self.vector.x, self.vector.y = 0, 0

    def move(self):
        # Keep the ship into the screen
        self.rect = self.rect.clamp(SCREENRECT)

        # track the previous position
        # used for the direction vector calculation
        old_position = self.position
        if DIRECTIONS != (0, 0):
            self.rect.move_ip(DIRECTIONS * SHIP_SPECS.speed_x * SPEED_FACTOR)
        else:
            if JOYSTICK.availability:
                self.rect.move_ip(JOYSTICK_AXIS_1 * SHIP_SPECS.speed_x * SPEED_FACTOR)

        # Calculate the new vector direction according to
        # the latest joystick/ keyboard input
        self.vector = pygame.math.Vector2(self.rect.center) - old_position

    def get_animation_index(self):
        return self.index

    def gun_position(self):
        pos = self.gun_offset + self.rect.centerx
        return pos, self.rect.top

    def location(self):
        return self.rect

    def center(self):
        return self.rect.center

    @staticmethod
    def nuke():
        if SHIP_SPECS.nukes > 0 and player.alive():

            # Check if the missile is reading (reloading time over)
            if not NUCLEAR_MISSILE.weapon_reloading_std():
                # check if the previous sprite animation is complete
                if not HomingMissile.is_nuke:
                    # Bomb release sound effect
                    SC_spaceship.play(sound_=NUCLEAR_MISSILE.sound_effect, loop_=False, priority_=2,
                                      volume_=NUCLEAR_MISSILE.volume, fade_out_ms=0, panning_=False,
                                      name_='BOMB_RELEASE', x_=0)  # x = 0 not using the panning mode

                    # Create a dummy target 400 pixels ahead of the spaceship
                    dummy_sprite = pygame.sprite.Sprite()
                    dummy_sprite.rect = player.rect.copy()
                    dummy_sprite.rect.center = (player.center()[0], player.center()[1] - 400)

                    nuke_aiming_point.add(dummy_sprite)
                    dummy_sprite.dummy = True

                    # display a circle where the bomb is aiming
                    GenericAnimation.images = MISSILE_TARGET_SPRITE
                    GenericAnimation(object_=dummy_sprite.rect, ratio_=1,
                                     timing_=15, offset_=dummy_sprite.rect,
                                     event_name_='TARGET', loop_=False)

                    # Missile launched
                    HomingMissile.images = NUKE_BOMB_SPRITE
                    shots.add(
                        HomingMissile(target_=dummy_sprite.rect, weapon_=NUCLEAR_MISSILE,
                                      time_passed_seconds=TIME_PASSED_SECONDS,
                                      All=All, enemy_group=GROUP_UNION, player=player,
                                      offset_=None, nuke_=True, timing_=33))
                    # shots.add(HomingMissile(target_=dummy_sprite.rect, weapon_=NUCLEAR_MISSILE,
                    #                        offset_=None, nuke_=True, timing_=33))
                    NUCLEAR_MISSILE.shooting = True
                    NUCLEAR_MISSILE.elapsed = time_time.time()
                    SHIP_SPECS.nukes -= 1

        else:
            if player.alive():
                # deny sound when no more nuke available
                if not SC_spaceship.get_identical_sounds(DENIED_SOUND):
                    SC_spaceship.play(sound_=DENIED_SOUND, loop_=False, priority_=0,
                                      volume_=SOUND_LEVEL, fade_out_ms=0, panning_=False,
                                      name_='DENIED', x_=0,
                                      object_id_=id(DENIED_SOUND))  # x = 0 not using the panning mode

    @staticmethod
    def missiles():

        global PREVIOUS_TARGET

        if SHIP_SPECS.missiles > 0:

            if not STINGER_MISSILE.weapon_reloading_std():

                # Create a list of entities
                entities = ia.create_entities(GROUP_UNION)  # new_group)
                # if list is not null
                if len(ia.inventory) != 0:

                    # Important!
                    # if sorting enemies by distance, do not forget
                    # to create a new instance ia before
                    # sorting the data e.g:
                    # ia = Threat(player.rect)
                    # otherwise the instance will calculate distances between
                    # player and enemies from a previous location.
                    # mode = ia.sort_by_low_deadliness(entities)
                    mode = ia.sort_by_high_deadliness(entities)

                    t0, t1 = None, None

                    # Select a target for each missile (x2)
                    # if only one target is available, assign
                    # same target for both missiles.
                    # Only object contains by SCREENRECT are into the list
                    if len(mode) > 2:
                        t0, t1 = mode[0][1][0], mode[1][1][0]
                    elif len(mode) == 1:
                        t0, t1 = mode[0][1][0], mode[0][1][0]

                    # Checking if the previous targets have been destroyed.
                    # if not, choose the previous target all over again.
                    if PREVIOUS_TARGET[0] and hasattr(PREVIOUS_TARGET[0], 'alive'):
                        if PREVIOUS_TARGET[0].alive():
                            t0 = PREVIOUS_TARGET[0]

                    if PREVIOUS_TARGET[1] and hasattr(PREVIOUS_TARGET[0], 'alive'):
                        if PREVIOUS_TARGET[1].alive():
                            t1 = PREVIOUS_TARGET[1]

                    if None not in (t0, t1):

                        STINGER_MISSILE.shooting = True
                        # kill all previous sound (missile firing)
                        SC_spaceship.stop_name('MISSILE FLIGHT')
                        # play the missile firing sound
                        SC_spaceship.play(sound_=STINGER_MISSILE.sound_effect, loop_=False, priority_=0,
                                          volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True, name_='MISSILE FLIGHT',
                                          x_=player.center()[0])

                        HomingMissile.images = STINGER_MISSILE_SPRITE

                        if t1.location().centerx > t0.location().centerx:

                            shots.add(HomingMissile(target_=t1, weapon_=STINGER_MISSILE,
                                                    time_passed_seconds=TIME_PASSED_SECONDS,
                                                    All=All, enemy_group=GROUP_UNION,
                                                    player=player, offset_=player.location().midright,
                                                    nuke_=False, timing_=33))
                            shots.add(HomingMissile(target_=t0, weapon_=STINGER_MISSILE,
                                                    time_passed_seconds=TIME_PASSED_SECONDS,
                                                    All=All, enemy_group=GROUP_UNION, player=player,
                                                    offset_=player.location().midleft,
                                                    nuke_=False, timing_=33))

                            # shots.add(HomingMissile(target_=t1, weapon_=STINGER_MISSILE,
                            # offset_=player.location().midright, nuke_=False, timing_=33))
                            # shots.add(HomingMissile(target_=t0, weapon_=STINGER_MISSILE,
                            # offset_=player.location().midleft, nuke_=False, timing_=33))
                            # print('targets :', id(t0), id(t1))
                        else:

                            shots.add(HomingMissile(target_=t0, weapon_=STINGER_MISSILE,
                                                    time_passed_seconds=TIME_PASSED_SECONDS,
                                                    All=All, enemy_group=GROUP_UNION, player=player,
                                                    offset_=player.location().midright,
                                                    nuke_=False, timing_=33))
                            shots.add(HomingMissile(target_=t1, weapon_=STINGER_MISSILE,
                                                    time_passed_seconds=TIME_PASSED_SECONDS,
                                                    All=All, enemy_group=GROUP_UNION, player=player,
                                                    offset_=player.location().midleft,
                                                    nuke_=False, timing_=33))

                            # print('targets :', id(t0), id(t1))
                            # shots.add(HomingMissile(target_=t0, weapon_=STINGER_MISSILE,
                            #                         offset_=player.location().midright,
                            #                         nuke_=False, timing_=33))
                            # shots.add(HomingMissile(target_=t1, weapon_=STINGER_MISSILE,
                            #                         offset_=player.location().midleft,
                            #                         nuke_=False, timing_=33))

                        GenericAnimation.images = MISSILE_TARGET_SPRITE
                        GenericAnimation(object_=t0, ratio_=1,
                                         timing_=33, offset_=None,
                                         event_name_='TARGET', loop_=True)

                        GenericAnimation.images = MISSILE_TARGET_SPRITE
                        GenericAnimation(object_=t1, ratio_=1,
                                         timing_=33, offset_=None,
                                         event_name_='TARGET', loop_=True)

                        STINGER_MISSILE.elapsed = time_time.time()
                        # Remove missiles from the stock
                        SHIP_SPECS.missiles -= 2
                        PREVIOUS_TARGET = [t0, t1]

    @staticmethod
    def super_warmup():
        warmup = CURRENT_WEAPON.get_super_warmup()
        if warmup:
            SC_spaceship.play(sound_=warmup.sound_effect, loop_=False, priority_=0, volume_=warmup.volume,
                              fade_out_ms=round(warmup.sound_effect.get_length() * 900),
                              panning_=True, name_=CURRENT_WEAPON.name, x_=player.gun_position()[0])
        # load the super shot animation
        Player.images = warmup.sprite
        Player.super_started = True

    @staticmethod
    def super_shot():
        # if still reloading exit
        if CURRENT_WEAPON.get_super().shooting or SHIP_SPECS.energy < CURRENT_WEAPON.get_super().energy:
            return

        if not Player.super_started:
            Player.super_warmup()

        if Player.super_ready:
            # stop previous sound if any
            SC_spaceship.stop_name(CURRENT_WEAPON.get_super().name)
            # timestamp for the reloading time
            CURRENT_WEAPON.get_super().elapsed = time_time.time()
            CURRENT_WEAPON.get_super().shooting = True
            Shot.screenrect = SCREENRECT
            Shot(player.gun_position(), CURRENT_WEAPON.get_super(), False, 0,
                 player.gun_position()[1], 33, SC_spaceship, TIME_PASSED_SECONDS, All, -2)
            # remove energy
            SHIP_SPECS.energy -= CURRENT_WEAPON.get_super().energy
            Player.super_ready = False
            Player.images = SPACESHIP_SPRITE
            Player.super_started = False

    def update(self):
        if player.alive():

            # player position saved into a vector position
            self.position.x = self.rect.centerx
            self.position.y = self.rect.centery

            if self.dt > self.timing:

                # Reload the aircraft image every frame
                self.images = Player.images

                if isinstance(self.images, list):
                    self.image = self.images[self.index % len(self.images)]
                    if self.index < len(self.images) - 1:
                        self.index += 1
                    else:
                        Player.super_ready = True
                        self.index = 0
                else:
                    self.image = self.images

                self.dt = 0
                # Recharging energy cells
                SHIP_SPECS.energy += int(100 * (TIME_PASSED_SECONDS / 1000))

                # check if the reloading time is over
                CURRENT_WEAPON.weapon_reloading_std()
                if CURRENT_WEAPON.get_super():
                    CURRENT_WEAPON.weapon_reloading_super()

            self.dt += TIME_PASSED_SECONDS


class TurretShot(pygame.sprite.Sprite):
    images = []

    def __init__(self, target, position: tuple, target_angle: int, timing: int = 20, loop: bool = True):

        pygame.sprite.Sprite.__init__(self, self.containers)

        # Fetch the laser orientation
        self.laser_orientation = CURRENT_TURRET.laser_orientation
        self.images_copy = self.images.copy()
        self.image = self.images_copy[0] if isinstance(self.images_copy, list) else self.images.copy()

        # Rotate the surface during the instantiation.
        if isinstance(self.image, pygame.Surface):
            self.image = self.rotation(self.image, int(target_angle - self.laser_orientation))

        self.rect = self.image.get_rect(center=(position[0] + player.rect.centerx,
                                                position[1] + player.rect.centery))
        self.dt = 0
        self.index = 0
        self.timing = timing
        self.loop = loop
        # projectile start position when turret is firing
        self.proj_position = pygame.math.Vector2()
        self.proj_position.x, self.proj_position.y = position[0] + player.rect.centerx, \
                                                     position[1] + player.rect.centery

        # for compatibility between methods
        self.pos = (self.proj_position.x, self.proj_position.y)

        # self.acceleration_vector is a pygame.math.Vector2
        # angle in degrees
        self.target_angle = int(target_angle)

        # projectile determinant for the acceleration vector
        self.acceleration_vector = TurretShot.vector_determinant_calculator(
            self.target_angle, CURRENT_TURRET.mounted_weapon.velocity.length())

        self.target_id = id(target)
        # target position (centre)
        self.target_centre = target.rect.center
        self.target_speed = target.vector

        # if aim assist, adjusting vector
        # and angle automatically
        if CURRENT_TURRET.aim_assist:
            self.acceleration_vector, self.target_angle = self.auto_aim()
            # self.image has already been rotated before.
            # So we are subtracting (target_angle - self.laser_orientation) to get the right angle
            self.image = self.rotation(self.image, int(self.target_angle - (target_angle - self.laser_orientation)))

        # play the shooting sound
        self.shooting_sound()
        self.muzzle_flash()
        # add the shot to the shots group
        # -----------------------------------------
        self.weapon = CURRENT_TURRET.mounted_weapon
        shots.add(self)
        # -----------------------------------------

    def muzzle_flash(self):
        """ Display a muzzle flash when the turret if firing """
        i = 0
        # Working from the copy
        MUZZLE_FLASH_COPY = MUZZLE_FLASH.copy()
        for surface in MUZZLE_FLASH_COPY:
            # MUZZLE_FLASH_COPY[i] = pygame.transform.rotozoom(surface, self.target_angle - 90, 1)
            MUZZLE_FLASH_COPY[i] = pygame.transform.rotate(surface, self.target_angle - 90)
            i += 1
        Follower.images = MUZZLE_FLASH_COPY
        Follower(offset_=(self.rect.centerx - 1, self.rect.centery + 5), timing_=15, loop_=False)

    def shooting_sound(self):
        # if not SC_spaceship.get_identical_sounds(CURRENT_TURRET.mounted_weapon.sound_effect):
        SC_spaceship.play(sound_=CURRENT_TURRET.mounted_weapon.sound_effect, loop_=False, priority_=0,
                          volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True,
                          name_=CURRENT_TURRET.mounted_weapon.name, x_=self.rect.center[0],
                          object_id_=self.target_id)  # send id

    def stop_shooting_sound(self):
        SC_spaceship.stop_object(self.target_id)

    def auto_aim(self) -> tuple:
        """ Give a little notch to the targeting system in order
            to hit the target with a better accuracy rate        """

        # v2_magnitude = self.target_speed.length()
        distance = self.proj_position.distance_to(self.target_centre)
        # eta calculation = distance / magnitude of projectile (speed vector)
        #  self.acceleration_vector is the projectile speed

        if self.acceleration_vector.length() == 0:
            raise ERROR('\n[-]WARNING - Weapon acceleration vector should not be equal to zero.')
        eta = distance / self.acceleration_vector.length()
        # Calculus of the travel distance since the projectile has been shot
        # This is the projection of the distance
        # target_jump_distance = eta * v2_magnitude
        # target direction angle
        # target_angle = atan2(self.target_speed.y * -1, self.target_speed.x) * RAD_TO_DEG
        # Calculate the new position of the target
        new_v2_position = self.target_speed * eta + pygame.math.Vector2(self.target_centre)
        new_target_angle = -int(atan2(new_v2_position.y - self.proj_position.y,
                                      new_v2_position.x - self.proj_position.x) * RAD_TO_DEG)

        # target angle from the turret center
        new_vector = self.vector_determinant_calculator(new_target_angle,
                                                        self.acceleration_vector.length())
        """
        # debugging only
        print('#--------------------------------------------------------------')
        print('V1 :', self.acceleration_vector, ' V1 angle:', self.target_angle, ' magnitude :', v1_magnitude)
        print('V2 :', self.target_speed, ' V2 angle:', target_angle, ' magnitude :', v2_magnitude)
        print('V1 pos :', self.proj_position, ' V2 pos', self.target_centre)
        print('L :', distance)
        print('ETA :', eta)
        print('Jump :', target_jump_distance)
        print('New position : ', new_v2_position, ' new angle: ', new_target_angle)
        print('new vector: ', new_vector)
        print('old angle: ',self.target_angle, ' new : ', new_target_angle)
        print('----------------------------------------------------------------')
        """
        return new_vector, new_target_angle

    @staticmethod
    def vector_determinant_calculator(angle_: int, vector_magnitude: float) -> pygame.math.Vector2:
        """ Vector determinant calculation for a given angle_ (in degrees) """
        # assert isinstance(angle_, int), 'Expecting int for argument angle_ got %s ' % type(angle_)
        # assert isinstance(vector_magnitude, float), \
        #    'Expecting float for argument vector_magnitude got %s ' % type(vector_magnitude)
        angle_ = angle_ % 360
        return pygame.math.Vector2(COS[angle_] * vector_magnitude, SIN[angle_] * -vector_magnitude)

    @staticmethod
    def rotation(surface_: pygame.Surface, angle_: int):
        """ Rotate the shot sprite """
        # assert isinstance(angle_, int), 'Expecting int for argument angle_ got %s ' % type(angle_)
        # assert isinstance(surface_, pygame.Surface), \
        #    'Expecting pygame.Surface for argument surface_ got %s ' % type(surface_)
        # return pygame.transform.rotozoom(surface_, angle_ % 360, 1)
        return pygame.transform.rotate(surface_, angle_ % 360)

    def quit(self):
        self.stop_shooting_sound()
        self.kill()
        shots.remove(self)

    def update(self):

        if player.alive():

            if self.dt > self.timing:
                # only for dynamic
                if isinstance(self.images_copy, list):
                    self.image = self.rotation(self.images_copy[self.index], self.target_angle)

                    """
                    Single sprite shot (this is useless, self.index = 0).
                    Therefore if planning shots with more than one 
                    sprites then it makes perfect sense. 
                    if self.index > len(self.images_copy) - 1:
                        if self.loop:
                            self.index = 0
                        else:
                            self.kill()
                    """
                self.proj_position += self.acceleration_vector
                self.rect = self.image.get_rect(center=tuple(self.proj_position))

                self.dt = 0
            self.dt += TIME_PASSED_SECONDS

            if not SCREENRECT.contains(self.rect):
                self.kill()
        else:
            self.quit()


class Turret(pygame.sprite.Sprite):
    containers = None
    images = None
    # Defence system enable or disable
    initialised = False
    target_locked = None

    def __init__(self, timing_: int, group_: (pygame.sprite.Group, tuple), weapon_: Weapons):
        # check if the turret is already
        # up and running
        if Turret.initialised:
            return
        pygame.sprite.Sprite.__init__(self, self.containers)
        # assert isinstance(self.initialised, bool), \
        #    'Expecting bool for instance variable initialised, got %s ' % type(self.initialised)
        # assert isinstance(self.images, (pygame.Surface, list)), \
        #    'Expecting pygame surface or list for argument images, got %s ' % type(self.images)
        # assert isinstance(timing_, int), \
        #    'Expecting int for argument timing_, got %s ' % type(timing_)
        # assert isinstance(group_, (pygame.sprite.Group, tuple)), \
        #    'Expecting pygame.sprite.Group or tuple for argument group_, got %s ' % type(group_)
        # assert isinstance(weapon_, Weapons), \
        #    'Expecting Weapons class for argument weapon_, got %s ' % type(weapon_)

        self.images_copy = self.images.copy()
        self.image = self.images_copy if isinstance(self.images_copy, pygame.Surface) \
            else self.images_copy[0]
        self.rect = self.image.get_rect(
            center=(player.location().center[0],
                    player.location().center[1] + 5))
        # turret pointing down when initialised -270 degres
        self.turret_angle = CURRENT_TURRET.rest_angle
        self.rotation_step = CURRENT_TURRET.rotation_speed
        self.max_rotation = CURRENT_TURRET.max_rotation
        # turret in lock position
        self.lock = False
        self.dt = 0
        self.timing = timing_
        self.group = group_
        self.weapon = weapon_
        self.vector_target = pygame.math.Vector2()
        Turret.initialised = True
        self.timestamp = 0
        # pre load the sprite for class TurretShot
        TurretShot.images = CURRENT_TURRET.mounted_weapon.sprite
        self.highlight_target = None
        self.target_group = pygame.sprite.GroupSingle()

    @staticmethod
    def rot_center(image_: pygame.Surface, angle_: (int, float), rect_) -> (pygame.Surface, pygame.Rect):
        """rotate an image while keeping its center and size (only for symmetric surface)"""
        # assert isinstance(image_, pygame.Surface), \
        #    ' Expecting pygame surface for argument image_, got %s ' % type(image_)
        # assert isinstance(angle_, (int, float)), \
        #    'Expecting int or float for argument angle_ got %s ' % type(angle_)
        # new_image = pygame.transform.rotozoom(image_, angle_, 1)
        new_image = pygame.transform.rotate(image_, angle_)
        return new_image, new_image.get_rect(center=rect_.center)

    @staticmethod
    def target(group_: pygame.sprite.Group, strategy: str) -> list:
        """ get the nearest target from the player location """
        # assert isinstance(group_, pygame.sprite.Group), \
        #    'Expecting pygame group_ for argument group, got %s ' % type(group_)
        # assert isinstance(strategy, str), \
        #    'Expecting string for argument strategy, got %s ' % type(strategy)
        objects = Threat(player.rect).create_entities(group_)
        return eval(TURRET_STRATEGY[strategy])

    @staticmethod
    def gun_position(angle_: int) -> tuple:
        """ calculate the position of the turret extremity."""
        # assert isinstance(angle_, int), 'Expecting int for argument angle_ got %s ' % type(angle_)
        return int(COS[angle_] * CURRENT_TURRET.sprite.get_width() // 2), \
               int(SIN[angle_] * -CURRENT_TURRET.sprite.get_height() // 2)

    def reloading(self):
        """ return True (reloading) or False ready to shoot
            Each weapon type have a specific reloading time, check
            Weapons.py to adjust the shooting rate for each weapon class.
            PS we are not using the timing method of the Weapons class weapon_reloading_std,
            but using the below code instead (faster).
        """
        if time_time.time() - self.timestamp >= CURRENT_TURRET.mounted_weapon.reloading:
            # if self.timer > CURRENT_TURRET.mounted_weapon.reloading * 1000:
            self.timestamp = 0
            return False
        else:
            # reloading, not ready to shoot
            return True

    def shooting(self):
        self.timestamp = time_time.time()

    @staticmethod
    def target_vector_normalize(dx, dy):
        return pygame.math.Vector2(dx, dy).normalize()

    def update(self):

        if player.alive():

            if Turret.initialised:

                if self.dt > self.timing:

                    if isinstance(self.group, tuple):
                        new_group = pygame.sprite.Group()
                        for g in self.group:
                            new_group.add(g)
                    else:
                        new_group = self.group

                    high_priority = Turret.target(group_=new_group, strategy=CURRENT_TURRET.strategy)

                    if high_priority is None:
                        # load previous target
                        close_target = Turret.target_locked
                    else:
                        # priority target first
                        close_target = high_priority

                    # check if close_target is empty
                    # is any target available?
                    if close_target:

                        close_target = close_target[1][0]
                        self.target_group.add(close_target)

                        if new_group.has(close_target) and close_target.alive():

                            if not hasattr(close_target, 'rect'):
                                return

                            # debugging only
                            # pygame.draw.line(screen, (255, 255, 0),
                            #                  self.rect.center, close_target.rect.center, 1)

                            dx = close_target.rect.centerx - self.rect.centerx
                            dy = close_target.rect.centery - self.rect.centery
                            rotation = atan2(dy, dx) * RAD_TO_DEG

                            if rotation > 0:
                                rotation = rotation - 360

                            # target angle from the turret center
                            rotation = -rotation

                            # calculus angular distance (between turret and target),
                            # turret rotating to the left.
                            left = (self.turret_angle - rotation) % 360
                            # calculus angular distance (between turret and target),
                            # turret rotating to the right
                            right = 360 - left

                            # if the turret is in shooting position (turret pointing
                            # toward the target, then lock is set to true to
                            # avoid erratic changes.
                            # lock = True no more adjustment

                            # Turret lock-on
                            if self.lock:
                                # find the shortest angular distance
                                self.rotation_step = -self.max_rotation if left < right else self.max_rotation
                                self.lock = False

                            # Turret is rotating until getting a lock
                            if not (rotation - self.max_rotation < self.turret_angle < rotation + self.max_rotation):
                                # continue to rotate
                                self.turret_angle += self.rotation_step
                                # not locked
                                self.lock = False
                            else:
                                # Turret is locked-on
                                self.lock = True
                                # Turret is now pointing toward the target with an tolerance of +/- self.tolerance
                                if self.weapon.type_ == 'TESLA':
                                    if not TeslaEffect.shooting and \
                                            self.weapon.range > Threat(player.rect) \
                                            .get_point_distance(close_target.rect.center) \
                                            and SHIP_SPECS.energy > self.weapon.energy:

                                        # Previous shot is over?
                                        # Play a sound effect
                                        if not SC_spaceship.get_identical_sounds(self.weapon.sound_effect):
                                            SC_spaceship.play(sound_=self.weapon.sound_effect, loop_=False, priority_=0,
                                                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True,
                                                              name_='TESLA', x_=self.rect.center[0],
                                                              object_id_=id(close_target))  # send id

                                        # TESLA effect
                                        TeslaEffect(30, new_group, close_target, self.weapon)
                                        self.shooting()

                                # Other weapon system here
                                else:
                                    # check if the weapon is reloading, has enough energy and if the target
                                    # is in the range
                                    if self.weapon.range > Threat\
                                                (player.rect).get_point_distance(close_target.rect.center):
                                        if not self.reloading() and SHIP_SPECS.energy > self.weapon.energy:
                                            TurretShot(close_target, Turret.gun_position(int(rotation)), rotation)
                                            self.shooting()

                                        self.highlight_target = \
                                            HighlightTarget(target_=close_target, timing_=15)

                            self.turret_angle = self.turret_angle % 360

                            # debugging
                            # loc = Turret.gun_position(int(rotation))

                            # draw the turret
                            self.image, self.rect = Turret.rot_center(self.images_copy
                                                                      if isinstance(self.images_copy, pygame.Surface)
                                                                      else self.images_copy[0], self.turret_angle + 90,
                                                                      self.rect)
                        else:
                            close_target = None
                            Turret.target_locked = None

                    else:

                        # No target, select a new one
                        close_target = Turret.target(group_=new_group, strategy=CURRENT_TURRET.strategy)
                        # Still no target available, using the fallback strategy mode (less specific)
                        if close_target is None:
                            close_target = Turret.target(group_=new_group, strategy=CURRENT_TURRET.fallback_strategy)
                        Turret.target_locked = close_target

                        if close_target:
                            if self.weapon.range > Threat \
                                        (player.rect).get_point_distance(close_target[1][0].rect.center):
                                self.highlight_target = HighlightTarget(target_=close_target[1][0], timing_=15)

                    self.dt = 0

                self.dt += TIME_PASSED_SECONDS
                self.rect.center = (player.location().center[0], player.location().center[1] + 5)
        else:
            self.kill()


class Shield(pygame.sprite.Sprite):
    containers = None
    images = None
    impact = False
    shield_up = False

    def __init__(self, player_: Player, loop_: bool = False, timing_: int = 15, event_: str = None):
        pygame.sprite.Sprite.__init__(self, self.containers)
        """
        assert isinstance(self.images, list), \
            'Expecting list for argument self.images got %s ' % type(self.images)
        assert isinstance(player_, Player), \
            'Expecting class player for argument player_ got %s ' % type(player_)
        assert isinstance(loop_, bool), \
            'Expecting bool for argument loop_ got %s ' % type(loop_)
        assert isinstance(timing_, int), \
            'Expecting int for argument timing_ got %s ' % type(timing_)
        assert isinstance(event_, (str, type(None))), \
            'Expecting str or None for argument event_ got %s ' % type(event_)
        """
        # Shield already busy?
        if Shield.impact:
            self.kill()

        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]
        self.rect = self.image.get_rect(center=player.rect.center)
        self.index = 0
        self.loop = loop_
        self.timing = timing_
        self.dt = 0
        self.event = event_
        self._id = id(self)
        self.counter = 0

        # special event for shield collision
        if self.event == 'SHIELD_IMPACT':
            Shield.impact = True

        # Shield up
        elif self.event == 'SHIELD_INIT':
            self.shield_up()

    @staticmethod
    def is_shield_up():
        return Shield.shield_up

    @staticmethod
    def is_shield_operational():
        return CURRENT_SHIELD.operational_status

    @staticmethod
    def is_shield_disrupted():
        return CURRENT_SHIELD.disrupted

    @staticmethod
    def is_shield_overloaded():
        return CURRENT_SHIELD.overloaded

    @staticmethod
    def shield_down(id_sound: int):
        # assert isinstance(id_sound, int), \
        #    'Expecting int for argument id_sound got %s ' % type(id_sound)
        Shield.shield_up = False
        # stop shield sound
        SC_spaceship.stop_object(id_sound)
        # play sound shield down
        if not SC_spaceship.get_identical_sounds(CURRENT_SHIELD.shield_sound_down):
            SC_spaceship.play(sound_=CURRENT_SHIELD.shield_sound_down, loop_=False, priority_=0,
                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=False,
                              name_='FORCE_FIELD', x_=0, object_id_=id(CURRENT_SHIELD.shield_sound_down))
        CURRENT_SHIELD.operational_status = False

    @staticmethod
    def shield_up():
        if player.alive() and CURRENT_SHIELD.energy > 0:
            if not CURRENT_SHIELD.disrupted:
                if not SC_spaceship.get_identical_sounds(CURRENT_SHIELD.shield_sound):
                    SC_spaceship.play(sound_=CURRENT_SHIELD.shield_sound, loop_=True, priority_=0,
                                      volume_=SOUND_LEVEL, fade_out_ms=0, panning_=False,
                                      name_='FORCE_FIELD', x_=0, object_id_=id(CURRENT_SHIELD.shield_sound))
                Shield.shield_up = True

    @classmethod
    def apply_damage(cls, damage_: int):
        """ apply damage to the shield """
        # assert isinstance(damage_, int), 'Expecting int for argument damage_ got %s ' % type(damage_)
        # transfer damage to the shield
        CURRENT_SHIELD.energy -= damage_
        if CURRENT_SHIELD.energy < 1:
            # Shield is down
            cls.shield_down(id(CURRENT_SHIELD.shield_sound_down))

    @classmethod
    def shield_impact(cls, damage_: int):
        """  play a sound effect after collision.
        :param damage_: Damage transfer to the shield
        """
        # assert isinstance(damage_, int), 'Expecting int for argument damage_ got %s ' % type(damage_)
        # assert isinstance(cls, type(Shield)), 'Expecting class Shield got %s ' % type(cls)

        if cls.is_shield_up():
            SC_spaceship.stop_name('SHIELD_IMPACT')
            SC_spaceship.play(sound_=CURRENT_SHIELD.shield_sound_impact, loop_=False, priority_=0,
                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=False,
                              name_='SHIELD_IMPACT', x_=0, object_id_=id(CURRENT_SHIELD.shield_sound_impact))
            cls.apply_damage(damage_)

    @staticmethod
    def heat_glow(rect_: pygame.Rect):
        """ heat glow when an object is colliding on the shield """
        # assert isinstance(rect_, pygame.Rect), \
        #    'Expecting pygame.Rect for argument rect_ got %s ' % type(rect_)
        # display a heatglow on the shield
        Follower.images = SHIELD_HEATGLOW
        Follower(offset_=rect_.center, timing_=15, loop_=False)

    @staticmethod
    def gradient(index_):
        """ create a color gradient for the shield indicator (red to green)"""
        # assert isinstance(index_, int), \
        #    'Expecting int for argument index_ got %s ' % type(index_)
        end_color = (0, 255, 0, 0)
        start_color = (255, 0, 0, 0)
        value = CURRENT_SHIELD.smi.get_width()
        diff_ = (array(end_color[:3]) - array(start_color[:3])) * value / value
        row = arange(value, dtype='float') / value
        row = repeat(row[:, newaxis], [3], 1)
        diff_ = repeat(diff_[newaxis, :], [value], 0)
        row = numpy.add(array(start_color[:3], numpy.float), array((diff_ * row), numpy.float),
                        dtype=numpy.float).astype(dtype=numpy.uint8)
        return row[index_ % value]

    @staticmethod
    def shield_electric_arc(rect_: pygame.Rect, speed_: int = 30):
        """ Create an electric arc inside the shield area """
        """
        assert isinstance(rect_, pygame.Rect), \
            'Expecting pygame.Rect for argument rect_ got %s ' % type(rect_)
        assert isinstance(speed_, int), \
            'Expecting int for argument speed_ got %s ' % type(speed_)
        """
        # display a heatglow on the shield
        i = 0
        # create a copy of SHIELD_ELECTRIC_ARC
        shield_electric_arc_copy = SHIELD_ELECTRIC_ARC.copy()
        angle = randint(0, 360)
        for surface in shield_electric_arc_copy:
            shield_electric_arc_copy[i] = pygame.transform.rotozoom(surface, angle, 0.5)
            i += 1
        Follower.images = shield_electric_arc_copy
        Follower(offset_=rect_.center, timing_=speed_, loop_=False)

    @staticmethod
    def shield_glow(rect_: pygame.Rect, speed_: int = 15):
        """ Create a colored glowing circle inside the shield area """
        """
        assert isinstance(rect_, pygame.Rect), \
            'Expecting pygame.Rect for argument rect_ got %s ' % type(rect_)
        assert isinstance(speed_, int), \
            'Expecting int for argument speed_ got %s ' % type(speed_)
        """
        Follower.images = SHIELD_GLOW
        Follower(offset_=rect_.center, timing_=speed_, loop_=False)

    @staticmethod
    def shield_power_indicator(surface_: pygame.Surface):
        """ display the shield power indicator below the shield sprite.
            This method assume that the shield is up and running (no need to do
            a test << if Shield.shield_up:>> has it is already performed by update() method
        """
        # assert isinstance(surface_, pygame.Surface), \
        #    'Expecting pygame.Surface for argument surface_ got %s ' % type(surface_)

        surface_rect = surface_.get_rect(center=player.rect.center)

        x = (surface_rect.w - CURRENT_SHIELD.sbi.get_width()) // 2

        # display the shield border indicator (sbi)
        surface_.blit(CURRENT_SHIELD.sbi, (x, surface_rect.h - CURRENT_SHIELD.sbi.get_height()))
        # copy of the shield meter indicator
        smi_ = CURRENT_SHIELD.smi
        # no need to display SMI if ratio is null
        if CURRENT_SHIELD.ratio > 0:

            if smi_.get_size() > (1, 1):
                grad = Shield.gradient(int(CURRENT_SHIELD.ratio - 1))
                color_ = pygame.Color(int(grad[0]), int(grad[1]), int(grad[2]))

                if smi_.get_bitsize() == 32:
                    smi_ = blend_texture(smi_, 1, color_)
                elif smi_.get_bitsize() == 24:
                    smi_ = blend_texture_24bit(smi_, 1, color_)
                else:
                    raise ERROR('\n[-]Shield Texture with 8-bit depth color cannot be blended.')

                surface_.blit(smi_, (x + 2, surface_rect.h - CURRENT_SHIELD.sbi.get_height() + 2),
                              (0, 0, int(CURRENT_SHIELD.ratio), smi_.get_height()))

        return surface_

    def quit(self):
        # do not forget to reset
        # the variable before killing the sprite
        Shield.impact = False
        if self.event == 'SHIELD_INIT':
            self.shield_down(id(FORCE_FIELD_SOUND))
        self.kill()

    @staticmethod
    def shield_recharge():
        # Recharge only if the shield is not disrupted or overloaded
        if not (Shield.is_shield_disrupted() or Shield.is_shield_overloaded()):
            CURRENT_SHIELD.energy += CURRENT_SHIELD.recharge_speed

    def update(self, *args):

        if Shield.shield_up:

            if self.dt > self.timing:
                # shield display only if player is alive
                if player.alive():

                    if self.event == 'SHIELD_INIT':
                        self.image = Shield.shield_power_indicator(self.images_copy[self.index])
                    else:
                        self.image = self.images_copy[self.index]

                    self.rect = self.image.get_rect()
                    self.rect.center = player.rect.center

                    # debug
                    # pygame.draw.rect(screen, (255, 0, 0, 0), self.rect, 2)

                    self.index += 1

                    if self.index > len(self.images_copy) - 1:
                        if self.loop:
                            self.index = 0
                        else:
                            self.quit()

                    self.dt = 0
                    # Restore the shield
                    Shield.shield_recharge()

                    if self.counter % randint(150, 300) == 0:
                        # shield_electric_arc and shield_glow are animation tasks that can
                        # be ran into the background (secondary tasks)
                        # group = []
                        # thread1 = threading.Thread(target=Shield.shield_electric_arc(self.rect, speed_=60))
                        # thread2 = threading.Thread(target=Shield.shield_glow(self.rect, speed_=60))
                        # group.append(thread1)
                        # group.append(thread2)
                        # for thread in group:
                        #    thread.start()
                        Shield.shield_electric_arc(self.rect, speed_=60)
                        Shield.shield_glow(self.rect, speed_=60)

                    if self.counter % randint(105, 160) == 0:
                        # threading.Thread(target=Shield.shield_electric_arc(self.rect, speed_=60)).start()
                        Shield.shield_electric_arc(self.rect, speed_=60)
                else:
                    self.quit()

            self.dt += TIME_PASSED_SECONDS
            self.counter += 1

        else:
            self.quit()


class EnemyShield(pygame.sprite.Sprite):
    containers = None
    images = None
    # Impact flag
    impact = False
    # set the shield status
    _shield_up = False

    def __init__(self, object_, loop_: bool = False, timing_: int = 15,
                 event_: str = None, shield_type: (ShieldClass, None) = None):
        """
        Create a shield around the enemy spaceship (the shield type is passed as an argument)
        :param object_: Enemy object to raise the shield.
        :param loop_:  if True, loop the animation otherwise kill the sprite when animation is complete.
        :param timing_: set the animation speed, default 15 fps
        :param event_: Specific event like INIT (special event for initialisation), IMPACT (special event for impact)
        :param shield_type : shield class (See weapon library for more details)
        """

        pygame.sprite.Sprite.__init__(self, self.containers)
        """
        assert isinstance(self.images, (list, pygame.Surface)), \
            'Expecting list or pygame.Surface for argument self.images got %s ' % type(self.images)
        assert isinstance(object_, Enemy), \
            'Expecting class Enemy for argument object_ got %s ' % type(object_)
        assert isinstance(loop_, bool), \
            'Expecting bool for argument loop_ got %s ' % type(loop_)
        assert isinstance(timing_, int), \
            'Expecting int for argument timing_ got %s ' % type(timing_)
        assert isinstance(event_, (str, type(None))), \
            'Expecting str or None for argument event_ got %s ' % type(event_)
        assert isinstance(shield_type, (ShieldClass, type(None))), \
            'Expecting ShieldClass or None for argument shield_type got %s ' % type(shield_type)
        """
        # Enemy spaceship
        # Reference to the Enemy class(sprite).
        self.object_ = object_

        self.images_copy = self.images.copy()
        self.image = self.images_copy[0] if isinstance(self.images_copy, list) else self.images_copy
        self.rect = self.image.get_rect(center=object_.rect.center)
        self.index = 0
        self.loop = loop_
        self.timing = timing_
        self.dt = 0
        self.event = event_
        self._id = id(self)
        self.counter = 0
        self.disruption_timer = 0

        self.shield_type = shield_type

        # special event for shield collision
        if self.event == 'SHIELD_IMPACT':
            self._shield_up = True
            self.impact = True

        # Shield up
        elif self.event == 'SHIELD_INIT':
            self.shield_up()

    def is_shield_up(self):
        # return the shield status
        # True | shield is up or False | shield is down
        return self._shield_up

    def is_shield_operational(self):
        # Return the shield operational status (True|False)
        return self.shield_type.operational_status

    def is_shield_disrupted(self):
        # return True if the shield is disrupted,
        # false otherwise
        return self.shield_type.disrupted

    def is_shield_overloaded(self):
        # return True if the shield is overloaded,
        # False otherwise
        return self.shield_type.overloaded

    def shield_down(self, id_sound: int):
        """ Disable the shield """
        # assert isinstance(id_sound, int), \
        #    'Expecting int for argument id_sound got %s ' % type(id_sound)

        # stop shield sound
        if id_sound is not None:
            SC_spaceship.stop_object(id_sound)

        SC_spaceship.stop_object(id(self.shield_type.shield_sound_down))

        # play sound shield down
        if not SC_spaceship.get_identical_sounds(self.shield_type.shield_sound_down):
            SC_spaceship.play(sound_=self.shield_type.shield_sound_down, loop_=False, priority_=0,
                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=False,
                              name_='SHIELD_DOWN', x_=0, object_id_=id(self.shield_type.shield_sound_down))
        self.shield_type.operational_status = False
        self._shield_up = False

    def shield_up(self):
        """ Try to enable the shield """
        if self.object_.alive() and self.shield_type.energy > 0:
            if not self.shield_type.disrupted:
                SC_spaceship.stop_object(id(NANOBOTS_SOUND)+id(self))
                SC_spaceship.stop_object(id(self.shield_type.shield_sound))
                if not SC_spaceship.get_identical_sounds(self.shield_type.shield_sound):
                    SC_spaceship.play(sound_=self.shield_type.shield_sound, loop_=True, priority_=0,
                                      volume_=SOUND_LEVEL, fade_out_ms=0, panning_=False,
                                      name_='FORCE_FIELD', x_=0, object_id_=id(self.shield_type.shield_sound))

                self._shield_up = True
                self.shield_type.operational_status = True
            else:
                # Shield is still disrupted
                # nothing to do
                pass
        else:
            # shield stays down not enough energy or dead
            pass

    def shield_impact(self, damage_: int, weapon_: Weapons):
        """  Transfer damages to the shield or enemy hull if energy is too low.
            Force the shield to go down when the energy is depleted.
            :param weapon_: Weapon class
            :param damage_: Damage transfer to the shield
        """
        # assert isinstance(damage_, int), \
        #    'Expecting int for argument damage_ got %s ' % type(damage_)
        # assert isinstance(weapon_, Weapons), \
        #    'Expecting class Weapons for argument weapon_ got %s ' % type(weapon_)

        if not self.is_shield_disrupted():
            SC_spaceship.stop_name('SHIELD_IMPACT')
            SC_spaceship.play(sound_=self.shield_type.shield_sound_impact, loop_=False, priority_=0,
                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True,
                              name_='SHIELD_IMPACT', x_=self.rect.centerx,
                              object_id_=id(self.shield_type.shield_sound_impact))

            # Transfer damage to the Enemy aircraft if
            # energy is too low to absorb the shot.
            if damage_ > self.shield_type.energy:
                self.object_.hp -= (damage_ - self.shield_type.energy)
                self.shield_type.energy = 0
                # Force the shield to go down
                self.shield_down(id_sound=id(self.shield_type.shield_sound))

            else:
                # Shield takes all damages
                self.shield_type.energy -= damage_
                if self.shield_type.energy <= 0:
                    # Shield goes down, stop the sound and set the status
                    self.shield_down(id_sound=id(self.shield_type.shield_sound))

    def heat_glow(self, rect_: pygame.Rect):
        """ Heat glow when an object is colliding on the shield """
        # assert isinstance(rect_, pygame.Rect), \
        #    'Expecting pygame.Rect for argument rect_ got %s ' % type(rect_)
        # Conditions alive, is_shield_disrupted are not checks prior entering
        # this block (function access from a different class).
        # Assuming the shield to be alive has is_shield_up condition is met prior the call.
        if not self.is_shield_disrupted():
            # Display a heatglow on the shield.
            Follower.images = self.shield_type.impact_sprite
            Follower(offset_=rect_.center, timing_=15, loop_=False, object_=self.object_)
        else:
            # Shield is disrupted
            # nothing to do
            pass

    def gradient(self, index_):
        """ create a color gradient for the shield indicator (red to green)"""
        # assert isinstance(index_, int), \
        #    'Expecting int for argument index_ got %s ' % type(index_)
        end_color = (0, 255, 0, 0)
        start_color = (255, 0, 0, 0)
        value = self.shield_type.smi.get_width()
        diff_ = (array(end_color[:3]) - array(start_color[:3])) * value / value
        row = arange(value, dtype='float') / value
        row = repeat(row[:, newaxis], [3], 1)
        diff_ = repeat(diff_[newaxis, :], [value], 0)
        row = numpy.add(array(start_color[:3], numpy.float), array((diff_ * row), numpy.float),
                        dtype=numpy.float).astype(dtype=numpy.uint8)
        return row[index_ % value]

    def shield_electric_arc(self, speed_: int = 30):
        """ Create an electric arc inside the shield area """
        # assert isinstance(speed_, int), \
        #    'Expecting int for argument speed_ got %s ' % type(speed_)
        # All conditions (Disruption/shield_up, alive) observed in the main loop.

        i = 0
        # create a copy of SHIELD_ELECTRIC_ARC
        shield_electric_arc_copy = SHIELD_ELECTRIC_ARC.copy()
        angle = randint(0, 360)
        for surface in shield_electric_arc_copy:
            shield_electric_arc_copy[i] = pygame.transform.rotozoom(surface, angle, 0.5)
            i += 1
        Follower.images = shield_electric_arc_copy
        Follower(offset_=self.rect.center, timing_=speed_, loop_=False, object_=self.object_)

    def shield_glow(self, speed_: int = 30):
        """ Create a colored glowing circle inside the shield area """
        # assert isinstance(speed_, int), \
        #    'Expecting int for argument speed_ got %s ' % type(speed_)
        # All conditions (Disruption/shield_up, alive) observed in the main loop.
        Follower.images = self.shield_type.shield_glow_sprite
        Follower(offset_=self.rect.center, timing_=speed_, loop_=False, object_=self.object_)

    def shield_power_indicator(self, surface_: pygame.Surface):
        """ display the shield power indicator below the shield sprite.
            This method assume that the shield is up and running (no need to do
            a test << if self._shield_up:>> has it is already performed by update() method.
        """
        # assert isinstance(surface_, pygame.Surface), \
        #    'Expecting pygame.Surface for argument surface_ got %s ' % type(surface_)

        surface_rect = surface_.get_rect(center=self.object_.rect.center)

        x = (surface_rect.w - self.shield_type.sbi.get_width()) // 2

        # display the shield border indicator (sbi)
        surface_.blit(self.shield_type.sbi, (x, self.shield_type.sbi.get_height()))
        # copy of the shield meter indicator
        smi_ = self.shield_type.smi
        # no need to display SMI if ratio is null
        if self.shield_type.ratio > 0:

            if smi_.get_size() > (1, 1):
                grad = self.gradient(int(self.shield_type.ratio - 1))
                color_ = pygame.Color(int(grad[0]), int(grad[1]), int(grad[2]))

                if smi_.get_bitsize() == 32:
                    smi_ = blend_texture(smi_, 1, color_)
                elif smi_.get_bitsize() == 24:
                    smi_ = blend_texture_24bit(smi_, 1, color_)
                else:
                    raise ERROR('\n[-]Shield Texture with 8-bit depth color cannot be blended.')

                surface_.blit(smi_, (x, self.shield_type.sbi.get_height() + 2),
                              (0, 0, int(self.shield_type.ratio), smi_.get_height()))

        return surface_

    def quit(self):
        # Kill the sprite.
        # Do not forget to reset
        # the variable before killing the sprite.
        self.impact = False
        if self.event == 'SHIELD_INIT':
            self.shield_down(id(self.shield_type.shield_sound_down))

        # stop the sound <shield disrupted>
        SC_spaceship.stop_object(id(NANOBOTS_SOUND) + id(self))
        self.kill()

    def shield_recharge(self):
        # All conditions (Disruption/shield_up, alive) have been observed in the main loop.
        # Recharge the shield only if operational flag is set to True
        # This function is launch from the block (alive, up and not disrupted) only.
        # Check the recharging speed from the Enemy library, variable self.shield
        if self.shield_type.operational_status:
            self.shield_type.energy += self.shield_type.recharge_speed

    def force_shield_disruption(self):
        # Force the shield to be disrupted and assign private variable
        # self._shield_up and operational_status accordingly.
        # This works only if operational status is True

        # Point to the first element
        self.index = 0
        # load the new set of surface
        self.images_copy = SHIELD_DISTUPTION_1.copy()
        self.shield_type.disrupted = True
        # stop the shied up sound and play the shield down sound
        # set self._shield_up and operational_status to False
        self.shield_down(id_sound=id(self.shield_type.shield_sound))
        if not SC_spaceship.get_identical_sounds(NANOBOTS_SOUND):
            SC_spaceship.play(sound_=NANOBOTS_SOUND, loop_=True, priority_=0,
                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True,
                              name_='SHIELD_DISTUPTED', x_=self.rect.centerx,
                              object_id_=id(NANOBOTS_SOUND)+id(self))
        # Start the timer
        self.disruption_timer = time_time.time()

    def disruption_time_over(self) -> bool:
        # Check if the shield's disruption timer is now over.
        # Return True when the shield can be enable again, false otherwise.
        if (time_time.time() - self.disruption_timer) > self.shield_type.disruption_time / 1000:
            self.shield_type.operational_status = True
            self.shield_type.disrupted = False
            self.index = 0
            # load the new set of images (disrupted shield)
            self.images_copy = self.shield_type.sprite.copy()
            # shield can be enable
            return True
        else:
            # Time is not over yet
            return False

    def update(self, *args):

        # shield display only if object is alive
        if self.object_.alive() and self.object_ in enemy_group:

            if self.dt > self.timing:

                if self._shield_up:

                    # check if the shield is disrupted
                    if not self.shield_type.disrupted:

                        # Restore the shield energy
                        # only is shield operational status is True
                        self.shield_recharge()

                        if self.counter % randint(200, 300) == 0:
                            # shield_electric_arc and shield_glow are animation tasks that can
                            # be ran into the background (secondary tasks)
                            # group = []
                            # thread1 = threading.Thread(target=self.shield_electric_arc(speed_=30))
                            # thread2 = threading.Thread(target=self.shield_electric_arc(speed_=30))
                            # group.append(thread1)
                            # group.append(thread2)
                            # for thread in group:
                            #    thread.start()
                            self.shield_electric_arc(speed_=30)
                            self.shield_glow(speed_=30)

                        if self.counter % randint(100, 150) == 0:
                            # threading.Thread(target=self.shield_electric_arc(speed_=30)).start()
                            self.shield_electric_arc(speed_=30)

                        if self.event == 'SHIELD_INIT':
                            if isinstance(self.images_copy, list):
                                self.image = self.shield_power_indicator(self.images_copy[self.index])
                            else:
                                self.image = self.shield_power_indicator(self.images_copy)
                        else:
                            self.image = self.images_copy[self.index]

                        self.rect = self.image.get_rect()
                        self.rect.center = self.object_.rect.center

                        if isinstance(self.images_copy, list):
                            self.index += 1

                            if self.index > len(self.images_copy) - 1:
                                if self.loop:
                                    self.index = 0
                                else:
                                    self.quit()

                # shield down
                else:

                    if self.shield_type.energy > 0:
                        if isinstance(self.images_copy, list):
                            self.image = self.images_copy[self.index]

                        self.rect = self.image.get_rect()
                        self.rect.center = self.object_.rect.center

                        if isinstance(self.images_copy, list):
                            self.index += 1

                            if self.index > len(self.images_copy) - 1:
                                if self.loop:
                                    self.index = 0
                                else:
                                    self.quit()
                    # energy <0
                    else:
                        self.quit()

                    if self.disruption_time_over():
                        self.shield_up()

            self.dt = 0
            self.dt += TIME_PASSED_SECONDS
            self.counter += 1

        # alive?
        else:
            self.quit()


class Gems(pygame.sprite.Sprite):
    containers = None
    GEM_VALUE = list(range(1, 22))

    def __init__(self, object_, ratio_: (int, float, list), timing_: int = 15, offset_: pygame.Rect = None):

        pygame.sprite.Sprite.__init__(self, self.containers)
        """
        assert isinstance(object_, (Asteroid, Enemy)), \
            'Expecting Asteroid or Enemy class for argument object, got %s ' % type(object_)
        assert isinstance(ratio_, (int, float, list)), 'Expecting int, float or list for argument ratio_' \
                                                       ' got %s ' % type(ratio_)
        assert isinstance(timing_, int), 'Expecting int for argument timing_ got %s ' % type(timing_)
        assert isinstance(offset_, (pygame.Rect, type(None))), \
            'Expecting a Rect or None got %s ' % type(offset_)
        """
        self.object_ = object_
        self.timing = timing_
        self.offset = offset_

        gem_number = randint(0, len(GEM_SPRITES) - 1)
        self.value = self.GEM_VALUE[gem_number]

        self.image = GEM_SPRITES[gem_number]
        self.image_copy = self.image.copy()

        self.ratio = ratio_

        if self.offset is not None:
            # display the sprite at a specific location.
            self.rect = self.image.get_rect(center=self.offset.center)
        else:
            # use object location
            self.rect = self.image.get_rect(center=self.object_.rect.center)

        self.speed = pygame.math.Vector2()
        self.speed.x = 0
        self.speed.y = 7

        self.dt = 0
        self.theta = 0

    def update(self):

        if self.dt > self.timing:

            if SCREENRECT.contains(self.rect):

                self.image = pygame.transform.rotozoom(self.image_copy, self.theta, self.ratio)
                # self.image_copy = blend_texture(self.image_copy, 0.01, self.color)
                self.rect.move_ip(self.speed.x, self.speed.y)
                # Note this method is faster than modulo
                self.theta += 2
                if self.theta > 359:
                    self.theta = 0

                # Adding sprite into the collision group
                COLLISION_GROUP.add(self)
                # inverted logic
                # removing the sprite from the group if the distance is over the collision radius.
                if (pygame.math.Vector2(self.rect.center) - player.position).length() > COLLISION_RADIUS:
                    COLLISION_GROUP.remove(self)
            else:
                self.kill()

            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


class Bonus(pygame.sprite.Sprite):
    images_ = []
    energy = None
    containers = None
    # keep a track of every objects
    inventory = []

    def __new__(cls, object_, ratio_: (int, float, list), timing_: int = 15, offset_: pygame.Rect = None,
                 event_name_: str = None, loop_: bool = True, bonus_type_: str = None, *args, **kwargs):
        # return if an instance already exist.
        if object_ in Bonus.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_, ratio_: (int, float, list), timing_: int = 15, offset_: pygame.Rect = None,
                 event_name_: str = None, loop_: bool = True, bonus_type_: str = None):
        """
        Create a bonus sprite for the player
        :param object_: Destroyed object used for spawning a bonus collectable.
        :param ratio_: Sprite ratio (adjust sprite width and height)
        :param timing_: Animation refreshing rate in ms
        :param offset_: Offset from object location center
        :param event_name_: Event name (control specific event)
        :param loop_: Determines if the animation is looping
        :param bonus_type_: Bonus type e.g Nuke, Energy cell etc
        """

        Bonus.inventory.append(object_)

        pygame.sprite.Sprite.__init__(self, self.containers)
        """
        assert isinstance(object_, (Asteroid, Enemy)), \
            'Expecting Asteroid or Enemy class for argument object, got %s ' % type(object_)
        assert isinstance(ratio_, (int, float, list)), 'Expecting int, float or list for argument ratio_' \
                                                       ' got %s ' % type(ratio_)

        assert isinstance(timing_, int), 'Expecting int for argument timing_ got %s ' % type(timing_)
        assert isinstance(offset_, (pygame.Rect, type(None))), \
            'Expecting pygame.Rect or NoneType for argument offset_ got %s ' % type(offset_)
        assert isinstance(event_name_, (str, type(None))), \
            'Expecting str or NoneType for argument event_name_ got %s ' % type(event_name_)
        assert isinstance(loop_, bool), \
            'Expecting bool for argument loop_ got %s ' % type(loop_)
        assert isinstance(bonus_type_, (str, type(None))), \
            'Expecting a string for argument bonus_type_ got %s ' % type(bonus_type_)
        """

        self.object_ = object_

        self.event_name_ = event_name_
        self.timing = timing_
        self.offset = offset_

        # work from a copy
        self.images_copy = self.images_.copy()
        self.image = self.images_copy[0]

        if isinstance(ratio_, list):
            self.ratio = ratio_
        else:
            self.ratio = [ratio_] * len(self.images_copy)

        if self.offset is not None:
            # display the sprite at a specific location.
            self.rect = self.image.get_rect(center=self.offset.center)
        else:
            # use object location
            self.rect = self.image.get_rect(center=self.object_.rect.center)

        self.speed = pygame.math.Vector2()
        self.speed.x = 0
        self.speed.y = 4

        # bool for infinite loop
        self.loop = loop_

        self._frame = 0
        self.index = 0
        self._energy = self.energy
        self.bonus_type = bonus_type_
        self.object_id = id(object_)
        self.dt = 0

    def kill_sound(self):
        SC_spaceship.stop_object(self.object_id)

    def get_animation_index(self):
        return self.index

    def quit(self):
        try:
            if self.object_ in Bonus.inventory:
                Bonus.inventory.remove(self.object_)
        except (IndexError, ValueError) as _error:
            print('\n[-]Asteroid Error : %s' % _error)
        finally:
            self.kill_sound()
            self.kill()

    def get_energy(self):
        return self._energy

    def update(self):

        if self.dt > self.timing:

            if SCREENRECT.contains(self.rect) and self.alive():

                self.image = self.images_copy[self.index]

                # Resize the sprite if needed (only if ratio is not NULL)
                if self.ratio[self.index] is not NULL:
                    self.image = pygame.transform.scale(self.image,
                                                        (round(self.image.get_width() * self.ratio[self.index]),
                                                         round(self.image.get_height() * self.ratio[self.index])))
                if self.offset is None:
                    self.rect.move_ip(self.speed.x, self.speed.y)

                self.index += 1
                if self.index > len(self.images_copy) - 1:
                    if self.loop:
                        self.index = 0
                    else:
                        self.quit()
            else:
                self.quit()
            self.dt = 0

        self._frame += 1
        self.dt += TIME_PASSED_SECONDS


class HighlightTarget(pygame.sprite.Sprite):
    """ draw a growing red rectangle around the target """
    images = None
    inventory = {}

    def __init__(self, target_, timing_: int = 60):


        if id(target_) in HighlightTarget.inventory:
            return

        pygame.sprite.Sprite.__init__(self, self.containers)

        HighlightTarget.inventory[id(target_)] = self

        if len(HighlightTarget.inventory) > 1:
            for id_, sprite_ in HighlightTarget.inventory.items():
                if sprite_ != self:
                    sprite_.kill()
                    HighlightTarget.inventory.pop(id_)
                    break

        self.timing = timing_
        self.image = self.images.copy()
        self.target = target_
        # Scale the surface before displaying it
        self.image = pygame.transform.smoothscale(self.images, (10, 10))
        self.rect = self.image.get_rect(center=target_.rect.center)



        self.size = 0

        self.dt = 0

    def quit(self):
        try:
            if id(self.target) in HighlightTarget.inventory:
                HighlightTarget.inventory.pop(id(self.target))
        except (IndexError, ValueError) as _error:
                print('\n[-]HighlightTarget Error : %s' % _error)
        finally:
            self.kill()

    def update(self):
        if self.target.alive() and player.alive():

            if self.target in GROUP_UNION:

                if self.dt > self.timing:
                    self.image = pygame.transform.smoothscale(self.images, (10 + self.size, 10 + self.size))
                    self.rect = self.image.get_rect()
                    self.rect.center = self.target.rect.center
                    self.size += 1

                    self.size = self.size % int(self.target.rect.w * 1.2)
                    self.dt = 0
            else:
                self.quit()

            self.dt += TIME_PASSED_SECONDS
        else:
            self.quit()


class Follower(pygame.sprite.Sprite):
    # Assign sprite to follow the Enemy position
    images = []
    containers = []
    inventory = []

    def __new__(cls, offset_: tuple, timing_: int = 15, loop_: bool = False,
                event_: str = None, object_=None, *args, **kwargs):
        # return if an instance already exist.

        # Instance with event=None can duplicate (and event_ is not None)
        # e.g heat_glow on enemy shield
        if event_ in Follower.inventory and event_ is not None:
                return
        else:
                return super().__new__(cls, *args, **kwargs)

    def __init__(self, offset_: tuple, timing_: int = 15, loop_: bool = False, event_: str = None, object_=None):

        Follower.inventory.append(event_)

        if object_ is None:
            object_ = player

        pygame.sprite.Sprite.__init__(self, self.containers)

        self.dt = 0
        self.timing = timing_

        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]
        self.offset = offset_
        if offset_:
            # offset is a tuple representing the center
            # of the sprite position.
            # x and y is the offset to add to the spaceship center
            self.x = object_.rect.centerx - self.offset[0]
            self.y = object_.rect.centery - self.offset[1]
            self.rect = self.image.get_rect(center=offset_)
        else:
            # no offset, the sprite position is by default
            # the center of the player rectangle.
            self.rect = self.image.get_rect(center=object_.rect.center)

        # define if the animation is looping back
        self.loop = loop_
        self.index = 0
        self.event = event_
        self.object = object_


    def quit(self):
        if self.event:
            if self.event in Follower.inventory:
                Follower.inventory.remove(self.event)
        self.kill()

    @classmethod
    def kill_instance(cls, instance_):
       if instance_.event in Follower.inventory:
            Follower.inventory.remove(instance_.event)
       instance_.kill()

    def update(self):

            if self.dt > self.timing:

                if self.object.alive():

                    self.image = self.images_copy[self.index]

                    if self.offset:
                        self.rect = self.image.get_rect()
                        self.rect.center = (
                            self.object.rect.centerx - self.x,
                            self.object.rect.centery - self.y)
                    else:
                        self.rect = self.image.get_rect()
                        self.rect.center = self.object.rect.center

                    self.index += 1
                    if self.index > len(self.images_copy) - 1:
                        if self.loop:
                            self.index = 0
                        else:
                            self.quit()
                else:
                    self.quit()

                self.dt = 0

            self.dt += TIME_PASSED_SECONDS


class GenericAnimation(pygame.sprite.Sprite):
    images = []
    containers = None
    inventory = []

    buffer = []
    buffer_initialized = False

    def __new__(cls, object_, ratio_: (int, float, list) = None, timing_: int = 15, offset_: pygame.Rect = None,
                 event_name_: str = None, loop_: bool = True, *args, **kwargs):
        # return if an instance already exist.
        if id(object_) in GenericAnimation.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_, ratio_: (int, float, list) = None, timing_: int = 15, offset_: pygame.Rect = None,
                 event_name_: str = None, loop_: bool = True):
        """
        :param object_: Player, Asteroid class, pygame.Rect, Anomaly and Shot
        :param ratio_:  int |float or list values.
                        It is used for re-scaling the animation if needed
                        if a single value is passed to the constructor n identical values will be placed into
                        a new list : [value] x len(animation).
                        List allow an user defined type of re-scaling. The list can include floating numbers
        :param timing_: Duration of the animation (frames / second)
        :param offset_: When offset is not used, the Player class is used to determine the exact location
                        where the sprite will be display.
                        Otherwise a pygame.rectangle is passed to the constructor with an user-defined location.
        :param event_name_: Optional, this variable is used in certain case to follow up events for a specific
                            type of sprite.
        :param loop_    : loop the sprite indefinitely until it touch the screen border or kill the sprite when
                          the animation is complete.
        """

        GenericAnimation.inventory.append(id(object_))

        pygame.sprite.Sprite.__init__(self, self.containers)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            if event_name_ == 'SPACE_ANOMALY':
                All.change_layer(self, -8)
            else:
                All.change_layer(self, -1)

        # assert isinstance(object_, (Player, Asteroid, pygame.Rect, Anomaly, Shot)), \
        #    'Expecting Player class got %s ' % type(object_)

        # self.object_ represent a tuples of an
        # object coordinates (location
        # where the sprite needs to be display).
        self.object_ = object_

        # assert isinstance(event_name_, (str, type(None))), 'Expecting string or None got %s ' % type(event_name_)
        self.event_name_ = event_name_

        # assert isinstance(ratio_, (list, int, float, type(None))), \
        #    'Expecting a list or an integer got %s ' % type(ratio_)
        # assert isinstance(timing_, int), \
        #    'Expecting an integer got %s ' % type(timing_)
        self.timing = timing_
        # assert isinstance(offset_, (pygame.Rect, type(None))), \
        #    'Expecting a Rect or None got %s ' % type(offset_)
        self.offset = offset_

        # work from a copy to avoid an Index Error
        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]

        if ratio_ is not None:
            if isinstance(ratio_, list):
                self.ratio = ratio_
            else:
                self.ratio = [ratio_] * len(self.images_copy)
        else:
            self.ratio = None

        if self.offset is not None:
            self.rect = self.image.get_rect(center=self.offset.center)
        else:
            self.rect = self.image.get_rect(center=self.object_.location().center)

        self.loop = loop_
        self._frame = 0
        self.index = 0

        # Growing rect is a dummy rectangle used
        # for nuke explosion.
        # It represent the explosion radius or blast
        # Every objects colliding with it will received damage inversely
        # proportional to their distance from the explosion centre.
        # Creating the blast rectangle of size 200 pixels square (minimum blast radius)
        self.blast_rectangle = pygame.Rect(10, 10, 200, 200)
        # Placing the rectangle centre (explosion centre)
        self.blast_rectangle.center = self.rect.center
        # sign = 1 inflating | -1 deflating
        self.sign = 1
        # list of object inside the blast radius that
        # already received damages
        self.blasted_object = []

        # used by sin(theta) of LEVEL UP
        self.theta = 0

        self._id = id(self)
        self.dt = 0

    def get_animation_index(self):
        return self.index

    def quit(self):
        try:
            if id(self.object_) in GenericAnimation.inventory:
                GenericAnimation.inventory.remove(id(self.object_))
        except (IndexError, ValueError) as _error:
            print('\n[-]Asteroid Error : %s' % _error)
        finally:
            self.kill()

    @classmethod
    def kill_event(cls, instance_):
        if instance_ in All:
            instance_.kill()

    @property
    def index(self):
        return self.__index

    @index.setter
    def index(self, index):
        if index >= len(self.images_copy):
            if self.loop:
                self.__index = 0
            else:
                if self.event_name_ == 'LEVEL_UP':
                    GenericAnimation.buffer_initialized = True
                    Score.level_up_state = False
                self.quit()
        else:
            self.__index = index

    def check_image(self):
        if not SCREENRECT.contains(self.image.get_rect()):
            self.quit()

    def update(self):

        # if self._frame % ceil(self.timing / (TIME_PASSED_SECONDS + 0.01)) == 0:
        if self.dt > self.timing:

            self.image = self.images_copy[self.index]

            # Resize the sprite if needed
            if self.ratio:
                if self.ratio[self.index] != 1:
                    self.image = pygame.transform.scale(self.images_copy[self.index],
                                                        (int(self.images_copy[self.index].get_width() * self.ratio[
                                                            self.index]),
                                                         int(self.images_copy[self.index].get_height() * self.ratio[
                                                             self.index])))

            # player class only (level up) or explosion
            if isinstance(self.object_, Player):

                # display the message LEVEL UP
                if self.event_name_ == 'LEVEL_UP':

                    if GenericAnimation.buffer_initialized:
                        # screen.blit(GenericAnimation.buffer[self.index], (10, 100))
                        self.image = GenericAnimation.buffer[self.index]
                        self.rect = self.image.get_rect(topleft=(10, 100))
                    else:

                        self.theta += pi / len(self.images_copy)

                        LEVEL_UP_MSG_ = pygame.transform.smoothscale(LEVEL_UP_MSG, (
                            LEVEL_UP_MSG.get_width() // 2 + int(LEVEL_UP_MSG.get_width() * sin(self.theta)) + 1,
                            LEVEL_UP_MSG.get_height() // 2 + int(LEVEL_UP_MSG.get_height() * sin(self.theta) + 1)
                        ))
                        # add transparency to the texture
                        #  LEVEL_UP_MSG_ = add_transparency_all(pygame.surfarray.array3d(LEVEL_UP_MSG_),
                        #                                     pygame.surfarray.array_alpha(LEVEL_UP_MSG_),
                        #                                     self.index * 4 if self.index < 63 else 1)

                        self.image.blit(LEVEL_UP_MSG_, (10, 100))
                        # create the buffer
                        GenericAnimation.buffer.append(LEVEL_UP_MSG_)

                    self.rect = self.image.get_rect(center=self.object_.location().center)

            # space anomalies
            elif isinstance(self.object_, Anomaly):
                if not self.rect.midtop[1] > SCREENRECT.h:
                    self.rect.move_ip(0, 1.05)
                else:
                    if self.event_name_ == 'SPACE_ANOMALY':
                        Anomaly.active = False
                    self.quit()
                    return

            # Create a SUPER explosion
            elif isinstance(self.object_, Shot):
                self.rect = self.image.get_rect(center=self.object_.rect.midtop)
                if self.index == (len(self.images_copy) - 1) // 2:
                    collateral_damage = pygame.sprite.spritecollideany(self, asteroids)
                    # draw a red rectangle to see the explosion radius
                    # pygame.draw.rect(screen, (255, 0, 0), self.rect, 2)

                    if collateral_damage:
                        Asteroid.hit(object_=collateral_damage, weapon_=HALO_EXPLOSION, bomb_effect_=True)

            # NUCLEAR MISSILE
            elif self.event_name_ == 'NUCLEAR_EXPLOSION':
                pass

            # Display a circle around an object
            # reference for the missile targeting system
            elif self.event_name_ == 'TARGET':

                if hasattr(self.object_, 'location'):

                    if not (self.object_.alive() and player.alive()) or self.object_ not in GROUP_UNION:
                        self.quit()

                    if self.object_.image.get_width() < 80:
                        self.image = pygame.transform.smoothscale(self.images_copy[self.index],
                                                                  (int(self.object_.image.get_width() * 1.2),
                                                                   int(self.object_.image.get_height() * 1.2)))
                    else:
                        self.image = pygame.transform.smoothscale(self.images_copy[self.index], (80, 80))

                    self.rect = self.image.get_rect(center=self.object_.location().center)



            # TESLA effect field
            elif self.event_name_ == 'BEAM_FIELD':
                if hasattr(self.object_, 'location'):
                    if not (self.object_.alive() and player.alive()):
                        self.quit()

                    self.image = pygame.transform.smoothscale(self.images_copy[self.index],
                                                              (int(self.object_.image.get_width() * 1.5),
                                                               int(self.object_.image.get_height() * 1.5)))
                    self.rect = self.image.get_rect(center=self.object_.location().center)

            elif self.event_name_ == 'MISSILE EXPLOSION':
                self.rect = self.image.get_rect(center=self.object_.location().center)

            else:
                # Bonus
                if SCREENRECT.contains(self.rect):
                    self.rect.move_ip(0, 4)

            self.index += 1
            self.dt = 0

        self._frame += 1
        self.dt += TIME_PASSED_SECONDS
        # self.check_image()


class ParticleFxElectrical(pygame.sprite.Sprite):
    """ Create particles special effect with electrical beam """

    # ParticleFxElectrical.images_
    # ParticleFxElectrical.source
    # ParticleFxElectrical.destination
    # ParticleFxElectrical.rectangle
    # ParticleFxElectrical.offset_x
    # ParticleFxElectrical.offset_y
    images = []
    inventory = []
    containers = None
    offset_x = 0
    offset_y = 0

    def __init__(self):

        pygame.sprite.Sprite.__init__(self, self.containers)

        # Work from a copy
        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]
        self.rect = self.image.get_rect(midbottom=(-10, -10))

        self.particles = Point(lifetime=[3000, 3000], spawn=[0, 1200])
        # Saving the particle into a list
        ParticleFxElectrical.inventory.append(self.particles)

        self.speed = pygame.math.Vector2()
        self.speed.x = 0
        self.speed.y = 20

        self.equation = choice(['COS[self.angle]', 'SIN[self.angle]'])

        # Create instance variables of offset_x and offset_y otherwise offset position is lost each time
        # ParticleFxElectrical is called (ex ParticleFxElectrical.offset_x = 17 )
        # Each time a particle is created some new values are pushed into offset_x and offset_y
        self.offx = self.offset_x
        self.offy = self.offset_y
        self._frame = 0
        self.__angle = 0

    @property
    def angle(self):
        return self.__angle

    @angle.setter
    def angle(self, angle):
        self.__angle = angle if 0 < angle < 360 else 0
        return self.__angle

    def kill_particle(self):
        try:
            ParticleFxElectrical.inventory.remove(self.particles)
            self.kill()
        except (ValueError, IndexError):
            pass
        finally:
            return

    @staticmethod
    def ms(time_):
        return time_ * 1000

    def set_position(self, point):
        point.vector.x = player.rect.midbottom[0] + self.offx  # self.offset_x
        point.vector.y = player.rect.midtop[1]  # + self.offset_y
        self.rect.center = (point.vector.x, point.vector.y)

    def update(self):

        try:

            if self._frame % ceil(33 / (TIME_PASSED_SECONDS + 0.01)) == 0:
                # Particle start to live
                if self.ms(time_time.time() - self.particles.start) > self.particles.spawn:
                    # Particle exceed lifetime
                    if self.ms(time_time.time() - self.particles.start) - self.particles.spawn \
                            > self.particles.lifetime:
                        self.kill_particle()
                        return

                    else:

                        if not self.particles.set_:
                            self.set_position(self.particles)
                            self.particles.set_ = True

                        self.particles.vector.x += self.speed.x  # round(eval(self.equation) * 4)
                        self.particles.vector.y += -self.speed.y  # round(self.speed.y)
                        self.rect.center = (player.location().centerx + self.offx, self.particles.vector.y)

                        # check screen boundaries
                        if not SCREENRECT.contains(self.rect):
                            self.kill_particle()
                            return

            # end of if condition statement
            self._frame += 1

        except IndexError:
            print('\n[-]ParticleFx Error : Index error.')
            self.kill_particle()
            return


class Blast(pygame.sprite.Sprite):
    images = []
    containers = None
    inventory = []

    def __new__(cls, object_, timing_, *args, **kwargs):
        # return if an instance already exist.
        if id(object_) in Blast.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_, timing_):

        pygame.sprite.Sprite.__init__(self, self.containers)
        # assert isinstance(object_, (Asteroid, Player, tuple)), 'Expecting a class or a tuple for argument ' \
        #                                                       'object_ got %s ' % type(object_)
        self.object_ = object_

        self.inventory.append(id(self.object_))

        self.speed = pygame.math.Vector2()
        self.speed.x = choice([randint(-6, -2), randint(2, 6)])
        self.speed.y = choice([randint(-6, -2), randint(2, 6)])

        # Work from a copy
        self.images_copy = Blast.images.copy()
        self.image = self.images_copy[0] if isinstance(self.images_copy, list) else \
            self.images_copy

        self.rect = self.image.get_rect(center=self.object_.rect.center)
        self._frame = 0
        self.index = 0
        self.dt = 0
        self.timing = timing_

        # Player explosion
        # Transform the spaceship debris into lethal projectiles (using
        # DEBRIS Weapon instance)
        if isinstance(self.object_, Player):
            # pass the vector
            DEBRIS.velocity = self.speed
            # pass the image
            DEBRIS.sprite = self.image
            # debris is now a shot
            Shot(self.rect.center, DEBRIS, True, 0, self.rect.centery, 33,
                 SC_spaceship, TIME_PASSED_SECONDS, All, -2)
            # no need to stay into Blast for debris animation,
            # the class Shot will take over.
            self.quit()

    def get_animation_index(self):
        return self.index

    def quit(self):
        try:
            if id(self.object_) in Blast.inventory:
                Blast.inventory.remove(id(self.object_))
        except (IndexError, ValueError) as _error:
            print('\n[-]Blast Error : %s' % _error)
        finally:
            self.kill()

    @property
    def index(self):
        return self.__index

    @index.setter
    def index(self, index):
        if isinstance(self.images_copy, list):
            if index >= len(self.images_copy):
                self.quit()
                return
        self.__index = index

    def update(self):

        if self.dt > self.timing:

            if SCREENRECT.contains(self.rect):

                if isinstance(self.object_, Enemy):

                    # check the sizes of the image before processing it with
                    # add_transparency method, also image with width equal zero
                    # will cause warning messages with numpy.average,
                    if self.image.get_width() == 0 or self.image.get_height() == 0:
                        self.quit()

                    # Check image bit size
                    if self.image.get_bitsize() == 32:
                        rgba_array = pygame.surfarray.pixels3d(self.image)
                        alpha_channel = pygame.surfarray.pixels_alpha(self.image)

                    elif self.image.get_bitsize() == 24:
                        rgba_array = pygame.surfarray.pixels3d(self.image)
                        alpha_channel = pygame.surfarray.array_alpha(self.image)
                    else:
                        raise ERROR('\n[-]ERROR - This can only work on 32/24 - bit Surfaces.')

                    # Alpha channel is below 20
                    if numpy.average(alpha_channel) < 20:
                        self.quit()
                    # todo need to check here if add_transparency_all can take 24bit else
                    # use set_alpha instead
                    # Add progressive transparency effect to the sprite
                    self.image = add_transparency_all(rgba_array, alpha_channel, 5)

                else:
                    if isinstance(self.images_copy, list):
                        self.image = self.images_copy[self.index]
                        self.speed.x = round(self.speed.x * 1 / (1 + 0.00001 * pow(self._frame, 2)), 1)
                        self.speed.y = round(self.speed.y * 1 / (1 + 0.00001 * pow(self._frame, 2)), 1)

                self.rect.move_ip((self.speed.x, self.speed.y))

                self.index += 1
                self._frame += 1

            else:
                self.quit()

            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


class ParticleFxFire(pygame.sprite.Sprite):
    """ Create fire particles """

    images = PHOTON_PARTICLE_1
    inventory = []
    containers = None

    def __init__(self, vector: pygame.math.Vector2, timing_: int = 15):

        # No need to create an instance if the player
        # is dead
        if not player.alive():
            return

        pygame.sprite.Sprite.__init__(self, self.containers)
        # assert isinstance(vector, pygame.math.Vector2), \
        #    'Expecting pygame.math.Vector2 for argument vector, got %s ' % type(vector)
        # assert isinstance(timing_, int), \
        #    'Expecting int for argument timing_ got %s ' % type(timing_)

        # Work from a copy
        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]

        self.rect = self.image.get_rect(midbottom=(-100, -100))

        self.particles = Point(lifetime=[30, 5000], spawn=[30, 200])
        ParticleFxFire.inventory.append(self.particles)

        self.speed = vector

        self.index = 1
        self.__index = 0
        self._frame = 0
        self.angle = 0
        self.__angle = 0
        self.dt = 0
        self.timing = timing_

    @property
    def index(self):
        return self.__index

    @index.setter
    def index(self, index):
        if index >= len(self.images):
            self.quit()
        else:
            self.__index = index

    @property
    def angle(self):
        return self.__angle

    @angle.setter
    def angle(self, angle):
        self.__angle = angle if 0 < angle < 360 else 0
        return self.__angle

    def scale_particle(self, image_, factor_):
        scale = (image_.get_width() - factor_,
                 (image_.get_height() - factor_))
        if scale <= (0, 0):
            self.quit()
            return
        return pygame.transform.scale(image_, scale)

    def quit(self):
        try:
            if self.particles in ParticleFxFire.inventory:
                ParticleFxFire.inventory.remove(self.particles)
        except (IndexError, ValueError) as error_:
            print('\n[-]ParticleFx Error : %s' % error_)
        finally:
            self.kill()

    def set_position(self, point):
        # assert isinstance(point, Point), \
        #    'Expecting class Point for argument point got %s ' % type(point)
        # self.rectangle is the player rect
        point.vector.x = player.rect.center[0] + randint(-10, 10)
        point.vector.y = player.rect.center[1] + randint(-10, 10)
        # Particle starting from the player center
        self.rect.center = (point.vector.x, point.vector.y)

    def update(self):

        if self.dt > self.timing:

            if (time_time.time() - self.particles.start) * 1000 > self.particles.spawn:

                if (time_time.time() - self.particles.start) * 1000 - self.particles.spawn \
                        > self.particles.lifetime:
                    self.quit()
                    return

                else:

                    reduce_factor = 0.9

                    self.image = self.images_copy[self.index]

                    if not self.particles.set_:
                        self.set_position(self.particles)
                        self.particles.set_ = True
                    else:
                        self.index += 1

                    self.images_copy[self.index] = self.scale_particle(self.images_copy[self.index],
                                                                       round(self.index * reduce_factor))
                    self.particles.vector += self.speed
                    self.rect.center = (
                        self.particles.vector.x + round(self.index * reduce_factor),
                        self.particles.vector.y
                    )
            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


class Halo(pygame.sprite.Sprite):
    # Create a luminous ring (disk of light) around an object.

    images = []
    containers = None
    inventory = []

    def __new__(cls, object_, speed_: int = 18, halo=HALO_EXPLOSION, *args, **kwargs):
        # return if an instance already exist.
        if object_ in Halo.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_, speed_: int = 18, halo=HALO_EXPLOSION):
        """
        :param object_: object to display the ring around it.
        :param speed_: Frame rate or animation speed.
        :param halo: halo class
        """

        # assert isinstance(halo, HALO), \
        #    'Expecting class HALO for argument halo got, %s ' % type(halo)
        # assert isinstance(object_, (Asteroid, Player, pygame.Rect, Enemy)), \
        #     'Expecting class or pygame.Rect for argument object_ got %s ' % type(object_)
        # assert isinstance(speed_, int), 'Expecting integer for argument speed_ got %s ' % type(speed_)

        self.halo = halo

        Halo.inventory.append(object_)

        pygame.sprite.Sprite.__init__(self, self.containers)

        self.object_ = object_
        # create an animation with a single sprite
        if isinstance(self.images, pygame.Surface):
            self.images = [self.images] * 30
        # Always working from a copy
        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]

        # if the object is a pygame rectangle
        if isinstance(self.object_, pygame.Rect):
            self.rect = self.image.get_rect(center=self.object_.center)
        # otherwise we are using the object's method
        # to get the center.
        else:
            self.rect = self.image.get_rect(center=object_.rect.center)

        self.dt = 0
        self.index = 0
        self.speed = speed_

        """
        # ------------- DO NOT DELETE ----------------------
        # uncomment the line below for elastic collision 
        # and explosion chain reaction. 
        self.blast_rectangle = pygame.Rect(10, 10, self.halo.min_radius, self.halo.min_radius)
        # Placing the rectangle centre (explosion centre)
        self.blast_rectangle.center = self.rect.center
        # sign = 1 inflating | -1 deflating
        self.sign = 1
        # list of object inside the blast radius that
        # already received damages
        self.blasted_object = []
        """

    def get_animation_index(self):
        return self.index

    def quit(self):
        try:
            if self.object_ in Halo.inventory:
                Halo.inventory.remove(self.object_)
        except (IndexError, ValueError) as _error:
            print('\n[-]Halo Error : %s' % _error)
        finally:
            self.kill()

    def update(self):

        if self.dt > self.speed:

            self.image = self.images_copy[self.index]
            if isinstance(self.object_, pygame.Rect):
                self.rect = self.image.get_rect(center=self.object_.center)
            else:
                self.rect = self.image.get_rect(center=self.object_.rect.center)

            """
            # --------------  DO NOT DELETE ------------------------ 
            # uncomment the line below for elastic collision effect 
            # and explosion chain reaction
            
            # Elastic collision simulation
            # sign > 0 inflating the rectangle
            if self.sign is 1:

                # inflate the rectangle until it reach the maximum blast radius
                if self.blast_rectangle.size < (self.halo.blast_radius,
                                                self.halo.blast_radius):
                    # todo need to replace 0.57 by the velocity
                    self.blast_rectangle.inflate_ip(int(self.index / 0.57), int(self.index / 0.57))
                else:
                    # we we reach the maximum radius,
                    # time to deflate the rectangle
                    self.sign = -1
            else:
                # deflate the rectangle to (100, 100)
                if self.blast_rectangle.size > (100, 100):
                    self.blast_rectangle.inflate_ip(-self.index, - self.index)
                else:
                    self.sign = 0

            
             
            self.blast_rectangle.center = self.rect.center

            # Assign self.rect to self.blast_rectangle for collision detection
            self.rect = self.blast_rectangle

            explosion_centre = self.rect.center

            if self.sign is 1:
                shock_wave_collision(self, explosion_centre, halo=self.halo)

            # Re-assign self.rect to its original location
            self.rect = self.image.get_rect(center=explosion_centre)
            """

            if self.index < len(self.images_copy) - 1:
                self.index += 1
            else:
                self.quit()

            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


def shock_wave_collision(sprite, centre: tuple, halo: HALO):
    """
    Elastic collision
    :param sprite:
    :param centre:
    :param halo:
    :return:
    """

    # assert isinstance(centre, tuple), \
    #     'Expecting tuple for argument centre, got %s ' % type(centre)
    # assert isinstance(halo, HALO), \
    #    'Expecting HALO class for argument weapon, got %s ' % type(halo)

    # debug only
    # pygame.draw.circle(screen, (255, 0, 0, 0), sprite.rect.center,
    #                   int(sqrt((sprite.rect.w//2)**2 + (sprite.rect.w//2)**2)), 3)  # outer circle
    # draw inner circle and rectangle
    # pygame.draw.circle(screen, (255, 0, 0, 0), sprite.rect.center, sprite.rect.w // 2, 3)
    # pygame.draw.rect(screen, (255, 0, 0, 0), sprite.rect, 3)  # explosion rectangle


    # return a single sprite colliding with the shock wave
    kill = pygame.sprite.spritecollideany(sprite, GROUP_UNION)  # asteroids)

    # check if the sprite has already sustain damages
    # if True we are creating a a copy of the group to remove this element and
    # continue the iteration over.
    # e.g If an object is not destroyed after the explosion, spritecollideany will return
    # this specific sprite all over again until it is not included into the list (group ordered dict).

    if id(kill) in sprite.blasted_object and kill:
        # copy_ = asteroids.copy()
        # copy_.remove(kill)

        GROUP_UNION.remove(kill)
        kill = pygame.sprite.spritecollideany(sprite, GROUP_UNION)  # copy_

    # check if the kill object is the nuke aiming point (not considered as a target)
    if kill and kill not in nuke_aiming_point:
        # debug only
        # pygame.draw.line(screen, (255, 255, 255, 0), self.rect.center, kill.rect.center, 3)

        # check if object has already received damages from the blast
        if id(kill) not in sprite.blasted_object:
            # distance from the explosion center (damages are proportional to the distance)
            distance = Threat.get_distance(pygame.math.Vector2(centre),
                                           pygame.math.Vector2(kill.rect.center))

            phi = Physics.Momentum.contact_angle(pygame.math.Vector2(centre),
                                                 pygame.math.Vector2(kill.rect.center))

            if distance != 0:  # avoid ValueError: Can't normalize Vector of length Zero
                v2 = pygame.math.Vector2(cos(phi) * distance, sin(phi) * distance).normalize()
                v2 *= 10

                kill.vector.y *= -1  # inverting y
                if isinstance(kill, Asteroid):
                    obj1 = Physics.TestObject(kill.vector.x, kill.vector.y,
                                              kill.asteroids.mass, kill.rect)
                elif isinstance(kill, Enemy):
                    obj1 = Physics.TestObject(kill.vector.x, kill.vector.y,
                                              kill.enemy_.mass, kill.rect)

                # shock wave force/mass will be proportional to the object distance
                obj2 = Physics.TestObject(v2.x, v2.y, halo.mass / distance, sprite.rect)

                # method returning only v1 vector components.
                # if v2 is needed, use method process instead.
                v1 = Physics.Momentum.process_v1(obj1, obj2)
                kill.vector = v1
            if isinstance(kill, Asteroid):
                # send damages to the object
                Asteroid.hit(object_=kill, weapon_=halo, bomb_effect_=True, distance=distance)
                # put the kill object into a list (received damages)
                if id(kill) not in sprite.blasted_object:
                    sprite.blasted_object.append(id(kill))

            elif isinstance(kill, Enemy):
                Enemy.hit(object_=kill, weapon_=halo, bomb_effect_=True, distance=distance)


class PlayerHalo(pygame.sprite.Sprite):
    """
        Create a luminous ring (disk of light) around the player (after explosion)
    """
    images = []
    containers = None
    inventory = []

    def __new__(cls, object_, speed_: int = 18, halo: HALO = HALO_EXPLOSION, *args, **kwargs):
        # return if an instance already exist.
        if object_ in PlayerHalo.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_, speed_: int = 18, halo: HALO = HALO_EXPLOSION):
        """
        :param object_: object to display the ring around it.
        :param speed_: Frame rate or animation speed.
        :param halo : halo class
        """
        """
        assert isinstance(object_, (Player, Asteroid, pygame.Rect)), \
            'Expecting class Player, Asteroid or pygame.Rect for argument object_ got %s ' % type(object_)
        assert isinstance(speed_, int), 'Expecting integer for argument speed_ got %s ' % type(speed_)
        assert isinstance(halo, HALO), \
            'Expecting HALO class for argument halo got %s ' % type(halo)
        """
        self.halo = halo

        PlayerHalo.inventory.append(object_)

        pygame.sprite.Sprite.__init__(self, self.containers)

        self.object_ = object_

        # create an animation with a single sprite
        if isinstance(self.images, pygame.Surface):
            self.images = [self.images * 30]
        # Always working from a copy
        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]

        # if the object is a pygame rectangle
        if isinstance(self.object_, pygame.Rect):
            self.rect = self.image.get_rect(center=self.object_.center)
        # otherwise we are using the object's method
        # to get the center.
        else:
            self.rect = self.image.get_rect(center=object_.rect.center)

        self.dt = 0
        self.index = 0
        self.speed = speed_

        # Elastic collision
        self.blast_rectangle = pygame.Rect(10, 10, self.halo.min_radius, self.halo.min_radius)
        # Placing the rectangle centre (explosion centre)
        self.blast_rectangle.center = self.rect.center
        # sign = 1 inflating | -1 deflating
        self.sign = 1
        # list of object inside the blast radius that
        # already received damages
        self.blasted_object = []

        global WOBBLY
        WOBBLY = 0

    def get_animation_index(self):
        return self.index

    def quit(self):
        try:
            if self.object_ in PlayerHalo.inventory:
                PlayerHalo.inventory.remove(self.object_)
        except (IndexError, ValueError) as _error:
            print('\n[-]PlayerHalo Error : %s' % _error)
        finally:
            global WOBBLY
            WOBBLY = 0
            self.kill()

    def update(self):

        global WOBBLY

        if self.dt > self.speed:

            WOBBLY = 10 if WOBBLY in (0, -10) else -10

            self.image = self.images_copy[self.index]
            if isinstance(self.object_, pygame.Rect):
                self.rect = self.image.get_rect(center=self.object_.center)
            else:
                self.rect = self.image.get_rect(center=self.object_.rect.center)

            # Elastic collision simulation
            # sign > 0 inflating the rectangle
            if self.sign is 1:

                # inflate the rectangle until it reach the maximum blast radius
                if self.blast_rectangle.size < (self.halo.blast_radius,
                                                self.halo.blast_radius):

                    self.blast_rectangle.inflate_ip(int(self.index / self.halo.velocity),
                                                    int(self.index / self.halo.velocity))
                else:
                    # we we reach the maximum radius,
                    # time to deflate the rectangle
                    self.sign = -1
            else:
                # deflate the rectangle to (100, 100)
                if self.blast_rectangle.size > (100, 100):
                    self.blast_rectangle.inflate_ip(-self.index, - self.index)
                else:
                    self.sign = 0

            self.blast_rectangle.center = self.rect.center

            # Assign self.rect to self.blast_rectangle for collision detection
            self.rect = self.blast_rectangle

            explosion_centre = self.rect.center

            if self.sign is 1:
                shock_wave_collision(self, explosion_centre, halo=self.halo)

            # Re-assign self.rect to its original location
            self.rect = self.image.get_rect(center=explosion_centre)

            if self.index < len(self.images_copy) - 1:
                self.index += 1
            else:
                self.quit()

            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


def bonus_energy(object_):
    """
    Create an energy bonus when an object/enemy is killed.
    :param object_: Class Player, Asteroid etc
    :return Return true if the bonus is granted otherwise false
    """
    # assert isinstance(object_, (Player, Asteroid, Enemy)), \
    #    'Expecting class got %s ' % type(object_)

    # count the number of energy cells in the bonus group.
    # Only one energy cell can be display at the time
    total = 0
    for element in bonus:
        if element.bonus_type == 'ENERGY':
            total += 1
        if total > 1:
            return False

    if total < 1:
        if randint(0, 100) > 92:
            Bonus.images_ = ENERGY_BOOSTER1
            Bonus.energy = randint(1000, 10000)
            # add the sprite to the group
            bonus.add(Bonus(object_=object_, ratio_=0, timing_=15,
                            offset_=None, event_name_='ENERGY BONUS', loop_=True, bonus_type_='ENERGY'))

            SC_spaceship.play(sound_=CRYSTAL_SOUND, loop_=True, priority_=0,
                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True,
                              name_='CRYSTAL', x_=object_.rect.centerx, object_id_=id(object_))
            return True

    return False


def bonus_bomb(object_):
    """
    Create a bomb bonus when an object/enemy is killed (see conditions below)
    :param object_: Class Player, Asteroid etc
    :return Return true if a bonus is granted otherwise false.
    """
    # assert isinstance(object_, (Player, Asteroid, Enemy)), \
    #    'Expecting a class got %s ' % type(object_)
    if 0 <= SHIP_SPECS.nukes < 3:

        # count the number of bomb in the bonus group.
        # Only one bomb can be display at the time
        total = 0
        for element in bonus:
            if element.bonus_type == 'BOMB':
                total += 1
            if total > 1:
                return False

        if total < 1:
            if randint(0, 100) > 98:
                Bonus.images_ = NUKE_BONUS
                # add the sprite to the group
                bonus.add(Bonus(object_=object_, ratio_=0, timing_=15,
                                offset_=None, event_name_='BOMB BONUS', loop_=True, bonus_type_='BOMB'))
                return True

    return False


def bonus_ammo(object_):
    """
    Create a bomb bonus when an object/enemy is killed (see conditions below)
    :param object_: Class Player, Asteroid etc
    :return Return true if a bonus is granted otherwise false.
    """
    # assert isinstance(object_, (Player, Asteroid, Enemy)), \
    #    'Expecting a class got %s ' % type(object_)

    # count the number of AMMO in the bonus group.
    # Only one AMMO can be display at the time
    total = 0
    for element in bonus:
        if element.bonus_type == 'AMMO':
            total += 1
        if total > 1:
            return False

    if total < 1:
        if randint(0, 100) > 98:
            Bonus.images_ = COLLECTIBLES_AMMO
            # add the sprite to the group
            bonus.add(Bonus(object_=object_, ratio_=0, timing_=15,
                            offset_=None, event_name_='AMMO BONUS', loop_=True, bonus_type_='AMMO'))
            return True
    return False


def bonus_gems(object_):
    """
    Create gem(s) bonus when an object/enemy is killed.
    :param object_: Class Player, Asteroid etc
    :return Return true if the bonus is granted otherwise false
    """
    # assert isinstance(object_, (Player, Asteroid, Enemy)), \
    #     'Expecting a class got %s ' % type(object_)

    # count the number of gems in the bonus group.
    # No more than 10 gems display at once.
    if len(gems) > 10:
        return
    # 70% chance to create a gem
    if randint(0, 100) > 70:
        # add the gem to the group
        gems.add(Gems(object_=object_, ratio_=1, timing_=15, offset_=None))
        return True

    return False


class ComboKill:
    _kill = 0
    _start = time_time.time()
    _watch = False

    def __init__(self):

        ComboKill._kill += 1

        # initialise variables
        if not ComboKill._watch:
            ComboKill._start = time_time.time()
            ComboKill._watch = True

        # todo finalize the bonus given to the player
        # checking the number of kills after 4 seconds
        # A Killstreak is earned when a player acquires a
        # certain number of kills in a row without dying
        if time_time.time() - ComboKill._start > 2:
            if ComboKill._kill > 11:
                self.bonus()
                self.message('Killing Streak X12')
            # 8 kills
            elif ComboKill._kill > 7:
                self.bonus()
                self.message('Fury X8')
            # 6 kills
            elif ComboKill._kill > 5:
                self.bonus()
                self.message('Rage X6')
            # 4 kills
            elif ComboKill._kill > 3:
                self.bonus()
                self.message('Aggressive X4')
            self.reset()

    def reset(self):
        """ Reset the variable """
        ComboKill._kill = 0
        ComboKill._watch = False

    def message(self, msg):
        """ Display a combo message """
        DamageDisplay(None, 10, TIME_PASSED_SECONDS, msg, timing_=33)
        pass

    def bonus(self):
        """
        Give extra life, experience, weapons, shield
        etc
        """
        pass


class Asteroid(pygame.sprite.Sprite):
    weakness = None
    inventory = []
    containers = None
    initialised = True

    def __init__(self, asteroids_: Asteroids, start_: int, stop_: int, timing_, layer_=-2):
        """
        Add methods and variables to a pre-existing asteroid object.
        Note about start_ and stop_ : Controls the time when asteroids
        are starting their journey in the game ( the time is choose randomly
        between start_ and stop_).
        :param asteroids_: Asteroids class (see Asteroids.py for more details).
        :param start_: Minimum spawning time in ms.
        :param stop_:  MAximum spawning time in ms.
        """

        # assert isinstance(asteroids_, Asteroids), 'Expecting class Asteroids for argument asteroids_ ' \
        #                                          'got %s ' % type(asteroids_)
        # assert isinstance(start_, int), 'Expecting int for argument start_ got %s ' % type(asteroids_)
        # assert isinstance(stop_, int), 'Expecting int for argument stop_  got %s ' % type(asteroids_)

        pygame.sprite.Sprite.__init__(self, self.containers)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_:
                All.change_layer(self, -2)

        self.asteroids = asteroids_
        self.impact_sound = asteroids_.impact_sound

        self.images = asteroids_.animation.copy() if isinstance(asteroids_.animation, list) \
            else [asteroids_.animation.copy()] * 2
        self.image = self.images[0]

        self.explosion_sprites = asteroids_.explosion
        self.impact_sprite = asteroids_.impact_animation

        # Asteroid location (Vector2D)
        self.position = pygame.math.Vector2()
        self.position.x = randint(0, SCREENRECT.w)
        self.position.y = SCREENRECT.top - 100

        # Asteroid vector speed
        if self.position.x < SCREENRECT.midtop[0]:
            self.vector = pygame.math.Vector2()  # Asteroid speed and trajectory (Vector2d)
            self.vector.x = uniform(0, 1)
        else:
            self.vector = pygame.math.Vector2()  # Asteroid speed and trajectory (Vector2d)
            self.vector.x = uniform(0, -1)
        self.vector.y = uniform(4, 12)

        self.rect = self.image.get_rect(midbottom=self.position)

        # Maximum damages before disintegration.
        self.hp = asteroids_.hp

        self.player_damages = [randint(25, 50), randint(51, 100), randint(101, 220), randint(221, 450),
                               randint(451, 650), randint(651, 780), randint(781, 900), randint(901, 1000)]
        self.damage = self.player_damages[asteroids_.asteroid_class]

        self.spawn = uniform(start_, stop_)  # Spawning time
        # 50%,25%,15% damage bonuses for this weapons
        self.weakness = {'ELECTRIC': 0.5, 'PHOTON': 0.25, 'LASER': 0.15}

        self.index = 0
        # timestamp
        self.time = time_time.time()
        self._id = id(self)

        if id(self) not in Asteroid.inventory:
            Asteroid.inventory.append(id(self))

        self.dt = 0
        self.timing = timing_
        self.initialised = Asteroid.initialised

    def get_animation_index(self):
        """ return animation index """
        return self.index

    def blend(cls, damages: float):
        # assert isinstance(intensity, float), \
        #    'Expecting float for argument intensity got %s ' % type(intensity)
        if cls.images[cls.index].get_bitsize() == 32:
            cls.image = blend_texture_alpha(cls.image, damages * 0.5 / cls.asteroids.max_hp, (255, 0, 0, 0))
        elif cls.images[cls.index].get_bitsize() == 24:
            cls.image = blend_texture_24bit(cls.image, damages * 0.5 / cls.asteroids.max_hp
                                            , (255, 0, 0), (0, 0, 0, 0))
        else:
            raise ERROR('\n[-]DamageDisplay - Texture with 8-bit depth color cannot be blended.')

    # property to cap asteroid health points
    # and to start a destruction sequence when <=0
    @property
    def hp(self):
        return self.__hp

    @hp.setter
    def hp(self, hp):
        self.__hp = hp
        # Health point < 1, start
        # an explosion animation.
        if hp < 1:
            self.__hp = 0
            self.explosion(mute_=False)
        return self.__hp

    @staticmethod
    def damage_radius_calculator(damage: int, gamma: float, distance: float) -> int:
        """
        Return damages proportional to the distance of the explosion centre
        :param damage: Max damages
        :param gamma:  Constant to adjust damages according to the distance
        :param distance: distance from the centre of the explosion
        :return: return damage proportional to the distance
        """

        # assert isinstance(damage, int), 'Expecting int for argument damage, got %s ' % type(damage)
        # assert isinstance(gamma, float), 'Expecting float for argument gamma, got %s ' % type(gamma)
        # assert isinstance(distance, float), 'Expecting float for argument distance, got %s ' % type(distance)
        try:
            return int((damage * (1 / (gamma * distance))) % damage)
        except ZeroDivisionError:
            return damage

    def get_distance(self, p1_: pygame.math.Vector2, p2_: pygame.math.Vector2) -> float:
        """ Get the distance between two points """
        # assert isinstance(p1_, pygame.math.Vector2), \
        #     'Expecting pygame.math.Vector2 for argument p1_, got %s ' % type(p1_)
        # assert isinstance(p2_, pygame.math.Vector2), \
        #    'Expecting pygame.math.Vector2 for argument p2_, got %s ' % type(p2_)
        return (p2_ - p1_).length()

    @staticmethod
    def hit(object_: Asteroids, weapon_: (Weapons, EnemyWeapons),
            bomb_effect_: bool = False, distance: (float, tuple) = 0.0, rect_center=None):
        """
        Control the amount of damage an asteroid is dealing with.
        :param object_: Asteroids class object containing all associated methods
                        and variables like hp (maximum damages before disintegration).
        :param weapon_: Weapons class containing all methods and variables like,
                        weapon type, damage etc.
        :param bomb_effect_ : For bomb or super shot with blast wave radius effect.
                (damage inversely proportional to the explosion centre distance)
        :param distance: distance from the explosion centre or shot origin (tuple, (x,y)).
        :param rect_center: collision rectangle between the shield and the projectile
        """

        # No collision rect passed to the method
        # by default the heat glow will be display in the centre.
        if rect_center is None:
            rect_center = object_.rect.center

        # assert isinstance(object_, Asteroid), \
        #    'Expecting class Asteroids for argument object_ got %s' % type(object_)
        # assert isinstance(bomb_effect_, bool), \
        #    'Expecting bool for argument bomb_effect_ got %s ' % type(bomb_effect_)
        # if bomb_effect_:
        #    assert isinstance(weapon_, HALO), \
        #        'Expecting class Weapons for argument weapon_ got %s ' % type(weapon_)
        # else:
        #    assert isinstance(weapon_, (Weapons, EnemyWeapons)), \
        #        'Expecting class Weapons for argument weapon_ got %s ' % type(weapon_)
        # assert isinstance(distance, (float, tuple, pygame.math.Vector2)), \
        #    'Expecting float, tuple or Vector2 for argument distance got %s ' % type(distance)

        if object_.rect.colliderect(SCREENRECT):

            if bomb_effect_:
                damage = Asteroid.damage_radius_calculator(damage=weapon_.damage, gamma=0.1E-1, distance=distance)
                object_.hp -= damage
                DamageDisplay(object_, damage, TIME_PASSED_SECONDS, event_=None, timing_=33)
            else:
                # Weapon bonus apply
                # +50%, +20% +15% more damage for specific weapons
                if weapon_.type_ in object_.weakness:
                    # base damage fraction (0.5 to 1)  + bonus
                    damage = randint(round(0.5 * weapon_.damage), weapon_.damage) + \
                             round(object_.weakness[weapon_.type_] * weapon_.damage)
                # No bonus
                else:
                    damage = weapon_.damage

                # damage proportional to the distance (player -> enemy) except
                # for missiles.
                if weapon_.name != 'STINGER_SINGLE':
                    damage = damage - int((damage * object_.get_distance(
                        pygame.math.Vector2(distance),
                        pygame.math.Vector2(object_.rect.center))) / SCREENRECT.h)

                object_.hp -= damage
                # No blending for list containing more than 2 sprites
                if len(object_.images) < 3:
                    # blend is proportional to the damage received
                    object_.blend(damage)

                # no damage display for Tesla effect
                # due to high frequency.
                if weapon_.type_ != 'TESLA':
                    DamageDisplay(object_, damage, TIME_PASSED_SECONDS, event_=None, timing_=33)

                # Tesla impact sprite is control directly by Tesla class
                if weapon_.type_ not in ('BULLET', 'TESLA'):
                    ImpactBurst(object_, override_method=False, loop_=False, timing_=33, rect_=None, layer_=-2)

    def quit(self):
        try:
            if id(self) in Asteroid.inventory:
                Asteroid.inventory.remove(id(self))
        except (IndexError, ValueError) as _error:
            print('\n[-]Asteroid Error : %s' % _error)
        finally:
            self.kill()

    def explosion(self, mute_: bool = False):
        """ Handle an asteroid/enemy explosion, create a sound effect,
            update player score and start method bonus_energy.
        :param : mute_, Mute on/off
         """
        # Sound of explosion is proportional to the asteroid size
        if not mute_:
            SC_explosion.play(sound_=self.asteroids.explosion_sound, loop_=False, priority_=0,
                              volume_=SOUND_LEVEL - 0.4 + self.asteroids.asteroid_class,
                              fade_out_ms=0, panning_=True,
                              name_='EXPLOSION', x_=self.rect.centerx, object_id_=self._id)

        # choose among 3 different color of halos
        Halo.images = choice([HALO_SPRITE11, HALO_SPRITE12, HALO_SPRITE13, HALO_SPRITE14])
        Halo(self)
        Explosion1(self, timing_=33, layer_=-1)

        if id(self) not in Blast.inventory:
            Blast.images = BLAST1
            for r in range(2):
                Blast(self, timing_=33)
                Blast.inventory.remove(id(self))
            Blast.images = BLAST1

        PlayerScore.update(self.asteroids.score)
        if not bonus_energy(self):
            if not bonus_bomb(self):
                bonus_ammo(self)

        bonus_gems(self)

        self.quit()

    def center(self):
        """ return a pygame.Rect (asteroid centre position)"""
        return self.rect.center

    def location(self):
        """ return a pygame.Rect (asteroid rectangle)"""
        return self.rect

    def update(self, *args):

        # inverted logic
        if self.initialised:
            if (time_time.time() - self.time) > self.spawn:
                self.initialised = False

        elif self.dt > self.timing:
            if not self.rect.colliderect(SCREENRECT):
                if self.rect.bottom > 0 or self.vector.y < 0:
                    self.quit()
                    return

            self.position += self.vector
            self.rect.center = self.position

            if isinstance(self.images, list):
                self.image = self.images[self.index]
                if self.index < len(self.images) - 1:
                    self.index += 1
                else:
                    self.index = 0

            # font = pygame.font.SysFont("arial", 10, 'normal')
            # display asteroid names
            # text = font.render(str(self.asteroids.name) + ' '
            #                  + str(self.damage), False, (5, 220, 12))
            # display hp/ id
            # text = font.render(str(self._id), False, (5, 220, 12))
            # screen.blit(text, self.rect.bottomright)

            if self.alive():
                # Adding sprite into the collision group
                COLLISION_GROUP.add(self)
                # inverted logic
                # removing the sprite from the group if the distance is over the collision radius.
                if (self.position - player.position).length() > COLLISION_RADIUS:
                    COLLISION_GROUP.remove(self)

            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


class ImpactBurst(pygame.sprite.Sprite):
    containers = None
    images = None
    inventory = []

    def __new__(cls, object_, override_method: bool = False,
                loop_: bool = False, timing_: int = 33, rect_=None, layer_=-2,  *args, **kwargs):
        # return if an instance already exist.
        if object_ in ImpactBurst.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_, override_method: bool = False,
                 loop_: bool = False, timing_: int = 33, rect_=None, layer_=-2):
        """
        Display an animation or particle ejected in space after collision
        between two objects or after taking a projectile direct hit.
        :param object_: Player, Asteroid class to apply impact animation
        """
        # todo rect argument is not used
        ImpactBurst.inventory.append(object_)

        pygame.sprite.Sprite.__init__(self, self.containers)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_:
                All.change_layer(self, layer_)

        # assert isinstance(object_, (Player, Asteroid, Enemy)), \
        #    'Expecting class Player, Asteroid or Enemy for argument object_ got %s ' % type(object_)
        # assert isinstance(override_method, bool), \
        #    'Expecting bool for argument override_method got %s ' % type(override_method)

        self.object_ = object_

        self.override_method = override_method
        if self.override_method:
            # assert isinstance(self.images, list), \
            #    'Expecting list for argument self.images got %s ' % type(self.images)
            self.images_copy = self.images.copy()
            self.image = self.images_copy[0]
        else:
            # assert isinstance(self.object_.impact_sprite, list), \
            #    'Expecting list for object_.impact_sprite got %s ' % type(self.object_.impact_sprite)
            self.images = self.object_.impact_sprite
            self.image = self.object_.impact_sprite[0]

        self.rect = self.image.get_rect(center=self.object_.rect.center)
        self.index = 0
        # id referring to the instance
        self.id = id(self)
        self.loop = loop_
        self.timing = timing_

        self.dt = 0

    @classmethod
    def kill_event(cls, instance_):
        if instance_ in All:
            instance_.kill()

    def get_animation_index(self):
        return self.index

    def quit(self):
        try:
            if self.object_ in ImpactBurst.inventory:
                ImpactBurst.inventory.remove(self.object_)
        except (IndexError, ValueError) as _error:
            print('\n[-]Asteroid Error : %s' % _error)
        finally:
            self.kill()

    @property
    def index(self):
        return self.__index

    @index.setter
    def index(self, index):
        if index >= len(self.images):
            # if Animation is not looping
            # kill it.
            if not self.loop:
                self.quit()
            else:
                self.__index = 0
        else:
            self.__index = index

    def update(self):

        if self.object_.alive():

            if self.dt > self.timing:

                if (len(self.images) / 2) - 1 < self.index < (len(self.images) / 2) + 1:
                    DamageDisplay(self.object_, 100, TIME_PASSED_SECONDS, 'EXP', timing_=33)

                self.image = self.images[self.index]
                # TESLA
                if self.override_method:
                    self.rect = self.image.get_rect(center=self.object_.rect.center)
                # OTHER
                else:
                    self.rect = self.image.get_rect(center=(self.object_.rect.midbottom[0],
                                                            self.object_.rect.midbottom[1] - 10))

                self.index += 1
                self.dt = 0

            # self._frame += 1
            self.dt += TIME_PASSED_SECONDS

        else:
            self.quit()


class Explosion1(pygame.sprite.Sprite):
    containers = None
    # keep a track of all objects
    inventory = []

    def __new__(cls, object_: Asteroid, timing_: int = 33, layer_: int = -1, *args, **kwargs):
        # return if an instance already exist.
        if object_ in Explosion1.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_: Asteroid, timing_: int = 33, layer_: int = -1):
        """ Control objects explosion """

        Explosion1.inventory.append(object_)

        pygame.sprite.Sprite.__init__(self, self.containers)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_:
                All.change_layer(self, layer_)

        # assert isinstance(object_, (Asteroid, Enemy)), \
        #    'Expecting Asteroid or Enemy class got %s ' % type(object_)

        self.object_ = object_

        if self.object_.hp < 1:
            self.images = self.object_.explosion_sprites
            self.image = self.images[0]
        else:
            # nothing to do here if the object
            # hit points are still above 0.
            self.quit()
            return

        self.rect = self.image.get_rect(center=self.object_.rect.center)
        self._frame = 0
        self.index = 0
        self.dt = 0
        self.timing = timing_

    def get_animation_index(self):
        return self.index

    def quit(self):
        try:
            if self.object_ in Explosion1.inventory:
                Explosion1.inventory.remove(self.object_)
        except (IndexError, ValueError) as _error:
            print('\n[-]Asteroid Error : %s' % _error)
        finally:
            self.kill()

    @property
    def index(self):
        return self.__index

    @index.setter
    def index(self, index):
        if index >= len(self.images):
            # Enemy exploding, check for combos
            ComboKill()
            self.quit()
            return
        else:
            self.__index = index

    def update(self):

        # set for 33 fps
        if self.dt > self.timing:

            # Explosions animations are already re-scale for asteroids.
            # Make sure this is ok for the other class of ENEMIES_RAPTOR.
            self.image = self.images[self.index]
            self.rect = self.image.get_rect(center=self.object_.rect.center)
            # Display the experience gained by the player.
            # The text will be display only once.
            # The message will be display approximately in the middle of
            # the explosion timing.
            if (len(self.images) / 2) - 1 < self.index < (len(self.images) / 2) + 1:
                DamageDisplay(self.object_, 100, TIME_PASSED_SECONDS, 'EXP', timing_=33)

            self.index += 1
            self.dt = 0

        self._frame += 1
        self.dt += TIME_PASSED_SECONDS


class PlayerLife:

    def __init__(self, object_: (Player, Asteroid)):
        """
        This class check the player health values after a collision with an object
        or after taking a hit (projectile). If health status is below zero, play a
        destruction sprite at the player location (life <0) or play an impact animation.
        If the player is killed, display the GAME OVER message.

        :param object_:
        """
        # assert isinstance(object_, (Player, Asteroid, EnemyShot, Enemy)), \
        #    'Expecting Player, Asteroids or EnemyShot class for argument object_ got %s ' % type(object_)
        self.object_ = object_

        # check if the shield is up and running
        if Shield.is_shield_up():
            Shield.images = ROUND_SHIELD_IMPACT
            Shield.shield_impact(damage_=object_.damage)
            # start a new instance (impact sprite)
            Shield(player_=player, loop_=False, timing_=15, event_='SHIELD_IMPACT')
            Shield.heat_glow(player.rect.clip(object_.rect))
        else:
            DamageControl(object_.rect)
            # Player has no shield.
            # send damage to player
            SHIP_SPECS.life -= object_.damage
            # Blend life hud with red
            # red quantity is proportional with the damage received.

            # global LIFE_HUD
            # try:
            #    LIFE_HUD = blend_texture_24bit(LIFE_HUD, object_.damage / SHIP_SPECS.max_health, (200, 0, 0, 255))
            # except ZeroDivisionError:
            #     raise ERROR("Player's maximum health has been set to zero,"
            #                " change it to a positive integer different to 0. ")

        # check if the player is still alive
        if int(SHIP_SPECS.life) <= 0:
            self.play_explosion_sound()
            self.explosion()
            self.game_over()
            player.kill()
            pygame.mixer.music.stop()
            # kill all sounds except EXPLOSION_SOUND_1
            SC_spaceship.stop_all_except(id(EXPLOSION_SOUND_1))
            for system, status in SHIP_SPECS.system_status.items():
                SHIP_SPECS.system_status[system] = (False, 0)

        else:

            if 151 < int(SHIP_SPECS.life) < 800:
                # check if the sound is already playing
                if not SC_spaceship.get_identical_sounds(HEART_SOUND):
                    SC_spaceship.play(sound_=HEART_SOUND, loop_=False, priority_=2, volume_=SOUND_LEVEL, fade_out_ms=0,
                                      panning_=False, name_='HEART', x_=0)  # note x=0 due to panning mode off





            GenericAnimation.images = BURST_UP_RED
            GenericAnimation(object_=self.object_, ratio_=None,
                             timing_=15, offset_=None, event_name_='IMPACT', loop_=False)

            self.play_impact_sound()

            Blast.image = BLAST1
            for r in range(2):
                Blast(self.object_, timing_=33)
                Blast.inventory.remove(id(self.object_))

            if id(self.object_) in Asteroid.inventory:
                Asteroid.inventory.remove(id(self.object_))

        self.object_.kill()

    @staticmethod
    def flame_effect():

        if 0 < int(SHIP_SPECS.life) < 200:
            # Create flame effect on the space ship
            ParticleFxFire(pygame.math.Vector2(0, 2), 30)
            Player.images = SPACESHIP_SPRITE_LAVA

            # automatic maintenance if hp < 200
            MicroBots.images = NANO_BOTS_CLOUD
            MicroBots(player, timing_=33)

        failure = False
        # check if any of the system status is False
        for system, status in SHIP_SPECS.system_status.items():
            if not status[0]:
                failure = True
                break

        if failure and player.alive():
            if not SC_spaceship.get_identical_sounds(ALARM_DESTRUCTION):
                SC_spaceship.play(sound_=ALARM_DESTRUCTION, loop_=True, priority_=2, volume_=SOUND_LEVEL,
                                  fade_out_ms=0, panning_=False, name_='ALARM', x_=0)
        else:
            SC_spaceship.stop_name('ALARM')

    @staticmethod
    def flash_effect():
        """ create a red and green lights on spaceship wings """
        if player.alive():
            global FLASH_COLOR
            if FLASH_COLOR is 1:
                FLASH_COLOR = 0
                Follower.images = [BRIGHT_LIGHT_BLUE] * 10
                Follower(offset_=(player.rect.centerx - 30, player.rect.centery + 15), timing_=10, loop_=False)
            else:
                FLASH_COLOR = 1
                Follower.images = [BRIGHT_LIGHT_RED] * 10
                Follower(offset_=(player.rect.centerx + 30, player.rect.centery + 15), timing_=10, loop_=False)

    @staticmethod
    def play_explosion_sound():
        """Play an explosion sound using the explosion class sound mixer SC. """
        SC_explosion.play(sound_=EXPLOSION_SOUND_1, loop_=False, priority_=0, volume_=SOUND_LEVEL, fade_out_ms=0,
                          panning_=False, name_='EXPLOSION_SOUND_1', x_=0)  # note x=0 due to panning mode off

    @staticmethod
    def play_impact_sound():
        """Play a loud impact sound using the explosion class sound mixer SC. """
        # do not play the impact sound
        # if the shield is up
        if not Shield.is_shield_up():
            SC_explosion.play(sound_=IMPACT2, loop_=False, priority_=0, volume_=SOUND_LEVEL, fade_out_ms=0,
                              panning_=False, name_='IMPACT2', x_=0)  # note, x=0 due to panning mode off

    @staticmethod
    def blast():
        """ Create a blast effect (player spaceship pieces flying around)
            after explosion or collision between two objects
            See blast class for more details.
        """
        if player.alive():
            if id(player) not in Blast.inventory:
                for r in range(6):
                    Blast.images = SPACESHIP_EXPLODE[r]
                    Blast(player, timing_=33)
                    if id(player) in Blast.inventory:
                        Blast.inventory.remove(id(player))
                Blast.images = BLAST1

    @staticmethod
    def explosion():
        """ Create an explosion effect when spaceship is destroy. """
        PlayerHalo.images = HALO_SPRITE8
        PlayerHalo(object_=player.rect, speed_=15, halo=HALO_NUCLEAR_BOMB)
        PlayerLife.blast()
        GenericAnimation.images = EXPLOSION10
        GenericAnimation(object_=player, ratio_=None, timing_=15, offset_=None, event_name_='GAME OVER', loop_=False)

    @staticmethod
    def game_over():
        """ Display the message game over"""

        font_ = freetype.Font(os.path.join(GAMEPATH + 'Assets\\Fonts\\', 'ARCADE_R.ttf'), size=72)
        font_.pad = True
        text_box = font_.render('GAME OVER.', style=freetype.STYLE_DEFAULT, size=72)
        box = text_box[1]
        x = (SCREENRECT.w - box.w) // 2
        y = (SCREENRECT.h - box.h) // 2

        font_.render_to(screen, (x, y), 'GAME OVER.',
                        (255, 255, 0), style=freetype.STYLE_DEFAULT, size=72)

        pygame.display.flip()

        font_.pad = False
        # global STOP_GAME
        # STOP_GAME = True


class Score:
    # Give a clue if the player
    # is currently leveling up or not
    level_up_state = False

    def __init__(self):
        pass

    def update(self, score_):
        """ Update the player score and experience.
            Initiate a level up if the player has gained enough experience.
        """
        # assert isinstance(score_, int), 'Expecting int for argument score_ got' \
        #                                ' %s ' % type(score_)
        SHIP_SPECS.score += score_
        SHIP_SPECS.experience += round(score_ / 10, 2)
        # Initiate a level up every 1000 experience points.
        # todo the level up could be done differently (not using a linear method)
        if SHIP_SPECS.experience // 1000 != SHIP_SPECS.level:
            self.level_up()

    @staticmethod
    def level_up_animation():
        """ Play a level up animation with sound effect using player sound mixer.
            Please note that the sound effect does not use the panning method.
        """
        # check if the player is already leveling up to avoid
        # playing two leveling up simultaneously.
        # Todo: Improve the method as the latest leveling up will be ignore
        if not Score.level_up_state:
            SC_spaceship.stop_name('LEVEL_UP')
            SC_spaceship.play(sound_=LEVEL_UP, loop_=False, priority_=0, volume_=SOUND_LEVEL, fade_out_ms=0,
                              panning_=False, name_='LEVEL_UP', x_=0)  # note x=0 due to panning mode off
            Score.level_up_state = False
            GenericAnimation.images = LEVEL_UP_5
            GenericAnimation(object_=player, ratio_=None, timing_=25, offset_=None, event_name_='LEVEL_UP', loop_=False)

    @staticmethod
    def level_up():
        """ Control the weapon class and change the global
            variable CURRENT_WEAPON and DEFAULT_WEAPON after leveling up
            Player weaponry system is always upgrading after a leveling up (single photon
            weapon type will upgrade to a double photon class etc).
        """
        global CURRENT_WEAPON, DEFAULT_WEAPON
        # Play animation
        Score.level_up_animation()
        SHIP_SPECS.level += 1

        # check to avoid crashing when player is reaching the last possible military rank.
        # Note, 'ranks' regroups all military ranks into a python list hold by SHIP_SPECS class.
        if SHIP_SPECS.level < len(SHIP_SPECS.ranks):
            SHIP_SPECS.rank = SHIP_SPECS.ranks[SHIP_SPECS.level]

        if CURRENT_WEAPON.level_up is not None:
            CURRENT_WEAPON = CURRENT_WEAPON.level_up
            DEFAULT_WEAPON = CURRENT_WEAPON


class TeslaEffect(pygame.sprite.Sprite):
    containers = None
    images = None
    shooting = False
    inventory = []

    def __new__(cls, timing_: int, group_: pygame.sprite.Group, target_, weapon_: Weapons, *args, **kwargs):
        # return if an instance already exist.
        if target_ in TeslaEffect.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)


    def __init__(self, timing_: int, group_: pygame.sprite.Group, target_, weapon_: Weapons):

        TeslaEffect.inventory.append(target_)

        pygame.sprite.Sprite.__init__(self, self.containers)

        # assert isinstance(self.images, list), \
        #    'Expecting list for argument images, got %s ' % type(self.images)
        # assert isinstance(timing_, int), \
        #    'Expecting int for argument timing_, got %s ' % type(timing_)

        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]

        self.rect = self.image.get_rect(
            midbottom=(SCREENRECT.center[0], SCREENRECT.center[1] - 500))

        self.timing = timing_
        self.weapon = weapon_
        # sprite orientation
        self.rotation = 90
        self.group = group_
        # target (belong to a group)
        self.target = target_
        self.index = 0
        self.dt = 0

        # TFT (Tesla Field Target)
        # II (Impact Target)
        self.TFT, self.IT = None, None

        # Turret shooting flag
        TeslaEffect.shooting = True

        # Create Tesla magnetic field around the target
        # This instance will be started only once
        self.tesla_field(self.target)
        self.impact_effect(self.target)

    def tesla_field(self, target):
        """
        Create a Tesla magnetic field around the target
        :param target: Target object
        :return:
        """
        if target.alive():
            # ELECTROMAGNETIC FIELD EFFECT
            GenericAnimation.images = BEAM_FIELD
            # The animation is looping back until kill signal received or object
            # no longer exists.
            self.TFT = GenericAnimation(object_=target, ratio_=None,
                                        timing_=15, offset_=None, event_name_='BEAM_FIELD', loop_=True)

    def kill_tesla_field(self):
        """
        Kill the Tesla magnetic field
        :return:
        """
        # kill the tesla field effect associated
        # to the instance if the target is still alive
        if self.target.alive():
            GenericAnimation.kill_event(self.TFT)

    def impact_effect(self, target):
        """
        Create Tesla impact sprite on target
        :param target:
        :return:
        """
        if target.alive():
            # Load sprite animation TESLA_IMPACT
            ImpactBurst.images = TESLA_IMPACT
            # display impact sprite animation
            self.IT = ImpactBurst(target, override_method=True, loop_=True, timing_=33, rect_=None, layer_=-2)

    def kill_impact_effect(self):
        """
        Kill the Tesla impact sprite
        :return:
        """
        if self.target.alive():
            ImpactBurst.kill_event(self.IT)

    @property
    def index(self):
        return self.__index

    @index.setter
    def index(self, index):
        if isinstance(self.images, list):
            if index >= len(self.images):
                # loop the sprite
                self.__index = 0
            else:
                self.__index = index

    def quit(self):
        try:
            # clean the inventory
            if self.target in TeslaEffect.inventory:
                TeslaEffect.inventory.remove(self.target)
            # kill sound effect
            SC_spaceship.stop_object(id(self.target))
            self.kill_tesla_field()
            self.kill_impact_effect()

        except (IndexError, ValueError) as _error:
            print('\n[-]TeslaEffect Error : %s' % _error)
        finally:
            TeslaEffect.shooting = False
            self.kill()

    def update(self):
        # Tesla effect as long has player and target are still alive
        if player.alive() and self.target.alive():

            # kill the sprite when the Tesla sound effect is finish
            if not SC_spaceship.show_time_left(id(self.target)) > 0:
                self.quit()

            if Turret.initialised:

                if self.dt > self.timing:

                    # check if the spaceship have enough energy
                    if SHIP_SPECS.energy > self.weapon.energy:

                        if hasattr(self.target, 'hit'):
                            self.target.hit(object_=self.target, weapon_=self.weapon, bomb_effect_=False)
                            SHIP_SPECS.energy -= self.weapon.energy

                        location = player.rect.center

                        self.rect = self.image.get_rect(midbottom=location)

                        if self.target:

                            dx = self.target.rect.centerx - location[0]
                            dy = self.target.rect.centery - location[1]

                            # -------------------------------------
                            rotation = atan2(dy, dx) * RAD_TO_DEG

                            if rotation > 0:
                                rotation = rotation - 360
                            rotation = -rotation
                            angle = (rotation - self.rotation) % 360
                            # --------------------------------------------
                            self.image = pygame.transform.rotozoom(self.images_copy[self.index], angle, 1)
                            self.image = pygame.transform.smoothscale(self.image,
                                                                      (int(abs(dx)), int(abs(dy))))

                            self.rect = self.image.get_rect(center=location)
                            w, h = self.image.get_bounding_rect(128).w, self.image.get_bounding_rect(128).h

                            bounding_rect = self.image.get_bounding_rect(128)
                            # todo see if this can be done differently
                            if 0 < rotation < 180:
                                # right
                                if dx > 0:

                                    self.rect = self.image.get_rect(bottomleft=(
                                        location[0] - (
                                                self.rect.w - w) // 2 + 4,
                                        location[1] + (self.rect.h - h) // 2
                                    ))
                                    bounding_rect.bottomleft = location
                                # left
                                else:
                                    self.rect = self.image.get_rect(bottomright=(
                                        location[0] + (
                                                self.rect.w - w) // 2 + 4,
                                        location[1] + (
                                                self.rect.h - h) // 2 - 2
                                    ))

                                    bounding_rect.bottomright = location
                            else:
                                # right
                                if dx > 0:
                                    self.rect = self.image.get_rect(topleft=(
                                        location[0] - (
                                                self.rect.w - w) // 2 - 4,
                                        location[1] - (
                                                self.rect.h - h) // 2 + 4
                                    ))
                                    bounding_rect.topleft = location
                                # left
                                else:
                                    self.rect = self.image.get_rect(topright=(
                                        location[0] + (self.rect.w - w) // 2 - 4,
                                        location[1] - (self.rect.h - h) // 2 - 4
                                    ))
                                    bounding_rect.topright = location

                        self.dt = 0
                        self.index += 1

                    else:
                        self.quit()

                self.dt += TIME_PASSED_SECONDS
        else:
            self.quit()


"""
class Shot(pygame.sprite.Sprite):
    containers = None

    def __init__(self, pos_: tuple, weapon_: Weapons, mute_: bool, offset_x: int, offset_y: int, timing_:int = 30):
        
        #:param pos_: tuple representing the space ship location (x,y)
        #:param weapon_: Weapon class, define the weapon currently used by the player.
        #                Weapon class is personalized and has specific attributes for each weapons type
        #                e.g speed, power, sound effect and sprite link to it. See Weapons.py for more info
        #:param mute_:   boolean. Determine if the sound is muted or not for the current shot (this is useful for
        #                weapons that shot more than one particle at once).
        #:param offset_x: integer, Offsetx from the center of the player rect
        #:param offset_y: integer, Offsety from the center of the player rect (shot with offset from center like
        #                multiple shots do)
        

        
        # REMOVED for few ms performance gain  
        assert isinstance(pos_, tuple), 'Argument <pos_> should be a tuple, got: ' \
                                        + str(type(pos_))
        assert isinstance(weapon_, Weapons), ' Expecting Weapon class got : %s ' % type(weapon_)
        assert isinstance(mute_, bool), ' Expecting boolean for argument mute_ got : %s ' % type(mute_)
        assert isinstance(offset_x, int), ' Expecting integer for argument offset_x got : %s ' % type(offset_x)
        assert isinstance(offset_y, int), ' Expecting integer for argument offset_y got : %s ' % type(offset_y)
        
        pygame.sprite.Sprite.__init__(self, self.containers)

        # ------ load weapon specs --------------
        self.weapon = weapon_
        self.images = weapon_.sprite.copy()

        # Loading sprite(s)
        if isinstance(self.images, list):
            if len(self.images) > 0:
                self.image = weapon_.sprite[0]
        else:
            self.image = weapon_.sprite

        self.speed = weapon_.velocity

        # projectile's offset from the center
        self.offset_x = offset_x
        self.offset_y = offset_y

        # Assign the offset
        self.pos = (pos_[0] + self.offset_x, self.offset_y)  # pos_[1])
        self.rect = self.image.get_rect(midbottom=self.pos)

        # -------------------------------------------
        self.index = 0
        # self.__index = 0
        # self.frame = 1
        self._id = id(self)
        self.dt = 0
        self.timing = timing_

        if not mute_:
            # -------------- load sound effect ----------
            self.sound = self.weapon.sound_effect
            SC_spaceship.stop_name(weapon_.name)

            # stop the sound
            if len(SC_spaceship.get_identical_sounds(self.sound)):
                SC_spaceship.stop_name(self.weapon.name)

            # fadeout the sound effect at 75% of his total length
            self.channel = SC_spaceship.play(sound_=self.sound, loop_=False, priority_=0, volume_=self.weapon.volume,
                                             fade_out_ms=0, panning_=True, name_=self.weapon.name, x_=pos_[0],
                                             object_id_=self._id)

        else:
            # Sound is muted for this dummy shot
            # we do not need to play the sound more than once when
            # using weapons with double, quadruple, sextuple shots.
            self.channel = None

        # ----------- Particles effect ---------------------------------
        # Particle effect for photon weapons,
        # distribute light particle(s) randomly along the super shot (photon)
        # No particle effect for (bullet, rocket) type weapon
        if weapon_.type_ != 'BULLET':
            ParticleFx.rectangle = self.rect
            if weapon_.units == 'SUPER':
                particles = randint(4, 10)
            else:
                # particles = randint(0, 1)
                # Not particle effect for normal shot
                particles = 0

            # ParticleFx.images = WEAPON_COLOR[weapon_.color_]
            
            #if weapon_.type_ == 'ELECTRIC':
            #    ParticleFxElectrical.images = ParticleFx.images
            #    ParticleFxElectrical.source = Color(weapon_.color_)
            #    ParticleFxElectrical.destination = Color('red')
            #    ParticleFxElectrical.rectangle = self.rect
            #    ParticleFxElectrical.offset_x = self.offset_x
            #    ParticleFxElectrical.offset_y = self.offset_y
            #    for _i in range(10):
            #        ParticleFxElectrical()
            #else:
            
            ParticleFx.images = PHOTON_PARTICLE_1
            ParticleFx.SCREENRECT = SCREENRECT
            for number_ in range(particles):
                ParticleFx(TIME_PASSED_SECONDS)

            # Rotate the sprite before
            # displaying it
            self.choose_image(self.image)

    def center(self):
        # return the centre coordinate  
        return self.rect.center

    def location(self):
        # return a Rect 
        return self.rect

    def get_animation_index(self):
        return self.index

    def choose_image(self, surface_):
        
        #Rotate a sprite
        #:param surface_: Sprite to rotate
        
        self.image = eval(WEAPON_ROTOZOOM[self.offset_x])

    def move(self, speed_):
        
        #Move a sprite according to the offset
        #from spaceship center.
        #:param speed_: Shot speed
        
        eval(WEAPON_OFFSET_X[self.offset_x])

    @property
    def index(self):
        return self.__index

    @index.setter
    def index(self, index):
        if isinstance(self.images, list):
            if index >= len(self.images):
                self.__index = 0
            else:
                self.__index = index
        else:
            self.__index = index

    def update(self):
        # self.frame % ceil(25 / (TIME_PASSED_SECONDS + 0.01)) == 0:
        if self.dt > 30:
            # Animation
            if isinstance(self.images, list):
                self.image = self.images[self.index]

            # Player spaceship debris
            if self.weapon.name == 'RED_DEBRIS_SINGLE':
                self.rect.center += self.speed * 2
                self.image = pygame.transform.rotozoom(self.images.copy(), self.index, 1)

            else:
                self.move(self.speed)

            self.index += 1

            if not self.rect.colliderect(SCREENRECT):
                self.kill()
                return
            self.dt = 0

        self.dt += TIME_PASSED_SECONDS
        # self.frame += 1

"""


class DamageControl:
    SYS = ['LW', 'SUPER', 'RW', 'RE', 'LE', 'RE']

    def __init__(self, object_: pygame.Rect):
        # todo need to check all the rects
        left_wing = pygame.Rect(player.rect.topleft[0], player.rect.topleft[1], 18, player.rect.h)
        right_wing = pygame.Rect(player.rect.topright[0] - 18, player.rect.topright[1], 18, player.rect.h)
        engine_left = pygame.Rect(player.rect.midbottom[0] - 13, player.rect.midbottom[1] - 19, 13, 19)
        engine_right = pygame.Rect(player.rect.midbottom[0], player.rect.midbottom[1] - 19, 13, 19)
        top = pygame.Rect(player.rect.midtop[0] - 13, player.rect.midtop[1], 26, 20)
        impacts = object_.collidelistall([left_wing, top, right_wing, engine_left, engine_right])
        for system in impacts:
            self.damages(self.SYS[system])

        # print(SHIP_SPECS.system_status)

    @staticmethod
    def damages(system):
        status = SHIP_SPECS.system_status[system]

        if status[0]:
            system_integrity = status[1] - 25
            if system_integrity <= 25:
                SHIP_SPECS.system_status[system] = (False, 0)
            else:
                SHIP_SPECS.system_status[system] = (True, system_integrity)


class DisplayScore(pygame.sprite.Sprite):

    def __init__(self, timing_):
        pygame.sprite.Sprite.__init__(self, self.containers)
        self.dt = 0
        self.image = None
        self.image = self.images
        self.rect = pygame.Rect(10, 10, 10, 10).move(300, 10)
        self.timing = timing_

    def update(self):
        if self.dt > self.timing:
            font_ = pygame.font.Font(
                os.path.join(GAMEPATH, "Assets\\Fonts", 'ARCADE_R.ttf'), 15)
            self.image = font_.render('Score ' + str(SHIP_SPECS.score), True, (255, 255, 0))
            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


class DisplayNukesLeft(pygame.sprite.Sprite):
    images = NUKE_BOMB_INVENTORY.copy()

    def __init__(self, timing_: int = 33):
        pygame.sprite.Sprite.__init__(self, All)
        self.dt = 0
        self.image = DisplayNukesLeft.images.copy()
        self.rect = pygame.Rect(20, 85, 96, 32)
        self.timing = timing_

    def update(self):
        if self.dt > self.timing:
            # self.image = font_.render('Score ' + str(SHIP_SPECS.score), True, (255, 255, 0))
            new_image = pygame.Surface((96, 32), 24).convert()
            new_image.blit(DisplayNukesLeft.images, (0, 0), (0, 0, 32 * SHIP_SPECS.nukes, 32))
            new_image.set_colorkey((0, 0, 0, 0), pygame.RLEACCEL)
            self.image = new_image
            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


class DisplayMissilesLeft(pygame.sprite.Sprite):
    images = MISSILE_INVENTORY.copy()

    def __init__(self, timing_: int = 33):
        pygame.sprite.Sprite.__init__(self, All)
        self.dt = 0
        self.image = DisplayMissilesLeft.images.copy()
        self.rect = self.image.get_rect(topleft=(SCREENRECT.w - DisplayMissilesLeft.images.get_width(), 85))
        self.font_ = freetype.Font(os.path.join(GAMEPATH + 'Assets\\Fonts\\', 'ARCADE_R.ttf'), size=12)
        self.h_ = self.font_.get_sized_height()
        self.timing = timing_

    def update(self):
        if self.dt > self.timing:
            # pygame.draw.rect()
            self.image = DisplayMissilesLeft.images.copy()
            self.font_.render_to(self.image,
                                 (0, (DisplayMissilesLeft.images.get_height() - self.h_) // 2),
                                 str(SHIP_SPECS.missiles) + 'x', fgcolor=(220, 198, 12), bgcolor=(10, 10, 36))

            self.image.set_colorkey((0, 0, 0, 0), pygame.RLEACCEL)

            self.dt = 0

        self.dt += TIME_PASSED_SECONDS


class EnemyShot(pygame.sprite.Sprite):
    containers = None

    def __init__(self, pos_: tuple,
                 weapon_: EnemyWeapons,
                 mute_: bool,
                 offset_: tuple,
                 vector_: pygame.math.Vector2,
                 angle_: int, spaceship_aim_: float,
                 rect_: pygame.Rect,
                 timing_: int = 33):

        # :param pos_: Tuple corresponding to the laser turret location (eg rect.center, rect.midleft etc)
        # :param weapon_: class EnemyWeapon. The class hold all the weapon settings.
        # :param mute_: Bool for muting a sound when more than one laser is shoot at the time. eg double laser
        # :param offset_: Offset to add to the turret location
        # :param vector_: Laser direction
        # :param angle_: angle corresponding to the laser direction (used for rotating the shot sprite in degrees)
        # :param spaceship_aim_:  Enemy spaceship angle (aiming direction) in radian
        # :param rect_: pygame rect used for calculation
        """
        assert isinstance(pos_, tuple), 'Expecting a tuple for argument got: %s ' % type(pos_)
        assert isinstance(weapon_, EnemyWeapons), \
            'Expecting EnemyWeapons class for argument weapon_ , got: %s ' % type(weapon_)
        assert isinstance(mute_, bool), \
            'Expecting boolean for argument mute_ got : %s ' % type(mute_)
        assert isinstance(offset_, tuple), \
            'Expecting tuple for argument offset_ got : %s ' % type(offset_)
        assert isinstance(vector_, pygame.math.Vector2), \
            'Expecting pygame.math.Vector2 for argument vector_ got : %s ' % type(vector_)
        assert isinstance(angle_, int), \
            'Expecting int for argument angle_ got : %s ' % type(angle_)
        assert isinstance(spaceship_aim_, float), \
            'Expecting float for argument spaceship_aim_ got : %s ' % type(spaceship_aim_)
        assert isinstance(rect_, pygame.Rect), \
            'Expecting pygame.Rect for argument rect_ got : %s ' % type(rect_)
        """
        pygame.sprite.Sprite.__init__(self, self.containers)

        # Weapon class
        self.weapon = weapon_

        # Extract the damage variable
        self.damage = weapon_.damage

        # Sprite (single image or animation)
        self.images_copy = self.weapon.sprite.copy()
        self.image = self.images_copy[0] if isinstance(self.images_copy, list) else self.images_copy

        # self.image = pygame.transform.rotozoom(self.image, angle_, 1)
        self.image = pygame.transform.rotate(self.image, angle_)

        # Laser speed 2d vector defined by the weapon class
        self.speed = weapon_.velocity
        # Laser vector 2d normalized (laser direction)
        self.vector = vector_

        dx = pos_[0] - rect_.centerx
        dy = pos_[1] - rect_.centery

        if dx != dy:
            org_angle = atan2(dy, dx)
            if org_angle < 0:
                org_angle += pi
            # Laser position 2d vector.
            # Calculate the laser position
            self.pos = pygame.math.Vector2(rect_.centerx +
                                           cos(org_angle + spaceship_aim_ - 3 * pi / 2) * (rect_.w - offset_[0]) // 2,
                                           rect_.centery - sin(org_angle + spaceship_aim_ - 3 * pi / 2) * rect_.h // 2)
        else:
            self.pos = pygame.math.Vector2(rect_.center)

        self.rect = self.image.get_rect(center=self.pos)

        # index for sprite animation
        self.index = 0
        # Time constant
        self.dt = 0
        # shot id
        self.timing = timing_

        if not mute_:
            if SC_spaceship.get_identical_sounds(self.weapon.sound_effect):
                SC_spaceship.stop_object(id(self.weapon.sound_effect))
            SC_spaceship.play(sound_=self.weapon.sound_effect, loop_=False, priority_=0,
                              volume_=self.weapon.volume, fade_out_ms=0, panning_=True,
                              name_=self.weapon.name, x_=self.rect.centerx)

    def location(self):
        # return the rect for external class 
        return self.rect

    @property
    def index(self):
        return self.__index

    @index.setter
    def index(self, index):
        if isinstance(self.images_copy, list):
            if index >= len(self.images_copy):
                self.__index = 0
                return
        self.__index = index

    @staticmethod
    def get_distance(p1_: pygame.math.Vector2, p2_: pygame.math.Vector2) -> float:
        """ Get the distance between two points """
        return (p2_ - p1_).length()

    def update(self):

        if self.dt > self.timing:

            # Animation
            if isinstance(self.images_copy, list):
                self.image = self.images_copy[self.index]
                self.index += 1

            self.pos += self.vector * self.speed.length()
            self.rect.center = self.pos

            if not self.rect.colliderect(SCREENRECT):
                self.kill()
                return

            self.dt = 0

            if self.alive():
                # Adding all sprites into the collision group
                COLLISION_GROUP.add(self)
                # inverted logic
                # removing the sprite from the group if the distance is over the collision radius.
                if (self.pos - player.position).length() > COLLISION_RADIUS:
                    COLLISION_GROUP.remove(self)

        self.dt += TIME_PASSED_SECONDS


class Enemy(pygame.sprite.Sprite):
    images = None
    initialized = False

    def __init__(self, enemy_: EnemyClass, timing_=35, layer_: int = -2):

        pygame.sprite.Sprite.__init__(self, All)

        if layer_:
            if isinstance(All, pygame.sprite.LayeredUpdates):
                All.change_layer(self, layer_)

        # load the object path.
        # The path is a numpy.array containing
        # a set of coordinates (x,y).
        # This are the reference points,
        # later on, a Bezier curve will be created
        # with these coordinates.
        self.path = enemy_.path

        # Reference to the class
        # self.enemy_ is useful for
        # retrieving all variables from the class
        self.enemy_ = enemy_

        self.images_copy = Enemy.images.copy()
        self.image = self.images_copy[0] if isinstance(Enemy.images, list) \
            else self.images_copy

        # Create a numpy array containing waypoints.
        # This is a Bezier curve that represent the enemy path.
        # The list is build with 100 coordinates (default value).
        # accuracy can be changed by passing an argument to the function bezier_curve,
        # e.g Enemy.bezier_curve(self.path[:, 0], self.path[:, 1], n_times_=50)
        # for 50 coordinates.
        # todo: look into the Bezier algorithm to avoid the for r in loop (also all the values are reversed
        self.waypoint_list = []

        # Reverse the waypoint
        self.path = self.path[::-1]

        self.waypoint_list_ = Enemy.bezier_curve(self.path[:, 0], self.path[:, 1], n_times_=20)
        for r in list(zip(self.waypoint_list_[0], self.waypoint_list_[1])):
            self.waypoint_list.append(r)

        # self.rect = self.image.get_rect(center=self.waypoint_list[0])
        self.rect = self.image.get_rect(center=self.enemy_.pos)

        if self.enemy_.strategy is 'PATH':
            # Calculate the last waypoint
            self.max_waypoint = len(self.waypoint_list)
            # Index on the first waypoint
            self.waypoint = 0

            # Create vectors for vessel direction
            # Vessel speed and direction will be calculated
            # with two points from the Bezier curve.
            self.vector1 = pygame.math.Vector2()
            self.vector2 = pygame.math.Vector2()

            # vector is the vessel direction and speed
            self.vector = self.new_vector()

            # Waypoint_list coordinates are numpy_array format and
            # needs to be converted to vector2d to allow vector calculation
            # position is the vessel coordinates
            # self.position = pygame.math.Vector2(list(self.waypoint_list[0]))

            self.position = pygame.math.Vector2(self.enemy_.pos)
        else:
            # todo : need to implement other strategy
            # math vector2d
            self.position = self.enemy_.pos
            self.max_waypoint = 2
            # Index on the first waypoint
            self.waypoint = 0

        # how many degrees the sprite need to be rotated clockwise
        # in order to be oriented/align with a zero degree angle.
        self.spaceship_aim_offset = self.enemy_.sprite_orientation
        # aim angle right at the start
        self.spaceship_aim = -self.spaceship_aim_offset  # inverted to get the right angle

        if self.enemy_.strategy is 'PATH':
            # set the spaceship angle
            self.enemy_rotation_path()

        # timing constant
        # timing should be high for fast aircraft
        # and low for slow ones
        self.dt = timing_

        # laser timer
        self.timer = 0

        # enemy has a lock-on
        # Lock on is automatically set to True
        # when the enemy spaceship angle is in the tolerance
        # area of +/- 5 degrees (True trigger shots)
        self.lock_on = False

        # Enemy life points
        self.hp = self.enemy_.hp

        self.index = 0

        # ---   for compatibility with other class ---
        self.explosion_sprites = enemy_.explosion_sprites
        self.impact_sprite = enemy_.impact_sprite
        self.impact_sound = enemy_.impact_sound
        self.damage = enemy_.collision_damage

        self.evasive = False

    def location(self):
        # return the rect for external class 
        return self.rect

    @property
    def waypoint(self):
        return self.__waypoint

    @waypoint.setter
    def waypoint(self, waypoint):
        if waypoint >= self.max_waypoint - 1:
            self.__waypoint = 0
            # the aircraft stop moving at
            # the last waypoint.
            self.vector.x, self.vector.y = (0, 0)
            # self.quit()
            self.evasive = False
        else:
            self.__waypoint = waypoint

    def __next__(self) -> list:
        # Return the next waypoint from the
        # the Bezier curve.
        # Loop back to index 0 when the end of
        # the list is reached.
        try:
            item = self.waypoint_list[self.waypoint]
        except IndexError:
            self.waypoint = 0
            item = self.waypoint_list[0]
        self.waypoint += 1
        return item

    def get_line_coefficient(vector: pygame.math.Vector2, position: pygame.math.Vector2):

        # Calculate regression coefficient (slope) and slope-intercept
        # of a line (y = mx + k or y = mx - k) from a given direction
        # and vector position (x, y).
        # m = Δy/Δx and k = Δy - m.x
        # :param vector:
        # :param position:

        # assert isinstance(vector, pygame.math.Vector2), \
        #    'Expecting pygame.math.Vector2 for argument vector got %s ' % type(vector)
        # assert isinstance(position, pygame.math.Vector2), \
        #    'Expecting pygame.math.Vector2 for argument coordinates got %s ' % type(position)

        # check if the vector is null,
        # if the vector is null return None (no solution).
        if vector == (0, 0):
            m, k = None, None
        else:
            # Vertical line slope is undifined.
            # Horizontal line slope is zero.
            m = vector.y / vector.x if vector.x != 0 else 0
            # next point after vector increment
            point2 = position + vector
            k = point2.y - m * point2.x
        # (y = mx + k or y = mx - k)
        # NOTE: -y = -mx -k (Y-axis is inverted)
        return m, k

    @staticmethod
    def get_intercept_coordinates(c1: tuple, c2: tuple):

        # Return point of intersection if lines intersect else return None.
        # This method is working only for moving objects.
        # x = Δk/Δm and (y = m1 * x + k1 or y = m2 * x + k2)

        # assert isinstance(c1, pygame.math.Vector2), \
        #     'Expecting pygame.math.Vector2 for argument c1 got %s ' % type(c1)
        # assert isinstance(c2, pygame.math.Vector2), \
        #    'Expecting pygame.math.Vector2 for argument c2 got %s ' % type(c2)
        # Δm is zero -> horizontal or parallel lines
        run = c1[0] - c2[0]
        if run == 0:
            return None
        else:
            x_intercept = (c2[1] - c1[1]) / run
            y_intercept = c1[0] * x_intercept + c1[1]
        return x_intercept, y_intercept

    def keep_distance(self):

        # EXPERIMENTAL
        # Enemy spaceship will try to keep distance from the player location.
        # A new path will be generated with Bezier curve using 3 points (representing
        # the direction in space and time).
        # First point is the enemy spaceship withdrawing from current location.
        # The second point is the enemy aircraft colliding with the screen (after
        # flying in the opposite direction to the player spaceship).
        # The last point is the reflected vector (bounce back from the screen edge).

        # if the aircraft is already performing
        # an evasive maneuver -> exit
        # if self.evasive:
        #    return

        if self.distance_to_player(player) < self.enemy_.safe_distance:

            # self.vector is the vector direction
            # self.position is a vector2d representing the
            # aircraft's coordinates in space
            # check if the player is not static else exit
            vector1 = pygame.math.Vector2()
            if player.vector != (0, 0):
                # same direction to avoid player
                if self.rect.centerx < player.vector.x:
                    vector1.x = -player.vector.x
                else:
                    vector1.x = player.vector.x

                vector1 = pygame.math.Vector2(player.vector.x, -abs(player.vector.y)).normalize()
            else:
                # player is not moving not need
                # to create an evasive path.
                return None

            # Evasive action is registered
            self.evasive = True
            # origin
            point1 = self.position
            # scale vector1 with the enemy aircraft speed
            vector1 *= self.enemy_.speed.length()
            # Speed should not be zero.
            assert vector1 != 0, \
                'Enemy speed should not be zero in an evasive maneuver'
            vector1.scale_to_length(50 * vector1.length())
            point2 = self.position + vector1
            point3 = point2 + pygame.math.Vector2(vector1.x, -vector1.y)
            path = numpy.array([[point1[0], point1[1]], [point2[0], point2[1]], [point3[0], point3[1]]])

            waypoint_list = []
            waypoint_list_ = Enemy.bezier_curve(path[:, 0], path[:, 1], n_times_=30)

            numpy.putmask(waypoint_list_, waypoint_list_ < 0, 0)
            numpy.putmask(waypoint_list_, waypoint_list_ > 800, 800)
            for r in list(zip(waypoint_list_[0], waypoint_list_[1])):
                waypoint_list.append(r)
            self.waypoint = 0
            self.max_waypoint = len(waypoint_list)
            self.vector = self.new_vector()
            self.waypoint_list = waypoint_list
            return waypoint_list

    @staticmethod
    def show_arbitrary_path(waypoint_list):
        if waypoint_list:
            for point in waypoint_list:
                pygame.draw.rect(screen, (255, 255, 0, 0), (point[0] - 5, point[1] - 5, 10, 10), 2)

    def show_waypoint(self):
        # show all the Bezier curve coordinates(points).
        # All points will be represented by a 'pygame.rectange'
        # with 10 pixels diameters(yellow).
        # This method is used only for debugging purpose.
        for point in self.waypoint_list:
            pygame.draw.rect(screen, (255, 255, 0, 0), (point[0] - 5, point[1] - 5, 10, 10), 2)

    def is_waypoint_passed(self):

        # This method checks if the enemy spaceship is colliding with one of the many
        # waypoint from the Bezier curve (point are represented by hidden rectangle).
        # Use the method show_waypoint to highlight the enemy path for debugging.
        # If the spaceship touch a waypoint then the next one is loaded and a new
        # speed/direction vector is calculate

        # create a dummy rectangle placed in the center
        # of the enemy sprite (60 pixels diameter).
        rect = pygame.Rect(self.rect.centerx - 30, self.rect.centery - 30, 60, 60)

        # debugging only
        # pygame.draw.rect(screen, (255, 0, 0, 0), rect, 4)

        # check for collision between rectangles
        if rect.collidepoint(self.waypoint_list[self.waypoint]):
            if self.waypoint < self.max_waypoint:
                # next direction vector calculation
                self.vector = self.new_vector()
                # keep the aircraft aiming in the right direction
                self.enemy_rotation_path()

                self.waypoint += 1
            else:
                # kill the sprite
                # self.quit()
                pass

    def tracking_vector(self) -> pygame.math.Vector2:

        # Track the Enemy spaceship position and adjust its vector direction
        # in function of the active waypoint coordinates.
        # This method is very useful in the situation where an alien spaceship is blown away
        # from its path, it will resume its course from the last known waypoint.

        # :return: Return a new vector direction to get to the next waypoint

        # current aircraft coordinates
        self.vector1.x, self.vector1.y = self.rect.center  # position vector
        # load active waypoint (destination)
        self.vector2.x, self.vector2.y = self.waypoint_list[self.waypoint]  # position vector

        # direction vector in order
        # to reach the active waypoint
        vector = self.vector2 - self.vector1

        if vector != (0, 0):
            factor = self.enemy_.speed.length() / (vector.normalize()).length()
            return vector.normalize() * factor
        else:
            return vector

    def new_vector(self) -> pygame.math.Vector2:

        # Similar as tracking_vector but update the direction vector
        # each time the aircraft is reaching a waypoint.
        # :return: Return a new direction vector.

        # current coordinates
        self.vector1.x, self.vector1.y = self.rect.center
        # load the next waypoint
        # Below line could be replaced using the method __next__ instead
        # self.vector2.x, self.vector2.y = next(self)
        if self.waypoint < self.max_waypoint - 2:
            self.vector2.x, self.vector2.y = self.waypoint_list[self.waypoint + 1]
        else:
            # no more waypoint
            # kill the sprite
            # self.quit()
            pass

        # Calculate the vector corespondent to the direction between
        # point 1 and point 2 (normalized).

        # ValueError: Can't normalize Vector of length Zero
        # length zero would mean that the enemy spaceship position
        # is right on the top of the next waypoint.
        # To avoid this issue we are loading the next waypoint until
        # the aircraft location clears up.
        vector = self.vector2 - self.vector1
        if vector != (0, 0):
            factor = self.enemy_.speed.length() / (vector.normalize()).length()
            return vector.normalize() * factor
        else:
            self.waypoint += 1
            return vector

    @staticmethod
    def bernstein_poly(index: int, n: float, t: numpy.array) -> list:
        # The Bernstein polynomial of n, index as a function of t.
        return comb(n, index) * (t ** (n - index)) * (1 - t) ** index

    @staticmethod
    def bezier_curve(x_points: numpy.array, y_points: numpy.array, n_times_: int = 30) -> numpy.array:

        # Given a set of control points, return the
        # bezier curve defined by the control points.
        # n_times_ is the number of time steps, defaults to 100

        n_points = len(x_points)
        t = numpy.linspace(0.0, 1.0, n_times_)
        polynomial_array = numpy.array([Enemy.bernstein_poly(i, n_points - 1, t) for i in range(0, n_points)])
        # numpy array with dtype int16 variables (to avoid rounding up values).
        new_array = numpy.dot([x_points, y_points], polynomial_array).astype(dtype=numpy.int16)
        return new_array

    def distance_to_player(self, player_) -> float:
        # Return the distance to the player location 
        # assert isinstance(player_, Player), \
        #    'Expecting player class for argument player got %s ' % type(player)
        # return the distance in pixels (float) to the player (centre to centre)
        return round((pygame.math.Vector2(player_.rect.center) - self.position).length(), 2)

    @staticmethod
    def get_distance(p1_: pygame.math.Vector2, p2_: pygame.math.Vector2) -> float:
        # Get the distance between two points 
        # Almost similar than method distance_to_player but use
        # two points in space instead (no reference to the player class location).
        return (p2_ - p1_).length()

    @staticmethod
    def rot_center(image_: pygame.Surface, angle_: (int, float), rect_) -> (pygame.Surface, pygame.Rect):
        # rotate an image while keeping its center and size (only for symmetric surface)
        # assert isinstance(image_, pygame.Surface), \
        #    ' Expecting pygame surface for argument image_, got %s ' % type(image_)
        # assert isinstance(angle_, (int, float)), \
        #     'Expecting int or float for argument angle_ got %s ' % type(angle_)
        # new_image = pygame.transform.rotozoom(image_, angle_, 1)
        new_image = pygame.transform.rotate(image_, angle_)
        return new_image, new_image.get_rect(center=rect_.center)

    def enemy_rotation_path(self):
        # Automatic correction of the aircraft trajectory according
        # to its current path (current waypoint).
        # Change also lock-on value (allowed to shoot) if the player is in the FOV.

        # This is the direction vector angle
        angle_rad = int(-atan2(self.vector.y, self.vector.x) * RAD_TO_DEG)

        # do not correct the trajectory if the angle is close enough
        if not (angle_rad - 2 < self.spaceship_aim < angle_rad + 2):
            # Spaceship aiming straight forward along its path
            self.spaceship_aim = angle_rad

        # Angle between the player and the enemy ship.
        diff_angle = int(-atan2(player.rect.centery - self.rect.centery,
                                player.rect.centerx - self.rect.centerx) * RAD_TO_DEG)

        if not (abs(diff_angle) - abs(angle_rad) < self.enemy_.fov // 2):
            self.lock_on = False
        else:
            self.lock_on = True

    def enemy_rotation(self):

        #    Aiming direction calculation.
        #    The spaceship is always facing its target independently of its direction

        # Enemy aiming direction function to the player location.
        # Enemy spaceship always facing the player location.
        # Aim tolerance +/- 5 degrees

        angle_rad = int(-atan2(player.rect.centery - self.rect.centery,
                               player.rect.centerx - self.rect.centerx) * RAD_TO_DEG)
        # all values from 0 to 360
        if angle_rad < 0:
            angle_rad = 360 - abs(angle_rad)

        left = (self.spaceship_aim - angle_rad) % 360
        right = 360 - left
        # find the shortest angular distance
        rotation_step = -self.enemy_.rotation_speed if left < right else self.enemy_.rotation_speed

        # capping the spaceship angle (max 360 degrees)
        self.spaceship_aim %= 360

        # Angle search tolerance
        # The enemy spaceship will stop rotating if in +/- 5 degrees
        # tolerance zone.
        if not (angle_rad - 5 < self.spaceship_aim < angle_rad + 5):
            self.spaceship_aim += rotation_step
            self.lock_on = False
        else:
            self.lock_on = True

    def shooting_vector(self) -> pygame.math.Vector2:
        # return vector between player and enemy (vector normalized) 
        # todo check why this method is not use
        return pygame.math.Vector2(player.rect.centerx - self.rect.centerx,
                                   player.rect.centery - self.rect.centery).normalize()

    def shot_accuracy(self) -> (int, pygame.math.Vector2):
        # Return shooting angle and vector (already normalized)
        #    Enemy spaceship accuracy defined the angle and vector calculations.

        # accuracy factor calculation function of the target distance.
        # maximum inaccuracy for long range.
        factor = int((self.enemy_.laser_accuracy / SCREENRECT.h) * self.distance_to_player(player_=player))
        # angle spread calculation
        low_aiming_point = self.spaceship_aim - factor
        high_aiming_point = self.spaceship_aim + factor

        # check the range to avoid a ValueError
        if low_aiming_point != high_aiming_point:
            angle = randrange(low_aiming_point, high_aiming_point)
        else:
            angle = low_aiming_point

        vector = pygame.math.Vector2(cos(angle * DEG_TO_RAD), -sin(angle * DEG_TO_RAD))  # inverted y
        return angle, vector

    def laser_shot(self):
        # Shoot all lasers mounted on the enemy spaceship. 

        # if the enemy spaceship is equipped
        # with lasers
        if self.enemy_.laser:
            # check if the lock is on
            if self.lock_on:
                # angle and vector calculation
                angle, vector = self.shot_accuracy()
                # go through all mounted lasers
                for laser_position, laser_type in self.enemy_.laser.items():
                    # check if the weapon is reloading and also if the player is in range
                    if not laser_type.is_reloading() and laser_type.range >= self.distance_to_player(player_=player):
                        EnemyShot.containers = enemyshots, All

                        enemyshots.add(EnemyShot(pos_=eval(laser_position),
                                                 weapon_=laser_type,
                                                 mute_=False, offset_=laser_type.offset,
                                                 vector_=vector, angle_=angle,
                                                 spaceship_aim_=self.spaceship_aim * DEG_TO_RAD,
                                                 rect_=self.rect, timing_=20))
                        laser_type.shooting()

    def explosion(self, mute_: bool = False):
        # Handle an Enemy explosion, create a sound effect,
        #    update player score and start method bonus_energy.
        # :param : mute_, Mute on/off
        #

        # Explosion sound is proportional
        # to the Enemy spaceship size
        if not mute_:
            SC_explosion.play(sound_=self.enemy_.explosion_sound, loop_=False, priority_=0,
                              volume_=SOUND_LEVEL,
                              fade_out_ms=0, panning_=True,
                              name_='EXPLOSION', x_=self.rect.centerx, object_id_=self.enemy_.id)

        # choose among 3 different color of halos
        Halo.images = choice([HALO_SPRITE11, HALO_SPRITE12, HALO_SPRITE13, HALO_SPRITE14])
        Halo(self)
        Explosion1(self, timing_=33, layer_=-1)
        self.enemy_blast()

        PlayerScore.update(self.enemy_.score)
        if not bonus_energy(self):
            if not bonus_bomb(self):
                bonus_ammo(self)

        bonus_gems(self)

        self.quit()

    def blend(self, damages: (float, int)):

        # assert isinstance(damages, (float, int)), \
        #    'Expecting float for argument damages got %s ' % type(damages)

        # todo: blending not working for list
        if isinstance(self.images_copy, list):

            # if self.images_copy[self.index].get_bitsize() == 32:
            #    self.images_copy[(self.index + 1) % len(self.images_copy)] = \
            #        blend_texture(self.images_copy[(self.index + 1) % len(self.images_copy)],
            #                               damages * 0.5 / self.enemy_.max_hp, (255, 0, 0))
            # elif self.images_copy[self.index].get_bitsize() == 24:
            #    self.images_copy[(self.index + 1) % len(self.images_copy)] = \
            #        blend_texture_24bit(self.images_copy[(self.index + 1) % len(self.images_copy)],
            #                                     damages * 0.5 / self.enemy_.max_hp, (255, 0, 0, 0))
            # else:
            #   raise ERROR('\n[-]DamageDisplay - Texture with 8-bit depth color cannot be blended.')
            # return self.image_copy[(self.index + 1) % len(self.images_copy)]

            pass
        else:
            # Red blending is proportional to the damage received
            # 0.5 is the amount of red in the texture, 1 being fully red.
            if self.image.get_bitsize() == 32:
                self.images_copy = blend_texture_alpha(self.images_copy,
                                                       damages * 0.5 / self.enemy_.max_hp, (255, 0, 0, 0))

            elif self.images.get_bitsize() == 24:
                self.images_copy = blend_texture_24bit(self.images_copy,
                                                       damages * 0.5 / self.enemy_.max_hp, (255, 0, 0, 0))
            else:
                raise ERROR('\n[-]DamageDisplay - Texture with 8-bit depth color cannot be blended.')

    def enemy_blast(self):
        # Create a blast effect (enemy spaceship pieces flying around)
        # after explosion or collision.
        # See blast class for more details.

        if id(self) not in Blast.inventory:
            if self.enemy_.disintegration_sprites:
                for r in range(5):
                    Blast.images = self.enemy_.disintegration_sprites[r]
                    Blast(self, timing_=33)
                    Blast.inventory.remove(id(self))
                Blast.images = BLAST1

    # property to cap asteroid health points
    # and show explosion when hp <= 0
    @property
    def hp(self):
        return self.__hp

    @hp.setter
    def hp(self, hp):
        self.__hp = hp
        # Health point < 1, start
        # an explosion animation.
        if hp < 1:
            self.__hp = 0
            self.explosion(mute_=False)
        return self.__hp

    @staticmethod
    def damage_radius_calculator(damage: int, gamma: float, distance: float) -> int:

        # Return damages proportional to the distance of the explosion centre
        # :param damage: Max damages
        # :param gamma:  Constant to adjust damages according to the distance
        # :param distance: distance from the centre of the explosion
        # :return: return damage proportional to the distance

        try:
            return int((damage * (1 / (gamma * distance))) % damage)
        except ZeroDivisionError:
            return damage

    @staticmethod
    def hit(object_, weapon_: Weapons, bomb_effect_: bool = False,
            distance: (float, tuple) = 0.0, rect_center=None):

        # Control the amount of damage the Enemy spaceship is dealing with.
        # :param object_: Enemy class object containing all associated methods
        #                and variables like hp (maximum damages before disintegration).
        # :param weapon_: Player weapons class
        # :param bomb_effect_ : For bomb or super shot with blast wave radius effect.
        #         (damage inversely proportional to the explosion centre distance)
        # :param distance: distance from the explosion centre for an explosion or tuple (x, y)
        #  representing the shot origin.
        # :param rect_center: collision point (rectangle) between the shield and the projectile.

        """
        assert isinstance(object_, Enemy), \
            'Expecting class Enemy for argument object_, got %s' % type(object_)
        if bomb_effect_:
            assert isinstance(weapon_, HALO), 'Expecting class Weapons for argument ' \
                                              'weapon_ got %s ' % type(weapon_)
        else:
            assert isinstance(weapon_, Weapons), 'Expecting class Weapons for argument ' \
                                                 'weapon_ got %s ' % type(weapon_)
        assert isinstance(bomb_effect_, bool), 'Expecting bool for argument ' \
                                               'bomb_effect_ got %s ' % type(bomb_effect_)
        assert isinstance(distance, (float, tuple)), 'Expecting float or tuple for argument ' \
                                                     'distance got %s ' % type(distance)
        """

        # no collision rectangle passed as argument
        # impact in the center
        if rect_center is None:
            rect_center = object_.rect.center

        # if the object is inside the screen
        # area, (partially or totally).
        if object_.rect.colliderect(SCREENRECT):

            if bomb_effect_:
                damage = Enemy.damage_radius_calculator(damage=weapon_.damage, gamma=0.1E-1, distance=distance)

                # Shield is disrupted by the blast.
                # Nuclear missile blast will transfer damage directly
                # to the enemy hull
                if weapon_.name != 'NUCLEAR_HALO':
                    if object_.enemy_.shield and object_.shield.is_shield_up():
                        object_.shield.force_shield_disruption()
                    # shield is already down
                    # transfer damage to the hull
                    else:
                        object_.hp -= damage
                        DamageDisplay(object_, damage, TIME_PASSED_SECONDS, event_=None, timing_=33)
                # Nuke
                else:
                    object_.hp -= damage
                    DamageDisplay(object_, damage, TIME_PASSED_SECONDS, event_=None, timing_=33)

            else:

                # check if fighter has a shield
                # if yes, the shield take all the damage
                if object_.enemy_.shield and object_.shield.is_shield_up():

                    object_.shield.shield_impact(damage_=weapon_.damage, weapon_=weapon_)
                    # Create a nice shield wobbly effect (new instance)
                    # EnemyShield.images = ROUND_SHIELD_IMPACT
                    # EnemyShield(object_=object_, loop_=False,
                    #            timing_=10, event_='SHIELD_IMPACT', shield_type=object_.enemy_.shield)
                    if rect_center:
                        object_.shield.heat_glow(object_.rect.clip(rect_center))
                    else:
                        object_.shield.heat_glow(object_.rect)
                else:

                    if object_.enemy_.weakness:
                        # Weapon bonus apply
                        # +50%, +20% +15% more damage for specific weapons
                        if weapon_.type_ in object_.enemy_.weakness:
                            # base damage fraction (0.5 to 1)  + bonus
                            damage = randint(round(0.5 * weapon_.damage), weapon_.damage) + \
                                     round(object_.weakness[weapon_.type_] * weapon_.damage)
                    # No bonus
                    else:
                        damage = weapon_.damage

                    if weapon_.name != 'STINGER_SINGLE':
                        # damage proportional to the distance (player -> enemy)
                        # except for missiles.
                        damage = damage - int((damage * object_.get_distance(
                            pygame.math.Vector2(distance),
                            pygame.math.Vector2(object_.rect.center))) / SCREENRECT.h)

                    object_.hp -= damage

                    object_.blend(damage)

                    # no damage display for Tesla effect
                    # due to high frequency.
                    if weapon_.type_ != 'TESLA':
                        DamageDisplay(object_, damage, TIME_PASSED_SECONDS, event_=None, timing_=33)

                    # Tesla impact sprite is control directly by Tesla class
                    if weapon_.type_ not in ('BULLET', 'TESLA', 'BEAM'):
                        ImpactBurst(object_, override_method=False, loop_=False, timing_=33, rect_=None, layer_=-2)

    def quit(self):
        # print('killed: ', self.enemy_.name)
        self.kill()
        enemy_group.remove(self)

    def update(self):

        time_trigger = (time_time.time() - GAME_START)
        if not self.initialized:
            if time_trigger < (self.enemy_.spawn + PAUSE_TOTAL_TIME):
                return
            else:
                # print('Enemy : ', self.enemy_.id, ' name :', self.enemy_.name, ' Initialized.')
                self.initialized = True

                # if the enemy has a shield
                if self.enemy_.shield:
                    EnemyShield.containers = All
                    EnemyShield.images = self.enemy_.shield.sprite
                    # Shield Instantiation only when the Enemy instance is ready
                    self.shield = EnemyShield(object_=self, loop_=True, timing_=15,
                                              event_='SHIELD_INIT', shield_type=self.enemy_.shield)

        if self.alive() and self.rect.colliderect(SCREENRECT):

            # adjust self.dt for a smooth animation
            # when enemy ship have a complex path or
            # are scrolling vertically and horizontally.
            # For enemy static object or very slow spaceship,
            # increase self.dt
            if self.dt > self.enemy_.refreshing_rate:

                self.position += self.vector if not isinstance(self.vector, type(None)) else (0, 0)
                self.rect.center = self.position

                if player.alive():
                    # Angle follow the path
                    if not self.enemy_.angle_follow_path:
                        self.enemy_rotation()

                    # Aircraft not allowed to shoot during 2 seconds after spawning
                    if time_trigger > self.enemy_.spawn + self.enemy_.shooting_restriction:
                        self.laser_shot()

                    if isinstance(self.images_copy, list):
                        self.image, self.rect = self.rot_center(self.images_copy[self.index],
                                                                self.spaceship_aim + self.spaceship_aim_offset,
                                                                self.rect)
                        if self.index < len(self.images_copy) - 1:
                            self.index += 1
                        else:
                            self.index = 0

                    else:
                        self.image, self.rect = self.rot_center(self.images_copy,
                                                                self.spaceship_aim + self.spaceship_aim_offset,
                                                                self.rect)

                # self.show_waypoint()
                self.is_waypoint_passed()

                # EXPERIMENTAL
                # show arbitrary waypoint list
                # self.show_arbitrary_path(self.keep_distance())
                # print(self.evasive, self.waypoint)

                if not SCREENRECT.contains(self.rect):
                    if not self.waypoint <= self.max_waypoint:
                        self.quit()

                self.dt = 0

                # Adding sprite into the collision group
                COLLISION_GROUP.add(self)
                # inverted logic
                # removing the sprite from the group if the distance is over the collision radius.
                if (self.position - player.position).length() > COLLISION_RADIUS:
                    COLLISION_GROUP.remove(self)

            self.dt += TIME_PASSED_SECONDS
            # self.vector = self.tracking_vector()
        else:
            if self.waypoint > 1:
                self.quit()
            else:
                self.vector = self.tracking_vector()
                self.position += self.vector if not isinstance(self.vector, type(None)) else (0, 0)
                self.rect.center = self.position


class MicroBots(pygame.sprite.Sprite):
    # Create a micro-bots cloud around the ship
    # for repairing hull damages and faulty systems.
    # See Micro - bots class for pre-defined variable eg(hp_per_frame, max_hp_restoration etc)

    images = None
    inventory = []

    def __new__(cls, object_, timing_, *args, **kwargs):
        # return if an instance already exist.
        if id(object_) in MicroBots.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_, timing_):
        # assert isinstance(object_, Player), \
        #    'Expecting player class for argument object_, got %s ' % type(object_)

        # store the id into the inventory
        MicroBots.inventory.append(id(object_))

        # no more micro-bots ?
        if SHIP_SPECS.microbots_quantity <= 0:
            return
        # player hp does not require micro-bots?
        if SHIP_SPECS.life == SHIP_SPECS.max_health:
            return
        self.object_ = object_
        pygame.sprite.Sprite.__init__(self, self.containers)
        self.images_copy = self.images.copy()
        self.image = self.images_copy[0] if isinstance(self.images_copy, list) else self.images_copy
        self.rect = self.image.get_rect(center=player.rect.center)
        self.index = 0
        self.counter = 0
        self.dt = 0
        self.timing = timing_
        # store the player hp into a variable
        # This will be use later on for comparison
        self.org_player_life = SHIP_SPECS.life
        # Play an electrical sound while the
        # micro-bots are working on the hull
        if not SC_spaceship.get_identical_sounds(NANOBOTS_SOUND):
            SC_spaceship.play(sound_=NANOBOTS_SOUND, loop_=True, priority_=0,
                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True,
                              name_='NANO_BOTS_CLOUD', x_=self.rect.centerx,
                              object_id_=id(NANOBOTS_SOUND))

    def rot_center(self, image_: pygame.Surface, angle_: (int, float), rect_) -> (pygame.Surface, pygame.Rect):
        """rotate an image while keeping its center and size (only for symmetric surface)"""
        # assert isinstance(image_, pygame.Surface), \
        #    ' Expecting pygame surface for argument image_, got %s ' % type(image_)
        # assert isinstance(angle_, (int, float)), \
        #    'Expecting int or float for argument angle_ got %s ' % type(angle_)
        # new_image = pygame.transform.rotozoom(image_, angle_, 1)
        new_image = pygame.transform.rotate(image_, angle_)
        return new_image, new_image.get_rect(center=rect_.center)

    def quit(self):
        # check if the electrical sound is on, if yes, kill it.
        if SC_spaceship.get_identical_sounds(NANOBOTS_SOUND):
            SC_spaceship.stop_object(id(NANOBOTS_SOUND))
        # Check all the systems (e.g Turret, left wing etc)
        # and add a pre - defined repair percentage to it
        # (depends on the micro-bots class).Basic nan-bots repair
        # capability is 25% (e.g MICROBOTS_CLOUD).
        for system, integrity in SHIP_SPECS.system_status.items():
            SHIP_SPECS.system_status[system] = (True, integrity[1] + 25) if integrity[1] + 25 <= 100 else (True, 100)
        # remove id from the inventory
        if id(self.object_) in MicroBots.inventory:
            MicroBots.inventory.remove(id(self.object_))

        # remove the lava effect on the spaceship skin.
        Player.images = SPACESHIP_SPRITE
        self.kill()

    def update(self):
        if self.dt > self.timing:
            if player.alive():
                self.image = self.images_copy[self.index]

                # Micro-bots cloud center calculation
                # angle = (270 + self.counter * 9) % 360
                # centre = (player.rect.centerx + int(cos(angle * DEG_TO_RAD) * 45),
                #           player.rect.centery - int(sin(angle * DEG_TO_RAD) * 45))
                # pygame.draw.circle(screen, (255, 255, 0, 0),
                #                   centre, 10, 2)

                self.index += 1

                # repairing hp_per_frame
                SHIP_SPECS.life += SHIP_SPECS.microbots.hp_per_frame

                # check if repair is complete.
                # max_hp_restoration is the maximum hp and system repair points
                # a micro-bots swarm/cloud is allowed to perform by its class.
                if SHIP_SPECS.life - self.org_player_life >= SHIP_SPECS.microbots.max_hp_restoration:
                    # remove a micro-bots cloud
                    SHIP_SPECS.microbots_quantity -= 1
                    self.quit()

                if self.index > len(self.images_copy) - 1:
                    self.index = 0
                # is player at max_health? -> exit
                if SHIP_SPECS.life == SHIP_SPECS.max_health:
                    self.quit()

                self.rect.center = player.rect.center
                self.counter += 1

            else:
                self.quit()
            self.dt = 0
        self.dt += TIME_PASSED_SECONDS



class Background(pygame.sprite.Sprite):
    images = None
    huds = [None, None]
    inventory = []

    def __new__(cls, v_pos: pygame.math.Vector2, speed_: pygame.math.Vector2,
                 final_: tuple, comeback_to_: pygame.math.Vector2, layer_=None,
                event_=None, timing_: int = 33, *args, **kwargs):
        # return if an instance already exist.

        if event_ in Background.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, v_pos: pygame.math.Vector2, speed_: pygame.math.Vector2,
                 final_: tuple, comeback_to_: pygame.math.Vector2, layer_=None, event_=None, timing_: int = 33):
        """
        assert isinstance(v_pos, pygame.math.Vector2), \
            'Expecting math.Vector2 for argument v_pos got %s ' % type(v_pos)
        assert isinstance(speed_, pygame.math.Vector2), \
            'Expecting math.Vector2 for argument speed_ got %s ' % type(speed_)
        assert isinstance(final_, tuple), \
            'Expecting tuple for argument final_ got %s ' % type(final_)
        assert isinstance(comeback_to_, pygame.math.Vector2), \
            'Expecting tuple for argument comeback_to_ got %s ' % type(comeback_to_)
        """
        Background.inventory.append(event_)

        pygame.sprite.Sprite.__init__(self, self.containers)

        self.images_copy = self.images.copy()
        self.image = self.images_copy[0] if isinstance(self.images, list) else self.images_copy
        self.rect = self.image.get_rect(topleft=v_pos)
        self.v_pos = v_pos
        self.speed = speed_
        self.final = final_
        self.comeback_to = tuple(comeback_to_)
        self.event = event_
        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_:
                All.change_layer(self, layer_)
            else:
                All.move_to_back(self)

            if event_ in ('ENERGY', 'LIFE'):
                All.move_to_front(self)

        # self.dt = 0
        self.dt = 0
        self.timing = timing_

    def update(self):

        if self.dt > 1:  # self.timing:

            if self.event == 'ENERGY':
                self.image = Background.huds[0]

            elif self.event == 'LIFE':
                self.image = Background.huds[1]

            else:

                if self.v_pos.y >= self.final[1]:

                    if self.event in ('CLOUD', 'CLOUD1', 'PLATFORM'):
                        self.v_pos = pygame.math.Vector2(SCREENRECT.centerx + randint(-600, 200),
                                                         self.comeback_to[1])
                    else:
                        self.v_pos = pygame.math.Vector2(self.comeback_to[0], self.comeback_to[1])
                else:
                    self.rect.topleft = self.v_pos

                self.v_pos += self.speed
                self.dt = 0
        self.dt += TIME_PASSED_SECONDS


class CosmicEvent(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        # print('\n[+]Thread CosmicEvent is initialised.')

    def run(self):
        while not STOP_GAME:

            if FRAME % 1000:

                if randint(0, 10000) > 8900:

                    if not Anomaly.active:
                        Anomaly.active = True
                        anomaly = anomalies_list[randint(0, len(anomalies_list) - 1)]
                        GenericAnimation.images = anomaly.images
                        anomaly.set_centre(x=randint(0, SCREENRECT.w), y=-anomaly.image.get_height() - 20)
                        GenericAnimation(object_=anomaly, ratio_=1, timing_=40, event_name_='SPACE_ANOMALY')

            if FRAME % 10 == 0:
                PlayerLife.flame_effect()
                if len(CosmicDust.dust) < 15:
                    threading.Thread(target=CosmicDust, args=(JOYSTICK, JOYSTICK_AXIS_1, DIRECTIONS,
                                                              SCREENRECT, TIME_PASSED_SECONDS, 33, All)).start()


            if FRAME % 50 == 0:
                PlayerLife.flash_effect()
                if len(Asteroid.inventory) < 5:
                    Asteroid_c = asteroids_list[randint(0, len(asteroids_list) - 1)]
                    asteroids.add(Asteroid(Asteroid_c, start_=4., stop_=5., timing_=33))

            pygame.time.wait(TIME_PASSED_SECONDS)
            pass
        # print('CosmicEvent thread is dead.')


def collision():

    if nuke_aiming_point:
        GROUP_UNION.add(nuke_aiming_point)
    # Check collision between the group (asteroids and enemy_group) with the player shots
    for object1, object2 in pygame.sprite.groupcollide(GROUP_UNION, shots, False, False).items():

        # print(object2[0].weapon.name)

        if object2[0].weapon.units == 'SUPER':
            if object1 not in nuke_aiming_point:
                # the bomb effect is control by the GenericAnimation
                object1.hit(object_=object1, weapon_=object2[0].weapon, bomb_effect_=False,
                            distance=object2[0].pos, rect_center=object2[0].rect)
                SC_explosion.stop_name('SUPER_EXPLOSION_SOUND')
                SC_explosion.play(sound_=SUPER_EXPLOSION_SOUND, loop_=False,
                                  priority_=0, volume_=SOUND_LEVEL, fade_out_ms=0,
                                  panning_=True, name_='SUPER_EXPLOSION_SOUND', x_=object2[0].rect.centerx)
                GenericAnimation.images = SUPER_EXPLOSION
                GenericAnimation(object_=object2[0],
                                 ratio_=list(linspace(1, 3, len(SUPER_EXPLOSION) // 2)) + [1] * (
                                         len(SUPER_EXPLOSION) // 2),
                                 timing_=15, offset_=object1.rect.clip(object2[0]), event_name_='EXPLOSION',
                                 loop_=False)

        elif object2[0].weapon.name == 'STINGER_SINGLE':
            if object1 not in nuke_aiming_point:

                if id(object1) in GenericAnimation.inventory:
                    GenericAnimation.inventory.remove(id(object1))

                GenericAnimation.images = MISSILE_EXPLOSION
                GenericAnimation(object1, None, 20, object1.rect.clip(object2[0]), 'MISSILE EXPLOSION', False)
                # No bomb effect for missile stinger
                object1.hit(object_=object1, weapon_=object2[0].weapon,
                            bomb_effect_=True, rect_center=object2[0].rect)
                SC_explosion.stop_name('MISSILE EXPLOSION')
                SC_explosion.play(sound_=MISSILE_EXPLOSION_SOUND, loop_=False, priority_=0,
                                  volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True, name_='MISSILE EXPLOSION',
                                  x_=object2[0].rect.centerx)

        elif object2[0].weapon.name == 'NUCLEAR_SINGLE':
            # Remove the dummy target from the GROUP_UNION
            # and delete the sprite from the nuke_aiming_point group
            GROUP_UNION.remove(object1)
            nuke_aiming_point.empty()

            SC_explosion.stop_name('NUCLEAR_EXPLOSION')
            SC_explosion.play(sound_=EXPLOSION_SOUND_1, loop_=False, priority_=0,
                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=False, name_='NUCLEAR_EXPLOSION',
                              x_=0)  # note x=0 due to panning mode off
            GenericAnimation.images = NUKE_EXOLOSION
            GenericAnimation(object1, None, 10, object1.rect, 'NUCLEAR_EXPLOSION', False)

            # Combine two halo red + blue
            PlayerHalo.images = HALO_SPRITE8
            PlayerHalo(object2[0], speed_=15, halo=HALO_NUCLEAR_BOMB)
            # Halo.images = HALO_SPRITE10
            # Halo(self.target, speed_=7)

            # Nuke missile explosion is now complete
            HomingMissile.is_nuke = False

        # Other type of weapons
        else:
            if object1 not in nuke_aiming_point:

                    # if object2[0].weapon.name == 'LASER_BEAM_BLUE':
                    # ImpactBurst.images = DEATHRAY_IMPACT
                    # ImpactBurst(object1, override_method=True, loop_=False, timing_=33, rect_=None, layer_=-2)
                    # todo need to implement here
                    # pass

                     # else:
                     # todo Traceback (most recent call last):
                    #   File "C:/Users/yoyob/PycharmProjects/Game/Engine24.py", line 6038, in <module>
                    #     collision()
                    #   File "C:/Users/yoyob/PycharmProjects/Game/Engine24.py", line 5550, in collision
                    #     object1.hit(object_=object1, weapon_=object2[0].weapon, bomb_effect_=False,
                    # AttributeError: 'Sprite' object has no attribute 'hit'

                     object1.hit(object_=object1, weapon_=object2[0].weapon, bomb_effect_=False,
                                distance=object2[0].pos, rect_center=object2[0].rect)
                     SC_spaceship.stop_name('IMPACT1')
                     SC_spaceship.play(sound_=object1.impact_sound, loop_=False,
                                      priority_=0, volume_=SOUND_LEVEL, fade_out_ms=0,
                                      panning_=True, name_='IMPACT1', x_=object1.rect.centerx)

        if object1 not in nuke_aiming_point:
            if object2[0].weapon.name not in 'LASER_BEAM_BLUE':
                object2[0].kill()

    # detect collision with asteroids, enemies, lasers and the player.
    if COLLISION_GROUP:
        for object_ in pygame.sprite.spritecollide(player, COLLISION_GROUP, True):
            if issubclass(Gems, type(object_)):
                # todo collect gems's value
                pass
            else:
                PlayerLife(object_)

    # Detect collisions between enemy shots and group asteroids
    if asteroids and enemyshots:
        for object1, object2 in pygame.sprite.groupcollide(asteroids, enemyshots, False, True).items():
            object1.hit(object_=object1, weapon_=object2[0].weapon, bomb_effect_=False,
                        distance=object2[0].pos, rect_center=object2[0].rect)

    # Collectable
    if bonus:
        bonus_ = pygame.sprite.spritecollideany(player, bonus)
        if bonus_:
            if bonus_.bonus_type == 'ENERGY':
                # Stop the crystal sound
                SC_spaceship.stop_object(bonus_.object_id)
                # SC_spaceship.stop(SC_spaceship.get_identical_sounds(CRYSTAL_SOUND))

                # Play the sound of energy being catch
                SC_spaceship.play(sound_=ENERGY_SUPPLY, loop_=False, priority_=0, volume_=SOUND_LEVEL,
                                  fade_out_ms=0,
                                  panning_=False, name_='ENERGY_SUPPLY', x_=0)  # Note x=0 due to panning mode off
                # Add energy to the player
                SHIP_SPECS.energy += bonus_.get_energy()

            elif bonus_.bonus_type == 'BOMB':
                # Play the sound of a nuke being catch
                SC_spaceship.play(sound_=BOMB_CATCH_SOUND, loop_=False, priority_=0, volume_=SOUND_LEVEL,
                                  fade_out_ms=0,
                                  panning_=False, name_='BOMB_SUPPLY', x_=0)  # Note x=0 due to panning mode off
                SHIP_SPECS.nukes += 1
                # NUKE_DISPLAY.images = NUKE_BOMB_INVENTORY
                # NUKE_DISPLAY.update()

            elif bonus_.bonus_type == 'AMMO':
                # Play the sound of a AMMO catch
                SC_spaceship.play(sound_=AMMO_RELOADING_SOUND, loop_=False, priority_=0, volume_=SOUND_LEVEL,
                                  fade_out_ms=0, panning_=False,
                                  name_='AMMO_SUPPLY', x_=0)  # Note x=0 due to panning mode off
                # Full reload ammo and missiles
                SHIP_SPECS.missiles += SHIP_SPECS.max_missiles
                SHIP_SPECS.ammo += SHIP_SPECS.max_ammo
            bonus_.kill()


if __name__ == '__main__':

    # pygame.init()
    # initialize all imported pygame modules
    # will automatically call this function if
    # the freetype module is already imported.
    #  It is safe to call this function more than once.
    freetype.init(cache_size=64, resolution=72)
    pygame.init()

    # Arcade font
    FONT = freetype.Font(os.path.join('Assets\\Fonts\\', 'ARCADE_R.ttf'))

    pygame.mixer.pre_init(44100, 16, 2, 4095)

    CLOCK = pygame.time.Clock()
    clock = pygame.time.Clock()

    TIME_PASSED_SECONDS = 0

    SPEED_FACTOR = 0

    FRAME = 0

    pygame.display.set_caption("Cobra")
    pygame.mouse.set_visible(True)
    # pygame.event.set_blocked(MOUSEMOTION)

    # os.environ['SDL_VIDEO_CENTERED'] = '1'
    # os.environ['SDL_VIDEODRIVER'] = 'windib'
    # Create an environment variable call SDL_VIDEODRIVER and set it to directx for
    # hardware acceleration.
    import os

    position = 50, 25
    os.environ['SDL_VIDEO_WINDOW_POS'] = str(position[0]) + "," + str(position[1])
    # FULLSCREEN | HWSURFACE | DOUBLEBUF, 32)
    screen = pygame.display.set_mode(SCREENRECT.size, 32)
    # screen = pygame.display.set_mode(SCREENRECT.size, pygame.FULLSCREEN | pygame.HWSURFACE,  32)

    print(pygame.display.get_driver())
    print(pygame.display.Info())

    from Shipspecs import SHIP_SPECS
    from Weapons import DEFAULT_WEAPON, CURRENT_WEAPON
    from Constants import SCREENRECT

    # ----------------- Background picture ----------
    # background = pygame.Surface.convert(pygame.Surface((SCREENRECT.w, SCREENRECT.h)))

    background = pygame.Surface.convert(pygame.image.load('Assets\\Graphics\\Background\\background1_part1.png'))
    background_part2 = pygame.Surface.convert(pygame.image.load('Assets\\Graphics\\Background\\background1_part2.png'))
    parallax_part3 = pygame.image.load('Assets\\Graphics\\Background\\parallax3_part3.png').convert_alpha()
    # parallax_part3 = pygame.image.load('Assets\\Graphics\\Background\\stage_cloud_2.png').convert_alpha()
    parallax_part4 = pygame.image.load('Assets\\Graphics\\Background\\parallax3_part4.png').convert_alpha()
    cloud_1 = pygame.image.load('Assets\\Graphics\\Background\\cloud1.png').convert_alpha()
    cloud_2 = pygame.image.load('Assets\\Graphics\\Background\\stage_cloud_2_bis.png').convert_alpha()
    platform = pygame.image.load('Assets\\Graphics\\Background\\test.png').convert_alpha()

    # -----------------------------------------------------
    bgd1_vector = pygame.math.Vector2(0, 0)
    bgd2_vector = pygame.math.Vector2(0, -1024)
    bgd3_vector = pygame.math.Vector2(200, -1024)
    bgd4_vector = pygame.math.Vector2(200, -1500)
    bgd5_vector = pygame.math.Vector2(200, -300)
    bgd6_vector = pygame.math.Vector2(200, -1100)
    bgd7_vector = pygame.math.Vector2(200, -1350)

    # screen.blit(background, bgd1_vector)
    # screen.blit(background_part2, bgd2_vector)

    # pygame.display.flip()

    # ----------------- Music -----------------------
    MUSIC_INDEX = 0
    MUSIC_1 = pygame.mixer.music.load(MUSIC_PLAYLIST[MUSIC_INDEX])
    pygame.mixer.music.play(0)
    pygame.mixer.music.set_volume(MUSIC_LEVEL)
    pygame.mixer.music.queue(MUSIC_PLAYLIST[MUSIC_INDEX + 1])
    pygame.mixer.music.set_endevent(NO_MORE_MUSIC)

    # ------------------------------------------------
    # Group assignment
    background_ = pygame.sprite.Group()
    player1 = pygame.sprite.GroupSingle()
    shots = pygame.sprite.Group()
    enemyshots = pygame.sprite.Group()
    asteroids = pygame.sprite.Group()
    enemy_group = pygame.sprite.Group()
    bonus = pygame.sprite.Group()
    gems = pygame.sprite.Group()
    missiles = pygame.sprite.Group()
    # virtual target point where the nuke is flying and
    # eventually collide and trigger an explosion.
    nuke_aiming_point = pygame.sprite.GroupSingle()
    cosmicdust = pygame.sprite.Group()
    explosions = pygame.sprite.Group()
    All = pygame.sprite.LayeredUpdates()
    # All = pygame.sprite.Group()

    Enemy.containers = enemy_group, All
    enemyshots.containers = enemyshots, All
    Background.containers = background_, All
    Bonus.containers = All
    Gems.containers = gems, All
    Player.containers = player1, All
    Asteroid.containers = asteroids, All
    Shot.containers = shots, All
    Shot.screenrect = SCREENRECT
    DisplayScore.containers = All
    CosmicDust.containers = cosmicdust, All
    ParticleFx.containers = All
    ParticleFxElectrical.containers = All
    MissileParticleFx.containers = All
    MissileParticleFx.images = MISSILE_TRAIL
    Turret.containers = All
    Turret.images = CURRENT_TURRET.sprite
    TurretShot.containers = All
    HighlightTarget.images = TURRET_TARGET_SPRITE
    HighlightTarget.containers = All
    TeslaEffect.containers = All
    TeslaEffect.images = TESLA_BLUE.sprite
    Shield.containers = All
    Shield.images = ROUND_SHIELD_1
    Explosion1.containers = explosions, All
    PlayerHalo.containers = All
    Halo.containers = All
    Halo.images = HALO_SPRITE11
    Blast.containers = All
    GenericAnimation.containers = All
    DamageDisplay.containers = All
    ImpactBurst.containers = All
    HomingMissile.containers = missiles, All

    HomingMissile.images = STINGER_MISSILE.sprite

    DamageDisplay.images = [COSMIC_DUST1] * 2
    DisplayScore.images = COSMIC_DUST1
    All.add(DisplayScore(timing_=150))

    DIRECTIONS = pygame.math.Vector2(0, 0)
    from Joystick import JoystickCheck

    JOYSTICK_AXIS_1 = pygame.math.Vector2(0, 0)
    JOYSTICK = JoystickCheck()

    Player.images = SPACESHIP_SPRITE
    CosmicDust.images = [COSMIC_DUST1] * 2

    PlayerHalo.images = HALO_SPRITE8
    GenericAnimation.images = None

    Blast.images = BLAST1

    player = Player(timing_=33, layer_=-1)
    player1.add(player)

    Follower.images = SHIELD_HEATGLOW
    Follower.containers = All

    MicroBots.images = NANO_BOTS_CLOUD
    MicroBots.containers = All

    # Initialised the class IA.
    # Pass the player rectangle for reference point
    # to all IA methods calculations.
    # IA inherit from the its parent class pygame.Rect.
    ia = Threat(player.rect)

    # Create a new group
    GROUP_UNION = pygame.sprite.Group()
    # add asteroids and ENEMIES_RAPTOR
    GROUP_UNION.add(asteroids)
    GROUP_UNION.add(enemy_group)

    # Turret initialisation
    Turret(timing_=33, group_=(asteroids, enemy_group), weapon_=CURRENT_TURRET.mounted_weapon)

    ParticleFxFire.containers = All
    ParticleFxFire.images = FIRE

    TIMER = 0

    # SpaceShip sound control
    # Reserved 16 channels for the spaceship sound effects.
    SC_spaceship = SoundControl(20)
    # Reserve 16 channels for explosions sounds
    SC_explosion = SoundControl(16)

    # Shield initialisation
    Shield(player, True, 20, event_='SHIELD_INIT')

    PlayerScore = Score()

    Follower.images = EXHAUST1_SPRITE
    Follower(offset_=player.rect.midbottom, timing_=15, loop_=True)

    from Constants import STOP_GAME

    energy_bar = HorizontalBar(start_color=pygame.Color(0, 7, 255, 0),
                               end_color=pygame.Color(120, 255, 255, 0),
                               max_=SHIP_SPECS.max_energy, min_=0,
                               value_=SHIP_SPECS.energy,
                               start_color_vector=(0, 1, 0), end_color_vector=(0, 0, 0), alpha=None)

    life_bar = HorizontalBar(start_color=pygame.Color(255, 10, 15, 0),
                             end_color=pygame.Color(4, 255, 15, 0),
                             max_=SHIP_SPECS.max_health, min_=0,
                             value_=SHIP_SPECS.life,
                             start_color_vector=(0, 0, 0), end_color_vector=(0, 0, 1), alpha=None)

    # Control the screen wobbly effect
    WOBBLY = 0
    PREVIOUS_TARGET = [None, None]

    # flickering lights on the spaceship
    FLASH_COLOR = 0

    DisplayNukesLeft.images = NUKE_BOMB_INVENTORY
    NUKE_DISPLAY = DisplayNukesLeft(timing_=244)
    DisplayMissilesLeft.images = MISSILE_INVENTORY
    MISSILE_DISPLAY = DisplayMissilesLeft(timing_=244)

    GAME_START = time_time.time()

    import ctypes

    for i, j in LEVEL1_WAVE0.items():
        enemy = ctypes.cast(id(i), ctypes.py_object).value
        enemy.override_attributes(j)
        Enemy.images = enemy.spaceship_animation
        enemy_group.add(Enemy(enemy, enemy.refreshing_rate, -2))
        # enemy_group.add(Enemy(enemy, enemy.refreshing_rate, -2, All, enemyshots,
        #                      player, SCREENRECT, TIME_PASSED_SECONDS,
        #                      SC_explosion, PlayerScore, PAUSE_TOTAL_TIME, GAME_START))

    for i, j in LEVEL1_WAVE1.items():
        enemy = ctypes.cast(id(i), ctypes.py_object).value
        enemy.override_attributes(j)
        Enemy.images = enemy.spaceship_animation
        enemy_group.add(Enemy(enemy, enemy.refreshing_rate, -2))
        # enemy_group.add(Enemy(enemy, enemy.refreshing_rate, -2, All, enemyshots,
        #                      player, SCREENRECT, TIME_PASSED_SECONDS,
        #                      SC_explosion, PlayerScore, PAUSE_TOTAL_TIME))

    for i, j in LEVEL1_WAVE2.items():
        enemy = ctypes.cast(id(i), ctypes.py_object).value
        enemy.override_attributes(j)
        Enemy.images = enemy.spaceship_animation
        enemy_group.add(Enemy(enemy, enemy.refreshing_rate, -2))
        # enemy_group.add(Enemy(enemy, enemy.refreshing_rate, -2, All, enemyshots,
        #                      player, SCREENRECT, TIME_PASSED_SECONDS,
        #                      SC_explosion, PlayerScore, PAUSE_TOTAL_TIME))


    # ASTEROID PARALLAX 1
    Background.images = parallax_part3
    Background(v_pos=bgd3_vector, speed_=pygame.math.Vector2(0, 2.2), final_=(200, 1024),
               comeback_to_=bgd3_vector, layer_=-5, event_='1', timing_=33)
    # ASTEROID PARALLAX 2
    Background.images = parallax_part4
    Background(v_pos=bgd4_vector, speed_=pygame.math.Vector2(0, 1.5), final_=(200, 1024),
               comeback_to_=bgd4_vector, layer_=-6, event_='2', timing_=33)
    # CLOUD PARALLAX 1
    Background.images = cloud_1
    Background(v_pos=bgd5_vector, speed_=pygame.math.Vector2(0, 3), final_=(200, 1024),
               comeback_to_=bgd5_vector, layer_=-6, event_='CLOUD', timing_=33)
    # CLOUD PARALLAX 2
    Background.images = cloud_2
    Background(v_pos=bgd6_vector, speed_=pygame.math.Vector2(0, 3.5), final_=(200, 1024),
               comeback_to_=bgd6_vector, layer_=-5, event_='CLOUD1', timing_=33)

    # SPACE BACKGROUND 1
    Background.images = background
    Background(v_pos=bgd1_vector, speed_=pygame.math.Vector2(0, 1 / 3),
               final_=(0, 1024), comeback_to_=pygame.math.Vector2(0, -1024), layer_=-8, event_='back1', timing_=33)
    # SPACE BACKGROUND 2
    Background.images = background_part2
    Background(v_pos=bgd2_vector, speed_=pygame.math.Vector2(0, 1 / 3),
               final_=(0, 1024), comeback_to_=pygame.math.Vector2(0, -1024), layer_=-8, event_='back2', timing_=33)

    # ENERGY HUD
    Background(v_pos=pygame.math.Vector2(0, 0), speed_=pygame.math.Vector2(0, 0), final_=(0, 1024),
               comeback_to_=pygame.math.Vector2(0, 0), layer_=0, event_='ENERGY', timing_=33)
    # LIFE HUD
    Background(v_pos=pygame.math.Vector2(SCREENRECT.w - LIFE_HUD.get_width(), 0),
               speed_=pygame.math.Vector2(0, 0), final_=(0, 1024),
               comeback_to_=pygame.math.Vector2(0, 0), layer_=0, event_='LIFE', timing_=33)

    """
    Background(v_pos=pygame.math.Vector2(0, 0), speed_=pygame.math.Vector2(0, 0), final_=(0, 1024),
                comeback_to_=pygame.math.Vector2(0, 0), layer_=-3, event_='BLOOD_TOP')
    Background(v_pos=pygame.math.Vector2(97, 966), speed_=pygame.math.Vector2(0, 0), final_=(0, 1024),
               comeback_to_=pygame.math.Vector2(0, 0), layer_=-3, event_='BLOOD_BOTTOM')
    Background(v_pos=pygame.math.Vector2(0, 117), speed_=pygame.math.Vector2(0, 0), final_=(0, 1024),
               comeback_to_=pygame.math.Vector2(0, 0), layer_=-3, event_='BLOOD_LEFT')
    Background(v_pos=pygame.math.Vector2(704, 117), speed_=pygame.math.Vector2(0, 0), final_=(0, 1024),
               comeback_to_=pygame.math.Vector2(0, 0), layer_=-3, event_='BLOOD_RIGHT')
    """

    # Platform
    Background.images = platform
    Background(v_pos=bgd7_vector, speed_=pygame.math.Vector2(0, 0.8), final_=(200, 1024),
               comeback_to_=bgd7_vector, layer_=-7, event_='PLATFORM', timing_=33)

    pygame.event.set_blocked(4)  # No mouse events

    CosmicEvent().start()

    # -------- Main Program Loop -----------
    while not STOP_GAME:

        while PAUSE:
            for event in pygame.event.get():
                keys = pygame.key.get_pressed()
                # print(keys)
                if keys[K_PAUSE]:
                    PAUSE = False
                    print('Pause : ', (time_time.time() - PAUSE_TIMER))
                    PAUSE_TOTAL_TIME += (time_time.time() - PAUSE_TIMER)
                    print('Total time : ', PAUSE_TOTAL_TIME)

        keys = pygame.key.get_pressed()
        for event in pygame.event.get():
            keys = pygame.key.get_pressed()

            if keys[K_ESCAPE]:
                print('Quitting')
                STOP_GAME = True

            if keys[K_PAUSE]:
                PAUSE = True
                print('game is pause')
                PAUSE_TIMER = time_time.time()

            if event.type == NO_MORE_MUSIC:
                MUSIC_INDEX += 1
                MUSIC_1 = pygame.mixer.music.load(MUSIC_PLAYLIST[MUSIC_INDEX % 2])
                pygame.mixer.music.play(0)

        DIRECTIONS = pygame.math.Vector2(keys[K_RIGHT] - keys[K_LEFT], keys[K_DOWN] - keys[K_UP])

        if JOYSTICK.availability:

            # Spaceship control up/down left/right
            JOYSTICK_AXIS_1 = pygame.math.Vector2(
                round(JOYSTICK.inventory[0].get_axis(0), 1), round(JOYSTICK.inventory[0].get_axis(1), 1))

            firing = keys[K_SPACE] or JOYSTICK.inventory[0].get_button(2)
            super_shot = keys[K_LCTRL] or JOYSTICK.inventory[0].get_button(7)

            # Micro - bots squad
            if JOYSTICK.inventory[0].get_button(3) or keys[K_RCTRL]:
                if player.alive():
                    MicroBots(player, timing_=33)

            # NUKE Bomb release
            elif JOYSTICK.inventory[0].get_button(6):
                Player.nuke()

        # Keyboard control only
        else:
            # todo need to check if a keyboard is available first
            firing = keys[K_SPACE]
            super_shot = keys[K_LCTRL]
            if keys[K_RCTRL]:
                if player.alive():
                    MicroBots(player, timing_=33)

        # background = blend_texture(background, 0.2, (0, 0, 0))
        # Extract all the pixel colors into a numpy array
        # rgba_array = pygame.surfarray.pixels3d(background)
        # Extract all the alpha values into a numpy array
        # alpha_channel = pygame.surfarray.pixels_alpha(background)
        # background = add_transparency_all(rgba_array, alpha_channel, 20)

        if DIRECTIONS or JOYSTICK_AXIS_1 != (0, 0):
            player.move()
        else:
            player.standby()

        if player.alive():
            if firing and not CURRENT_WEAPON.weapon_reloading_std():
                # todo need to check ammo for bullets
                if SHIP_SPECS.energy > (CURRENT_WEAPON.energy * shot_number(CURRENT_WEAPON.units)) \
                        or CURRENT_WEAPON.type_ == 'BULLET':
                    player.images = CURRENT_WEAPON.animation
                    # lock the weapon in shooting mode
                    CURRENT_WEAPON.shooting = True
                    # start the counter for the reloading
                    CURRENT_WEAPON.elapsed = time_time.time()
                    multiple_shots(CURRENT_WEAPON.units, SHIP_SPECS,
                                   CURRENT_WEAPON, SC_spaceship, player, TIME_PASSED_SECONDS, All)

            elif super_shot:
                # Player.SPACESHIP_STATUS == 'SUPER'
                Player.super_shot()
                Player.missiles()

                if not LASER_BEAM_BLUE.weapon_reloading_std():

                    Follower.images = DEATHRAY_SHAFT
                    instance_ = Follower(offset_=player.rect.center, timing_=15, loop_=True, event_='SHAFT LIGHT')
                    if instance_:
                        SuperLaser.containers = shots, All
                        SuperLaser.images = LASER_BEAM_BLUE.sprite
                        SuperLaser(LASER_BEAM_BLUE, TIME_PASSED_SECONDS,
                                   SC_spaceship, player, All, instance_, layer_=-2)



        # create a new group
        GROUP_UNION = pygame.sprite.Group()
        # add asteroids and ENEMIES_RAPTOR (update every frames)
        GROUP_UNION.add(asteroids)
        GROUP_UNION.add(enemy_group)

        if FRAME % 2 == 0:
            collision()

        energy_bar.VALUE = SHIP_SPECS.energy
        energy = energy_bar.display_gradient()
        ENERGY_HUD_COPY = ENERGY_HUD.copy()
        ENERGY_HUD_COPY.blit(energy_bar.display_value(), (50, 35))
        if energy:
            ENERGY_HUD_COPY.blit(energy, (87, 23))

        Background.huds[0] = ENERGY_HUD_COPY

        life_bar.VALUE = SHIP_SPECS.life
        life = life_bar.display_gradient()
        LIFE_HUD_COPY = LIFE_HUD.copy()
        LIFE_HUD_COPY.blit(life_bar.display_value(), (220, 65))

        # screen.blit(LIFE_HUD_COPY, (SCREENRECT.w - LIFE_HUD.get_width(), 0))
        Background.huds[1] = apparent_damage(player, LIFE_HUD_COPY, life)

        # All.update()
        # pygame.display.update(All.draw(screen))
        # All.clear(screen, background) -> off

        # Update the list of sound objects for the SpaceShip mixer
        SC_spaceship.update()
        # update the list of sound objects for the explosion mixer
        SC_explosion.update()

        # debug display colliders
        # collider = ia.colliders(asteroids, player.rect)
        # for object in collider:
        #    pygame.draw.line(screen, (255, 0, 0, 0), player.rect.center, object.rect.center, 2)
        """
        colliders = ia.colliders(asteroids, player.rect)
        print(ia.sort_by_farthest_collider(colliders))
        """

        All.update()

        """
        background_.draw(screen)
        cosmicdust.draw(screen)
        enemyshots.draw(screen)

        shots.draw(screen)
        GROUP_UNION.draw(screen)
        player1.draw(screen)
        explosions.draw(screen)
        """

        All.draw(screen)

        # Screen wobbling effect
        if WOBBLY != 0:
            screen.blit(screen, (0 + WOBBLY, 0))

        time = time_time.time()

        if SHIP_SPECS.life < 200:

            screen.blit(BLOOD_SURFACE[0], (0, 0))
            screen.blit(BLOOD_SURFACE[1], (0, 117))
            screen.blit(BLOOD_SURFACE[2], (704, 117))
            screen.blit(BLOOD_SURFACE[3], (97, 966))
            # print('TOTAL ', time_time.time() - time)

        pygame.display.flip()

        # pygame.display.update(All.draw(screen))
        # pygame.display.flip()
        # This will update the contents of the entire display.
        # If your display mode is using the flags pygame.HWSURFACE
        # and pygame.DOUBLEBUF, this will wait for a vertical retrace
        # and swap the surfaces.
        # If you are using a different type of display mode,
        # it will simply update the entire contents of the surface.
        # When using an pygame.OPENGL display mode this will perform a gl buffer swap.
        # pygame.display.flip()

        FRAME += 1

        # print(ia.get_all_rect_distances(asteroids))
        # print(ia.sort__by_deadliness(ia.create_entities(asteroids)))

        # SC_spaceship.show_sounds_playing()

        # print('All layers :', All.layers())

        TIME_PASSED_SECONDS = CLOCK.tick(MAXFPS)  # in ms
        # print(round(CLOCK.get_fps()), TIME_PASSED_SECONDS)

        SPEED_FACTOR = TIME_PASSED_SECONDS / 1000

        # print(len(enemy_group), enemy_group, len(All))

        # pygame.time.wait(2)

    pygame.freetype.quit()
    pygame.quit()
