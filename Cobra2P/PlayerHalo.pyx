

# CYTHON IS REQUIRED
import numpy
from numpy import float32

# from Textures import RADIAL4_ARRAY_256x256, RADIAL4_ARRAY_512x512, RADIAL4_ARRAY_256x256_FAST

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

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, BLEND_RGB_ADD, Rect
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, \
        array3d, make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotate

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:
    from Sprites cimport Sprite, spritecollideany, spritecollide, LayeredUpdates
    from Sprites import Group
except ImportError:
    raise ImportError("\nSprites.pyd missing?!.Build the project first.")

from Weapons import HALO_EXPLOSION
from AI_cython import Threat
import Player
from Enemy_ import GroundEnemyTurretSentinel, GroundEnemyDroneClass
from BulletHell import EnemyBoss
from CobraLightEngine import LightEngineBomb

cdef float ONE_255 = 1.0 / 255.0

cdef list PLAYERHALO_INVENTORY = []
cdef PLAYERHALO_INVENTORY_APPEND = PLAYERHALO_INVENTORY.append
cdef PLAYERHALO_INVENTORY_REMOVE = PLAYERHALO_INVENTORY.remove



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef v1_vector_components_alternative(v1, v2, float m1, float m2, x1, x2):
    """ SCALAR SIZE V1 OF THE ORIGINAL PLAYER SPEED REPRESENTED BY (V1, M1, X1 ARGUMENTS)."""
    cdef float mass = <unsigned char>2 * m2 / (m1 + m2)
    cdef c1 = x1 - x2
    cdef float c2 = c1.length()
    return v1 - (mass * (v1 - v2).dot(c1) / (c2 * c2)) * c1



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef void kill_enemy_bullets(obj_, group_, bullet_hell_group_):
    """
    CHECK COLLISION BETWEEN THE SHOCKWAVE RECTANGLE AGAINST TWO GROUPS SEQUENTIALLY 
    FIRST ENEMY GROUP THEN BULLET GROUP. REMOVE EVERY OBJECT (KILL) COLLIDING
    
    :param obj_   : pygame sprite group; First group (PlayerHalo sprite instance, bomb shockwave). 
    :param group_ : pygame sprite group; second group to check collision with 
    (Group containing all the enemies,
     asteroid,and dummy rectangles)
    :param bullet_hell_group_: pygame sprite group (enemy bullet group)
    :return: void
    """
    # TODO IF AN ENEMY BOSS IS INSIDE THE SHOCKWAVE IT WILL BE KILLED

    # FIND SPRITES IN A GROUP THAT INTERSECT ANOTHER SPRITE
    # ALL SPRITES THAT COLLIDE WILL BE REMOVED FROM THE GROUP.
    # REMOVE ENEMY INSIDE THE SHOCKWAVE AREA
    # spritecollide(sprite=obj_, group=group_, dokill=True)

    # REMOVE EVERY BULLET IN THE SHOCKWAVE ARE
    spritecollide(sprite=obj_, group=bullet_hell_group_, dokill=True)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef sort(obj_, group_union_):
    """
    RETURN A SINGLE SPRITE FROM THE GROUP GROUP_UNION (ENEMY) COLLIDING 
    WITH THE SHOCKWAVE RECTANGLE. IF THE GIVEN SPRITE HAS ALREADY BEEN 
    PROCESS (PRIOR PULL), IT WILL BE DISREGARDED AND THE FUNCTION WILL RETURN NONE.
    
    :param obj_        : pygame sprite group; First group (PlayerHalo sprite, bomb shockwave). 
    :param group_union_:  pygame sprite group; second group to check collision with 
    (Group containing all the enemies,
     asteroid,and dummy rectangles)
    :return: Return None (sprite already process) or return a single sprite from 
    the group group_union (enemy)
    """
    # FINDS ANY SPRITES IN A GROUP THAT COLLIDE WITH THE GIVEN SPRITE
    kill = spritecollideany(obj_, group_union_)

    # BLASTED_OBJET IS A LIST CONTAINING ALL THE SPRITES IDs ALREADY PROCESSED (TAKEN DAMAGES)
    if id(kill) in obj_.blasted_object:
        return None

    return kill

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void shock_wave_collision(obj_, tuple centre_, halo_, enemy_,
                                unaffected_group_, bullet_hell_group_, gl_):
    """
    ENEMIES IN THE SHOCKWAVE AREA WILL UNDERTAKE DAMAGES OR BE DESTROYED (BULLETS).
    
    * You can pass a sprite group containing object to be excluded from the elastic collision 
    (unaffected_group_)
      If you noticed objects that should not fly around after an explosion 
      (nuke explosion for example), add them to this group
    * Centre represent the original position of the explosion or shockwave centre, 
    the elastic collision process 
      will graduate the amount of damages pass to the enemy according to the distance 
      from the shockwave centre.
    
    :param obj_              : pygame sprite; Shockwave sprite (PlayerHalo instance). 
    The shockwave rect is used 
    for the collision detection process and to determine the elastic collision vector v1  
    :param centre_           : tuple; coordinates x, y centre of the explosion 
    (also shockwave centre)
    :param halo_             : class/instance; This is the instance containing 
    all the attributes of the halo, e.g
    HALO_NUCLEAR_BOMB = HALO(name='NUCLEAR_HALO', min_radius=200, radius=900, velocity=0.57,
     mass=10000.0, damage=820) 
    :param enemy_            : instance; Enemy sprite instance containing attributes 
    (e.g object mass)
    :param unaffected_group_ : sprite group; Sprites to exclude from the elastic collision
     (e.g gems etc). Objects 
    that can be in the shockwave area without being thrown away.
    :param bullet_hell_group_: sprite group; Bullet group 
    :param gl_               : class; Global variables/ constants
    :return: void 
    """

    cdef:
        float distance, m1=0, m2=0
        v1=0, v2=0, x1=0, x2=0
        int center_x = centre_[0]
        int center_y = centre_[1]

    # CHECK COLLISIONS BETWEEN THE SHOCK WAVE RECT AND BOTH GROUP (ENEMY BULLETS AND ENEMY GROUP)
    # WHEN AN ENEMY/BULLET COLLIDE WITH THE SHOCK WAVE IT WILL BE FLAGGED KILLED (DOKILL=True)
    kill_enemy_bullets(obj_, gl_.enemyshots, bullet_hell_group_)

    # RETURN A SINGLE OBJECT FROM ALL OBJECTS COLLIDING WITH THE SHOCKWAVE RECT.
    # sort CAN ALSO RETURN NONE WHEN THE SPRITE HAS BEEN ALREADY INSERTED INTO
    # THE GROUP blasted_object
    kill = sort(obj_, gl_.GROUP_UNION)
    #
    cdef:
        int kill_centre_x
        int kill_centre_y

    if kill is not None:

        # CHECKING IF THE SPRITE RETURN BY SORT IS NOT A DUMMY SPRITE SUCH AS nuke_aiming_point
        # AND CHECK IF THE SPRITE HAS THE ATTRIBUTE vector (THIS ATTRIBUTE IS NEEDED FOR
        # ELASTIC COLLISION
        if kill not in gl_.nuke_aiming_point and PyObject_HasAttr(kill, 'vector'):

            kill_rect = kill.rect
            kill_centre_x = kill_rect.centerx
            kill_centre_y = kill_rect.centery

            # CHECK IF SPRITE HAS ALREADY RECEIVED DAMAGES FROM THE BLAST (PREVIOUS ITERATION/CALLS)
            if id(kill) not in obj_.blasted_object:
                distance = Threat.get_distance(Vector2(centre_),
                                               Vector2((kill_centre_x, kill_centre_y)))


                # AVOID ValueError: CAN'T NORMALIZE VECTOR OF LENGTH ZERO
                # DISTANCE FROM THE CENTER OF THE SHOCKWAVE IS NULL !
                if distance != 0.0:

                    # NORMALIZE VECTOR
                    v2 = Vector2(kill_centre_x - center_x, kill_centre_y - center_y).normalize()
                    v2 *= 10
                    if kill.vector.length() != 0:
                        v1 = Vector2(kill.vector.x, kill.vector.y).normalize()
                    else:
                        v1 = Vector2(kill.vector.x, kill.vector.y)

                    if PyObject_HasAttr(kill, 'enemy_'):


                        # AIRCRAFT TYPE TAKING DAMAGES
                        if PyObject_IsInstance(kill, enemy_):
                            m1 = kill.enemy_.mass
                            kill.hit(player_     = obj_.player,
                                     object_     = kill,
                                     weapon_     = halo_,
                                     bomb_effect_= True,
                                     )

                        # GROUND ENEMY TAKING DAMAGES
                        elif PyObject_IsInstance(kill.enemy_,
                                                 (GroundEnemyDroneClass,
                                                  GroundEnemyTurretSentinel)):
                            kill.hit(player_        = obj_.player,
                                     object_        = kill,
                                     weapon_        = halo_,
                                     bomb_effect_   = True,
                                     )

                        # BOSS TYPE TAKING DAMAGES
                        elif PyObject_IsInstance(kill, EnemyBoss):
                            m1 = kill.enemy_.mass
                            kill.hit(player_        = obj_.player,
                                     object_        = kill,
                                     weapon_        = halo_,
                                     bomb_effect_   = True,
                                     )

                    # EXCLUDE TYPES LIKE GROUND TURRETS, GROUND ENEMY DRONES, SHIELD GENERATOR
                    # FROM THE ELASTIC COLLISION (BEING THROWN AWAY)
                    if type(kill) not in unaffected_group_:
                        x1 = Vector2(kill_centre_x, kill_centre_y)
                        x2 = Vector2(obj_.rect.center)
                        m2 = <float>halo_.mass / distance
                        v11 = v1_vector_components_alternative(v1, v2, m1, m2, x1, x2)

                        kill.vector = v11
                        if PyObject_IsInstance(kill, EnemyBoss):
                            kill.momentum = v11

                # ** DISTANCE == 0 **

                else:
                    if PyObject_IsInstance(kill, enemy_):

                        kill.hit(player_        = obj_.player,
                                 object_        = kill,
                                 weapon_        = halo_,
                                 bomb_effect_   = True,
                                 )

                    elif PyObject_IsInstance(kill, EnemyBoss):
                        kill.hit(player_        = obj_.player,
                                 object_        = kill,
                                 weapon_        = halo_,
                                 bomb_effect_   = True,
                                 )

                # PUT OBJECT INTO THE LIST (TAGGED HAS RECEIVED DAMAGES)
                obj_.blasted_object.append(id(kill))

            # ** OBJECT ALREADY BLASTED **
            else:
                pass

        # ** DUMMY RECT OR MISSING ATTRIBUTE vector_ **
        else:
            pass

# color = numpy.array([247.0 * ONE_255, 94.0 * ONE_255, 19.0 * ONE_255], float32, copy=False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class PlayerHalo(Sprite):

    cdef:
        public object image, rect
        public int _layer, _blend


    def __init__(
            self,
            group_,
            images_,
            player_,
            object_,
            gl_,
            enemy_,
            unaffected_group,
            bullet_hell_,
            float timing_=16.67,
            halo=HALO_EXPLOSION,
            int layer_=-1):
        """

        :param group_   : sprite group; Sprite group this sprite belong
        :param images_  : Surface; list of surfaces for the halo/shockwave animation.
         surface can also be a
        single surface as an argument but it will be converted to a list
        :param player_  : class/instance; Player instance
        :param object_  : Sprite; Object colliding with the bomb
        :param gl_      : class; global variables/constants
        :param enemy_   : Group; Sprite group containing all the enemy sprite instances
        :param unaffected_group: Group; list of sprite to exclude from the elastic collision process
        :param bullet_hell_: Group; Sprite group containing all the bullet sprites
        :param timing_     : Cap the maximum FPS to default 60 fps 16.67 ms
        :param halo        : instance; Instance containing all the attributes such as :
        HALO_NUCLEAR_BOMB = HALO(name='NUCLEAR_HALO', min_radius=200, radius=900, velocity=0.57,
        mass=10000.0, damage=820)
        :param layer_      : integer; sprite layer
        """
        if PyObject_HasAttr(halo, 'velocity'):
            assert halo.velocity != 0.0, \
                "halo velocity cannot be null! please the value velocity"
        else:
            raise AttributeError("halo instance does not have attribute velocity")


        if id(player_) in PLAYERHALO_INVENTORY:
            return

        Sprite.__init__(self, group_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        # IF PLAYER_ IS NOT A PLAYER INSTANCE USE PLAYER_ ATTRIBUTE TO RETRIEVE THE PLAYER CLASS
        if not PyObject_IsInstance(player_, type(Player)) and PyObject_HasAttr(player_, 'player'):
            self.player = player_.player
        else:
            self.player = player_

        self.halo = halo
        self.gl = gl_

        # BUILD A LIST
        if PyObject_IsInstance(images_, Surface):
            self.images = [images_ * <unsigned char>30]

        self.images_copy = images_.copy()
        self.image = <object>PyList_GetItem(self.images_copy, 0)

        if object_ is None:
            self.rect = self.image.get_rect(center=self.player.rect.center)
        else:
            self.rect = self.image.get_rect(center=object_.rect.center)

        self.blast_rectangle        = pygame.Rect(10, 10,
                                                  self.halo.min_radius, self.halo.min_radius)

        self.blast_rectangle.center = self.rect.center
        self.sign                   = 1
        self.blasted_object         = []
        self.enemy                  = enemy_
        self.unaffected_group       = unaffected_group
        self.object                 = object_
        self.gl.SHOCKWAVE           = True
        self.bullet_hell            = bullet_hell_
        self.dt                     = 0
        self.index                  = 0
        self.timing                 = timing_

        # LightEngineBomb(
        #     gl_,
        #     self,
        #     array_alpha_ = RADIAL4_ARRAY_512x512,
        #     fast_array_alpha_ = RADIAL4_ARRAY_256x256_FAST,
        #     intensity_  = 12.0,
        #     color_      = color,
        #     smooth_     = False,
        #     saturation_ = False,
        #     sat_value_  = 1.0,
        #     bloom_      = False,
        #     bloom_threshold_ = 128,
        #     heat_       = False,
        #     frequency_  = 1.0,
        #     blend_      = BLEND_RGB_ADD,
        #     timing_     = self.timing,
        #     time_to_live_ = 80,
        #     fast_         = True)

        PLAYERHALO_INVENTORY_APPEND(id(player_))

    cdef void quit(self):
        """
             
        :return: void 
        """
        try:
            if id(self.player) in PLAYERHALO_INVENTORY:
                PLAYERHALO_INVENTORY_REMOVE(id(self.player))

        except Exception as e:
            pass

        finally:
            self.kill()

    cpdef update(self, args=None):

        cdef int index  = self.index
        cdef int sign   = self.sign
        blast_rectangle = self.blast_rectangle

        if self.dt > self.timing:

            # self.gl.WOBBLY = 10 if self.gl.WOBBLY in (0, -10) else -10

            self.image = <object>PyList_GetItem(self.images_copy, index)

            if self.object is None:
                self.rect = self.image.get_rect(center=self.player.rect.center)
            else:
                self.rect = self.image.get_rect(center=self.object.rect.center)


            # ELASTIC COLLISION SIMULATION
            # SIGN > 0 INFLATING THE RECTANGLE
            if sign == 1:

                # INFLATE THE RECTANGLE UNTIL IT REACH THE MAXIMUM BLAST RADIUS
                if blast_rectangle.size < (self.halo.blast_radius, self.halo.blast_radius):

                    blast_rectangle.inflate_ip(<int>(index / self.halo.velocity),
                                               <int>(index / self.halo.velocity))
                else:
                    # WE WE REACH THE MAXIMUM RADIUS, CHANGING SIGN (DEFLATE THE RECTANGLE)
                    sign = -1
            else:
                # DEFLATE THE RECTANGLE TO (100, 100)
                if blast_rectangle.size > (<unsigned char>100, <unsigned char>100):
                    blast_rectangle.inflate_ip(-index, - index)
                else:
                    sign = 0

            blast_rectangle.center = self.rect.center

            # ASSIGN SELF.RECT TO BLAST_RECTANGLE FOR COLLISION DETECTION
            self.rect = blast_rectangle

            explosion_centre = self.rect.center

            if sign == 1:
                shock_wave_collision(self, explosion_centre, self.halo,
                                    self.enemy, self.unaffected_group, self.bullet_hell, self.gl)

            # RE-ASSIGN SELF.RECT TO ITS ORIGINAL LOCATION
            self.rect = self.image.get_rect(center=explosion_centre)

            if index < PyList_Size(self.images_copy) - <unsigned char>1:
                index += <unsigned char>1
            else:
                self.quit()

            self.dt = 0

        self.index = index
        self.sign  = sign
        self.blast_rectangle = blast_rectangle

        self.dt += self.gl.TIME_PASSED_SECONDS
