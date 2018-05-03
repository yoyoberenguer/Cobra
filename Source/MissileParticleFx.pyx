"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """

import pygame
from random import uniform, choice, randint
from time import time
from Constants import COS, SIN, DEG_TO_RAD, RAD_TO_DEG


class Point:

    def __init__(self, lifetime, spawn):
        self.lifetime = uniform(lifetime[0], lifetime[1])
        self.spawn = uniform(spawn[0], spawn[1])
        self.vector = pygame.math.Vector2()
        self.set_ = False
        self.start = time()

class MissileParticleFx(pygame.sprite.Sprite):

    images = []
    containers = None

    def __init__(self, rectangle, parent_trajectory, timing, screenrect, time_passed_seconds, All, layer_=-2):

        pygame.sprite.Sprite.__init__(self, self.containers)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_:
                All.change_layer(self, layer_)

        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]
        self.rect = self.image.get_rect(midbottom=(-150, -150))
        self.rectangle = rectangle
        self.particles = Point(lifetime=[0.1, 0.35], spawn=[0.0, 0.01])
        self.parent_trajectory = parent_trajectory
        self.speed = pygame.math.Vector2()
        self.speed.y = -self.parent_trajectory.y * uniform(1, 1.5)
        self.speed.x = -self.parent_trajectory.x * uniform(1, 1.2)
        self.index = 1
        self.dt = 0
        self.reduce_factor = 1.5
        self.timing = timing
        self.initialized = True
        self.time_passed_seconds = time_passed_seconds
        self.screenrect = screenrect

    def scale_particle(self, image_, factor_):
        scale = (image_.get_width() - factor_,
                 (image_.get_height() - factor_))
        if scale <= (0, 0):
            self.kill()
        return pygame.transform.scale(image_, scale)

    def set_position(self, point):
        point.vector.x = randint(-2, 2) + self.rectangle.center[0]
        point.vector.y = self.rectangle.center[1]
        self.rect.center = (point.vector.x, point.vector.y)

    def update(self):

        if self.dt > self.timing:
            # inverted logic
            if self.initialized:
                if (time() - self.particles.start) < self.particles.spawn:
                    return
                else:
                    self.initialized = False
                    if not self.particles.set_:
                        self.set_position(self.particles)
                        self.particles.set_ = True

            if (time() - self.particles.start)  - self.particles.spawn > self.particles.lifetime:
                self.kill()
            else:
                self.image = self.images_copy[self.index]
                self.images_copy[self.index] = self.scale_particle(self.images_copy[self.index],
                                                                           round(self.index * self.reduce_factor))
                self.particles.vector += self.speed
                self.rect.center = (self.particles.vector.x + round(self.index * self.reduce_factor),
                                            self.particles.vector.y)
                if self.index < len(self.images) - 1:
                    self.index += 1
                else:
                    self.kill()

                if not self.screenrect.contains(self.rect):
                    self.kill()
            self.dt = 0
        self.dt += self.time_passed_seconds




