
import pygame
from surface import blend_texture
import os
from Constants import GAMEPATH

class DamageDisplay(pygame.sprite.Sprite):
    images = []
    containers = None
    inventory = []

    def __new__(cls, object_, damages_: int, time_passed_seconds: int,
                event_= None, timing_=33, *args, **kwargs):
        # return if an instance already exist.
        if object_ in DamageDisplay.inventory:
            return
        else:
            return super().__new__(cls, *args, **kwargs)

    def __init__(self, object_, damages_: int, time_passed_seconds: int, event_= None, timing_=33):
        """
        Display the amount of damage(s)inflicted by projectiles
        :param object_: Object Class passed as an argument, this could be an Asteroid, Enemy class or any
                        other class that can takes player damages.
                        None type passed as an argument will trigger the GAME OVER message
        :param damages_: Integer showing amount of damages.
        :param event_ : String, flag used for catching special events
        """
        """
        assert isinstance(object_, (Asteroid, type(None), Enemy)), \
            '\n[-] Error : Expecting class Asteroid, Enemy for argument object_ got: %s ' % type(object_)
        assert isinstance(damages_, int), \
            '\n[-] Error : Expecting an integer for argument damages_ got: %s ' % type(damages_)
        assert isinstance(event_, (str, type(None))), '\n[-] Error : Expecting ' \
                                                      'a string or NoneType  for ' \
                                                      'argument event_ integer got: %s ' % type(damages_)
        """

        DamageDisplay.inventory.append(object_)

        pygame.sprite.Sprite.__init__(self, self.containers)

        # color for damages
        self.high_damage = pygame.Color('red')
        self.medium_damage = pygame.Color('yellow')
        self.low_damage = pygame.Color('white')

        self.damages = damages_

        # Choose a color corresponding
        # to the amount of damages.
        if self.damages > 200:
            self.color = self.high_damage
            # interval is used for blending the object surface to red.
            # the less interval, the brighter red the surface will be.
            # 0.5 here means 2 intervals
            self.interval = 0.5
        elif 200 > self.damages > 100:
            self.color = self.medium_damage
            # 3 intervals
            self.interval = 0.34
        else:
            self.color = self.low_damage
            # 5 intervals
            self.interval = 0.2

        self.image = self.images[0]
        self.object = object_

        self.event = event_

        # Initialised the Rect oustise of the visible area
        self.rect = self.image.get_rect(center=(-100, -100))
        self.index = 0
        self.frame = 0
        self.dt = 0
        self.timing = timing_
        self.time_passed_seconds = time_passed_seconds

        # Experience bonus preparations
        # Antialias is enable.
        if self.event == 'EXP':
            self.font = pygame.font.SysFont("arial", 10, 'normal')
            self.image = self.font.render(str('+') + str(self.damages / 10), True, (5, 220, 12))
            self.image = pygame.transform.scale2x(self.image)
        # Damage display preparations.
        # Using arial font size 7 with antialias.
        # Antialias option will determine the type of surface used.
        # If antialiasing is not used, the return image will always be
        # an 8-bit image with a two-color palette.
        # Antialiased images are rendered to 24-bit RGB images.
        # If the background is transparent a pixel alpha will be included.
        else:
            self.font = pygame.font.SysFont("calibri", 11, 'bold')
            if self.image.get_bitsize() is not 8:
                self.image = self.font.render(str(self.damages), True, self.color)
            else:
                self.image = self.font.render(str(self.damages), False, self.color)

    def get_animation_index(self):
        return self.index

    def quit(self):

        if self.object in DamageDisplay.inventory:
            DamageDisplay.inventory.remove(self.object)
        self.kill()

    def update(self):

        if self.dt > self.timing:
            # Display the experience gained
            if self.event == 'EXP':
                self.rect.center = (self.object.location().midtop[0] + 10, self.object.location().midtop[1])
                if self.object.image.get_bitsize() == 32:
                    self.image = blend_texture(self.image, 0.1, (0, 0, 0))

                if self.index > 8:
                    # todo need to apply the experience to the player
                    # SHIP_SPECS.experience += self.damages / 10
                    self.quit()
            # display damages
            else:
                if self.object:

                    # self.image = pygame.transform.scale(self.image,
                    #                                    (round(self.image.get_width() * 1.05),
                    #                                     round(self.image.get_height() * 1.05)))
                    self.rect.center = self.object.location().midright
                    if self.index > 8:
                        self.quit()
                # Display combo messages
                # on the right side of the
                # screen (Aggressive, Fury etc).
                else:
                    font_ = pygame.font.Font('Assets\\Fonts\\ARCADE_R.ttf', 18)
                    # font_ = pygame.font.SysFont("comicsansms", 18)
                    self.image = font_.render(str(self.event), True, (255, 255, 0))
                    self.image = pygame.transform.smoothscale(self.image,
                                                              (round(self.image.get_width() + self.index * 4),
                                                               round(self.image.get_height() + self.index * 4)))
                    self.rect.center = (10, 150)

                    if self.index > 12:
                        self.quit()

            self.index += 1
            self.dt = 0

        self.frame += 1
        self.dt += self.time_passed_seconds