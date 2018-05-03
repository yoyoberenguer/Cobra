# encoding: utf-8
import pygame
from math import sqrt, pow, atan
from random import uniform, randint
import timeit
from Constants import SCREENRECT, RAD_TO_DEG


class Entity:

    def __init__(self, parent_, name_, position_, distance_to_player_, deadly_):
        self.parent = parent_
        self.name = name_
        self.position = position_
        self.distance_from_player = distance_to_player_
        self.deadly = deadly_
        self.id = id(self)


class Threat(pygame.Rect):
    inventory = []

    def __init__(self, player_rect):
        pygame.Rect.__init__(self, player_rect)
        self.Rect = player_rect

    def get_point_distance(self, point):
        return int(sqrt(pow(self.centerx - point[0], 2) +
                        pow(self.centery - point[1], 2)))

    def get_rect_distance(self, obj):
        return int(sqrt(pow(self.centerx - obj.centerx, 2) +
                        pow(self.centery - obj.centery, 2)))

    def get_all_rect_distances(self, stack):
        distances = {}
        for obj in stack:
            if SCREENRECT.contains(obj.rect):
                distances[str(obj._id)] = int(sqrt(pow(self.centerx - obj.rect.centerx, 2) +
                                                   pow(self.centery - obj.rect.centery, 2)))
        return distances

    def create_entities(self, stack):
        entities = {}
        for obj in stack:
            if SCREENRECT.contains(obj.rect):
                if hasattr(obj, 'asteroids'):
                    entities[str(obj._id)] = Entity(parent_=obj, name_=obj.asteroids.name, position_=obj.position,
                                                    distance_to_player_=int(
                                                        sqrt(pow(self.centerx - obj.rect.centerx, 2) +
                                                             pow(self.centery - obj.rect.centery, 2))),
                                                    deadly_=obj.damage)
                elif hasattr(obj, 'dummy'):
                    pass

                else:
                    entities[str(obj.enemy_.id)] = Entity(parent_=obj, name_=obj.enemy_.name, position_=obj.position,
                                                   distance_to_player_=int(
                                                       sqrt(pow(self.centerx - obj.rect.centerx, 2) +
                                                            pow(self.centery - obj.rect.centery, 2))),
                                                   deadly_=obj.damage)
        Threat.inventory = entities
        return entities

    @staticmethod
    def single_sorted_by_distance_nearest(stack):
        if stack:
            ordered_distances = {}
            for _id, _entity in stack.items():
                ordered_distances[_entity.distance_from_player] = [_entity.parent, _id]
            return sorted(ordered_distances.items(), reverse=False)[0]
        else:
            return None

    @staticmethod
    def single_sorted_by_distance_farthest(stack):
        if stack:
            ordered_distances = {}
            for _id, _entity in stack.items():
                ordered_distances[_entity.distance_from_player] = [_entity.parent, _id]
            # return first closest object (first entry)
            return sorted(ordered_distances.items(), reverse=True)[0]
        else:
            return None

    @staticmethod
    def sort__by_distance(stack):
        if stack:
            ordered_distances = {}
            for _id, _entity in stack.items():
                ordered_distances[_entity.distance_from_player] = [_entity.parent, _id]
            return sorted(ordered_distances.items(), reverse=False)[0]
        else:
            return None

    @staticmethod
    def sort_by_high_deadliness(stack):
        if stack:
            ordered_deadliness = {}
            for _id, _entity in stack.items():
                ordered_deadliness[_entity.deadly] = [_entity.parent, _id]
            return sorted(ordered_deadliness.items(), reverse=True)
        else:
            return None

    @staticmethod
    def sort_by_low_deadliness(stack):

        if stack:
            ordered_by_weakness = {}
            for _id, _entity in stack.items():
                ordered_by_weakness[_entity.deadly] = [_entity.parent, _id]
            return sorted(ordered_by_weakness.items(), reverse=False)
        else:
            return None

    @staticmethod
    def slope(p1, p2):
        try:
            slope = (p2.y - p1.y) / (p2.x - p1.x)
        except ZeroDivisionError:
            return None
        return round(slope, 3)

    @staticmethod
    def intersection(slope, point):
        return round(point.y - slope * point.x, 3)

    @staticmethod
    def theta_degree(p1, p2):
        return atan(Threat.slope(p1, p2)) * RAD_TO_DEG

    @staticmethod
    def get_object_coefficients(obj):
        if all(hasattr(obj, attributes) for attributes in ["position", "vector"]):
            p1 = obj.position
            p2 = obj.position + obj.vector
        else:
            print('\n[-]get_object_slope error : argument obj '
                  'missing one or both of the following methods (position, vector)')
            raise AttributeError
        m = Threat.slope(p1, p2)
        k = Threat.intersection(m, p1)
        if m is not None:
            return m, k
        else:
            return None

    @staticmethod
    def get_impact_coordinates(object1, object2):
        c1 = Threat.get_object_coefficients(object1)
        c2 = Threat.get_object_coefficients(object2)
        if (c1 and c2) is not None:
            try:
                x_coordinate = (c2[1] - c1[1]) / (c1[0] - c2[0])
            except ZeroDivisionError:
                return None
            y_coordinate = c1[0] * x_coordinate + c1[1]
        else:
            return None
        return x_coordinate, y_coordinate

    @staticmethod
    def get_distance(p1_, p2_) -> float:
        return (p2_ - p1_).length()

    def sort_by_nearest_collider(self, stack):
        if stack:
            sort_by_distance = {}
            for obj in stack:
                sort_by_distance[Threat.get_distance(pygame.math.Vector2(self.center),
                                                     pygame.math.Vector2(obj.rect.center))] = [obj, id(obj)]
            return sorted(sort_by_distance.items(), reverse=False)[0]
        else:
            return None

    def sort_by_farthest_collider(self, stack):
        sort_by_distance = {}
        if stack:
            for obj in stack:
                sort_by_distance[Threat.get_distance(pygame.math.Vector2(self.center),
                                                     pygame.math.Vector2(obj.rect.center))] = [obj, id(obj)]
            return sorted(sort_by_distance.items(), reverse=True)[0]
        else:
            return None

    def colliders(self, stack, player_rect):
        colliders_ = []
        rect1 = player_rect
        rect1_center = pygame.math.Vector2(player_rect.center)
        for obj in stack:
            if SCREENRECT.contains(obj.rect):
                rect2 = obj.rect.copy()
                rect2_center = pygame.math.Vector2(rect2.center)
                vector_copy = pygame.math.Vector2()
                vector_copy.x = obj.vector.x
                vector_copy.y = obj.vector.y
                if Threat.is_colliding(vector=vector_copy, p1=rect1_center,
                                       p2=rect2_center, rect1=rect1, rect2=rect2)[0]:
                    colliders_.append(obj)
        return colliders_

    @staticmethod
    def is_colliding(vector, p1, p2, rect1, rect2):
        if vector.length() == 0:
            return tuple((False, rect1))
        vector.scale_to_length((p2 - p1).length())
        rect2.center = vector + p2
        return tuple((bool(rect1.colliderect(rect2)), rect2.clip(rect1)))

