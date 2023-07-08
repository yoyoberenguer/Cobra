# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


from BindSprite import BindSprite
from Follower import Follower
from Sounds import  NANOBOTS_SOUND
from Textures import SHIELD_DISTUPTION_1
from Tools cimport blend_texture_32c, blend_texture_24c
from PygameShader import create_horizontal_gradient_1d
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray, linspace
except ImportError:
    raise ImportError("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")


# CYTHON IS REQUIRED
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

# CYTHON IS REQUIRED
try:
    cimport cython
    from cython.parallel cimport prange
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

from pygame.locals import K_PAUSE
# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, gfxdraw, \
        BLEND_RGB_ADD, BLEND_RGB_SUB, freetype, \
    SWSURFACE, RESIZABLE, FULLSCREEN, HWSURFACE
    from pygame.freetype import STYLE_NORMAL
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d
    from pygame.image import frombuffer
    from pygame import Rect
    from pygame.time import get_ticks
    from operator import truth
    from pygame.draw import aaline
    from pygame.math import Vector2
    from pygame.transform import scale, smoothscale, rotozoom

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

from Sprites cimport Sprite, LayeredUpdates
from Sprites import Group

import time

cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;

COLOR_GRADIENT = create_horizontal_gradient_1d(63)

cdef list SHIELD_INVENTORY = []


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class EnemyShield(Sprite):

    cdef:
        public int _layer, _blend
        public shield_type
        public object image, rect
        int index, loop, timing, dt, counter,  disruption_timer
        str event
        long long int _id
        public bint impact, _shield_up
        object gl, object_, containers, images_copy, instance_disruption

    def __init__(self, gl_, containers_, images_, object_, bint loop_=False, int timing_=1,
                 str event_=None, shield_type=None, int layer_=-4):

        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self._layer             = layer_
        self.object_            = object_
        self.shield_type        = shield_type
        self.images_copy        = images_.copy()
        self.image              = <object>PyList_GetItem(self.images_copy, 0) if \
            PyObject_IsInstance(self.images_copy, list) else self.images_copy
        self.rect               = self.image.get_rect(center=object_.rect.center)
        self.index              = 0
        self.loop               = loop_
        self.timing             = timing_
        self.dt                 = 0
        self.event              = event_
        self._id                = id(self)
        self.counter            = 0
        self.disruption_timer   = 0
        self.instance_disruption = None
        self.impact             = False
        self._shield_up         = False
        self.gl                 = gl_
        self.containers         = containers_

        if self.event == 'SHIELD_IMPACT':
            self._shield_up = True
            self.impact     = True

        elif self.event == 'SHIELD_INIT':
            self.shield_up()

        SHIELD_INVENTORY.append(self)

    cpdef bint is_shield_up(self):
        return self._shield_up

    cpdef bint is_shield_operational(self):
        return self.shield_type.operational_status

    cpdef bint is_shield_disrupted(self):
        return self.shield_type.disrupted

    cpdef int is_shield_overloaded(self):
        return self.shield_type.overloaded

    cdef void shield_down(self, long long int id_sound):
        gl                = self.gl
        mixer_stop_object = gl.SC_spaceship.stop_object
        shield_down       = self.shield_type.shield_sound_down

        if id_sound is not None:
            mixer_stop_object(id_sound)
            mixer_stop_object(id(shield_down))

        if not gl.SC_spaceship.get_identical_sounds(shield_down):
            gl.SC_spaceship.play(sound_=shield_down, loop_=False, priority_=0,
                                 volume_=gl.SOUND_LEVEL, fade_out_ms=0, panning_=False,
                                 name_='SHIELD_DOWN', x_=0, object_id_=id(shield_down))
        self.shield_type.operational_status = False
        self._shield_up = False

    cdef void shield_up(self):

        gl          = self.gl
        mixer       = gl.SC_spaceship
        shield_sound = self.shield_type.shield_sound

        if self.object_.alive() and self.shield_type.energy > 0:

            if not self.shield_type.disrupted:

                mixer.stop_object(id(NANOBOTS_SOUND))
                mixer.stop_object(id(shield_sound))
                if not mixer.get_identical_sounds(shield_sound):
                    mixer.play(sound_=shield_sound, loop_=True, priority_=0,
                               volume_=self.gl.SOUND_LEVEL, fade_out_ms=0, panning_=False,
                               name_='FORCE_FIELD', x_=0, object_id_=id(shield_sound))

                self._shield_up = True
                self.shield_type.operational_status = True

    cpdef void shield_impact(self, int damage_):

        if damage_ < 0:
            damage = 0

        gl          = self.gl
        mixer       = self.gl.SC_spaceship
        shield_type = self.shield_type
        energy      = shield_type.energy

        if not self.is_shield_disrupted():

            mixer.stop_name(shield_type.name)
            mixer.play(sound_=shield_type.shield_sound_impact, loop_=False, priority_=0,
                       volume_=gl.SOUND_LEVEL, fade_out_ms=0, panning_=True,
                       name_=shield_type.name, x_=self.rect.centerx,
                       object_id_=id(shield_type.shield_sound_impact))

            # DAMAGE TO THE HULL IF DAMAGE > ENERGY
            if damage_ > energy:
                self.object_.hp -= (damage_ - energy)
                energy = 0
                self.shield_down(id_sound=id(shield_type.shield_sound))

            # DAMAGE ABSORBED BY THE SHIELD
            else:
                energy -= damage_
                if energy <= 0:
                    self.shield_down(id_sound=id(shield_type.shield_sound))

        self.shield_type.energy = energy

    @staticmethod
    def hit_shield(gl_, shield_, projectile_rect, int damage_):

        mixer  = gl_.SC_spaceship
        sound  = shield_.shield_type.shield_sound_impact
        energy = shield_.shield_type.energy
        cdef long long int shield_sound = id(shield_.shield_type.shield_sound)

        if not shield_.is_shield_disrupted():
            mixer.stop_name(shield_.shield_type.name)
            mixer.play(sound_=sound, loop_=False, priority_=0,
                       volume_=gl_.SOUND_LEVEL, fade_out_ms=0, panning_=True,
                       name_=shield_.shield_type.name, x_=shield_.rect.centerx,
                       object_id_=id(sound))

            if damage_ > energy:
                shield_.object_.hp -= (damage_ - energy)
                energy = 0

                shield_.shield_down(id_sound=shield_sound)

            else:
                energy -= damage_
                if energy <= 0:

                    shield_.shield_down(id_sound=shield_sound)
                shield_.heat_glow(projectile_rect)

            shield_.shield_type.energy = energy

    cpdef void heat_glow(self, rect_):

        if not self.is_shield_disrupted():

            Follower(self.gl, self.gl.All, self.shield_type.impact_sprite, offset_=rect_.center,
                     timing_=1, loop_=False, event_='SHIELD HEAT GLOW', object_=self.object_,
                     layer_=-3, blend_=BLEND_RGB_ADD)


    cdef gradient(self, int index_):
        return COLOR_GRADIENT[index_]

    cdef void shield_electric_arc(self):
        BindSprite(group_=self.containers, images_=self.shield_type.shield_electric, object_=self, gl_=self.gl,
                   offset_=None, timing_=self.timing, layer_=self._layer, loop_=False, dependency_=True,
                   follow_=False, event_='SHIELD_ELECTRIC', blend_=BLEND_RGB_ADD)

    cdef void shield_glow(self, int speed_=1):
        Follower(self.gl, self.gl.All, self.shield_type.shield_glow_sprite, offset_=self.rect.center,
                 timing_=speed_, loop_=False, object_=self.object_, layer_=-3, event_='SHIELD_GLOW',
                 blend_=0)

    cdef shield_power_indicator(self, surface_):

        surface_blit = surface_.blit
        shield_type  = self.shield_type

        surface_rect = surface_.get_rect(center=self.object_.rect.center)

        cdef int x = int(surface_rect.w - shield_type.sbi.get_width()) >> 1

        cdef tuple r = (x, shield_type.sbi.get_height())
        cdef tuple rr

        PyObject_CallFunctionObjArgs(
            surface_blit,
            <PyObject*> shield_type.sbi,
            <PyObject*> r,
            <PyObject*> None,
            <PyObject*> 0,
            NULL)

        smi_ = shield_type.smi

        if shield_type.ratio > 0:

            if smi_.get_size() > (1, 1):

                grad = self.gradient(<int> (shield_type.ratio - 1))
                color_ = Color(<int> grad[0], <int> grad[1], <int> grad[2])


                if smi_.get_bitsize() == 32:
                    smi_ = blend_texture_32c(smi_, color_, 100)

                elif smi_.get_bitsize() == 24:
                    smi_ = blend_texture_24c(smi_, color_, 100)
                else:
                    print('\nEnemy shield Texture with 8-bit depth color cannot be blended.')
                    return Surface(10, 10)

                r = (x, shield_type.sbi.get_height() + 2)
                rr = (0, 0, <int> shield_type.ratio, smi_.get_height())
                PyObject_CallFunctionObjArgs(
                    surface_blit,
                    <PyObject*> smi_,
                    <PyObject*> r,
                    <PyObject*> rr,
                    <PyObject*> 0,
                    NULL)

        return surface_

    cdef void quit(self):

        self.impact = False

        if self.event == 'SHIELD_INIT':
            self.shield_down(id(self.shield_type.shield_sound_down))
            self.gl.SC_spaceship.stop_object(id(NANOBOTS_SOUND))

        self.kill()

    cdef void shield_recharge(self):

        if self.shield_type.operational_status:
            self.shield_type.energy += self.shield_type.recharge_speed

    cpdef void force_shield_disruption(self):

        mixer = self.gl.SC_spaceship

        self.index                 = 0
        self.images_copy           = SHIELD_DISTUPTION_1.copy()
        self.shield_type.disrupted = True

        self.shield_down(id_sound=id(self.shield_type.shield_sound))

        if not mixer.get_identical_sounds(NANOBOTS_SOUND):
            mixer.play(sound_=NANOBOTS_SOUND, loop_=True, priority_=0,
                       volume_=self.gl.SOUND_LEVEL, fade_out_ms=0, panning_=True,
                       name_='SHIELD_DISTUPTED', x_=self.rect.centerx,
                       object_id_=id(NANOBOTS_SOUND))

        self.disruption_timer = time.time()
        self._blend = True

    # todo FRAME ?
    cdef bint disruption_time_over(self):

        instance = self.instance_disruption

        if (time.time() - self.disruption_timer) > self.shield_type.disruption_time / 1000.0:

            self.shield_type.operational_status = True
            self.shield_type.disrupted          = False
            self.index                          = 0
            self.images_copy                    = self.shield_type.sprite.copy()
            self._blend = False
            if instance is not None:
                instance.kill_instance(instance)

            self.instance_disruption = None
            return True
        else:

            return False

    cpdef void disruption_effect(self):

        if self.instance_disruption is None:

            self.instance_disruption = \
                BindSprite(group_=self.containers, images_=self.shield_type.shield_disrupted_sprite,
                           object_=self, gl_=self.gl, offset_=None, timing_=self.timing,
                           layer_=self._layer,
                           loop_=True, dependency_=True, follow_=False, event_='BLURRY_WATER2',
                           blend_=BLEND_RGB_ADD)

    cpdef update(self, args=None):

        object_     = self.object_
        gl          = self.gl
        images_copy = self.images_copy

        cdef:
            int index   = self.index

        if object_.alive() and object_ in gl.enemy_group \
                and object_.rect.top < gl.screenrect.bottom:

            if self.dt > self.timing:

                if self._shield_up:

                    # check if the shield is disrupted
                    if not self.shield_type.disrupted:

                        # Restore the shield energy
                        # only is shield operational deployed is True
                        self.shield_recharge()

                        if self.event == 'SHIELD_INIT':
                            if PyObject_IsInstance(images_copy, list):
                                self.image = self.shield_power_indicator(
                                    (<object>PyList_GetItem(images_copy, index)).copy())
                            else:
                                self.image = self.shield_power_indicator(images_copy.copy())
                        else:
                            self.image = (<object>PyList_GetItem(images_copy, index)).copy()

                        if randRange(0, 1000) > 998:
                            self.shield_electric_arc()
                            self.shield_glow(speed_=self.timing)

                        self.rect = self.image.get_rect()
                        self.rect.center = object_.rect.center

                        if PyObject_IsInstance(images_copy, list):
                            index += 1

                            if index > len(images_copy) - 1:
                                if self.loop:
                                    index = 0
                                else:
                                    self.quit()

                # shield down
                else:

                    if self.shield_type.energy > 0:
                        if PyObject_IsInstance(images_copy, list):
                            self.image = <object>PyList_GetItem(images_copy, index)

                        self.rect = self.image.get_rect()
                        self.rect.center = object_.rect.center

                        if self.shield_type.disrupted:
                            self.disruption_effect()

                        if PyObject_IsInstance(images_copy, list):
                            index += 1

                            if index > len(images_copy) - 1:
                                if self.loop:
                                    index = 0
                                else:
                                    self.quit()
                    # energy <0
                    else:
                        self.quit()

                    if self.disruption_time_over():
                        self.shield_up()

                self.dt     = 0
                self.index  = index

            self.dt += gl.TIME_PASSED_SECONDS
            self.counter += 1

        # alive?
        else:
            self.quit()