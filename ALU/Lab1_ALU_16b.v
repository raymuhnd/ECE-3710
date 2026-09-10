module Lab1_ALU_16b(A, B, C, Opcode, Flags);
input [15:0] A, B;
input [7:0] Opcode;
output reg [15:0] C;
output reg [4:0] Flags; //Flags[4] Z bit, Flags[3] Carry, Flags[2] Overflow, Flags[1] Less Than,Flags[0] Negative
//Z -> does the output produce zero?
//Carry -> addition produce a carry beyond most significant bit? (unsigned)
//Overflow -> signed arithmetic produce result too large or small for 16 bits? (POS + POS = NEGor vice versa)
//Less than -> is a < b?
//Negative -> encodes the negative/less than condition

reg [16:0] diff17;
reg [16:0] sum17;

parameter ADD = 8'b00000101;
parameter ADDI = 8'b0101????;
parameter ADDU = 8'b00000110;
parameter ADDUI = 8'b0110????;
parameter ADDC = 8'b00000111;
//parameter ADDCUI 
parameter ADDCI = 8'b0111????;
parameter SUB = 8'b00001001;
parameter SUBC = 8'h0A;
//parameter SUBI
parameter CMP = 8'b00001011;
parameter CMPI = 8'b1011????;
parameter CMPU = 8'b00001100;
parameter AND = 8'b00000001;
parameter OR = 8'b00000010;
parameter XOR = 8'b00000011;
parameter NOT = 8'b00000100;
parameter LSH = 8'b10000100;
parameter LSHI = 8'b1000000?;
parameter ALSH = 8'b00010101;
parameter NOP = 8'b00000000;

always @(A, B, Opcode)
begin
	casez (Opcode)
	//Add (signed)
	ADD:
		begin
			sum17 = A + B;
			C = sum17[15:0];
			// is the result zero?
			if (C == 16'b0)
			// sets zero flag
				Flags[4] = 1'b1;
			else
			// otherwise zero flag is not used
				Flags[4] = 1'b0;
			// checks for signed overflow
			if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) )
			//sets overflow flag
				Flags[2] = 1'b1;
			else
				Flags[2] = 1'b0;
			Flags[1] = 1'b0;
			Flags[0] = C[15];
			Flags[3] = sum17[16];
		end
	
	ADDI:
		begin
			//B treated as the immediate; otherwise same as ADD
			sum17 = A + B;
			C = sum17[15:0];
			if (C == 16'b0)
				Flags[4] = 1'b1;
			else
				Flags[4] = 1'b0;
			if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) )
				Flags[2] = 1'b1;
			else
				Flags[2] = 1'b0;
			//no carry or compare
			Flags[1] = 1'b0;
			Flags[0] = C[15];
			Flags[3] = sum17[16];
		end
		
	//Add unsigned
	ADDU:
		begin
			//bit 16 of A+B into Flags[3] and the lower 16 bits into C
			{Flags[3], C} = A + B;
			if (C == 16'b0)
			// If all zeros, Z bit is set
				Flags[4] = 1'b1;
			else
				Flags[4] = 1'b0;
			//no overflow/signed bit
			Flags[2:1] = 2'b0;
			Flags[0] = C[15];
		end
		
	ADDUI:
		begin
			//same as ADDU
			{Flags[3], C} = A + B;
			if (C == 16'b0)
				Flags[4] = 1'b1;
			else
			Flags[4] = 1'b0;
			Flags[2:1] = 2'b0;
			Flags[0] = C[15];
		end
		
	ADDC:
		begin
		//Adds carry bit to the sum (signed); similar to ADDI
			sum17 = A + B + Flags[3];
			C = sum17[15:0];
			if (C == 16'b0)
				Flags[4] = 1'b1;
			else
				Flags[4] = 1'b0;
			if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) )
				Flags[2] = 1'b1;
			else
				Flags[2]= 1'b0;
			Flags[1] = 1'b0;
			Flags[0] = C[15];
			Flags[3] = sum17[16];
		end
	
//	ADDCUI:
//		begin
//			//ADDI with carry (unsigned)
//			{Flags[3], C} = A + B + Flags[3];
//			if (C == 16'b0)
//				Flags[4] = 1'b1;
//			else
//				Flags[4] = 1'b0;
//			Flags[2:0] = 3'b000;
//		end
		
	ADDCI:
		begin
			//ADDI with carry (signed)
			sum17 = A + B + Flags[3];
			C = sum17[15:0];
			if (C == 16'b0)
				Flags[4] = 1'b1;
			else
				Flags[4] = 1'b0;
			if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) )
				Flags[2] = 1'b1;
			else
				Flags[2] = 1'b0;
			Flags[1] = 1'b0;
			Flags[0] = C[15];
			Flags[3] = sum17[16];
		end
		
	SUB:
		begin
		diff17 = A - B;
		C = diff17[15:0];
		Flags[4] = (C == 16'b0);                          // Z
		Flags[3] = diff17[16];                            // no-borrow out
		Flags[2] = (A[15] ^ B[15]) & (A[15] ^ C[15]);      // Overflow
		Flags[1] = 1'b0; 
		Flags[0] = C[15]; 
			
		end
		
	SUBC:begin
		diff17 = {1'b0, A} - {1'b0, B} - (Flags[3]);
		C = diff17[15:0];
		Flags[4] = (C == 16'b0);                          // Z
		Flags[3] = diff17[16];                            // no-borrow out
		Flags[2] = (A[15] ^ B[15]) & (A[15] ^ C[15]);		// Overflow
		Flags[1] = 1'b0; // Forcefully set to 0 so it doesnt pick up on past less than flags
		Flags[0] = C[15]; 
	end
		/*
	SUBI:
		begin
			//same as SUB but B is an immediate value
			C = A - B;
			if (C == 16'b0)
				Flags[4] = 1'b1;
			else
				Flags[4] = 1'b0;
			if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) )
				Flags[2] = 1'b1;
			else
				Flags[2] = 1'b0;
			Flags[1:0] = 2'b00;
			Flags[3] = 1'b0;
		end
		*/
	CMP:
		begin
			C = 16'h0000;
			Flags[4] = (A == B);                  // Z
			Flags[3] = 1'b0;                      // C 
			Flags[2] = 1'b0;                      // F 
			Flags[1] = (A < B);                   // L 
			Flags[0] = ($signed(A) < $signed(B));
		end
		
	CMPI:
		begin
			C = 16'h0000;
			Flags[4] = (A == B);                  // Z
			Flags[3] = 1'b0;                      // C 
			Flags[2] = 1'b0;                      // F 
			Flags[1] = (A < B);                   // L 
			Flags[0] = ($signed(A) < $signed(B));
		end
		
//	CMPU:
//		begin
//			if (A < B)
//				Flags[3:0] = 4'b1000;
//			else if (A == B)
//				Flags[3:0] = 4'b0010;
//			else
//				Flags[3:0] = 4'b0000;
//			C = 4'b0000;
//			Flags[4] = 1'b0;
//		end
// Logic section; self-explanatory
// Flags are set to zero for each case as they are not needed
	AND:
		begin
			C = A & B;
			Flags[4] = (C == 16'b0);
			Flags[3:1] = 3'b0;
			Flags[0] = C[15];
		end
	OR:
		begin
			C = A | B;
			Flags[4] = (C == 16'b0);
			Flags[3:1] = 3'b0;
			Flags[0] = C[15];
		end
	XOR:
		begin
			C = A ^ B;
			Flags[4] = (C == 16'b0);
			Flags[3:1] = 3'b0;
			Flags[0] = C[15];
		end
	NOT:
		begin
			C = ~A;
			Flags[4] = (C == 16'b0);
			Flags[3:1] = 3'b0;
			Flags[0] = C[15];
		end
		
// Left-shift
	LSH:
		begin
			if (B[15] == 1'b0)
				C = A << B;
			else
				C = A >> (-B);

			if (C == 16'b0)
				Flags[4] = 1'b1;
			else
				Flags[4] = 1'b0;
			Flags[3:1] = 3'b0;
			Flags[0] = C[15];
	end

	
	LSHI:
	begin
		// Similar to LSH, however, B acts as an immediate
		if (B[15] == 1'b0)
			C = A << B;
		else
			C = A >> (-B);

		if (C == 16'b0)
			Flags[4] = 1'b1;
		else
			Flags[4] = 1'b0;
		Flags[3:1] = 3'b0;
		Flags[0] = C[15];
	end
	
	// Arithmetic left-shift
	ALSH:
	begin
		if (B[15] == 1'b0)
			C = A <<< B;
		else
			C = $signed(A) >>> (-B);

		if (C == 16'b0)
			Flags[4] = 1'b1;
		else
			Flags[4] = 1'b0;
		Flags[3:1] = 3'b0;
		Flags[0] = C[15];
	end
	
//	ASHU:begin
//	
//		Flags[0] = C[15];
//	end
	
	NOP:
	begin
		C = 16'b0;
		Flags[4] = (C == 16'b0);
		Flags[3:1] = 2'b0;
		Flags[0] = C[15];
	end
	
	default:
		begin
			C = 4'b0000;
			Flags[4:1] = 4'b0000;
			Flags[0] = C[15];
		end
	endcase
	
end

endmodule