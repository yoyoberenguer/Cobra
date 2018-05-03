"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """

import pygame
import math
import unittest
import multiprocessing

import timeit
from timeit import *


class TestObject:
    """ Create a test object for elastic collision engine"""
    def __init__(self, x, y, mass, rect):
        self.vector = pygame.math.Vector2()
        self.vector.x = x
        self.vector.y = y
        self.mass = mass
        self.rect = rect


class Momentum(unittest.TestCase):

    def __init__(self, obj1, obj2):
        self.obj1 = obj1
        self.obj2 = obj2

    def collision_calculator(self):
        phi = Momentum.contact_angle(pygame.math.Vector2(self.obj1.rect.center),
                                     pygame.math.Vector2(self.obj2.rect.center))

        theta1 = Momentum.theta_angle(self.obj1.vector)
        theta2 = Momentum.theta_angle(self.obj2.vector)

        v1 = Momentum.v1_vector_components(self.obj1.vector.length(), self.obj2.vector.length(),
                                           theta1, theta2, phi, self.obj1.mass,
                                           self.obj2.mass)

        v2 = Momentum.v2_vector_components(self.obj1.vector.length(), self.obj2.vector.length(),
                                           theta1, theta2, phi, self.obj1.mass,
                                           self.obj2.mass)
        return v1, v2

    @staticmethod
    def get_distance(p1_, p2_):
        return (p2_ - p1_).length()

    @staticmethod
    def contact_angle(obj, reference):
        phi = math.atan2(reference.y - obj.y, reference.x - obj.x)
        if phi > 0:
            phi -= 2 * math.pi
        phi *= -1
        return phi

    @staticmethod
    def theta_angle(vector):
        try:
            theta = math.acos(vector.x / vector.length())
            if vector.y < 0:
                theta *= -1
            return theta
        except ZeroDivisionError:
            return 0

    @staticmethod
    def v1_vector_components_alternative(v1, v2, m1, m2, x1, x2):
        assert (m1 + m2) > 0, 'Expecting a positive mass for m1 and m2, got %s ' % (m1 + m2)
        assert (x1 != x2), 'Expecting x1 and x2 to have different values, x1:%s, x2:%s ' % (x1, x2)
        mass = 2 * m2 / (m1 + m2)
        return v1 - (mass * (v1 - v2).dot(x1 - x2)/pow((x1-x2).length(), 2))*(x1 - x2)

    @staticmethod
    def v2_vector_components_alternative(v1, v2, m1, m2, x1, x2):
        assert (m1 + m2) > 0, 'Expecting a positive mass for m1 and m2, got %s ' % (m1 + m2)
        assert (x1 != x2), 'Expecting x1 and x2 to have different values, x1:%s, x2:%s ' % (x1, x2)
        mass = 2 * m1 / (m1 + m2)
        return v2 - (mass * (v2 - v1).dot(x2 - x1) / pow((x2 - x1).length(), 2)) * (x2 - x1)

    @staticmethod
    def v1_vector_components(v1, v2, theta1, theta2, phi, m1, m2):

        assert v1 >= 0 and v2 >= 0, 'v1 and v2 are vector magnitude and cannot be < 0.'
        assert (m1 + m2) > 0, 'Expecting a positive mass for m1 and m2, got %s ' % (m1 + m2)
        numerator = v1 * math.cos(theta1 - phi) * (m1 - m2) + 2 * m2 * v2 * math.cos(theta2 - phi)
        v1x = numerator * math.cos(phi) / (m1 + m2) + v1 * math.sin(theta1 - phi) * math.cos(phi + math.pi / 2)
        v1y = numerator * math.sin(phi) / (m1 + m2) + v1 * math.sin(theta1 - phi) * math.sin(phi + math.pi / 2)

        if math.isclose(v1x, 0.1e-10, abs_tol=1e-10):
            v1x = 0.0
        if math.isclose(v1y, 0.1e-10, abs_tol=1e-10):
            v1y = 0.0

        v1y *= -1 if v1y != 0 else 0.0
        return pygame.math.Vector2(v1x, v1y)

    @staticmethod
    def v2_vector_components(v1, v2, theta1, theta2, phi, m1, m2):

        assert v1 >= 0 and v2 >= 0, 'v1 and v2 are vector magnitude and cannot be < 0.'
        assert (m1+m2) > 0, 'Expecting a positive mass for m1 and m2, got %s ' % (m1 + m2)
        numerator = v2 * math.cos(theta2 - phi) * (m1 - m2) + 2 * m1 * v1 * math.cos(theta1 - phi)
        v2x = numerator * math.cos(phi) / (m1 + m2) + v2 * math.sin(theta2 - phi) * math.cos(phi + math.pi / 2)
        v2y = numerator * math.sin(phi) / (m1 + m2) + v2 * math.sin(theta2 - phi) * math.sin(phi + math.pi / 2)
        if math.isclose(v2x, 0.1e-10, abs_tol=1e-10):
            v2x = 0.0
        if math.isclose(v2y, 0.1e-10, abs_tol=1e-10):
            v2y = 0.0

        v2y *= -1 if v2y != 0 else 0.0  # y-axis inverted
        return pygame.math.Vector2(v2x, v2y)

    @staticmethod
    def process(obj1, obj2):

        phi = Momentum.contact_angle(pygame.math.Vector2(obj1.rect.center),
                                     pygame.math.Vector2(obj2.rect.center))

        theta1 = Momentum.theta_angle(obj1.vector)
        theta2 = Momentum.theta_angle(obj2.vector)

        v1 = Momentum.v1_vector_components(obj1.vector.length(), obj2.vector.length(),
                                           theta1, theta2, phi, obj1.mass,
                                           obj2.mass)

        v2 = Momentum.v2_vector_components(obj1.vector.length(), obj2.vector.length(),
                                           theta1, theta2, phi, obj1.mass,
                                           obj2.mass)
        return v1, v2

    @staticmethod
    def process_v1(obj1, obj2):
        phi = Momentum.contact_angle(pygame.math.Vector2(obj1.rect.center),
                                     pygame.math.Vector2(obj2.rect.center))

        theta1 = Momentum.theta_angle(obj1.vector)
        theta2 = Momentum.theta_angle(obj2.vector)
        v1 = Momentum.v1_vector_components(obj1.vector.length(), obj2.vector.length(),
                                           theta1, theta2, phi, obj1.mass,
                                           obj2.mass)

        return v1


    @staticmethod
    def process_v2(obj1, obj2):
        phi = Momentum.contact_angle(pygame.math.Vector2(obj1.rect.center),
                                     pygame.math.Vector2(obj2.rect.center))

        theta1 = Momentum.theta_angle(obj1.vector)
        theta2 = Momentum.theta_angle(obj2.vector)
        v2 = Momentum.v2_vector_components(obj1.vector.length(), obj2.vector.length(),
                                           theta1, theta2, phi, obj1.mass,
                                           obj2.mass)

        return v2

