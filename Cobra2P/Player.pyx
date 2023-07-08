# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


from CobraLightEngine import LightEngine


try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")

cimport numpy as np

from BrokenGlass import BrokenScreen
# from LIGHTS cimport area24_c
from MicroBots import MicroBots
from Shipspecs import NEMESIS_SPECS, LEVIATHAN_SPECS
from Constants import PLAYER_LIFE  # RAD_TO_DEG
from Sounds import DENIED_SOUND, ENGINE_ON, ENGINE_TURBO # NANOBOTS_SOUND, WARNING
import time  # random
from Shot import Shot
from GenericAnimation import GenericAnimation
from HomingMissile import Homing, Adaptive, Nuke
from SuperLaser_cython import super_laser_improved, display_super_laser  # , SuperLaser
from HorizontalBar import HorizontalBar

from Textures import ALL_SPACE_SHIP, \
    RADAR_INTERFACE, R_AIRCRAFT_TARGET, R_MISSILE_TARGET, R_BOSS_TARGET, R_GROUND_TARGET, \
    NANO_BOTS_CLOUD, SCREEN_IMPACT, SCREEN_IMPACT1, R_FRIEND, \
    PHOTON_PARTICLE_1, PHOTON_PARTICLE_1_NEG, \
    RADIAL3_ARRAY_64x64, RADIAL3_ARRAY_32x32_FAST, WING_WARNING_LIGHT,\
    WING_STANDBY_LIGHT
    # JETLIGHT_ARRAY, JETLIGHT_ARRAY_FAST, JETLIGHTCOLOR, WING_LIGHT

from AI_cython import SortByDeadliestTarget, colliders_c
from AI_cython import Threat
from Tools cimport make_transparent32, mask_shadow
from PygameShader.misc import create_horizontal_gradient_1d

from Weapons import SHOT_CONFIGURATION  # LASER_BEAM_BLUE_SMALL, LZRFX109
from MultipleShots import multiple_shots
from PlayerTurret import Turret, TURRET_INITIALISED
from libc.math cimport round as round_c
from BindSprite import *

from Radar import RadarClass as Radar, RADAR_CST
from pygame import BLEND_RGBA_ADD, Vector2, BLEND_RGB_ADD, BLEND_RGB_SUB, Surface, SRCALPHA, \
    RLEACCEL, BLEND_RGB_MIN, BLEND_RGB_MAX


from Sprites import Group
from Sprites cimport collide_mask, Sprite, LayeredUpdates
from WingTurret import WingTurret

try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject_CallFunctionObjArgs, PyObject, \
        PyList_SetSlice, PyObject_HasAttr, PyObject_IsInstance, \
        PyObject_CallMethod, PyObject_CallObject
    from cpython.dict cimport PyDict_DelItem, PyDict_Clear, PyDict_GetItem, PyDict_SetItem, \
        PyDict_Values, PyDict_Keys, PyDict_Items
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size, PyList_SetItem
    from cpython.object cimport PyObject_SetAttr

except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

from Shield import Shield, _shield_up, SHIELD_IMPACT, SHIELD_INVENTORY

cdef extern from 'Include/randnumber.c':
    float randRangeFloat(float lower, float upper)nogil;
    int randRange(int lower, int upper)nogil;


COLOR_GRADIENT = create_horizontal_gradient_1d(63)
cdef float ONE_255 = 1.0 / 255.0


from XML_parsing import xml_get_weapon, xml_parsing_missile

# Load the missile from xml file
STINGER_XML = dict(xml_get_weapon('xml/Missiles.xml', 'STINGER'))
BUMBLEBEE_XML = dict(xml_get_weapon('xml/Missiles.xml', 'BUMBLEBEE'))
WASP_XML = dict(xml_get_weapon('xml/Missiles.xml', 'WASP'))
HORNET_XML = dict(xml_get_weapon('xml/Missiles.xml', 'HORNET'))
NUKE_XML = dict(xml_get_weapon('xml/Missiles.xml', 'NUKE'))

# Parse the values into dictionaries
STINGER_FEATURES = xml_parsing_missile(STINGER_XML)
BUMBLEBEE_FEATURES = xml_parsing_missile(BUMBLEBEE_XML)
WASP_FEATURES = xml_parsing_missile(WASP_XML)
HORNET_FEATURES = xml_parsing_missile(HORNET_XML)
NUKE_FEATURES = xml_parsing_missile(NUKE_XML)

from HomingMissile import Homing, ExtraAttributes

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
class Player(Sprite):
    gun_offset = 0
    super_ready = False
    super_started = False
    images = []
    containers = None
    instances = [[], []]
    turbo_boost = [None, None]
    # True if the radar is already initialised
    radar_flag = False
    # True if the screen is painted red.
    # This flag will avoid the screen to be painted
    # twice when both players are taking hits.
    player_hurt = [0, 0, 0]
    invisibility_time = 5           # invisibility timer (also invincibility)
    invisibility_stop_moving = 2    # timer, ship stop moving during invisibility period
    artificial_intelligence = True

    def __init__(self,
                 Score_,                        # Score class
                 follower_,                     # Follower class
                 gl_,
                 int timing_= 15,
                 int layer_= -1,
                 origin_ = Rect(0, 0, 800, 1024).midbottom,
                 str name_ = 'NEMESIS',
                 str p_ = '1',
                 joystick_=None,
                 int plife_ = PLAYER_LIFE,
                 int pscore_ = 0):
        """

        :param timing_  : Update time in milliseconds
        :param layer_   : Player layer
        :param origin_  : Player aircraft start position
        :param name_    : Player aircraft name
        :param p_       : Player number (default player 1)
        :param joystick_: Joystick assigned to player (None by default)
        """
        print("******************** NEW LIFE *******************************")

        assert Player.containers is not None, \
            'Player variable containers should be a pygame.sprite.Group'

        self._layer = layer_
        Sprite.__init__(self, self.containers)

        if isinstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.image = Player.images[0].copy() if isinstance(Player.images, list) \
            else Player.images.copy()
        self.images_copy = self.image

        self.mask = pygame.mask.from_surface(self.image)
        self.mask_count = self.mask.count()

        self.rect = self.image.get_rect(midbottom=origin_)

        self.position = Vector2()  # aircraft position
        self.vector = Vector2()  # direction vector

        self.name = name_
        self.gl = gl_

        # Player id
        self.p_ = p_

        # Instantiating aircraft specifications & hud (life + energy)
        if self.p_ == '1' and self.name == 'NEMESIS':
            # link to NEMESIS instance (class ShipSpecs)
            self.aircraft_specs = NEMESIS_SPECS.__copy__()
            self.aircraft_specs.life_number = plife_    # adjust player life
            self.aircraft_specs.score = pscore_         # adjust player score
            self.current_weapon = self.aircraft_specs.current_weapon.__copy__()
            self.supershot = self.aircraft_specs.current_weapon.get_super().__copy__()


            self.energy_bar = HorizontalBar(start_color_=(0, 7, 255, 0),
                                            end_color_=(120, 255, 255, 0),
                                            maximum_=self.aircraft_specs.max_energy, minimum_=0,
                                            current_value_=self.aircraft_specs.energy,
                                            alpha_=False, h_=32, w_=180, scan_=False)

            self.life_bar = HorizontalBar(start_color_=(255, 10, 15, 0),
                                          end_color_=(4, 255, 15, 0),
                                          maximum_=self.aircraft_specs.max_health, minimum_=0,
                                          current_value_=self.aircraft_specs.life,
                                          alpha_=False, h_=32, w_=180)

        # elif self.p_ == '2':
        else:
            # link to LEVIATHAN instance (class ShipSpecs)
            self.aircraft_specs = LEVIATHAN_SPECS.__copy__()
            self.aircraft_specs.life_number = plife_    # adjust player life
            self.aircraft_specs.score = pscore_         # adjust player score
            self.current_weapon = self.aircraft_specs.current_weapon.__copy__()
            self.supershot = self.aircraft_specs.current_weapon.get_super().__copy__()
            self.energy_bar = HorizontalBar(start_color_=Color(0, 7, 255, 0),
                                            end_color_=Color(120, 255, 255, 0),
                                            maximum_=self.aircraft_specs.max_energy, minimum_=0,
                                            current_value_=self.aircraft_specs.energy,
                                            alpha_=None, h_=32, w_=180, scan_=False)

            self.life_bar = HorizontalBar(start_color_=Color(255, 10, 15, 0),
                                          end_color_=Color(4, 255, 15, 0),
                                          maximum_=self.aircraft_specs.max_health, minimum_=0,
                                          current_value_=self.aircraft_specs.life,
                                          alpha_=None, h_=32, w_=180)

        # link to the class Follower in Engine library
        self.follower = follower_


        # SHIELD INIT
        # -----------------------------------------------------------
        # self.shield is linking to the shield instance (Shield class)
        # self.aircraft_specs.shield contains all the shield specifications (ShieldClass)

        if self.aircraft_specs.shield is not None:

            global _shield_up, SHIELD_IMPACT, SHIELD_INVENTORY
            _shield_up[p_]   = False
            SHIELD_IMPACT    = False
            SHIELD_INVENTORY = []

            self.shield = Shield(
                            containers_ = gl_.All,
                            images_     = self.aircraft_specs.shield.sprite,
                            player_     = self,
                            loop_       = True,
                            timing_     = timing_,
                            event_      = 'SHIELD_INIT',
                            layer_      = layer_
            )

            # if Shield._shield_up[self.p_] is True and self.shield:
            #     print('Player %s shield is %s ' % (p_, 'up.'))
            #
            # else:
            #     print('Player %s shield is %s ' % (p_, 'down.'))
            #     print(self.shield.shield_specs.energy)

        else:
            self.shield = None
            print('Player %s has no shield.' % p_)
        # -----------------------------------------------------------

        # link to STINGER_MISSILE instance (class Weapons)
        self.weapon_missile = self.aircraft_specs.missiles_class.__copy__()
        # link to NUCLEAR_MISSILE instance (class Weapons)
        self.weapon_nuke = self.aircraft_specs.missile_nuke_class.__copy__()

        self.turret = self.aircraft_specs.turret.__copy__()

        # link to the CLASS Score in Engine library
        self.score = Score_

        self.previous_missile_target = [None, None]
        self.index = 0
        self.dt = 0
        self.timing = timing_

        # start the engine
        self.engine_on()
        self.turbo_boost_on()


        self.joystick = joystick_
        self.joystick_axis_1 = Vector2(0, 0)
        self.player_direction = Vector2(0, 0)

        # RADAR INIT
        # -----------------------------------------------------------
        self.radar_initialised = False
        if not Player.radar_flag:
            # RADAR
            RADAR_CST.active = True
            RADAR_CST.inventory = []

            screenrect = self.gl.screen.get_rect()
            objects = Threat(self.gl.screenrect).create_entities(gl_.screenrect, gl_.enemy_group)

            hostiles = []
            for id_, entity_ in objects.items():
                hostiles.append(
                    [Vector2(entity_.position[0],
                        entity_.position[1]), entity_.category, entity_.distance_to_player])

            RADAR_CST.hostiles = hostiles
            RADAR_CST.category = {'aircraft': R_AIRCRAFT_TARGET,
                                  'ground'  : R_GROUND_TARGET,
                                  'boss'    : R_BOSS_TARGET,
                                  'missile' : R_MISSILE_TARGET,
                                  'friend'  : R_FRIEND}



            # INSTANTIATION
            # player 1
            if p_ == '1':
                self.radar_instance = Radar(
                    RADAR_INTERFACE, gl_.All,
                    location_=(self.gl.screenrect.w - (RADAR_INTERFACE[0].get_width() >> 1),
                    self.gl.screenrect.h - (RADAR_INTERFACE[0].get_height() >> 1)),
                    gl_=gl_, player_=self, layer_=1, blend_=BLEND_RGB_ADD)

            # player 2
            else:
                self.radar_instance = Radar(
                    RADAR_INTERFACE, gl_.All,
                    location_=(RADAR_INTERFACE[0].get_width() >> 1,
                    self.gl.screenrect.h - (RADAR_INTERFACE[0].get_height() >> 1)),
                    gl_=gl_, player_=self, layer_=1, blend_=BLEND_RGB_ADD)


            self.radar_initialised = True
            Player.radar_flag = True

            self.radar_instance.set_dampening_fx()
        # -----------------------------------------------------------

        self.homing_missile_is_locked = False
        self.nuke_missile_is_locked = False
        self.visibility = 255
        self.visibility_steps = -10
        self.invincible = True
        self.start = time.time()
        self.origin = self.gl.screenrect.midbottom

        self.gl.PLAYER_GROUP.add(self)

        # AI INIT
        # -----------------------------------------------------------
        self.AI = Threat(self.rect)

        # -----------------------------------------------------------

        # self.turret = None

        # TURRET INIT
        TURRET_INITIALISED[int(self.p_) - <unsigned char>1] = False
        if self.turret is not None:
            self.turret_instance = Turret(
                                    containers_ =self.gl.All,
                                    images_     =self.turret.sprite,
                                    player_     =self,
                                    n_player    =self.p_,
                                    gl_         =self.gl,
                                    follower_   =self.follower,
                                    timing_     =<float>16.67,
                                    group_      =self.gl.enemy_group,
                                    weapon_     =self.turret.mounted_weapon,
                                    layer_      =-1)
            # if TURRET_INITIALISED[int(self.p_) - 1] and self.turret_instance:
            #     print('Player %s turret is %s.' % (self.p_, 'initialised'))
            # else:
            #     print('Player %s turret is %s.' % (self.p_, 'not initialised'))

        else:
            print('Player %s has no turret.' % self.p_)

            # -----------------------------------------------------------

        # if True, second player is control by AI
        self.automatic_AI = False
        self.super_laser_bool = False

        # ---------------------------------------------------------------
        # WING TURRET
        if self.aircraft_specs.wing_turret_number != 0:
            WingTurret(self.containers, self.aircraft_specs.wing_turret_sprite,
                       self, name_='left', offset_=(-100, +20),timing_=0, layer_=-1)
            WingTurret(self.containers, self.aircraft_specs.wing_turret_sprite,
                       self, name_='right', offset_=(+100, +20),timing_=0, layer_=-1)
            pass

        self.super_laser_instance_ = None

        self.aircraft_shadow = self.aircraft_specs.shadow.copy()

        # LightEngine(gl_,
        #             self,
        #             array_alpha_=JETLIGHT_ARRAY,
        #             fast_array_alpha_=JETLIGHT_ARRAY_FAST,
        #             intensity_=1.5,
        #             color_=JETLIGHTCOLOR,
        #             smooth_=False,
        #             saturation_=True,
        #             sat_value_=0.2,
        #             bloom_=False,
        #             bloom_threshold_=128,
        #             heat_=False,
        #             frequency_=1.0,
        #             blend_=BLEND_RGB_ADD,
        #             timing_=0,
        #             fast_=True,
        #             offset_x=0,
        #             offset_y=-240)

        self.light_flipflop = True

        print('Player %s initialized' % self.p_)

    def centre(self):
        return self.rect.center

    def force_centre(self, position_):
        self.rect.center = position_

    @staticmethod
    def display_fire_particle_fx(fire_particle_vertex):
        """
        UPDATE FIRE PARTICLE

        * This is the update method for the particles, it does not display the particles
        to the display but update their positions instead

        :param fire_particle_vertex: Sprite group; Group to assign the particles.
        :return: void
        """
        cdef:
            int fire_particle_index
            object fire_particle_images

        for fire_particle in fire_particle_vertex:

            fire_particle_index  = fire_particle.index
            fire_particle_images = fire_particle.images
            # MOVE THE PARTICLE IN THE VECTOR DIRECTION
            fire_particle.rect.move_ip(fire_particle.vector)

            fire_particle.image = <object>PyList_GetItem(fire_particle.images, fire_particle_index)
            if fire_particle_index > PyList_Size(fire_particle.images) - <unsigned char>2:
                fire_particle.kill()

            fire_particle.index += 1


    def fire_particles_fx(self, position_, vector_, list images_, int layer_=0, int blend_=BLEND_RGB_ADD):

        """
        CREATE FIRE PARTICLES ALL AROUND THE PLAYER AIRCRAFT

        :param position_: tuple or Vector2; particle starting location (tuple or Vector2)
        :param vector_  : Vector2; Particle trajectory/speed
        :param images_  : Surface list; Particle image
        :param layer_   : integer; layer to use for the particles
        :param blend_   : integer; blend mode, default BLEND_RGB_ADD
        :return         : void
        """
        gl = self.gl
        gl_all = gl.All

        # CAP THE NUMBER OF PARTICLES TO AVOID LAG
        if len(gl.FIRE_PARTICLES_FX) > 100:
            return

        sprite_     = Sprite()

        gl_all.add(sprite_)

        gl.FIRE_PARTICLES_FX.add(sprite_)

        # ASSIGN THE PARTICLE TO A SPECIFIC LAYER
        if PyObject_IsInstance(gl_all, LayeredUpdates):
            gl_all.change_layer(sprite_, layer_)

        sprite_._blend  = blend_
        sprite_.images  = images_
        sprite_.image   = <object>PyList_GetItem(images_, 0)
        sprite_.rect    = sprite_.image.get_rect(center=position_)
        sprite_.vector  = vector_
        sprite_.index   = 0


    def full_merge(self, object right, object left):
        """
        RETURN TRUE WHEN BOTH MASK FULLY OVERLAP

        This method is used to determine if a mask fully overlap (e.g bomb crater
        must fully overlap with the background image and not only a section)

        :param right: pygame.Sprite; right sprite 
        :param left : pygame.Sprite; left sprite
        :return: bool; True | False
        """
        cdef int xoffset = right.rect[0] - left.rect[0]
        cdef int yoffset = right.rect[1] - left.rect[1]
        r_mask = left.mask.overlap_mask(right.mask, (xoffset, yoffset))
        if r_mask.count() == self.mask_count:
            return True
        else:
            return False


    def drop_shadow_improve(self, texture_, texture_mask, gl_, tuple center_):
        """
        DROP THE AIRCRAFT SHADOW ON THE GROUND

        Return True when the shadow can be cast to the background surface otherwise return False
        :return: True | False
        """
        shadow_sprite       = Sprite()
        shadow_sprite.image = texture_
        shadow_sprite.mask  = texture_mask
        gl_ = self.gl
        shadow_sprite.rect = texture_.get_rect(center=(center_[0], center_[1]))

        cdef:
            list sprites_at_drop_position
            gl_All = gl_.All
            get_sprites_at = gl_All.get_sprites_at
            int w, h
            crater_sprite_rect = shadow_sprite.rect
            list ground_level_group = []
            int ground_layer = -7

        # RETURN A LIST WITH ALL SPRITES AT THAT POSITION
        # LAYEREDUPDATES.GET_SPRITES_AT(POS): RETURN COLLIDING_SPRITES
        # BOTTOM SPRITES ARE LISTED FIRST; THE TOP ONES ARE LISTED LAST.
        sprites_at_drop_position = get_sprites_at(shadow_sprite.rect.center)

        for sp in sprites_at_drop_position:
            if not PyObject_HasAttr(sp, '_layer'):
                continue

            if sp._layer != ground_layer:
                continue
            else:
                ground_level_group.append(sp)

        if len(ground_level_group) > 0:

            for spr in ground_level_group:

                # ONLY PLATFORM 0 AND PLATFORM 7 HAVE A MASK OTHER BACKGROUND SPRITE DOES NOT
                # OTHER BACKGROUND HAVE A PLAN SURFACE
                if PyObject_HasAttr(spr, 'mask') and spr.mask is not None:
                    # Tests for collision between two sprites by testing if their bitmasks
                    # overlap. If the sprites have a "mask" attribute, that is used as the mask;
                    # otherwise, a mask is created from the sprite image. Intended to be passed
                    # as a collided callback function to the *collide functions. Sprites must
                    # have a "rect" and an optional "mask" attribute.

                    if collide_mask(spr, shadow_sprite):
                        # return self.full_merge(spr, shadow_sprite)

                        xoffset = spr.rect[0] - shadow_sprite.rect[0]
                        yoffset = spr.rect[1] - shadow_sprite.rect[1]
                        lmask = shadow_sprite.mask.overlap_mask(spr.mask, (xoffset, yoffset))
                        mask_surface = lmask.to_surface(setcolor=(255, 255, 255), unsetcolor=(0, 0, 0))
                        w, h = self.aircraft_specs.shadow.get_size()
                        # CREATE A SURFACE WITH SAME DIMENSION THAT THE SHADOW AND BLIT THE MASK ON IT
                        new_surface = Surface((w, h))
                        new_surface.fill((0, 0, 0))
                        new_surface.blit(mask_surface, (0, 0))
                        self.aircraft_shadow = mask_shadow(self.aircraft_specs.shadow.copy(), new_surface)
                        return True
                else:
                    return True

        return False


    @property
    def visibility(self):
        return self.__visibility


    @visibility.setter
    def visibility(self, visibility):
        self.__visibility = visibility
        if visibility < 0:
            self.__visibility = 0
            self.visibility_steps *= -1
        elif visibility > 255:
            self.__visibility = 255
            self.visibility_steps *= -1


    def respawn(self):
        """
        RESPAWN THE PLAYER

        :return: void
        """

        # remove player life
        if self.aircraft_specs.life_number > 0:
            self.aircraft_specs.life_number -= 1

            return Player(self.score,
                      self.follower,
                          self.gl,
                          self.timing,
                          self._layer,
                          self.origin,
                          self.name,
                          self.p_,
                          self.joystick,
                          self.aircraft_specs.life_number,
                          self.aircraft_specs.score)

    def standby(self):
        """
        RESET THE PLAYER VECTOR DIRECTION

        :return: void
        """
        # VECTOR DIRECTION IS NULL
        self.vector.x, self.vector.y = 0, 0

    def move(self, direction_):

        if self.alive():

            # # NOTE CLAMP PREVENT THE PLAYER TO MOVE WITH KEYBOARD
            # # KEEP THE SHIP INTO THE SCREEN NO MATTER WHAT
            # self.rect = self.rect.clamp(self.gl.screenrect)

            # TRACK THE PREVIOUS POSITION
            # USED FOR THE DIRECTION VECTOR CALCULATION
            old_position = self.position

            self.rect.move_ip(direction_ * self.aircraft_specs.speed_x * self.gl.SPEED_FACTOR)

            # CALCULATE THE NEW VECTOR DIRECTION ACCORDING TO
            # THE LATEST JOYSTICK/ KEYBOARD INPUT
            self.vector = Vector2(self.rect.center) - old_position

    def blinking(self):
        """
        BLINKING EFFECT (AIRCRAFT BLINKING AFTER SPAWNING)
        :return: void
        """
        self.image = make_transparent32(self.image, self.visibility)

    @staticmethod
    def hurt_effect(gl_):
        """
        RED DISPLAY AFTER TAKING DAMAGES AND BULLET IMPACTS TO THE DISPLAY

        :param gl_           : class/instance; Global variables/constants
        :return              : void
        """

        cdef int p0, p1, p2, alpha
        p0 = Player.player_hurt[0]
        p1 = Player.player_hurt[1]
        p2 = Player.player_hurt[2]
        alpha = min(<int>((p1 / p2) * <unsigned char>255 * p0 / <float>10.0), <unsigned char>160)

        if alpha < 0:
            alpha = 0

        gl_.screen.fill((255, 0, 0, alpha), special_flags=BLEND_RGB_ADD)
        gl_.screen.convert()
        Player.player_hurt[0] -= <unsigned char>1

        # DISPLAY BULLET IMPACT
        if randRange(0, 100) > 70:
            BrokenScreen([SCREEN_IMPACT, SCREEN_IMPACT1][randRange(0, 1)], gl_, 60, 0)

    def get_animation_index(self):
        return self.index

    def gun_position(self):
        return Player.gun_offset + self.rect.centerx, self.rect.top

    def location(self):
        return self.rect

    def center(self):
        return self.rect.center

    @staticmethod
    def clean_player_instance(n_player=0):
        """

        :param n_player:
        :return: void
        """

        assert PyObject_IsInstance(n_player, int), \
            '\n[-] Argument n_player should be an int got %ds ' % type(n_player)
        if Player.instances:
            if PyObject_IsInstance(Player.instances, list) and len(Player.instances)>0:
                all_instance = Player.instances[n_player]
                if PyObject_IsInstance(all_instance, list):
                    for sprite in all_instance:
                        all_instance.remove(sprite)
                        if PyObject_HasAttr(sprite, 'kill_instance'):
                            sprite.kill_instance(sprite)

                else:
                    if PyObject_HasAttr(all_instance, 'kill_instance'):
                        all_instance.kill_instance(all_instance)

        if Player.turbo_boost:

            instance = Player.turbo_boost[n_player]

            if instance and PyObject_HasAttr(instance, 'kill_instance'):
                instance.kill_instance(instance)
                Player.turbo_boost[n_player] = None


    def turbo_boost_on(self):
        """

        :return: void
        """

        mixer = self.gl.SC_spaceship
        gl    = self.gl
        rect  = self.rect

        instance_ = self.follower(gl,
                                  gl.All,
                                  self.aircraft_specs.exhaust_turbo_sprite,
                                  offset_   = (rect.midbottom[0],
                                               rect.midbottom[1] + 17),
                                  timing_   = self.timing,
                                  loop_     = True,
                                  event_    = 'TURBO_BOOST',
                                  object_   = self,
                                  layer_    = -1,
                                  blend_    = BLEND_RGBA_ADD)

        if not mixer.get_identical_sounds(ENGINE_TURBO):

            mixer.play(sound_      = ENGINE_TURBO,
                       loop_       = True,
                       priority_   = 0,
                       volume_     = gl.SOUND_LEVEL,
                       fade_out_ms = 0,
                       panning_    = True,
                       name_       = 'TURBO_BOOST',
                       x_          = rect.centerx)
        Player.turbo_boost[int(self.p_)-<unsigned char>1] = instance_


    def turbo_boost_off(self):
        """

        :return: void
        """

        instance = Player.turbo_boost[int(self.p_) - <unsigned char>1]

        if instance and PyObject_HasAttr(instance, 'kill_instance'):
            instance.kill_instance(instance)

            Player.turbo_boost[int(self.p_) - <unsigned char>1] = None

        # STOP THE TURBO BOOST SOUND
        self.gl.SC_spaceship.stop_name('TURBO_BOOST')



    def engine_on(self):
        """

        :return: void
        """
        gl    = self.gl
        mixer = self.gl.SC_spaceship

        instance_ = self.follower(gl,
                                  gl.All,
                                  self.aircraft_specs.exhaust_sprite,
                                  offset_   = self.rect.midbottom,
                                  timing_   = self.timing,
                                  loop_     = True,
                                  event_    = 'ENGINE_ON',
                                  object_   = self,
                                  layer_    = -2,
                                  vector_   = None,
                                  blend_    = BLEND_RGB_ADD
                                  )

        # Play the engine sound
        if not mixer.get_identical_sounds(ENGINE_ON):

            mixer.play(sound_        = ENGINE_ON,
                       loop_         = True,
                       priority_     = 0,
                       volume_       = gl.SOUND_LEVEL,
                       fade_out_ms   = 0,
                       panning_      = False,
                       name_         = 'TURBO_BOOST',
                       x_            = 0
                       )
        if PyObject_IsInstance(instance_, self.follower):
            Player.instances[int(self.p_) -1].append(instance_)

    def engine_off(self):
        """

        :return: void
        """

        cdef int index = int(self.p_) - <unsigned char>1
        cdef list ins  = Player.instances[index]

        for instance_ in ins:

            if PyObject_IsInstance(instance_, self.follower):

                if instance_.event == 'ENGINE_ON':
                    ins.remove(instance_)
                    instance_.kill_instance(instance_)

        # Stop the engine sound
        self.gl.SC_spaceship.stop_name('ENGINE_ON')


    def is_super_laser_shooting(self) ->bool:
        """

        :return: bool;
        """

        if self.super_laser_instance_ is None:
            return True
        else:
            if PyObject_HasAttr(self.super_laser_instance_, 'alive'):
                if self.super_laser_instance_.alive():
                    return False
                else:
                    return True

    def super_laser(self):
        """

        :return: void
        """

        gl = self.gl


        # CHOOSE THE SUPER LASER ACCORDING TO THE PLAYER AIRCRAFT TYPE
        super_laser_, shaft, burst = self.aircraft_specs.beam

        # check if weapon is reloading and if the super_laser_instance_ is dead
        if not super_laser_.weapon_reloading_std(self.gl.FRAME) and self.is_super_laser_shooting():

            # CREATE A FOLLOWER AND ASSIGN A VARIABLE TO PASS IT TO THE CLASS SUPERLASER
            self.super_laser_instance_ =\
                self.follower(
                gl,
                gl.All,
                shaft,
                offset_     = self.rect.center,
                timing_     = self.timing,
                loop_       = True,
                event_      = 'SHAFT LIGHT',
                object_     = self,
                layer_      = -1,
                blend_      = BLEND_RGBA_ADD
            )


            if PyObject_IsInstance(self.super_laser_instance_, self.follower):

                Player.instances[int(self.p_) - <unsigned char>1].append(self.super_laser_instance_)

                super_laser_improved(gl,
                                     self,
                                     self.super_laser_instance_,
                                     super_laser_,
                                     super_laser_.sprite,
                                     turret_        = None,
                                     mute_          = False,
                                     layer_         = -2)


    def nuke(self):
        """

        :return: void
        """
        gl    = self.gl
        mixer = gl.SC_spaceship
        rect  = self.rect


        if self.aircraft_specs.nukes_quantity > 0:

            # MISSILE RELOADING ?
            if not self.weapon_nuke.weapon_reloading_std(gl.FRAME):

                # Bomb release sound effect
                mixer.play(sound_        = self.weapon_nuke.sound_effect,
                           loop_         = False,
                           priority_     = 2,
                           volume_       = gl.SOUND_LEVEL,
                           fade_out_ms   = 0,
                           panning_      = False,
                           name_         = 'BOMB_RELEASE',
                           x_            = 0
                           )

                # CREATE A DUMMY TARGET 400 PIXELS AHEAD OF THE SPACESHIP
                # VIRTUAL RECTANGLE THAT WILL TRIGGER A NUKE EXPLOSION AFTER COLLIDING WITH IT.
                # THIS SPRITE IS PASSED INTO THE GROUP NUKE_AIMING_POINT(THIS GROUP CONTAINS EVERY
                # VIRTUAL RECTANGLE)

                dummy_sprite             = Sprite()
                dummy_sprite.rect        = rect.copy()
                dummy_sprite.rect.center = (rect.centerx, rect.centery - 400)
                dummy_sprite.dummy       = True
                dummy_sprite.name        = self.p_
                gl.nuke_aiming_point.add(dummy_sprite)

                # DISPLAY A TARGET WHERE THE BOMB IS AIMING
                GenericAnimation(group_         = gl.All,
                                 images_        = self.aircraft_specs.nuke_target_sprite,
                                 object_        = dummy_sprite.rect,
                                 ratio_         = None,
                                 timing_        = self.timing,
                                 offset_        = dummy_sprite.rect,
                                 event_name_    = 'NUCLEAR_EXPLOSION',
                                 loop_          = False,
                                 gl_            = gl,
                                 score_         = self.score,
                                 layer_         = -1,
                                 blend_         = 0)

                extra = ExtraAttributes(
                        {'target': dummy_sprite.rect,
                         'shoot_angle': 90,
                         'ignition': False,
                         'offset': (0, 0)})

                # Missile launched
                Nuke(
                      gl_              = gl,
                      group_           = (gl.missiles, gl.All),
                      weapon_features_ = NUKE_FEATURES,
                      extra_attributes = extra,
                      weapon_          = self.weapon_nuke,
                      player_          = self,
                      timing_          = 800
                      )


                self.weapon_nuke.shooting           = True
                self.weapon_nuke.elapsed            = gl.FRAME
                self.aircraft_specs.nukes_quantity -= 1

        else:
            if self.alive():
                # DENY SOUND WHEN NO MORE NUKE AVAILABLE
                if not mixer.get_identical_sounds(DENIED_SOUND):
                    mixer.play(sound_       = DENIED_SOUND,
                               loop_        = False,
                               priority_    = 0,
                               volume_      = gl.SOUND_LEVEL,
                               fade_out_ms  = 0,
                               panning_     = False,
                               name_        = 'DENIED',
                               x_           = 0,
                               object_id_=id(DENIED_SOUND))


    def missiles(self):
        """

        :return: void
        """

        cdef dict entities
        cdef list mode
        cdef list sprite_tuple1, sprite_tuple2
        cdef int distance1 = 0, distance2=0

        gl     = self.gl
        rect   = self.rect
        missile = self.weapon_missile

        if self.aircraft_specs.missiles_quantity > 0:

            if not missile.weapon_reloading_std(gl.FRAME):

                # CREATE A LIST OF ENEMY ENTITIES
                # TARGETS OUTSIDE THE SCREEN WILL BE DISREGARDED
                entities = self.AI.create_entities(gl.screenrect, gl.GROUP_UNION)

                if len(entities) != 0:

                    # AS LONG AS ENTITIES IS NOT EMPTY THE METHOD BELOW SHOULD RETURN A LIST
                    mode = SortByDeadliestTarget(entities)

                    t0, t1 = None, None

                    # SELECT A TARGET FOR EACH MISSILES (X2)
                    # IF ONLY ONE TARGET IS AVAILABLE, ASSIGN
                    # SAME TARGET FOR BOTH MISSILES.
                    if <object>PyList_Size(mode) >= 2:
                        distance1, sprite_tuple1 = mode[0]
                        distance2, sprite_tuple2 = mode[1]
                        t0 = <object>PyList_GetItem(sprite_tuple1, 0)
                        t1 = <object>PyList_GetItem(sprite_tuple2, 0)
                    else:
                        distance1, sprite_tuple1 = mode[0]
                        t0 = t1 = <object>PyList_GetItem(sprite_tuple1, 0)

                    # CHECKING IF THE PREVIOUS TARGETS HAVE BEEN DESTROYED.
                    # IF NOT, CHOOSE THE PREVIOUS TARGET AGAIN.
                    if self.previous_missile_target[0] and \
                            PyObject_HasAttr(self.previous_missile_target[0], 'alive'):
                        if self.previous_missile_target[0].alive():
                            t0 = self.previous_missile_target[0]

                    if self.previous_missile_target[1] and \
                            PyObject_HasAttr(self.previous_missile_target[1], 'alive'):
                        if self.previous_missile_target[1].alive():
                            t1 = self.previous_missile_target[1]

                    if t0 and t1:
                        missile_sprite   = self.aircraft_specs.missile_sprite
                        missile.shooting = True

                        if PyObject_HasAttr(t0, 'rect') and PyObject_HasAttr(t1, 'rect'):

                            if t1.rect.centerx > t0.rect.centerx:

                                # ASSIGNING MISSILE TO PLAYER MISSILE GROUP (gl.missiles)
                                s = Homing(
                                    gl_=gl,
                                    group_=(gl.All, gl.missiles),
                                    weapon_features_=STINGER_FEATURES,
                                    extra_attributes=ExtraAttributes(
                                        {'target': t0,
                                         'shoot_angle': 225,
                                         'ignition': False,
                                         'offset': (-30, 60)}),
                                    weapon_ = missile,
                                    player_=self,
                                    timing_=800,
                                )
                                # ASSIGNING MISSILE TO PLAYER MISSILE GROUP (gl.missiles)
                                s = Homing(
                                    gl_=gl,
                                    group_=(gl.All, gl.missiles),
                                    weapon_features_=STINGER_FEATURES,
                                    extra_attributes=ExtraAttributes(
                                    {'target': t1,
                                     'shoot_angle': -45,
                                     'ignition': False,
                                     'offset': (30, 60)}),
                                    weapon_=missile,
                                    player_ = self,
                                    timing_=800,
                                )

                            else:
                                # ASSIGNING MISSILE TO PLAYER MISSILE GROUP (gl.missiles)
                                s = Homing(
                                    gl_=gl,
                                    group_=(gl.All, gl.missiles),
                                    weapon_features_=STINGER_FEATURES,
                                    extra_attributes=ExtraAttributes(
                                        {'target': t1,
                                         'shoot_angle': 225,
                                         'ignition': False,
                                         'offset': (-30, 60)}),
                                    weapon_=missile,
                                    player_=self,
                                    timing_=800,
                                )
                                # ASSIGNING MISSILE TO PLAYER MISSILE GROUP (gl.missiles)
                                s = Homing(
                                    gl_=gl,
                                    group_=(gl.All, gl.missiles),
                                    weapon_features_=STINGER_FEATURES,
                                    extra_attributes=ExtraAttributes(
                                        {'target': t0,
                                         'shoot_angle': -45,
                                         'ignition': False,
                                         'offset': (30, 60)}),
                                    weapon_=missile,
                                    player_=self,
                                    timing_=800,
                                )


                            GenericAnimation(group_     = gl.All,
                                             images_    = self.aircraft_specs.missile_target_sprite,
                                             object_    = t0,
                                             ratio_     = 1,
                                             timing_    = 33,
                                             offset_    = None,
                                             event_name_= 'TARGET',
                                             loop_      = True,
                                             gl_        = gl,
                                             score_     = self.score,
                                             layer_     = -4)

                            GenericAnimation(
                                group_          = gl.All,
                                images_         = self.aircraft_specs.missile_target_sprite,
                                object_         = t1,
                                ratio_          = 1,
                                timing_         = 33,
                                offset_         = None,
                                event_name_     = 'TARGET',
                                loop_           = True,
                                gl_             = gl,
                                score_          = self.score,
                                layer_          = -4
                            )

                            missile.elapsed                         = gl.FRAME
                            # Remove missiles from the stock
                            self.aircraft_specs.missiles_quantity  -= 2
                            self.previous_missile_target            = [t0, t1]
                else:
                    # CREATE DUMMY TARGETS.
                    # THE TARGETS WILL BE IGNORED BY THE HOMING MISSILE ALGORITHM AS
                    # THE MISSILES WILL GO STRAIGHT AHEAD WITHOUT AIMING TO A SPECIFIC ENEMY
                    dummy               = Sprite()
                    dummy.rect          = Rect(10, 10, 10 , 10)
                    dummy.rect.center   = (rect.centerx, 0)
                    dummy.dummy         = True
                    dummy.invincible    = True
                    dummy_group = pygame.sprite.GroupSingle()
                    dummy_group.add(dummy)

                    missile.shooting    = True
                    s = Homing(
                        gl_=gl,
                        group_=(gl.All, gl.missiles),
                        weapon_features_=STINGER_FEATURES,
                        extra_attributes=ExtraAttributes(
                            {'target': dummy,
                             'shoot_angle': 225,
                             'ignition': False,
                             'offset': (-30, 60)}),
                        weapon_=missile,
                        player_=self,
                        timing_=800,
                    )
                    # ASSIGNING MISSILE TO PLAYER MISSILE GROUP (gl.missiles)
                    s = Homing(
                        gl_=gl,
                        group_=(gl.All, gl.missiles),
                        weapon_features_=STINGER_FEATURES,
                        extra_attributes=ExtraAttributes(
                            {'target': dummy,
                             'shoot_angle': -45,
                             'ignition': False,
                             'offset': (30, 60)}),
                        weapon_=missile,
                        player_=self,
                        timing_=800,
                    )

                    missile.elapsed = gl.FRAME
                    # REMOVE MISSILES FROM THE STOCK
                    self.aircraft_specs.missiles_quantity -= 2

        self.weapon_missile = missile


    def super_shot(self):
        """

        :return: void
        """

        gl        = self.gl
        supershot = self.supershot


        if supershot.shooting or \
                self.aircraft_specs.energy < supershot.energy:
            return

        # STOP PREVIOUS SOUND IF ANY
        gl.SC_spaceship.stop_name(supershot.name)
        # TIMESTAMP FOR THE RELOADING TIME
        self.supershot.elapsed  = gl.FRAME
        self.supershot.shooting = True

        Shot(group_         = (gl.shots, gl.All),
             pos_           = self.gun_position(),
             current_weapon_= self.supershot,
             player_        = self,
             mute_          = False,
             offset_        = (0, self.gun_position()[1]),
             timing_        = self.timing,
             gl_            = gl,
             layer_         = -5)

        # REMOVE ENERGY
        self.aircraft_specs.energy -= supershot.energy


    def supershot_is_reloading(self):
        """

        :return: void
        """
        gl = self.gl
        supershot = self.supershot

        if supershot is not None:
            if gl.FRAME - supershot.elapsed > supershot.reloading * gl.MAXFPS:
                supershot.shooting = False
                supershot.elapsed = 0
            else:
                supershot.shooting = True

        self.supershot = supershot

    # TODO INVESTIGATE BELOW DOES NOT WORKS
    def hazardous(self):
        """
        DETECT OBJECT IN COLLISION COURSE WITH THE PLAYER

        :return: list
        """
        all_group = Group()
        all_group.add(self.gl.enemyshots)

        if self.shield.is_shield_up():
            collision_cluster = colliders_c(self.gl.screenrect, all_group, self.shield.rect)
        else:
            collision_cluster = colliders_c(self.gl.screenrect, all_group, self.rect)

        nearest_collision  = self.AI.sort_by_nearest_collider(collision_cluster)
        return nearest_collision

    def flashing_light(self):


        LightEngine(self.gl,
                    self,
                    array_alpha_=RADIAL3_ARRAY_64x64,
                    fast_array_alpha_=RADIAL3_ARRAY_32x32_FAST,
                    intensity_=4.0,
                    color_=WING_WARNING_LIGHT if len(Threat.inventory)!=0
                    else WING_STANDBY_LIGHT,
                    smooth_=False,
                    saturation_=False,
                    sat_value_=1.0,
                    bloom_=False,
                    bloom_threshold_=128,
                    heat_=False,
                    frequency_=1.0,
                    blend_=BLEND_RGB_ADD,
                    timing_=0,
                    fast_=False,
                    offset_x=35 if self.light_flipflop == True else -35,
                    offset_y=10)

        self.light_flipflop = not self.light_flipflop


    def update(self):

        gl       = self.gl
        joystick = self.joystick


        global SHIELD_IMPACT

        if self.aircraft_specs.life <= 0:
            self.kill()

        # FLAME SHADOW
        elif 151 < self.aircraft_specs.life < 800:
            position = Vector2(randRange(-20, 20), randRange(0, 25))
            self.fire_particles_fx(
                position_=Vector2(self.rect.centerx + (self.rect.w >> 1),
                                  self.rect.centery + self.rect.h) + position,
                vector_=Vector2(randRangeFloat(-1.0, 1.0), randRangeFloat(0.0, 6.0)),
                images_=PHOTON_PARTICLE_1_NEG[:8],
                layer_=0,
                blend_=BLEND_RGB_SUB
            )

            # FLAME EFFECT
            if self.alive():
                position = Vector2(randRange(-20, 20), randRange(0, 25))
                self.fire_particles_fx(
                    position_   = position + Vector2(self.rect.center),
                    vector_     = Vector2(randRangeFloat(-1.0, 1.0), randRangeFloat(0.0, 6.0)),
                    images_     = PHOTON_PARTICLE_1[:8],
                    layer_      = 0,
                    blend_      = BLEND_RGB_ADD
                    )

        cdef:
            int w_2, h_2, w, h
            bint micro_bots = False
            bint nuke = False
            bint firing = False
            bint super_shot = False


        if self.alive():

            # WING FLASHING LIGHT
            if gl.FRAME % 60 == 0:
                self.flashing_light()



            # Keep the super laser display outside the sync loop
            # to avoid offsetting the laser with the player or the wing turrets
            display_super_laser(False, False, 1.0)

            if self.dt > self.timing:

                w, h = self.aircraft_shadow.get_size()
                w_2, h_2 = w >> 1, h >> 1

                if self.drop_shadow_improve(
                        texture_      = self.aircraft_shadow,
                        texture_mask  = self.mask,
                        gl_           = gl,
                        center_       =(self.rect.centerx + w_2,
                                        self.rect.centery + h_2)):



                    BindSprite(group_     = gl.All,
                               images_    = self.aircraft_shadow,
                               object_    = self,
                               gl_        = gl,
                               offset_    = (w_2, h_2),
                               timing_    = self.timing,
                               layer_     = self._layer - 1,
                               loop_      = False,
                               dependency_= True,
                               follow_    = True,
                               blend_     = BLEND_RGB_SUB,
                               event_     = 'SHADOW')

                    self.aircraft_shadow = self.aircraft_specs.shadow.copy()

                self.super_laser_bool = False
                direction = Vector2(<float>0.0, <float>0.0)

                if self.p_ == '2' and self.automatic_AI:
                        haz = self.hazardous()
                        if PyObject_IsInstance(haz, tuple):
                            if PyObject_HasAttr(haz[1][0], 'vector'):
                                # m is either 1 or -1 depends on the enemy x vector component
                                m = 1 if haz[1][0].vector.normalize().x < 0 \
                                         and self.rect.x > self.shield.rect.x else -1
                                direction = Vector2(m, 0)

                        if bool(gl.GROUP_UNION):
                            firing = True
                            super_shot = True
                        else:
                            firing = False
                            super_shot = False

                 # automatic repair if hp < 200
                if self.aircraft_specs.life < 200:
                    micro_bots = True

                # Player1 joystick inputs
                # Player 1 is reading the joystick inputs straight from
                # the pygame.joystick object. The joystick object is referenced
                # after calling the class JoystickCheck.
                # If no joystick detected, the lines below will be ignored
                if self.p_ == '1':
                    if joystick is not None:
                        self.joystick_axis_1 = Vector2(round(joystick.get_axis(0), 3),
                                                       round(joystick.get_axis(1), 3))

                        # << ----- ADJUST JOYSTICK LATERAL VERTICAL SPEED -------- >>
                        self.joystick_axis_1 *= <float>1.4

                        # Micro - bots squad
                        if joystick.get_button(3):
                            micro_bots = True

                        if joystick.get_button(6):
                            nuke = True

                        if joystick.get_button(2):
                            firing = True

                        if joystick.get_button(7):
                            super_shot = True

                        if joystick.get_button(0):
                            self.super_laser_bool = True

                # Player2 joystick Input (via Server socket)
                # The Server is receiving a Joystick object via the network
                # that contains the status of the joystick inputs, buttons, hats etc
                # See file JoystickServer.py for more info and details of class
                # JoystickClient & JoystickServer
                # If no valid joystick object is returned, the line below will be ignored.
                elif self.p_ == '2':
                    """
                    if self.gl.P2JNI is not None:
                        print('\n')
                        print('Joystick id %s ' % self.gl.P2JNI.id)
                        print('Joystick name %s ' % self.gl.P2JNI.name)
                        print('Joystick axes %s ' % self.gl.P2JNI.axes)
                        print('Joystick axes_status %s ' % self.gl.P2JNI.axes_status)
                        print('Joystick button %s ' % self.gl.P2JNI.buttons)
                        print('Joystick button_status %s ' % self.gl.P2JNI.button_status)
                        print('Joystick hats %s ' % self.gl.P2JNI.hat)
                        print('Joystick hats_status %s ' % self.gl.P2JNI.hats_status)
                        print('Joystick balls %s ' % self.gl.P2JNI.balls)
                        print('Joystick balls_status %s ' % self.gl.P2JNI.balls_status)
                    """
                    if gl.P2JNI is not None:
                        if hasattr(gl.P2JNI, 'axes_status'):
                            self.joystick_axis_1 = Vector2(round(gl.P2JNI.axes_status[0], 3),
                                                           round(gl.P2JNI.axes_status[1], 3))
                        else:
                            self.joystick_axis_1 = Vector2(0, 0)

                        if PyObject_HasAttr(gl.P2JNI, 'button_status'):
                            # Micro - bots squad
                            if gl.P2JNI.button_status[3]:
                                micro_bots = True

                            if gl.P2JNI.button_status[6]:
                                nuke = True

                            if gl.P2JNI.button_status[2]:
                                firing = True

                            if gl.P2JNI.button_status[7]:
                                super_shot = True

                            if gl.P2JNI.button_status[0]:
                                self.super_laser_bool = True


                # Only PLAYER 1 can use the keyboard
                if self.p_ == '1':

                    direction = Vector2(
                        gl.KEYS[pygame.K_RIGHT] - gl.KEYS[pygame.K_LEFT],
                        gl.KEYS[pygame.K_DOWN] - gl.KEYS[pygame.K_UP])


                    if gl.KEYS[pygame.K_RCTRL]:
                        micro_bots = True

                    if gl.KEYS[pygame.K_RETURN]:
                        nuke = True

                    if gl.KEYS[pygame.K_SPACE]:
                        firing = True

                    if gl.KEYS[pygame.K_LCTRL]:
                        super_shot = True

                    if gl.KEYS[pygame.K_LSHIFT]:
                        self.super_laser_bool = True

                if self.dt > self.timing:

                    # Recharging energy cells +2
                    self.aircraft_specs.energy += 2

                    # check if the reloading time is over
                    self.current_weapon.weapon_reloading_std(gl.FRAME)

                    if self.supershot is not None:
                        self.supershot_is_reloading()

                    if micro_bots:

                        micro = MicroBots(gl.All, NANO_BOTS_CLOUD,
                                          player_=self, gl_=gl, timing_=self.timing, layer_=-1)
                        if micro is not None:
                            # Blend additive mode
                            self.aircraft_specs.microbots_quantity -= 1
                            micro._blend = BLEND_RGB_ADD

                    if nuke:
                        self.nuke()

                    if firing and not self.current_weapon.weapon_reloading_std(gl.FRAME):

                        if self.aircraft_specs.energy > \
                                (self.current_weapon.energy *
                                 SHOT_CONFIGURATION[self.current_weapon.units]):
                            # todo check why NEMESIS here
                            if self.name == 'NEMESIS':
                                self.images = self.current_weapon.animation
                            else:
                                self.images = ALL_SPACE_SHIP[self.name]

                            # lock the super_laser in shooting mode
                            self.current_weapon.shooting = True
                            # start the counter for the reloading
                            self.current_weapon.elapsed = gl.FRAME
                            multiple_shots(self.current_weapon.units, self, gl)

                    if super_shot:
                        self.super_shot()
                        self.missiles()

                    if self.super_laser_bool:
                        self.super_laser()

                    # Reload the aircraft image every frame
                    # self.images = Player.images
                    self.images = self.images_copy

                    if PyObject_IsInstance(self.images, list):
                        self.image = self.images[self.index % len(self.images)]
                        if self.index < len(self.images) - 1:
                            self.index += 1
                        else:
                            # Player.super_ready = True
                            self.index = 0
                    else:
                        self.image = self.images

                    self.position = Vector2(*self.rect.center)

                    self.dt = 0

                    if self.invincible:
                        self.blinking()
                        self.visibility +=self.visibility_steps
                        # Force the player to go forward regardless
                        # of the player actions
                        if time.time() - self.start < Player.invisibility_stop_moving:
                            self.rect.move_ip(0, -3)
                            direction = Vector2(0, 0)
                            self.joystick_axis_1 = Vector2(0, 0)
                        else:
                            self.turbo_boost_off()

                        # 5 seconds of invincibility when spawning
                        if time.time() - self.start > Player.invisibility_time:
                            self.visibility = 255
                            self.visibility_steps = 0
                            self.invincible = False
                            self.start = 0


                    if direction and direction.length() != 0:
                        self.move(direction)

                    elif self.joystick_axis_1.length() != 0:
                        self.move(self.joystick_axis_1)

                    else:
                        self.standby()

            # NOTE CLAMP PREVENT THE PLAYER TO MOVE WITH KEYBOARD
            # KEEP THE SHIP INTO THE SCREEN NO MATTER WHAT
            self.rect = self.rect.clamp(self.gl.screenrect)

            self.dt += gl.TIME_PASSED_SECONDS


        else:
            self.clean_player_instance(int(self.p_) - 1)
            # Clear the inventory
            Player.instances[int(self.p_) -1] = []
            self.aircraft_specs.life -= 1 if self.aircraft_specs.life > 0 else 0

            if PyObject_HasAttr(self, 'radar_instance') and self.radar_instance is not None:
                self.radar_instance.kill()
                Player.radar_flag = False

            if PyObject_HasAttr(self, 'shield') and self.shield is not None:
                self.shield.kill()
                _shield_up[self.p_] = False
                SHIELD_IMPACT = False

            if PyObject_HasAttr(self, 'turret_instance') and self.turret_instance is not None:
                self.turret_instance.kill()

            if self in gl.PLAYER_GROUP:
                gl.PLAYER_GROUP.remove(self)

            # REMOVE FIRE PARTICLES
            for p in self.gl.FIRE_PARTICLES_FX:
                p.kill()