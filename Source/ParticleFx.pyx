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
from Constants import COS, SIN, SCREENRECT


class Point:

    def __init__(self, lifetime: list, spawn: list):
        """
        Class Point regroup important data for ParticleFx class
        :param lifetime: List, Lifetime of a particle, time to live etc (in ms)
        :param spawn:    List, Time when the particle start to be display (delay in ms)
        """
        # Remove for gaining few ms
        # assert isinstance(lifetime, list) and isinstance(spawn, list), \
        #    '\n[-] Error: Expecting List only, got: lifetime:%s, spawn:%s ' % (type(lifetime), type(spawn))

        self.lifetime = uniform(lifetime[0], lifetime[1])
        self.spawn = uniform(spawn[0], spawn[1])
        self.vector = pygame.math.Vector2()  # Vector 2D for the particle coordinates
        self.set_ = False
        # get a timestamp when initialised
        self.start = time()

class ParticleFx(pygame.sprite.Sprite):
    
    """ Create particles special effect when firing """
    images = []
    containers = None
    rectangle = None

    def __init__(self, time_passed_seconds, timing_, All, layer_=-2):

        pygame.sprite.Sprite.__init__(self, self.containers)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_:
                All.change_layer(self, layer_)

        # Work from a copy
        self.images_copy = self.images.copy()
        self.image = self.images_copy[0] if isinstance(self.images, list) else self.images_copy

        self.rect = self.image.get_rect(midbottom=(-100,100))

        # Create instance variables of the rectangle otherwise the
        # position will be lost at the next ParticleFX call.
        self.rectangle_ = self.rectangle

        self.particles = Point(lifetime=[0.3, 0.8], spawn=[0.5, 1.0])

        self.speed = pygame.math.Vector2()
        self.speed.x = 0
        self.speed.y = uniform(5, 15)

        self.equation = choice(['COS[self.angle % 360] * 2', '-1', '1', 'SIN[self.angle % 360]'])

        self.index = 0
        self.dt = 0
        self.initialized = True
        self.reduce_factor = 0.9
        self.angle = 0
        self.time_passed_seconds = time_passed_seconds
        self.timing = timing_

    def scale_particle(self, image_, factor_):
        scale = (image_.get_width() - factor_,
                 (image_.get_height() - factor_))
        if scale <= (0, 0):
            self.kill()

        return pygame.transform.scale(image_, scale)

    def set_position(self, point):
        point.vector.x = randint(-10, 10) + self.rectangle_.midbottom[0]
        point.vector.y = self.rectangle_.midbottom[1]
        self.rect.center = (point.vector.x, point.vector.y)

    def update(self):

        if self.dt > self.timing:
            # Inverse logic
            if self.initialized:
                # Particle start to live
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
                # processing next image
                self.images_copy[self.index] = self.scale_particle(self.images_copy[self.index],
                                                                   round(self.index * self.reduce_factor))
                self.particles.vector.x += round(eval(self.equation) * 4)
                # changing sign to - if particles needs to go up
                self.particles.vector.y += round(self.speed.y)
                self.rect.center = (self.particles.vector.x +\
                                    round(self.index * self.reduce_factor), self.particles.vector.y)
                self.angle += round(2 * self.speed.y)
                if self.index < len(self.images) - 1:
                    self.index += 1
                else:
                    self.kill()

                # check screen boundaries
                if not SCREENRECT.contains(self.rect):
                    self.kill()

            self.dt = 0

        self.dt += self.time_passed_seconds

