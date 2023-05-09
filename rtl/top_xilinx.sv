`include "vga_module/vga_types.sv"

/**
    Working Xilinx Top.
    Shown in the readme demo.
    Tested on a Zybo Z7-10.

    Clocking Wizard PLL to Pixel Clock [sysclk -> 25.175MHz] (see desired clock from vga_res_cfg_t)
*/

localparam vga_res_cfg_t CFG = VGA_RESOLUTION_640X480_4BIT;

module top_xilinx (
    input  logic sysclk,
    output logic hsync,
    output logic vsync,
    output logic[CFG.COL_BITS - 1:0] r,
    output logic[CFG.COL_BITS - 1:0] g,
    output logic[CFG.COL_BITS - 1:0] b
);
    //Top Signals
    wire w_clk;
    logic i_rstn;
    logic i_en = 1;

    //Pixel Clock PLL (Reference vga_res_cfg_t)
    clk_wiz_0 pll_inst (
        .clk_in(sysclk),
        .locked(i_rstn),
        .clk_out(w_clk)
    );

    //Instantiate vga_src_io interface for vga_src to vga_controller. Pass the config.
    vga_src_if #(.CFG(CFG)) src();

    //Create test_source, which will generate a test pixel output for the vga_controller. Connect the vga_src_io.
    //This module can be anything as long as it provides a source for the vga_controller that conforms to the vga_src_io interface.
    test_source #(
        .COL_BITS(CFG.COL_BITS)
    ) test_src(
        .i_rstn,
        .i_clk(w_clk),
        .i_en,
        .io(src)
    );

    //Create the interface for the physical VGA IO.
    vga_if #(.COL_BITS(CFG.COL_BITS)) vga();

    //Create the VGA controller. This will generate the timing signals and colors (vga_src_io), and output them to the vga_io interface.
    vga_controller #(
        .CFG(CFG)
    ) vga_controller (
        .i_rstn,
        .i_clk(w_clk),
        .i_en,
        .i_src(src),
        .o_vga(vga)
    );

    //Assign VGA output signals from the vga_io interface from the vga_controller.
    assign hsync = vga.hsync;
    assign vsync = vga.vsync;
    assign r     = vga.r;
    assign g     = vga.g;
    assign b     = vga.b;

endmodule
