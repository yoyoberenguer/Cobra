# encoding: utf-8

# REQUIRMENTS

# pygame==2.4.0
# numpy==1.19.5
# psutil>=5.9.5
# Cython==0.29.25
# lz4>=3.1.3
# PygameShader>=1.0.8



import atexit
import lz4.frame as lz4frame
from psutil import virtual_memory as vm
from pygame.image import tostring

# from Bonus import bonus_energy, bonus_bomb, bonus_life, bonus_ammo, bonus_gems
from BulletHell import EnemyBoss, loop_display_bullets, VERTEX_BULLET_HELL
from ClusterBomb import XBomb, show_debris, DisplayCrack  # damped_oscillation, BindSpriteLoopOver
# from Dialogs import DialogBox
# from CobraLightEngine import aircraft_light
from EnemyShield import EnemyShield
from EnemyShot import EnemyParentClass, Enemy  # EnemyShot

from Flares import display_flare_sprite, CHILD_FLARE_INVENTORY
from Follower import Follower  # FOLLOWER_INVENTORY
# from GaussianBlur5x5 import blur5x5_array24_inplace_c, blur5x5_surface24_inplace_c
from Gems import Gems
# from Halo import Halo
from HighLightTarget import CURRENT_TARGET, Target
from Miscellaneous import game_pause, toggle_fullscreen, ShowMousePosition, ShowFps, \
    ImpactBurst, Explosion1, Score, \
    DisplayLife, DisplayScore, DisplayNukesLeft, DisplayMissilesLeft, display_lights,\
    laser_impact_fx, \
    start_flare_effect, start_dialog, background_layers
from PlayerLife import PlayerLife  # DamageControl
# from Saturation import saturation_array24

from PygameShader import blood, dampening, shader_bloom_fast1, brightness, horizontal_glitch,\
    blend, lateral_dampening
from PygameShader.misc import create_horizontal_gradient_1d
# from PygameShader.shader_gpu import block_grid
from Score import PlayerLost
from ShowDamage import DamageDisplay

from StationBoss import STATION_VERTEX_BULLET_HELL, station_loop_display_bullets, Station  # Station
from SurfaceBurst import display_burst, VERTEX_ARRAY_SUBSURFACE, burst_into_memory, burst, \
    rebuild_from_memory  # burst


# from VideoRecording import WriteVideo

# TODO ADD THIS FOR RECORDING, start_audio_recording, stop_audio_recording
from XML_parsing import xml_get_weapon, xml_parsing, xml_parsing_G5V200
from Default import BindDefault
# from bloom import bloom_effect_buffer24, bpf24_c
# from hsv_surface import hsv_surface24c_inplace

# from surface import black_blanket_surface


# KEEP THE LINES BELOW IN ORDER TO CREATE AN EXECUTABLE FILE WITH PYINSTALLER
import Shipspecs  # used during the exe build process
import numpy
import random
from random import choice, randint
from math import atan2
# todo rename time
import time

# import colorsys

# PYGAME IS REQUIRED

try:
    import pygame
    from pygame.surfarray import pixels3d, pixels_alpha, array_alpha
    from pygame.math import Vector2
    from pygame import RLEACCEL
    from pygame.transform import flip, rotate, smoothscale, rotozoom, scale2x
    from pygame.locals import *
except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
                     "\nTry: \n   C:/pip install pygame on a window command prompt.")

from Sprites import LayeredUpdatesModified, LayeredUpdates
from Sprites import Group

import Shipspecs
from Weapons import *

from Constants import *

from Joystick import JoystickCheck

# IF YOU HAVE ANY ERROR IMPORTING SPRITES, DON'T FORGET TO REBUILD THE PYX FILE
from Textures import ENERGY_HUD, LIFE_HUD, BLOOD_SURFACE, ALL_SPACE_SHIP, \
    NEMESIS_LIFE_INVENTORY, LEVIATHAN_LIFE_INVENTORY, \
    COUNTDOWN_NUMBER_256x256, GROUND_CRACK1, GROUND_CRACK2, GROUND_CRACK3, bytes_conversion, \
    SHOOTING_STAR, FLARE, PARTICLES_SPRITES, G5V200_ANIMATION, STATION, COBRA, FINAL_MISSION
# EXPLOSION10, ENERGY_BOOSTER1, HALO_SPRITE8, BURST_UP_RED, \
# LEVEL_UP_6, PHOTON_PARTICLE_1, COSMIC_DUST1, BLAST1, \
# HALO_SPRITE11, HALO_SPRITE12, HALO_SPRITE13, \
# HALO_SPRITE14, NUKE_BONUS, GEM_SPRITES, BEAM_FIELD, ROUND_SHIELD_1, \
# ROUND_SHIELD_IMPACT, TESLA_IMPACT, SHIELD_HEATGLOW1, SHIELD_ELECTRIC_ARC, COLLECTIBLES_AMMO, \
# NUKE_BOMB_INVENTORY, MISSILE_INVENTORY, \
# NANO_BOTS_CLOUD, SHIELD_DISTUPTION_1, \
# CRATERS, SMOKE, LASER_EX, NAMIKO, \
# DIALOG, VOICE_MODULATION, IMPACT_GLASS, IMPACT_GLASS1, \
# MISSILE_EXHAUST, DIALOGBOX_READOUT, \
# HOTFURNACE, HOTFURNACE1, HOTFURNACE2, LEVEL_UP_MSG, G5V200_EXPLOSION_DEBRIS, \
# RADIAL, HALO_SPRITE9_, EXPLOSION19, FINAL_MISSION, BonusLifeLeviathan, BonusLifeNemesis, \
# DIALOGBOX_READOUT_RED, SKULL, RADIAL_LASER, BLURRY_WATER1, \
# SHIELD_ELECTRIC_ARC_1, EXPLOSIONS, BOMB, CRATER, CRATER_MASK, EXPLOSION5, ELECTRIC,
# TURRET_SHARK, FRAMEBORDER, \
# G5V200_ANIMATION, NUMBERS, PARALLAX_PART3, PARALLAX_PART4, CLOUD_2, CLOUD_3, \
# PLATFORM_0, PLATFORM, PLATFORM_2, PLATFORM_3, PLATFORM_4, PLATFORM_5, PLATFORM_6,
# PLATFORM_7, STATION, \
# RADIAL4_ARRAY_128x128,

from Sounds import MUSIC_PLAYLIST, WHOOSH
# HEART_SOUND, CRYSTAL_SOUND, ALARM_DESTRUCTION, NANOBOTS_SOUND, \
# EXPLOSION_COLLECTION_SOUND, SCREEN_IMPACT_SOUND, BROKEN_GLASS, EXPLOSION_SOUND_2
# GROUND_EXPLOSION, EXPLOSION_SOUND_1, LEVEL_UP, IMPACT2



from Waves import level1

# -------------------------------------------------
# |              cython modules                   |
# -------------------------------------------------
from ParticleFx import VERTEX_PARTICLEFX, display_particlefx # ParticleFx
# from Shot import Shot
from Shot import LIGHTS_VERTEX
from Apparent_damage import apparent_damage
from CosmicDust import cosmic_dust, cosmic_dust_display, VERTEX_ARRAY_DUST
from AI_cython import *
from MissileParticleFx import VERTEX_ARRAY_MP  # MissileParticleFx_improve
# from MultipleShots import *
from SoundControl_cython import SoundLevel
from SoundServer import SoundControl

# from HomingMissile_cython import HomingMissile, EnemyHomingMissile, AdaptiveHomingMissile
# from SuperLaser_cython import display_super_laser  # SuperLaser

from GenericAnimation import nuke_flash  # GenericAnimation
from PlayerHalo import *
from CollisionDetection import CollisionDetection
from SpriteSheet import *

from Player import Player  # Shield
# from CobraLightEngine import aircraft_light

from PlayerTurret import TurretShot, Turret, TURRET_INITIALISED
from BindSprite import *

from Background import BACKGROUND_HUDS  # Background, create_stars,
# from Blast import Blast, BLAST_INVENTORY
from BrightStars import BrightStars, ShootingStar

import warnings

from JoystickServer import *

# from Flares import polygon, second_flares, TEXTURE3, TEXTURE2, TEXTURE1, \
#     TEXTURE, make_vector2d, create_flare_sprite, STAR_BURST

from numba import njit, jit


warnings.simplefilter(action='ignore')

M_PI = 3.14159265359
DEG_TO_RAD = M_PI / 180.0
RAD_TO_DEG = 180.0 / M_PI

COLOR_GRADIENT = create_horizontal_gradient_1d(63)


def Exit():
    print("An unexpected interruption!")


atexit.register(Exit)


class GroundEnemyTurret(EnemyParentClass):

    """
    GROUND ENEMY TURRET CLASS (inherit from EnemyParentClass)

    """

    initialized = False

    def __init__(self,
                 gl_,
                 enemy_,
                 timing_=35,
                 layer_: int = -5):

        EnemyParentClass.__init__(self, gl_)

        self._layer = layer_
        self.enemy_ = enemy_
        self.gl = gl_

        # player causing damage to the enemy
        self.player_inflicting_damage = None
        # choose a player right from the start
        self.targeted_player = self.select_player()
        self.lock_on = False

        if isinstance(self.gl.All, LayeredUpdates):
            self.gl.All.change_layer(self, layer_)

        self.images_copy = self.enemy_.object_animation.copy()
        self.image = self.images_copy[0] if isinstance(self.enemy_.object_animation.copy(), list) \
            else self.images_copy

        self.rect = self.image.get_rect(center=(self.enemy_.pos.x * self.gl.RATIO.x,
                                                self.enemy_.pos.y * self.gl.RATIO.y))
        # time variable
        self.dt = 0

        self.position = Vector2(self.enemy_.pos.x * self.gl.RATIO.x,
                                self.enemy_.pos.y * self.gl.RATIO.y)

        # todo self.vector should always match the image speed that support the sprite
        self.vector = Vector2(0, 1)  # self.enemy_.speed #

        # Using laser damage instead of collision damage.
        # self.damage is used by IA_cython to determine
        # player deadliness
        # todo the below need to be done differently self.rect.midtop is true
        # only for that instance
        self.damage = self.enemy_.laser['(self.rect.center[0], self.rect.center[1] - 20)'].damage

        self.explosion_sprites = self.enemy_.explosion_sprites
        self.impact_sprite = self.enemy_.impact_sprite
        self.impact_sound = self.enemy_.impact_sound
        # Enemy life points
        self.hp = self.enemy_.hp
        # enemy has a lock-on
        # Lock on is automatically set to True
        # when the enemy spaceship angle is in the tolerance
        # area of +/- 5 degrees (True trigger shots)
        self.lock_on = False
        # how many degrees the sprite need to be rotated clockwise
        # in order to be oriented/align with a zero degree angle.
        self.spaceship_aim_offset = self.enemy_.sprite_orientation
        # aim angle right at the start
        self.spaceship_aim = -self.spaceship_aim_offset  # inverted to get the right angle

        # Turret offset position on the map from the top left corner.
        # self.offset = self.position.copy()
        self.offset = Vector2(self.position[0], self.position[1])

        # Place the turret
        self.position = self.gl.vector1 + self.offset

        self.rect.center = self.position
        self.index = 0
        self.timing = timing_


    def update(self):

        # rect is now visible onto the screen
        if self.rect.bottom > 0:
            # add the background vertical speed
            self.position += Vector2(0, 1)
            self.rect.center = self.position

        # rect is still outside the screen
        else:
            self.position = self.gl.vector1 + self.offset
            self.rect.center = self.position

        if self.dt > self.timing:

            if self.targeted_player is not None:
                if not self.targeted_player.alive():
                    self.targeted_player = self.select_player()
            else:
                self.targeted_player = self.select_player()

            if self.rect.bottom > 0:

                if bool(self.gl.PLAYER_GROUP) and self.targeted_player is not None:
                    self.enemy_rotation()
                    self.laser_shot()

                if isinstance(self.images_copy, list):
                    self.image, self.rect = self.rot_center(
                        self.images_copy[self.index],
                        self.spaceship_aim + self.spaceship_aim_offset, self.rect)
                    if self.index < len(self.images_copy) - 1:
                        self.index += 1
                    else:
                        self.index = 0

                else:
                    self.image, self.rect = self.rot_center(
                        self.images_copy,
                        self.spaceship_aim + self.spaceship_aim_offset,
                        self.rect)
                if self.rect.top > self.gl.screen.get_height():
                    self.quit()

                self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS
        pass


class GroundEnemyDrone(EnemyParentClass):

    """
    GROUND ENEMY DRONE CLASS (inherit from EnemyParentClass)

    """

    initialized = False

    def __init__(self, gl_, enemy_, timing_=35, layer_: int = -5):

        EnemyParentClass.__init__(self, gl_)

        self._layer = layer_
        self.enemy_ = enemy_
        self.gl = gl_
        # player causing damage to the enemy
        self.player_inflicting_damage = None
        # choose a player right from the start
        self.targeted_player = self.select_player()
        self.lock_on = False

        if isinstance(self.gl.All, LayeredUpdates):
            self.gl.All.change_layer(self, layer_)

        self.images_copy = self.enemy_.object_animation.copy()
        self.image = self.images_copy[0] if isinstance(self.enemy_.object_animation.copy(), list) \
            else self.images_copy

        self.damage = self.enemy_.laser['(self.rect.center[0], self.rect.center[1])'].damage

        self.waypoint_list = []

        self.path = enemy_.path.copy()

        i = 0
        for x, y in self.path:
            self.path[i] = float(x * self.gl.RATIO.x), float(y * self.gl.RATIO.y)
            i += 1

        for point in self.path:
            self.waypoint_list.append(point)

        self.rect = self.image.get_rect(center=(self.enemy_.pos.x * self.gl.RATIO.x,
                                                self.enemy_.pos.y * self.gl.RATIO.y))

        # time variable
        self.dt = 0

        self.position = Vector2(self.enemy_.pos.x * self.gl.RATIO.x,
                                self.enemy_.pos.y * self.gl.RATIO.y)

        # Turret offset position on the map from the top left corner.
        self.offset = Vector2(self.position.x, self.position.y)

        # Calculate the last waypoint
        self.max_waypoint = len(self.waypoint_list)

        # Index on the first waypoint
        self.waypoint = 0

        self.vector1 = Vector2()
        self.vector2 = Vector2()

        self.vector = Vector2(0, 0)
        # vector is the vessel direction and speed
        self.vector = self.new_vector()

        # how many degrees the sprite need to be rotated clockwise
        # in order to be oriented/align with a zero degree angle.
        self.spaceship_aim_offset = self.enemy_.sprite_orientation
        # aim angle right at the start
        self.spaceship_aim = -self.spaceship_aim_offset  # inverted to get the right angle

        self.enemy_rotation_path()

        # timing constant
        self.dt = 0

        # laser timer
        self.timer = 0

        self.lock_on = False

        # Enemy life points
        self.hp = self.enemy_.hp

        self.index = 0
        self.shift = 0.0

        # ---   for compatibility with other class ---
        self.explosion_sprites = enemy_.explosion_sprites
        self.impact_sprite = enemy_.impact_sprite
        self.impact_sound = enemy_.impact_sound

        self.position = self.gl.vector1 + self.offset
        self.rect.center = self.position
        self.timing = timing_

    @staticmethod
    def show_arbitrary_path(waypoint_list):
        if waypoint_list:
            for point in waypoint_list:
                pygame.draw.rect(GL.gl.screen,
                                 (255, 255, 0, 0), (point[0] - 5, point[1] - 5, 10, 10), 2)
        pygame.display.flip()

    def show_waypoint(self):
        for point in self.waypoint_list:
            pygame.draw.rect(self.gl.screen,
                             (255, 255, 0, 0), (point[0] - 5, point[1] - 5, 10, 10), 2)
        pygame.display.flip()

    def is_waypoint_passed(self):

        dummy_rect = pygame.Rect(self.rect.centerx - 30, self.rect.centery - 30, 60, 60)

        if self.waypoint < self.max_waypoint:

            if dummy_rect.collidepoint(self.waypoint_list[self.waypoint]):
                # next direction vector calculation
                self.waypoint += 1
                self.vector = self.new_vector()

            self.enemy_rotation_path()

        else:
            # Drone is turning toward player
            if bool(self.gl.PLAYER_GROUP):
                self.enemy_rotation()
            # Drone stop moving
            self.vector = Vector2(0, 0)

    def new_vector(self) -> Vector2:
        assert self.vector1 is not None, "Instance variable self.vector1 should not be a NoneType."
        assert self.vector2 is not None, "Instance variable self.vector2 should not be a NoneType."
        assert self.vector is not None, "Instance variable self.vector should not be a NoneType."
        self.vector1.x, self.vector1.y = self.rect.center
        if self.waypoint < self.max_waypoint:
            self.vector2.x, self.vector2.y = self.waypoint_list[self.waypoint]

        vector = self.vector2 - self.vector1
        if vector.length() > 0:
            factor = self.enemy_.speed.length() / (vector.normalize()).length()
            return vector.normalize() * factor
        else:
            return Vector2(0, 0)

    def enemy_rotation_path(self):

        # angle in degrees corresponding to the object
        rotation_degrees = -int(RAD_TO_DEG * (atan2(self.vector.y, self.vector.x)) % 360)
        angle = -(self.spaceship_aim - rotation_degrees) % 360
        if angle != 0:
            sign = 0
            clockwise = angle
            anticlockwise = 360 - clockwise

            # equidistant, choose a direction
            if anticlockwise == clockwise:
                sign = choice((-1, 1))
            # equidistant 0 % 360 degrees same angle.
            elif abs(anticlockwise - clockwise) == 360:
                sign = 0
            # anticlockwise is shortest angular rotation
            elif anticlockwise < clockwise:
                sign = -1
            elif anticlockwise > clockwise:
                sign = +1

            if abs(angle) - self.enemy_.rotation_speed * sign >= 1:
                self.spaceship_aim += (self.enemy_.rotation_speed * sign)
            else:
                self.spaceship_aim += sign

    def update_path(self):
        path_ = numpy.zeros((4, 2))
        # path_ = [[[0., 0.], [0.,  0.]],
        #         [[0.,  0.], [0.,  0.]],
        #         [[0.,  0.], [0.,  0.]],
        #         [[0.,  0.], [0.,  0.]]
        #        ]
        i = 0
        for point in self.path:
            path_[i] = [point[0], self.gl.vector1[1] + point[1]]
            i += 1
        return path_

    def update(self):

        self.waypoint_list = self.update_path()
        # self.show_waypoint()

        if self.rect.bottom > 0:
            # add the background vertical speed
            self.position += self.vector + Vector2(0, 1)
            self.rect.center = self.position
        else:
            self.position = self.gl.vector1 + self.offset
            self.rect.center = self.position

        if self.dt > self.timing:

            if self.targeted_player is not None:
                if not self.targeted_player.alive():
                    self.targeted_player = self.select_player()
            else:
                self.targeted_player = self.select_player()

            if self.rect.bottom > 0:

                self.is_waypoint_passed()
                """
                # add the background vertical speed
                self.position += self.vector + Vector2(0, 1)
                self.rect.center = self.position
                """
                if self.rect.colliderect(self.gl.screen.get_rect()):
                    # random variable to make sure all shots are
                    # synchronized
                    os.urandom(100)
                    if random.randint(0, 1000) > 950:
                        if bool(self.gl.PLAYER_GROUP) and self.targeted_player is not None:
                            self.laser_shot_without_lock()

                if isinstance(self.images_copy, list):
                    self.image, self.rect = self.rot_center(
                        self.images_copy[self.index],
                        self.spaceship_aim + self.spaceship_aim_offset,
                        self.rect)
                    if self.index < len(self.images_copy) - 1:
                        self.index += 1
                    else:
                        self.index = 0

                else:
                    self.image, self.rect = self.rot_center(
                        self.images_copy,
                        self.spaceship_aim + self.spaceship_aim_offset,
                        self.rect)
                if self.rect.top > self.gl.screen.get_height():
                    self.quit()
            """
            # sprite with y coordinates < 0 (not yet visible)
            else:
                # the sprite has not started to move
                if self.waypoint == 0:
                    self.position = self.gl.vector1 + self.offset
                    self.rect.center = self.position
                else:
                    # sprite has moved (waypoint !=0) and moved upward
                    # and got outside the delimited SCREENRECT
                    # self.show_waypoint()
                    self.is_waypoint_passed()
                    # add the background vertical speed
                    self.position += self.vector + Vector2(0, 1)
                    self.rect.center = self.position
            """
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS


class GroundEnemyGenerator(EnemyParentClass):
    initialized = False

    def __init__(self,
                 gl_,
                 enemy_,
                 timing_=35,
                 layer_: int = -5):

        EnemyParentClass.__init__(self, gl_)

        self._layer = layer_
        self.enemy_ = enemy_
        self.gl = gl_

        # player causing damage to the enemy
        self.player_inflicting_damage = None
        # choose a player right from the start
        self.targeted_player = self.select_player()
        self.lock_on = False

        if isinstance(self.gl.All, LayeredUpdates):
            self.gl.All.change_layer(self, layer_)

        self.images_copy = self.enemy_.object_animation.copy()
        self.image = self.images_copy[0] if isinstance(self.enemy_.object_animation.copy(), list) \
            else self.images_copy

        self.rect = self.image.get_rect(center=(self.enemy_.pos.x * self.gl.RATIO.x,
                                                self.enemy_.pos.y * self.gl.RATIO.y))
        self.index = 0
        self.dt = 0
        self.damage = 0
        self.position = Vector2(self.enemy_.pos.x * self.gl.RATIO.x,
                                self.enemy_.pos.y * self.gl.RATIO.y)

        # Turret offset position on the map from the top left corner.
        self.offset = Vector2(self.position.x, self.position.y)
        self.vector = Vector2(0, 0)

        # Enemy life points
        self.hp = self.enemy_.hp

        # ---   for compatibility with other class ---
        self.explosion_sprites = enemy_.explosion_sprites
        self.impact_sprite = enemy_.impact_sprite
        self.impact_sound = enemy_.impact_sound

        self.position = self.gl.vector1 + self.offset
        self.rect.center = self.position

        self.timing = timing_
        # if the enemy has a shield
        if self.enemy_.shield:
            # EnemyShield.containers = self.gl.All
            # EnemyShield.images = self.enemy_.shield.sprite
            # EnemyShield._shield_up = False

            self.shield = EnemyShield(gl_=self.gl, containers_=self.gl.All,
                                      images_=self.enemy_.shield.sprite,
                                      object_=self, loop_=True, timing_=self.timing,
                                      event_='SHIELD_INIT', shield_type=self.enemy_.shield)

    def update(self):
        if isinstance(self.images_copy, list):
            self.image = self.images_copy[self.index]

        if self.rect.bottom > 0:
            # add the background vertical speed
            self.position += self.vector + Vector2(0, 1)
            self.rect.center = self.position

        else:
            self.position = self.gl.vector1 + self.offset
            self.rect.center = self.position

        if self.dt > self.timing:

            if self.rect.bottom > 0:

                if self.rect.top > self.gl.screen.get_height():
                    self.quit()
            self.dt = 0

            if self.index >= len(self.images_copy) - 1:
                self.index = 0
            else:
                self.index += 1

        self.dt += self.gl.TIME_PASSED_SECONDS


def collision():
    if bool(GL.PLAYER_GROUP):

        # check if the target dummy is active
        # the target dummy represent the pygame square a nuke
        # has to collide with to trigger the explosion.
        # insert the dummy rectangle in the GROUP_UNION containing
        # all enemies rectangles (at this point the dummy target will be considered
        # as a potential collider but also an enemy rectangle.
        # This is why it is essential to introduce "if object1 not in GL.nuke_aiming_point:"
        # before processing each weapons (dummy rectangle should not be identify as an enemy target.
        # Exception for nuke missile.
        if bool(GL.nuke_aiming_point):
            for dummy in GL.nuke_aiming_point:
                GL.GROUP_UNION.add(dummy)

        CollisionDetection(GL,
                           Score,
                           Enemy,
                           (GroundEnemyTurret, GroundEnemyDrone, GroundEnemyGenerator),
                           Gems,
                           PlayerLife,
                           Follower
                           )  # EnemyHomingMissile


def level_1(music_level_=25.0,
            sfx_volume_=25.0,
            gamma_value_=100,
            resolution_="800x1024",  # "1024x768", # '800x1024',
            ship_name_={0: 'NEMESIS', 1: 'LEVIATHAN'},
            player_=2):
    """

    :param music_level_: integer; range [0 ... 100] represent the music volume in %
    :param sfx_volume_ : integer; range [0 ... 100] represent the sound volume in %

    :param gamma_value_: integer; Gamma display float value in range [0 ... 100].
    Change the hardware gamma ramps
    set_gamma(red, green=None, blue=None) -> bool
    Set the red, green, and blue gamma values on the display hardware.
    If the green and blue arguments are not passed, they will both be the same as red.
    Not all systems and hardware support gamma ramps, if the function succeeds it will return True.
    A gamma value of 1.0 creates a linear color table.
    Lower values will darken the display and higher values will brighten.

    :param resolution_ : string; screen resolution such as width x height
    :param ship_name_  : python dict; Dict containing the player aircraft names, default 0:
    'NEMESIS', 1: 'LEVIATHAN'}
    would mean that player 1 aircraft is NEMESIS and player 2 name is LEVIATHAN
    :param player_     : integer; number of active player for this level
    :return: void
    """
    print("LEVEL 1 LOADING")
    # MUSIC LEVEL CONVERTED TO RANGE [0.0 ... 1.0] FOR pygame MIXER
    music_level_ /= 100.0

    # SOUND LEVEL CONVERTED TO RANGE [0.0 ... 1.0]
    sound_level = sfx_volume_ / 100.0

    print("Music volume     : {v}".format(v=music_level_ * 100))
    print('SFX volume       :', sound_level * 100)  # volume in %
    print('Difficulty level :', GL.DIFFICULTY_VALUE)
    print('Gamma value      :', gamma_value_ / 100.0)
    print('Particles        :', GL.PARTICLES_VALUE)
    print('Screen mode      :', GL.SCREEN_MODE_VALUE)
    print('Screen size      :', resolution_)
    print('Player(s)        : %s ' % player_)

    GL.JOYSTICK = JoystickCheck()
    if pygame.joystick.get_init():
        for i_ in range(pygame.joystick.get_count()):
            print('Joystick %s : %s player : %s' %
                  (i_, pygame.joystick.Joystick(i_).get_name(), pygame.joystick.Joystick(i_)))
    else:
        print('Joystick : not initialised')

    # UPDATING THE VOLUME
    GL.MUSIC_LEVEL = music_level_
    GL.SOUND_LEVEL = sound_level

    # DEFINE THE SCREEN RECTANGLE (SCREEN WIDTH & HEIGHT)
    width = int(resolution_.split('x')[0])
    height = int(resolution_.split('x')[1])
    SCREENRECT = pygame.Rect(0, 0, width, height)

    # UPDATE RATIO VARIABLE
    GL.RATIO.x = float(width) / SCREENRECT.width
    GL.RATIO.y = float(height) / SCREENRECT.height
    print('RATIO : ', GL.RATIO)

    # UPDATE screenrect variable
    GL.screenrect = SCREENRECT

    # LOAD THE DRIVER AND SET THE SCREEN POSITION (WINDOWED MODE)
    screen_position = (0, 0)
    os.environ['SDL_VIDEODRIVER'] = GL.DRIVER
    os.environ['SDL_VIDEO_WINDOW_POS'] = str(screen_position[0]) + "," + str(screen_position[1])

    # VSYNC SLOW DOWN THE GAME
    GL.screen = pygame.display.set_mode(
        SCREENRECT.size, pygame.FULLSCREEN | pygame.SCALED, 32)

    pygame.init()
    print('Smoothscale acceleration backend : %s ' %
          (pygame.transform.get_smoothscale_backend()))

    freetype.init(cache_size=64, resolution=72)

    pygame.mixer.pre_init(44100, 16, 2, 4095)

    pygame.display.set_caption("Cobra")
    pygame.display.set_icon(COBRA)

    # HIDE THE MOUSE CURSOR
    pygame.mouse.set_visible(False)

    # todo check if this is crashing the game
    gamma = pygame.display.set_gamma(gamma_value_ / float(100.0))
    if not gamma:
        print("Gamma cannot be adjusted, not all systems and hardware support gamma ramps")

    # UPDATE VARIABLES SHIP_NAME & PLAYER_NUMBER
    GL.SHIP_NAME = ship_name_
    GL.PLAYER_NUMBER = player_

    GL.All = LayeredUpdatesModified()

    # DEFINE THE BACKGROUND
    background_layers(SCREENRECT, GL)

    # ----------- Instances  ---------------------
    # Enemy.containers        = GL.enemy_group, GL.All
    Player.containers = GL.All

    vertex_bright_stars = Group()
    vertex_shooting_star = Group()

    # SpaceShip sound control
    # Reserved 20 channels for the spaceship sound effects.
    # INITIALIZE THE SOUND SERVER PRIOR INSTANTIATING THE PLAYER CLASS
    GL.SC_spaceship = SoundControl(GL.screenrect, 50)
    GL.SC_explosion = SoundControl(GL.screenrect, 50)

    # TURRET INIT
    TURRET_INITIALISED = [True, True]
    TURRET_TARGET_LOCKED = [None, None]

    player_origin = (SCREENRECT.midbottom[0] + 100, SCREENRECT.midbottom[1] + 80)
    player2_origin = (SCREENRECT.midbottom[0] - 100, SCREENRECT.midbottom[1] + 80)

    # ONLY ONE PLAYER
    if player_ == 1:
        # PLAYER 1 INITIALISATION
        # Check if at least one joystick is initialised and passed
        # the joystick player as reference to the Player class
        # Passed value None if no joystick
        Player.images = ALL_SPACE_SHIP[GL.SHIP_NAME[0]]
        GL.player = Player(
            Score_=Score,
            follower_=Follower,
            gl_=GL,
            timing_=15,
            layer_=-1,
            origin_=player_origin,
            name_=GL.SHIP_NAME[0],
            p_='1',
            joystick_=GL.JOYSTICK.inventory[0] if GL.JOYSTICK is not None and
                                                  len(GL.JOYSTICK.inventory) > 0 else None)

        # joystick_=GL.JOYSTICK.inventory[0]
        # if pygame.joystick.get_init() else None)  # --> player 1

        # Add PLAYER1 to the group of players
        # GL.PLAYER_GROUP.add(GL.player)

        # **** FORCE PLAYER 2 to exist for GROUP_COLLISION  ****
        # GL.player2 = GL.player

    # TWO PLAYERS
    elif player_ == 2:
        # PLAYER 1 INITIALISATION
        # Check if at least one joystick is initialised and passed
        # the joystick player as reference to the Player class
        # Passed value None if no joystick

        Player.images = ALL_SPACE_SHIP[GL.SHIP_NAME[0]]
        GL.player = Player(
            Score_=Score,
            follower_=Follower,
            gl_=GL,
            timing_=15,
            layer_=-1,
            origin_=player_origin,
            name_=GL.SHIP_NAME[0],
            p_='1',
            joystick_=GL.JOYSTICK.inventory[0] if GL.JOYSTICK is not None and
                                                  len(GL.JOYSTICK.inventory) > 0 else None)
        # joystick_=GL.JOYSTICK.inventory[0] if
        # pygame.joystick.get_init() else None)  # --> player 1
        # Add PLAYER1 to the group of players
        # GL.PLAYER_GROUP.add(GL.player)

        # A LOCAL JOYSTICK HAS TO BE CONNECTED TO ALLOW A SECOND PLAYER OR
        # IF A PLAYER HAS JOIN THE GAME VIA NETWORK
        # if pygame.joystick.get_count() > 0 or GL.P2JNI is not None:
        # PLAYER 2 INITIALISATION
        Player.images = ALL_SPACE_SHIP[GL.SHIP_NAME[1]]
        GL.player2 = Player(
            Score_=Score,
            follower_=Follower,
            gl_=GL,
            timing_=15,
            layer_=-1,
            origin_=player2_origin,
            name_=GL.SHIP_NAME[1],
            p_='2',
            joystick_=GL.P2JNI)
        # Add PLAYER2 to the group of players
        # GL.PLAYER_GROUP.add(GL.player2)

    DisplayScore(timing_=15, gl_=GL)

    # CREATE A NEW GROUP AND ADD GL.ASTEROIDS AND GL.ENEMY_GROUP
    GL.GROUP_UNION = Group()
    GL.GROUP_UNION.add(GL.enemy_group)

    # HUD DISPLAY NUKES, MISSILES AND LIFE
    DisplayNukesLeft(GL, timing_=244)
    DisplayMissilesLeft(GL, timing_=244)

    DisplayLife(GL, NEMESIS_LIFE_INVENTORY.copy() if
        GL.player.name == 'NEMESIS' else LEVIATHAN_LIFE_INVENTORY.copy(), timing_=244)

    GL.GAME_START = time.time ()
    GL.PAUSE_TOTAL_TIME = 0

    # LOAD ALL ENEMIES FROM LEVEL1
    GL.enemy_group = level1(GL, Enemy, GroundEnemyTurret, GroundEnemyDrone,
                            GroundEnemyGenerator, GL.enemy_group)

    FX074_XML = dict(xml_get_weapon('xml/Weapon.xml', 'LASER_FX074'))
    FX086_XML = dict(xml_get_weapon('xml/Weapon.xml', 'LASER_FX086'))
    GV500_XML = dict(xml_get_weapon('xml/G5V200.xml', 'G5V200'))
    LASER_FX074_DICT = xml_parsing(FX074_XML)
    LASER_FX086_DICT = xml_parsing(FX086_XML)
    G5V200_DICT = xml_parsing_G5V200(GV500_XML)

    # Bossenemy = Station(
    #     gl_           = GL,
    #     weapon1_      = LASER_FX074_DICT,
    #     weapon2_      = LASER_FX086_DICT,
    #     attributes_   = G5V200_DICT,
    #     group_        = GL.All,
    #     surface_      = STATION,
    #     pos_x         = ((SCREENRECT.w - STATION.get_width()) >> 1) + (STATION.get_width() >> 1),
    #     pos_y         = -800,
    #     blend_        = 0,
    #     layer_        = -2,
    #     timing_       = 0
    #     )
    #
    # # ADD STATION TO ENEMY GROUP OTHERWISE PLAYER WEAPONS WILL NOT
    # # DESTROY IT
    # GL.enemy_group.add(Bossenemy)
    #
    # GV500 = EnemyBoss(gl_           = GL,
    #                   weapon1_      = LASER_FX074_DICT,
    #                   weapon2_      = LASER_FX086_DICT,
    #                   attributes_   = G5V200_DICT,
    #                   containers_   = GL.All,
    #                   pos_x         = -200,
    #                   pos_y         = -150,
    #                   image_        = G5V200_ANIMATION,
    #                   timing_       = 0,
    #                   layer_        = -2,
    #                   _blend        = 0)
    # ADD GV500 TO ENEMY GROUP OTHERWISE PLAYER WEAPONS WILL NOT
    # DESTROY IT
    # GL.enemy_group.add(GV500)

    # *** MOUSE DEACTIVATED
    # pygame.event.set_blocked(4)  # No mouse events

    # TODO DEFINE screen.get_width() and screen.get_height() IN GL
    # ADD  ANIMATED STARS TO THE BACKGROUND
    for r in range(5):
        vertex_bright_stars.add(BrightStars(
            group_=(vertex_bright_stars, GL.All),
            bv_=Vector2(0.0, 1.0 / 3.0),
            gl_=GL,
            pos_=Rect(0, 0, GL.screen.get_width(), GL.screen.get_height()),
            layer_=-8,
            acceleration_=True,
            acc_speed_=6.0,
            timing_=0.0))

    # ADD SHOOTING STARS TO BACKGROUND
    ShootingStar(SHOOTING_STAR, (vertex_shooting_star, GL.All), gl_=GL, layer_=-8)

    # START DIALOG COBRA AND MASAKO
    start_dialog(GL)

    # FLAG TRUE | FALSE, TRUE PLAYER IS STILL ALIVE
    GL.FAIL = False

    # START THE FLARE EFFECT
    start_flare_effect(GL)

    # Start the main loop
    start(music_level_, vertex_bright_stars, vertex_shooting_star)


def start(music_level, vertex_bright_stars, vertex_shooting_star):
    print("GAME STARTING")
    transition_variable = 100

    # TRANSITION EFFECT
    # Load the transition screen
    # todo need to check if the file exist first
    TRANSITION_ARRAY = None
    try:
        GL.TRANSITION_BACKGROUND = pygame.image.load('Assets/Transition.png').convert()
        TRANSITION_ARRAY = pixels3d(GL.TRANSITION_BACKGROUND)
    except:
        ...

    if GL.TRANSITION_BACKGROUND is not None:
        GL.TRANSITION_BACKGROUND = scale(GL.TRANSITION_BACKGROUND, GL.screenrect.size)
        TRANSITION_ARRAY = pixels3d(GL.TRANSITION_BACKGROUND)

    bld_surface = smoothscale(BLOOD_SURFACE, (GL.screen.get_width(), GL.screen.get_height()))
    BLOOD_MASK = asarray(pixels_alpha(bld_surface) / float(255.0), numpy.float32)

    MUSIC_INDEX = 0
    pygame.mixer.music.load(MUSIC_PLAYLIST[MUSIC_INDEX])
    pygame.mixer.music.play(0)
    pygame.mixer.music.set_volume(music_level)
    pygame.mixer.music.queue(MUSIC_PLAYLIST[MUSIC_INDEX + 1])
    pygame.mixer.music.set_endevent(NO_MORE_MUSIC)

    GL.FIRE_PARTICLES_FX = Group()

    t_start = time.time()

    CLOCK = pygame.time.Clock()

    GL.SC_spaceship.play(sound_=WHOOSH, loop_=False, priority_=0, volume_=GL.SOUND_LEVEL,
                         fade_out_ms=0, panning_=False, name_='WHOOSH', x_=0)

    if len(VERTEX_ARRAY_MP) > 0:
        for sprite in VERTEX_ARRAY_MP:
            if hasattr(sprite, 'kill'):
                sprite.kill()

    sound_icon = pygame.image.load('Assets/Graphics/GUI/sound_icon1.png')
    sound_icon = smoothscale(sound_icon, (64, 64))

    level_icon = pygame.image.load('Assets/Graphics/GUI/device/switchGreen04.png').convert_alpha()
    level_icon = rotozoom(level_icon, 90, 0.7)

    SL = SoundLevel(sound_icon, level_icon, volume_=GL.SOUND_LEVEL, scale_=0.4)
    ML = SoundLevel(sound_icon, level_icon, volume_=GL.MUSIC_LEVEL, scale_=0.4)

    GL.FPS_AVG = [GL.MAXFPS]
    GL.VideoBuffer = []

    # global JSERVER
    # if not JSERVER.is_alive():
    #             JSERVER = JoystickServer(GL, '192.168.1.106', 1024, 0)
    #             JSERVER.start()

    # global JCLIENT
    # if GL.JOYSTICK is not None and len(GL.JOYSTICK.inventory) > 0:
    #     if isinstance(GL.JOYSTICK.inventory[0], pygame.joystick.JoystickType):
    #         if not JCLIENT.is_alive():
    #             JCLIENT = JoystickClient(GL, '192.168.1.112', 1025, 0)
    #             JCLIENT.start()

    # -------- Main Program Loop -----------

    # SHOW FPS VALUE ON TOP THE LEFT CORNER
    ShowFps(GL, 60.0, 0, 0)
    # SHOW MOUSE POSITION ON TOP LEFT CORNER
    ShowMousePosition(GL, 0, 0)

    # DISPLAY A COUNT DOWN 4 to 0
    BindDefault(
        GL.All, COUNTDOWN_NUMBER_256x256, GL,
        GL.screenrect.w // 2 - COUNTDOWN_NUMBER_256x256[0].get_width() // 2,
        GL.screenrect.h // 2 - COUNTDOWN_NUMBER_256x256[0].get_height() // 2,
        timing_=1000, blend_=BLEND_RGB_MAX)

    # ------------------------------------------
    # TWEAKS
    videobuffer_append = GL.VideoBuffer.append
    lz4_frame_compress = lz4frame.compress
    lz4_frame_decompress = lz4frame.decompress
    gl_screen = GL.screen
    gl_screenrect = GL.screenrect
    gl_screen_blit = gl_screen.blit
    get_pressed = pygame.key.get_pressed
    event_get = pygame.event.get
    mouse_get_rel = pygame.mouse.get_rel
    mouse_get_pos = pygame.mouse.get_pos
    event_clear = pygame.event.clear
    SC_spaceship = GL.SC_spaceship
    SC_explosion = GL.SC_explosion
    mixer_set_volume = pygame.mixer.music.set_volume


    # todo remove if fisheye shader is not used
    # shader_fisheye24_footprint_inplace(GL.screen)
    #
    # s = shader_rain_footprint_inplace(pygame.transform.smoothscale(GL.screen, (128, 128)))
    # RAIN_LIST = []
    # for i in range(80):
    #     RAIN_LIST.append((randint(32, 764), randint(32, 900)))

    # pygame.mouse.set_pos(GL.MOUSE_POS[0], GL.MOUSE_POS[1])
    pygame.mouse.set_pos(GL.screen.get_width() >> 1, (GL.screen.get_height() >> 1) + 300)

    # <<<< ----- FIX BUG for Enemy turret & drones showing at layer 0 ----- >>>>>
    # Not sure what causing this
    for spr in GL.enemy_group:
        if isinstance(spr, GroundEnemyTurret):
            spr._layer = -5
            GL.All.change_layer(spr, -5)
        if isinstance(spr, GroundEnemyDrone):
            spr._layer = -5
            GL.All.change_layer(spr, -5)

    while not GL.STOP_GAME:

        # pygame.event.pump()

        keys = get_pressed()
        GL.KEYS = keys

        # - decrease SFX volume
        if keys[K_KP_MINUS]:
            if GL.SOUND_LEVEL >= 0.02:
                GL.SOUND_LEVEL = round(GL.SOUND_LEVEL - 0.01, 2)
            else:
                GL.SOUND_LEVEL = 0
            SL.update_volume(GL.SOUND_LEVEL)
            SC_spaceship.update_volume(volume_=GL.SOUND_LEVEL)
            SC_explosion.update_volume(volume_=GL.SOUND_LEVEL)

        # + increase SFX sound volume
        if keys[K_KP_PLUS]:
            if GL.SOUND_LEVEL <= 0.98:
                GL.SOUND_LEVEL = round(GL.SOUND_LEVEL + 0.01, 2)
            else:
                GL.SOUND_LEVEL = 1.0
            SL.update_volume(GL.SOUND_LEVEL)
            SC_spaceship.update_volume(volume_=GL.SOUND_LEVEL)
            SC_explosion.update_volume(volume_=GL.SOUND_LEVEL)

        # - decrease music volume
        if keys[pygame.K_MINUS]:
            if GL.MUSIC_LEVEL > 0.01:
                GL.MUSIC_LEVEL -= 0.01
            ML.update_volume(GL.MUSIC_LEVEL)
            mixer_set_volume(GL.MUSIC_LEVEL)

        # = increase music level
        if keys[pygame.K_EQUALS]:
            if GL.MUSIC_LEVEL < 0.99:
                GL.MUSIC_LEVEL += 0.01
            ML.update_volume(GL.MUSIC_LEVEL)
            mixer_set_volume(GL.MUSIC_LEVEL)

        for event in event_get():

            keys = get_pressed()

            if event.type == pygame.MOUSEMOTION:
                GL.MOUSE_POS = event.pos
                mouse_x, mouse_y = mouse_get_rel()
                mouse_vector = Vector2(mouse_x, mouse_y)

                if mouse_vector.length() != 0:
                    mouse_vector.normalize_ip()

                if GL.player.alive():
                    GL.player.move(mouse_vector / 10.0)
                    GL.player.force_centre(mouse_get_pos())

            if keys[K_ESCAPE]:
                print('Quitting')
                GL.STOP_GAME = True  # stop the game main loop
                event_clear()
                # if JSERVER is not None:
                #     print('\nSending termination signal to joystick server socket...')
                #     send_sigterm(host, port)
                # else:
                #     print('\nCannot send termination signal to joystick server socket...')
                global ABORT_GAME
                ABORT_GAME = True

            elif keys[K_PAUSE]:
                GL.PAUSE = True
                print('game is pause')
                GL.PAUSE_TIMER = time.time()
                game_pause(GL)
                # pygame.mixer.music.unpause()

            # full screen
            elif keys[K_F1]:
                GL.PAUSE = True
                print('game is pause')
                GL.PAUSE_TIMER = time.time()
                toggle_fullscreen(GL)
                gl_screen = pygame.display.get_surface()
                gl_screenrect = gl_screen.get_rect()
                gl_screen_blit = gl_screen.blit
                GL.SC_spaceship.display_size_update(gl_screenrect)
                GL.SC_explosion.display_size_update(gl_screenrect)

            # screenshots
            elif keys[K_F8]:
                pygame.image.save(gl_screen,
                                  'Assets/Screenshot/Screendump' + str(GL.screendump) + '.png')
                GL.screendump += 1

            # todo bomb is coded only for GL.player
            elif keys[K_b]:
                if GL.player.alive():
                    if not SC_spaceship.get_identical_sounds(BOMB_RELEASE):
                        SC_spaceship.play(
                            sound_=BOMB_RELEASE, loop_=False, priority_=2,
                            volume_=GL.SOUND_LEVEL, fade_out_ms=0, panning_=False,
                            name_='BOMB_RELEASE', x_=GL.player.rect.centerx)
                    if len(GL.BOMB_CONTAINER) < 30:

                        DisplayCrack(image_ = [GROUND_CRACK1, GROUND_CRACK2, GROUND_CRACK3][
                                         randint(0, 2)],
                                     gl_=GL,
                                     center_x = GL.player.rect.centerx,
                                     center_y = GL.player.rect.centery,
                                     timing_ = 5)

                        for r in range(25):
                            XBomb(gl_=GL, layer_=-4, timing_=16.67, collision_=True)

            if event.type == NO_MORE_MUSIC:
                MUSIC_INDEX += 1
                pygame.mixer.music.load(MUSIC_PLAYLIST[MUSIC_INDEX % 2])
                pygame.mixer.music.play(0)

        if GL.FRAME > 300:
            GL.vector1 += GL.bv

        # *** TESTING
        # if GL.FRAME > 1050:
        #     GL.bv = Vector2(0, 0)

        # create a new group
        GL.GROUP_UNION = Group()
        GL.GROUP_UNION.add(GL.enemy_group)

        collision()

        # CHECK THE OTHER FRAME
        if GL.FRAME % 2 == 0:

            GL.player.energy_bar.current_value = int(GL.player.aircraft_specs.energy)
            energy = GL.player.energy_bar.display_gradient()
            energy_hud_copy = ENERGY_HUD.copy()
            energy_hud_copy.blit(GL.player.energy_bar.display_value(), (50, 35))
            if energy:
                energy_hud_copy.blit(energy, (87, 23))

            BACKGROUND_HUDS[0] = energy_hud_copy

            GL.player.life_bar.current_value = int(GL.player.aircraft_specs.life)
            life = GL.player.life_bar.display_gradient()
            life_hud_copy = LIFE_HUD.copy()
            life_hud_copy.blit(GL.player.life_bar.display_value(), (220, 65))

            BACKGROUND_HUDS[1] = apparent_damage(GL.player, life_hud_copy, life)

        # Update the list of sound objects for the SpaceShip mixer
        SC_spaceship.update()

        # update the list of sound objects for the explosion mixer
        SC_explosion.update()

        GL.All.update()
        GL.All.draw(gl_screen)

        # ADD SPACE DUST IF LOW COUNT
        if len(VERTEX_ARRAY_DUST) < 15:
            cosmic_dust(GL)

        if GL.FRAME > 250:
            GL.ACCELERATION = 1

        # DISPLAY MISSILE PARTICLES
        # IF ANY IN THE VERTEX_ARRAY_MP
        if len(VERTEX_ARRAY_MP) > 0:
            for particle in VERTEX_ARRAY_MP:
                particle.update(gl_screen)

        # dust particles
        if len(VERTEX_ARRAY_DUST) > 0:
            cosmic_dust_display(GL)

        # Particles
        if len(VERTEX_PARTICLEFX) > 0:
            display_particlefx(GL)

        # impact sprites
        if len(GL.VERTEX_IMPACT) > 0:
            laser_impact_fx(GL)

        # # display all the ligth effects
        if len(LIGHTS_VERTEX) > 0:
            display_lights(gl_screen)

        if len(VERTEX_BULLET_HELL) > 0:
            loop_display_bullets(GL)

        if len(STATION_VERTEX_BULLET_HELL) > 0:
            station_loop_display_bullets(GL)

        if len(GL.FIRE_PARTICLES_FX) > 0:
            Player.display_fire_particle_fx(GL.FIRE_PARTICLES_FX)

        if len(GL.CURRENT_TARGET) > 0:
            GL.CURRENT_TARGET[0].update_poly(gl_screen)

        if len(GL.DEBRIS_CONTAINER) > 0:
            show_debris(GL)

        if len(VERTEX_ARRAY_SUBSURFACE) > 0:
            display_burst(
                screen_=GL.screen,
                vertex_array_=VERTEX_ARRAY_SUBSURFACE,
                blend_=0)



        if GL.FRAME < 2000:
            if len(vertex_bright_stars) < 5:
                for r in range(5):
                    BrightStars(
                        group_=(vertex_bright_stars, GL.All),
                        bv_=Vector2(0.0, 1.0 / 3.0),
                        gl_=GL,
                        pos_=Rect(0, 0, gl_screen.get_width(), -gl_screen.get_height()),
                        layer_=-8,
                        acceleration_=True if GL.FRAME < 300 else False,
                        timing_=0)

            if randint(0, 1000) > 998:
                ShootingStar(SHOOTING_STAR, (vertex_shooting_star, GL.All),
                             gl_=GL, layer_=-8, timing_=8)

        if len(GL.VERTEX_DEBRIS) > 0:
            EnemyParentClass.show_debris(gl_=GL, screen_=gl_screen)

        if len(CHILD_FLARE_INVENTORY) > 0:
            display_flare_sprite(GL.LENS_VECTOR + GL.LENS_VECTOR_SPEED, GL.LENS_VERTICAL_SPEED)
            GL.LENS_VERTICAL_SPEED += Vector2(0, 1.0 / 3.0)
            GL.LENS_VECTOR_SPEED += Vector2(1.0 / 4.8, -1.0 / 2.2)
            GL.FLARE_EFFECT_CENTRE += (0, 1.0 / 3.0)

        if GL.SHOCKWAVE:
            # shake the screen
            tm = lateral_dampening(GL.FRAME, amplitude_=50.0, duration_=35, freq_=5.0)

            if abs(tm) < 0.8:
                GL.SHOCKWAVE = False
            else:
                gl_screen_blit(gl_screen, (tm, 0), special_flags=0)

        # print(GL.player.aircraft_specs.score, GL.player2.aircraft_specs.score)

        if GL.player.aircraft_specs.life < GL.player.aircraft_specs.max_health:
            # 1.0 - xxx determine the blend %
            # if you want the blend % to be low than 100% specify 1.2 or a number above
            # 1.0. that way the blend will never reach 100% screen fully red (which might be
            # a little excessive). Blend is a multi-processing job to alter the entire windows
            # pixels in real time.
            blood(gl_screen, BLOOD_MASK,
                  1.0 - (GL.player.aircraft_specs.life /
                         GL.player.aircraft_specs.max_health))

        # # todo for both player if two player
        # if GL.player.aircraft_specs.life < 200:
        #
        #     # Top    (0, 0)
        #     gl_screen_blit(BLOOD_SURFACE[0], (0, 0),
        #                    special_flags=BLEND_RGBA_ADD)
        #     # left   (0, 117)
        #     gl_screen_blit(BLOOD_SURFACE[1],
        #                    (0, BLOOD_SURFACE[0].get_height()),
        #                    special_flags=BLEND_RGB_ADD)
        #     # right  (704, 117)
        #     gl_screen_blit(BLOOD_SURFACE[2],
        #                    (gl_screen.get_width() - BLOOD_SURFACE[2].get_width(),
        #                     BLOOD_SURFACE[0].get_height()),
        #                    special_flags=pygame.BLEND_ADD)
        #     # bottom (97, 966)
        #     gl_screen_blit(BLOOD_SURFACE[3],
        #                    (0, gl_screen.get_width() - BLOOD_SURFACE[3].get_height()),
        #                    special_flags=BLEND_RGBA_ADD)

        # Only one instance (one player) can paint
        # the screen red at the time
        if Player.player_hurt[0] != 0:
            Player.hurt_effect(GL)

        # Player lost, restarting the level
        if GL.FAIL:
            print("Average FPS : %s" % (sum(GL.FPS_AVG) / len(GL.FPS_AVG)))
            print('PLAYER_1 score: ', GL.player.aircraft_specs.score)
            print('PLAYER_1 gems : ', GL.player.aircraft_specs.gems)
            print('PLAYER_1 gems value: ', GL.player.aircraft_specs.gems_value)
            print('PLAYER_1 life left : ', GL.player.aircraft_specs.life_number)
            if GL.player2:
                print('P2 score: ', GL.player2.aircraft_specs.score)
                print('P2 gems : ', GL.player2.aircraft_specs.gems)
                print('P2 gems value: ', GL.player2.aircraft_specs.gems_value)
                print('P2 life left : ', GL.player2.aircraft_specs.life_number)

            GL.STOP_GAME = True

        # # DEBUG SPRITE ISSUES (UNCOMMENT) OR COMMENT OUT IF NOT USED
        # for spr in GL.All:
        #
        #     if isinstance(spr, EnemyBoss) or isinstance(spr, GroundEnemyTurret):
        #         # print(len(GL.All), spr, GL.All.get_layer_of_sprite(spr))
        #         if isinstance(spr, GroundEnemyTurret):
        #             print(spr._layer)
        #             # GL.All.change_layer(spr, -5)
        #         ...
        #     ...
        # for spr in GL.enemy_group:
        #
        #     if isinstance(spr, EnemyBoss) or isinstance(spr, GroundEnemyTurret):
        #         print(len(GL.All), spr, GL.All.get_layer_of_sprite(spr))
        #         if isinstance(spr, GroundEnemyTurret):
        #             print(spr._layer)
        #             # GL.All.change_layer(spr, -5)
        #         ...
        #     ...

        # print(GL.player.aircraft_specs.rank, GL.player.aircraft_specs.level)

        # CALL THE METHOD TO INCREASE THE SCREEN BRIGHTNESS OR THE
        # SCREEN COLORATION
        if GL.nuke > 0:
            nuke_flash(GL)

        # CREATE A TRANSITION EFFECT WHEN PLAYER RESTART
        # OR AT EACH LEVEL START
        if transition_variable > 0:
            if GL.TRANSITION_BACKGROUND is not None:
                # 60FPS perfs
                transition_ = blend(
                    source_=gl_screen,
                    destination_= TRANSITION_ARRAY,
                    # TRANSITION_ARRAY,
                    percentage_=transition_variable)

                gl_screen_blit(transition_, (0, 0))

            transition_variable -= 1

        # display the sound level indicator and the music level indicator
        if SL.value > 1:
            gl_screen_blit(SL.image, (10, 250))
        if ML.value > 1:
            gl_screen_blit(ML.image, (10, 280))

        # update Sound level and music menu visibility
        SL.update_visibility()
        ML.update_visibility()

        if random.randint(0, 1000) > 985:
            # REDUCE THE SCREEN SIZE BY 2, APPLY TRANSFORMATION AND RESCALE x2
            scr = pygame.display.get_surface()
            w_ = scr.get_width()
            h_ = scr.get_height()
            reduce_screen = smoothscale(scr, (w_ >> 1, h_ >> 1))
            horizontal_glitch(reduce_screen, 1, 0.3, (50 - GL.FRAME) % 100)
            glitch_screen_x2 = scale2x(reduce_screen)
            gl_screen_blit(glitch_screen_x2, (0, 0))

        # aircraft_light(
        #     GL,
        #     GL.player,
        #     fast_=False,
        #     saturation_=False,
        #     # offset_x=0 + GL.WOBBLY if GL.WOBBLY != 0 else 0 +
        #     #   (damped_oscillation(GL.SHOCKWAVE_RANGE[GL.SHOCKWAVE_INDEX]) * 50) if GL.SHOCKWAVE
        #     # else 0,
        #     offset_x = 0 + tm if GL.SHOCKWAVE else 0,
        #     offset_y=-140)

        # **** TESTING
        # shader_hsl_surface24bit_inplace(GL.screen, 0.1+GL.FRAME/100)
        # shader_bloom_effect_array24(GL.screen, 90, True)
        # shader_fisheye24_inplace(GL.screen)

        # s = pygame.transform.scale(GL.screen, (128, 128))
        # shader_rain_fisheye24_inplace(s)
        # p = s.get_at((0, 0))
        # s.set_colorkey(p)
        # surf = pygame.Surface((128, 128)).convert()
        # surf.fill((0, 0, 0))
        # surf.blit(s, (0, 0))
        # for i in range(80):
        #     GL.screen.blit(surf, (RAIN_LIST[i][0], RAIN_LIST[i][1] + GL.FRAME),
        #     special_flags=pygame.BLEND_RGB_MAX)
        # shader_bloom_effect_array24(GL.screen, 20, True)
        # shader_rgb_split_inplace(GL.screen, 4)

        # scr_rect = GL.screen.get_rect()

        # if (GL.screenrect.w != scr_rect.w or GL.screenrect.h != scr_rect.h) and \
        #         gl_screen.get_flags() & pygame.FULLSCREEN:
        #     gl_screen.fill((0, 0, 0, 0), (GL.screenrect.w, 0,
        #     scr_rect.w - GL.screenrect.w, scr_rect.h))

        pygame.display.flip()

        # RECORD THE FRAME
        # CHECK IF MEM < 1GB
        # TODO vm() IS VERY SLOW FIND ALTERNATIVE
        # if vm().available > 1e9:
        # if GL.recording:
        #         screen_2 = smoothscale(gl_screen, (gl_screenrect.w >> 1, gl_screenrect.h >> 1))
        #         # videobuffer_append(
        #         #     lz4_frame_compress(tostring(screen_2, 'RGB', False), compression_level=1))
        #         videobuffer_append(tostring(screen_2, 'RGB', False))
        # else:
        #     # DISABLE THE CAPTURE
        #     GL.recording = False
        #     GL.VideoBuffer = []

        GL.FRAME += 1

        GL.TIME_PASSED_SECONDS = CLOCK.tick(GL.MAXFPS)  # CLOCK.tick_busy_loop(GL.MAXFPS)  # in ms

        # print(round(CLOCK.get_fps()), sum(GL.AVGFPS)/(len(GL.AVGFPS) +1), GL.TIME_PASSED_SECONDS, GL.FRAME)
        # , bool(GL.PLAYER_GROUP), len(GL.PLAYER_GROUP) == 0, \
        # SL.value)

        GL.SPEED_FACTOR = GL.TIME_PASSED_SECONDS / 1000.0
        fps = CLOCK.get_fps()
        GL.FPS_AVG.append(fps)
        GL.FPS_VALUE = fps

        # for instance in Follower.inventory:
        #    print(instance.event)

        # print(GL.P2JNI.axes_status if GL.P2JNI is not None else None)
        # print(GL.P2JNI.hats_status if GL.P2JNI is not None else None)
        # print(GL.P2JNI.button_status if GL.P2JNI is not None else None)

        # for r in GL.All.__dict__:
        #     print('\n', len(r))

    pygame.mixer.music.stop()
    GL.SC_explosion.stop_all()
    GL.SC_spaceship.stop_all()

    for item in GL.All:
        item.remove()
        item.kill()
    GL.All.empty()

    event_clear()

    for event in pygame.event.get():
        if hasattr(event, 'clear'):
            event.clear()

    pygame.mixer.stop()
    pygame.event.set_allowed(4)

    # STOP ESC BUTTON TO PRESS
    time.sleep(1)
    # Create a video
    # convert all the image into a AVI file (with 60 fps)
    # if GL.recording:
    #     WriteVideo(GL)


if __name__ == '__main__':

    import sys
    import platform

    print('Driver            : ', pygame.display.get_driver())
    print(pygame.display.Info())
    # New in pygame 1.9.5.
    try:
        print('Display(s)       : ', pygame.display.get_num_displays())
    except AttributeError:
        pass
    sdl_version = pygame.get_sdl_version()
    print('SDL version      : ', sdl_version)
    print('Pygame version   : ', pygame.version.ver)
    python_version = sys.version_info
    print('Python version   :  %s.%s.%s ' % (python_version[0], python_version[1], python_version[2]))
    print('Platform         : ', platform.version())
    print('Available modes  : ', pygame.display.list_modes())
    mem = vm().available
    print('Mem available    : %s %s' % (bytes_conversion(vm().available)))

    # todo start_audio_recording use pyaudio and this library is
    # todo not available with pip for python > 3.6

    if os.path.exists("Replay/GameVideo2.avi"):
        os.remove("Replay/GameVideo2.avi")

    if os.path.exists("Replay/GameReplay.avi"):
        os.remove("Replay/GameReplay.avi")

    # if GL.recording:
    #     start_audio_recording("Replay/SoundReplay.wav")

    ABORT_GAME = False

    while not ABORT_GAME:
        GL = GLOBAL()
        # GL.STOP_GAME = False
        # GL.FAIL = False
        level_1(resolution_=str(GL.screenrect.width) + "x" + str(GL.screenrect.height))



        # if len(GL.FPS_AVG) != 0:
        #     print("Average FPS : %s" % (sum(GL.FPS_AVG) / len(GL.FPS_AVG)))

    # if GL.recording:
    #     stop_audio_recording()
    #
    #     #    Merging audio and video signal
    #     import subprocess
    #     l = len(GL.FPS_AVG)
    #     avg = round(sum(GL.FPS_AVG) / float(l), 2)
    #
    #     # if abs(avg - 6) >= 0.01:
    # If the fps rate was higher/lower than expected, re-encode it to the expected
    #     #
    #     #     print("Re-encoding")
    #     #     cmd = "ffmpeg -r " + str(avg) + " -i Replay/GameVideo.avi -pix_fmt yuv420p
    #     -r 6 Replay/GameVideo2.avi"
    #     #     subprocess.call(cmd, shell=True)
    #     #
    #     #     print("Mixing")
    #     #     cmd = "ffmpeg -ac 2 -channel_layout stereo -i Replay/SoundReplay.wav
    #     -i Replay/GameVideo2.avi -pix_fmt yuv420p " + "Replay/GameReplay" + ".avi"
    #     #     subprocess.call(cmd, shell=True)
    #     #
    #     # else:
    #
    #     print("Normal recording\nMixing")
    #     # cmd = "ffmpeg -ac 2 -channel_layout stereo -i Replay/SoundReplay.wav
    #     -i Replay/GameVideo.avi -pix_fmt rgb24 " + "Replay/GameReplay" + ".avi"
    #
    #     cmd = "ffmpeg -ac 2 -channel_layout stereo -i Replay/SoundReplay.wav
    #     -i Replay/GameVideo.avi " \
    #           "-codec:v mpeg2video -qscale:v 2 -codec:a mp2 -b:a 192k
    #           -pix_fmt rgb24 " + "Replay/GameReplay" + ".avi"
    #     subprocess.call(cmd, shell=True)

    pygame.quit()
