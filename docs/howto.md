# Implementation and Use Guide

## 1. Import and Include

Copy over the `rtl/vga_module/* folder`.

Add this at the top of the file where the vga_controller will be implemented.

```sv
`include "vga_types.sv"
```

## 2. Create/Use a Config

Create a timing configuration for the VGA output.

There are 2 premade VGA timing configs in `vga_types.sv`.

1) `VGA_RESOLUTION_640X480_4BIT`: 640x480 with 4 bit color (444 rgb). **DEFAULT**
2) `VGA_RESOLUTION_640X480_1BIT`: 640x480 with 1 bit color (111 rgb).

**If you wish to use the above configs, you can skip to step 3.**

You can find VGA timing info here http://tinyvga.com/vga-timing.

Create your custom timing config as shown below. 

```sv
parameter vga_res_cfg_t VGA_RESOLUTION_640X480_4BIT = '{
    25_175_000, //Pixel Clock (This is just for reference, the value is unused)
    640, //Display Width
    480, //Display Height
    4,   //Color Bits (4 = 444 rgb, 2 = 222rgb, etc.)
    '{640, 16, 96, 48, 800}, //Horizontal Timing
    '{480, 10, 2,  33, 525}  //Vertical Timing
    //Timing is in the format of {VISIBLE, FRONT PORCH, SYNC, BACK PORCH, TOTAL}
};
```

## 3. Create Interfaces

There are 2 interfaces that the vga_controller uses.

1) `vga_src_if`: Video Source Interface. The `vga_controller` uses this to get the color value of a pixel.
2) `vga_if`: VGA PMOD Output Interface. This should match the pinout of your VGA connector.

```sv
//Your custom config or the default ones.
localparam vga_cfg_t CFG = VGA_RESOLUTION_640X480_4BIT;

//(Optional) If parameters are left blank, they will default to VGA_RESOLUTION_640x480_4BIT.

//VGA Source Interface
vga_src_if #(.CFG(CFG)) src();

//VGA Output PMOD Interface
vga_if #(.COL_BITS(CFG.COL_BITS)) vga();

//(Optional) You may have to map the vga_if to output pins of your top.
assign hsync = vga.hsync;
assign vsync = vga.vsync;
assign r     = vga.r;
assign g     = vga.g;
assign b     = vga.b;
```

## 4. Create a VGA Source Module

The `vga_controller` uses the `vga_src_if` interface to get a pixel value from a source and output it to the display. 

`vga_src_if` has 5 inputs/outputs.

```sv
//From the perspective of vga_src_if.mem (the memory side).
//Inputs/Outputs flipped  with vga_src_if.vga (the vga_controller side).
input addr_row  //Pixel Row (Y) (Between 0 -> HEIGHT-1)
input addr_col  //Pixel Column (X) (Between 0 -> WIDTH-1)
output col_r    //RGB Outputs for each (X,Y) Co-ordinate.
output col_g    //These outputs must be held by a flop/buffered
output col_b    //vga_controller expects a 1 cycle read delay
```

This alows the VGA source to be user sourced from:
- BRAM
- DDR
- Generated on fabric with custom logic

Buffering is done by the user implemented module.

**vga_controller expects a one clock cycle delay. That is, one flip flop at the output of the vga source module for RGB values.**

### 4.1. A VGA Source Example

This example shows a fabric generated image.

```sv
module test_source #(
    parameter int COL_BITS = 4
)(
    input logic i_rstn,
    input logic i_clk,
    input logic i_en,

    vga_src_if.mem io
);
    logic[COL_BITS - 1:0] buf_r;
    logic[COL_BITS - 1:0] buf_g;
    logic[COL_BITS - 1:0] buf_b;

    assign {io.col_r, io.col_g, io.col_b} = {buf_r, buf_g, buf_b};

    always_ff @(posedge i_clk, negedge i_rstn) begin
        if(!i_rstn) begin
            {buf_r, buf_g, buf_b} <= '0;
        end else if(i_en) begin
            buf_r <= '1;
            buf_g <= '0;
            buf_b <= '1;
        end
    end
endmodule
```

## 5. Finishing Up

### 5.1. Add the Source
```sv
//Test Image Source
test_source #(
    .COL_BITS(CFG.COL_BITS)
) test_src(
    .i_rstn,
    .i_clk(w_clk),
    .i_en,
    .io(src)
);
```
### 5.2. Add the VGA Controller
```sv
//VGA Controller Core
vga_controller #(
    .CFG(CFG)
) vga_controller (
    .i_rstn,
    .i_clk(w_clk),
    .i_en,
    .i_src(src),
    .o_vga(vga)
);
```

## 6. Top Example

An example for a Lattice ice40 top exists in `rtl/top_lattice.sv`.

**Checklist**

1) Import `vga_types.sv`
2) Created Config
3) Create Interfaces
4) Create VGA Source Module
5) Create VGA Controller
6) PLL for VGA Controller and VGA Source