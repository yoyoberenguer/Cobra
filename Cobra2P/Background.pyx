# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


# PYGAME IS REQUIRED

from Textures import ELECTRIC

try:
    import pygame
    from pygame import Color, Surface, SRCALPHA, RLEACCEL, BufferProxy, HWACCEL, HWSURFACE, \
        QUIT, K_SPACE, Rect, BLEND_RGB_ADD
    from pygame.surfarray import pixels3d, array_alpha, pixels_alpha, array3d, \
        make_surface, blit_array
    from pygame.image import frombuffer
    from pygame.math import Vector2
    from pygame import _freetype
    from pygame._freetype import STYLE_STRONG, STYLE_NORMAL
    from pygame.transform import scale, smoothscale, rotate, rotozoom
except ImportError:
    raise ValueError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

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


from Sprites cimport Sprite
from Sprites cimport LayeredUpdates

cdef extern from 'Include/randnumber.c':
    int randRange(int lower, int upper)nogil;


cdef struct color_:
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;


@cython.binding(False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void create_stars(surface_, bint dark_zone_exclusion=True):
    """
    ADD PIXELS AT RANDOM POSITION TO A SURFACE (BACKGROUND)
    
    * Add bright pixels to the background surface to create a more details 
      and more a lively space background surface / animation
    * dark_zone_exclusion is by default set to True and prevent to draw pixel in 
      bright areas of the background.   
    * Transformation apply inplace (pixels3d)
    * This algo use randrange to provide better performances than randint and allow 
      to work nicely without the python GIL
    
    :param surface_: pygame.Surface; 24-bit or 32-bit pygame.Surface
    :param dark_zone_exclusion: Do not add pixels on bright area 
    :return: void 
    """
    cdef int w, h, rand, avg, x, y, \
        r, g, b
    # PUT STARS ALL OVER THE SURFACE
    w, h = surface_.get_size()

    # LOCK THE SURFACE
    surface_.lock()

    cdef color_ c;
    cdef unsigned char [:, :, :] array_

    try:
        array_ = pygame.surfarray.pixels3d(surface_)
    except:
        raise ValueError()
    with nogil:
        for r in prange(3000):
            rand = randRange(0, 1000)

            # YELLOW 10% CHANCE
            if rand > 950:
                c.r = <unsigned char>255
                c.g = <unsigned char>255
                c.b =  randRange(1, <unsigned char>255)
                c.a = randRange(1, <unsigned char>255)

            # RED 5%
            elif rand > 995:
                c.r = randRange(1, <unsigned char>255)
                c.g = <unsigned char>0
                c.b = <unsigned char>0
                c.a = randRange(<unsigned char>1, <unsigned char>255)

            # BLUE 2%
            elif rand > 998:
                c.r = <unsigned char>0
                c.g = <unsigned char>0
                c.b = randRange(<unsigned char>1, <unsigned char>255)
                c.a = randRange(<unsigned char>1, <unsigned char>255)

            else:
                avg = randRange(<unsigned char>128, <unsigned char>255)
                c.r = avg
                c.g = avg
                c.b = avg
                c.a = randRange(1, <unsigned char>255)
            x = randRange(<unsigned char>0, w - <unsigned char>1)
            y = randRange(<unsigned char>0, h - <unsigned char>1)

            # PIXEL VALUES BEFORE ADDING THE STAR
            r, g, b  = array_[x, y, <unsigned char>0], array_[x, y, <unsigned char>1],\
                       array_[x, y, <unsigned char>2]

            if not dark_zone_exclusion:
                # ADD PIXEL IF SUM RGB IS > 80
                if (r + g + b) > <unsigned char>80:
                    array_[x, y, <unsigned char>0], \
                    array_[x, y, <unsigned char>1], \
                    array_[x, y, <unsigned char>2] = c.r, c.g, c.b
            else:
                # ADD PIXELS ONLY IF SUM IS < 384 (DARK AREA)
                if (r + g + b) < 384:
                    array_[x, y, <unsigned char>0], array_[x, y, <unsigned char>1], \
                    array_[x, y, <unsigned char>2] = c.r, c.g, c.b

    surface_.unlock()


BACKGROUND_INVENTORY = []
BACKGROUND_INVENTORY_REMOVE = BACKGROUND_INVENTORY.remove

BACKGROUND_HUDS = [None, None]

cdef int FRAME_ACCEL = 300
cdef int FRAME_DEC = 250


@cython.binding(False)
@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Background(Sprite):
    cdef:
        public int _blend, _layer
        public image, rect, mask
        object v_pos, final, gl, comeback_to, images_copy
        public object speed
        public str event
        int index, i
        bint loop
        float rotation_speed, acceleration

    def __init__(self,
                 object images_,
                 object group_,
                 object gl_,
                 object v_pos_,
                 object speed_,
                 tuple final_,
                 object comeback_to_,
                 int layer_  = -<int>9,
                 str event_  = "",
                 bint loop_  = False,
                 bint blend_ = 0
                 ):
        """
        CONTROL THE BACKGROUND TEXTURES AND PARALLAX SPEED

        * You can pass a specific event in order to customized the background surface speed

        :param images_: pygame.Surface; Representing the background to display
        :param group_ : pygame Group; Sprite belonging to this group
        :param gl_    : class; Class containing all the contants/variables
        :param v_pos_ : Vector2; Vector, background position (top left corner)
        :param speed_ : Vector2; Vector, background speed
        :param final_ : Tuple;  define the background final destination before reassignment (org position)
        :param comeback_to_: Vector2; Vector; define the original position
        :param layer_ : integer; Sprite layer default -9
        :param event_ : string; define the background event/category
        :param loop_  : bool; Loop indefinitely if True
        :param blend_ : integer; Blending effect default 0 (no blending)
        """

        # CANNOT INSTANTIATE THE SAME BACKGROUND TWICE
        # if id(self) in BACKGROUND_INVENTORY:
        #     return

        Sprite.__init__(self, group_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

            # DISPLAY THE ENERGY AND LIFE SPRITE AT LEVEL ZERO
            if event_ in ('ENERGY', 'LIFE'):
                group_.change_layer(self, 0)

        self._blend         = blend_
        self._layer         = layer_
        self.images_copy    = images_.copy()
        self.image          = <object>PyList_GetItem(images_, 0) if \
            PyObject_IsInstance(images_, list) else images_

        self.image          = images_
        self.rect           = self.image.get_rect(topleft=v_pos_)
        self.v_pos          = v_pos_
        self.speed          = speed_
        self.final          = final_
        self.gl             = gl_
        self.comeback_to    = tuple(comeback_to_)
        self.event          = event_
        self.acceleration   = <float>6.0
        self.loop           = loop_
        self.rotation_speed = <float>0.0
        self.i              = 0

        # PRE CALCULATED MASK for PLATFORM 0 AND PLATFORM 7 ONLY
        # THE MASK IS USED FOR BOMB COLLISION PURPOSE OR FOR THE AIRCRAFT
        # SHADOW PROJECTION
        if event_ in ('PLATFORM_0', 'PLATFORM_7', 'ASTEROID1', 'ASTEROID2'):
            self.mask = pygame.mask.from_surface(self.image)
        else:
            self.mask = None

        self.index = 0

        BACKGROUND_INVENTORY.append(id(self))


    cdef void quit(self):
        if PyObject_HasAttr(self, 'kill'):
            self.kill()

        if id(self) in BACKGROUND_INVENTORY:
                BACKGROUND_INVENTORY_REMOVE(id(self))

    cpdef void kill_instance(cls, instance_):
        """ KILL A GIVEN INSTANCE AND REMOVE IT FROM THE INVENTORY"""
        if PyObject_IsInstance(instance_, Background):
            if PyObject_IsInstance(BACKGROUND_INVENTORY, list) and instance_ in BACKGROUND_INVENTORY:
                BACKGROUND_INVENTORY_REMOVE(instance_)
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()

    cpdef update(self, args=None):

        # TWEAKS
        cdef:
            str event       = self.event
            images_copy     = self.images_copy
            int index       = self.index
            gl              = self.gl
            screenrect      = gl.screenrect
            float acceleration = self.acceleration
            speed           = self.speed if not event == "PLATFORM_8" else gl.bv
            int frame       = gl.FRAME
            v_pos           = self.v_pos
            rect            = self.rect


        if event == 'ENERGY':
            self.image = <object>PyList_GetItem(BACKGROUND_HUDS, 0)
            if frame % 2 == 0:
                self.image.blit(ELECTRIC[self.i], (0, 0),
                                special_flags=BLEND_RGB_ADD)
                self.i += 1
                if self.i == len(ELECTRIC) - 1:
                    self.i = 0

        elif event == 'LIFE':
            self.image = <object>PyList_GetItem(BACKGROUND_HUDS, 1)

        else:
            if PyObject_IsInstance(images_copy, list):
                self.image = <object>PyList_GetItem(images_copy, index)
                rect = self.image.get_rect(center = v_pos)
                if index > len(images_copy) - <unsigned char>2:
                    index = <int>0
                else:
                    index += <int>1

            if frame < FRAME_ACCEL and bool(gl.PLAYER_GROUP):

                acc = speed * acceleration
                gl.vector1 += acc if event == 'PLATFORM' else (<float>0.0, <float>0.0)
                v_pos += acc

                # START TO DECELERATE AT 250 FRAMES
                if frame > FRAME_DEC:
                    acceleration -= <float>6.0/<float>50.0
                    if acceleration < <float>1.0:
                        acceleration = <float>1.0

            else:
                v_pos += speed

            if event in ('GALAXY1', 'GALAXY2'):
                if rect.top >= self.final[1]:
                    if not self.loop:
                        self.quit()
                    else:
                        v_pos = Vector2(randRange(0, screenrect.w), randRange(-<int>2048, -<int>1024))
                rect.centerx = v_pos.x
                rect.centery = v_pos.y

            elif v_pos.y >= self.final[1]:
                if not self.loop:
                    self.quit()
                else:
                    v_pos = Vector2(self.comeback_to[0], self.comeback_to[1])

            else:
                rect.topleft = self.v_pos


        if event in ('GALAXY1', 'GALAXY2'):

            if rect.colliderect(screenrect):

                self.rotation_speed += <float>0.08
                self.image = rotate(images_copy, self.rotation_speed)
                self.image.set_colorkey((0, 0, 0, 0), RLEACCEL)

                rect = self.image.get_rect(center = v_pos)

        # elif event == "PLATFORM_8":
        #
        #     if rect.colliderect(screenrect):
        #
        #         self.rotation_speed += 0.08
        #
        #         self.image = rotozoom(images_copy, self.rotation_speed, 1.0)
        #         rect_ = images_copy.get_rect()
        #         w, h = rect_.size
        #         self.image.set_colorkey((0, 0, 0, 0), RLEACCEL)
        #         rect = self.image.get_rect(center = (v_pos.x + (w >> 1), v_pos.y))
        #
        #         print(rect.center)

        self.index = index
        self.acceleration = acceleration
        self.v_pos = v_pos
        self.rect = rect
