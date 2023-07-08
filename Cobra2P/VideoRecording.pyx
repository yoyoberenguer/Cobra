#cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True
# encoding: utf-8

import numpy
import pygame
from numpy import uint8 # , empty, asarray
# from pygame.image import frombuffer
from pygame.transform import rotozoom, smoothscale
from pygame import freetype, Surface, K_ESCAPE
import os
import lz4.frame as lz4frame
# import time
# import wave
# import threading
# import pyaudio
#
# _CUPY = True
# try:
#     import cupy as cp
# except:
#     _CUPY=False



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

try:
    import cv2
    from cv2 import COLOR_RGBA2BGR, cvtColor
except ImportError:
    raise ImportError("\nLibrary OpenCv is missing from your system"
                      "\nPlease try C:pip install opencv-python")


LEVEL_ICON = pygame.image.load('Assets/Graphics/GUI/device/switchGreen04.png').convert_alpha()
LEVEL_ICON = rotozoom(LEVEL_ICON, 90, 0.7)

VIDEO_ICON = pygame.image.load('Assets/Graphics/Icon/video1.png').convert_alpha()
VIDEO_ICON = smoothscale(VIDEO_ICON, (64, 64))

#
#
# cdef class AudioRecorder(object):
#
#     cdef:
#         object open, format, audio, stream
#         int rate, frames_per_buffer
#         unsigned short channels
#         str filename, audio_filename
#         list audio_frames
#
#
#     def __init__(self,
#                  str filename_,
#                  int rate_=44100,
#                  frames_per_buffer_=1024,
#                  unsigned short channels_=2):
#
#
#         self.open           = True
#         self.rate           = rate_
#         self.frames_per_buffer = frames_per_buffer_
#         self.channels       = 2
#
#         self.format         = pyaudio.paInt16
#         self.audio_filename = filename_
#         self.audio          = pyaudio.PyAudio()
#         info                = self.audio.get_host_api_info_by_index(0)
#
#         cdef:
#             int numdevices = info.get('deviceCount')
#             int i =0
#
#         for i in range(0, numdevices):
#             print(self.audio.get_device_info_by_host_api_device_index(0, i))
#             if (self.audio.get_device_info_by_host_api_device_index(0, i).get('maxInputChannels')) > 0:
#                 print("Input Device id ", i, " - ",
#                       self.audio.get_device_info_by_host_api_device_index(0, i).get('name'))
#
#         self.stream = self.audio.open(format                =self.format,
#                                       channels              =2,
#                                       rate                  =self.rate,
#                                       output                =True,
#                                       output_device_index   = 3,
#                                       input                 =True,
#                                       input_device_index    = 0,
#                                       frames_per_buffer     = self.frames_per_buffer)
#         self.audio_frames = []
#
#     cpdef record(self):
#
#         self.stream.start_stream()
#         while self.open is True:
#             data = self.stream.read(self.frames_per_buffer)
#             self.audio_frames.append(data)
#             if self.open is False:
#                 break
#
#     cpdef stop(self):
#
#         if self.open is True:
#             self.open = False
#             self.stream.stop_stream()
#             self.stream.close()
#             self.audio.terminate()
#
#             waveFile = wave.open(self.audio_filename, 'wb')
#             waveFile.setnchannels(self.channels)
#             waveFile.setsampwidth(self.audio.get_sample_size(self.format))
#             waveFile.setframerate(self.rate)
#             waveFile.writeframes(b''.join(self.audio_frames))
#             waveFile.close()
#
#     cpdef start(self):
#         audio_thread = threading.Thread(target=self.record)
#         audio_thread.start()
#
# cpdef stop_audio_recording():
#     audio_thread.stop()
#
# cpdef start_audio_recording(filename):
#
#     if os.path.exists(filename):
#         os.remove(filename)
#
#     global audio_thread
#     audio_thread = AudioRecorder(filename)
#     audio_thread.start()
#
#







@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef class BuildVideo(object):

    cdef:
        public object image
        float length, height, scale
        object canvas, level_indicator
        int h


    def __init__(self,
                 float volume_play_      = <float>1.0,
                 float scale_            = <float>1.0,
                 object video_icon_      = VIDEO_ICON,
                 object level_indicator_ = LEVEL_ICON):


        self.length     = <float>350.0 * scale_
        self.height     = <float>72.0 * scale_

        self.canvas     = Surface((self.length, self.height)).convert()
        self.canvas.fill((28, 40, 32, 20))

        cdef int w, h

        if scale_ != 1.0:
            w, h = video_icon_.get_size()
            video_icon_ = smoothscale(
                video_icon_, (<int>(w * scale_), <int>(h * scale_)))

            w, h = level_indicator_.get_size()
            level_indicator_ = smoothscale(
                level_indicator_, (<int>(w * scale_), <int>(h * scale_)))

        w, h = video_icon_.get_size()
        self.canvas.blit(
            video_icon_,  (<int>(<float>2.85 * self.length / <float>100.0),
                          (self.canvas.get_height() - h) // <unsigned char>2))

        self.h      = level_indicator_.get_height()
        self.level_indicator = level_indicator_
        self.image  = None
        self.scale  = scale_
        self.update_progress_bar(volume_play_)

    def update_progress_bar(self, play_):
        can = self.canvas.copy()
        for level in range(<int>(play_ * <unsigned char>10)):
            can.blit(self.level_indicator,
            (<int>(<float>22.85 * self.length / <float>100.0) +
             (level * <unsigned char>25 * self.scale),
            (self.canvas.get_height() - self.h) // <unsigned char>2))

        can.set_alpha(255)
        self.image = can




@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cdef void rgb_to_bgr_inplace(unsigned char [:, :, :] rgb_array):

    cdef int w, h
    w, h = (<object>rgb_array).shape[:2]

    cdef:
        int i=0, j=0
        unsigned char tmp

    with nogil:

        for i in prange(w, schedule='static', num_threads=8):
            for j in range(h):
                tmp = rgb_array[i, j, <unsigned char>0]  # keep the blue color
                rgb_array[i, j, <unsigned char>0]  = rgb_array[i, j, <unsigned char>2]
                rgb_array[i, j, <unsigned char>2]  = tmp

#
# @cython.binding(False)
# @cython.boundscheck(False)
# @cython.wraparound(False)
# @cython.nonecheck(False)
# @cython.cdivision(True)
# @cython.profile(False)
# cpdef WriteVideo(object gl_):
#
#     cdef:
#         gl_screenrect  = gl_.screenrect
#         gl_screen      = gl_.screen
#         int w2         = gl_screenrect.w >> 1
#         int h2         = gl_screenrect.h >> 1
#         str video_name = 'Replay/GameVideo.avi'
#         object codec   = cv2.VideoWriter_fourcc(*'WMV2')
#         int fps        = 60
#         str text       = "Video capture, please wait...ESC to stop"
#         tuple text_color = (255, 255, 255)
#
#     video = cv2.VideoWriter(video_name, codec, fps, (w2, h2), True)
#
#     font = freetype.Font(os.path.join('Assets/Fonts/', 'ARCADE_R.ttf'), size=15)
#     rect1 = font.get_rect(text, style=freetype.STYLE_NORMAL, size=15)
#     rect1.center = (gl_screenrect.centerx - rect1.w // <unsigned char>2,
#                     gl_screenrect.centery - rect1.h // <unsigned char>2)
#     font.render_to(gl_screen, rect1.center, text, fgcolor=text_color, size=15)
#     pygame.display.flip()
#
#     video_bar = BuildVideo(0, 0.4)
#
#     cdef:
#         unsigned int video_length = len(gl_.VideoBuffer)
#         unsigned int counter      = 0
#         unsigned int c1         = w2 - <unsigned char>175 // <unsigned char>2
#         unsigned int c2         = (h2 >> 1) + <unsigned char>25
#         event_pump       = pygame.event.pump
#         key_pressed      = pygame.key.get_pressed
#         video_write      = video.write
#         flip             = pygame.display.flip
#         video_bar_update = video_bar.update_progress_bar
#
#     for rgb_array in gl_.VideoBuffer:
#
#         event_pump()
#         keys = key_pressed()
#
#         if keys[K_ESCAPE]:
#             break
#
#         rgb_array = lz4frame.decompress(rgb_array)
#         video_bar_update(<float>counter / <float>video_length)
#         gl_screen.blit(video_bar.image, (c1, c2))
#         rgb_array = numpy.fromstring(rgb_array, uint8).reshape(h2, w2, <unsigned char>3)
#         # rgb_array = cvtColor(rgb_array, COLOR_RGBA2BGR)
#         rgb_to_bgr_inplace(rgb_array)
#         video_write(rgb_array)
#
#         counter += 1
#         flip()
#
#     cv2.destroyAllWindows()
#     video.release()


@cython.binding(False)
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
@cython.profile(False)
cpdef WriteVideo(object gl_):
    cdef:
        gl_screenrect = gl_.screenrect
        gl_screen = gl_.screen
        int w2 = gl_screenrect.w >> 1
        int h2 = gl_screenrect.h >> 1
        str video_name = 'Replay/GameVideo.avi'
        object codec = cv2.VideoWriter_fourcc(*'WMV2')
        int fps = 60
        str text = "Video capture, please wait...ESC to stop"
        tuple text_color = (255, 255, 255)

    video = cv2.VideoWriter(video_name, codec, fps, (w2, h2), True)

    font = freetype.Font(os.path.join('Assets/Fonts/', 'ARCADE_R.ttf'), size=15)
    rect1 = font.get_rect(text, style=freetype.STYLE_NORMAL, size=15)
    rect1.center = (gl_screenrect.centerx - rect1.w // <unsigned char> 2,
                    gl_screenrect.centery - rect1.h // <unsigned char> 2)
    font.render_to(gl_screen, rect1.center, text, fgcolor=text_color, size=15)
    pygame.display.flip()

    video_bar = BuildVideo(0, 0.4)

    cdef:
        unsigned int video_length = len(gl_.VideoBuffer)
        unsigned int counter = 0
        unsigned int c1 = w2 - <unsigned char> 175 // <unsigned char> 2
        unsigned int c2 = (h2 >> 1) + <unsigned char> 25
        event_pump = pygame.event.pump
        key_pressed = pygame.key.get_pressed
        video_write = video.write
        flip = pygame.display.flip
        video_bar_update = video_bar.update_progress_bar

    # x_gpu = cp.asarray(gl_.VideoBuffer)

    for gpu_array in gl_.VideoBuffer:

        event_pump()
        keys = key_pressed()

        if keys[ K_ESCAPE ]:
            break

        # gpu_array = lz4frame.decompress(gpu_array)
        video_bar_update(<float> counter / <float> video_length)
        gl_screen.blit(video_bar.image, (c1, c2))
        gpu_array = numpy.fromstring(gpu_array, uint8).reshape(h2, w2, <unsigned char> 3)
        # rgb_array = cvtColor(rgb_array, COLOR_RGBA2BGR)
        #  rgb_to_bgr_inplace(rgb_array)
        video_write(gpu_array)

        counter += 1
        flip()

    cv2.destroyAllWindows()
    video.release()



