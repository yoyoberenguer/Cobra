import socket
import sys
import time
import datetime

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# Bind the socket to the port
server_address = ('192.168.1.118', 30052)
sock.bind(server_address)
# Listen for incoming connections
sock.listen(1)


IMEI = ['352093084130813']


def accept(connection):
        connection.sendall(b'\x01')
        return


def ack_packets():
    # print(bytes(4 - len(bytes([packets_]))) + bytes([packets_]))
    connection.sendall(b'\x00\x00\x00\x21')
    pass


def read_imei(data_):
    return data_[2:]    # trim the first 2 bytes (\x00\x0f)


def get_codec(data_):
    return data_[16:18]


def get_header_length(data_):
    return data_[:16]


def get_packets_number(data_):
    return data_[18:20]


def get_timestamp(data_):
    timestamp = str(int(data_[20:36], 16))
    readable = datetime.datetime.fromtimestamp(int(timestamp[:-3])).isoformat()
    return readable


def get_priority(data_):
    return data_[36:38]


def get_longitude(data_):
    return int(data_[38:46], 16)


def get_latitude(data_):
    return int(data_[46:54], 16)


authenticated = False

while True:
    # Wait for a connection
    print('waiting for a connection')
    connection, client_address = sock.accept()
    try:
        print('connection from', client_address)

        # Receive the data in small chunks and retransmit it
        while True:
            data = connection.recv(2048)

            print('Received "%s"' % data)

            if not authenticated:
                imei = read_imei(data).decode('UTF-8')
                print(imei)
                if imei in IMEI:
                    print('Authenticated IMEI :', read_imei(data))
                    authenticated = True
                    accept(connection)
                continue

            if authenticated and len(data) > 0:
                data = data.hex()
                print('AVL data packet header: ', get_header_length(data))
                print('Codec: ', get_codec(data))
                print('packet number: ', get_packets_number(data))
                print('timestamp: ', get_timestamp(data))
                print('longitude :', get_longitude(data))
                print('latitude :', get_latitude(data))
                ack_packets()
            else:
                print('no more data from', client_address)
                break

    finally:
        # Clean up the connection
        connection.close()