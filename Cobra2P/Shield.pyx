# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from BindSprite import BindSprite
from Sounds import WARNING
from Sprites cimport LayeredUpdates
from Sprites cimport Sprite


from pygame import BLEND_RGB_ADD, Color, Surface

from Tools cimport make_transparent32, blend_texture_32c, \
    blend_texture_24c
from PygameShader import create_horizontal_gradient_1d

COLOR_GRADIENT = create_horizontal_gradient_1d(63)
COLOR_GRADIENT_LENGTH = len(COLOR_GRADIENT)

cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;

try:
    cimport cython
    from cython.parallel cimport prange
    from cpython cimport PyObject_CallFunctionObjArgs, PyObject, \
        PyList_SetSlice, PyObject_HasAttr, PyObject_IsInstance, \
        PyObject_CallMethod, PyObject_CallObject
    from cpython.dict cimport PyDict_DelItem, PyDict_Clear, PyDict_GetItem, PyDict_SetItem, \
        PyDict_Values, PyDict_Keys, PyDict_Items
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size, PyList_SetItem
    from cpython.object cimport PyObject_SetAttr

except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")


SHIELD_IMPACT = False
_shield_up = {'1' : False, '2': False}
SHIELD_INVENTORY = []


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Shield(Sprite):

    cdef:
        public object player, follower, shield_specs, image, rect, layer_
        object containers, images_copy
        int index, timing, dt
        bint loop
        str event
        public long long int id

    def __init__(self,
                 containers_,
                 images_,
                 player_,
                 bint loop_    = False,
                 int timing_   = 16,
                 str event_    = None,
                 int layer_    = -1):


        global SHIELD_INVENTORY, SHIELD_IMPACT
        if id(player_) in SHIELD_INVENTORY:
            return

        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(player_.gl.All, LayeredUpdates):
            if layer_:
                player_.gl.All.change_layer(self, layer_)


        self.player = player_

        # Shield already busy?
        if SHIELD_IMPACT:
            # todo remove from inventory ?
            self.kill()

        # Link to class Follower
        self.follower = player_.follower

        # Link to the shield characteristics (e.g SHIELD_ACHILLES, SHIELD_ANCILE)
        self.shield_specs = player_.aircraft_specs.shield.__copy__()
        self.containers  = containers_
        self.images_copy = images_.copy()
        self.image       = self.images_copy[0]
        self.rect        = self.image.get_rect(center=self.player.rect.center)
        self.index       = 0
        self.loop        = loop_
        self.timing      = timing_
        self.dt          = 0
        self.event       = event_
        self._id         = id(self)
        self.layer_      = layer_

        # SPECIAL EVENT FOR SHIELD COLLISION
        if self.event == 'SHIELD_IMPACT':
            SHIELD_IMPACT = True

        # SHIELD UP
        elif self.event == 'SHIELD_INIT':
            self.shield_up()

    def __copy__(self):
        return Shield(containers_= self.containers,
                      images_    = self.images_copy,
                      player_    = self.player,
                      loop_      = self.loop,
                      timing_    = self.timing,
                      event_     = self.event,
                      layer_     = self.layer_)

    cdef void blinking(self):
        """
        CREATE A BLINKING EFFECT OF THE SURFACE
        
        :return: void
        """
        self.image=make_transparent32(self.image, self.player.visibility)

    cpdef bint is_shield_up(self):
        """
        RETURN TRUE WHEN THE SHIELD IS UP FALSE OTHERWISE 
        
        * self.player.p_ is the player number such as '1' or '2'
        * _shield_up is a dict such as {'1' : False, '2': False}
        
        :return: bool; True | False 
        """
        return _shield_up[self.player.p_]

    cpdef bint is_shield_operational(self):
        """
        RETURN TRUE WHEN THE SHIELD IS OPERATIONAL (NOT USED)
        :return: bool; True | False 
        
        """
        return self.shield_specs.operational_status

    cpdef bint is_shield_disrupted(self):
        """
        RETURN TRUE WHEN THE SHIELD IS DISRUPTED
        
        :return: bool; True | False
        """
        return self.shield_specs.disrupted

    cdef bint is_shield_overloaded(self):
        """
        RETURN TRUE WHEN THE SHIELD IS OVERLOADED
        
        :return: bool; Return True | False
        """
        return self.shield_specs.overloaded

    cpdef void shield_down(self, long long int id_sound):
        """
        SHIELD IS DOWN 
        
        * set _shield_up[self.player.p_] to False and operational_status to False
        * Play a sound to the mixer
        
        :param id_sound: integer; Sound id such as id(sound) 
        :return: void
        """

        mixer      = self.player.gl.SC_spaceship
        sound_down = self.shield_specs.shield_sound_down

        _shield_up[self.player.p_] = False

        mixer.stop_object(id_sound)

        if not mixer.get_identical_sounds(sound_down):
            mixer.play(sound_=sound_down, loop_=False, priority_=0,
                       volume_=self.player.gl.SOUND_LEVEL, fade_out_ms=0, panning_=False,
                       name_='FORCE_FIELD', x_=0, object_id_=id(sound_down))

        self.shield_specs.operational_status = False


    cpdef void shield_up(self):
        """
        SHIELD IS UP
        
        * The shield will not start if the energy level is too low, if 
        the shield is disrupted 
        
        :return: void
        """

        mixer        = self.player.gl.SC_spaceship
        shield_sound = self.shield_specs.shield_sound

        if self.player.alive() and self.shield_specs.energy > 0:

            if not self.shield_specs.disrupted:

                if not mixer.get_identical_sounds(shield_sound):
                    mixer.play(sound_=shield_sound, loop_=True, priority_=0,
                               volume_=self.player.gl.SOUND_LEVEL, fade_out_ms=0, panning_=False,
                               name_='FORCE_FIELD', x_=0, object_id_=id(shield_sound))

                _shield_up[self.player.p_] = True

    cpdef void apply_damage(self, int damage_):
        """
        SHIELD IS TAKING DAMAGE (SHIELD ENERGY - DAMAGE)
        
        * Damage must be > 0
        
        :param damage_: integer; Amount of damages
        :return: void
        """
        # CAP THE DAMAGE
        if damage_ < 0:
            damage_ = 0

        cdef int remaining = damage_ - self.shield_specs.energy

        self.shield_specs.energy -= damage_

        # SHIELD ENERGY IS DEPLETED
        # PLAY THE SOUND EFFECT OF THE SHIELD DOWN
        if self.shield_specs.energy <= 0:

            self.shield_down(id(self.shield_specs.shield_sound_down))

            # PASSING DAMAGE TO THE PLAYER ALSO
            if remaining > 0:
                self.player.aircraft_specs.life -= remaining


    cpdef void shield_impact(self, int damage_):
        """
        PLAY THE SHIELD IMPACT SOUND AND CALL THE METHOD apply_damage TO PASS 
        DAMAGES TO THE SHIELD. ADD A SPRITE EFFECT (DISRUPTION) TO THE SHIELD 
        WHEN CALLING BindSprite
        
        :param damage_: integer; Amount of damage 
        :return: void
        """

        mixer               = self.player.gl.SC_spaceship
        shield_sound_impact = self.shield_specs.shield_sound_impact

        # IF THE SHIELD IS UP
        if self.is_shield_up():

            mixer.stop_name('SHIELD_IMPACT')
            mixer.play(sound_           = shield_sound_impact,
                       loop_            = False,
                       priority_        = 0,
                       volume_          = self.player.gl.SOUND_LEVEL,
                       fade_out_ms      = 0,
                       panning_         = False,
                       name_            = 'SHIELD_IMPACT',
                       x_               = 0,
                       object_id_       = id(shield_sound_impact))

            self.apply_damage(damage_)

            # DISRUPTION EFFECT
            BindSprite(group_           = self.containers,
                       images_          = self.shield_specs.shield_disrupted_sprite,
                       object_          = self,
                       gl_              = self.player.gl,
                       offset_          = None,
                       timing_          = self.timing,
                       layer_           = self.layer_,
                       loop_            = False,
                       dependency_      = True,
                       follow_          = False,
                       event_           = 'BLURRY_WATER1',
                       blend_           = BLEND_RGB_ADD)


    cpdef heat_glow(self, rect_):
        """
        CREATE AN IMPACT EFFECT ON THE SHIELD
        
        :param rect_ : Rect; Pygame Rect, representing the surface rect
        :return:  void
        """

        impact_sprite           = Sprite()
        impact_sprite.images    = self.shield_specs.impact_sprite
        impact_sprite.image     = self.shield_specs.impact_sprite[0]
        impact_sprite.object    = self
        impact_sprite.offset    = (self.rect.centerx - rect_.centerx, self.rect.centery - rect_.centery)
        impact_sprite.rect      = impact_sprite.image.get_rect(center=rect_.center)
        impact_sprite._layer    = 0
        impact_sprite.index     = 0

        self.player.gl.VERTEX_IMPACT.append(impact_sprite)


    cdef gradient(self, int index_):
        """
        RETURN A SPECIFIC COLOR FROM A GRADIENT (GIVEN AN INDEX VALUE)
        
        :param index_: integer; index value in the gradient array  
        :return: 
        """
        if index_ > COLOR_GRADIENT_LENGTH:
            index_ = COLOR_GRADIENT_LENGTH - 1
        if index_ < 0:
            index_ = 0
        return COLOR_GRADIENT[index_]


    cdef void shield_electric_arc(self):
        """
        CREATE AN ELECTRIC ARC EFFECT WITHIN THE SHIELD 
        
        :return: void 
        """
        BindSprite(group_=self.containers, images_=self.shield_specs.shield_electric, object_=self, gl_=self.player.gl,
                   offset_=None, timing_=self.timing,
                   layer_=self.layer_, loop_=False, dependency_=True,
                   follow_=False, event_='SHIELD_ELECTRIC', blend_=BLEND_RGB_ADD)

    cdef shield_glow(self):
        """    
        CREATE A GLOWING/HALO EFFECT WITHIN THE SHIELD WHEN 
        AN ELECTRIC ARC
        
        :return: 
        """

        impact_sprite           = Sprite()
        impact_sprite.images    = self.shield_specs.shield_glow_sprite
        impact_sprite.image     = self.shield_specs.shield_glow_sprite[0]
        impact_sprite.object    = self
        impact_sprite.offset    = None
        impact_sprite.rect      = impact_sprite.image.get_rect(center=self.rect.center)
        impact_sprite._layer    = 0
        impact_sprite.index     = 0
        impact_sprite._blend    = BLEND_RGB_ADD

        self.player.gl.VERTEX_IMPACT.append(impact_sprite)

    cdef shield_power_indicator(self, surface_):

        surface_blit = surface_.blit
        shield_specs = self.shield_specs
        surface_rect = surface_.get_rect(center=self.player.rect.center)
        cdef int x = <int>(surface_rect.w - shield_specs.sbi.get_width()) >> 1
        cdef tuple r = (x, surface_rect.h - shield_specs.sbi.get_height())
        cdef tuple rr
        PyObject_CallFunctionObjArgs(
            surface_blit,
            <PyObject*> shield_specs.sbi,
            <PyObject*> r,
            <PyObject*> None,
            <PyObject*> 0,
            NULL)

        smi_ = shield_specs.smi

        if shield_specs.ratio > 0:

            if smi_.get_size() > (1, 1):
                grad = self.gradient(<int>(shield_specs.ratio - 1))
                color_ = Color(<int>grad[0], <int>grad[1], <int>grad[2])

                if smi_.get_bitsize() == 32:
                    smi_ = blend_texture_32c(smi_, color_, 100)

                elif smi_.get_bitsize() == 24:
                    smi_ = blend_texture_24c(smi_, color_, 100)
                else:
                    print('\nShield Texture with 8-bit depth color cannot be blended.')
                    return Surface(10, 10)

                r = (x + 2, surface_rect.h - shield_specs.sbi.get_height() + 2)
                rr = (0, 0, <int>shield_specs.ratio, smi_.get_height())
                PyObject_CallFunctionObjArgs(
                    surface_blit,
                    <PyObject*> smi_,
                    <PyObject*> r,
                    <PyObject*> rr,
                    <PyObject*> 0,
                    NULL)

        return surface_

    cdef quit(self):

        global SHIELD_INVENTORY, SHIELD_IMPACT
        SHIELD_IMPACT = False

        if self.event == 'SHIELD_INIT':
            self.shield_down(id(self.shield_specs.shield_sound))

        for instance_ in SHIELD_INVENTORY:
            if PyObject_IsInstance(instance_, self.follower) \
                    and PyObject_HasAttr(instance_, 'kill_instance'):
                instance_.kill_instance(instance_)

        SHIELD_INVENTORY = []

        self.kill()


    cdef void shield_recharge(self):
        """
        SHIELD RECHARGING 
        
        :return: void  
        """

        if not (self.is_shield_disrupted() or self.is_shield_overloaded()):
            self.shield_specs.energy += self.shield_specs.recharge_speed

    cpdef update(self, args=None):

        cdef int index = self.index

        if _shield_up[self.player.p_]:

            if self.dt > self.timing:

                if self.player.alive():

                    if self.event == 'SHIELD_INIT':
                        self.image = self.shield_power_indicator(self.images_copy[index])
                    else:
                        self.image = <object>PyList_GetItem(self.images_copy, index)

                    self.rect = self.image.get_rect()
                    self.rect.center = self.player.rect.center

                    index += 1

                    if index > (PyList_Size(self.images_copy) - <unsigned char>1):
                        if self.loop:
                            index = 0
                        else:
                            self.quit()

                    self.dt = 0
                    # Restore the shield
                    self.shield_recharge()

                    if randRange(0, 1000) > 999:
                        self.shield_electric_arc()
                        self.shield_glow()

                    if self.player.invincible:
                        self.blinking()
                else:
                    self.quit()

            self.index = index
            self.dt += self.player.gl.TIME_PASSED_SECONDS

        else:
            self.quit()
