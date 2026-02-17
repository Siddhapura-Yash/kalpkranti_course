# ex10: Pre-emphasis Filter

A simple first-order pre-emphasis filter implemented on FPGA. It boosts high-frequency content by subtracting a fraction of the previous sample from the current one.

## What It Does

The filter computes:

```
y = x - alpha * x_prev
```

- `x` is the current 16-bit signed input sample
- `x_prev` is the previous sample
- `alpha` is 16384 (0.5 in Q15 fixed-point)

Samples are sent over UART. The FPGA filters each sample and sends the result back over UART.

## Project Structure

```
rtl/
  pr_emphasis.v    Filter core (one multiply, one subtract, one register)
  top.v            UART RX/TX, filter glue, LED blinky
  uart_rx.v        UART receiver
  uart_tx.v        UART transmitter

sim/
  tb_pr_emphasis.v Testbench for the filter block

firmware/
  ex10.py          Host script (MicroPython on Shrike) - sends samples, checks FPGA output

timing-constraints/
  top.sdc          50 MHz clock constraint
```

## Simulation

From the example root:

```bash
cd sim
iverilog -o tb_pr_emphasis.out ../rtl/pr_emphasis.v tb_pr_emphasis.v
vvp tb_pr_emphasis.out
gtkwave pre_emphasis.vcd
```

## Hardware

- Open [ex10.ffpga](../../fpga/shrike_v1/ex10.ffpga) in your FPGA toolchain to build the bitstream (do not modify the original)
- Baud rate: 115200
- Protocol: send two bytes per sample (MSB first, big-endian signed 16-bit)
- FPGA echoes filtered output in the same format

## Firmware Test

Run `ex10.py` on the Shrike MCU. It sends 20 random samples, compares FPGA output to a software reference, and prints pass/fail.
