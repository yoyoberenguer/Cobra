# encoding: utf-8
import numpy
from numpy import array, arange, repeat, newaxis, linspace, clip
import pygame
from surface import make_surface, make_array

class HorizontalBar:

    def __init__(self, start_color, end_color, max_, min_, value_,
                 start_color_vector, end_color_vector, alpha):

        self.START_COLOR = pygame.math.Vector3(*start_color[:3])
        self.END_COLOR = pygame.math.Vector3(*end_color[:3])
        self.MAX = max_
        self.MIN = min_
        self.VALUE = value_
        self.Y = 32
        self.FACTOR = self.MAX / 180
        self.start_color_vector = pygame.math.Vector3(*start_color_vector)
        self.end_color_vector = pygame.math.Vector3(*end_color_vector)
        self.alpha_value = alpha
        self.display_color = pygame.Color(255, 255, 255, 255)
        self.font_ = pygame.font.SysFont("arial", 9, 'normal')
        self.logic_compilation = []

    def horizontal_gradient(self):

        diff_ = (array(self.END_COLOR[:3]) - array(self.START_COLOR[:3])) * self.VALUE / self.MAX
        w, h = self.VALUE//self.FACTOR, self.Y
        row = arange(w, dtype='float') / w
        row = repeat(row[:, newaxis], [3], 1)
        diff_ = repeat(diff_[newaxis, :], [w], 0)
        row = array(self.START_COLOR[:3]) + (diff_ * row).astype(dtype=numpy.float)
        row = row.astype(dtype=numpy.uint8)[:, newaxis, :]
        row = repeat(row[:, :], [h], 1)
        return row

    def display_value(self):
        if 500 < self.VALUE < 1000:
            self.display_color = pygame.Color(255, 132, 64, 255)
        elif 0 < self.VALUE < 500:
            self.display_color = pygame.Color(255, 0, 0, 255)
        else:
            self.display_color = pygame.Color(255, 255, 255, 255)
        return self.font_.render(str(self.VALUE), False, self.display_color)

    def alpha(self):
        w, h = self.VALUE//self.FACTOR, self.Y
        row = linspace(255, self.alpha_value, self.VALUE/self.FACTOR,  dtype='float')
        row = repeat(row[:, newaxis], [1], 0)
        row = row.astype(dtype=numpy.uint8)[:, newaxis, :]
        row = repeat(row[:, :], [h], 1)
        return row

    def display_gradient(self):
        if self.VALUE > 1:
            row = self.horizontal_gradient()
            if self.START_COLOR.length() > 0:
                if self.START_COLOR.x > 255 or self.START_COLOR.x < 0:
                    self.start_color_vector.x *= -1
                if self.START_COLOR.y > 255 or self.START_COLOR.y < 0:
                    self.start_color_vector.y *= -1
                if self.START_COLOR.z > 255 or self.START_COLOR.z < 0:
                    self.start_color_vector.z *= -1
            if self.END_COLOR.length() > 0:
                if self.END_COLOR.x > 255 or self.END_COLOR.x < 0:
                    self.end_color_vector.x *= -1
                if self.END_COLOR.y > 255 or self.END_COLOR.y < 0:
                    self.end_color_vector.y *= -1
                if self.END_COLOR.z > 255 or self.END_COLOR.z < 0:
                    self.end_color_vector.z *= -1
            self.START_COLOR += self.start_color_vector
            self.END_COLOR += self.end_color_vector

            if row.shape[0] == 0:
                return None
            if self.alpha_value:
                rgba_array = make_array(row, self.alpha())
                bar = make_surface(rgba_array)
            else:
                bar = pygame.surfarray.make_surface(row)
            return bar
        else:
            return None


