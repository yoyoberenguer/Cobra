# cython: boundscheck=False, wraparound=False, nonecheck=False, optimize.use_switch=True, optimize.unpack_method_calls=True, cdivision=True, profile=False


# encoding: utf-8


# CYTHON IS REQUIRED
from Textures import NAMIKO, DIALOGBOX_READOUT, VOICE_MODULATION

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


from numpy import linspace, empty, uint8, asarray, ndarray
cimport numpy as np

cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;

DEF M_PI = 3.14159265358979323846

try:
    import pygame
    from pygame import freetype, Color, BLEND_RGB_ADD, RLEACCEL, Surface, Rect
    from pygame import freetype
    from pygame.freetype import STYLE_STRONG
    from pygame.transform import rotate, smoothscale
    from pygame.surfarray import pixels3d
    from pygame.image import frombuffer
    from pygame.math import Vector2

except ImportError:
    print("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")
    raise SystemExit

from Sprites cimport Sprite
from Tools cimport damped_oscillation
from PygameShader import horizontal_glitch


# from SurfaceBurst import instant_display, burst, VERTEX_ARRAY_SUBSURFACE

FRAMEBORDER = pygame.image.load('Assets/Graphics/GUI/FrameBorder_.png').convert()
FRAMEBORDER.set_colorkey((0, 0, 0, 0), RLEACCEL)
FRAMEBORDER = smoothscale(FRAMEBORDER, (370, 250))
FRAMEBORDER = smoothscale(FRAMEBORDER, (FRAMEBORDER.get_width(), FRAMEBORDER.get_height() - 40))

FRAMESURFACE = pygame.Surface((FRAMEBORDER.get_width() - 20, FRAMEBORDER.get_height() - 20),
                              pygame.RLEACCEL).convert()
FRAMESURFACE.fill((10, 10, 18, 200))
FRAMEBORDER.blit(FRAMESURFACE, (10, 15))




IMAGES               = FRAMEBORDER

cdef bint ACTIVE     = False
cdef list INVENTORY  = []
cdef inv_remove      = INVENTORY.remove

FONT                 = freetype.Font('C:/Windows/Fonts/Arial.ttf')
FONT.antialiased     = True

VOICE_MODULATION     = VOICE_MODULATION
READOUT              = DIALOGBOX_READOUT


cdef destroy():
    for instance in INVENTORY:
        inv_remove(instance)
        instance.kill()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class DialogBox(Sprite):

    cdef:
        object gl, image_copy, scan_background_surface, character, acceleration, \
        fade_in, fade_out
        public object image, rect
        public int _layer, _blend
        int index, readout_index,\
        start, count, start_moving, stop_moving, move_counter, \
        fade_in_counter, start_fadeout, start_fadein, fade_out_counter
        list text
        tuple location, text_color
        str direction
        bint voice, scan, damp_effect
        float text_origin, voice_module_index, scan_index
        float dt

    def __init__(self,
                 object gl_,
                 tuple location_,
                 object scan_image,
                 object character,
                 float speed_      = <float>16.0,
                 int layer_        = -3,
                 bint voice_       = True,
                 bint scan_        = True,
                 int start_        = 0,
                 str direction_    = 'RIGHT',
                 tuple text_color_ = (149, 119, 236, 245),
                 int fadein_       = 100,
                 int fadeout_      = 1000,
                 list text         = [],
                 str text_max_string_ = ""):

        Sprite.__init__(self, gl_.All)

        self.gl             = gl_
        self.text           = text
        self.image          = IMAGES
        self.image_copy     = IMAGES.copy()
        self.location       = location_
        self.rect           = self.image.get_rect(
            topleft=(self.location[0], self.location[1]))
        self.direction      = direction_
        self.text_origin    = <float>150.0
        self.index          = 0

        self.timing         = speed_
        self.max_width, self.max_height = self.image.get_size()

        self.voice_module_index      = <float>0.0
        self.readout_index           = 0

        scan_image.set_colorkey((0, 0, 0, 0), pygame.RLEACCEL)
        self.scan_background_surface = scan_image

        self.scan_background_surface = smoothscale(
            self.scan_background_surface, (60, self.max_height - 15))
        self.scan_index              = <float>0.0
        self.character               = character
        self.voice                   = voice_
        self.scan                    = scan_
        self.count                   = 0
        self.start_dialog_box        = start_
        self.text_color              = text_color_
        self.start_moving            = self.start_dialog_box + 0
        self.stop_moving             = self.start_dialog_box + 200
        self.acceleration            = linspace(12, 0, self.stop_moving)
        self.move_counter            = 0
        cdef int diff                = self.stop_moving - self.start_moving
        self.fade_in                 = linspace(0, 255,  diff)
        self.fade_in_counter         = 0
        self.fade_out                = linspace(255, 0, diff)
        self.start_fadeout           = fadeout_
        self.start_fadein            = fadein_
        self.fade_out_counter        = 0
        self.damp_effect             = False

        rect = FONT.get_rect(text_max_string_, style=freetype.STYLE_STRONG, rotation=0, size=17)
        image = Surface((rect.w, rect.h * <unsigned char>12)).convert()
        y = 25
        for sentence in text:
            FONT.render_to(
                image, (0, y), sentence, fgcolor=pygame.Color(149, 119, 236, 245),
                style=freetype.STYLE_STRONG, size=17)
            y += 25

        self.box_image               = image
        self._layer                  = layer_
        self._blend                  = 0
        self.dt                      = 0

        INVENTORY.append(self)


    cdef void move_right(self):

        cdef:
            int frame        = self.gl.FRAME
            int move_counter = self.move_counter
            acceleration     = self.acceleration
            int start        = self.start_moving
            int stop         = self.stop_moving
            rect             = self.rect

        if rect.left < 10:
            if start < frame < stop:
                rect.move_ip(acceleration[move_counter % (len(acceleration) - <unsigned char>1)], 0)
                move_counter += <unsigned char>1
            else:
                if frame > stop:
                    rect.move_ip(2, 0)
            self.move_counter = move_counter
        else:
            self.damp_effect = True
            self.direction = "None"

    cdef void move_left(self):

        cdef:
            int frame        = self.gl.FRAME
            int move_counter = self.move_counter
            acceleration     = self.acceleration
            int start        = self.start_moving
            int stop         = self.stop_moving
            int screenrect_w = self.gl.SCREENRECT.w
            rect             = self.rect

        if rect.right > screenrect_w - 10:
            if start < frame < stop:
                rect.move_ip(-acceleration[move_counter % (len(acceleration) - <unsigned char>1)], 0)
                move_counter += 1
            else:
                if frame > stop:
                    rect.move_ip(-2, 0)
            self.move_counter = move_counter
        else:
            self.damp_effect = True
            self.direction = "None"

    cdef void alpha_in(self, im_):

        cdef:
            fade_in             = self.fade_in
            int fade_in_counter = self.fade_in_counter
            int start           = self.start_fadein
            int stop            = self.stop_moving
            int frame           = self.gl.FRAME

        if self.fade_in_counter < len(fade_in) - <unsigned char>1:
            if start < frame < stop:
                im_.set_alpha(fade_in[fade_in_counter % (len(fade_in) - <unsigned char>1)])
                fade_in_counter += <unsigned char>1
        else:
            im_.set_alpha(<unsigned char>255)

        self.fade_in_counter = fade_in_counter

    cdef void alpha_out(self, im_):

        cdef:
            fade_out             = self.fade_out
            int fade_out_counter = self.fade_out_counter
            int start            = self.start_fadeout
            int frame            = self.gl.FRAME

        if fade_out_counter > len(fade_out) - <unsigned char>1:
            destroy()
            return

        if frame > start:
            im_.set_alpha(fade_out[fade_out_counter])
            fade_out_counter += <unsigned char>1

        self.fade_out_counter = fade_out_counter


    cdef display_text(self, image_):

        cdef:
            int x, y

        x = 120
        y = <int>self.text_origin
        image_.blit(self.box_image, (x, y), special_flags=BLEND_RGB_ADD)
        if self.text_origin > 12:
        # SCROLL THE TEXT UP
            self.text_origin -= <float>0.2
        return image_

    cdef disruption_effect(self, im_):
        horizontal_glitch(im_, 1, <float>0.8, (50 - self.gl.FRAME) % 10)
        im_.set_colorkey((0, 0, 0, 0), RLEACCEL)
        return im_

    cdef dampening_effect(self):

        cdef float c = (self.gl.FRAME / <float>20.0) % 10

        if c == 0.0:
            self.damp_effect = False
            return
        cdef float t = damped_oscillation(c)

        cdef int w, h, ww, hh
        cdef float tm = t * <float>100.0
        w, h = self.image.get_size()
        if w + tm < 0:
            tm = 0
        if h + tm < 0:
            tm = 0
        cdef int x, y
        x, y = self.rect.topleft
        self.image = smoothscale(self.image, (<int> (w + tm), <int> (h + tm)))
        self.rect = self.image.get_rect(topleft=(x, y))

    cpdef update(self, args=None):

        cdef:
            float scan_index = self.scan_index
            int frame = self.gl.FRAME
            int index = self.index
            int count = self.count
            int readout_index = self.readout_index
            character = self.character
            float voice_module_index = self.voice_module_index
            voice_modulation = VOICE_MODULATION
            readout = READOUT

        if self.dt > self.timing:

            if frame > self.start_dialog_box:

                image = self.image_copy.copy()
                image.set_alpha(None)

                char_sprite = PyList_GetItem(character, index)

                # # DISPLAY THE GLITCH
                # if randRange(0, 100) >= 98:
                #     PyObject_CallFunctionObjArgs(
                #         image.blit,
                #         <PyObject*> character[len(character) - 1],
                #         <PyObject*> <object> (10, 20),
                #         <PyObject*> None,
                #         <PyObject*> 0,
                #         NULL)
                # else:
                PyObject_CallFunctionObjArgs(
                    image.blit,
                    <PyObject*> char_sprite,
                    <PyObject*> <object>(8, 20),
                    <PyObject*> None,
                    <PyObject*> BLEND_RGB_ADD,
                    NULL)

                if index < (<object>PyList_Size(character) - 2):
                    if count > 20:
                        index += 1
                        count = 0
                else:
                    index = 0

                if self.scan:
                    scan_index += 4

                PyObject_CallFunctionObjArgs(
                    image.blit,
                    <PyObject*> readout[<int>readout_index % (<object>PyList_Size(readout) - 1)],
                    <PyObject*> <object> (100, 0),
                    <PyObject*> None,
                    <PyObject*> BLEND_RGB_ADD,
                    NULL)

                if self.voice:
                    PyObject_CallFunctionObjArgs(
                        image.blit,
                        <PyObject*> voice_modulation[
                            <int>voice_module_index % (<object>PyList_Size(voice_modulation) - 1)],
                        <PyObject*> <object>(0, 10),
                        <PyObject*> None,
                        <PyObject*> BLEND_RGB_ADD,
                        NULL)

                if self.scan:
                    p = (scan_index, 12)
                    PyObject_CallFunctionObjArgs(
                        image.blit,
                        <PyObject*> self.scan_background_surface,
                        <PyObject*> <object>p,
                        <PyObject*> None,
                        <PyObject*> BLEND_RGB_ADD,
                        NULL)

                    if scan_index > self.max_width:
                        scan_index = 0

                voice_module_index += <float>0.2
                readout_index += 1

                image = self.display_text(image)
                self.alpha_in(image)

                if frame > self.start_fadeout:
                    self.alpha_out(image)

                if self.direction == 'RIGHT':
                    self.move_right()

                elif self.direction == 'LEFT':
                    self.move_left()

                count += 1

                self.scan_index = scan_index
                self.index = index
                self.image = image
                self.count = count
                self.readout_index = readout_index
                self.voice_module_index = voice_module_index

                # if self.damp_effect:
                #     self.dampening_effect()
                if randRange(0, 100) >= 98:
                    self.image = self.disruption_effect(image)

            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS