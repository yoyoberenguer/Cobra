#!/usr/bin/env python3

import socket

HOST = '185.166.35.5'  # The server's hostname or IP address
PORT = 16584        # The port used by the server

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((HOST, PORT))
    s.sendall(b'01')
    data = s.recv(1024)

print('Received', repr(data))