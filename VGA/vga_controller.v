module vga_controller (
	input  wire       vga_clk,     // 25 MHz pixel clock from the clock divider
	input  wire       rst,         // active-low reset (KEY on the board)
	output wire       vga_hs,
	output wire       vga_vs,
	output wire       vga_blank_n,
	output reg  [9:0] hcount,
	output reg  [9:0] vcount
);

// Parameters for a VGA display resolution of 640 x 480 pixels (at a 60Hz refresh rate so 60 frames/second) display
// dropping our 50MHz clock to a 25MHz pixel clock (because 800 pixels/line * 525 lines/frame * 60 frames/second = 
// 25.2M pixels/second = 25.2MHz vga clock, but we'll use 25MHz vga clock)

// NOTE: Because we will use a 25MHz VGA clock instead of 25.2MHz the calculations below are slightly off 
// -- you may change this if you want BUT it should be fine for your Lab 5 check offs.

parameter H_SYNC        = 10'd96;  // Horizontal Sync Region -- 96 pixels
parameter H_BACK_PORCH  = 10'd48;  // Horizontal Back Porch -- 48 pixels
parameter H_DISPLAY     = 10'd640; // Horizontal Display Region -- 640 pixels
parameter H_FRONT_PORCH = 10'd16;  // Horizontal Front Porch -- 16 pixels
parameter H_TOTAL       = 10'd800; // Horizontal Total Width -- 96 + 16 + 640 + 48 = 800 pixels

parameter V_SYNC        = 10'd2;   // Vertical Sync Region -- 2 lines
parameter V_BACK_PORCH  = 10'd33;  // Vertical Back Porch -- 33 lines
parameter V_DISPLAY     = 10'd480; // Vertical Display Region -- 480 lines
parameter V_FRONT_PORCH = 10'd10;  // Vertical Front Porch -- 10 lines
parameter V_TOTAL       = 10'd525; // Vertical Total Width -- 2 + 33 + 480 + 10 = 525 lines

// where each sync pulse starts and ends
localparam H_SYNC_START = H_DISPLAY + H_FRONT_PORCH;   // 656
localparam H_SYNC_END   = H_SYNC_START + H_SYNC;       // 752
localparam V_SYNC_START = V_DISPLAY + V_FRONT_PORCH;   // 490
localparam V_SYNC_END   = V_SYNC_START + V_SYNC;       // 492

// hcount counts every pixel clock; vcount steps once at the end of each line.
always @(posedge vga_clk, negedge rst) begin
    if (~rst) begin
        hcount <= 10'd0;
        vcount <= 10'd0;
    end
    else if (hcount == H_TOTAL - 1) begin       // end of line
        hcount <= 10'd0;
        if (vcount == V_TOTAL - 1)              // end of frame
            vcount <= 10'd0;
        else
            vcount <= vcount + 10'd1;
    end
    else begin
        hcount <= hcount + 10'd1;
    end
end

// Sync signals are active LOW: 0 only inside the sync pulse region.
assign vga_hs = ~((hcount >= H_SYNC_START) && (hcount < H_SYNC_END));
assign vga_vs = ~((vcount >= V_SYNC_START) && (vcount < V_SYNC_END));

// HIGH only in the visible 640 x 480 area; LOW in porches and syncs.
assign vga_blank_n = (hcount < H_DISPLAY) && (vcount < V_DISPLAY);

endmodule
