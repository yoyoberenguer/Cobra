# cython: binding=False, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

cimport cython

import pygame
from pygame import BLEND_RGB_ADD
from pygame import freetype
from GenericAnimation import GenericAnimation, GENERIC_ANIMATION_INVENTORY
from Sounds import SUPER_EXPLOSION_SOUND, MISSILE_EXPLOSION_SOUND, EXPLOSION_SOUND_1, \
    ENERGY_SUPPLY, \
    BOMB_CATCH_SOUND, AMMO_RELOADING_SOUND, EXTRA_LIFE, COIN_SOUND, WHOOSH, IMPACT1, \
    SEISMIC_CHARGE

from Sprites import Group

from Sprites cimport Sprite, groupcollide, spritecollideany, collide_circle_ratio, collide_mask


from Textures import SUPER_EXPLOSION, MISSILE_EXPLOSION, HALO_SPRITE8,\
    ENERGY_SUPPLY_ASSIMILATION, GEM_ASSIMILATION,  BLUE_IMPACT2 # BLUE_IMPACT, BLUE_IMPACT1,
from numpy import linspace
from Weapons import HALO_NUCLEAR_BOMB
from PlayerHalo import PlayerHalo
from HomingMissile cimport Homing
import os

from Messages import Messages, ML
from Shot import LIGHTS_VERTEX
from BulletHell import EnemyBoss, VERTEX_BULLET_HELL

FONT = freetype.Font(os.path.join('Assets\\Fonts\\', 'ARCADE_R.ttf'), size=9)
FONT.antialiased = True

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef CollisionDetection(GL,
                       Score,
                       Enemy,
                       Unaffected_group,
                       Gems,
                       PlayerLife,
                       Follower
                       ):

        mixer = GL.SC_explosion
        mixer_p = GL.SC_spaceship

        player_projectiles = Group()      # Create a new group to gather all the player's bullets
        player_projectiles.add(GL.shots, GL.missiles)   # Adding all the projectile to the group.
                                                        # e.g missiles and bullets (shot)
        for object1, obj in groupcollide(GL.GROUP_UNION, player_projectiles, False, False).items():

            # Check if the enemy sprite is still alive (still in a group)
            if object1.alive():

                for object2 in obj:

                    if hasattr(object1, 'hit') and object1 not in GL.nuke_aiming_point:

                        if hasattr(object1, 'units') and object2.weapon.units == 'SUPER':

                            object1.hit(player_     = object2.player,
                                        object_     = object1,
                                        weapon_     = object2.weapon,
                                        bomb_effect_= False,
                                        rect_center = object2.rect)

                            mixer.stop_name('SUPER_EXPLOSION_SOUND')
                            mixer.play(sound_       = SUPER_EXPLOSION_SOUND,
                                       loop_        = False,
                                       priority_    = 0,
                                       volume_      = GL.SOUND_LEVEL,
                                       fade_out_ms  = 0,
                                       panning_     = True,
                                       name_        = 'SUPER_EXPLOSION_SOUND',
                                       x_           = object2.rect.centerx)

                            generic = GenericAnimation(
                                        group_      = GL.All,
                                        images_     = SUPER_EXPLOSION,
                                        object_     = object2,
                                        ratio_      = list(linspace(
                                            1, 3, len(SUPER_EXPLOSION) >> 1)) + [1] * (
                                                        len(SUPER_EXPLOSION) >> 1),
                                        timing_     = 15,
                                        offset_     = None,
                                        event_name_ = 'EXPLOSION',
                                        loop_       = False,
                                        gl_         = GL,
                                        score_      = Score,
                                        layer_      = -1)
                            if generic is not None:
                                generic._blend = pygame.BLEND_RGB_ADD

                        # PLAYER MISSILE COLLIDING WITH ENEMY RECTANGLE(S)
                        elif object2.weapon.name == 'STINGER_SINGLE':


                            if id(object1) in GENERIC_ANIMATION_INVENTORY:
                                GENERIC_ANIMATION_INVENTORY.remove(id(object1))

                            generic = GenericAnimation(GL.All,
                                                       MISSILE_EXPLOSION,
                                                       object1,
                                                       None,
                                                       20,
                                                       object1.rect.clip(object2),
                                                       'MISSILE EXPLOSION',
                                                       False,
                                                       gl_      = GL,
                                                       score_   = Score,
                                                       layer_   = -1)

                            if generic is not None:
                                generic._blend = pygame.BLEND_RGB_ADD

                            object1.hit(player_         = object2.player,
                                        object_         = object1,
                                        weapon_         = object2.weapon,
                                        bomb_effect_    = False,
                                        rect_center     = object2.rect)

                            mixer.stop_name('MISSILE EXPLOSION')
                            mixer.play(sound_           = MISSILE_EXPLOSION_SOUND,
                                       loop_            = False,
                                       priority_        = 0,
                                       volume_          = GL.SOUND_LEVEL,
                                       fade_out_ms      = 0,
                                       panning_         = True,
                                       name_            = 'MISSILE EXPLOSION',
                                       x_               = object2.rect.centerx)

                            object2.kill()
                            continue

                        # NUKE COLLIDE WITH OBJECT (ENEMY)
                        elif object2.weapon.name == 'NUCLEAR_SINGLE':


                            mixer.stop_name('NUCLEAR_EXPLOSION')
                            mixer.play(sound_           = EXPLOSION_SOUND_1,
                                       loop_            = False,
                                       priority_        = 0,
                                       volume_          = GL.SOUND_LEVEL,
                                       fade_out_ms      = 0,
                                       panning_         = False,
                                       name_            = 'NUCLEAR_EXPLOSION',
                                       x_               = 0)

                            mixer.stop_name('WHOOSH')
                            mixer.play(sound_           = WHOOSH,
                                       loop_            = False,
                                       priority_        = 0,
                                       volume_          = GL.SOUND_LEVEL,
                                       fade_out_ms      = 0,
                                       panning_         = False,
                                       name_            = 'WHOOSH',
                                       x_               = 0)

                            g = GenericAnimation(
                                group_          = GL.All,
                                images_         = object2.player.aircraft_specs.nuke_explosion_sprite,
                                object_         = object2.rect,
                                ratio_          = None,
                                timing_         = 15,
                                offset_         = object1.rect,
                                event_name_     = 'NUCLEAR_EXPLOSION',
                                loop_           = False,
                                gl_             = GL,
                                score_          = Score,
                                layer_          = -1,
                                blend_          =1)

                            # g = Follower(GL.All, containers_=GL.ALL,
                            #              images_=object2.player.aircraft_specs.nuke_explosion_sprite,
                            #              offset_=(0, 0), timing_= 16, loop_= False,
                            #              event_= None, object_=None, layer_= -1, vector_=None,
                            #              blend_=1)

                            if g is not None:
                                g._blend = pygame.BLEND_RGB_ADD

                                PlayerHalo(
                                    group_          = GL.All,
                                    images_         = HALO_SPRITE8,
                                    player_         = object2.player,
                                    object_         = object1,
                                    gl_             = GL,
                                    enemy_          = Enemy,
                                    unaffected_group= Unaffected_group,
                                    bullet_hell_    = Group(VERTEX_BULLET_HELL),
                                    timing_         = 15,
                                    halo            = HALO_NUCLEAR_BOMB,
                                    layer_          = -1)

                                GL.nuke = <float>20.0

                            # KILL THE NUKE SPRITE
                            object2.kill()

                            # KILL THE ENEMY SPRITE
                            # object1.kill()

                            # KILL OBJECT COLLIDING WITH NUKE IF IN GROUP_UNION
                            if bool(GL.GROUP_UNION):
                                GL.GROUP_UNION.remove(object1)

                            # KILL THE DUMMY RECT
                            if bool(GL.nuke_aiming_point):
                                GL.nuke_aiming_point.remove(object1)

                            continue

                        # Death ray colliding with enemy rectangle
                        elif object2.weapon.name == 'C_DEATHRAY_SINGLE':
                            # OBJECT1 : SPRITE FROM THE ENEMY GROUP (GROUP_UNION)
                            # OBJECT2 : PROJECTILE SPRITE COLLIDING WITH THE ENEMY RECTANGLE
                            object1.hit(player_     = object2.player,
                                        object_     = object1,
                                        weapon_     = object2.weapon,
                                        bomb_effect_= False,
                                        rect_center = object2.rect)

                        else:

                            if hasattr(object1, 'weapon') and object1.weapon.name == 'Missile':

                                generic = GenericAnimation(
                                    GL.All, MISSILE_EXPLOSION,
                                    object1, None, 20, object1.rect,
                                    'MISSILE EXPLOSION', False,
                                    gl_=GL,
                                    score_=Score,
                                    layer_=-1)

                                if generic is not None:
                                    generic._blend = pygame.BLEND_RGB_ADD

                                mixer.stop_name('MISSILE EXPLOSION')
                                mixer.play(sound_       = MISSILE_EXPLOSION_SOUND,
                                           loop_        = False,
                                           priority_    = 0,
                                           volume_      = GL.SOUND_LEVEL,
                                           fade_out_ms  = 0,
                                           panning_     = True,
                                           name_        = 'MISSILE EXPLOSION',
                                           x_           = object2.rect.centerx)

                            # ENEMY MISSILE(S) COLLIDING WITH
                            # PLAYERS SHOT (TURRET, PLAYER SHOT ETC)
                            if hasattr(object1, 'super_laser') \
                                    and object1.weapon.name == 'Missile':

                                generic = GenericAnimation(
                                    GL.All, MISSILE_EXPLOSION,
                                    object1, None, 20, object1.rect,
                                    'MISSILE EXPLOSION', False,
                                    gl_ = GL,
                                    score_=Score,
                                    layer_=-1)

                                if generic is not None:
                                    generic._blend = pygame.BLEND_RGB_ADD


                                mixer.stop_name('MISSILE EXPLOSION')
                                mixer.play(sound_       = MISSILE_EXPLOSION_SOUND,
                                           loop_        = False,
                                           priority_    = 0,
                                           volume_      = GL.SOUND_LEVEL,
                                           fade_out_ms  = 0,
                                           panning_     = True,
                                           name_        = 'MISSILE EXPLOSION',
                                           x_           = object2.rect.centerx)

                                # MISSILE BEING HIT (KILL THE SPRITE)
                                object1.hit()

                            # PLAYER BULLET COLLIDING WITH ENEMY (PYGAME.RECTANGLE)
                            # OBJECT1 : SPRITE FROM THE ENEMY GROUP (GROUP_UNION)
                            # OBJECT2 : PROJECTILE SPRITE COLLIDING WITH THE ENEMY RECTANGLE
                            else:
                                # PASSING DAMAGE TO THE ENEMY
                                object1.hit(player_     = object2.player,
                                            object_     = object1,
                                            weapon_     = object2.weapon,
                                            bomb_effect_= False,
                                            rect_center = object2.rect)

                                # STOP THE SOUND IMPACT1 IF ALREADY PLAYING ON A CHANNEL
                                mixer_p.stop_name('IMPACT1')
                                # IF OBJECT1 IS NOT AN INSTANCE OF
                                # ENEMYHOMINGMISSILE, PLAY THE IMPACT SOUND
                                if not isinstance(object1, Homing):
                                    mixer_p.play(
                                        sound_     = object1.impact_sound if
                                        hasattr(object1, 'impact_sound') else
                                        IMPACT1,
                                        loop_      = False,
                                        priority_  = 0,
                                        volume_    = GL.SOUND_LEVEL,
                                        fade_out_ms= 0,
                                        panning_   = True,
                                        name_      = 'IMPACT1',
                                        x_         = object1.rect.centerx)

                                # CREATE A SPRITE THAT WILL BE ADDED TO THE VERTEX_IMPACT LIST
                                # THIS LIST CONTAINS ALL THE IMPACT SPRITE
                                # (BLUE IMPACT SPRITE AFTER COLLISION BETWEEN
                                # A PLAYER BULLET AND AN ENEMY
                                impact_sprite        = Sprite()
                                impact_sprite.images = BLUE_IMPACT2
                                impact_sprite.image  = BLUE_IMPACT2[0]
                                impact_sprite.object = object2
                                impact_sprite.offset  = (0, impact_sprite.image.get_height() >> 1)
                                impact_sprite.rect    = impact_sprite.image.get_rect\
                                    (center=object2.rect.clip(object1.rect).center)
                                # center=object2.rect.center)
                                impact_sprite._layer  = 0
                                impact_sprite.index   = 0
                                GL.VERTEX_IMPACT.append(impact_sprite)
                                # add the sprite into VERTEX_IMPACT list

                        # LIGHTS_VERTEX IS A LIST CONTAINING LIGHT EFFECT SPRITE
                        # AFTER A COLLISION (LIGHT FLASH)
                        # NO LIGHT EFFECT FOR DEATHRAY WEAPON.
                        # ALSO DELETE OBJECT2 IF OBJECT2 IS NOT A DEATHRAY WEAPON CLASS
                        if object2.weapon.name!='C_DEATHRAY_SINGLE':
                            if object2 in LIGHTS_VERTEX:
                                LIGHTS_VERTEX.remove(object2)

                            # KILL BULLET/MISSILE ETC THAT COLLIDE WITH ENEMY
                            # OBJECT1 : SPRITE FROM THE ENEMY GROUP (GROUP_UNION)
                            # OBJECT2 : PROJECTILE SPRITE COLLIDING WITH THE ENEMY RECTANGLE
                            object2.kill()


                    # NUKE COLLIDE WITH DUMMY RECT
                    else:

                        if object2.weapon.name == 'NUCLEAR_SINGLE' and \
                                (object2.rect.centery <= object1.rect.centery):
                            # print('collision with DUMMY', id(object1), id(object2))

                            mixer.stop_name('NUCLEAR_EXPLOSION')
                            mixer.play(sound_       = EXPLOSION_SOUND_1,
                                       loop_        = False,
                                       priority_    = 0,
                                       volume_      = GL.SOUND_LEVEL,
                                       fade_out_ms  = 0,
                                       panning_     = False,
                                       name_        = 'NUCLEAR_EXPLOSION',
                                       x_           = 0)

                            mixer.stop_name('WHOOSH')
                            mixer.play(sound_       = WHOOSH,
                                       loop_        = False,
                                       priority_    = 0,
                                       volume_      = GL.SOUND_LEVEL,
                                       fade_out_ms  = 0,
                                       panning_     = False,
                                       name_        = 'WHOOSH',
                                       x_           = 0)


                            g = GenericAnimation(
                                group_      = GL.All,
                                images_     = object2.player.aircraft_specs.nuke_explosion_sprite,
                                object_     = object2,  # pass the missile object to avoid duplicates
                                ratio_      = None,
                                timing_     = 15,
                                offset_     = object1.rect,
                                event_name_ = 'NUCLEAR_EXPLOSION',
                                loop_       = False,
                                gl_         = GL,
                                score_      = Score,
                                layer_      = -1)

                            if g is not None:
                                g._blend = pygame.BLEND_RGB_ADD


                                # object2 contains the player class (object2.player)
                                PlayerHalo(
                                    group_          = GL.All,
                                    images_         = HALO_SPRITE8,
                                    player_         = object2.player,
                                    object_         = object1,
                                    gl_             = GL,
                                    enemy_          = Enemy,
                                    unaffected_group= Unaffected_group,
                                    bullet_hell_    = Group(VERTEX_BULLET_HELL),
                                    timing_         = 15,
                                    halo            = HALO_NUCLEAR_BOMB,
                                    layer_          = -1)

                                GL.nuke = <float>20.0

                            # KILL THE NUKE MISSILE
                            object2.kill()

                            # REMOVE THE DUMMY TARGET RECTANGLE FROM GL.GROUP_UNION
                            # AND DELETE THE SPRITE FROM THE GL.NUKE_AIMING_POINT GROUP
                            # GL.NUKE_AIMING_POINT CONTAINS ALL TARGET RECTANGLES
                            # (SPRITE USED EXCLUSIVELY FOR THE
                            # NUKE EXPLOSION)

                            if hasattr(object1, 'kill'):
                                object1.kill()

                            if bool(GL.GROUP_UNION):
                                GL.GROUP_UNION.remove(object1)

                            # REMOVE DUMMY RECT FROM nuke_aiming_point GROUP
                            if bool(GL.nuke_aiming_point):
                                GL.nuke_aiming_point.remove(object1)



        # ************* COLLISION WITH GEMS OR ENEMY

        # CHECK COLLISION BETWEEN PLAYER(S) AND (ENEMY SPACESHIP, SHOTS, GEMS AND BONUSES)
        groups = Group()
        # groups.add(GL.enemyshots, GL.gems, GL.GROUP_UNION)
        groups.add(GL.gems, GL.GROUP_UNION)

        for obj1, obj2  in groupcollide(GL.PLAYER_GROUP, groups, False, False).items():

            for obj in obj2:

                if hasattr(obj, 'enemy_') and hasattr(obj.enemy_, 'invincible'):
                    if obj.enemy_.invincible:
                        continue

                # Player collide with gems
                if issubclass(Gems, type(obj)) and hasattr(obj, 'value'):
                    mixer_p.play(
                        sound_      = COIN_SOUND,
                        loop_       = False,
                        priority_   = 0,
                        volume_     = GL.SOUND_LEVEL,
                        fade_out_ms = 0,
                        panning_    = False,
                        name_       = 'COIN_SOUND',
                        x_          = obj1.rect.centerx)

                    obj1.aircraft_specs.gems += 1
                    obj1.aircraft_specs.gems_value += obj.value

                    Follower(GL,
                             GL.All,
                             GEM_ASSIMILATION,
                             offset_    = None,
                             timing_    = 1,
                             loop_      = False,
                             event_     = 'Gem assimilation',
                             object_    = obj1,
                             layer_     = -3,
                             blend_     = 0)

                    # REMOVE THE MESSAGE FOR GEMS (TOO MANY)
                    # surface = pygame.Surface((250, 20), pygame.RLEACCEL | pygame.HWACCEL, 32)
                    # surface.fill((0, 128, 64, 255))
                    # FONT.render_to(surface, (20, 5), 'gem +'+
                    # str(obj1.aircraft_specs.gems_value),
                    #     fgcolor=(255, 255, 255, 255),
                    #     bgcolor=(0, 128, 64, 255), style=freetype.STYLE_STRONG)
                    # Messages(surface, GL.All, -200, 450, gl_=GL)

                    # KILL THE GEMS INSTANCE
                    obj.remove_from_inventory()


                # All other collisions
                else:

                    # No collision while the player is invincible
                    if hasattr(obj1, 'invincible'):
                        if not obj1.invincible and obj1.alive():
                            # avoid collision with large enemy shield.
                            # Large enemy shield are assigned to the collision_group but are
                            # not collisional.
                            # Check if the object is from the ground group
                            if not hasattr(obj, 'hit_shield') and hasattr(obj, 'damage') \
                                    and type(obj) not in Unaffected_group:
                                # Let PlayerLife class decide to kill or not obj
                                PlayerLife(GL, player_=obj1, object_=obj)

                        # Player is not alive or
                        # player is invincible
                        else:
                            ...
                    else:
                        ...

        groups.empty()

        # COLLECTABLE COLLISION
        if GL.bonus:
            for obj1, obj2  in groupcollide(GL.PLAYER_GROUP, GL.bonus, False, True).items():

                if obj1.alive():

                    for obj in obj2:
                        if obj.bonus_type == 'ENERGY':
                            # Stop the crystal sound
                            mixer_p.stop_object(obj.object_id)
                            mixer_p.play(
                                sound_      = ENERGY_SUPPLY,
                                loop_       = False,
                                priority_   = 0,
                                volume_     = GL.SOUND_LEVEL,
                                fade_out_ms = 0,
                                panning_    = False,
                                name_       = 'ENERGY_SUPPLY',
                                x_          = 0)
                            # Add energy to the player
                            obj1.aircraft_specs.energy += obj.get_energy()

                            Follower(GL,
                                     GL.All,
                                     ENERGY_SUPPLY_ASSIMILATION,
                                     offset_        = None,
                                     timing_        = 1,
                                     loop_          = False,
                                     event_         = 'Energy supply assimilation',
                                     object_        = obj1,
                                     layer_         = -3)

                            surface = pygame.Surface((250, 20), pygame.RLEACCEL, 32)
                            surface.fill((0, 128, 192, 255))
                            FONT.render_to(surface, (20, 5), 'energy bonus +'
                                           +str(obj.get_energy()),
                            fgcolor=pygame.Color(255, 255, 250, 255),
                                           bgcolor=pygame.Color(0, 128, 192, 255),
                                              style=freetype.STYLE_STRONG)


                            Messages(surface, GL.All, -200, 450, gl_=GL)

                        elif obj.bonus_type == 'BOMB':
                            # Play the sound of a nuke being catch
                            mixer_p.play(sound_     = BOMB_CATCH_SOUND,
                                                 loop_      = False,
                                                 priority_  = 0,
                                                 volume_    = GL.SOUND_LEVEL,
                                                 fade_out_ms= 0,
                                                 panning_   = False,
                                                 name_      = 'BOMB_SUPPLY',
                                                 x_         =0
                                                 )

                            # CAP THE MAXIMUM NUKES
                            if obj1.aircraft_specs.nukes_quantity < 3:
                                obj1.aircraft_specs.nukes_quantity += 1


                            surface = pygame.Surface((250, 20), pygame.RLEACCEL, 32)
                            surface.fill((15, 15, 15, 255))
                            FONT.render_to(surface, (20, 5), 'nuke bonus +1',
                            fgcolor=pygame.Color(255, 255, 250, 255),
                                           bgcolor=pygame.Color(15, 15, 15, 255),
                                              style=freetype.STYLE_STRONG)


                            Messages(surface, GL.All, -200, 450, gl_=GL)

                        elif obj.bonus_type == 'AMMO':
                            # Play the sound of a AMMO catch
                            mixer_p.play(sound_         = AMMO_RELOADING_SOUND,
                                                 loop_          = False,
                                                 priority_      = 0,
                                                 volume_        = GL.SOUND_LEVEL,
                                                 fade_out_ms    = 0,
                                                 panning_       = False,
                                                 name_          = 'AMMO_SUPPLY',
                                                 x_             = 0)
                            # Full reload ammo and missiles
                            obj1.aircraft_specs.missiles_quantity += \
                                obj1.aircraft_specs.max_missiles
                            obj1.aircraft_specs.ammo += obj1.aircraft_specs.max_ammo

                            surface = pygame.Surface((250, 20), pygame.RLEACCEL, 32)
                            surface.fill((128, 64, 0, 255))

                            FONT.render_to(surface, (20, 5), 'missiles bonus +'
                                           +str(obj1.aircraft_specs.max_missiles),
                            fgcolor=pygame.Color(255, 255, 255, 255),
                                           bgcolor=pygame.Color(128, 64, 0, 255),
                                              style=freetype.STYLE_STRONG)

                            Messages(surface, GL.All, -200, 450, gl_=GL)

                        elif obj.bonus_type == 'LIFE':
                            # Play the sound of extra life added
                            mixer_p.play(
                                sound_         = EXTRA_LIFE,
                                loop_          = False,
                                priority_      = 0,
                                volume_        = GL.SOUND_LEVEL,
                                fade_out_ms    = 0,
                                panning_       = False,
                                name_          = 'EXTRA_LIFE',
                                x_             = 0)

                            # Cap the result to 5 life
                            if obj1.aircraft_specs.life_number < 5:
                                obj1.aircraft_specs.life_number += 1

                            surface = pygame.Surface((250, 20), pygame.RLEACCEL, 32)
                            surface.fill((241, 50, 35, 255))

                            FONT.render_to(surface, (20, 5), 'extra life bonus',
                            fgcolor=pygame.Color(255, 255, 255, 255),
                                           bgcolor=pygame.Color(241, 50, 35, 255),
                                              style=freetype.STYLE_STRONG)

                            Messages(surface, GL.All, -200, 450, gl_=GL)


        # ************** COLLISION WITH ENEMY BULLETS AND VERTEX_BULLET_HELL (BOSS)
        new_group = Group()
        new_group.add(VERTEX_BULLET_HELL)
        new_group.add(GL.enemyshots)

        # player_group = Group()
        # player_group.add(*GL.PLAYER_GROUP)
        # if hasattr(GL.player, 'shield') and GL.player.shield is not None:
        #     player_group.add(GL.player.shield)
        #     print('ADD SHIELD')
        # if hasattr(GL.player2, 'shield') and GL.player2.shield is not None:
        #     player_group.add(GL.player2.shield)

        if len(new_group) > 0:

            if GL.player in GL.PLAYER_GROUP:

                collision = spritecollideany(
                    GL.player, new_group,
                    collided = collide_circle_ratio(0.65)) # collided=pygame.sprite.collide_mask)

                if collision is not None:

                    # Check if player is invincible and alive
                    if not GL.player.invincible and GL.player.alive():
                        # avoid collision with large enemy shield.
                        # Large enemy shield are assigned to the collision_group
                        # (but cannot collide with players).
                        # Check if the object is from the ground group
                        if not hasattr(collision, 'hit_shield') and hasattr(collision, 'damage') \
                                and type(collision) not in Unaffected_group:
                            # Let PlayerLife class decide to kill or not obj
                            PlayerLife(GL, player_=GL.player, object_=collision)


                    # PLAYER IS NOT ALIVE OR PLAYER IS INVINCIBLE
                    else:
                        ...

                    if collision in VERTEX_BULLET_HELL:
                        VERTEX_BULLET_HELL.remove(collision)
                    collision.kill()

            if GL.player2 in GL.PLAYER_GROUP:

                collision = spritecollideany(
                    GL.player2, new_group,
                    collided = collide_circle_ratio(0.65)) # collided=pygame.sprite.collide_mask)

                if collision is not None:

                    # Check if player is invincible and alive
                    if not GL.player2.invincible and GL.player2.alive():
                        # avoid collision with large enemy shield.
                        # Large enemy shield are assigned to the collision_group
                        # (but cannot collide with players).
                        # Check if the object is from the ground group
                        if not hasattr(collision, 'hit_shield') and hasattr(collision, 'damage') \
                                and type(collision) not in Unaffected_group:
                            # Let PlayerLife class decide to kill or not obj
                            PlayerLife(GL, player_=GL.player2, object_=collision)

                    # Player is not alive or player is invincible
                    else:
                        ...

                    if collision in VERTEX_BULLET_HELL:
                        VERTEX_BULLET_HELL.remove(collision)
                    collision.kill()

        new_group.empty()