# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from Shot import Shot
from Sprites cimport Sprite
from Sprites cimport LayeredUpdates

from pygame.math import Vector2
from pygame import BLEND_RGBA_ADD, BLEND_RGB_ADD

from Tools cimport make_transparent32

from Textures import TURRET_SHARK
from Weapons import LZRFX109
from SuperLaser_cython import super_laser_improved

from libc.math cimport cos, sin, atan2

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

# TODO CREATE DOC
# TODO CREATE PACKING TURRET AND UNPACKING



@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class WingTurret(Sprite):
    cdef:
        int _layer
        public object image, rect, images_copy
        public magnitude, position, gl, player, weapon_beam, instance
        int index, visibility, visibility_steps
        int dt, timing
        tuple offset
        bint deployed, status
        str name


    def __init__(self,
                 containers_,
                 images_,
                 player_,
                 str name_,
                 offset_,
                 int timing_ = 15,
                 int layer_  = -1):

        self._layer = layer_
        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(player_.gl.All, LayeredUpdates):
            player_.gl.All.change_layer(self, layer_)
        self.image          = images_[0] if PyObject_IsInstance(images_, list) else images_
        self.images_copy    = images_.copy()
        self.rect           = self.image.get_rect(midbottom=(player_.rect.centerx + offset_[0],
                                                   player_.rect.centery + offset_[1]))

        # Speed of the wing turret
        self.magnitude      = Vector2(<float>8.0, <float>8.0).length()
        self.position       = Vector2(player_.rect.centerx + offset_[0],
                                            player_.rect.centery + offset_[1])
        self.gl             = player_.gl

        self.index          = 0
        self.dt             = 0
        self.timing         = timing_

        self.offset         = offset_
        # 0 packed, 1 deployed
        self.deployed       = False
        # 0 not ready, 1 ready
        self.status         = False
        self.player         = player_
        self.instance       = None
        self.name           = name_
        self.weapon_beam    = self.player.aircraft_specs.beam[0].__copy__()
        self.laser          = LZRFX109.__copy__()
        self.visibility     = 255
        self.visibility_steps = -10

    cdef bint is_super_laser_shooting(self):
        if self.instance is not None:
            if self.instance.alive():
                return True
            else:
                return False
        else:
            return False

    cdef void super_laser(self):


        if not self.weapon_beam.weapon_reloading_std(self.gl.FRAME):
            # TURRET FULLY DEPLOYED ? AND NOT SHOOTING?
            if self.deployed and not self.is_super_laser_shooting():

                super_laser_, shaft, burst = self.player.aircraft_specs.beam

                # CREATE A FOLLOWER AND ASSIGN A VARIABLE TO PASS IT TO THE CLASS SUPER LASER

                if hasattr(self.player, 'follower'):

                    # self.player.follower.images_copy = shaft
                    # self.player.follower.image = shaft[0]


                    super_laser_instance_ = \
                        self.player.follower(
                            gl_         = self.gl,
                            containers_ = self.gl.All,
                            images_     = shaft,
                            offset_     = self.rect.center,
                            timing_     = 0, # self.timing,
                            loop_       = True,
                            event_      = 'SHAFT LIGHT'+str(self.name),
                            object_     = self,
                            layer_      = -1,
                            vector_     = None,
                            blend_      = BLEND_RGBA_ADD

                            )

                    self.instance = \
                        super_laser_improved(
                            gl_                = self.gl,
                            player_            = self.player,
                            follower_instance_ = super_laser_instance_,
                            super_laser_       = self.weapon_beam,
                            surface_           = self.weapon_beam.sprite,
                            turret_            = self,
                            mute_              = False,
                            layer_             = -2)

    cdef void laser_shot(self):

        if self.laser.shooting or self.player.aircraft_specs.energy < self.laser.energy:
            return

        # timestamp for the reloading time
        self.laser.elapsed  = self.gl.FRAME
        self.laser.shooting = True

        s = Shot(group_         = (self.gl.shots, self.gl.All),
                 pos_           = self.rect.midtop,
                 current_weapon_= self.laser,
                 player_        = self.player,
                 mute_          = False,
                 offset_        = (0, self.rect.midtop[1] - 20),
                 timing_        = self.timing,
                 gl_            = self.gl,
                 layer_         = -2)
        s._blend = BLEND_RGB_ADD
        # remove energy
        self.player.aircraft_specs.energy -= self.laser.energy

    cdef void laser_shot_is_reloading(self, int frame_):

        cdef laser = self.laser

        if laser is not None:
            # check if the reloading time is over
            if laser.reloading * self.gl.MAXFPS < frame_ - laser.elapsed:
                # ready to shoot again
                laser.shooting = False
                laser.elapsed = 0
            else:
                laser.shooting = True
        self.laser = laser

    cdef void blinking(self):
        self.image = make_transparent32(self.image, self.visibility)

    cdef void deployment(self):
        ...

    cdef void packed(self):
        ...

    cdef void quit(self):
        self.kill()

    cdef rotate_turret(self):
        pass

    cdef trajectory(self):
        cdef float dx = (self.player.rect.centerx + self.offset[0]) - self.rect.centerx
        cdef float dy = (self.player.rect.centery + self.offset[1]) - self.rect.centery
        cdef float angle_rad

        diff = Vector2(dx, dy)
        if diff.length() > 8:
            angle_rad = <float>atan2(dy, dx)
            return Vector2(<float>cos(angle_rad) * self.magnitude,
                           <float>sin(angle_rad) * self.magnitude)
        else:
            return Vector2(<float>0.0, <float>0.0)

    cpdef update(self, args=None):

        cdef unsigned char visibility = self.visibility
        cdef char visibility_steps    = self.visibility_steps

        if self.dt > self.timing:

            if self.player.alive():

                if PyObject_IsInstance(self.images_copy, list):

                    self.image = self.images_copy[self.index]
                    if self.index > len(self.images_copy) - 2:
                        self.index = 0
                        if not self.deployed:
                            self.status      = True
                            self.deployed    = True
                            self.images_copy = TURRET_SHARK.copy()
                    else:
                        self.index += 1

                self.position   += self.trajectory()
                self.rect.center = (<int>self.position.x, <int>self.position.y)

                # 0 : not ready, 1 ready
                if self.status:
                    # check if the player pressed the key
                    if self.player.super_laser_bool:
                        self.super_laser()
                        ...
                    # Automatic laser
                    if not self.player.invincible:
                        self.laser_shot_is_reloading(self.gl.FRAME)
                        self.laser_shot()

                if self.player.invincible:
                    self.blinking()

                    visibility += visibility_steps
                    if visibility < 0:
                        visibility = 0
                        visibility_steps *= -1
                    elif visibility > 255:
                        visibility = 255
                        visibility_steps *= -1

            else:
                self.quit()

            self.dt = 0
            self.visibility       = visibility
            self.visibility_steps = visibility_steps

        self.dt += self.gl.TIME_PASSED_SECONDS

