from Constants import SCREENRECT
from Weapons import SHOT_CONFIGURATION
from Shot import Shot


# return the number of projectile for a single shot
def shot_number(unit):
    # assert isinstance(unit, str), ' Expecting a string got %s ' % type(unit)
    return SHOT_CONFIGURATION[unit]


# Draw as many projectile(s) the weapon is designed with
# SINGLE SHOT, DOUBLE, QUADRUPLE, SEXTUPLE
def multiple_shots(unit, ship_specs, current_weapon, SC_spaceship, player, time_passed_seconds, All):
    # assert isinstance(unit, str), \
    #    'Expecting a string got %s ' % type(unit)
    offset_x = [-17, 17, -30, 30, -45, 45]
    offset_y = [player.rect.midtop[1]] * 6
    mute = False
    if unit == 'SINGLE':
        if current_weapon.type_ == 'BULLET':
            offset_x = [-6]
        else:
            offset_x = [0]
    if unit == 'DOUBLE':
        offset_x = [-17, 17]

    quantity = SHOT_CONFIGURATION[unit]

    # The left wing is damaged.
    # Disable all guns on portside
    if not ship_specs.system_status['RW'][0]:
        # popping all the even index (values>0)
        offset_x = offset_x[0::2]
        quantity = len(offset_x)
    # Same for right wing
    if not ship_specs.system_status['LW'][0]:
        if len(offset_x) < shot_number(unit):
            offset_x = []
            quantity = 0
        else:
            offset_x = offset_x[1::2]
            quantity = len(offset_x)

    for index in range(quantity):
        Shot.screenrect = SCREENRECT
        Shot(player.gun_position(), current_weapon, mute, offset_x[index],
             offset_y[index], 33, SC_spaceship, time_passed_seconds, All, -2)
        mute = True

    if current_weapon.type_ == 'BULLET':
        ship_specs.ammo -= quantity
    else:
        ship_specs.energy -= quantity * current_weapon.energy
