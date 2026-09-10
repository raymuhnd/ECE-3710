module tb_Lab1_ALU;

	reg [15:0] A;
	reg [15:0] B;
	reg [7:0] Opcode;
	
	wire [15:0] C;
	wire [4:0] Flags;

	integer i, errors;
	reg [7:0] valid_opcodes [0:18];
	reg [31:0] r;
	
	localparam 
		WAIT = 8'h00, 
		AND  = 8'h01, 
		OR   = 8'h02,
		XOR = 8'h03,
		NOT = 8'h04, //Unused value for Opcode and I didn't want to conflict with LSH opcode
		ADD  = 8'h05,
		ADDI = 8'b0101????,
		ADDU = 8'h06, //Conflict between ASHU and ADDU, so I am setting ASHU to an unused value
		ADDUI = 8'b0110????,
		ADDC = 8'h07,
		ADDCI = 8'b0111????,
		LSH  = 8'h84,
		LSHI = 8'b1000000?,
		SUB  = 8'h09,
		SUBC = 8'h0A,
		CMP = 8'h0B,
		CMPI = 8'b1011????,
//      ASHU = 8'h86,//Change to 4'b0110 once decoder added
		ALSH = 8'h15;
		//CMPU = 8'h08;
		//Check if these match the ISA specifications or if we need to add more
		//Didn't add certain tasks bc I thought we might handle [15:12] of instruction before ALU 
		
	localparam
		//Z bit, Carry bit, Flag(overflow) bit, Low(less than) bit, Negative bit
		Z_bit = 4, C_bit = 3, F_bit = 2, L_bit = 1, N_bit = 0;
		
	// Change ALU to whatever y'all name it
	Lab1_ALU_16b uut (
		.A(A), 
		.B(B), 
		.C(C), 
		.Opcode(Opcode), 
		.Flags(Flags)
	);	
	
	task check(input [15:0] test_a, 
		input [15:0] test_b, 
		input [7:0] test_opcode);
		
		reg [16:0] sum17;
		reg [16:0] minus17; // For big numbers
		reg [15:0] exp_out;
		reg [4:0] exp_flags;
		reg test_carry;
		
		begin
		
			// Reuse testbench but change localparam values 
			exp_flags = 5'b00000;
			test_carry = Flags[C_bit];	
			A = test_a;
			B = test_b;
			Opcode = test_opcode;	
			#1;
			
			
			casez (test_opcode)
				
				WAIT:begin
					exp_out = C;
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
				AND:begin
					exp_out = test_a & test_b;
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];

				end
				
				OR:begin
					exp_out = test_a | test_b;
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];

				end
				
				XOR:begin
					exp_out = test_a ^ test_b;
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
				NOT:begin
					exp_out = ~test_a;
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];

				end
				
				ADD:begin
					sum17 = {1'b0,test_a} + {1'b0, test_b};
					exp_out = sum17[15:0];
					exp_flags[C_bit] = sum17[16];
					exp_flags[F_bit] = (test_a[15] == test_b[15]) && (test_a[15] != exp_out[15]); // Same MSB(sign bit) -> different sign bit -> overflow
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
				ADDI: begin
					sum17 = {1'b0, test_a} + {1'b0, test_b}; 
					exp_out = sum17[15:0];

					exp_flags[C_bit] = sum17[16];
					exp_flags[F_bit] =
						  (test_a[15] == test_b[15]) &&
						  (test_a[15] != exp_out[15]);
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end

				
				ADDU:begin // No overflow for unsigned add
					sum17 = {1'b0,test_a} + {1'b0, test_b};
					exp_out = sum17[15:0];
					exp_flags[C_bit] = sum17[16];
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
				ADDUI: begin
					sum17 = {1'b0,test_a} + {1'b0, test_b};
					exp_out = sum17[15:0];
					exp_flags[C_bit] = sum17[16];
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];				
				end
				
				ADDC: begin
					sum17 = {1'b0,test_a} + {1'b0, test_b} + test_carry;
					exp_out = sum17[15:0];
					exp_flags[C_bit] = sum17[16];
					exp_flags[F_bit] = (test_a[15] == test_b[15]) && (test_a[15] != exp_out[15]); // Same MSB(sign bit) -> different sign bit -> overflow
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
				ADDCI: begin
					sum17 = {1'b0,test_a} + {1'b0, test_b} + test_carry;
					exp_out = sum17[15:0];
					exp_flags[C_bit] = sum17[16];
					exp_flags[F_bit] = (test_a[15] == test_b[15]) && (test_a[15] != exp_out[15]); // Same MSB(sign bit) -> different sign bit -> overflow
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
				SUB:begin
					minus17 = {1'b0,test_a} - {1'b0, test_b};
					exp_out = minus17[15:0];
					exp_flags[C_bit] = minus17[16];
					exp_flags[F_bit] = (test_a[15] != test_b[15]) && (test_a[15] != exp_out[15]); // Same MSB(sign bit) -> different sign bit -> overflow
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
				SUBC:begin
					minus17 = {1'b0,test_a} - {1'b0, test_b} - (test_carry);
					exp_out = minus17[15:0];
					exp_flags[C_bit] = minus17[16];
					exp_flags[F_bit] = (test_a[15] != test_b[15]) && (test_a[15] != exp_out[15]);
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end

				CMP:begin
					exp_out = 16'h0000;
					exp_flags[Z_bit] = (test_a == test_b);
					exp_flags[L_bit] = (test_a < test_b);
					exp_flags[N_bit] = ($signed(test_a) < $signed(test_b)); // Same MSB(sign bit) -> different sign bit -> overflow
				end
				
				CMPI: begin
					exp_out = 16'h0000;
					exp_flags[Z_bit] = (test_a == test_b);
					exp_flags[L_bit] = (test_a < test_b);
					exp_flags[N_bit] = ($signed(test_a) < $signed(test_b)); // Same MSB(sign bit) -> different sign bit -> overflow
				end
				
				LSH:begin
					if (test_b[15] == 1'b0)
						exp_out = test_a << test_b;
					else
						exp_out = test_a >> (-test_b);
						
					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
				LSHI: begin
					if (test_b[15] == 1'b0)
						exp_out = test_a << test_b;
					else
						exp_out = test_a >> (-test_b);

					exp_flags[Z_bit] = (exp_out == 16'b0);
					exp_flags[N_bit] = exp_out[15];
				end
				
//				ASHU:begin
//					if($signed(test_b[4:0]) >= 0) // Range is -15 to 15
//						exp_out = test_a << test_b[3:0];
//					else
//						exp_out = $signed(test_a) >>> (-test_b[4:0]);
//						
//					exp_flags[Z_bit] = (exp_out == 16'b0);
//				end
				
				
				ALSH: begin
				  if (test_b[15] == 1'b0)
						exp_out = test_a <<< test_b;
					else
						exp_out = $signed(test_a) >>> (-test_b);

				  exp_flags[Z_bit] = (exp_out == 16'b0);
				  exp_flags[N_bit] = exp_out[15];
				end
				
				default:begin
					exp_out = 16'h0000;
					exp_flags = 5'b00000;
				end
				
			endcase
			
			if((exp_out !== C) || (exp_flags !== Flags)) begin
				$display("A: %d, B: %d, Opcode: %h, Flags: %b vs. Expected Flags: %b, C: %d vs.Expected C: %d", A, B, Opcode, Flags, exp_flags, C, exp_out);
				errors = errors + 1;
			end
		
		end
		
	endtask
	
	initial begin
	
		$display("SIM start");
	
		valid_opcodes[0]  = WAIT;
		valid_opcodes[1]  = AND;
		valid_opcodes[2]  = OR;
		valid_opcodes[3]  = XOR;
		valid_opcodes[4]  = NOT;
		valid_opcodes[5]  = ADD;
		r = $random; valid_opcodes[6]  = {4'b0101, r[3:0]};//ADDI
		valid_opcodes[7]  = ADDU;
		r = $random; valid_opcodes[8]  = {4'b0110,r[3:0]};//ADDUI
		valid_opcodes[9]  = ADDC;
		r = $random; valid_opcodes[10]  = {4'b0111,r[3:0]};//ADDCI
		valid_opcodes[11]  = SUB;
		valid_opcodes[12] = SUBC;
		valid_opcodes[13] = CMP;
		r = $random; valid_opcodes[14] = {4'b1011, r[3:0]};//CMPI
		valid_opcodes[15] = ALSH;
		valid_opcodes[16] = LSH;
		r = $random; valid_opcodes[17] = {7'b1000000, r[0]};//LSHI
//		valid_opcodes[18] = ASHU;

		errors = 0;
		
		A = 16'h0000;
		B = 16'h0000;
		Opcode = WAIT;
		#1;

		for(i = 0; i < 1000; i = i + 1) begin
			A = $random;
			B = $random;
			Opcode = valid_opcodes[$urandom_range(0,18)];

			check(A, B, Opcode);
		end
		
		// Not including the monitor because it might slow down testing
		//$monitor("A: %h/%d, B: %h/%d, C: %h/%d, Flags: %b, time:%0d", A,A, B, B, C,C, Flags, $time );
		if (errors > 0) begin
			$display("Error count: %0d", errors);
		end else begin
			$display("All tests passed!");
		end
	end
	
endmodule

