# 📺 VGA Controller IP

A VGA Display Controller IP for use with a VGA PMOD on an FPGA. Designed to be platform agnostic. Written in SystemVerilog.

## 📖 Usage

See [`docs/howto.md`](/docs/howto.md).

## 📷 Screenshots

The generated test image of `test_source.sv` (white is the image border).
![](/images/test.jpg)

The development board + VGA Pmod.
![](/images/board.jpg)

## 🔖 Compatibility

- Xilinx: Developed and Tested on Zybo Z7-10 with Zynq 7010.
- Lattice: Synthesizes and uploads, but functionality untested.
- Altera: Almost synthesizes. Case inside SystemVerilog construct of `rtl/vga_timer.sv` is unsupported by Quartus, and it will not synthesize without modification.

## 🧑‍💻 Feedback and Issues

Feel free to leave feedback in the discussions or issues page.
