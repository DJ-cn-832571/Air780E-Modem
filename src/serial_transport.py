"""Raw serial transport; never sends speculative AT commands."""
import os
import termios
class ATSerial:
    def __init__(self, path): self.path, self.fd = path, None
    def __enter__(self):
        self.fd = os.open(self.path, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        try:
            attrs = termios.tcgetattr(self.fd)
            attrs[0] = attrs[1] = attrs[3] = 0
            attrs[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
            attrs[4] = attrs[5] = termios.B115200
            attrs[6][termios.VMIN] = attrs[6][termios.VTIME] = 0
            termios.tcsetattr(self.fd, termios.TCSANOW, attrs)
            return self
        except Exception:
            os.close(self.fd); self.fd = None; raise
    def __exit__(self, *args):
        if self.fd is not None: os.close(self.fd); self.fd = None
