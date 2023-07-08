# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True, profile=False
# encoding: utf-8


import pygame
from pygame import mixer

from libc.math cimport round

try:
    cimport cython
    from cpython.list cimport PyList_Append, PyList_GetItem, PyList_Size, PyList_SetItem
    from cpython.object cimport PyObject_SetAttr
    from cpython cimport PyObject, PyObject_HasAttr, PyObject_IsInstance
    from cpython cimport array
except ImportError:
    raise ImportError("\n<cython> library is missing on your system."
          "\nTry: \n   C:\\pip install cython on a window command prompt.")

from time import time

cdef struct stereo:
   float left;
   float right;



if not mixer.get_init():
    mixer.pre_init(44100, 16, 2, 4096)
    pygame.init()

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class SoundObject(object):

    cdef:
        public sound
        public int priority, length, active_channel
        public long int time,
        public str name
        public long long int obj_id, id

    # Sound player constructor
    def __init__(self, sound_, int priority_, str name_, int channel_, long long int obj_id_):
        """
        CREATE A SOUND OBJECT CONTAINING CERTAIN ATTRIBUTES (SEE THE
        COMPLETE LIST BELOW)

        :param sound_   : Sound object; Sound object to play
        :param priority_: integer; Sound width in seconds
        :param name_    : string; Sound given name
        :param channel_ : integer; Channel to use
        :param obj_id_  : python int (C long long int); Sound unique ID
        """

        # SOUND OBJECT TO PLAY
        self.sound = sound_
        # RETURN THE LENGTH OF THIS SOUND IN SECONDS
        self.length = sound_.get_length()
        # SOUND PRIORITY - LOWEST TO HIGHEST (0 - 2)
        self.priority = priority_ if 0 < priority_ < 2 else 0
        # TIMESTAMP
        self.time = time()
        # SOUND NAME FOR IDENTIFICATION
        self.name = name_
        # CHANNEL USED
        self.active_channel = channel_
        # UNIQUE SOUND ID NUMBER
        self.obj_id = obj_id_
        # CLASS ID
        self.id = id(self)

@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class SoundControl(object):

    cdef:
        public int channel_num, start, end, channel
        public list channels, snd_obj, all
        public screen_size


    def __init__(self, screen_size_, int channel_num_=8):

        # CHANNEL TO INIT
        self.channel_num = channel_num_
        # GET THE TOTAL NUMBER OF PLAYBACK CHANNELS
        # FIRST CHANNEL
        self.start = mixer.get_num_channels()
        # LAST CHANNEL
        self.end = self.channel_num + self.start
        # SETS THE NUMBER OF AVAILABLE CHANNELS FOR THE MIXER.
        mixer.set_num_channels(self.end)

        # RESERVE CHANNELS FROM BEING AUTOMATICALLY USED
        mixer.set_reserved(self.end)

        # CREATE A CHANNEL OBJECT FOR CONTROLLING PLAYBACK
        cdef int j
        self.channels = [mixer.Channel(j + self.start) for j in range(self.channel_num)]

        # LIST OF UN-INITIALISED OBJECTS
        self.snd_obj = [None] * self.channel_num

        # POINTER TO THE BOTTOM OF THE STACK
        self.channel = self.start

        # CREATE A LIST WITH ALL CHANNEL NUMBER
        self.all = list(range(self.start, self.end))

        self.screen_size = screen_size_

    cpdef void update(self):
        """ 
        CLEAR THE LIST SND_OBJ WHEN THE 
        CHANNEL IS NOT BUSY (SOUND PLAYED)  
        """
        cdef:
            int i = 0
            snd_obj = self.snd_obj

        for c in self.channels:
            if c:
                if not c.get_busy():
                    snd_obj[i] = None
            i += 1

    cpdef void update_volume(self, float volume_=1.0):
        """
        UPDATE ALL SOUND OBJECT TO A SPECIFIC VOLUME.
        THIS HAS IMMEDIATE EFFECT AND DO NOT FADE THE SOUND      
        
        :param volume_: float; volume value, default is 1.0
        :return: None 
        """
        # SET THE VOLUME IN CASE OF AN INPUT ERROR
        if <float>0.0 >= volume_ >= <float>1.0:
            volume_ = <float>1.0
        # SET THE VOLUME FOR ALL SOUNDS
        for c in self.channels:
            c.set_volume(volume_)

    cpdef list show_free_channels(self):
        """
        RETURN A LIST OF FREE CHANNELS (NUMERICAL VALUES). 
        :return: list; RETURN A LIST 
        """
        cdef:
            list free_channels = []
            int i = 0
            free_channels_append = free_channels.append
            start = self.start

        for c in self.channels:
            if not c.get_busy():
                free_channels_append(i + start)
            i += 1

        return free_channels

    cpdef void show_sounds_playing(self):
        """
        DISPLAY ALL SOUNDS OBJECTS
        """
        cdef:
            int j = 0
            snd_obj = self.snd_obj

        j = 0
        for object_ in self.snd_obj:
            if object_:
                print('\nName %s  id %s priority %s  channel %s width %s time left %s ' %
                      (object_.name, object_.priority, object_.active_channel, <float>round(object_.length),
                 <float>round(snd_obj.length - (time() - snd_obj.time))))
            j += 1

    cpdef list get_identical_sounds(self, sound):
        """ 
        RETURN A LIST OF CHANNEL(S) PLAYING IDENTICAL SOUND OBJECT(s)
        
        :param sound: Mixer object; Object to compare to 
        :return: python list; List containing channels number 
        playing similar sound object
        """
        cdef:
            list duplicate = []
            duplicate_append = duplicate.append

        for obj in self.snd_obj:
            if obj:
                if obj.sound == sound:
                    duplicate_append(obj.active_channel)
        return duplicate

    cpdef list get_identical_id(self, long long int id_):
        """ 
        RETURN A LIST CONTAINING ANY IDENTICAL SOUND BEING MIXED.
        USE THE UNIQUE ID FOR REFERENCING OBJECTS
        
        :param id_: python integer; unique id number that reference a sound object
        :return: list; Return a list of channels containing identical sound object
        """
        cdef:
            list duplicate = []
            duplicate_append = duplicate.append

        for obj in self.snd_obj:
            if obj:
                if obj.obj_id == id_:
                    duplicate_append(obj)
        return duplicate

    cpdef void stop(self, list stop_list):
        """ 
        STOP ALL SOUND BEING PLAYED ON THE GIVEN LIST OF CHANNELS.
        ONLY SOUND WITH PRIORITY LEVEL 0 CAN BE STOPPED.
        
        :param stop_list: python list; list of channels 
        :return: None
        """
        cdef:
            int c, l
            int start = self.start
            snd_obj = self.snd_obj
            channels = self.channels

        for c in stop_list:
                l = c - start
                if <object>PyList_GetItem(snd_obj, l):
                    if snd_obj[l].priority == 0:
                        channels[l].stop()
        self.update()

    cpdef void stop_all_except(self, exception=None):
        """ 
        STOP ALL SOUND OBJECT EXCEPT SOUNDS FROM A GIVEN LIST OF ID(SOUND)
        IT WILL STOP SOUND PLAYING ON ALL CHANNELS REGARDLESS
        OF THEIR PRIORITY.
        
        :exception: Can be a single pygame.Sound id value or a list containing
        all pygame.Sound object id numbers.     
        """
        # EXCEPTION MUST BE DEFINED
        if exception is None:
            raise ValueError("\nArgument exception is not defined.")

        if not PyObject_IsInstance(exception, list):
            exception = [exception]
        cdef:
            int l, c
            int start = self.start
            snd_obj = self.snd_obj
            channels = self.channels

        for c in self.all:
            l = c - start
            snd_object = <object>PyList_GetItem(snd_obj, l)  # snd_obj[l]
            if snd_object:
                if snd_object.obj_id not in exception:
                    channels[l].stop()
        self.update()

    cpdef void stop_all(self):
        """ STOP ALL SOUNDS NO EXCEPTIONS."""
        cdef:
            int c, l
            int start = self.start
            snd_obj = self.snd_obj
            channels = self.channels

        for c in self.all:
            l = c - start
            snd_object = <object>PyList_GetItem(snd_obj, l)  # snd_obj[l]
            if snd_object:
                channels[l].stop()
        self.update()

    cpdef void stop_name(self, str name_):
        """ 
        STOP A PYGAME.SOUND OBJECT IF PLAYING ON ANY OF THE CHANNELS.
        NAME_ REFER TO THE NAME GIVEN TO THE SOUND WHEN INSTANTIATED (E.G 'WHOOSH' NAME BELOW)
        GL.MIXER_PLAYER.PLAY(SOUND_=WHOOSH, LOOP_=FALSE, PRIORITY_=0, VOLUME_=GL.SOUND_LEVEL,
                FADE_OUT_MS=0, PANNING_=FALSE, NAME_='WHOOSH', X_=0)
        """
        cdef:
            channels = self.channels
            int start = self.start

        for sound in self.snd_obj:
            if sound and sound.name == name_:
                try:
                    channels[sound.active_channel - start].stop()
                except IndexError:
                    # IGNORE ERROR
                    ...
        self.update()

    cpdef void stop_object(self, long long int object_id):
        """ STOP A GIVEN SOUND USING THE PYGAME.SOUND OBJECT ID NUMBER. """
        cdef:
            channels = self.channels
            int start = self.start

        for sound in self.snd_obj:
            if sound and sound.obj_id == object_id:
                try:
                    channels[sound.active_channel - start].stop()
                except IndexError:
                    # IGNORE ERROR
                    ...

        self.update()

    cpdef float show_time_left(self, long long int object_id):
        """ 
        RETURN THE TIME LEFT
        :param object_id: python integer; unique object id
        :return: a float representing the time left in seconds.
        """
        cdef:
            int j = 0
            snd_obj = self.snd_obj
        for obj in snd_obj:
            if obj:
                if obj.obj_id == object_id:
                    return <float>round(snd_obj[j].length - (time() - snd_obj[j].time))
            j += 1
        return 0.0

    cpdef int get_reserved_channels(self):
        """ RETURN THE NUMBER OF RESERVED CHANNELS """
        return self.channel_num

    cpdef int get_reserved_start(self):
        """ RETURN THE FIRST RESERVED CHANNEL NUMBER """
        return self.start

    cpdef int get_reserved_end(self):
        """ RETURN THE LAST RESERVED CHANNEL NUMBER """
        return self.end

    cpdef list get_channels(self):
        """ 
        RETURN A LIST OF ALL RESERVED PYGAME MIXER CHANNELS.
        """
        return self.channels

    cpdef get_sound(self, int channel_):
        """ 
        RETURN THE SOUND BEING PLAYED ON A SPECIFIC CHANNEL (PYGAME.MIXER.CHANNEL)
        
        :param channel_: integer;  channel_ is an integer representing the channel number.
        """
        try:
            sound = self.channels[channel_]
        except IndexError:
            raise Exception('\nIndexError: Channel number out of range ')
        else:
            return sound

    cpdef get_sound_object(self, int channel_):
        """ 
        RETURN A SPECIFIC SOUND OBJECT 
        RETURN NONE IN CASE OF AN INDEX ERROR
        """
        try:
            s = <object>PyList_GetItem(self.snd_obj, channel_)
        except IndexError:
            return None
        else:
            return s

    cpdef list get_all_sound_object(self):
        """ RETURN ALL SOUND OBJECTS """
        return self.snd_obj

    cpdef play(self, sound_, int loop_, int priority_=0, float volume_=1.0,
             float fade_out_ms=0.0, bint panning_=False, name_=None,
             x_=None, object_id_=None):

        """
        PLAY A SOUND OBJECT ON THE GIVEN CHANNEL 
        RETURN NONE IF ALL CHANNELS ARE BUSY OR IF AN EXCEPTION IS RAISED
        
        :param sound_       : pygame mixer sound 
        :param loop_        : loop the sound indefinitely -1
        :param priority_    : Set the sound priority (low : 0, med : 1, high : 2)
        :param volume_      : Set the sound volume 0.0 to 1.0 (100% full volume)
        :param fade_out_ms  : Fade out sound effect in ms
        :param panning_     : boolean for using panning method (stereo mode)
        :param name_        : String representing the sound name
        :param x_           : Sound position for stereo mode,
        :param object_id_   : unique sound id
        """

        cdef:
            int l = 0
            list channels = self.channels
            int channel  = self.channel
            int start    = self.start
            int end      = self.end
            int screen_width = self.screen_size.w

        cdef stereo st;

        try:
            if not sound_:
                raise AttributeError('\nArgument sound_ cannot be None')

            if x_ is None:
                x_ = screen_width >> 1

            x_ = min(x_, screen_width)
            x_ = max(x_, 0)

            if name_ is None:
                name_ = str(id(sound_))

            if object_id_ is None:
                object_id_ = id(sound_)

            l = channel - start
            # TODO OVERFLOW CHANNELS[l]
            # CHECK IF CURRENT CHANNEL IS BUSY
            if channels[l].get_busy() == 0:

                # AS IN SOUND.PLAY(), THE FADE_MS ARGUMENT CAN BE USED FADE IN THE SOUND.
                channels[l].play(sound_, loops=loop_, maxtime=0, fade_ms=<int>fade_out_ms)


                # PLAY A SOUND IN STEREO MODE
                if panning_:
                    st = self.stereo_panning(x_, self.screen_size.w, volume_)

                    channels[l].set_volume(st.left, st.right)
                else:
                    # IF THE CHANNEL IS PLAYING A SOUND ON WHICH SET_VOLUME() HAS ALSO BEEN CALLED,
                    # BOTH CALLS ARE TAKEN INTO ACCOUNT.
                    channels[l].set_volume(volume_)

                self.snd_obj[l] = SoundObject(sound_, priority_, name_, channel, object_id_)

                # PREPARE THE MIXER FOR THE NEXT CHANNEL
                self.channel += <unsigned char>1

                if self.channel > end - <unsigned char>1:
                    self.channel = start

                # RETURN THE CHANNEL NUMBER PLAYING THE SOUND OBJECT
                return channel - <unsigned char>1

            # ALL CHANNELS ARE BUSY
            else:
                self.stop(self.get_identical_sounds(sound_))
                # VERY IMPORTANT, GO TO NEXT CHANNEL.
                self.channel += 1
                if self.channel > end - <unsigned char>1:
                    self.channel = start
                return None

        except IndexError as e:
            print('\n[-] SoundControl error : %s ' % e)
            print(self.channel, l)
            return None

    cpdef void display_size_update(self, rect_):
        """
        UPDATE THE SCREEN SIZE AFTER CHANGING MODE
        THIS FUNCTION IS MAINLY USED FOR THE PANNING MODE (STEREO) 
        :param rect_: pygame.Rect; display dimension 
        :return: None
        """
        self.screen_size = rect_

    cdef inline stereo stereo_panning(self, int x_, int screen_width, float volume_)nogil:
        """
        STEREO MODE 
        
        :param screen_width: display width 
        :param x_: integer; x value of sprite position on screen  
        :param volume_: float; sound volume float in range [0.0 ... 1.0]
        :return: tuple of float; 
        """
        cdef:
            float right_volume=0.0, left_volume=0.0

        cdef stereo st
        st.left  = <float>0.0
        st.right = <float>0.0

        # MUTE THE SOUND IF OUTSIDE THE BOUNDARIES
        if x_ < 0 or x_ > screen_width:
            return st

        right_volume = float(x_) / <float>screen_width
        left_volume = <float>1.0 - right_volume

        st.left  = left_volume * volume_
        st.right = right_volume * volume_
        return st

