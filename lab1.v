module lab1 (
    input  [15:0] A,
    input  [15:0] B,
    input  [7:0] Opcode,
    output [15:0] C,
    output [4:0] Flags
);

    Lab1_ALU_16b alu (
        .A(A),
        .B(B),
        .Opcode(Opcode),
        .C(C),
        .Flags(Flags)
    );

endmodule