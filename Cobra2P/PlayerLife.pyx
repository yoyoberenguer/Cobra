

import threading

# TODO CIMPORT
from BindSprite import BindSprite
from Blast import Blast, BLAST_INVENTORY
from GenericAnimation import GenericAnimation
from Miscellaneous import Score
from Player import Player
from Score import PlayerLost
from Shield import Shield
from Sounds import WHOOSH, EXPLOSION_SOUND_1, HEART_SOUND, IMPACT2, EXPLOSION_SOUND_2
from Textures import ROUND_SHIELD_IMPACT, ALL_SPACE_SHIP, BURST_UP_RED, RADIAL, EXPLOSION19, \
    HALO_SPRITE9_, BLAST1, \
    SPACESHIP_SPRITE, FINAL_MISSION
import time
# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
    QUIT, K_SPACE, BLEND_RGB_ADD, Rect, freetype
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, \
        array3d, make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotate, flip, rotozoom
except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")


try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject_CallFunctionObjArgs, PyObject, \
        PyList_SetSlice, PyObject_HasAttr, PyObject_IsInstance, \
        PyObject_CallMethod, PyObject_CallObject
    from cpython.dict cimport PyDict_DelItem, PyDict_Clear, PyDict_GetItem, PyDict_SetItem, \
        PyDict_Values, PyDict_Keys, PyDict_Items
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size
    from cpython.object cimport PyObject_SetAttr
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;


# TIMER
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
class Timer(threading.Thread):

    def __init__(self, gl_, int delay_):
        threading.Thread.__init__(self)
        self.gl    = gl_
        self.delay = delay_

    def run(self):
        time.sleep(2)

        t_start = time.time()
        while time.time() - t_start < self.delay:
            time.sleep(<float>0.01)

        self.gl.FAIL = True


cdef list SYS = ['LW', 'SUPER', 'RW', 'RE', 'LE', 'RE']

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class DamageControl:

    cdef:
        public object gl, object_

    def __init__(self, gl_, object_):
        """
        THE PLAYER AIRCRAFT (NEMESIS) IS COMPOSED OF RECTANGLES PLACE AT DIFFERENT
        LOCATIONS TO REPRESENT ALL THE THE ONBOARD ELECTRONIC SYSTEM.
        RECTS COLLIDING WITH THE OBJECT WILL TAKE SOME DAMAGES (COLLISION DETECTION)

        * More than one system can take damages

        :param gl_: class; global variables /constants
        :param object_: instance; object hitting the player
        """

        self.gl         = gl_
        self.object_    = object_
        player_rect     = gl_.player.rect

        # THE RECTS BELOW ARE TAKEN FOR A DEFINITE PLAYER IMAGE SIZE
        # EACH RECTANGLE CORRESPOND TO A SPECIFIC LOCATION ON THE AIRCRAFT
        left_wing       = Rect(player_rect.topleft[0], player_rect.topleft[1],
                               <unsigned char>18, player_rect.h)
        right_wing      = Rect(player_rect.topright[0] -  <unsigned char>18,
                               player_rect.topright[1], <unsigned char>18, player_rect.h)
        engine_left     = Rect(player_rect.midbottom[0] - <unsigned char>13,
                               player_rect.midbottom[1] - <unsigned char>19,
                               <unsigned char>13, <unsigned char>19)
        engine_right    = Rect(player_rect.midbottom[0], player_rect.midbottom[1] -
                               <unsigned char>19, <unsigned char>13, <unsigned char>19)
        top             = Rect(player_rect.midtop[0] - <unsigned char>13, player_rect.midtop[1],
                               <unsigned char>26, <unsigned char>20)

        cdef list impacts = object_.collidelistall([left_wing, top,
                                                    right_wing, engine_left, engine_right])

        # ITERATE OVER ALL THE SYSTEMS
        for system in impacts:
            self.damages(SYS[system])

    cdef void damages(self, str system):
        """
        ASSIGN DAMAGES (25% or 25HP) TO THE A SPECIFIC ONBOARD ELECTRONIC DEVICE
        
        :param system: string; can be 'LW', 'SUPER', 'RW', 'RE', 'LE', 'RE'
        :return: void
        """
        status = self.gl.player.aircraft_specs.system_status

        if status[system][0]:
            system_integrity = status[system][1] - <unsigned char>25
            if system_integrity <= <unsigned char>25:
                status[system] = (False, 0)
            else:
                status[system] = (True, system_integrity)


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class PlayerLife:

    cdef public object gl, object_, player

    def __init__(self, gl_, player_, object_):
        """
        CONTROL THE PLAYER LIFE AND RESPAWN

        :param gl_    : class; global variables / constants
        :param player_: Player instance with all public attributes and methods
        :param object_: Object instance with all public attributes and methods
        """

        self.gl      = gl_
        self.player  = player_

        player_shield = self.player.shield
        mixer         = gl_.SC_spaceship
        player_status = player_.aircraft_specs.system_status


        # CHECK IF THE PLAYER SHIELD IS UP
        if player_shield is not None and player_shield.is_shield_up():


            # APPLY DAMAGE TO THE HULL IF SHIELD ENERGY VALUE IS TO LOW TO CONTAINS DAMAGE
            player_shield.shield_impact(object_.damage)

            # start a new instance (impact sprite)
            instance = Shield(
                              containers_   = gl_.All,
                              images_       = ROUND_SHIELD_IMPACT,
                              player_       = player_,
                              loop_         = False,
                              timing_       = 16,
                              event_        = 'SHIELD_IMPACT',
                              layer_        = -1
            )
            instance.heat_glow(player_.rect.clip(object_.rect))


        else:
            DamageControl(gl_, object_.rect)

            # PLAYER HAS NO SHIELD, SEND DAMAGE TO PLAYER

            player_.aircraft_specs.life -= object_.damage

            if hasattr(player_, "radar_instance") and player_.radar_instance is not None:
                player_.radar_instance.set_disruption_fx()

            # CHANGE SCREEN COLOR (WHEN PLAYER IS HURT)
            Player.player_hurt[0] += <unsigned char>3
            Player.player_hurt[1] = player_.aircraft_specs.life
            Player.player_hurt[2] = player_.aircraft_specs.max_health


        if player_.aircraft_specs.life <= 0:


            # CHECK PLAYER LIFE NUMBER?
            # PLAYER CAN RESPAWN
            if player_.aircraft_specs.life_number > 1:

                self.play_explosion_sound()
                self.explosion()
                self.blast()
                player_.clean_player_instance(int(player_.p_) - <unsigned char>1)

                gl_.PLAYER_GROUP.remove(player_)

                if PyObject_HasAttr(player_, 'radar_instance'):
                    player_.radar_instance.kill()

                player_.kill()

                Player.images = <object>PyDict_GetItem(ALL_SPACE_SHIP, player_.name)

                # IF PLAYER 1
                if player_.p_ == '1':
                    if not gl_.PLAYER_GROUP.has(player_):
                        Player.radar_flag = False
                        gl_.player = player_.respawn()

                # MUST BE PLAYER 2
                else:
                    if not gl_.PLAYER_GROUP.has(player_):
                        Player.radar_flag = False
                        gl_.player2 = player_.respawn()

                mixer.play(
                    sound_      = WHOOSH,
                    loop_       = False,
                    priority_   = 0,
                    volume_     = gl_.SOUND_LEVEL,
                    fade_out_ms = 0,
                    panning_    = False,
                    name_       = 'WHOOSH',
                    x_          = 0)

            # A PLAYER DIED (PLAYER 1 OR PLAYER 2)
            else:

                self.play_explosion_sound()
                self.explosion()
                self.blast()
                if hasattr(player_, 'radar_instance'):
                    player_.radar_instance.kill()
                player_.kill()
                player_.engine_off()
                player_.clean_player_instance(int(player_.p_) - 1)
                Player.radar_flag = False
                gl_.PLAYER_GROUP.remove(player_)
                mixer.stop_all_except(id(EXPLOSION_SOUND_1))

                # ALL SYSTEM UP AGAIN
                for system, status in player_status.items():
                    player_status[system] = (True, <unsigned char>100)

                mixer.stop_all()

                # IF NO PLAYER(S) REMAIN INTO THE GROUP, STOP / END THE GAME
                if len(gl_.PLAYER_GROUP) == 0:

                    pygame.mixer.music.pause()
                    self.game_over()

                    # Stop the blood screen effect player
                    if hasattr(gl_, 'player'):
                        if gl_.player is not None:
                            gl_.player.aircraft_specs.life = \
                            gl_.player.aircraft_specs.max_health

                    # Stop the blood screen effect player 2
                    if hasattr(gl_, 'player2'):
                        if gl_.player2 is not None:
                            gl_.player2.aircraft_specs.life =  \
                                gl_.player2.aircraft_specs.max_health

                    # display mission failed
                    pl_lost = PlayerLost(gl_=gl_, layer_=0)

                    if pl_lost is not None:
                        gl_.All.add(pl_lost)

                    pygame.image.save(gl_.screen.convert(), 'Assets/Transition.png')
                    # Set the variable gl_.FAIL
                    # gl_.FAIL = True  # will restart the level
                    timer = Timer(gl_, 6)
                    timer.start()


        else:

            if 151 < player_.aircraft_specs.life < 800:

                # CHECK IF THE SOUND IS ALREADY PLAYING
                if not mixer.get_identical_sounds(HEART_SOUND):

                    mixer.play(
                        sound_          = HEART_SOUND,
                        loop_           = False,
                        priority_       = 2,
                        volume_         = gl_.SOUND_LEVEL,
                        fade_out_ms     = 0,
                        panning_        = False,
                        name_           = 'HEART',
                        x_              = 0)

            GenericAnimation(group_     = gl_.All,
                             images_    = BURST_UP_RED,
                             object_    = object_,
                             ratio_     = None,
                             timing_    = 15,
                             offset_    = None,
                             event_name_= 'IMPACT',
                             loop_      = False,
                             gl_        = gl_,
                             score_     = Score,
                             layer_     = -1)

            self.play_impact_sound()


            for r in range(2):

                Blast(group_    = gl_.All,
                      images_   = BLAST1,
                      gl_       = gl_,
                      object_   = object_,
                      timing_   = <float>16.67,
                      layer_    = -1,
                      blend_    = BLEND_RGB_ADD)

                BLAST_INVENTORY.remove(id(object_))

            # CHECK THE OBJECT INSTANCE
            # IF THE OBJECT HAS LIFE ATTRIBUTE (LEAVING OBJECT) THEN
            # THE ENEMY MUST TAKE COLLISION DAMAGES

            if type(object_).__name__ == "Enemy":
                if PyObject_HasAttr(object_, 'hp'):
                    object_.hp -= player_.aircraft_specs.collision_damage
                    object_.player_inflicting_damage = player_
                    return

            if PyObject_HasAttr(object_, 'kill'):
                object_.kill()



    cdef play_explosion_sound(self):
        self.gl.SC_explosion.play(
            sound_      = EXPLOSION_SOUND_1,
            loop_       = False,
            priority_   = 0,
            volume_     = self.gl.SOUND_LEVEL,
            fade_out_ms = 0,
            panning_    = False,
            name_       = 'EXPLOSION_SOUND_1',
            x_          = 0)

    cdef play_impact_sound(self):
        if not self.player.shield.is_shield_up():
            self.gl.SC_explosion.play(
                sound_      = IMPACT2,
                loop_       = False,
                priority_   = 0,
                volume_     = self.gl.SOUND_LEVEL,
                fade_out_ms = 0,
                panning_    = False,
                name_       = 'IMPACT2',
                x_          = 0)

    cdef blast(self):
        player    = self.player
        gl = self.gl
        cdef:
            long long int player_id = id(self.player)

        if player.aircraft_specs.debris is not None:
            if player_id not in BLAST_INVENTORY:
                for r in self.player.aircraft_specs.debris:
                    Blast(group_    = gl.All,
                          images_   = r,
                          gl_       = gl,
                          object_   = player,
                          timing_   = <float>16.67,
                          blend_    = 0)
                    if player_id in BLAST_INVENTORY:
                        BLAST_INVENTORY.remove(player_id)

    cdef explosion(self):

        player  = self.player
        gl      = self.gl
        cdef float v = <float>0.0
        cdef int r

        # CREATE FLASH EFFECT
        BindSprite(
            group_      = gl.All,
            images_     = RADIAL,
            object_     = player,
            gl_         = gl,
            offset_     = None,
            timing_     = 15,
            layer_      = 0,
            blend_      = BLEND_RGB_ADD)

        # display the explosion
        for r in range(5):
            position = Vector2(randRange(-<int>100, <int>100), randRange(-<int>100, <int>100))
            BindSprite(group_       = gl.All,
                       images_      = EXPLOSION19,
                       object_      = player,
                       gl_          = gl,
                       offset_      = position,
                       timing_      = <int>(15 * v),
                       layer_       = 0,
                        blend_       = BLEND_RGB_ADD)
            v += <float>0.2

        # display the halo
        BindSprite(group_       = gl.All,
                   images_      = HALO_SPRITE9_,
                   object_      = player,
                   gl_          = gl,
                   offset_      = None,
                   timing_      = 15,
                   layer_       = 0,
                   blend_       = BLEND_RGB_ADD)

        # play the explosion sound
        self.gl.SC_explosion.play(
            sound_      = EXPLOSION_SOUND_2,
            loop_       = False,
            priority_   = 2,
            volume_     = gl.SOUND_LEVEL,
            fade_out_ms = 0, panning_=True,
            name_       = "PLAYER EXPLOSION",
            x_          = player.rect.centerx,
            object_id_  = id(EXPLOSION_SOUND_2))


    cdef game_over(self):

        # re-initalize the FRAME
        self.gl.FRAME = 0
        # Re-initialize the GAME_START
        self.gl.GAME_START = time.time()
        self.gl.PAUSE_TOTAL_TIME = 0
        # Stop Player2 client socket


