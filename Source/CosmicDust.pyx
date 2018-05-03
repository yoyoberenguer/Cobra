import pygame
from random import choice, randint
from surface import blink_surface


class ERROR(BaseException):
    pass


class CosmicDust(pygame.sprite.Sprite):
    """ Create blinking cosmic dust effect on the background """
    images = []
    dust = []
    containers = None

    def __init__(self, joystick, joystick_axis_1, directions, screenrect, time_passed_seconds, timing, All):
        pygame.sprite.Sprite.__init__(self, self.containers)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            All.change_layer(self, -1)


        self.images_copy = self.images.copy()
        self.image = self.images_copy[0]
        self.rect = self.image.get_rect(midtop=(randint(0, screenrect.w), -10))
        self.vector = pygame.math.Vector2()
        self.stars = choice([True, False])
        if self.stars:
            self.speed = pygame.math.Vector2()
            self.speed.x = 0
            self.speed.y = randint(10, 15)
        else:
            self.speed = pygame.math.Vector2()
            self.speed.x = 0
            self.speed.y = randint(15, 25)
        self.dt = 0
        self.time_passed_seconds = time_passed_seconds
        self.screenrect = screenrect
        self.directions = directions
        self.joystick = joystick
        self.joystick_axis_1 = joystick_axis_1
        self.timing = timing
        CosmicDust.dust.append(self)

    def blinking(self):
        array_ = pygame.surfarray.pixels3d(self.image)
        if self.image.get_bitsize() is 32:
            alpha_ = pygame.surfarray.pixels_alpha(self.image)
        elif self.image.get_bitsize() is 24:
            alpha_ = pygame.surfarray.array_alpha(self.image)
        else:
            raise ERROR('\n[-]blinking method works only for 32-24 bit surface, got %s'
                        % self.image.get_bitsize())
        self.image = blink_surface(array_, alpha_, 5)

    def update(self):
        if self.dt > self.timing:
            if not self.stars:
                self.vector = self.directions * 2
                if self.joystick.availability and self.directions == (0, 0):
                    self.vector = self.joystick_axis_1 * 2
            else:
                self.blinking()
            self.rect.move_ip(self.speed + self.vector)
            self.vector = pygame.math.Vector2()
            if self.rect.top >= self.screenrect.h:
                if self in CosmicDust.dust:
                    CosmicDust.dust.remove(self)
                self.kill()
            self.dt = 0
        self.dt += self.time_passed_seconds