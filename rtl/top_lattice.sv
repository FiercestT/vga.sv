`include "vga_module/vga_types.sv"

/**
    An example top of how to hook up the vga controller on a lattice chip.
    Untested.
    A functional top is present in top_xilinx.
*/

localparam vga_res_cfg_t CFG = VGA_RESOLUTION_640X480_4BIT;

module top_lattice(
    output logic hsync,
    output logic vsync,
    output logic[CFG.COL_BITS - 1:0] r,
    output logic[CFG.COL_BITS - 1:0] g,
    output logic[CFG.COL_BITS - 1:0] b
);
    //Top Signals
    wire w_hosc;
    wire w_clk;
    logic i_rstn = 1;
    logic i_en   = 1;

    //48Mhz Internal Oscilator
    HSOSC #(
        .CLKHF_DIV ("0b00")
    ) hfosc_inst (
        .CLKHFPU ('1),
        .CLKHFEN ('1),
        .CLKHF   (w_hosc)
    );

    //Pixel Clock PLL (Reference vga_res_cfg_t)
    vga_pll pll_inst(
        .ref_clk_i(w_hosc),
        .rst_n_i(i_rstn),
        .outcore_o(w_clk)
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
