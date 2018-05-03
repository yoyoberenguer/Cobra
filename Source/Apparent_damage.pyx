"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """

import pygame
from pygame import *
from Sprites import DAMAGE_NONE, DAMAGE_LEFT_WING_RED, DAMAGE_LEFT_WING_ORANGE, DAMAGE_LEFT_WING_YELLOW,\
    DAMAGE_RIGHT_WING_RED, DAMAGE_RIGHT_WING_YELLOW, DAMAGE_RIGHT_WING_ORANGE, DAMAGE_NOSE_RED, DAMAGE_NOSE_YELLOW,\
    DAMAGE_NOSE_ORANGE, DAMAGE_LEFT_ENGINE_RED, DAMAGE_LEFT_ENGINE_YELLOW, DAMAGE_LEFT_ENGINE_ORANGE, \
    DAMAGE_RIGHT_ENGINE_RED, DAMAGE_RIGHT_ENGINE_YELLOW, DAMAGE_RIGHT_ENGINE_ORANGE, DAMAGE_ALL
from Shipspecs import SHIP_SPECS


def apparent_damage(player, life_hud_copy, life):
    if player.alive():
        # Display the spaceship all green (system all ok)
        life_hud_copy.blit(DAMAGE_NONE, (12, 0))
        if SHIP_SPECS.system_status['LW'][0] is False:
            life_hud_copy.blit(DAMAGE_LEFT_WING_RED, (12, 0))
        else:
            if 50 < SHIP_SPECS.system_status['LW'][1] <= 75:
                life_hud_copy.blit(DAMAGE_LEFT_WING_YELLOW, (12, 0))
            elif 0 < SHIP_SPECS.system_status['LW'][1] <= 50:
                life_hud_copy.blit(DAMAGE_LEFT_WING_ORANGE, (12, 0))

        if SHIP_SPECS.system_status['RW'][0] is False:
            life_hud_copy.blit(DAMAGE_RIGHT_WING_RED, (12, 0))
        else:
            if 50 < SHIP_SPECS.system_status['RW'][1] <= 75:
                life_hud_copy.blit(DAMAGE_RIGHT_WING_YELLOW, (12, 0))
            elif 0 < SHIP_SPECS.system_status['RW'][1] <= 50:
                life_hud_copy.blit(DAMAGE_RIGHT_WING_ORANGE, (12, 0))

        if SHIP_SPECS.system_status['SUPER'][0] is False:
            life_hud_copy.blit(DAMAGE_NOSE_RED, (12, 0))
        else:
            if 50 < SHIP_SPECS.system_status['SUPER'][1] <= 75:
                life_hud_copy.blit(DAMAGE_NOSE_YELLOW, (12, 0))
            elif 0 < SHIP_SPECS.system_status['SUPER'][1] <= 50:
                life_hud_copy.blit(DAMAGE_NOSE_ORANGE, (12, 0))

        if SHIP_SPECS.system_status['LE'][0] is False:
            life_hud_copy.blit(DAMAGE_LEFT_ENGINE_RED, (12, 0))
        else:
            if 50 < SHIP_SPECS.system_status['LE'][1] <= 75:
                life_hud_copy.blit(DAMAGE_LEFT_ENGINE_YELLOW, (12, 0))
            elif 0 < SHIP_SPECS.system_status['LE'][1] <= 50:
                life_hud_copy.blit(DAMAGE_LEFT_ENGINE_ORANGE, (12, 0))

        if SHIP_SPECS.system_status['RE'][0] is False:
            life_hud_copy.blit(DAMAGE_RIGHT_ENGINE_RED, (12, 0))
        else:
            if 50 < SHIP_SPECS.system_status['LE'][1] <= 75:
                life_hud_copy.blit(DAMAGE_RIGHT_ENGINE_YELLOW, (12, 0))
            elif 0 < SHIP_SPECS.system_status['LE'][1] <= 50:
                life_hud_copy.blit(DAMAGE_RIGHT_ENGINE_ORANGE, (12, 0))

    else:
        life_hud_copy.blit(DAMAGE_ALL, (12, 0))
    if life:
        life_hud_copy.blit(life, (83, 20))
    return life_hud_copy


