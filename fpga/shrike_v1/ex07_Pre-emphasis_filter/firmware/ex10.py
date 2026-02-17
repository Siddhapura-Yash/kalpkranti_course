import shrike
shrike.flash("FPGA_bitstream_MCU.bin")

from machine import UART, Pin
import time
import urandom
import struct

ALPHA_Q15 = 16384

uart = UART(0, baudrate=115200, tx=Pin(0), rx=Pin(1))

def to_int16(val):
    return (val + 32768) % 65536 - 32768

def pre_emphasis_sw(x, x_prev):
    alpha_x_prev = (x_prev * ALPHA_Q15) >> 15
    return to_int16(x - alpha_x_prev)

def send_sample(value):
    uart.write(struct.pack(">h", value))

def read_sample():
    if uart.any() >= 2:
        return struct.unpack(">h", uart.read(2))[0]
    return None

print("Syncing FPGA state...")

send_sample(0)
while uart.any() < 2:
    time.sleep_ms(10)
uart.read(2)

x_prev = 0
print("Starting test...\n")
for i in range(20):
    x = urandom.getrandbits(16) - 32768
    send_sample(x)
    timeout = 0
    y_fpga = None
    while timeout < 100:
        y_fpga = read_sample()
        if y_fpga is not None:
            break
        time.sleep_ms(10)
        timeout += 1
    if y_fpga is not None:
        y_expected = pre_emphasis_sw(x, x_prev)
        error = y_fpga - y_expected
        print("x:", x,
              "| FPGA:", y_fpga,
              "| Expected:", y_expected,
              "| Error:", error)
    else:
        print("UART Timeout!")

    x_prev = x
    time.sleep(1)

