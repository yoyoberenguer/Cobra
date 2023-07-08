# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

import pygame
from pygame.transform import smoothscale
from pygame.surface import Surface
import time
import threading
cimport cython
# TODO DOC

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class SoundLevel:

    cdef:
        public int value
        object th
        bint flag
        public object image, level_indicator, canvas
        float scale, length, height
        int h


    def __init__(self, sound_icon, level_indicator, float volume_, float scale_):


        cdef float length, height
        length, height = <float>350.0 * scale_, <float>72.0 * scale_

        self.canvas = Surface((length, height)).convert()
        self.canvas.fill((28, 40, 32, 20))

        cdef int w, h

        if scale_ != 1:
            w, h = sound_icon.get_size()
            sound_icon = smoothscale(sound_icon, (<int>(w * scale_), <int>(h * scale_)))

            w, h = level_indicator.get_size()
            level_indicator = smoothscale(level_indicator, (<int>(w * scale_), int(h * scale_)))

        w, h = sound_icon.get_size()
        self.canvas.blit(sound_icon,
                         (<int>(<float>2.85 * length / <float>100.0),
                          (self.canvas.get_height() - h) >> 1))

        w, self.h   = level_indicator.get_size()

        self.value  = 255
        self.th     = None
        self.flag   = False
        self.image  = None
        self.scale  = scale_
        self.length = length
        self.height = height
        self.level_indicator = level_indicator
        self.update_volume(volume_)

    cpdef pause(self):
        pause_time = <unsigned char>2  # 2 seconds
        t1         = time.time()
        while time.time() - t1 < pause_time:
            pygame.time.wait(<unsigned char>10)
        self.flag  = True
        self.th    = None

    cpdef update_volume(self, float volume_):

        can = self.canvas.copy()

        for level in range(<int>(volume_ * <unsigned char>10)):
            can.blit(self.level_indicator,
                     (<int>(<float>22.85 * self.length/<float>100.0) + (level * 25 * self.scale),
                      (self.canvas.get_height() - self.h) // <unsigned char>2))
        self.value  = <unsigned char>255
        self.flag   = False
        can.set_alpha(self.value)
        self.image  = can

        if self.th is None:
            self.th = threading.Thread(target=self.pause)
            self.th.start()

    cpdef update_visibility(self):
        if self.flag:
            self.value -= 2 if self.value > 1 else 0
            self.image.set_alpha(self.value)



