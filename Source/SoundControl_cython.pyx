# encoding: utf-8
"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """

import pygame
import time as time_t
from Constants import SCREENRECT


if not pygame.mixer.get_init():
    pygame.mixer.pre_init(44100, 16, 2, 4096)
    pygame.init()


class SoundObject:

    # Sound object constructor
    def __init__(self, sound_= None, priority_= 0,
                 name_= None, channel_=None, obj_id_= None):
        """
        Define a sound object with specific attributes
        :param sound_: Sound object loaded with pygame.mixer.Sound method
        :param priority_: define a priority for the sound (low : 0. med : 1, high : 2)
        :param name_: String representing the sound name
        :param channel_: Channel number used for playing the sound
        :param obj_id_: unique object id
        """

        # assert isinstance(sound_, pygame.mixer.Sound), \
        #    'Expecting pygame sound object, got %s ' % type(sound_)
        self.sound = sound_

        # assert isinstance(priority_, int), 'Expecting int got %s ' + \
        #                                    str(type(priority_))
        self.priority = priority_ if 0 < priority_ < 2 else 0

        self.time = time_t.time()
        # assert isinstance(name_, (str, type(None))), \
        #    'Expecting string, got %s ' % type(name_)
        self.name = name_

        # length in seconds
        self.length = sound_.get_length()

        # self.active_channel represent the numeric value
        # of the channel playing the sound
        self.active_channel = channel_

        # sound id number
        self.id = id(self)
        # Object id number.
        # very useful for killing a specific sound
        # when the object id number is known
        self.obj_id = obj_id_


class SoundControl:

    # SoundControl constructor
    def __init__(self, channel_num_=8):

        # assert isinstance(channel_num_, int), \
        #     'Expecting integer, got %s ' % type(channel_num_)

        self.channel_num = channel_num_
        reserved_channel = pygame.mixer.get_num_channels()

        self.start = reserved_channel
        self.end = self.channel_num + reserved_channel

        pygame.mixer.set_num_channels(self.end)
        pygame.mixer.set_reserved(self.end)

        # list of all reserved channels,
        # create a stack
        self.channels = [pygame.mixer.Channel(j_ + self.start)
                         for j_ in range(self.channel_num)]

        # initialised all SoundObject.
        # Create an empty list for now
        self.snd_obj = [None] * self.channel_num

        # Channel index point to the origin of the stack
        self.channel = self.start

        # create a list of all channel number
        self.all = list(range(self.start, self.end))

    def update(self):
        """ update the list of sound objects.
            iterate through all the channels to check
            if the sound still active or not and update the list
            accordingly with a marker : None for not active
        """
        i_ = 0
        # iterate over all channels
        for channels in self.channels:
            # check if a sound is active
            if not channels.get_busy():
                self.snd_obj[i_] = None
            i_ += 1

    def show_free_channels(self) -> list:
        """ return a list of free channels.
            Only the numeric value of the free channel
            is return.
        """
        free = []
        i_ = 0
        for channels in self.channels:
            if not channels.get_busy():
                free.append(i_ + self.start)
            i_ += 1
        return free

    def show_sounds_playing(self):
        """
        Display all sounds objects
        """
        j_ = 0
        for object_ in self.snd_obj:
            if object_ is not None:
                print('Name :', object_.name, 'id ', object_.id, ' priority ', object_.priority,
                      ' channel ', object_.active_channel, ' length ', round(object_.length, 2),
                      ' time left : ', round(self.snd_obj[j_].length - (time_t.time() - self.snd_obj[j_].time), 2))
            j_ += 1

    def get_identical_sounds(self, sound: pygame.mixer.Sound) -> list:
        """ Return a list of channel(s) where identical sounds are being played.
         """
        # assert isinstance(sound, pygame.mixer.Sound), \
        #     'Expecting sound object, got %s ' % type(sound)
        list_ = []
        for obj in self.snd_obj:
            if obj is not None:
                if obj.sound == sound:
                    list_.append(obj.active_channel)
        return list_

    def stop(self, list_: list):
        """ stop sound(s) from a given list of channel(s).
            Any sound object with a priority above 0 will be spare.
         """
        # assert isinstance(list_, list), 'Expecting list got %s ' % type(list_)
        for channels_ in list_:
                if self.snd_obj[channels_ - self.start].priority == 0:
                    self.channels[channels_ - self.start].stop()
        self.update()

    def stop_all_except(self, exception= None):
        """ stop all sound except sounds from a given list of id(object) """
        # assert isinstance(exception, (list, int, type(None))), \
        #     'Expecting (list, int or None) for argument exception, got %s ' % type(exception)

        if exception is None:
            return

        exception = [exception] if isinstance(exception, int) else exception

        for channels_ in self.all:
            snd_object = self.snd_obj[channels_ - self.start]
            if snd_object is not None:
                if snd_object.obj_id not in exception:
                    self.channels[channels_ - self.start].stop()
        self.update()

    def stop_name(self, name_: str):
        """ stop a given sound name (Sound object). """
        # assert isinstance(name_, str), 'Expecting string got %s ' % type(name_)
        for sound in self.snd_obj:
            if sound is not None and sound.name == name_:
                self.channels[sound.active_channel - self.start].stop()
        self.update()

    def stop_object(self, object_id):
        """ stop a given sound using the object id number. """
        # assert isinstance(object_id, int), \
        #    'Expecting int for argument object_id got %s ' % type(object_id)
        for sound in self.snd_obj:
            if sound is not None and sound.obj_id == object_id:
                self.channels[sound.active_channel - self.start].stop()
        self.update()

    def show_time_left(self, object_id: int) -> float:
        """ show time left to play for a specific sound
        :param object_id: identification like e.g id(self)
        :return: a float representing the time left in seconds.
        """
        j = 0
        for obj in self.snd_obj:
            if obj is not None:
                # print(obj.name)
                # print('object_.obj_id ', obj.obj_id, ' == ', object_id)
                if obj.obj_id == object_id:
                    return round(self.snd_obj[j].length - (time_t.time() - self.snd_obj[j].time), 2)
            j += 1
        # did not found the object into the list
        # Sound probably killed, finished or wrong
        # object_id number.
        return 0.0

    @property
    def channel(self):
        return self.__channel

    @channel.setter
    def channel(self, channel):
        if channel > self.end - 1:
            self.__channel = self.start
        else:
            self.__channel = channel

    # Return the current channel.
    def get_channel(self):
        return self.channel

    # user can override the automatic indexing system
    # by selecting manually the next channel.
    def set_channel(self, channel):
        # assert isinstance(channel, int), \
        #    'Expecting python int got %s: ' % str(type(channel))
        if channel > self.end:
            print('\n[-] Channel %s is not reserved.' % channel)
            return
        self.channel = channel

    def get_reserved_channels(self) -> int:
        """ return the total number of reserved channels """
        return self.channel_num

    def get_reserved_start(self) -> int:
        """ return the first reserved channel number """
        return self.start

    def get_reserved_end(self) -> int:
        """ return the last reserved channel number """
        return self.end

    def get_channels(self) -> list:
        """ return a list of all reserved
            mixer channels. Contains also all
            the sound object currently attached to
            the list.
        """
        return self.channels

    def get_sound(self, channel_: int) -> pygame.mixer.Sound:
        """ return a sound being played on a specific channel
            (pygame.mixer.Channel)
            channel_ is an integer representing the channel
            number. see also self.start and self.end to see
            the exact channel range.
        """
        # assert isinstance(channel_, int), \
        #    'Expecting integer, got %s ' % type(channel_)
        try:
            sound = self.channels[channel_]
        except IndexError:
            raise Exception('Incorrect channel number. ')
        else:
            return sound

    def get_sound_object(self, channel_: int):
        """ return a specific sound object (SoundObject) """
        # assert isinstance(channel_, int), \
        #    'Expecting integer, got %s ' % type(channel_)
        return self.snd_obj[channel_]

    def get_all_sound_object(self) -> list:
        """ return all sound objects """
        return self.snd_obj

    def play(self, sound_: pygame.mixer.Sound, loop_= False, priority_= 0, volume_= 1,
             fade_out_ms= 0, panning_=False, name_= None,
             x_= SCREENRECT.centerx, object_id_= None):
        """
        :type loop_: bool
        :param sound_: pygame mixer sound object
        :param loop_:  boolean for looping sound or not (True : loop)
        :param priority_: Set the sound priority (low : 0, med : 1, high : 2)
        :param volume_:   Set the sound volume 0 to 1 (1 being full volume)
        :param fade_out_ms: Fade out sound effect in ms
        :param panning_: boolean for using panning method or not (stereo mode)
        :param name_: String representing the sound name
        :param x_:  Position for panning a sound,
        :param object_id_: unique object id
        """
        """
        assert isinstance(sound_, pygame.mixer.Sound), 'Expecting sound object ' \
                                                       'for argument sound_got %s ' % type(sound_)
        assert isinstance(loop_, bool), 'Expecting boolean for argument loop_ got %s ' % type(loop_)
        assert isinstance(priority_, int), 'Expecting int for argument priority got %s ' % type(priority_)
        assert isinstance(volume_, (float, int)), 'Expecting float or int for argument volume_ got %s ' % type(volume_)
        assert isinstance(fade_out_ms, (float, int)), 'Expecting float or int for argument ' \
                                                      'fade_out_ms got %s ' % type(fade_out_ms)
        assert isinstance(panning_, bool), 'Expecting bool for argument panning_ got %s ' % type(panning_)
        assert isinstance(name_, (str, type(None))), 'Expecting string or NoneType for ' \
                                                     'argument name_ got %s ' % type(name_)
        assert isinstance(x_, int), 'Expecting int for argument x_ got %s ' % type(x_)
        assert isinstance(object_id_, (int, type(None))), \
            'Expecting int for argument object_id_ got %s ' % type(object_id_)
        """
        try:
            # check if the current channel is busy.
            # if not play the given sound. <sound_>
            if self.channels[self.channel - self.start].get_busy() == 0:

                self.channels[self.channel - self.start].play(
                    sound_, loops=-1 if loop_ else 0, maxtime=0, fade_ms=fade_out_ms)

                self.channels[self.channel - self.start].set_volume(volume_)
                self.snd_obj[self.channel - self.start] \
                    = SoundObject(sound_, priority_, name_, self.channel, object_id_)

                # play a sound in stereo
                if panning_:
                    self.channels[self.channel - self.start].set_volume(
                        self.stereo_panning(x_)[0] * volume_, self.stereo_panning(x_)[1] * volume_)

                # prepare the mixer for the next channel
                self.channel += 1

                # return the channel number where the sound is
                # currently playing.
                return self.channel - 1

            # All channels busy
            else:
                # print('Stopping duplicate sound on channel(s) %s %s ' % (self.get_identical_sounds(sound_), name_))
                self.stop(self.get_identical_sounds(sound_))
                # very important, go to next channel.
                self.channel += 1
                return None

        except IndexError as e:
            print('\n[-] SoundControl error : %s ' % e)

    @staticmethod
    def stereo_panning(x_):
        # assert isinstance(x_, (float, int)), 'Expecting float got %s ' % type(x_)
        right_volume = float(x_) / SCREENRECT.w
        left_volume = 1 - right_volume
        return left_volume, right_volume

