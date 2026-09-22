`timescale 1ns/1ps

module tb_regfile;

	reg         Clock;
	reg         Reset;
	reg         WriteEnable;
	reg         FlagWriteEnable;
	reg         ReadEnableA;
	reg         ReadEnableB;
	reg  [3:0]  WriteAddress;
	reg  [3:0]  ReadAddressA;
	reg  [3:0]  ReadAddressB;
	reg  [15:0] WriteData;
	reg  [4:0]  FlagsIn;      // [4] Z, [3] Carry, [2] Overflow, [1] Less Than, [0] Negative
	wire [15:0] ReadDataA;
	wire [15:0] ReadDataB;
	wire [4:0]  StoredFlags;

	regfile uut (
		.Clock           (Clock),
		.Reset           (Reset),
		.WriteEnable     (WriteEnable),
		.FlagWriteEnable (FlagWriteEnable),
		.ReadEnableA     (ReadEnableA),
		.ReadEnableB     (ReadEnableB),
		.WriteAddress    (WriteAddress),
		.ReadAddressA    (ReadAddressA),
		.ReadAddressB    (ReadAddressB),
		.WriteData       (WriteData),
		.FlagsIn         (FlagsIn),
		.ReadDataA       (ReadDataA),
		.ReadDataB       (ReadDataB),
		.StoredFlags     (StoredFlags)
	);

	// 50 MHz
	initial Clock = 1'b0;
	always #10 Clock = ~Clock;

	reg [15:0] model [0:15];
	reg [4:0]  model_flags;
	integer    errors, checks;

	initial begin
		#1000000;
		$display("tb timeout ");
		$finish;
	end

	task check16(input [15:0] got, input [15:0] exp);
		begin
			checks = checks + 1;
			if (got !== exp) begin
				errors = errors + 1;
				$display("fail | got %h expected %h",  got, exp);
			end
		end
	endtask

	task check5(input [4:0] got, input [4:0] exp);
		begin
			checks = checks + 1;
			if (got !== exp) begin
				errors = errors + 1;
				$display("fail | got %b expected %b", got, exp);
			end
		end
	endtask

	task cycle(input we, input [3:0] a, input [15:0] d, input fwe, input [4:0] f);
		begin
			@(negedge Clock);
			WriteEnable     = we;
			WriteAddress    = a;
			WriteData       = d;
			FlagWriteEnable = fwe;
			FlagsIn         = f;
			@(posedge Clock);
			#1;
			if (we)  model[a]    = d;
			if (fwe) model_flags = f;
			WriteEnable     = 1'b0;
			FlagWriteEnable = 1'b0;
		end
	endtask

	task write_reg(input [3:0] a, input [15:0] d);
		begin
			cycle(1'b1, a, d, 1'b0, 5'b0);
		end
	endtask

	task write_flags(input [4:0] f);
		begin
			cycle(1'b0, 4'd0, 16'h0000, 1'b1, f);
		end
	endtask

	task read(input enA, input enB, input [3:0] addrA, input [3:0] addrB);
		reg [15:0] expA, expB;
		begin
			ReadEnableA  = enA;
			ReadEnableB  = enB;
			ReadAddressA = addrA;
			ReadAddressB = addrB;
			#0.1;
			expA = enA ? model[addrA] : 16'h0000;
			expB = enB ? model[addrB] : 16'h0000;
			check16(ReadDataA, expA);
			check16(ReadDataB, expB);
		end
	endtask

	task check_all;
		integer k;
		begin
			for (k = 0; k < 16; k = k + 1)
				read(1'b1, 1'b1, k[3:0], ~k[3:0]);
			check5(StoredFlags, model_flags);
		end
	endtask

	task clear_model;
		integer k;
		begin
			for (k = 0; k < 16; k = k + 1) model[k] = 16'h0000;
			model_flags = 5'b00000;
		end
	endtask

	integer i;
	reg [15:0] p;

	initial begin
		errors = 0;
		checks = 0;

		Reset = 1'b1; // reset to start
		WriteEnable = 1'b0;  FlagWriteEnable = 1'b0;
		ReadEnableA = 1'b1;  ReadEnableB = 1'b1;
		WriteAddress = 4'd0; ReadAddressA = 4'd0;  ReadAddressB = 4'd0;
		WriteData = 16'h0000; FlagsIn = 5'b00000;
		clear_model;
		repeat (3) @(posedge Clock);
		Reset = 1'b0;

		$display("reset then write and read every reg");
		check_all;                                   
		for (i = 0; i < 16; i = i + 1) begin
			p = 16'hA000 + i * 16'h0101;
			write_reg(i[3:0], p);
			check_all;
			write_reg(i[3:0], ~p);
			check_all;
		end
		read(1'b1, 1'b1, 4'd5, 4'd5);         

		$display("Enable then read + write, test flags, reset");

		@(posedge Clock);
		WriteAddress = 4'd6;  WriteData = 16'hDEAD;
		#2 WriteEnable = 1'b1;
		#3 WriteEnable = 1'b0;
		@(posedge Clock);
		#1;
		check_all;

		read(1'b0, 1'b1, 4'd3, 4'd4);
		read(1'b1, 1'b0, 4'd3, 4'd4);
		read(1'b0, 1'b0, 4'd3, 4'd4);
		read(1'b1, 1'b1, 4'd3, 4'd4);

		write_reg(4'd3, 16'h1111);
		@(posedge Clock);
		ReadEnableA  = 1'b1;  ReadEnableB  = 1'b1;
		ReadAddressA = 4'd3;  ReadAddressB = 4'd3;
		WriteAddress = 4'd3;  WriteData    = 16'h2222;  WriteEnable = 1'b1;
		#1;
		check16(ReadDataA, 16'h1111);
		check16(ReadDataB, 16'h1111);
		@(posedge Clock);
		#1;
		model[3]    = 16'h2222;
		WriteEnable = 1'b0;
		check16(ReadDataA, 16'h2222);
		check16(ReadDataB, 16'h2222);

		
		write_flags(5'b10101);
		check5(StoredFlags, model_flags);
		write_flags(5'b01010);
		check5(StoredFlags, model_flags);
		cycle(1'b0, 4'd0, 16'h0000, 1'b0, 5'b11111);             
		check5(StoredFlags, model_flags);
		cycle(1'b1, 4'd12, 16'hFEEB, 1'b0, 5'b10101);           
		check_all;
		cycle(1'b0, 4'd12, 16'h0000, 1'b1, 5'b10101);             
		check_all;

		@(posedge Clock);
		#3 Reset = 1'b1;
		clear_model;
		#1;
		check_all;
		#1 Reset = 1'b0;
		@(posedge Clock);
		#1;
		check_all;                                   
		write_reg(4'd2, 16'hCAFE);                  
		check_all;

		$display("%0d pass, %0d errors", checks, errors);
		if (errors == 0) $display("All pass");
		else             $display("Fail");
		$finish;
	end

endmodule