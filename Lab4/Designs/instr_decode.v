`timescale 1ns / 1ps

module instr_decode(
    input [15:0] instruction,
    output [7:0] alu_op,
    output [3:0] ra_addr,
    output [3:0] rb_addr,
    output [7:0] disp, // to pc_unit
    output [3:0] cond, 
    output reg [15:0] imm16;
    output is_alu,
    output use_imm, 
    output is_load,
    output is_store,
    output is_branch, 
    output is_jump,
    output is_jal,
    output reg_write,
    output flag_en
    );
    
    wire [3:0] op  = instruction[15:12];
    wire [3:0] ext = instruction[7:4];

    assign ra_addr = instruction[11:8];
    assign rb_addr = instruction[3:0];
    assign disp    = instruction[7:0];
    assign cond    = instruction[11:8];

    // class decode from ALU
    wire is_r = (op == 4'b0000) &&
                (ext == 4'b0001 || ext == 4'b0010 || ext == 4'b0011 ||
                 ext == 4'b0101 || ext == 4'b1001 || ext == 4'b1011 ||
                 ext == 4'b1101);                  // AND OR XOR ADD SUB CMP MOV
    wire is_i = (op == 4'b0001 || op == 4'b0010 || op == 4'b0011 ||
                 op == 4'b0101 || op == 4'b1001 || op == 4'b1011 ||
                 op == 4'b1101 || op == 4'b1111);  // ANDI ORI XORI ADDI SUBI CMPI MOVI LUI
    wire is_lsh  = (op == 4'b1000) && (ext == 4'b0100);
    wire is_lshi = (op == 4'b1000) && (ext[3:1] == 3'b000);

    assign is_alu    = is_r | is_i | is_lsh | is_lshi;
    assign use_imm   = is_i | is_lshi;
    assign is_load   = (op == 4'b0100) && (ext == 4'b0000);
    assign is_store  = (op == 4'b0100) && (ext == 4'b0100);
    assign is_jump   = (op == 4'b0100) && (ext == 4'b1100);
    assign is_jal    = (op == 4'b0100) && (ext == 4'b1000);
    assign is_branch = (op == 4'b1100);

    // CMP CMPI  do not write back
    wire is_cmp = (op == 4'b1011) || (op == 4'b0000 && ext == 4'b1011);
    assign reg_write = is_alu & ~is_cmp;

    // only ADD, ADDI, SUB, SUBI, CMP, CMPI change flags
    assign flag_en = (op == 4'b0000 && (ext == 4'b0101 || ext == 4'b1001 || ext == 4'b1011)) ||
                     (op == 4'b0101 || op == 4'b1001 || op == 4'b1011);

    assign alu_op = is_alu ? {op, ext} : 8'h00;

    always @(*) begin
        case (op)
            4'b0101, 4'b1001, 4'b1011:            // ADDI SUBI CMPI: sign extend
                imm16 = {{8{instruction[7]}}, instruction[7:0]};
            4'b0001, 4'b0010, 4'b0011, 4'b1101:   // ANDI ORI XORI MOVI: zero extend
                imm16 = {8'h00, instruction[7:0]};
            4'b1111:                              // LUI
                imm16 = {instruction[7:0], 8'h00};
            4'b1000:                              // LSHI: 5-bit signed amount
                imm16 = {{11{instruction[4]}}, instruction[4:0]};
            default:
                imm16 = 16'h0000;
        endcase
    end
    
endmodule
