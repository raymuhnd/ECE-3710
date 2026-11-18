module clk_divider
(
	input wire clk, 
	input wire rst,
	output reg div_clk
);

always @(posedge clk, negedge rst) begin
		if (~rst) begin
			div_clk <= 1'b0; 
		end
		else begin
			div_clk <= ~div_clk;
		end
	end

endmodule
