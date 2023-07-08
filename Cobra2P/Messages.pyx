# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8

"""
This unit handle game events.
Display text information on the left side of the screen message about (options or bonuses collected)
The text is display for a certain amount of time (in full opacity)
"""

from __future__ import print_function

# NUMPY IS REQUIRED
try:
    import numpy
    from numpy import ndarray, zeros, empty, uint8, int32, float64, float32, dstack, full, ones,\
    asarray, ascontiguousarray
except ImportError:
    print("\n<numpy> library is missing on your system."
          "\nTry: \n   C:\\pip install numpy on a window command prompt.")
    raise SystemExit

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

# PYGAME IS REQUIRED
try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, make_surface,\
        blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL

except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

try:

    from Sprites cimport Sprite
    from Sprites cimport LayeredUpdates
except ImportError:
    raise ImportError("\nSprites.pyd missing!.Build the project first.")

import os

if not pygame._freetype.get_init():
    _freetype.init(cache_size=64, resolution=72)

if not pygame.display.get_init():
    raise ValueError("Display module has not been initialized")


# Pygame Vector2 substitute
cdef extern from 'Include/vector.c':

    struct vector2d:
       float x;
       float y;

    void vecinit(vector2d *v, float x, float y)nogil

# List/stack containing all the events (first at the bottom more
# recent at the end of the stack
cdef public list QUEUE = []

# Convenient class that holds all the unit global variable(s).
# This class can be access from other units to check the
# variable values. The lock state True tells the main program
# to wait at least 0.3 seconds before starting/sending the next event.
cdef class MessageLock(object):
    cdef dict __dict__
    def __init__(self):
        self.lock = False

FONT = _freetype.Font(os.path.join('Assets/Fonts/', 'ARCADE_R.ttf'), size=9)
FONT.antialiased = True


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class CreateEvent(object):

    cdef:
        str text_, category
        public object surf


    def __init__(self, str category_, str text_):
        self.surf = pygame.Surface((250, 20)).convert()

        if category_ == "energy":
            self.surf.fill((255, 4, 2, 255))
            self.render(text_, (255, 255, 255, 255), (255, 4, 2, 255))

        elif category_ == "xp":
            self.surf.fill((0, 128, 192, 255))
            self.render(text_, (255, 255, 255, 255), (0, 128, 192, 255))

        elif category_ == "gem":
            self.surf.fill((0, 128, 64, 255))
            self.render(text_, (255, 255, 255, 255), (0, 128, 64, 255))

        elif category_ == "nuke":
            self.surf.fill((15, 15, 15, 255))
            self.render(text_, (255, 255, 255, 255), (30, 30, 30, 255))

        elif category_ == "missile":
            self.surf.fill((128, 64, 0, 255))
            self.render(text_, (255, 255, 255, 255), (128, 64, 0, 255))

        else:
            raise ValueError('Invalid category %s.\nChoose between '
                             '(energy, xp, gem, nuke, missile). The text is case sensitive' % category_)

    cdef inline void render(self, text_, foreground_, background_, style_=STYLE_STRONG):
        FONT.render_to(self.surf, (20, 5), text_, foreground_, background_, style_)


# Instance to share with the rest of the program
ML = MessageLock()
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Messages(Sprite):
    cdef:
        public object image, rect
        object v_pos
        int start
        unsigned char alpha_value
        float max_frames, frames

    def __init__(self, image_, groups_, int x_, int y_, gl_, int layer_=-6):
        """
        MESSAGE METHOD

        This method had to instantiated from the main loop to call an event to be display
        on the left side of the playable area. The event will scroll top to bottom and the
        surface transparency will slowly fadeout with the background.
        You can call many times this method consecutively without affecting the speed
        of the program or filling up the queue. The program will determine when to start the next
        event (usually 0.3 seconds after the last event).

        :param image_ : object; 24-bit Image fast blit
        :param groups_: object; Sprite group where the sprite belong
        :param x_     : integer; starting location (x offset)
        :param y_     : integer; starting location (y offset)
        :param gl_    : object; Class containing all the program constants & variables
        :param layer_ : integer; layer where the sprite will be display. The sprite might not be
        visible if the selected sprite layer is below the background or other large surface
        """

        global QUEUE, ML

        # Check the lock status.
        # Prevent multiple events to be trigger
        # at the same time.
        if ML.lock is True:
            return

        # Prevent the queue to buildup
        if PyList_Size(QUEUE)>100:
            QUEUE = []

        Sprite.__init__(self, groups_)

        if isinstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.gl         = gl_
        # No copy, the surface must be unique
        self.image      = image_
        self.rect       = self.image.get_rect(topleft=(x_, y_))

        self._blend     = 0

        cdef vector2d v_pos
        vecinit(&v_pos, <float>x_, <float>y_)
        self.v_pos = v_pos

        self.alpha_value = 255
        self.start       = gl_.FRAME

        if self.gl.MAXFPS == 0:
            raise ValueError("Constant MAXFPS cannot be zero!")
        cdef float inv_fps = (<float>1.0 / self.gl.MAXFPS)
        self.max_frames = <float>0.6 / inv_fps

        # Lock mechanism
        # ML.lock = True
        QUEUE.append(id(self))

    cdef inline void kill_sprite(self):
        """
        Remove the object id from the queue and 
        kill the sprite (kill the sprite in all groups) 
        and reset the lock
        
        :return: void;  
        """
        if id(self) in QUEUE:
            QUEUE.remove(id(self))
        self.kill()

    cpdef update(self, args=None):
        """
        The update is access from the main loop every iterations. 
        If the program is running at 60 FPS then this method will be 
        access every 1/60 secs 
        
        :param args: default None   
        :return: void
        """
        cdef:
            object gl_ = self.gl
            int current_frame = gl_.FRAME
            int start = self.start
            float frames = self.frames
            int x = self.v_pos['x'], y = self.v_pos['y']
            int alpha_value = self.alpha_value
            vector2d v

        cdef int t = current_frame - start


        if t > self.max_frames:
            self.kill_sprite()

        if PyList_Size(QUEUE) > 0:

            self.image.set_alpha(alpha_value)
            self.rect.topleft = (x, y)

            if x < 20:
                x += 30
            else:
                alpha_value -= 8
                if alpha_value < 0:
                    alpha_value = 0
                    self.kill_sprite()
                    return

                y += 5

            vecinit(&v, <float>x, <float>y)
            self.v_pos = v

        self.alpha_value = alpha_value



