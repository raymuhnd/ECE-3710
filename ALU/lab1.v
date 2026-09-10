/*
 * FPGA demonstration wrapper for Lab1_ALU_16b.
 *
 * NOTE: switches are ACTIVE LOW on the DE-series boards, so every switch
 * input is inverted right at the top of this module before use.
 *
 * Switch assignments (logical / active-high, after inversion):
 *     SW[3:0] = selects one of 16 ALU operations (see table below)
 *     SW[9:7] = selects one of 8 hard-coded values for A (lhs)
 *     SW[6:4] = selects one of 8 hard-coded values for B (rhs)
 *
 * LED assignments:
 *     LEDR[0]   = selected test passed (result + flags match, when checked)
 *     LEDR[1]   = result matches expected (forced 1 for un-checked ops)
 *     LEDR[2]   = flags match expected   (forced 1 for un-checked ops)
 *     LEDR[3]   = selected opcode is implemented
 *     LEDR[8:4] = actual Flags[4:0] from the DUT (Z, Carry, Ovf, LT, Neg)
 *     LEDR[9]   = selected, implemented test FAILED auto-check
 *
 * Seven-segment assignments:
 *     HEX3:HEX0 = actual ALU result C, in hex
 *     HEX5      = SW[9:7] index (which A value is selected, 0-7)
 *     HEX4      = SW[6:4] index (which B value is selected, 0-7)
 */
module demo_ALU (
    input  [9:0] SW,
    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5
);

    // ---- de-invert the active-low switches -------------------------
    wire [3:0] op_sel  = ~SW[3:0];
    wire [2:0] lhs_sel = ~SW[9:7];
    wire [2:0] rhs_sel = ~SW[6:4];

    reg  [15:0] A, B;
    reg  [7:0]  Opcode;
    wire [15:0] C;
    wire [4:0]  Flags;

      Lab1_ALU_16b alu (
        .A(A),
        .B(B),
        .Opcode(Opcode),
        .C(C),
        .Flags(Flags)
    );

    // ---- operand selection --------------------------------------------
    always @(*) begin
        case (lhs_sel)
            3'd0: A = 16'h0000;
            3'd1: A = 16'h0001;
            3'd2: A = 16'h7FFF;
            3'd3: A = 16'h8000;
            3'd4: A = 16'hFFFF;
            3'd5: A = 16'hAAAA;
            3'd6: A = 16'h5555;
            3'd7: A = 16'h0064;
            default: A = 16'h0000;
        endcase

        case (rhs_sel)
            3'd0: B = 16'h0000;
            3'd1: B = 16'h0001;
            3'd2: B = 16'h7FFF;
            3'd3: B = 16'h8000;
            3'd4: B = 16'hFFFF;
            3'd5: B = 16'hAAAA;
            3'd6: B = 16'h5555;
            3'd7: B = 16'h0064;
            default: B = 16'h0000;
        endcase
    end

    // ---- opcode selection ------------------------------------------
    always @(*) begin
        case (op_sel)
            4'd0:  Opcode = 8'b00000000; // NOP
            4'd1:  Opcode = 8'b00000001; // AND
            4'd2:  Opcode = 8'b00000010; // OR
            4'd3:  Opcode = 8'b00000011; // XOR
            4'd4:  Opcode = 8'b00000100; // NOT
            4'd5:  Opcode = 8'b00000101; // ADD
            4'd6:  Opcode = 8'b00000110; // ADDU
            4'd7:  Opcode = 8'b00000111; // ADDC
            4'd8:  Opcode = 8'b00001001; // SUB
            4'd9:  Opcode = 8'b00001010; // SUBC
            4'd10: Opcode = 8'b00001011; // CMP
            4'd11: Opcode = 8'b10000100; // LSH
            4'd12: Opcode = 8'b00010101; // ALSH
            4'd13: Opcode = 8'b01011010; // ADDI (imm nibble = 1010)
            4'd14: Opcode = 8'b10000001; // LSHI (imm bit  = 1)
            4'd15: Opcode = 8'b10110011; // CMPI (imm nibble = 0011)
            default: Opcode = 8'b00000000;
        endcase
    end

    // ---- golden reference model (independent of the DUT's code) ------
    reg  [15:0] expected_result;
    reg  [4:0]  expected_flags;
    reg         valid_test;
    reg         skip_check; 
    reg  [16:0] sum17, diff17;

    always @(*) begin
        expected_result = 16'h0000;
        expected_flags  = 5'b00000;
        valid_test = 1'b1;
        skip_check = 1'b0;
        sum17           = 17'b0;
        diff17          = 17'b0;

        case (op_sel)
            4'd0: begin // NOP
                expected_result = 16'h0000;
                expected_flags[4] = 1'b1; // Z
            end
            4'd1: begin // AND
                expected_result = A & B;
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            4'd2: begin // OR
                expected_result = A | B;
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            4'd3: begin // XOR
                expected_result = A ^ B;
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            4'd4: begin // NOT
                expected_result = ~A;
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            4'd5, 4'd13: begin // ADD / ADDI
                sum17 = {1'b0, A} + {1'b0, B};
                expected_result = sum17[15:0];
                expected_flags[3] = sum17[16];
                expected_flags[2] = (A[15] == B[15]) && (A[15] != expected_result[15]);
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            4'd6: begin // ADDU
                sum17 = {1'b0, A} + {1'b0, B};
                expected_result = sum17[15:0];
                expected_flags[3] = sum17[16];
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            4'd7: begin // ADDC - depends on prior Flags[3], not auto-checked
                skip_check = 1'b1;
            end
            4'd8: begin // SUB
                diff17 = {1'b0, A} - {1'b0, B};
                expected_result = diff17[15:0];
                expected_flags[3] = diff17[16];
                expected_flags[2] = (A[15] ^ B[15]) & (A[15] ^ expected_result[15]);
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            4'd9: begin // SUBC - depends on prior Flags[3], not auto-checked
                skip_check = 1'b1;
            end
            4'd10, 4'd15: begin // CMP / CMPI
                expected_result = 16'h0000;
                expected_flags[4] = (A == B);
                expected_flags[1] = (A < B);
                expected_flags[0] = ($signed(A) < $signed(B));
            end
            4'd11, 4'd14: begin // LSH / LSHI
                if (B[15] == 1'b0)
                    expected_result = A << B;
                else
                    expected_result = A >> (-B);
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            4'd12: begin // ALSH
                if (B[15] == 1'b0)
                    expected_result = A <<< B;
                else
                    expected_result = $signed(A) >>> (-B);
                expected_flags[4] = (expected_result == 16'h0000);
                expected_flags[0] = expected_result[15];
            end
            default: valid_test = 1'b0;
        endcase
    end

    wire result_matches = (C == expected_result);
    wire flags_match    = (Flags == expected_flags);
    wire test_passed    = skip_check ? 1'b1 : (valid_test && result_matches && flags_match);

    assign LEDR[8:4] = Flags;
    assign LEDR[3]   = valid_test;
    assign LEDR[2]   = skip_check ? 1'b1 : flags_match;
    assign LEDR[1]   = skip_check ? 1'b1 : result_matches;
    assign LEDR[0]   = test_passed;
    assign LEDR[9]   = valid_test && !test_passed;

    // ---- seven-segment displays --------------------------------------
    hex_to_seven_segment display_result_0 (.hex_value(C[3:0]),   .segments(HEX0));
    hex_to_seven_segment display_result_1 (.hex_value(C[7:4]),   .segments(HEX1));
    hex_to_seven_segment display_result_2 (.hex_value(C[11:8]),  .segments(HEX2));
    hex_to_seven_segment display_result_3 (.hex_value(C[15:12]), .segments(HEX3));
    hex_to_seven_segment display_rhs      (.hex_value({1'b0, rhs_sel}), .segments(HEX4));
    hex_to_seven_segment display_lhs      (.hex_value({1'b0, lhs_sel}), .segments(HEX5));

endmodule


// Active-low hexadecimal seven-segment decoder (unchanged from provided file)
module hex_to_seven_segment (
    input  [3:0] hex_value,
    output reg [6:0] segments
);

    always @(*) begin
        case (hex_value)
            4'h0: segments = 7'b1000000;
            4'h1: segments = 7'b1111001;
            4'h2: segments = 7'b0100100;
            4'h3: segments = 7'b0110000;
            4'h4: segments = 7'b0011001;
            4'h5: segments = 7'b0010010;
            4'h6: segments = 7'b0000010;
            4'h7: segments = 7'b1111000;
            4'h8: segments = 7'b0000000;
            4'h9: segments = 7'b0010000;
            4'hA: segments = 7'b0001000;
            4'hB: segments = 7'b0000011;
            4'hC: segments = 7'b1000110;
            4'hD: segments = 7'b0100001;
            4'hE: segments = 7'b0000110;
            4'hF: segments = 7'b0001110;
            default: segments = 7'b1111111;
        endcase
    end

endmodule

/*
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
*/
