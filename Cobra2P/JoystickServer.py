# encoding: utf-8
"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """
import time

__author__ = "Yoann Berenguer"
__copyright__ = "Copyright 2007, Cobra Project"
__credits__ = ["Yoann Berenguer"]
__license__ = "GPL"
__version__ = "1.0.0"
__maintainer__ = "Yoann Berenguer"
__email__ = "yoyoberenguer@hotmail.com"
__status__ = "Joystick Client"

import pygame
import socket
import _pickle as pickle
import threading
import pickletools


# encoding: utf-8
"""

                   GNU GENERAL PUBLIC LICENSE

                       Version 3, 29 June 2007


 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>

 Everyone is permitted to copy and distribute verbatim copies

 of this license document, but changing it is not allowed.
 """

__author__ = "Yoann Berenguer"
__copyright__ = "Copyright 2007, Cobra Project"
__credits__ = ["Yoann Berenguer"]
__license__ = "GPL"
__version__ = "1.0.0"
__maintainer__ = "Yoann Berenguer"
__email__ = "yoyoberenguer@hotmail.com"
__status__ = "Joystick Client"


class GL_:
    All = None
    TIME_PASSED_SECONDS = None
    JOYSTICK = None
    MOUSE_POS = None
    STOP_GAME = False
    P2CS_STOP = False


class JoystickServer(threading.Thread):
    """
        Open a socket and listen for incoming data
        Here is the data layout (JoystickObject class)

        self.id = id_
        self.name = name_
        self.axes = axes_
        self.axes_status = axes_status_
        self.buttons = buttons_
        self.button_status = buttons_status_
        self.hat = hat_
        self.hats_status = hats_status
        self.balls = balls_
        self.balls_status = balls_status_

    """

    def __init__(self,
                 gl_,  # Global variables
                 host_,  # host address
                 port_,  # port value
                 ):

        """
        Create a socket to received Joystick pickle objects
        :param host_: String corresponding to the server address
        :param port_: Integer used for the port.
                      Port to listen on (non-privileged ports are > 1023) and 0 < port_ < 65535
        """

        threading.Thread.__init__(self)

        assert isinstance(host_, str), \
            'Expecting string for argument host_, got %s instead.' % type(host_)
        assert isinstance(port_, int), \
            'Expecting integer for argument port_, got %s instead.' % type(port_)
        # Port to listen on (non-privileged ports are > 1023)
        assert 0 < port_ < 65535, \
            'Incorrect value assign to port_, 0 < port_ < 65535, got %s ' % port_
        if port_ > 1023:
            print('\n[-]JoystickServer - WARNING, selected port require superuser privilege.')

        if gl_ is not None:
            self.gl = gl_  # global variable
        else:
            raise ValueError('\n[-]JoystickServer - ERROR, Argument gl_ is not defined.')

        if gl_.P2CS_STOP:
            raise ValueError('\n[-]JoystickServer - ERROR, P2CS_STOP should be reset prior starting thread.')

        # Create a TCP/IP socket
        try:

            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        except socket.error as error:
            print('\n[-]JoystickServer - ERROR 0, socket: %s ' % error)
            gl_.P2CS_STOP = True

        try:

            # Bind the socket to the port
            self.sock.bind((host_, port_))
            # listen() enables a server to accept() connections.
            # It makes it a “listening” socket:
            # listen() has a backlog parameter. It specifies the number of unaccepted
            # connections that the system will allow before refusing new connections.
            # Starting in Python 3.5, it’s optional. If not specified,
            # a default backlog value is chosen.
            # If your server receives a lot of connection requests simultaneously,
            # increasing the backlog value may help by setting the maximum length of
            # the queue for pending connections.
            self.sock.listen(1)

        except socket.error as error:
            print('\n[-]JoystickServer - ERROR 1, socket: %s ' % error)
            if self.sock in self.__dict__ and isinstance(self.sock, socket.socket):
                self.sock.close()
            gl_.P2CS_STOP = True

        self.host = host_  # address to listen
        self.port = port_  # Port to listen on (non-privileged ports are > 1023)
        self.buf = 4096
        self.view = memoryview(bytearray(self.buf))
        self.totalbytes = 0

    def kill(self):
        if hasattr(self, 'gl') and hasattr(self.gl, 'P2CS_STOP'):
            self.gl.P2CS_STOP = True
            if hasattr(self, 'sock'):
                try:
                    self.sock.shutdown(socket.SHUT_RD)
                except OSError:
                    print('\n[-]Termination signal could not be delivered ')

    def run(self):

        if not self.gl.P2CS_STOP:
            print('\n[+]JoystickServer - INFO, socket is listening... '
                  'host %s : %s...' % (self.host, self.port))
        else:
            print('\n[-]JoystickServer - WARNING, something is not quite right, '
                  'socket is closing down... ')

        while not self.gl.P2CS_STOP:

            try:

                # accept() blocks and waits for an incoming connection.
                # When a client connects, it returns a new socket object
                # representing the connection and a tuple holding the address of the client.
                connection, client_address = self.sock.accept()

            except Exception as error:
                print('\n[-]JoystickServer - ERROR, socket: %s ' % error)
                # self.gl.P2CS_STOP = True
                connection, client_address = None, None

            ii = 0
            if connection is not None:
                print('\n[+]JoystickServer - INFO, Player 2 is connected from %s:%s '
                      % connection.getpeername())
            # try:

            while not self.gl.P2CS_STOP:

                size = 0
                pyobject = None

                # After getting the client socket object conn from accept(),
                # an infinite while loop is used to loop over blocking calls to connection.recv().
                # This reads whatever data the client sends and echoes it back using connection.sendall().
                # If connection.recv() returns an empty bytes object, b'', then the client closed the
                # connection and the loop is terminated. The with statement is used with connection to
                # automatically close the socket at the end of the block.
                try:
                    connection.recvfrom_into(self.view, self.buf)
                except (AttributeError, ConnectionError) as error:
                    print('\n[+]JoystickServer - ERROR, Player 2 is disconnected...')
                    # print('\n[+]JoystickServer - ERROR, %s ' % error)
                    break

                ii += 1

                if not self.view:
                    break

                if len(self.view) > 0:
                    try:

                        size, pyobject = pickle.loads(self.view)
                        pyobject = pickle.loads(pyobject)

                    except pickle.UnpicklingError as error:
                        print('\n[+]JoystickServer - INFO, Player 2 is disconnected...')
                        print('\n[+]JoystickServer - ERROR, %s ' % error)
                        # self.gl.P2CS_STOP = True
                        break

                if pyobject is not None:
                    try:
                        connection.sendall(self.view.tobytes())
                    except ConnectionError as error:
                        print('\n[+]JoystickServer - INFO, Player 2 is disconnected...')
                        # print('\n[+]JoystickServer - ERROR, %s ' % error)

                self.totalbytes += size

                if pyobject == b'quit':
                    print('\n[-]JoystickServer - WARNING : socket is shutting down...')
                    self.gl.P2CS_STOP = True
                    break

                else:
                    # print('data received : ', self.view)
                    # print('data decoded  : ', pyobject)

                    print('\n')
                    print('Joystick id %s ' % pyobject.id)
                    print('Joystick name %s ' % pyobject.name)
                    print('Joystick axes %s ' % pyobject.axes)
                    print('Joystick axes_status %s ' % pyobject.axes_status)
                    print('Joystick button %s ' % pyobject.buttons)
                    print('Joystick button_status %s ' % pyobject.button_status)
                    print('Joystick hats %s ' % pyobject.hat)
                    print('Joystick hats_status %s ' % pyobject.hats_status)
                    print('Joystick balls %s ' % pyobject.balls)
                    print('Joystick balls_status %s ' % pyobject.balls_status)

                    self.gl.P2JNI = pyobject  # Player2 Joystick network inputs

            """
            except Exception as error:
                print('\n[-]JoystickServer - ERROR, socket : %s ' % error)
                self.gl.P2CS_STOP = True

            finally:
                if connection is not None:
                    connection.close()
            """
            if connection in self.__dict__ and isinstance(connection, socket.socket):
                # further receives are disallowed.
                connection.shutdown(socket.SHUT_RD)
                connection.close()

        print('\n[+]JoystickServer - INFO, socket thread is now terminated.')


class JoystickClient(threading.Thread):

    # todo need the script to detect if joystick 1, 2, 3 etc is used joystickid
    def __init__(self, gl_, host_, port_, joystick_id_):

        threading.Thread.__init__(self)

        assert isinstance(host_, str), \
            'Expecting string for argument host_, got %s, %s instead.' % (type(host_), host_)
        assert isinstance(port_, int), \
            'Expecting integer for argument port_, got %s, %s instead.' % (type(port_), host_)
        # Port to listen on (non-privileged ports are > 1023)
        assert 0 < port_ < 65535, \
            'Incorrect value assign to port_, 0 < port_ < 65535, got %s ' % port_
        if port_ > 1023:
            print('\n[-]JoystickClient - WARNING, selected port require superuser privilege.')

        self.gl_ = gl_
        self.host = host_
        self.port = port_
        self.joystickid = joystick_id_
        self.sent_bytes = 0
        self.receive_bytes = 0

        try:

            # creates a socket object, connects to the server
            # and calls s.sendall() to send its message.
            # Lastly, it calls s.recv() to read the server’s reply.
            # The thread will block here until a connection is made.
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.connect((self.host, self.port))

        except socket.error as error:
            print('\n[-]JoystickClient - ERROR, : %s ' % error)
            if self.sock in self.__dict__ and isinstance(self.sock, socket.socket):
                self.sock.close()
        print('\n[-]JoystickClient - INFO: Connection to host %s: %s ' % (self.host, self.port))

        if self.gl_ and hasattr(self.gl_, 'JOYSTICK'):

            # JOYSTICK is an formatted joystick object class JoystickObject
            if isinstance(self.gl_.JOYSTICK, JJoystick):
                self.fetch_values = self.gl_.JOYSTICK.get_all_status

            # GL.JOYSTICK reference a joystick object unformed for the network transaction.
            # pointing the variable self.fetch_values toward a new formatted object (JoystickObject)
            # The new object will inherit the class attributes get_all_status that reference the joystick
            # status such as number of buttons, hats a and joystick positions.
            elif isinstance(self.gl_.JOYSTICK.inventory[self.joystickid], pygame.joystick.JoystickType):
                jjoy = JJoystick(self.joystickid, 0.01, verbosity_=True)
                self.fetch_values = jjoy.get_all_status

            else:
                print('\n[-]JoystickClient - ERROR, '
                      'Wrong joystick object, got type %s ' % type(self.gl_.JOYSTICK))
                raise BaseException
        else:
            print('\n[-]JoystickClient - ERROR, Missing JOYSTICK variable from self.gl_ variable class.')
            raise BaseException

        obj = self.fetch_values(self.joystickid)
        if isinstance(obj, JoystickObject) and hasattr(obj, 'name'):
            print('\n[+]JoystickClient - INFO, name %s id %s is ready.' %
                  (self.fetch_values(self.joystickid).name, self.joystickid))
        else:
            print('\n[-]JoystickClient - ERROR, Referenced object is not a Joystick object, or '
                  'Joystick object is missing attributes.')
            raise BaseException

    def kill(self):
        if hasattr(self, 'gl_') and hasattr(self.gl_, 'P2CS_STOP'):
            self.gl_.P2CS_STOP = True
            if hasattr(self, 'sock'):
                try:
                    self.sock.shutdown(socket.SHUT_RD)
                except OSError:
                    print('\n[-]Termination signal could not be delivered ')

    def run(self):

        olddata = self.fetch_values(self.joystickid)

        try:
            while not self.gl_.P2CS_STOP:

                data = self.fetch_values(self.joystickid)
                """
                print('\n')
                print('Joystick id %s ' % data.id)
                print('Joystick name %s ' % data.name)
                print('Joystick axes %s ' % data.axes)
                print('Joystick axes_status %s ' % data.axes_status)
                print('Joystick button %s ' % data.buttons)
                print('Joystick button_status %s ' % data.button_status)
                print('Joystick hats %s ' % data.hat)
                print('Joystick hats_status %s ' % data.hats_status)
                print('Joystick balls %s ' % data.balls)
                print('Joystick balls_status %s ' % data.balls_status)
                """
                if data is not None:
                    # Only send joystick info if data changed since the last check
                    # data and olddata have to be a JoystickObject instance
                    if isinstance(data, JoystickObject) and isinstance(olddata, JoystickObject):

                        if any(data.__dict__['button_status']) or any(data.__dict__['hats_status'][0]) or \
                                data.__dict__['axes_status'] != olddata.__dict__['axes_status']:

                            # if not data.__dict__ == olddata.__dict__:
                            # print(data.__dict__['button_status'])     -> all buttons
                            # print(data.__dict__['hats_status'][0])    -> all hats
                            # print(data.__dict__['axes_status'])       -> all axes

                            # Send data to the socket. The socket must be connected to a remote socket.
                            # The optional flags argument has the same meaning as for recv() above.
                            # Unlike send(), this method continues to send data from string until either
                            # all data has been sent or an error occurs. None is returned on success.
                            # On error, an exception is raised, and there is no way to determine how much data,
                            # if any, was successfully sent.
                            # print('\n[-]JoystickClient - INFO, sending data...')
                            pickle_data = pickle.dumps(data)
                            package = pickle.dumps((len(pickle_data), pickle_data))
                            self.sock.sendall(pickletools.optimize(package))

                            data_received = self.sock.recv(4096)
                            # Check the data received
                            try:
                                length, data_ = pickle.loads(data_received)
                                unpickle_data = pickle.loads(data_)

                                if unpickle_data.__dict__ != data.__dict__:
                                    print('\n[-]JoystickClient - INFO, data received not identical %s ' % time.ctime())

                                self.sent_bytes += len(pickle_data)
                                self.receive_bytes += length

                                # self.s.send(pickle.dumps(b'quit'))
                            except pickle.UnpicklingError:
                                ...
                        else:
                            # print('\n[-]JoystickClient - INFO, data identical...')
                            ...

                        olddata = data

                    else:
                        print('\n[-]JoystickClient - INFO, data is not a joystick object!. ')

                else:
                    print('\n[-]JoystickClient - INFO, No data... ')

                # if FRAME % 30 == 0:
                #    raise Exception

                # at least 1ms of pause between transfers
                time.sleep(0.001)
        except Exception as error:
            if isinstance(error, ConnectionResetError):
                print('\n[-]JoystickClient - ERROR, %s ' % 'Player 2 is disconnected...')
            else:
                print('\n[-]JoystickClient - ERROR, %s ' % error)

        finally:
            try:
                self.sock.shutdown(socket.SHUT_RDWR)
                self.sock.close()
            except OSError as error:
                print('\n[-]JoystickClient - ERROR, %s ' % error)
        print('\n[+]JoystickClient - INFO, bytes sent %s kb, received %s kb ' %
              (self.sent_bytes // 1000, self.receive_bytes // 1000))
        print('\n[+]JoystickClient - INFO, thread is now closed.')


class JoystickObject:
    """
    Create a Joystick object referencing all attributes
    """

    def __init__(self,
                 id_: int = 0,
                 name_: str = '',
                 buttons_: int = 0,
                 buttons_status_: list = None,
                 axes_: int = 0,
                 axes_status_: list = None,
                 hats_: int = 0,
                 hats_status: list = None,
                 balls_: int = 0,
                 balls_status_: list = None
                 ):
        """
        :param id_:             get the Joystick ID
        :param name_:           get the Joystick system name
        :param axes_:           get the number of axes
        :param axes_status_:    get the axes status
        :param buttons_:        get the number of buttons
        :param buttons_status_: get the buttons status
        :param hats_:           get the number of hat controls
        :param hats_status:     get the status of hat controls
        :param balls_:          get the number of trackballs
        :param balls_status_:   get the trackballs status
        """

        self.id = id_
        self.name = name_
        self.buttons = buttons_
        self.button_status = buttons_status_
        self.axes = axes_
        self.axes_status = axes_status_
        self.hat = hats_
        self.hats_status = hats_status
        self.balls = balls_
        self.balls_status = balls_status_


class JoystickAttributes:
    """
    Create a Joystick object with formatted attributes

    """

    def __init__(self,
                 id_: int = 0,
                 name_: str = '',
                 axes_: int = 0,
                 buttons_: int = 0,
                 hats_: int = 0,
                 balls_: int = 0,
                 ):
        """
        :param id_:         get the Joystick ID
        :param name_:       get the Joystick system name
        :param axes_:       get the number of axes
        :param buttons_:    get the number of buttons
        :param hats_:       get the number of hat controls
        :param balls_:      get the number of trackballs
        """
        """
        assert isinstance(id_, int), 'Expecting integer for argument id_, got %s ' % type(id_)
        assert isinstance(name_, str), 'Expecting string for argument name_, got %s ' % type(name_)
        assert isinstance(axes_, int), 'Expecting integer for argument axes_, got %s ' % type(axes_)
        assert isinstance(buttons_, int), 'Expecting integer for argument buttons_, got %s ' % type(buttons_)
        assert isinstance(hats_, int), 'Expecting integer for argument hats_, got %s ' % type(hats_)
        assert isinstance(balls_, int), 'Expecting integer for argument balls_, got %s ' % type(balls_)
        """
        self.id = id_
        self.name = name_
        self.axes = axes_
        self.button = buttons_
        self.hats = hats_
        self.balls = balls_
        try:
            self.button_status = [False] * self.button  # init the buttons status
            self.axes_status = [0] * self.axes  # init the axes status
            self.hats_status = [(0, 0)] * self.hats  # init hats status
            self.balls_status = [pygame.math.Vector2()] * self.balls  # init the trackballs

        except IndexError as error:
            print('\n[-] ERROR Joystick Object cannot be instantiated. ', error)


class JJoystick(JoystickAttributes):
    """
        Prior testing the Joystick
        1) The pygame display has to be initialised pygame.init()
    """
    PRESENT = False  # Confirm if a joystick is present (bool)
    QUANTITY = 0  # How many joystick(s) are connected (int)
    OBJECT = []  # Bind to the joystick(s) device(s)-> pygame.joystick.Joystick object

    def __init__(self,
                 joystick_id_: int = 0,
                 sensitivity_: float = 0.01,
                 verbosity_: bool = False
                 ):

        """
        :joystick_id_ id_: get the Joystick ID integer
        :sensitivity_ name_: Joystick sensitivity threshold default float 0.01, any variation below
        the threshold will be ignored.
        :param verbosity_: verbosity (bool False | True)

        """

        assert isinstance(joystick_id_, int), \
            'Expecting int for argument joystick_id_ got %s ' % type(joystick_id_)
        assert isinstance(sensitivity_, float), \
            'Expecting float for argument sensitivity_ got %s ' % type(sensitivity_)
        assert isinstance(verbosity_, bool), \
            'Expecting bool for argument verbosity_ got %s ' % type(verbosity_)
        assert isinstance(JJoystick.OBJECT, list), \
            'Expecting list for argument OBJECT got %s ' % type(JJoystick.OBJECT)

        self.verbosity = verbosity_  # default False
        self.sensitivity = sensitivity_  # axis sensitivity_
        self.init_joystick()
        self.args = None
        JoystickAttributes.__init__(self)

    def init_joystick(self):

        if not bool(pygame.joystick.get_init()):  # return bool
            # Initialize the joystick module.
            # This will scan the system for all joystick devices.
            pygame.joystick.init()

        JJoystick.QUANTITY = self.get_joystick_number()  # returns the number of joystick available

        if JJoystick.QUANTITY == 0:
            self.no_joystick()

        # at least one Joystick is present
        else:

            if self.verbosity:
                print('\n[+] Info %s joystick(s) detected...' % JJoystick.QUANTITY)

            for joystick_id in range(JJoystick.QUANTITY):

                JJoystick.PRESENT = True

                # Reference object into a python list
                jobj = pygame.joystick.Joystick(joystick_id)
                JJoystick.OBJECT.append(jobj)
                JJoystick.OBJECT[joystick_id].init()
                print('[+] Info: Joystick name %s ' % JJoystick.OBJECT[joystick_id].get_name())
                print('[+] Info: Joystick id %s initialised.' % joystick_id)
                self.args = self.get_overall_status(joystick_id)

                if self.args is not None:
                    JoystickAttributes.__init__(self, *list(self.args))
                else:
                    self.no_joystick(joystick_id)

    @staticmethod
    def pickle_data(data):
        """
            Pickle all the joystick buttons including hats and axes before
            sending the data through the network
        """
        return pickle.dumps(data)

    @staticmethod
    def adjust_quantity():
        """
        Current tested joystick failed to respond.
        Decrement quantity.
        """
        JJoystick.QUANTITY -= 1

        # None of the joystick are responding
        # Flag PRESENT is set to False (no joystick present)
        if JJoystick.QUANTITY < 0:
            JJoystick.QUANTITY = 0
            JJoystick.PRESENT = False
        else:
            JJoystick.PRESENT = True

    def no_joystick(self, id_=None):
        """ No joystick present """
        if id_ is None:
            JJoystick.QUANTITY = 0
            JJoystick.OBJECT = []
            print('\n[-] Info No Joystick available...')
        else:
            assert isinstance(id_, int), 'Expecting int for argument id_, got %s ' % type(id_)
            self.adjust_quantity()
            if isinstance(JJoystick.OBJECT, list):
                JJoystick.OBJECT[id_] = None
            else:
                raise Exception

    @staticmethod
    def get_joystick_number() -> int:
        """
            Return the number of joysticks connected to the interface (int).
            Returns 0 if no joystick available
        """
        quantity = 0
        try:
            quantity = pygame.joystick.get_count()
        except Exception as error:
            JJoystick.QUANTITY = 0
            JJoystick.PRESENT = False
            JJoystick.OBJECT = []
            print('\n[-] Error: ', error)
            quantity = 0

        finally:
            return quantity

    def get_overall_status(self, joystick_id_=0):

        """
            Fetch number of buttons, hats and axes.
            Joystick_id_ (int) select the joystick object from all joysticks that have been detected
            If an error occurred during the checks None is return otherwise return a tuple.
        """

        args = None
        try:
            assert isinstance(joystick_id_, int), \
                'Expecting int for argument joystick_id_ got %s ' % type(joystick_id_)

            obj = JJoystick.OBJECT[joystick_id_]

            args = obj.get_id(), \
                obj.get_name(), \
                obj.get_numaxes(), \
                obj.get_numbuttons(), \
                obj.get_numhats(), \
                obj.get_numballs()

            # print('\n id %s, \n name %s, \n number of axes  %s, '
            #      '\n number of button %s, \n number of hats %s, \n number of balls %s' % (tuple(args)))
            return args

        except (pygame.error, AssertionError, AttributeError) as err:
            self.adjust_quantity()
            args = None
            print('\n[-] Joystick id, %s Error: %s' % (joystick_id_, err))

        finally:
            return args

    def get_all_status(self, joystick_id_=0) -> JoystickObject:
        """
            Returns all the Joysticks attributes values (button's status, axes position and hats value.
            Returns None if an error occurred.
        """

        jobject = None
        try:
            assert len(JJoystick.OBJECT) >= joystick_id_ + 1, 'Argument Joystick_id is incorrect.'

            obj = JJoystick.OBJECT[joystick_id_]
            if JJoystick.PRESENT and isinstance(obj, pygame.joystick.JoystickType):

                JoystickAttributes.__init__(self, *list(self.get_overall_status(joystick_id_)))

                # buttons status
                for i in range(self.button):
                    self.button_status[i] = True if \
                        obj.get_button(i) else False

                # Axis status
                for axis in range(self.axes):
                    axis_response = round(obj.get_axis(axis), 3)
                    self.axes_status[axis] = axis_response if abs(axis_response) > self.sensitivity else 0.0

                # hats status
                if self.hats > 0:
                    for hat in range(self.hats):
                        self.hats_status[hat] = obj.get_hat(hat)

                # trackball
                if self.balls > 0:
                    for balls in range(self.balls):
                        self.balls_status[balls] = obj.get_ball(balls)

                jobject = JoystickObject(obj.get_id(), obj.get_name(), self.button, self.button_status, self.axes,
                                         self.axes_status, self.hats, self.hats_status, self.balls, self.balls_status)

            return jobject

        except (AssertionError, AttributeError) as err:
            print('\n[-] Joystick id, %s Error: %s' % (joystick_id_, err))
            return jobject

    def check_ball_position(self, ball_number_: int = 0, joystick_id_=0):
        """
            Get the relative position of a trackball.
            Return None if an error occurred

        """
        argument = None
        try:

            if JJoystick.PRESENT and len(JJoystick.OBJECT) > 0 and \
                    isinstance(JJoystick.OBJECT[joystick_id_], pygame.joystick.JoystickType):

                obj = JJoystick.OBJECT[joystick_id_]

                if hasattr(obj, 'balls'):
                    if obj.balls > 0:
                        assert isinstance(ball_number_, int), \
                            'Expecting int for argument ball_number_ got %s ' % type(ball_number_)
                        argument = obj.get_ball(ball_number_)
                else:
                    if obj.verbosity:
                        AssertionError('\n[-] Error JJoystick missing attribute balls.')

        except (pygame.error, AssertionError, AttributeError) as error:
            self.adjust_quantity()
            print('\n[-] Joystick id %s, Error %s ' % (joystick_id_, error))

        finally:
            return argument


def send_sigterm(host_, port_):

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.connect((host_, port_))
            data = pickle.dumps(b'quit')
            package = pickle.dumps((len(data), data))
            sock.sendall(package)
    except socket.error as error:
        print('\n[-]send_sigterm - ERROR: %s ' % error)
    finally:
        sock.close()


if __name__ == '__main__':

    # host = '192.168.1.106'  # '127.0.0.1' # '192.168.1.106'
    # port = 1025

    joystick = 0
    # socket.setdefaulttimeout(60)

    pygame.init()
    pygame.mixer.init()

    SCREENRECT = pygame.Rect(0, 0, 800, 600)
    screen = pygame.display.set_mode(SCREENRECT.size, pygame.HWSURFACE, 32)

    GL_.All = pygame.sprite.Group()
    GL_.TIME_PASSED_SECONDS = 0

    GL_.JOYSTICK = JJoystick(0, 0.01, verbosity_=True)

    clock = pygame.time.Clock()
    STOP_GAME = False

    FRAME = 1

    if GL_.JOYSTICK.PRESENT:
        server = JoystickServer(GL_, '192.168.1.109', 1025)
        server.start()
        client = JoystickClient(GL_, '192.168.1.112', 1026, joystick)
        client.start()
        ...
    else:
        print('\n No joystick present...')
        STOP_GAME = True

    while not STOP_GAME:

        pygame.event.pump()

        for event in pygame.event.get():
            keys = pygame.key.get_pressed()

            if event.type == pygame.QUIT:
                print('Quitting')
                STOP_GAME = True

            if keys[pygame.K_ESCAPE]:
                STOP_GAME = True

            if event.type == pygame.MOUSEMOTION:
                GL_.MOUSE_POS = pygame.math.Vector2(event.pos)

        GL_.All.update()
        GL_.All.draw(screen)
        GL_.TIME_PASSED_SECONDS = clock.tick(30)

        """
        pyobject = GL_.JOYSTICK.get_all_status(joystick)
        
        print('\n')
        print('Joystick id %s ' % pyobject.id)
        print('Joystick name %s ' % pyobject.name)
        print('Joystick axes %s ' % pyobject.axes)
        print('Joystick axes_status %s ' % pyobject.axes_status)
        print('Joystick button %s ' % pyobject.buttons)
        print('Joystick button_status %s ' % pyobject.button_status)
        print('Joystick hats %s ' % pyobject.hat)
        print('Joystick hats_status %s ' % pyobject.hats_status)
        print('Joystick balls %s ' % pyobject.balls)
        print('Joystick balls_status %s ' % pyobject.balls_status)
        """
        # if FRAME % 50==0:
        #    GL_.P2CS_STOP = False
        #    JoystickServer(GL_, host, port).start()
        #    JoystickClient(host, port).start()

        # if FRAME == 50:
        #    client.kill()

        # Restart the client if it dies
        if not client.is_alive():
            client = JoystickClient(GL_, '192.168.1.112', 1025, joystick)
            client.start()

        pygame.display.flip()
        FRAME += 1
        # print(FRAME)

    pygame.quit()
