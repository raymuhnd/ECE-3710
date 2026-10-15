`timescale 1ns / 1ps
module cond_check (
    input  wire [3:0] cond,
    input  wire [4:0] flags, 
    output reg        take // 1 = go to the target, 0 = PC + 1
);

    wire Z = flags[4]; // zero
    wire C = flags[3]; // carry/borrow
    wire F = flags[2]; // overflow
    wire L = flags[1]; // unsigned <
    wire N = flags[0]; // signed < 

	// from CR16 ISA
    localparam [3:0] EQ = 4'b0000, NE = 4'b0001,
			CS = 4'b0010, CC = 4'b0011,
			HI = 4'b0100, LS = 4'b0101,
			GT = 4'b0110, LE = 4'b0111,
			FS = 4'b1000, FC = 4'b1001,
			LO = 4'b1010, HS = 4'b1011,
			LT = 4'b1100, GE = 4'b1101,
			UC = 4'b1101, NV = 4'b1110;

    always @(*) begin
        case (cond)
            EQ: take =  Z;
            NE: take = ~Z;
            CS: take =  C;
            CC: take = ~C;
            HI: take =  L;
            LS: take = ~L;
            GT: take =  N;
            LE: take = ~N;
            FS: take =  F;
            FC: take = ~F;
            LO: take = ~L & ~Z;
            HS: take =  L |  Z;
            LT: take = ~N & ~Z;
            UC: take =  N |  Z;
            NV: take = 1'b1;
            default: take = 1'b0;
        endcase
    end

endmodule
