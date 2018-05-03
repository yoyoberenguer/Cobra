"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """


import pygame
from math import atan2
from Constants import COS, SIN, SCREENRECT, RAD_TO_DEG
from MissileParticleFx import MissileParticleFx


class HomingMissile(pygame.sprite.Sprite):
    containers = None
    images = None
    is_locked = False
    is_nuke = False


    def __init__(self, target_, weapon_, time_passed_seconds, All, enemy_group,
                 player, offset_=None, nuke_=False, timing_=33, layer_=-2):

        pygame.sprite.Sprite.__init__(self, self.containers)

        if layer_:
            if isinstance(All, pygame.sprite.LayeredUpdates):
                All.change_layer(self, layer_)

        # assert isinstance(target_, (pygame.Rect, Asteroid, Enemy)), \
        #    'Expecting pygame.Rect, Asteroids or Enemy got %s' % type(target_)
        # assert isinstance(offset_, (tuple, type(None))), 'Expecting tuple or None got %s ' % type(offset_)

        self.weapon = weapon_

        # missile speed
        self.speed = pygame.math.Vector2()
        self.speed.x = 0
        self.speed.y = float(weapon_.velocity.y)
        self.magnitude = self.speed.length()
        self.rotation = 90
        self.target = target_

        self.images_copy = self.images.copy()
        self.image = self.images_copy[0] if isinstance(self.images_copy, list) else self.images_copy


        self.offset = player.center() if offset_ is None else offset_


        self.rect = self.image.get_rect(midbottom=self.offset)
        # missile location
        self.pos = self.rect.center

        self.vector = pygame.math.Vector2()

        HomingMissile.is_locked = True
        self.index = 0

        if nuke_:
            HomingMissile.is_nuke = True

        self.timing = timing_
        self.dt = 0
        self.time_passed_seconds = time_passed_seconds
        self.All = All
        self.enemy_group = enemy_group



    @staticmethod
    def rot_center(image_: pygame.Surface, angle_, rect_) -> (pygame.Surface, pygame.Rect):
        """rotate an image while keeping its center and size (only for symmetric surface)"""
        # assert isinstance(image_, pygame.Surface), \
        #    ' Expecting pygame surface for argument image_, got %s ' % type(image_)
        # assert isinstance(angle_, (int, float)), \
        #    'Expecting int or float for argument angle_ got %s ' % type(angle_)
        # new_image = pygame.transform.rotozoom(image_, angle_, 1)
        new_image = pygame.transform.rotate(image_, angle_)
        return new_image, new_image.get_rect(center=rect_.center)


    def location(self):
        return self.rect

    def center(self):
        return self.rect.center

    def update(self):
        if self.dt > self.timing:

            if not isinstance(self.target, pygame.Rect):

                # Returns True when the Sprite belongs to one or more Groups.
                if self.target.alive():

                    # Returns True if the sprite belongs to the group
                    if self.target in self.enemy_group:

                        dx = self.target.rect.centerx - self.rect.centerx
                        dy = self.target.rect.centery - self.rect.centery
                        rotation = atan2(dy, dx) * RAD_TO_DEG

                        angle = -rotation - self.rotation

                        self.image, self.rect = self.rot_center(self.images_copy[self.index], angle, self.rect)

                        self.speed.x = COS[int(rotation % 360)] * self.magnitude
                        self.speed.y = SIN[int(rotation % 360)] * self.magnitude

                        self.rect.center += self.speed

                        # Particle effect
                        for N in range(4):
                            MissileParticleFx(self.rect, self.speed,
                                              33, SCREENRECT, self.time_passed_seconds, self.All, -2)

                        """
                        # check for collision with any targets 
                        target = pygame.sprite.spritecollideany(self, GROUP_UNION)
    
                        if target:
    
                            target.hit(object_=target, weapon_=HALO_STINGER_MISSILE, bomb_effect_=True)
    
                            # play an explosion sound
                            SC_explosion.stop_name('MISSILE EXPLOSION')
                            SC_explosion.play(sound_=MISSILE_EXPLOSION_SOUND, loop_=False, priority_=0,
                                              volume_=SOUND_LEVEL, fade_out_ms=0, panning_=True, name_='MISSILE EXPLOSION',
                                              x_=player.center()[0])
                            GenericAnimation.images = MISSILE_EXPLOSION
                            GenericAnimation(target, None, 20, self.rect, 'MISSILE EXPLOSION', False)
    
                            self.kill()
                        """
                    # sprite (target) is still alive but does
                    # not belongs to any group
                    else:
                        # continue in the same direction
                        # but does not check for collision
                        self.rect.center += self.speed

                # Srpite (target) is now dead
                else:
                    # Continue but does not check for collision
                    self.rect.center += self.speed

            # NUCLEAR BOMB
            else:
                self.rect.center += self.speed
                self.pos = self.rect.center

            # missile is not display is not display
            # into the screen boudaries.
            if not SCREENRECT.contains(self.rect):
                if isinstance(self.target, pygame.Rect):
                    HomingMissile.is_nuke = False
                self.kill()
                return

            if isinstance(self.images_copy, list):
                if self.index >= len(self.images_copy) - 1:
                    self.index = 0
                else:
                    self.index += 1

            self.dt = 0

        self.dt += self.time_passed_seconds
