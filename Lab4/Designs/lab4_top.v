`timescale 1ns / 1ps
module lab4_top #(
    parameter PROGRAM = "lab4_program.hex"   // or "prog_regreg.hex"
)(
    input        CLOCK_50,
    input  [3:0] KEY,
    input  [9:0] SW,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR
);

    wire [15:0] result, pc, ir;
    wire [3:0]  state;
    wire [4:0]  flags;

    // slow clock: bit 22 of a counter, 50 MHz / 2^23 = about 6 Hz
    reg [22:0] div = 23'd0;
    always @(posedge CLOCK_50)
        div <= div + 23'd1;

    wire cpu_clk = SW[0] ? div[22] : CLOCK_50;

    cpu #(.INIT_FILE(PROGRAM)) u_cpu (
        .clk(cpu_clk), .rst_n(KEY[0]),
        .disp_out(result),
        .pc_out(pc), .ir_out(ir), .state_out(state), .flags_out(flags)
    );

    wire [15:0] shown = SW[1] ? ir : result;

    hex_to_seven_segment h0 (.hex_value(shown[3:0]),   .segments(HEX0));
    hex_to_seven_segment h1 (.hex_value(shown[7:4]),   .segments(HEX1));
    hex_to_seven_segment h2 (.hex_value(shown[11:8]),  .segments(HEX2));
    hex_to_seven_segment h3 (.hex_value(shown[15:12]), .segments(HEX3));
    hex_to_seven_segment h4 (.hex_value(pc[3:0]),      .segments(HEX4));
    hex_to_seven_segment h5 (.hex_value(pc[7:4]),      .segments(HEX5));

    assign LEDR[3:0] = state;
    assign LEDR[4]   = div[22];
    assign LEDR[9:5] = flags;

endmodule
