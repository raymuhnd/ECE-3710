`timescale 1ns / 1ps
module Lab4_ALU(A, B, C, CarryIn, Opcode, Flags);
input [15:0] A, B;
input [7:0] Opcode;
input CarryIn;
output reg [15:0] C;
output reg [4:0] Flags; //Flags[4] Z bit, Flags[3] Carry, Flags[2] Overflow, Flags[1] Less Than,Flags[0] Negative

// Opcode = {instr[15:12], instr[7:4]}. A = Rdest, B = Rsrc or extended immediate.

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
parameter SUBI = 8'b1001????;      
parameter SUBC = 8'h0A;
parameter CMP = 8'b00001011;
parameter CMPI = 8'b1011????;
parameter CMPU = 8'b00001100;
parameter AND = 8'b00000001;
parameter ANDI = 8'b0001????;     
parameter OR = 8'b00000010;
parameter ORI = 8'b0010????;       
parameter XOR = 8'b00000011;
parameter XORI = 8'b0011????;      
parameter NOT = 8'b00000100;
parameter MOV = 8'b00001101;       
parameter MOVI = 8'b1101????;      
parameter LUI = 8'b1111????;       
parameter LSH = 8'b10000100;
parameter LSHI = 8'b1000000?;
parameter ALSH = 8'b00010101;
parameter NOP = 8'b00000000;

always @(*)
begin
	//Needed: defaults to avoid latches??
	casez (Opcode)
	ADD:
		begin
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
			Flags[1] = 1'b0;
			Flags[0] = C[15];
			Flags[3] = sum17[16];
		end
	
	ADDI:
		begin
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
			Flags[1] = 1'b0;
			Flags[0] = C[15];
			Flags[3] = sum17[16];
		end
		
	ADDU:
		begin
			{Flags[3], C} = A + B;
			if (C == 16'b0)
				Flags[4] = 1'b1;
			else
				Flags[4] = 1'b0;
			Flags[2:1] = 2'b0;
			Flags[0] = C[15];
		end
		
	ADDUI:
		begin
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
			sum17 = A + B + CarryIn;
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
			sum17 = A + B + CarryIn;
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
		
	SUB, SUBI:
		begin
            diff17 = A - B;
            C = diff17[15:0];
            Flags[4] = (C == 16'b0);                          
            Flags[3] = diff17[16];                            
            Flags[2] = (A[15] ^ B[15]) & (A[15] ^ C[15]);     
            Flags[1] = 1'b0; 
            Flags[0] = C[15]; 
			
		end
		
	SUBC:begin
            diff17 = {1'b0, A} - {1'b0, B} - (CarryIn);
            C = diff17[15:0];
            Flags[4] = (C == 16'b0);                          
            Flags[3] = diff17[16];                            
            Flags[2] = (A[15] ^ B[15]) & (A[15] ^ C[15]);		
            Flags[1] = 1'b0; // Forcefully set to 0
            Flags[0] = C[15]; 
	    end

	CMP:
		begin
			C = 16'h0000;
			Flags[4] = (A == B);                  
			Flags[3] = 1'b0;                       
			Flags[2] = 1'b0;                       
			Flags[1] = (A < B);                    
			Flags[0] = ($signed(A) < $signed(B));
		end
	
	CMPI:
		begin
			C = 16'h0000;
			Flags[4] = (A == B);                  
			Flags[3] = 1'b0;                       
			Flags[2] = 1'b0;                       
			Flags[1] = (A < B);                    
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

	AND, ANDI:
		begin
			C = A & B;
			Flags[4] = (C == 16'b0);
			Flags[3:1] = 3'b0;
			Flags[0] = C[15];
		end
	OR, ORI:
		begin
			C = A | B;
			Flags[4] = (C == 16'b0);
			Flags[3:1] = 3'b0;
			Flags[0] = C[15];
		end
	XOR, XORI:
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

	MOV, MOVI, LUI:
		begin
			C = B;
			Flags[4] = (C == 16'b0);
			Flags[3:1] = 3'b0;
			Flags[0] = C[15];
		end
		
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