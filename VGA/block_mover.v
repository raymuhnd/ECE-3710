module block_mover (
    input            vga_clk,
    input            rst,              // active low
    output reg [9:0] block_x_offset    // left edge of the moving rectangle
);

	// 25 MHz / 250,000 = one step every 10 ms, ~100 pixels per second.
	localparam COUNT = 250000;
	reg [20:0] counter;
	reg        tick;
	localparam MAX_X = 480;

	// Generate a one-clock "tick" pulse every COUNT clocks
    always @(posedge vga_clk, negedge rst) begin
        if (~rst) begin
            counter <= 0;
            tick    <= 0;
        end else if (counter == COUNT - 1) begin
            counter <= 0;
            tick    <= 1;
        end else begin
            counter <= counter + 1;
            tick    <= 0;
        end
    end

    // Move the block 1 pixel right per tick, wrap back to the left edge at the end
    always @(posedge vga_clk, negedge rst) begin
        if (~rst)
            block_x_offset <= 0;
        else if (tick) begin
            if (block_x_offset < MAX_X)
                block_x_offset <= block_x_offset + 1;
            else
                block_x_offset <= 0;
        end
    end

endmodule
