`timescale 1ns/1ps

module tb_datapath;

	reg         Clock;
	reg         Reset;            
	reg  [3:0]  Rsrc, Rdest, WriteAddress;
	reg         WriteEnable, ReadEnableA, ReadEnableB, RI, Fe;
	reg  [15:0] Immediate;
	reg  [7:0]  Opcode;
	wire [15:0] ReadDataA, ReadDataB, ALUResult;
	wire [4:0]  ALUFlags, StoredFlags;

	ALU_Datapath dut (
		.Clock        (Clock),
		.Reset        (Reset),
		.Rsrc         (Rsrc),
		.Rdest        (Rdest),
		.WriteAddress (WriteAddress),
		.WriteEnable  (WriteEnable),
		.ReadEnableA  (ReadEnableA),
		.ReadEnableB  (ReadEnableB),
		.RI           (RI),
		.Immediate    (Immediate),
		.Opcode       (Opcode),
		.Fe           (Fe),
		.ReadDataA    (ReadDataA),
		.ReadDataB    (ReadDataB),
		.ALUResult    (ALUResult),
		.ALUFlags     (ALUFlags),
		.StoredFlags  (StoredFlags)
	);

	initial Clock = 1'b0;
	always #10 Clock = ~Clock;

	localparam [7:0] OP_NOP  = 8'h00,
	                 OP_AND  = 8'h01,
	                 OP_ADD  = 8'h05,
	                 OP_ADDC = 8'h07,
	                 OP_SUB  = 8'h09,
	                 OP_CMP  = 8'h0B,
	                 OP_ADDI = 8'h50,   
	                 OP_LSH  = 8'h84;


	localparam [4:0] F_NONE = 5'b00000,
	                 F_Z    = 5'b10000,   
	                 F_C    = 5'b01000,   
	                 F_OVF  = 5'b00100,   
	                 F_L    = 5'b00010,   
	                 F_N    = 5'b00001;  

	reg [15:0] model [0:15]; // data array
	reg [4:0]  model_flags;
	integer    errors, checks;
	
	initial begin
		#1000000;
		$display("tb did not finish");
		$finish;
	end

	task check16(input [15:0] got, input [15:0] exp);
		begin
			checks = checks + 1;
			if (got !== exp) begin
				errors = errors + 1;
				$display("fail | got %h expected %h", got, exp);
			end
		end
	endtask

	task check5(input [4:0] got, input [4:0] exp);
		begin
			checks = checks + 1;
			if (got !== exp) begin
				errors = errors + 1;
				$display("Fail | got %b expected %b", got, exp);
			end
		end
	endtask

	task check_state;
		integer k;
		begin
			for (k = 0; k < 16; k = k + 1) begin
				checks = checks + 1;
				if (dut.u_regfile.Registers[k] !== model[k]) begin
					errors = errors + 1;
					$display("Fail | R%0d = %h expected %h", k, dut.u_regfile.Registers[k], model[k]);
				end
			end
			check5(StoredFlags, model_flags);
		end
	endtask

	task reset;
		integer k;
		begin
			@(posedge Clock);
			Reset = 1'b1;
			WriteEnable = 1'b0;  Fe = 1'b0;  RI = 1'b0;
			Opcode = OP_NOP;     Immediate = 16'h0000;
			for (k = 0; k < 16; k = k + 1) model[k] = 16'h0000;
			model_flags = 5'b00000;
			#1;
			check_state;
			@(posedge Clock);
			#1;
			@(posedge Clock);
			Reset = 1'b0;
		end
	endtask

	task run( input [7:0] op, input [3:0] rs, input [3:0] rd,
	         input ri, input [15:0] im, input we, input fe,
	         input [15:0] expC, input [4:0] expF);
		begin
			@(posedge Clock);
			#1; // start a little later/ no race
			Opcode       = op;
			Rsrc         = rs;
			Rdest        = rd;
			WriteAddress = rd;       
			RI           = ri;
			Immediate    = im;
			WriteEnable  = we;
			Fe           = fe;
			#1;                      
			check16(ReadDataA, model[rs]);
			check16(ReadDataB, model[rd]);
			check16(ALUResult, expC);
			check5 (ALUFlags,  expF);
			@(posedge Clock);
			#1;
			if (we) model[rd]   = expC;     
			if (fe) model_flags = expF;
			WriteEnable = 1'b0;
			Fe          = 1'b0;
			check_state;
		end
	endtask

	task load(input [3:0] rd, input [15:0] value, input [4:0] expF);
		begin
			run( OP_ADDI, 4'd0, rd, 1'b1, value, 1'b1, 1'b1, value, expF); //loading addi
		end
	endtask

	integer n;
	integer a, b;                       

	initial begin
		errors = 0;  checks = 0;
		Reset = 1'b1;
		WriteEnable = 1'b0;  Fe = 1'b0;  RI = 1'b0;
		ReadEnableA = 1'b1;  ReadEnableB = 1'b1;
		Rsrc = 4'd0;  Rdest = 4'd0;  WriteAddress = 4'd0;
		Immediate = 16'h0000;  Opcode = OP_NOP;
		
		$display("fibonacci into the register");
		reset;
		load(4'd0, 16'd1, F_NONE);
		load(4'd1, 16'd1, F_NONE);
		a = 1;  b = 1;
		for (n = 1; n <= 14; n = n + 1) begin
			if (n % 2 == 1) begin
				b = a + b;
				run( OP_ADD, 4'd0, 4'd1, 1'b0, 16'h0, 1'b1, 1'b1, b[15:0], F_NONE); //Fib: R1 <- R1 + R0
			end else begin
				a = a + b;
				run( OP_ADD, 4'd1, 4'd0, 1'b0, 16'h0, 1'b1, 1'b1, a[15:0], F_NONE); //Fib: R0 <- R0 + R1
			end
		end
		run(OP_ADD, 4'd0, 4'd15, 1'b0, 16'h0, 1'b1, 1'b1, 16'd987, F_NONE); //Fib: R15 <- R15 + R0 (move)
		check16(dut.u_regfile.Registers[15], 16'h03DB);

		$display("Instruction mix, dest=source");
		reset;
		load(4'd1, 16'h000A, F_NONE);                   
		load(4'd2, 16'h0003, F_NONE);                   

		// Sub
		run(OP_SUB, 4'd2, 4'd1, 1'b0, 16'h0, 1'b1, 1'b1, 16'h0007, F_NONE); //SUB R1 <- R1 - R2
		run(OP_SUB, 4'd1, 4'd2, 1'b0, 16'h0, 1'b1, 1'b1, 16'hFFFC, F_C | F_N); //SUB R2 <- R2 - R2

		// signed overflow
		load(4'd3, 16'h7FFF, F_NONE);
		run(OP_ADDI, 4'd0, 4'd3, 1'b1, 16'h0001, 1'b1, 1'b1, 16'h8000, F_OVF | F_N); //ADDI R3 + 1
		load(4'd4, 16'h0001, F_NONE);
		run(OP_SUB, 4'd4, 4'd3, 1'b0, 16'h0, 1'b1, 1'b1, 16'h7FFF, F_OVF); //SUB R3 <- R3 - R4

		// carry add
		load(4'd5, 16'hFFFF, F_N);
		run(OP_ADD,  4'd4, 4'd5, 1'b0, 16'h0, 1'b1, 1'b1, 16'h0000, F_Z | F_C); //ADD R5 <- R5 + R4
		run(OP_ADDC, 4'd7, 4'd6, 1'b0, 16'h0, 1'b1, 1'b1, 16'h0001, F_NONE); //ADDC R6 <- R6 + R7 + carry

		// CMP 
		run(OP_CMP, 4'd1, 4'd2, 1'b0, 16'h0, 1'b0, 1'b1, 16'h0000, F_N); //CMP R2 vs R1
		run(OP_CMP, 4'd2, 4'd1, 1'b0, 16'h0, 1'b0, 1'b1, 16'h0000, F_L); //CMP R1 vs R2

		// logic and shift 
		load(4'd8, 16'hF0F0, F_N);
		load(4'd9, 16'h0FF0, F_NONE);
		run(OP_AND, 4'd9, 4'd8, 1'b0, 16'h0, 1'b1, 1'b1, 16'h00F0, F_NONE); //AND R8 <- R8 & R9
		load(4'd14, 16'h0001, F_NONE);
		load(4'd15, 16'h0004, F_NONE);
		run(OP_LSH, 4'd15, 4'd14, 1'b0, 16'h0, 1'b1, 1'b1, 16'h0010, F_NONE); //LSH R14 <<= R15

		$display("%0d passes, %0d errors", checks, errors);
		if (errors == 0) $display("All Pass");
		else             $display("Fail");
		$finish;
	end

endmodule