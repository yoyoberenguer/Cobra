# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8
import numpy
from pygame.mask import from_surface

from CobraLightEngine import LightEngineBomb
from SpriteSheet cimport sprite_sheet_fs8
from Tools cimport reshape, make_transparent32,\
    blend_to_textures_24c, alpha_mask, mask_alpha32_inplace
# ,blend_texture_inplace_24c, blend_texture_24_alpha, blend_to_textures_inplace_24c

# from Textures import RADIAL4_ARRAY_256x256, RADIAL4_ARRAY_128x128

try:
    import pygame
    from pygame.math import Vector2
    from pygame import Rect, BLEND_RGB_ADD, HWACCEL, BLEND_RGB_MAX, RLEACCEL
    from pygame import Surface, SRCALPHA, mask
    from pygame.transform import rotate, scale, smoothscale, rotozoom
    from pygame.mixer import Sound

except ImportError:
    raise ImportError("\n<Pygame> library is missing on your system."
          "\nTry: \n   C:\\pip install pygame on a window command prompt.")

GROUND_EXPLOSION = []
GROUND_EXPLOSION.append(Sound('Assets/Sounds/GroundExplosion.ogg'))
GROUND_EXPLOSION.append(Sound('Assets/Sounds/Huge explosion1a.ogg'))
GROUND_EXPLOSION.append(Sound('Assets/Sounds/GroundExplosiona.ogg'))
GROUND_EXPLOSION.append(Sound('Assets/Sounds/GroundExplosionb.ogg'))

from libc.math cimport cos, sin, round, exp, floor

cdef extern from 'Include/randnumber.c':

    float randRangeFloat(float lower, float upper)nogil;
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

try:
   from Sprites cimport Sprite, collide_mask, spritecollideany, LayeredUpdates, \
       collide_rect_ratio, collide_rect
   from Sprites import Group
except ImportError:
    raise ImportError("\n<Sprites> library is missing on your system or not cynthonized."
                      "\nTry: \n   C:\\python setup_Project.py build_ext --inplace")

from numpy import linspace, float32

DEF M_PI = 3.14159265359
DEF RAD_TO_DEG = 180.0 / M_PI
DEF DEG_TO_RAD = M_PI / 180.0

image_load = pygame.image.load

# *********************************************************************************************************************
BOMB = image_load('Assets/Graphics/Missiles/MISSILE3.png').convert_alpha()
cdef:
    int w = BOMB.get_width()
    int h = BOMB.get_height()

BOMB = smoothscale(BOMB, (<int>(w / <float>30.0), <int>(h / <float>30.0)))
BOMB_ROTATE_BUFFER = {}
for a in range(360):
    BOMB_ROTATE_BUFFER[a] = rotozoom(BOMB, a - 90, <float>1.0)


# *** EXPLOSIONS SPRITES
cdef list EXPLOSION1 = \
    sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/Explosion8_256x256_.png',  256, 6, 6)
cdef list EXPLOSION2 = \
    sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/Explosion9_256x256_.png',  256, 6, 8)
cdef list EXPLOSION3 = \
    sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/Explosion10_256x256_.png', 256, 6, 7)
cdef list EXPLOSION4 = \
    sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/Explosion11_256x256_.png', 256, 6, 7)
cdef list EXPLOSION5 = \
    sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/Explosion12_256x256_.png', 256, 6, 7)
cdef list EXPLOSION6 = \
    sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/Explosion12_256x256_.png', 256, 6, 7)

EXPLOSION6 = reshape(EXPLOSION6, (256, 256))
cdef int rnd
rnd = randRange(256, 512)
EXPLOSION1 = reshape(EXPLOSION1, (rnd, rnd))
rnd = randRange(256, 512)
EXPLOSION2 = reshape(EXPLOSION2, (rnd, rnd))
rnd = randRange(256, 512)
EXPLOSION3 = reshape(EXPLOSION3, (rnd, rnd))
rnd = randRange(256, 512)
EXPLOSION4 = reshape(EXPLOSION4, (rnd, rnd))
rnd = randRange(256, 512)
EXPLOSION5 = reshape(EXPLOSION5, (rnd, rnd))
EXPLOSIONS = [EXPLOSION1, EXPLOSION2, EXPLOSION3, EXPLOSION4, EXPLOSION5]

CRATER      = image_load('Assets/Graphics/TimeLineFx/Explosion/Crater2_.png')
CRATER      = smoothscale(CRATER, (64, 64)).convert_alpha()
CRATER_MASK = from_surface(CRATER)
cdef int CRATER_MASK_COUNT = CRATER_MASK.count()

HOTFURNACE2 = \
    sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/Burning/Burning1_256x256_.png', 256, 6, 6)
HOTFURNACE2 = reshape(HOTFURNACE2, (64, 64))
HOTFURNACE = \
    sprite_sheet_fs8('Assets/Graphics/TimeLineFx/Explosion/Burning/HotFurnace_256x256_.png', 256, 6, 6)
HOTFURNACE = reshape(HOTFURNACE, (64, 64))

# *** DEBRIS SPRITES
cdef list G5V200_DEBRIS = [
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/Boss7Debris1.png').convert(),
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/Boss7Debris2.png').convert(),
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/Boss7Debris3.png').convert(),
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/Boss7Debris4.png').convert(),
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/Boss7Debris5.png').convert()
]

cdef list G5V200_DEBRIS_HOT = [
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/debris1.png').convert(),
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/debris2.png').convert(),
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/debris3.png').convert(),
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/debris4.png').convert(),
    image_load('Assets/Graphics/SpaceShip/Original/Boss7Debris/debris5.png').convert()
]
G5V200_DEBRIS     = reshape(G5V200_DEBRIS, factor_=(64, 64))
G5V200_DEBRIS_HOT = reshape(G5V200_DEBRIS_HOT, factor_=(64, 64))
EXPLOSION_DEBRIS  = [*G5V200_DEBRIS_HOT, *G5V200_DEBRIS]

# *** HALO SPRITES
cdef double [::1] steps = linspace(0, 255, 30)
image = smoothscale(image_load('Assets/Graphics/Halo/Halo11.png').convert_alpha(), (64, 64))
cdef:
    int n = 30
    unsigned char [:, :, :] rgb
    unsigned char [:, :] alpha
    int i
    float c1 = 0;

HALO_SPRITE11 = [image] * n
w = image.get_width()
h = image.get_height()

i = 0
for image in HALO_SPRITE11:
    image = make_transparent32(image, <int>steps[i])
    c1 = 1.0 + (<float>i / <float>5.0)
    HALO_SPRITE11[i] = smoothscale(image, (<int>(w * c1), <int>(h * c1))).convert_alpha()
    i += 1

HALO_SPRITE13 = [smoothscale(image_load(
    'Assets/Graphics/Halo/Halo13.png').convert_alpha(), (64, 64))] * 30
i = 0
for image in HALO_SPRITE13:
    image = make_transparent32(image, <int>steps[i])
    c1 = 1.0 + (<float>i / <float>5.0)
    surface1 = smoothscale(image, (<int>(w * c1), <int>(h * c1)))
    HALO_SPRITE13[i] = surface1.convert_alpha()
    i += 1

FLASH_LIGHT = image_load("Assets/Radial5_.png").convert()
LIGHT = [smoothscale(FLASH_LIGHT, (128, 128))] * 20

w = LIGHT[0].get_width()
h = LIGHT[0].get_height()

cdef:
    float ii = 0.0
    int j = 0

for surface in LIGHT:
    if j != 0:
        LIGHT[j] = smoothscale(surface, (<int>(w / ii), <int>(h / ii)))
    else:
        LIGHT[0] = surface

    ii += <float>0.5
    j += 1

# *********************************************************************************************************************

cdef:
    list COS_TABLE  = [<float>cos(a * <float>DEG_TO_RAD) for a in range(0, 360)]
    list SIN_TABLE  = [<float>sin(a * <float>DEG_TO_RAD) for a in range(0, 360)]


cdef list CRATER_RECT_LIST = []

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindSprite(Sprite):

    cdef:
        int obj_center_x, obj_center_y, index, length_1
        public int _blend , layer_
        object images_copy, obj, gl
        public object rect, image
        float timing, dt

    def __init__(self,
                 images_,
                 object_,
                 gl_,
                 float timing_    =16.67,
                 int layer_       = 0,
                 int blend_       = 0,
                 ):
        """
        BIND A SPRITE TO AN OBJECT (THE SPRITE WILL BE DISPLAY AT THE COORDINATE
        MATCHING THE OBJECT RECT CENTRE (X, Y POSITION)

        * Use the object rect.center position to display the sprite
        * Display all the surfaces from the sprite list (animation) and kill the sprite

        :param images_: pygame.Surface; Texture surface used by the sprite
        :param object_: class; Instance/ object containing attributes
        :param gl_    : class; constants/variables
        :param timing_: float; Cap max fps to 60fps (16.67ms)
        :param layer_ : integer; Layer to use for the sprite
        :param blend_ : integer; Blend mode to use default None
        """

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self._layer       = layer_
        self.images_copy  = images_
        self.image        = images_[0] if PyObject_IsInstance(
            images_, list) else images_
        self.obj          = object_
        self.obj_center_x = object_.rect.centerx
        self.obj_center_y = object_.rect.centery
        self.rect         = self.image.get_rect()
        self.rect.center  = (self.obj_center_x, self.obj_center_y)
        self.dt           = 0
        self.index        = 0
        self.gl           = gl_
        self._blend       = blend_

        self.length_1     = len(self.images_copy)  - 1 \
            if PyObject_IsInstance(images_, list) else 1


    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindSprite):
            if PyObject_HasAttr(instance_, 'kill'):
                instance_.kill()


    cpdef update(self, args=None):
        cdef:
            obj              = self.obj
            int obj_center_x = self.obj_center_x
            int obj_center_y = self.obj_center_y
            images_copy      = self.images_copy

        if self.dt > self.timing:

            if self.index == self.length_1:
                self.kill()
                return

            self.image = images_copy[self.index]

            self.index += 1
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindSpriteLoopOver(Sprite):

    cdef:
        int index,
        public int _blend , layer_
        object  gl
        public object rect, image

    def __init__(self,
                 images_,
                 x,
                 y,
                 gl_,
                 int layer_       = 0,
                 int blend_       = 0,
                 ):
        """
        BIND A SPRITE TO AN OBJECT (THE SPRITE WILL BE DISPLAY AT THE COORDINATE
        MATCHING THE OBJECT RECT CENTRE (X, Y POSITION)

        * Use the object rect.center position to display the sprite
        * Display all the surfaces from the sprite list (animation) and kill the sprite

        :param images_: pygame.Surface; Texture surface used by the sprite
        :param gl_    : class; constants/variables
        :param layer_ : integer; Layer to use for the sprite
        :param blend_ : integer; Blend mode to use default None
        """

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self._layer       = layer_
        self.image        = images_[0] if PyObject_IsInstance(
            images_, list) else images_
        self.rect         = self.image.get_rect(center=(x, y))
        self._blend       = blend_
        self.gl = gl_


    cpdef update(self, args=None):

        if not self.rect.colliderect(self.gl.screenrect):
            self.kill()

        self.rect.center += self.gl.bv

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef bint full_merge(object right, object left):
    """
    RETURN TRUE WHEN BOTH SPRITES FULLY OVERLAP 

    :param right: pygame.Sprite; right sprite 
    :param left : pygame.Sprite; left sprite
    :return: bool; True | False
    """
    cdef:
        int xoffset = right.rect[0] - left.rect[0]
        int yoffset = right.rect[1] - left.rect[1]
    r_mask = left.mask.overlap_mask(right.mask, (xoffset, yoffset))
    if r_mask.count() == CRATER_MASK_COUNT:
        return True
    else:
        return False

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef bint crack_collision(object gl_,
                          object crack_image_,
                          object crack_mask_,
                          int center_x_,
                          int center_y_,
                          short int layer_=-7):
    """
    CHECK CRACK COLLISION WITH THE GROUND (LAYER -7)
    
    :param gl_: class; Contains all constants / variables
    :param crack_image_: pygame.Surface (ground crack image)
    :param crack_mask_: Mask of the image 
    :param center_x_: integer; x coordinates (center)
    :param center_y_: integer; y coordinates (center)
    :param layer_:  integer; layer to use
    :return: bool; True|False Return True if the sprite fully collide with the ground 
    """

    crack_sprite = Sprite()
    crack_sprite.image = crack_image_
    crack_sprite.mask = crack_mask_

    crack_sprite.rect = crack_image_.get_rect(center=(center_x_, center_y_))

    cdef:
        list sprites_at_drop_position
        gl_All = gl_.All
        get_sprites_at = gl_All.get_sprites_at
        int w, h
        list ground_level_group = []
        int ground_layer = layer_

    sprites_at_drop_position = get_sprites_at(crack_sprite.rect.center)

    for sp in sprites_at_drop_position:
        if not PyObject_HasAttr(sp, '_layer'):
            continue
        if sp._layer != ground_layer:
            continue
        else:
            ground_level_group.append(sp)

    if len(ground_level_group) > 0:

        for spr in ground_level_group:

            if PyObject_HasAttr(spr, 'mask') and spr.mask is not None:

                if collide_mask(spr, crack_sprite):
                    return full_merge(spr, crack_sprite)
            else:
                return True

    return False

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class DisplayCrack(Sprite):
    """
    DISPLAY A GROUND CRACK AFTER A BOMBING EFFECT
    """

    cdef:
        public int _blend, layer_
        int w, h, speed
        object images_copy, gl
        public object rect, image
        float timing, dt

    def __init__(self,
                 image_,
                 gl_,
                 int center_x,
                 int center_y,
                 float timing_    = <float>16.67,
                 int layer_       = -6,  # was 6
                 int blend_       = 0,
                 int speed_       = 1
                 ):

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)
        w, h = image_.get_size()
        self._layer      = layer_
        self.images_copy = image_.copy()
        self.rect        = self.images_copy.get_rect()
        self.rect.center = (center_x, center_y)
        self.dt          = 0
        self.gl          = gl_
        self._blend      = blend_
        self.image_mask  = from_surface(self.images_copy)
        self.mask        = alpha_mask(self.images_copy, 0)
        self.image       = self.images_copy
        self.zero        = numpy.zeros((w, h), dtype=numpy.uint8)
        self.speed = speed_

        crk = crack_collision(gl_, self.images_copy, self.image_mask, center_x, center_y, -7)

        if not crk:
            self.kill()
            if self.gl.All.has(self):
                self.gl.All.remove(self)


    cpdef update(self, args=None):

        if self.dt > self.timing:

            if self.rect.colliderect(self.gl.screenrect):

                if not (numpy.array_equal(numpy.asarray(self.mask), self.zero)):
                    self.mask = mask_alpha32_inplace(self.image, self.mask, self.speed)


                # ADD BACKGROUND VELOCITY
                self.rect.center += self.gl.bv
                self.dt = 0

            else:
                self.kill()

        self.dt += self.gl.TIME_PASSED_SECONDS


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BindToBackground(Sprite):

    cdef:
        int obj_center_x, obj_center_y, index, length
        public int _blend , layer_
        object images_copy, obj, gl
        public object rect, image
        float timing, dt
        bint loop


    def __init__(self,
                 images_,
                 object_,
                 gl_,
                 float timing_    = <float>16.67,
                 int layer_       = 0,
                 int blend_       = 0,
                 bint loop_       = False
                 ):
        """
        BIND A SPRITE TO THE BACKGROUND (BACKGROUND SPEED IS GIVEN BY GL.BV background velocity)

        * Use the object rect center position to display the sprite and add the background velocity to
          the it.
        * Optional argument loop_ to create an infinite animation (as long as the sprite is within the
          playable area
        * All the surfaces from the sprite animation will be blended toward another surface (CRATER surface)
          This will create an illusion of hot lava cooling down
        * The sprite list is copied during instantiation to avoid the original set to be modified.
        * The sprite rectangle is added to a special list CRATER_RECT_LIST that will be used for rect
          collision and determine if two rects are overlapping (two craters overlaps not allowed).

        :param images_: pygame.Surface; Surface to use for the sprite
        :param object_: class/instance; Object instance with attributes such as rect etc
        :param gl_    : class/ instance; Global variables / constants
        :param timing_: float; Cap the max fps to 60 fps (16.67ms)
        :param layer_ : integer; Layer to use for the sprite
        :param blend_ : integer; Blend mode (default None)
        """

        Sprite.__init__(self, gl_.All)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self._layer       = layer_
        self.images_copy  = images_.copy()
        self.image        = images_[0] if PyObject_IsInstance(
            images_, list) else images_
        self.obj          = object_
        self.obj_center_x = object_.rect.centerx
        self.obj_center_y = object_.rect.centery
        self.rect         = self.image.get_rect()
        self.rect.center  = (self.obj_center_x, self.obj_center_y)

        self.dt           = 0
        self.index        = 0
        self.gl           = gl_
        self._blend       = blend_
        self.loop         = loop_
        self.length       = len(self.images_copy) \
            if PyObject_IsInstance(images_, list) else 1

        CRATER_RECT_LIST.append(self.rect)

    @classmethod
    def kill_instance(cls, instance_):
        """ Kill a given instance """
        if PyObject_IsInstance(instance_, BindSprite):
            if PyObject_HasAttr(instance_, 'kill'):
                CRATER_RECT_LIST.remove(cls.rect)
                instance_.kill()


    cpdef update(self, args=None):
        cdef:
            obj              = self.obj
            int obj_center_x = self.obj_center_x
            int obj_center_y = self.obj_center_y
            int v1           = self.index // <unsigned char>10

        if self.dt > self.timing:

            if self.rect.colliderect(self.gl.screenrect):

                self.image = self.images_copy[self.index % self.length]

                if v1 < 100:
                    self.image = blend_to_textures_24c(self.image, CRATER, v1)

                # ADD BACKGROUND VELOCITY
                self.rect.center += self.gl.bv

                self.index += 1
                self.dt = 0
            else:
                CRATER_RECT_LIST.remove(self.rect)
                self.kill()

        self.dt += self.gl.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef float damped_oscillation(double t)nogil:
    return <float>(<float>exp(-t) * <float>cos(M_PI * t))


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class Halo(Sprite):

    cdef:
        object gl_, images_copy
        public object image, rect, _name
        tuple center
        int index
        float dt, timing
        public int _blend

    def __init__(self,
                 gl_,
                 containers_,
                 images_,
                 int x,
                 int y,
                 float timing_= <float>16.67,
                 int layer_   =-3,
                 int _blend   =0
                 ):

        """
        DISPLAY A COLORFUL HALO AFTER AN EXPLOSION

        *  The sprite will use the coordinates x, y at the time of the explosion

        :param gl_        : class; global variables / constants
        :param containers_: sprite group; Sprite group where this sprite belongs
        :param images_    : pygame.Surface; Surface(s) to use for this sprite
        :param x          : integer; coordinate x for the sprite center
        :param y          : integer; coordinate y for the sprite center
        :param timing_    : float; Cap max fps to 60fps 16.67 ms
        :param layer_     : integer; layer to use for this sprite
        :param _blend     : integer; Blend mode default None
        """

        Sprite.__init__(self, containers_)

        if PyObject_IsInstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        self.images_copy = images_ # .copy()
        self.image       = images_[0]
        self.center      = (x, y)
        self.rect        = self.image.get_rect(center=(x, y))
        self._blend      = _blend
        self.dt          = 0
        self.index       = 0
        self.gl          = gl_

        self.length1 = len(self.images_copy) - <unsigned char>1
        self._name = 'HALO'

    cpdef update(self, args=None):

        cdef:
            int index = self.index
            int length1   = self.length1

        if self.dt > self.timing:

            self.image = self.images_copy[index]
            self.rect  = self.image.get_rect(center=(self.center[0], self.center[1]))
            if index < length1:
                index += 1
            else:
                self.kill()
            self.dt = 0

        self.dt += self.gl.TIME_PASSED_SECONDS
        self.index = index


INVENTORY = []


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef void show_debris(gl_, float timing_=16.67):
    """
    UPDATE THE DEBRIS POSITION ON THE GAME DISPLAY 
    
    This method replace the sprite class update method (convenient hook)
    The function requires to be called from the main loop of your game every frames
    such as:
    
    if len(DEBRIS_CONTAINER) > 0:
            show_debris(GL)
            
    This function update the debris movement, it does not draw the 
    debris onto your game display. If the debris is still not moving 
    after inserting the above line of codes into your main loop, 
    ask yourself is the sprite belongs to Gl.All group?
    
    :param gl_    : Global variables/Constants 
    :param timing_: CAP max fps to 60
    :return: None
    """

    cdef:
        list debris_container = list(gl_.DEBRIS_CONTAINER)
        int w, h, w_, h_
        int debris_index
        float acceleration = 0
        float c

    for debris in debris_container:

        debris_image = debris.image
        debris_index = debris.index

        w  = debris_image.get_width()
        h  = debris_image.get_height()
        c  = <float>floor(debris_index / <float>20.0)
        w_ = <int>(w - c)
        h_ = <int>(h - c)
        if w > 1 and h >1:
            debris_image = scale(debris_image, (w_, h_))
        else:
            debris.kill()

        # ADJUST SPEED ACCORDING TO FPS
        if debris.dt >= timing_:
            acceleration = <float>1.0 / (<float>1.0 + <float>0.001 * debris_index * debris_index)
            debris.vector *= acceleration
            debris.dt = 0
            debris.index += 1
            debris.image = debris_image
            debris.rect.move_ip(debris.vector)

        debris.dt += gl_.TIME_PASSED_SECONDS

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class XBomb(Sprite):
    """
    XBOMB CLASS DEFINITION

    """

    cdef:
        public object rect, image, mask
        public int _blend, layer_
        object image_copy, vector, position
        int angle
        float index, timing, dt


    def __init__(self, gl_, int layer_, float timing_=16.67, bint collision_=True):
        """

        :param gl_        : instance; Contains all the variables / constants
        :param layer_     : integer; layer to display sprite.
        :param timing_    : float; FPS rate default is 60 fps
        :param collision_ : bool; Detect object collision at layer level (Bomb are triggered

         only when touching the ground)
        """

        Sprite.__init__(self, gl_.All)

        if isinstance(gl_.All, LayeredUpdates):
            gl_.All.change_layer(self, layer_)

        cdef:
            float angle_
            int x, y, angle_deg

        rect_            = gl_.player.rect
        x                = rect_.centerx
        y                = rect_.centery
        self._layer      = layer_

        angle_deg        = randRange(0, 359)
        self.image       = BOMB_ROTATE_BUFFER[angle_deg]

        self.image_copy  = self.image
        self.rect        = self.image.get_rect(center=(x, y))
        self.vector      = Vector2(COS_TABLE[angle_deg],
                                   -SIN_TABLE[angle_deg]) * randRangeFloat(<float>0.9, <float>4.2)
        self._blend      = 0
        self.position    = Vector2(x, y)
        self.index       = 0
        self.mask        = CRATER_MASK
        self.gl          = gl_
        self.dt          = 0

        # NUMBER OF DEBRIS AFTER EXPLOSION
        self.DEBRIS_NUMBER = 2
        self.collision     = collision_

        gl_.BOMB_CONTAINER_ADD(self)


    cdef void debris(self, int layer_=-2):
        """
        CREATE A SINGLE DEBRIS 
           
        The sprite will be assigned to two different sprite groups / list
        1) GL.All (containing all the sprite that will be update and draw from the main loop)
        2) GL.DEBRIS_CONTAINER containing only debris sprites that needs to be updated separately
         by show_debris
         
        If you are using GL.DEBRIS, add the following line of codes in your main loop
        
        if len(DEBRIS_CONTAINER) > 0:
            show_debris(GL)
            
        * and before draw
        GL.All.draw(SCREEN)
             
        :param layer_: integer; Layer to use for this sprite
        :return: void 
        """

        # VAR DECLARATION AND TWEAKS
        cdef:
            int x = self.rect.centerx
            int y = self.rect.centery
            gl_All = self.gl.All

        # CREATE A SPRITE
        debris_sprite = Sprite()

        # ADD THE SPRITE TO GL.ALL (UPDATE FROM MAIN LOOP)
        # IN ORDER TO SEE YOU SPRITE MOVING (GL.All WILL DRAW
        # THE SPRITE)
        self.gl.All.add(debris_sprite)

        if isinstance(gl_All, LayeredUpdates):
            gl_All.change_layer(debris_sprite, layer_)

        cdef:
            int w, h

        # POPULATE SPRITE
        debris_sprite._layer   = layer_
        image                  = EXPLOSION_DEBRIS[
            randRange(0, len(EXPLOSION_DEBRIS) - <unsigned char>1)]
        debris_sprite.position = Vector2(x, y)
        w                      = image.get_width()
        h                      = image.get_height()
        debris_sprite._blend   = BLEND_RGB_ADD

        # RANDOM DEBRIS SIZE
        debris_sprite.image    = scale(image, (<int>(w * <float>randRangeFloat(<float>0.1, <float>0.3)),
                                               <int>(h * <float>randRangeFloat(<float>0.1, <float>0.3))))
        debris_sprite.rect     = debris_sprite.image.get_rect(center=(x, y))
        # UNIQUE ANGLE AND VELOCITY
        debris_sprite.vector   = Vector2(<float>randRangeFloat(-<float>15.0, <float>15.0),
                                         <float>randRangeFloat(-<float>15.0, <float>15.0))
        debris_sprite.index    = 0
        debris_sprite.dt       = 0
        debris_sprite.name     = id(debris_sprite)

        # ADD THE SPRITE TO A SEPARATE GROUP DEBRIS_CONTAINER
        self.gl.DEBRIS_CONTAINER_ADD(debris_sprite)



    # cdef bint full_merge( right, left):
    #     """
    #     RETURN TRUE WHEN BOTH SPRITES FULLY OVERLAP
    #
    #     :param right: pygame.Sprite; right sprite
    #     :param left : pygame.Sprite; left sprite
    #     :return: bool; True | False
    #     """
    #     cdef int xoffset = right.rect[0] - left.rect[0]
    #     cdef int yoffset = right.rect[1] - left.rect[1]
    #     r_mask = left.mask.overlap_mask(right.mask, (xoffset, yoffset))
    #     if r_mask.count() == CRATER_MASK_COUNT:
    #         return True
    #     else:
    #         return False

    cdef bint bomb_collision(self):
        """
        CHECK BOMB COLLISION WITH THE GROUND 
        
        NOTE: This method is called when the sprite surface 
        width and height (self.image) are < 1.0
        
        :return: True | False
        """

        crater_sprite       = Sprite()
        crater_sprite.image = CRATER
        crater_sprite.mask  = CRATER_MASK

        gl_                 = self.gl
        center_x            = self.rect.centerx
        center_y            = self.rect.centery
        crater_sprite.rect  = CRATER.get_rect(center=(center_x, center_y))

        cdef:
            list sprites_at_drop_position
            gl_All                  = gl_.All
            get_sprites_at          = gl_All.get_sprites_at
            int w, h
            crater_sprite_rect      = crater_sprite.rect
            list ground_level_group = []
            int ground_layer        = -7

        # RETURN A LIST WITH ALL SPRITES AT THAT POSITION
        # LAYEREDUPDATES.GET_SPRITES_AT(POS): RETURN COLLIDING_SPRITES
        # BOTTOM SPRITES ARE LISTED FIRST; THE TOP ONES ARE LISTED LAST.
        sprites_at_drop_position = get_sprites_at(crater_sprite.rect.center)

        for sp in sprites_at_drop_position:

            if not PyObject_HasAttr(sp, '_layer'):
                continue

            if sp._layer != ground_layer:
                continue
            else:
                ground_level_group.append(sp)

        # w, h = crater_sprite.rect.size

        if len(ground_level_group) > 0:

            for spr in ground_level_group:

                # ONLY PLATFORM 0 AND PLATFORM 7 HAVE A MASK OTHER BACKGROUND SPRITE DOES NOT
                # OTHER BACKGROUND HAVE A PLAN SURFACE
                if PyObject_HasAttr(spr, 'mask') and spr.mask is not None:
                    # Tests for collision between two sprites by testing if their bitmasks
                    # overlap. If the sprites have a "mask" attribute, that is used as the mask;
                    # otherwise, a mask is created from the sprite image. Intended to be passed
                    # as a collided callback function to the *collide functions. Sprites must
                    # have a "rect" and an optional "mask" attribute.

                    if collide_mask(spr, crater_sprite):

                       return full_merge(spr, crater_sprite)

                else:
                    return True

        return False


    cpdef update(self, args=None):
        """
        UPDATE METHOD FOR SPRITE BOMB 
        
        This method is called every frame from the main loop. 
        Sprite refreshing time will be equal to self.timing value.
        The sprite is destroyed as soon has it gets outside the display 
        limits (checking for rectangle collision). 
        - method bomb_collision Check for collision with the ground. 
        - BindSprite create a single instance of an explosion 
        - Halo create a single instance 
        - Create 5 debris after collision with the ground 
        * If no collision with the ground is detected the bomb will continue 
        its descent and eventually be destroyed when its surface width and height 
        get <1 
        
        NOTE: 
            Debris are placed into a separate sprite container (GL.DEBRIS_CONTAINER)
        
        :param args: None 
        :return: None 
        """

        # VAR DECLARATION AND TWEAKS
        cdef:
            gl                  = self.gl
            list bomb_container = list(gl.BOMB_CONTAINER)
            screenrect          = gl.screenrect
            int w, h, center_x, center_y
            int w_, h_
            float vector_x, vector_y
            int length1         = len(GROUND_EXPLOSION) - <unsigned char>1
            int length2         = len(EXPLOSIONS) - <unsigned char>1
            int r

        # LIMIT THE FPS
        if self.dt > self.timing:

            # CHECK BOUNDARIES
            if self.rect.colliderect(screenrect):

                # TWEAKS
                sprite_bomb_image_copy = self.image_copy
                center_x               = self.rect.centerx
                center_y               = self.rect.centery
                vector_x               = self.vector.x
                vector_y               = self.vector.y

                # RECT SIZE KEEPS CHANGING
                self.rect = self.image.get_rect(center=self.position)

                w = sprite_bomb_image_copy.get_width()
                h = sprite_bomb_image_copy.get_height()
                w_ = <int>(round(w - self.index))
                h_ = <int>(round(h - self.index))

                # SCALE DOES NOT RETURN AN EXCEPTION WHEN SIZES IS <= 0
                if w_ > 1.0 and h_ > 1.0:
                    self.image = scale(sprite_bomb_image_copy, (w_, h_))
                else:

                    # CHECK COLLISION WITH THE GROUND TRUE | FALSE
                    if self.collision:
                        if not self.bomb_collision():
                            self.kill()
                            return

                    # ALLOW SCREEN DAMPENING (SCREEN SHACKING)
                    gl.SHOCKWAVE = True

                    BindSprite(
                               EXPLOSIONS[randRange(0, length2)],
                               self,
                               gl,
                               timing_    = <float>16.67,
                               layer_     = -3,
                               blend_     = BLEND_RGB_ADD
                               )

                    # IF NO COLLISIONS ARE FOUND AN INDEX OF -1 IS RETURNED.
                    # AVOID RECT COLLISION (CRATERS ON TOP OF EACH OTHERS)
                    if self.rect.collidelist(CRATER_RECT_LIST) == -1:
                        BindToBackground(
                            [HOTFURNACE2,HOTFURNACE][randRange(0, 1)],
                            self,
                            gl,
                            timing_= <float>16.67,
                            layer_= -6,
                            blend_= BLEND_RGB_ADD,
                            loop_ = True
                        )

                    # LIGHT EFFECT
                    Halo(gl, gl.All, LIGHT.copy(), center_x,
                         center_y, <float>16.67, layer_=-4, _blend=BLEND_RGB_ADD)

                    # CREATE A LIGHT EFFECT (PLASMA)
                    # if randRange(<int>0, <int>100) > 95:
                    #     LightEngineBomb(gl, self, RADIAL4_ARRAY_256x256, None,
                    #                 intensity_  = <float>16.0,
                    #                 color_      = numpy.array(
                    #                     [<float>203.0 / <float>255.0,
                    #                      <float>119.0 / <float>255.0,
                    #                      <float>27.0 / <float>255.0],
                    #                     float32, copy=False),
                    #                 smooth_     = False,
                    #                 saturation_ = False,
                    #                 sat_value_  = <float>1.0,
                    #                 bloom_      = False,
                    #                 heat_       = False,
                    #                 frequency_  = <float>1.0,
                    #                 blend_      = BLEND_RGB_ADD,
                    #                 timing_     = self.timing,
                    #                 time_to_live_ = 100,
                    #                 fast_       = False
                    #     )


                    # EXPLOSION SOUND (STEREO MODE)
                    gl.SC_explosion.play(
                        sound_      = GROUND_EXPLOSION[randRange(0, length1)],
                        loop_       = False,
                        priority_   = 0,
                        volume_     = gl.SOUND_LEVEL,
                        fade_out_ms = 0,
                        panning_    = True,
                        name_       = 'BOOM',
                        x_          = center_x)

                    # A BOMB INSTANCE WILL CREATE 5 DEBRIS AFTER EXPLOSION
                    for r in range(self.DEBRIS_NUMBER):
                        self.debris(layer_=-6)

                    # CREATE A SINGLE INSTANCE (HALO)
                    # HALO IS A SPRITE CLASS AND WILL BE UPDATED FROM THE MAIN
                    # LOOP.IF SELF IS KILLED, THE HALO SPRITE WILL STILL BE UPDATED)
                    Halo(gl, gl.All, [HALO_SPRITE11, HALO_SPRITE13][randRange(0, 1)],
                         center_x, center_y, <float>16.67, layer_=-4, _blend=0)

                    self.kill()


                self.rect.move_ip(vector_x, vector_y)
                self.position.x += vector_x
                self.position.y += vector_y

                self.index += randRangeFloat(<float>0.15, <float>0.16)

            # SPRITE OUTSIDE THE SCREEN
            else:
                self.kill()

            self.dt = 0

        self.dt += gl.TIME_PASSED_SECONDS