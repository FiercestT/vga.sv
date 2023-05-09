`include "../rtl/vga_module/vga_types.sv"

module vga_test_tb();
    localparam vga_res_cfg_t CFG = VGA_RESOLUTION_640X480_4BIT;

    //Inputs
    logic i_clk  = 0;
    logic i_rstn = 0;
    logic i_en   = 0;

    //VGA Source Interface
    vga_src_if #(.CFG(CFG)) src();

    //Test Image Source
    test_source #(
        .COL_BITS(CFG.COL_BITS)
    ) test_src(
        .i_rstn,
        .i_clk(i_clk),
        .i_en,
        .io(src)
    );

    //VGA Output PMOD Interface
    vga_if #(.COL_BITS(CFG.COL_BITS)) vga();

    //VGA Controller Core
    vga_controller #(
        .CFG(CFG)
    ) vga_controller (
        .i_rstn,
        .i_clk(i_clk),
        .i_en,
        .i_src(src),
        .o_vga(vga)
    );

    //Testbench Driver
    //Reset for 50ns, No enable until 100ns.
    //21.175MhZ clock
    always  #(39.72) i_clk = ~i_clk;
    initial #50 i_rstn = 1;
    initial #100 i_en  = 1;

    bit fin = 0;
    always @(posedge i_clk)
        if(src.addr_row == CFG.HEIGHT - 1 && src.addr_col == CFG.WIDTH - 1)
            if(fin == 1) begin
                $display("Simulated one full frame. Stopping.");
                $finish;
            end else fin = 1;
endmodule
