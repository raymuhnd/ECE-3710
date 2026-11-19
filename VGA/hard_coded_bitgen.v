module hard_coded_bitgen (
    input wire          vga_blank_n,
    input wire [9:0]         hcount, 
	 input wire [9:0]         vcount,
	 input wire [9:0] block_x_offset,
    output [23:0]               rgb
);

reg [7:0] r, g, b;
assign rgb = {r,g,b};

wire [9:0] x_pos, y_pos;
assign x_pos = hcount;
assign y_pos = vcount;

always @(vga_blank_n, x_pos, y_pos, block_x_offset) begin
    {r,g,b} = 0;
    if (vga_blank_n) begin
			// Draws a moving block
			if ((x_pos >= block_x_offset) && (x_pos < 160 + block_x_offset) && (y_pos >= 310) && (y_pos < 410)) begin
                r = 8'd255;
			end
			// Draws a static block
			else if ((x_pos >= 240) && (x_pos < 400) && (y_pos >= 70) && (y_pos < 170)) begin
					  g = 8'd255;
			end
         else begin
            r = 8'd255;
            g = 8'd255;
            b = 8'd255;
         end
    end
end

endmodule
