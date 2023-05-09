`include "vga_module/vga_types.sv"

/**
    Simple dummy image source for testing.
    This will generate a test image.
    See vga_src_io and the readme to make your own implementation.
*/

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

    wire[COL_BITS - 1:0] r_grad = io.addr_col / 40;

    always_ff @(posedge i_clk, negedge i_rstn) begin
        if(!i_rstn) begin
            {buf_r, buf_g, buf_b} <= '0;
        end else if(i_en) begin
            //White Outline
            if(io.addr_row inside {0, 479} || io.addr_col inside {0, 639})
                {buf_r, buf_g, buf_b} <= {4'hf, 4'hf, 4'hf};
            //Black Inside White Outline
            else if(io.addr_row inside {1, 478} || io.addr_col inside {1, 638})
                {buf_r, buf_g, buf_b} <= '0;
            //White
            else if(io.addr_row inside {[0:59]})
                {buf_r, buf_g, buf_b} <= {r_grad, r_grad, r_grad};
            //Red
            else if(io.addr_row inside {[60:119]})
                {buf_r, buf_g, buf_b} <= {r_grad, 4'h0, 4'h0};
            //Magenta
            else if(io.addr_row inside {[120:179]})
                {buf_r, buf_g, buf_b} <= {r_grad, 4'h0, r_grad};
            //Blue
            else if(io.addr_row inside {[180:239]})
                {buf_r, buf_g, buf_b} <= {4'h0, 4'h0, r_grad};
            //Cyan
            else if(io.addr_row inside {[240:299]})
                {buf_r, buf_g, buf_b} <= {4'h0, r_grad, r_grad};
            //Green
            else if(io.addr_row inside {[300:359]})
                {buf_r, buf_g, buf_b} <= {4'h0, r_grad, 4'h0};
            //Yellow
            else if(io.addr_row inside {[360:419]})
                {buf_r, buf_g, buf_b} <= {r_grad, r_grad, 4'h0};
            //White
            else if(io.addr_row inside {[420:479]})
                {buf_r, buf_g, buf_b} <= {r_grad, r_grad, r_grad};
            else
                {buf_r, buf_g, buf_b} <= '0;
        end
    end
endmodule
