#!/bin/bash
src=../
echo "Begin Comp..."
xvlog --nolog --sv $src/rtl/vga_module/* $src/tb/* $src/rtl/test_source.sv
echo "Begin Elab..."
xelab --nolog -top vga_test_tb -snapshot snap --debug all
#xelab --nolog -top top_lattice -snapshot snap --debug all