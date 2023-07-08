import pygame
from pygame import Vector2
from pygame.transform import rotozoom

from Sprites import Sprite, LayeredUpdates, Group, LayeredUpdatesModified
from math import cos, sin, pi
DEG_TO_RAD = pi/180


SCREEN = pygame.display.set_mode((800, 800))
SCREENRECT = SCREEN.get_rect()
FX086 = pygame.image.load("Assets/Graphics/Laser_Fx/png/1 basic/lzrfx029_.png")
FX087 = pygame.image.load("Assets/Graphics/Laser_Fx/png/1 basic/lzrfx018_.png")
FX086.convert(32, pygame.RLEACCEL)
FX087.convert(32, pygame.RLEACCEL)


VERTEX_BULLET_HELL = []



def create_bullet_hell(image_, shooting_angle_, all_, angle_, angle_velocity=0.1, bullet_speed = 10):

        rect_x = SCREEN.get_width() >> 1
        rect_y = SCREEN.get_height() >> 1
        offset_x = 0
        offset_y = 0

        # BULLET ORIGIN
        position = Vector2(rect_x + offset_x, rect_y - offset_y)

        velocity = bullet_speed
        spr = Sprite()
        global VERTEX_BULLET_HELL

        for r in range(1):
            all_.add(spr)

            shooting_angle_ += angle_
            shooting_angle_ %= 360
            spr.rad_angle       = shooting_angle_ * DEG_TO_RAD
            spr.vec             = Vector2(cos(spr.rad_angle) * velocity, -sin(spr.rad_angle) * velocity)
            spr.image           = image_
            spr.image           = rotozoom(image_.copy(), shooting_angle_, 1)
            # w, h = spr.image.get_size()
            # w_2, h_2 = w >> 1, h >> 1
            spr.rect = spr.image.get_rect(center=(position.x, position.y))
            spr.center = position
            spr._blend          = pygame.BLEND_RGB_ADD

            VERTEX_BULLET_HELL.append(spr)
        angle_ += angle_velocity
        return angle_, shooting_angle_

def display_bullets():

    global VERTEX_BULLET_HELL, SCREENRECT

    for spr in VERTEX_BULLET_HELL:

        # rect = spr.rect
        # w_2 = rect.w >> 1
        # h_2 = rect.h >> 1

        # BULLET OUTSIDE DISPLAY ?
        if spr.rect.colliderect(SCREENRECT):

            spr.center.x += spr.vec.x
            spr.center.y += spr.vec.y
            # SCREEN.blit(spr.image, (spr.center.x - w_2, spr.center.y - h_2), special_flags=pygame.BLEND_RGB_ADD)
            spr.rect.centerx = spr.center.x
            spr.rect.centery = spr.center.y
        else:
            if spr in VERTEX_BULLET_HELL:
                VERTEX_BULLET_HELL.remove(spr)
            spr.kill()


All = LayeredUpdatesModified()

FRAME = 0
MOUSE_POS = (0, 0)
FRAME = 0
ANGLE1 = 0
ANGLE2 = 180
SHOOTING_ANGLE1 = 0
SHOOTING_ANGLE2 = -180
if __name__ == '__main__':

    while 1:
        pygame.event.pump()
        for event in pygame.event.get():

            keys = pygame.key.get_pressed()

            if event.type == pygame.MOUSEMOTION:
                MOUSE_POS = event.pos

        SCREEN.fill((0, 0, 0, 0))
        pygame.draw.aaline(SCREEN,(255, 0, 0, 0), (400, 0), (400, 800))
        pygame.draw.aaline(SCREEN,(255, 0, 0, 0), (0, 400), (800, 400))
        ANGLE1, SHOOTING_ANGLE1 = create_bullet_hell(FX086, SHOOTING_ANGLE1, All, ANGLE1, 0.2, 8)
        ANGLE2, SHOOTING_ANGLE2 = create_bullet_hell(FX086, SHOOTING_ANGLE2, All, ANGLE2, 0.2, 8)
        display_bullets()
        All.update()
        All.draw(SCREEN)
        pygame.display.flip()

        pygame.time.delay(16)

        FRAME += 1

