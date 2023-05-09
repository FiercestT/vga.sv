`include "vga_types.sv"

/**
    Manages the timings for a horizontal or vertical axis of the VGA signal.

    Params
    CFG         : The vga timing config to use for this timer. E.g. Horizontal or vertical timing at different resolutions.
                  Inherited from vga_controller's Hor/Ver timings.
    POS_PRELOAD : Should only be used for the horizontal timer.
                  o_pos will be 1 greater than r_cnt. This will give one clock cycle for vga_src to load pixel info.
                  Not applicable for the vertical timer.

    Inputs:
    i_rstn      : Async Active Low Reset
    i_clk       : Clock to increment line count
    i_en        : Enable

    Outputs:
    o_sync      : Sync Pulse
    o_wen       : Write Enable. Is the picture in the active area.
    o_new_line  : High at one cycle when the FSM goes back to the FRONT_PORCH state.
    o_pos       : The pixel in the active area.
*/

module vga_timer #(
    parameter vga_timing_cfg_t CFG = VGA_640X480_H_TIMING,
    parameter bit POS_PRELOAD = 0
)(
    input  logic i_rstn,
    input  logic i_clk,
    input  logic i_en,

    output logic o_sync,
    output logic o_wen,
    output logic o_new_line,
    output logic[$clog2(CFG.A_VISIBLE) - 1:0] o_pos
);

    logic[$clog2(CFG.A_TOTAL) - 1:0] r_cnt;
    vga_line_state_e r_state;
    vga_line_state_e r_nstate;

    always_comb begin
        r_nstate = VGA_STATE_XXX;
        case(r_state)
            VGA_STATE_FRONT_PORCH:
                if(r_cnt inside {[0:CFG.A_FRONT_PORCH-2]}) r_nstate = VGA_STATE_FRONT_PORCH;
                else                                       r_nstate = VGA_STATE_SYNC;
            VGA_STATE_SYNC:
                if(r_cnt inside {[0:CFG.A_SYNC-2]})        r_nstate = VGA_STATE_SYNC;
                else                                       r_nstate = VGA_STATE_BACK_PORCH;
            VGA_STATE_BACK_PORCH:
                if(r_cnt inside {[0:CFG.A_BACK_PORCH-2]})  r_nstate = VGA_STATE_BACK_PORCH;
                else                                       r_nstate = VGA_STATE_DISPLAY;
            VGA_STATE_DISPLAY:
                if(r_cnt inside {[0:CFG.A_VISIBLE-2]})     r_nstate = VGA_STATE_DISPLAY;
                else                                       r_nstate = VGA_STATE_FRONT_PORCH;
            default:                                       r_nstate = VGA_STATE_XXX;
        endcase
    end

    always_ff @(posedge i_clk, negedge i_rstn)
        if(!i_rstn) r_state <= VGA_STATE_BACK_PORCH;
        else if(i_en) r_state <= r_nstate;

    always_ff @(posedge i_clk, negedge i_rstn) begin
        if(!i_rstn) begin
            r_cnt <= 0;
            o_sync <= 1;
            o_new_line <= 0;
            o_pos <= 0;
            o_wen <= 0;
        end else if(i_en) begin
            //State Transition (Reset Counter)
            if(r_state != r_nstate) r_cnt <= 0;
            else                    r_cnt <= r_cnt + 1;

            //Transition for newline.
            if(r_nstate == VGA_STATE_FRONT_PORCH && r_state == VGA_STATE_DISPLAY) o_new_line <= 1;
            else                                                                  o_new_line <= 0;

            //Sync Pulse
            if(r_nstate == VGA_STATE_SYNC) o_sync <= 0;
            else                           o_sync <= 1;

            //Write Enable
            if(r_nstate == VGA_STATE_DISPLAY) o_wen <= 1;
            else                              o_wen <= 0;

            //Increment Position Output
            //Should be optimized at elbaoration.
            if(POS_PRELOAD) begin
                //Preload will incremenmt position ahead of cnt so that vga_src can get the correct pixel info and load it with 1 cycle delay ahead of output.
                if(r_nstate == VGA_STATE_DISPLAY && o_pos < CFG.A_VISIBLE-1) o_pos <= o_pos + 1;
                else                                                         o_pos <= 0;
            end else begin
                if(r_state == VGA_STATE_DISPLAY && r_nstate == VGA_STATE_DISPLAY)
                     o_pos <= o_pos + 1;
                else o_pos <= 0;
            end
        end
    end
endmodule
