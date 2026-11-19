module hard_coded_vga
(
	input  wire       clk,          // 50 MHz board clock (CLOCK_50)
	input  wire       rst,          // active-low reset (a KEY)
	output wire       vga_clk,      // 25 MHz -> VGA_CLK
	output wire       vga_blank_n,  // -> VGA_BLANK_N
	output wire       vga_sync_n,   // -> VGA_SYNC_N (not used, tie low)
	output wire       vga_vs,       // -> VGA_VS
	output wire       vga_hs,       // -> VGA_HS
	output wire [7:0] r,            // -> VGA_R
	output wire [7:0] g,            // -> VGA_G
	output wire [7:0] b             // -> VGA_B
);

wire [9:0] hcount, vcount, block_x_offset;

// The DAC's sync-on-green input isn't used
assign vga_sync_n = 1'b0;

clk_divider clk_div
(
	.clk(clk),
	.rst(rst),
	.div_clk(vga_clk)
);

vga_controller vga_ctrl (
	.vga_clk(vga_clk),
	.rst(rst),
	.vga_hs(vga_hs),
	.vga_vs(vga_vs),
	.vga_blank_n(vga_blank_n),
	.hcount(hcount),
	.vcount(vcount)
);

block_mover block_mov (
    .vga_clk(vga_clk),
    .rst(rst),
    .block_x_offset(block_x_offset)
);

hard_coded_bitgen blockgen_inst (
    .vga_blank_n(vga_blank_n),
    .hcount(hcount),
    .vcount(vcount),
    .block_x_offset(block_x_offset),
    .rgb({r, g, b})
);

endmodule
