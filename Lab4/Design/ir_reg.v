`timescale 1ns/1ps

module ir_reg(
    input clk,
    input rst_n,
    input ir_en,
    input [15:0] data_in,
    output reg [15:0] ir

);

    always@(posedge clk)begin
        if(!rst_n)begin
            ir <= 16'd0;
        end else if (ir_en) begin
            ir <= data_in;
        end
    
    end
    
endmodule