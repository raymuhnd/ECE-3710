`timescale 1ns / 1ps
//   KEY[0] : reset, active low
//   HEX3-HEX0 : the last word the program stored to address 0x00FF 
//   HEX5-HEX4 : shows where the program is / where it halted (low byte)
//   LEDR[3:0] : current state
module lab4_top (
    input        CLOCK_50,
    input  [3:0] KEY,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR
);

    wire [15:0] result, pc, ir;
    wire [3:0]  state;

    cpu #(.INIT_FILE("lab4_program.hex")) u_cpu (
        .clk(CLOCK_50), .rst_n(KEY[0]),
        .disp_out(result),
        .pc_out(pc), .ir_out(ir), .state_out(state)
    );

    hex_to_seven_segment h0 (.hex_value(result[3:0]),   .segments(HEX0));
    hex_to_seven_segment h1 (.hex_value(result[7:4]),   .segments(HEX1));
    hex_to_seven_segment h2 (.hex_value(result[11:8]),  .segments(HEX2));
    hex_to_seven_segment h3 (.hex_value(result[15:12]), .segments(HEX3));
    hex_to_seven_segment h4 (.hex_value(pc[3:0]),       .segments(HEX4));
    hex_to_seven_segment h5 (.hex_value(pc[7:4]),       .segments(HEX5));

    assign LEDR[3:0] = state;
    assign LEDR[9:4] = 6'b000000;

endmodule
