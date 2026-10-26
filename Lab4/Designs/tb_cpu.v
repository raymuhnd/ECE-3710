`timescale 1ns / 1ps
module tb_cpu;
    reg clk = 1'b0;
    reg rst_n;

    wire [15:0] disp_out;
    wire [15:0] pc;
    wire [15:0] ir;
    wire [3:0]  state;

    integer errors = 0;
    integer cycles = 0;
    integer instrs = 0;

    localparam TRACE     = 0;
    localparam DONE_ADDR = 16'h0030;   // "done: BUC done" in lab4_program.asm

    cpu #(.INIT_FILE("lab4_program.hex")) uut(.clk(clk), .rst_n(rst_n), .disp_out(disp_out),
      .pc_out(pc), .ir_out(ir), .state_out(state));

    always #10 clk = ~clk;

    // count cycles / instructions and (optionally) print a trace
    always @(posedge clk) begin
        if (rst_n) begin
            cycles = cycles + 1;
            if (state == 4'd2) begin       // S_DECODE: ir holds the current instruction
                instrs = instrs + 1;
                if (TRACE)
                    $display("t=%0t pc=%h ir=%h psr(ZCFLN)=%b", $time, pc, ir, uut.psr);
            end
        end
    end

    task check_reg(input [3:0] r, input [15:0] exp_val);
        begin
            if (uut.u_regfile.Registers[r] !== exp_val) begin
                errors = errors + 1;
                $display("R%0d is incorrect | Got: %h | Expected: %h", r, uut.u_regfile.Registers[r], exp_val);
            end
        end
    endtask

    task check_mem(input [15:0] addr, input [15:0] exp_val);
        begin
            if (uut.u_mem.mem[addr] !== exp_val) begin
                errors = errors + 1;
                $display("mem[%h] is incorrect | Got: %h | Expected: %h", addr, uut.u_mem.mem[addr], exp_val);
            end
        end
    endtask

    initial begin
        rst_n = 1'b0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        if (pc !== 16'd0) begin
            errors = errors + 1;
            $display("Incorrect pc start value");
        end

        // run until the program reaches "done" (or give up after 2000 cycles)
        while (pc !== DONE_ADDR && cycles < 2000)
            @(posedge clk);
        repeat (8) @(posedge clk);         // let it spin on "done" a couple of times

        if (pc !== DONE_ADDR) begin
            errors = errors + 1;
            $display("Program did not reach done | PC: %h | Expected: %h", pc, DONE_ADDR);
        end

        // (i) loads
        check_reg(4'd2,  16'h0007);
        check_reg(4'd3,  16'h0005);
        // (ii) reg-reg / immediate / shift results
        check_reg(4'd4,  16'h00AB);
        check_reg(4'd5,  16'h00F4);
        check_reg(4'd6,  16'hCDAB);
        check_reg(4'd10, 16'h0CD0);
        check_reg(4'd11, 16'h0004);
        // (iii)/(iv) store then reload
        check_mem(16'h00F2, 16'hCDAB);
        check_reg(4'd7,  16'hCDAB);
        // (v)/(vi) loop with branches, signed/unsigned compares
        check_reg(4'd8,  16'h0023);
        check_reg(4'd9,  16'h0000);
        check_reg(4'd14, 16'hFFFF);
        // jumps: JAL link register and return
        check_reg(4'd13, 16'h002E);
        // (vii) final result in memory and in the display register
        check_reg(4'd0,  16'hCDCE);
        check_mem(16'h00FF, 16'hCDCE);
        if (disp_out !== 16'hCDCE) begin
            errors = errors + 1;
            $display("Display data is incorrect | Got: %h | Expected: %h", disp_out, 16'hCDCE);
        end

        $display("Instructions decoded: %0d | Clock cycles: %0d", instrs, cycles);

        // reset mid-run should send the PC back to 0
        @(negedge clk); rst_n = 0;
        @(posedge clk); #1;
        if (pc !== 16'd0) begin
            errors = errors + 1;
            $display("PC incorrect after reset mid-run");
        end

        if(errors == 0)
            $display("All pass");
        else
            $display("There were %0d errors", errors);

        $finish;
    end

endmodule
