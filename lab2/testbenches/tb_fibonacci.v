`timescale 1ns/1ps

module tb_fibonacci;

	reg         Clock;
	reg         Reset_n;            
	wire [15:0] DisplayValue;
	wire [15:0] ALUResult;
	wire [4:0]  FlagsOut;
	wire        Halt;
	wire [4:0]  StateOut;

	Fibonacci_Core core (
		.Clock        (Clock),
		.Reset_n      (Reset_n),
		.DisplayValue (DisplayValue),
		.ALUResult    (ALUResult),
		.FlagsOut     (FlagsOut),
		.Halt         (Halt),
		.StateOut     (StateOut)
	);

	initial Clock = 1'b0;
	always #10 Clock = ~Clock;         // 50 MHz

	reg [15:0] fib [0:15];
	integer    errors, checks;

	initial begin
		#2000000;
		$display("testbench did not finish");
		$finish;
	end

	task check16(input [15:0] got, input [15:0] exp);
		begin
			checks = checks + 1;
			if (got !== exp) begin
				errors = errors + 1;
				$display("Fail got %h expected %h", got, exp);
			end
		end
	endtask

	task check_bit(input got, input exp);
		begin
			checks = checks + 1;
			if (got !== exp) begin
				errors = errors + 1;
				$display("Fail got %b expected %b", got, exp);
			end
		end
	endtask

	task check_regs(input integer written);
		integer j;
		begin
			for (j = 0; j < 16; j = j + 1) begin
				checks = checks + 1;
				if (core.u_dp.u_regfile.Registers[j] !== ((j < written) ? fib[j] : 16'h0000)) begin
					errors = errors + 1;
					$display("fail | state %0d |  reg %0d = %h expected %h",
					         StateOut, j, core.u_dp.u_regfile.Registers[j],
					         (j < written) ? fib[j] : 16'h0000);
				end
			end
		end
	endtask

	task wait_state(input [4:0] target);
		integer t;
		begin
			t = 0;
			while (StateOut !== target && t < 60) begin
				@(posedge Clock);
				#1;
				t = t + 1;
			end
			checks = checks + 1;
			if (StateOut !== target) begin
				errors = errors + 1;
				$display("timeout fail | state %0d (StateOut = %0d)",
				        target, StateOut);
			end
		end
	endtask

	task run_and_check_program;
		integer s, w;
		begin
			wait_state(5'd1);
			for (s = 1; s <= 17; s = s + 1) begin
				check16({11'b0, StateOut}, s);
				w = s - 1;                                 
				check_regs(w);
				check16({11'b0, FlagsOut}, 16'h0000);
				check_bit(Halt, (s == 17));
				if (s <= 16)                                
					check16(ALUResult, fib[s-1]);
				if (s < 17) begin
					@(posedge Clock);
					#1;
				end
			end

			// state 17 = S_HALT
			check16(DisplayValue, 16'h03DB);
			check16(core.u_dp.u_regfile.Registers[15], 16'h03DB);

			// halt sticky
			repeat (5) begin
				@(posedge Clock);
				#1;
				check16({11'b0, StateOut}, 16'd17);
				check_bit(Halt, 1'b1);
				check_regs(16);
				check16(DisplayValue, 16'h03DB);
			end
		end
	endtask

	task apply_reset;
		begin
			@(negedge Clock);
			Reset_n = 1'b0;
			#1;
			check_regs(0);                                  
			repeat (3) @(posedge Clock);
			#1;
			check16({11'b0, StateOut}, 16'd0);
			check_bit(Halt, 1'b0);
			check16({11'b0, FlagsOut}, 16'h0000);
			@(negedge Clock);
			Reset_n = 1'b1;
		end
	endtask

	integer n;
	initial begin
		errors = 0;  checks = 0;

		// expected values, last is 987
		fib[0] = 16'd1;  fib[1] = 16'd1;
		for (n = 2; n < 16; n = n + 1) fib[n] = fib[n-1] + fib[n-2];
		check16(fib[15], 16'd987);

		$display("reset to start, then run program");
		Reset_n = 1'b0;
		repeat (3) @(posedge Clock);
		#1;
		check_regs(0);
		check16({11'b0, StateOut}, 16'd0);
		@(negedge Clock);
		Reset_n = 1'b1;
		run_and_check_program;

		$display("reset from halt");
		apply_reset;
		run_and_check_program;

		$display("reset mid program ");
		apply_reset;
		wait_state(5'd9);
		check_regs(8);                                      
		apply_reset;                                        
		run_and_check_program;

		// ---------------- summary ----------------
		$display("%0d passes, %0d errors", checks, errors);
		if (errors == 0) $display("All pass");
		else             $display("Fails");
		$finish;
	end

endmodule