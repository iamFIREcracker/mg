#!/usr/bin/env bash

# USE:
#
#   * mg IMAGE            # open IMAGE
#   * mg --listen         # starts a image viewer daemon -- handy when trying to
#                         # open IMAGEs from a remote ssh session

MG_REMOTE_PORT=${MG_REMOTE_PORT:-5558}

listen() {
    echo "Listening on port ${MG_REMOTE_PORT}..."
    while (true); do
        python <<END
from __future__ import print_function
from tempfile import mkstemp
import os, socket, subprocess

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('localhost', ${MG_REMOTE_PORT}))
s.listen(1)
remote, _ = s.accept()
fd, path = mkstemp(suffix='.png')
with os.fdopen(fd, 'wb') as f:
    while True:
        data = remote.recv(1024)
        if not data:
            break
        f.write(data)
process = subprocess.Popen(['$0', path], stdin=subprocess.PIPE)
process.wait()
print('Image open: ' + path)
remote.close()
s.close()
END
        if [ $? -ne 0 ]; then
            break
        fi
    done
}

myopen() {
    if env | grep --quiet -F SSH_TTY; then
        echo -n "$@" | nc -N localhost ${MG_REMOTE_PORT}
    elif hash open 2>/dev/null; then
        open "$@"
    else
        cygstart "$@"
    fi
}

if [ "$1" = "--listen" ]; then
    listen
else
    myopen "$@"
fi
