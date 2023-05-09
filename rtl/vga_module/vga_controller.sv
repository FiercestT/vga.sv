`include "vga_types.sv"

/**
    The Top of the VGA Module. Implement this for VGA output functionality.

    Params
    CFG     : The config to define the behaviour of the VGA output. Default: VGA_RESOLUTION_640x480_8bit from vga_types.svh.

    Inputs
    i_rstn      : Async active low reset.
    i_clk       : The pixel clock. Must match CFG.PIX_FREQ.
    i_en        : Enable VGA output and state counting.
    i_src       : A vga_src_io interface that is used as a lookup for each pixel to send to the VGA image.
                  E.g. Storing the image in RAM/BRAM/DDR and writing a wrapper around it to support (x, y) addressing.
                  This can also be generated on-fabric, or streamed from some source.
                  The vga_controler does not have a buffer, the vga_src_io source should be buffered.

    Outputs
    o_vga       : The physical VGA output that maps to a VGA PMOD.
*/

module vga_controller # (
    parameter vga_res_cfg_t CFG = VGA_RESOLUTION_640X480_4BIT
)(
    input logic i_rstn,
    input logic i_clk,
    input logic i_en,
    vga_src_if.vga i_src,

    vga_if.out o_vga
);

    wire w_h_wen;
    wire w_v_wen;
    wire[$clog2(CFG.WIDTH)  - 1:0] w_hpos;
    wire[$clog2(CFG.HEIGHT) - 1:0] w_vpos;
    wire w_new_line;

    vga_timer #(
        .CFG(CFG.H_TIMING),
        .POS_PRELOAD(1)
    ) inst_h_timer (
        .i_rstn,
        .i_clk(i_clk),
        .i_en(i_en),
        .o_sync(o_vga.hsync),
        .o_wen(w_h_wen),
        .o_pos(w_hpos),
        .o_new_line(w_new_line)
    );

    vga_timer #(
        .CFG(CFG.V_TIMING)
    ) inst_v_timer (
        .i_rstn,
        .i_clk(i_clk),
        .i_en(i_en & w_new_line),
        .o_sync(o_vga.vsync),
        .o_wen(w_v_wen),
        .o_pos(w_vpos),
        .o_new_line()
    );

    assign i_src.addr_row = w_vpos;
    assign i_src.addr_col = w_hpos;

    wire w_oen = i_en & w_h_wen & w_v_wen;

    always_comb begin
        if(!i_rstn | !w_oen)
            {o_vga.r, o_vga.g, o_vga.b} = '0;
        else begin
            o_vga.r = i_src.col_r;
            o_vga.g = i_src.col_g;
            o_vga.b = i_src.col_b;
        end
    end
endmodule
