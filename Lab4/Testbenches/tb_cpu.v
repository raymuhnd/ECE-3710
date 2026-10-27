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
    
    localparam STEP = 1;
    localparam SHOW_WR = 1;   // 1 = print results

    reg        w_reg_p = 0, w_mem_p = 0, w_flg_p = 0;
    reg [3:0]  w_reg;
    reg [15:0] w_old, w_mem_addr, w_ir, w_pc;

    // A write enabled at posedge, such that it can be sampled at negedge, report one cycle after
    always @(negedge clk) begin
        if (!rst_n) begin
            w_reg_p = 0; w_mem_p = 0; w_flg_p = 0;
        end else if (SHOW_WR) begin
            if (w_reg_p)
                $display("pc=%h %0s | R%0d: %h -> %h",
                         w_pc, mnem(w_ir), w_reg, w_old, uut.u_regfile.Registers[w_reg]);
            if (w_mem_p)
                $display("pc=%h %0s | mem[%h] = %h",
                         w_pc, mnem(w_ir), w_mem_addr, uut.u_mem.mem[w_mem_addr]);
            if (w_flg_p)
                $display(" pc=%h %0s | psr(ZCFLN) = %b",
                         w_pc, mnem(w_ir), uut.psr);
            w_reg_p = 0; w_mem_p = 0; w_flg_p = 0;

            if (uut.reg_we) begin
                w_reg_p = 1;
                w_reg   = uut.ra_addr;
                w_old   = uut.u_regfile.Registers[uut.ra_addr];
            end
            
            if (uut.mem_en && uut.mem_we) begin
                w_mem_p    = 1;
                w_mem_addr = uut.mem_addr;
            end
            
            if (uut.flag_we) w_flg_p = 1;
            w_ir = ir;
            w_pc = pc;
        end
    end   

    // instruction name
    function [39:0] mnem(input [15:0] i);
        begin
            case (i[15:12])
                4'b0000: case (i[7:4])
                            4'b0001: mnem = "AND  ";
                            4'b0010: mnem = "OR   ";
                            4'b0011: mnem = "XOR  ";
                            4'b0101: mnem = "ADD  ";
                            4'b1001: mnem = "SUB  ";
                            4'b1011: mnem = "CMP  ";
                            4'b1101: mnem = "MOV  ";
                            default: mnem = "WAIT ";
                         endcase
                4'b0001: mnem = "ANDI ";
                4'b0010: mnem = "ORI  ";
                4'b0011: mnem = "XORI ";
                4'b0101: mnem = "ADDI ";
                4'b1001: mnem = "SUBI ";
                4'b1011: mnem = "CMPI ";
                4'b1101: mnem = "MOVI ";
                4'b1111: mnem = "LUI  ";
                4'b1000: mnem = (i[7:4] == 4'b0100) ? "LSH  " : "LSHI ";
                4'b1100: mnem = "Bcond";
                4'b0100: case (i[7:4])
                            4'b0000: mnem = "LOAD ";
                            4'b0100: mnem = "STOR ";
                            4'b1000: mnem = "JAL  ";
                            4'b1100: mnem = "Jcond";
                            default: mnem = "?????";
                         endcase
                default: mnem = "?????";
            endcase
        end
    endfunction

    // sampled at negedge so every value is stable 
    always @(negedge clk) begin
        if (STEP && rst_n && state == 4'd2) begin   
            $display("Decode stage | t=%0t | pc=%h | instruction reg=%h %0s | Ra=R%0d | Rb=R%0d | imm=%h | alu operation=%h",
                     $time, pc, ir, mnem(ir), uut.ra_addr, uut.rb_addr, uut.imm16, uut.alu_op);
//            $display("         alu=%b | use_imm=%b | ld=%b | st=%b | br=%b | jmp=%b | jal=%b | regwr=%b | flagen=%b | cond=%h| take=%b | psr(ZCFLN)=%b",
//                     uut.is_alu, uut.use_imm, uut.is_load, uut.is_store, uut.is_branch,
//                     uut.is_jump, uut.is_jal, uut.reg_write, uut.flag_en,
//                     uut.cond, uut.take, uut.psr);
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
