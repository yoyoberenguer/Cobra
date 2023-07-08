# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8
from random import randint

from Weapons import Weapons

from pygame import BLEND_RGB_ADD
from pygame.transform import scale
from pygame.math import Vector2


from Sprites cimport Sprite
from Sprites cimport LayeredUpdates


# CYTHON IS REQUIRED
from hsv_surface cimport hsv_surface24c_inplace, hsv_surface24c

try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject, PyObject_HasAttr, PyObject_IsInstance
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size
except ImportError:
    print("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")
    raise SystemExit


cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;

# VERTEX CONTAINING ALL THE SUPER LASER SPRITES
cdef list VERTEX_SUPER_LASER = []
VERTEX_SUPER_LASER_REMOVE = VERTEX_SUPER_LASER.remove
VERTEX_SUPER_LASER_APPEND = VERTEX_SUPER_LASER.append

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef void remove_sprite(sprite_):
    """
    KILL A SPRITE AND ASSOCIATED INSTANCE AND REMOVE IT FROM THE VERTEX INVENTORY 
      
    Kill the sprite if the player is no longer alive, if the player energy is too low <0.  
    
    :param sprite_: pygame sprite; Sprite to kill with sub instance
    :return: Void
    """
    # STOP THE SOUND EFFECT
    sprite_.gl.SC_spaceship.stop_object(id(sprite_))

    # STOP LASER EFFECT BY KILLING FOLLOWERS (SUB INSTANCE)
    if sprite_.follower_instance is not None and sprite_.follower_instance.alive():
        sprite_.follower_instance.kill()

    # KILL THE SPRITE
    if PyObject_HasAttr(sprite_, 'kill'):
        sprite_.kill()

    # REMOVE THE SPRITE FROM THE VERTEX INVENTORY
    if sprite_ in VERTEX_SUPER_LASER:
        VERTEX_SUPER_LASER_REMOVE(sprite_)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void display_super_laser(bint hue_=False, bint inplace_=False, float factor_=1.0):
    """
    UPDATE THE DISPLAYED IMAGE OF THE SUPER LASER EFFECT. THIS ALGO DO NOT 
    DISPLAY THE SPRITES ONTO YOUR SCREEN, IT DOES NOT BLIT THE SURFACE TO YOUR DISPLAY.  
    
    This code check all the sprites from the inventory and update/scale the sprites according 
    to the player location. Also decrease the player amount of energy after calling this function. 
    If the player energy is too low, kill the super laser effect.
    
    :param hue_    : bool; Allow hue shifting  
    :param inplace_: bool; True, do a hue shifting inplace (hue shift inplace rotate the hue from the latest 
    transformation and tend to hue a surface very quickly). When using the technic inplace choose factor value 
    accordingly to avoid shifting the hue too quickly.  
    :param factor_ : float; Degrees per frames
    :return: void
    """
    cdef float f
    cdef int index


    f = factor_/ <float>360.0
    for spr in VERTEX_SUPER_LASER:

        index = spr.index
        spr_player = spr.player

        if spr_player.alive():

            mid_top = (spr_player.rect.centerx if spr.turret is None else
                        spr.turret.rect.centerx, 0)

            image = <object>PyList_GetItem(spr.images_copy, index)
            if hue_:
                if inplace_:
                    image = hsv_surface24c_inplace(image, index * f)
                else:
                    image = hsv_surface24c(image, index * f)


            # TRANSFORM AND SCALE THE SPRITE
            spr.image = scale(image, (image.get_width() - randRange(<int>0, <int>10),
                 spr_player.rect.centery if spr.turret is None else spr.turret.rect.centery))

            # spr.image.convert()
            spr.rect = spr.image.get_rect(midtop=mid_top)

            spr.player_energy -= spr.super_energy

            # IF ENERGY LEVEL IS TOO LOW, KILL THE SPRITE
            if spr.player_energy < 0:
                remove_sprite(spr)

            if PyObject_IsInstance(spr.images_copy, list):
                if index >= spr.index_max:
                    remove_sprite(spr)
                else:
                    index += 1
        else:

            remove_sprite(spr)

        spr_player.aircraft_specs.energy = spr.player_energy
        spr.index = index



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef super_laser_improved(gl_, player_, follower_instance_, super_laser_, surface_,
                           turret_=None, bint mute_=False, int layer_=-2):
    """
    TRIGGER THE SUPER LASER EFFECT
    
    * Player energy level must be > to the require amount of the beam energy to initiate the laser effect
     
    
    :param gl_               : class;  Global variables/constants, see GL class for more details.
    :param player_           : instance; Player instance Nemesis or Leviathan
    :param follower_instance_: instance; Follower instance
    :param super_laser_      : Beam instance
    :param surface_          : Beam sprites
    :param turret_           : Turret instance (left turret or right turret)
    :param mute_             : mute sound True | False
    :param layer_            : Layer to use.
    :return: void 
    """

    assert PyObject_IsInstance(super_laser_, Weapons), \
            "super_laser_ argument must be Weapons class type, got %s " % type(super_laser_)

    # RETURN IF PLAYER ENERGY LEVEL IS TOO LOW TO INITIATE A FULL BEAM
    # AT THE TIME OF THE TRIGGER
    # TOTAL ENERGY NEEDED = SPRITE DURATION (FRAME NUMBER) * ENERGY PER FRAME
    # ALSO CHECK IF ANOTHER INSTANCE IS RUNNING
    if follower_instance_ is not None and player_.aircraft_specs.energy \
            < len(super_laser_.sprite) * super_laser_.energy:
        if PyObject_HasAttr(follower_instance_, 'kill_instance'):
            follower_instance_.kill_instance(follower_instance_)
        return

    sprite = Sprite()

    Sprite.__init__(sprite, (gl_.All, gl_.shots))

    if PyObject_IsInstance(gl_.All, LayeredUpdates):
        gl_.All.change_layer(sprite, layer_)

    sprite.gl                = gl_
    sprite.player            = player_
    sprite.player_energy     = player_.aircraft_specs.energy
    sprite.follower_instance = follower_instance_
    sprite.super_laser       = super_laser_
    sprite.super_energy      = super_laser_.energy
    sprite.turret            = turret_
    sprite.mute              = mute_
    sprite._layer            = layer_
    sprite.index             = 0
    sprite._blend            = BLEND_RGB_ADD


    sprite.images_copy       = surface_.copy()
    sprite.image             = <object>PyList_GetItem(sprite.images_copy, 0) if \
        PyObject_IsInstance(surface_, list) else sprite.images_copy

    if PyObject_IsInstance(sprite.images_copy, list):
        sprite.index_max = len(sprite.images_copy) - 1


    sprite.rect = sprite.image.get_rect()
    player_rect = player_.rect

    # CHECK IF THE BEAM COME FROM ONE OF THE SIDE TURRETS
    # (LEFT OR RIGHT WING TURRET) OR DIRECTLY FROM THE PLAYER SPACESHIP CENTER.
    if turret_ is not None:
        if player_.name == 'LEVIATHAN':
            # BOTTOM OF THE RECTANGLE (REPRESENTING THE BEAM) IS
            # LOCATED AT THE TURRET CENTER POSITION
            sprite.rect.midbottom = turret_.rect.center
        else:
            # CENTER OF THE RECTANGLE REPRESENTING THE BEAM IS LOCATED
            # AT THE CENTER OF THE TURRET POSITION
            sprite.rect.center = turret_.rect.center
    else:
        if player_.name == 'LEVIATHAN':
            sprite.rect.midbottom = player_rect.center
        else:
            # BEAM SHOT FROM THE PLAYER SPACESHIP POSITION
            sprite.rect.center = player_rect.center

    gl_SC_spaceship = gl_.SC_spaceship
    # PLAY THE SUPER LASER SOUND EFFECT IF THE SOUND IS NOT MUTED AND IS NOT BEING PLAYED ON THE MIXER
    if not mute_ and not gl_SC_spaceship.get_identical_sounds(super_laser_.sound_effect):
            gl_SC_spaceship.play(sound_=super_laser_.sound_effect, loop_=False,
                                   priority_=0, volume_=gl_.SOUND_LEVEL, fade_out_ms=0,
                                   panning_=True, name_=super_laser_.name,
                                   x_=player_rect.centerx if
                                   turret_ is None else turret_.rect.centerx, object_id_=id(player_))

    # ---------------------------
    # USED FOR COMPATIBILITY ONLY
    sprite.weapon = super_laser_
    sprite.pos = Vector2(player_rect.center)
    # ---------------------------

    # WEAPON IS NOW FIRING
    super_laser_.shooting = True
    # SET THE TIMESTAMP
    super_laser_.elapsed = gl_.FRAME

    VERTEX_SUPER_LASER_APPEND(sprite)




