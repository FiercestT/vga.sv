`ifndef VGA_TYPES

//VGA Types

// VGA Output Module Interface
interface vga_if # (
    parameter int COL_BITS = 4
);
    logic hsync;
    logic vsync;
    logic[COL_BITS - 1:0] r;
    logic[COL_BITS - 1:0] g;
    logic[COL_BITS - 1:0] b;

    modport out (output hsync, vsync, r, g, b);
    modport in  (input  hsync, vsync, r, g, b);
endinterface

// VGA Timing States
typedef enum logic[2:0] {
    VGA_STATE_XXX, //If you get this something went wrong
    VGA_STATE_FRONT_PORCH,
    VGA_STATE_SYNC,
    VGA_STATE_BACK_PORCH,
    VGA_STATE_DISPLAY
} vga_line_state_e;

// VGA Configs

// Defines the pixel timings of each region.
typedef struct {
    int A_VISIBLE;     // Visible region
    int A_FRONT_PORCH; // Front porch
    int A_SYNC;        // Sync pulse
    int A_BACK_PORCH;  // Back porch
    int A_TOTAL;       // Total line pixels (sum the above)
} vga_timing_cfg_t;

// Defines the config that the vga_controller should adhere to.
typedef struct {
    int PIX_FREQ;              // Unused, use as reference. Pixel frequency.
    int WIDTH;                 // Visible display area width.
    int HEIGHT;                // Visible display area height.
    int COL_BITS;              // How many bits are to be used in each R, G, B component.
                               // E.g. If 8 bits cannot be used due to RAM not having enough space.
    vga_timing_cfg_t H_TIMING; // Fill in with the horizontal timing info
    vga_timing_cfg_t V_TIMING; // Fill in with the vertical timing info
} vga_res_cfg_t;

//Defaults
parameter vga_timing_cfg_t VGA_640X480_H_TIMING = '{640, 16, 96, 48, 800};
parameter vga_timing_cfg_t VGA_640X480_V_TIMING = '{480, 10, 2,  33, 525};
parameter vga_res_cfg_t VGA_RESOLUTION_640X480_1BIT = '{
    25_175_000,
    640,
    480,
    1,
    VGA_640X480_H_TIMING,
    VGA_640X480_V_TIMING
};

parameter vga_res_cfg_t VGA_RESOLUTION_640X480_4BIT = '{
    25_175_000,
    640,
    480,
    4,
    VGA_640X480_H_TIMING,
    VGA_640X480_V_TIMING
};

//RAM Interface
//Implement your image RAM in a wrapper exposing this interface that connects to vga_controller
interface vga_src_if #(
    parameter vga_res_cfg_t CFG = VGA_RESOLUTION_640X480_4BIT
);
    wire[$clog2(CFG.HEIGHT) - 1:0] addr_row;
    wire[$clog2(CFG.WIDTH) - 1:0] addr_col;
    wire[CFG.COL_BITS - 1:0] col_r;
    wire[CFG.COL_BITS - 1:0] col_g;
    wire[CFG.COL_BITS - 1:0] col_b;

    modport mem (input addr_row, addr_col, output col_r, col_g, col_b);
    modport vga (input col_r, col_g, col_b, output addr_row, addr_col);
endinterface

`define VGA_TYPES
`endif
