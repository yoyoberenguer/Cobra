"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """

from ParticleFx import *
from Sprites import PHOTON_PARTICLE_1
from Weapons import WEAPON_ROTOZOOM, WEAPON_OFFSET_X
from Constants import SCREENRECT

class Shot(pygame.sprite.Sprite):

    containers = None

    def __init__(self, pos_, weapon_, mute_, offset_x, offset_y, timing_,
                 sc_spaceship, time_passed_seconds, All, layer_=-2):
        """
        :param pos_: tuple representing the space ship location (x,y)
        :param weapon_: Weapon class, define the weapon currently used by the player.
                        Weapon class is personalized and has specific attributes for each weapons type
                        e.g speed, power, sound effect and sprite link to it. See Weapons.py for more info
        :param mute_:   boolean. Determine if the sound is muted or not for the current shot (this is useful for
                        weapons that shot more than one particle at once).
        :param offset_x: integer, Offsetx from the center of the player rect
        :param offset_y: integer, Offsety from the center of the player rect (shot with offset from center like
                        multiple shots do)
        :param sc_spaceship: Mixer to used for playing sounds
        :param time_passed_seconds: Number of milli-seconds since the last frame  (time between frames)
        """

        """
        # REMOVED to gain few more ms
        assert isinstance(pos_, tuple), 'Argument <pos_> should be a tuple, got: ' \
                                        + str(type(pos_))
        assert isinstance(weapon_, Weapons), ' Expecting Weapon class got : %s ' % type(weapon_)
        assert isinstance(mute_, bool), ' Expecting boolean for argument mute_ got : %s ' % type(mute_)
        assert isinstance(offset_x, int), ' Expecting integer for argument offset_x got : %s ' % type(offset_x)
        assert isinstance(offset_y, int), ' Expecting integer for argument offset_y got : %s ' % type(offset_y)
        """
        pygame.sprite.Sprite.__init__(self, self.containers)

        if isinstance(All, pygame.sprite.LayeredUpdates):
            if layer_:
                All.change_layer(self, layer_)

        # Weapon
        self.weapon = weapon_

        self.images = weapon_.sprite.copy()
        self.image = self.images[0] if isinstance(self.images, list) else self.images

        self.speed = weapon_.velocity

        # projectile's offset from the center
        self.offset_x = offset_x
        self.offset_y = offset_y

        # Assign the offset
        self.pos = (pos_[0] + self.offset_x, self.offset_y)  # pos_[1])
        self.rect = self.image.get_rect(midbottom=self.pos)

        self.index = 0
        self.dt = 0
        self.timing = timing_
        self.time_passed_seconds = time_passed_seconds
        self.All = All



        if not mute_:
            # -------------- load sound effect ----------
            self.sound = self.weapon.sound_effect
            sc_spaceship.stop_name(weapon_.name)

            # stop the sound
            if len(sc_spaceship.get_identical_sounds(self.sound)):
                sc_spaceship.stop_name(self.weapon.name)

            self.channel = sc_spaceship.play(sound_=self.sound, loop_=False, priority_=0, volume_=self.weapon.volume,
                                             fade_out_ms=0, panning_=True, name_=self.weapon.name, x_=pos_[0],
                                             object_id_=id(self))
        else:
            self.channel = None

        particles = 0
        # ----------- Particles effect ---------------------------------
        # Particle effect for photon weapons,
        # distribute light particle(s) randomly along the super shot (photon)
        # No particle effect for (bullet, rocket)
        if weapon_.type_ != 'BULLET':
            ParticleFx.rectangle = self.rect
            if weapon_.units == 'SUPER':
                particles = randint(3, 5)

            ParticleFx.images = PHOTON_PARTICLE_1
            ParticleFx.screenrect = SCREENRECT
            for number_ in range(particles):
                ParticleFx(self.time_passed_seconds, 33, self.All, -2)

            # Rotate the sprite before
            # displaying it
            self.choose_image(self.image)
        else:
            # todo need to implement bullet
            pass

    def center(self):
        """ return the centre coordinate  """
        return self.rect.center

    def location(self):
        """ return a Rect """
        return self.rect

    def get_animation_index(self):
        return self.index

    def choose_image(self, surface_):
        """
        Rotate a sprite
        :param surface_: Sprite to rotate
        """
        self.image = eval(WEAPON_ROTOZOOM[self.offset_x])

    def move(self, speed_):
        """
        Move a sprite according to the offset
        from spaceship center.
        :param speed_: Shot speed
        """
        eval(WEAPON_OFFSET_X[self.offset_x])

    def update(self):
        if self.dt > self.timing:
            # Animation
            if isinstance(self.images, list):
                self.image = self.images[self.index]

            # Player spaceship debris
            if self.weapon.name == 'RED_DEBRIS_SINGLE':
                self.rect.center += self.speed * 2
                self.image = pygame.transform.rotozoom(self.images.copy(), self.index, 1)

            else:
                self.move(self.speed)

            if isinstance(self.images, list):
                if self.index < len(self.images) - 1:
                    self.index += 1
                else:
                    self.kill()

            if not self.rect.colliderect(SCREENRECT):
                self.kill()


            self.dt = 0

        self.dt += self.time_passed_seconds

