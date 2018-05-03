"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """

from pygame import *
from surface_cython import *
from Constants import SCREENRECT
from Shipspecs import SHIP_SPECS
import time


class SuperLaser(pygame.sprite.Sprite):
    containers = None
    # track number of instances
    instantiate = False

    def __new__(cls, weapon_type, time_passed_seconds,
                                          sc_spaceship, player, All, follower_instance,  layer_=-2, *args, **kwargs):
        # return if an instance already exist.
        if SuperLaser.instantiate or SHIP_SPECS.energy < len(weapon_type.sprite) * weapon_type.energy:
            follower_instance.kill_instance(follower_instance)
            return
        else:
            return super().__new__(cls, *args, **kwargs)


    def __init__(self, weapon_type, time_passed_seconds, sc_spaceship, player, All, follower_instance, layer_=-2):

        pygame.sprite.Sprite.__init__(self, self.containers)

        SuperLaser.instantiate = True

        # Change sprite layer
        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_ and self.alive():
                All.change_layer(self, layer_)

        self.weapon = weapon_type
        # Weapon is now firing
        self.weapon.shooting = True
        # set the timestamp
        self.weapon.elapsed = time.time()

        self.images_copy = self.weapon.sprite.copy()
        self.image = self.images_copy[0] if isinstance(self.images_copy, list) else self.images_copy

        self.rect = self.image.get_rect(center=player.rect.center)

        if isinstance(self.images_copy, list):
            self.index_max = len(self.images_copy) - 1

        self.index = 0
        self.dt = 0

        self.w, self.h = self.image.get_width(), self.image.get_height()
        self.time_passed_seconds = time_passed_seconds
        self.sc_spaceship = sc_spaceship
        self.player = player
        self.pos = pygame.math.Vector2(self.player.rect.center)

        self.follower_instance = follower_instance


    def quit(self):
        SuperLaser.instantiate = False
        # Stop the sound object associated with the instance name
        self.sc_spaceship.stop_object(id(self))
        # stop the shaft of light
        self.follower_instance.kill_instance(self.follower_instance)
        self.kill()

    def beam_sound(self):
        self.sc_spaceship.play(sound_=self.weapon.sound_effect, loop_=False, priority_=0, volume_=0.5,
                               fade_out_ms=0, panning_=True, name_=self.weapon.name, x_=0, object_id_=id(self))

    def update(self):

        if self.dt > 10:

            if self.player.alive():

                if self.rect.colliderect(SCREENRECT):

                    if self.index < 1:
                        self.beam_sound()

                    s = pygame.Surface((self.w, self.player.rect.centery), flags=SRCALPHA, depth=32)

                    for r in range(self.player.rect.centery // self.h):
                        s.blit(self.images_copy[self.index], (0, r * self.h))

                    self.image = pygame.transform.smoothscale(s, (s.get_width(), s.get_height()))
                    self.rect = self.image.get_rect(midbottom=self.player.rect.center)

                    SHIP_SPECS.energy -= self.weapon.energy
                    # Check the energy level.
                    # if energy is too low, kill the sprite
                    if SHIP_SPECS.energy < 0:
                        self.quit()

                    if isinstance(self.images_copy, list):
                        if self.index >= self.index_max:
                            self.quit()
                        else:
                            self.index += 1

                else:
                    self.quit()

            else:
                self.quit()

            self.dt = 0
        self.dt += self.time_passed_seconds
