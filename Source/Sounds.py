# encoding: utf-8
import pygame
from Constants import GAMEPATH

if not pygame.mixer.get_init():
    pygame.mixer.pre_init(44100, 16, 2, 4096)
    pygame.init()

PATH = 'Assets\\Sounds\\'
HEAVY_LASER1 = pygame.mixer.Sound(PATH + 'heavylaser1.ogg')
HEAVY_LASER2 = pygame.mixer.Sound(PATH + 'heavylaser2.ogg')
HEAVY_LASER3 = pygame.mixer.Sound(PATH + 'heavylaser3.ogg')

DISRUPTOR = pygame.mixer.Sound(PATH + 'disruptor.ogg')

FIRE_BOLT_LONG = pygame.mixer.Sound(PATH + 'fire_bolt_long.ogg')
FIRE_BOLT_MED = pygame.mixer.Sound(PATH + 'fire_bolt_med.ogg')
FIRE_BOLT_MICRO = pygame.mixer.Sound(PATH + 'fire_bolt_micro.ogg')
FIRE_BOLT_SHORT = pygame.mixer.Sound(PATH + 'fire_bolt_short.ogg')

FIRE_NEUTRON1 = pygame.mixer.Sound(PATH + 'fire_neutron1.ogg')
FIRE_PLASMA = pygame.mixer.Sound(PATH + 'fire_plasma5.ogg')
FLAK = pygame.mixer.Sound(PATH + 'Flak.ogg')
GAUSS = pygame.mixer.Sound(PATH + 'Gauss.ogg')
SD_LASER_LARGE_ALT_03 = pygame.mixer.Sound(PATH + 'sd_weapon_laser_large_alt_03.ogg')
SD_LASER_BURST = pygame.mixer.Sound(PATH + 'sd_weapon_laser_burst_01.ogg')
INTERSTELLAR_GUN1 = pygame.mixer.Sound(PATH + 'interstellar_gun_01.ogg')


AUTO_CANNON = pygame.mixer.Sound(PATH + 'AutoCannon.ogg')

UZI_LOOP = pygame.mixer.Sound(PATH + 'uzi_loop.ogg')
WEAK_LASER = pygame.mixer.Sound(PATH + 'weak laser.ogg')

TX0_FIRE1 = pygame.mixer.Sound(PATH + 'tx0_fire1.ogg')
TX0_FIRE2 = pygame.mixer.Sound(PATH + 'tx0_fire2.ogg')
TX0_FIRE3 = pygame.mixer.Sound(PATH + 'tx0_fire3.ogg')

CANNON_1 = pygame.mixer.Sound(PATH + 'sd_weapon_Turretgun_001.ogg')
CANNON_2 = pygame.mixer.Sound(PATH + 'autocannon2.ogg')
CANNON_3 = pygame.mixer.Sound(PATH + 'sd_weapon_Turretgun_002.ogg')
SUPERSHOT_WARMUP_1 = pygame.mixer.Sound(PATH + 'interstellar_gun_warmup_02.ogg')
ENGINE_ON = pygame.mixer.Sound(PATH + 'sd_weapon_vulcan_spinloop_01.ogg')

PLAMA_SOUND_1 = pygame.mixer.Sound(PATH + 'sd_weapon_flame_start_02.ogg')
BEAM_ELECTRIC_1 = pygame.mixer.Sound(PATH + 'Electric Shock Zap1.ogg')
IMPACT1 = pygame.mixer.Sound(PATH + 'sd_impact_bullet_small_alt_01.ogg')
EXPLOSION_SOUND_1 = pygame.mixer.Sound(PATH + 'explosion_04.ogg')
EXPLOSION_SOUND_2 = pygame.mixer.Sound(PATH + 'explosion_11.ogg')
EXPLOSION_SOUND_3 = pygame.mixer.Sound(PATH + 'Huge explosion1a.ogg')
LEVEL_UP = pygame.mixer.Sound(PATH + 'Level_up1.ogg')

IMPACT2 = pygame.mixer.Sound('Assets\\Sounds\\Impact.ogg')
# impact on enemy hull
IMPACT3 = pygame.mixer.Sound(PATH + 'sound22.ogg')
ENERGY_SUPPLY = pygame.mixer.Sound(PATH + 'EnergySupply.ogg')

MISSILE_FLIGHT_SOUND = pygame.mixer.Sound(PATH + 'sd_weapon_missile_heavy_01.ogg')
MISSILE_EXPLOSION_SOUND = pygame.mixer.Sound(PATH + 'sd_weapon_massive_02.ogg')
BOMB_RELEASE = pygame.mixer.Sound(PATH + 'sd_bomb_release1.ogg')
BOMB_CATCH_SOUND = pygame.mixer.Sound(PATH + 'Bomb_catch.ogg')
DENIED_SOUND = pygame.mixer.Sound(PATH + 'denied.ogg')
CRYSTAL_SOUND = pygame.mixer.Sound(PATH + 'crystal1.ogg')
HEART_SOUND = pygame.mixer.Sound(PATH + 'heart.ogg')
EXPLOSION_COLLECTION_SOUND = [pygame.mixer.Sound(PATH + 'boom1.ogg'),
                             pygame.mixer.Sound(PATH + 'boom2.ogg'),
                             pygame.mixer.Sound(PATH + 'boom3.ogg'),
                             pygame.mixer.Sound(PATH + 'boom4.ogg'),
                             pygame.mixer.Sound(PATH + 'bomb_explosion_1.ogg'),
                             pygame.mixer.Sound(PATH + 'explosion_10.ogg'),
                             pygame.mixer.Sound(PATH + 'Huge explosion1a.ogg')]

SUPER_EXPLOSION_SOUND = pygame.mixer.Sound(PATH + 'SuperExplosion.ogg')

BEAM_FUSION_MED = pygame.mixer.Sound(PATH + 'sd_weapon_beam_fusion_med.ogg')
ALARM_DESTRUCTION = pygame.mixer.Sound(PATH + 'Alarm9.ogg')
FORCE_FIELD_SOUND = pygame.mixer.Sound(PATH + 'forcefield.ogg')
SHIELD_IMPACT_SOUND = pygame.mixer.Sound(PATH + 'sd_weapon_massive_01.ogg')

# Enemy shield impacts
SHIELD_IMPACT_SOUND_1 = pygame.mixer.Sound(PATH + 'impact6.ogg')
SHIELD_IMPACT_SOUND_2 = pygame.mixer.Sound(PATH + 'sound24.ogg')

SHIELD_DOWN_SOUND = pygame.mixer.Sound(PATH + 'Shield_down.ogg')
AMMO_RELOADING_SOUND = pygame.mixer.Sound(PATH + 'ammo_reloading.ogg')

NANOBOTS_SOUND = pygame.mixer.Sound(PATH + 'elec.ogg')

MUSIC_PLAYLIST = ['Assets\\Music\\EXAMPLE_techno-009-03.12.mp3', 'Assets\\Music\\EXAMPLE_techno-001-01.22.mp3']
# juhani.junkala@musician.org