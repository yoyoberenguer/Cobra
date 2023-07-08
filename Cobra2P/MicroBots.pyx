# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

from Sounds import NANOBOTS_SOUND
from Sprites cimport Sprite
from Sprites cimport LayeredUpdates
from pygame.transform import rotozoom


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


cdef list BOTS_INVENTORY = []
BOTS_INVENTORY_REMOVE = BOTS_INVENTORY.remove
BOTS_INVENTORY_APPEND = BOTS_INVENTORY.append


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class MicroBots(Sprite):

    cdef:
        public object player, image, rect
        object images_copy, org_player_life, gl
        float timing, dt
        int index, counter


    def __init__(self, containers_, images_, player_, gl_, float timing_=16.67, int layer_=-1):

        if id(player_) in BOTS_INVENTORY:
            return

        # no more micro-bots ?
        if player_.aircraft_specs.microbots_quantity <= 0:
            return

        # player hp does not require micro-bots?
        if player_.aircraft_specs.life >= player_.aircraft_specs.max_health:
            return

        Sprite.__init__(self, containers_)

        if layer_:
            if PyObject_IsInstance(gl_.All, LayeredUpdates):
                gl_.All.change_layer(self, layer_)

        self.player         = player_
        self.images_copy    = images_.copy()
        self.image          = <object>PyList_GetItem(self.images_copy, 0) if PyObject_IsInstance(
            self.images_copy, list) else self.images_copy
        self.rect           = self.image.get_rect(center=player_.rect.center)
        self.index          = 0
        self.counter        = 0
        self.dt             = 0
        self.timing         = timing_

        self.org_player_life = gl_.player.aircraft_specs.life

        if not gl_.SC_spaceship.get_identical_sounds(NANOBOTS_SOUND):
            gl_.SC_spaceship.play(sound_=NANOBOTS_SOUND, loop_=True, priority_=0,
                                 volume_=gl_.SOUND_LEVEL, fade_out_ms=0, panning_=True,
                                 name_='NANO_BOTS_CLOUD', x_=self.rect.centerx,
                                 object_id_=id(NANOBOTS_SOUND))
        self.gl = gl_
        # store the id into the inventory
        BOTS_INVENTORY_APPEND(id(self.player))

    cdef stop_mixer(self):#
        mixer = self.gl.SC_spaceship
        # CHECK IF THE ELECTRICAL SOUND IS ON, IF YES, KILL IT.
        if mixer.get_identical_sounds(NANOBOTS_SOUND):
            mixer.stop_object(id(NANOBOTS_SOUND))

    cdef update_systems(self):
        system_status = self.player.aircraft_specs.status

        # UPDATE ALL THE SYSTEMS WITH 25hp
        for system, integrity in system_status.items():
            # e.g ('LW', (True, 100)) : system = 'LW' and integrity = (True, 100)
            system_status[system] = (True, integrity[1] + 25) \
                if integrity[1] + 25 <= 100 else (True, 100)

    cdef void quit(self):
        self.stop_mixer()
        if id(self.player) in BOTS_INVENTORY:
            BOTS_INVENTORY_REMOVE(id(self.player))
        self.kill()

    cpdef update(self, args=None):

        cdef specs = self.player.aircraft_specs

        if self.dt > self.timing:

            if self.player.alive():

                self.image = <object>PyList_GetItem(self.images_copy, self.index)
                self.index += 1

                # REPAIRING HP_PER_FRAME
                specs.life += specs.microbots.hp_per_frame

                # CHECK IF REPAIR IS COMPLETE.
                if specs.life - self.org_player_life >= specs.microbots.max_hp_restoration:
                    specs.microbots_quantity -= 1
                    self.update_systems()
                    self.quit()

                if self.index > PyList_Size(self.images_copy) - 1:
                    self.index = 0

                # IS PLAYER AT MAX_HEALTH?
                if specs.life >= specs.max_health:
                    self.update_systems()
                    self.quit()

                self.rect.center = self.player.rect.center
                self.counter += 1

            else:
                self.quit()

            self.dt = 0
            self.player.aircraft_specs = specs

        self.dt += self.gl.TIME_PASSED_SECONDS
