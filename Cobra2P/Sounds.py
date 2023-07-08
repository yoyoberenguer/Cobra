# cython: boundscheck=False, wraparound=False, nonecheck=False, cdivision=True, optimize.use_switch=True
# encoding: utf-8


import pygame
from pygame.mixer import Sound 

if not pygame.mixer.get_init():
    pygame.mixer.pre_init(44100, 16, 2, 4096)
    pygame.init()

PATH = 'Assets/Sounds/'
HEAVY_LASER1          = Sound(PATH + 'heavylaser1.ogg')
HEAVY_LASER2          = Sound(PATH + 'heavylaser2.ogg')
HEAVY_LASER3          = Sound(PATH + 'heavylaser3.ogg')
DISRUPTOR             = Sound(PATH + 'disruptor.ogg')
FIRE_BOLT_LONG        = Sound(PATH + 'fire_bolt_long.ogg')
FIRE_BOLT_MED         = Sound(PATH + 'fire_bolt_med.ogg')
FIRE_BOLT_MICRO       = Sound(PATH + 'fire_bolt_micro.ogg')
FIRE_BOLT_SHORT       = Sound(PATH + 'fire_bolt_short.ogg')
FIRE_PARTICLE3        = Sound(PATH + 'fIRE_PARTICLE3.ogg')
PHOTON                = Sound(PATH + 'sd_weapon_photon_reg_01_c.ogg')
FIRE_NEUTRON1         = Sound(PATH + 'fire_neutron1.ogg')
FIRE_PLASMA           = Sound(PATH + 'fire_plasma5.ogg')
FLAK                  = Sound(PATH + 'Flak.ogg')
GAUSS                 = Sound(PATH + 'Gauss.ogg')
SD_LASER_LARGE_ALT_03 = Sound(PATH + 'sd_weapon_laser_large_alt_03.ogg')
SD_LASER_BURST        = Sound(PATH + 'sd_weapon_laser_burst_01.ogg')
INTERSTELLAR_GUN1     = Sound(PATH + 'interstellar_gun_01.ogg')
AUTO_CANNON           = Sound(PATH + 'AutoCannon.ogg')
UZI_LOOP              = Sound(PATH + 'uzi_loop.ogg')
WEAK_LASER            = Sound(PATH + 'weak laser.ogg')
TX0_FIRE1             = Sound(PATH + 'tx0_fire1.ogg')
TX0_FIRE2             = Sound(PATH + 'tx0_fire2.ogg')
TX0_FIRE3             = Sound(PATH + 'tx0_fire3.ogg')
CANNON_1              = Sound(PATH + 'sd_weapon_Turretgun_001.ogg')
CANNON_2              = Sound(PATH + 'autocannon2.ogg')
CANNON_3              = Sound(PATH + 'sd_weapon_Turretgun_002.ogg')
SUPERSHOT_WARMUP_1    = Sound(PATH + 'interstellar_gun_warmup_02.ogg')
ENGINE_ON             = Sound(PATH + 'sd_weapon_vulcan_spinloop_01.ogg')
ENGINE_TURBO          = Sound(PATH + 'Turbo.ogg')
PLAMA_SOUND_1         = Sound(PATH + 'sd_weapon_flame_start_02.ogg')
BEAM_ELECTRIC_1       = Sound(PATH + 'Electric Shock Zap1.ogg')
IMPACT1               = Sound(PATH + 'sd_impact_bullet_small_alt_01.ogg')
EXPLOSION_SOUND_1     = Sound(PATH + 'explosion_04.ogg')
EXPLOSION_SOUND_2     = Sound(PATH + 'explosion_11.ogg')
EXPLOSION_SOUND_3     = Sound(PATH + 'Huge explosion1a.ogg')
LEVEL_UP              = Sound(PATH + 'Level_up1.ogg')
IMPACT2               = Sound('Assets/Sounds/Impact.ogg')
# impact on enemy hull
IMPACT3               = Sound(PATH + 'sound22.ogg')
ENERGY_SUPPLY         = Sound(PATH + 'EnergySupply.ogg')
MISSILE_FLIGHT_SOUND  = Sound(PATH + 'sd_weapon_missile_heavy_01.ogg')
MISSILE_EXPLOSION_SOUND = Sound(PATH + 'sd_weapon_massive_02.ogg')
BOMB_RELEASE          = Sound(PATH + 'sd_bomb_release1.ogg')
BOMB_CATCH_SOUND      = Sound(PATH + 'Bomb_catch.ogg')
DENIED_SOUND          = Sound(PATH + 'denied.ogg')
CRYSTAL_SOUND         = Sound(PATH + 'crystal1.ogg')
HEART_SOUND           = Sound(PATH + 'heart.ogg')
EXPLOSION_COLLECTION_SOUND = [Sound(PATH + 'boom1.ogg'),           # 0
                             Sound(PATH + 'boom2.ogg'),
                             Sound(PATH + 'boom3.ogg'),
                             Sound(PATH + 'boom4.ogg'),
                             Sound(PATH + 'bomb_explosion_1.ogg'),
                             Sound(PATH + 'explosion_10.ogg'),
                             Sound(PATH + 'Huge explosion1a.ogg')]  #6
GROUND_EXPLOSION = []
GROUND_EXPLOSION.append(Sound(PATH + 'GroundExplosion.ogg'))
GROUND_EXPLOSION.append(Sound(PATH + 'Huge explosion1a.ogg'))
GROUND_EXPLOSION.append(Sound(PATH + 'GroundExplosiona.ogg'))
GROUND_EXPLOSION.append(Sound(PATH + 'GroundExplosionb.ogg'))

SUPER_EXPLOSION_SOUND = Sound(PATH + 'SuperExplosion.ogg')
BEAM_FUSION_MED       = Sound(PATH + 'sd_weapon_beam_fusion_med.ogg')
BEAM_FUSION_SMALL     = Sound(PATH + 'sd_weapon_beam_fusion_small.ogg')
BEAM_PLASMA_SMALL     = Sound(PATH + 'sd_weapon_beam_plasma_small.ogg')
BEAM_ION_MED          = Sound(PATH + 'sd_weapon_beam_ion_med.ogg')
ALARM_DESTRUCTION     = Sound(PATH + 'Alarm9.ogg')
FORCE_FIELD_SOUND     = Sound(PATH + 'forcefield.ogg')
SHIELD_IMPACT_SOUND   = Sound(PATH + 'sd_weapon_massive_01.ogg')
# Enemy shield impacts
SHIELD_IMPACT_SOUND_1 = Sound(PATH + 'impact6.ogg')
SHIELD_IMPACT_SOUND_2 = Sound(PATH + 'sound24.ogg')
SHIELD_DOWN_SOUND     = Sound(PATH + 'Shield_down.ogg')
AMMO_RELOADING_SOUND  = Sound(PATH + 'ammo_reloading.ogg')
NANOBOTS_SOUND        = Sound(PATH + 'elec.ogg')
MUSIC_PLAYLIST        = ['Assets/Music/EXAMPLE_techno-009-03.12.mp3',
                         'Assets/Music/EXAMPLE_techno-001-01.22.mp3']
SCREEN_IMPACT_SOUND   = Sound(PATH + 'sd_troop_attack_miss.ogg')
BROKEN_GLASS          = Sound(PATH + 'impact_glass_window_smash_001.ogg')
LASER_BULLET_HELL     = Sound(PATH + 'LaserBulletHell.ogg')
COIN_SOUND            = Sound(PATH + 'coin_sound.ogg')
EXTRA_LIFE            = Sound(PATH + 'extra_life.ogg')
WHOOSH                = Sound(PATH + 'whoosh.ogg')
WARNING               = Sound(PATH + 'warning.ogg')
THUNDER               = Sound(PATH + 'thndr_cls.ogg')
PULSE                 = Sound(PATH + 'pulse.ogg')
FLAT_PULSE            = Sound(PATH + 'Flat_pulse.ogg')
DISK_READ             = Sound(PATH + 'floppy-disk-drive-read.ogg')
LOADING_SOUND         = Sound(PATH + 'jump_flight.ogg')
SEISMIC_CHARGE        = Sound(PATH + 'seismic_charge.ogg')


