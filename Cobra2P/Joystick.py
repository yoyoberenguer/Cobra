# encoding: utf-8
import pygame


class ERROR(BaseException):
    pass


class JoystickCheck:
    availability = False
    inventory = []
    _status = ['Not initialised', 'Initialised']

    def __init__(self):
        try:

            self.joystick_number = 0
            if pygame.joystick.get_init():
                self.joystick_number = pygame.joystick.get_count()
            else:
                self.joystick_number = 0
                JoystickCheck.availability = False
                raise ERROR('The joystick is not initialised.')

            if self.joystick_number > 0:
                JoystickCheck.availability = True
                for id_ in range(self.joystick_number):
                    joystick_object = pygame.joystick.Joystick(id_)
                    joystick_object.init()
                    JoystickCheck.inventory.append(joystick_object)

        except:
            JoystickCheck.availability = False

    @staticmethod
    def number():
        return len(JoystickCheck.inventory)

    @staticmethod
    def objects():
        return JoystickCheck.inventory

    @staticmethod
    def names():
        i_ = 0
        for joystick in JoystickCheck.inventory:
            print('\n[+] Joystick : %s, id %s ' % (joystick.get_name(), i_))
            i_ += 1
    @staticmethod
    def status():
        i_ = 0
        for joystick in JoystickCheck.inventory:
            print('\n[+] id, %s deployed : %s ' % (i_, JoystickCheck._status[joystick.get_init()]))
            i_ += 1


if __name__ == '__main__':
    pygame.init()
    j = JoystickCheck()
    print(j.number(), j.objects())

    JoystickCheck.names()
    JoystickCheck.status()


    pass