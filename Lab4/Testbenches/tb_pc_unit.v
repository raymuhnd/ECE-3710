`timescale 1ns / 1ps

module tb_pc_unit;
    reg clk = 1'b0;
    reg rst_n;
    reg pc_en;
    reg [1:0] pc_sel;
    reg [7:0] disp;     
    reg [15:0] r_target;
    
    wire [15:0] pc;
    wire [15:0] pc_plus;
    
    integer errors = 0;
    
    pc_unit uut(.clk(clk), .rst_n(rst_n), .pc_en(pc_en), .pc_sel(pc_sel), .disp(disp),
     .r_target(r_target), .pc(pc), .pc_plus(pc_plus));
     
    always #10 clk = ~clk;
    
    task check_pc(input [1:0] sel, input [7:0] pc_disp, input [15:0] target);
        reg [15:0] exp_pc;
        
        begin    
            @(negedge clk);
            pc_en = 1'b1;
            pc_sel = sel;
            disp = pc_disp;
            r_target = target;
            case(sel)
                2'b01: exp_pc = pc + {{8{disp[7]}},disp};
                2'b10: exp_pc = pc + r_target;
                default : exp_pc = pc + 16'd1;
            endcase
            @(posedge clk);
            #1;
            pc_en = 1'b0;
            
            if(uut.pc !== exp_pc)begin
                errors = errors + 1;
                $display("PC is incorrect | Got: %0d | Expected: %0d", uut.pc , exp_pc);
            end
            if(uut.pc_plus !== pc + 16'd1)begin
                errors = errors + 1;
                $display("PC plus is incorrect | Got: %0d | Expected: %0d", uut.pc_plus , pc + 16'd1);
            end
            
        end
    endtask
    
    initial begin
        pc_en = 1'b0;
        disp = 8'd0;
        pc_sel = 2'b00;
        r_target = 16'd0;
    
        rst_n = 1'b0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        
        if (pc !== 16'd0) begin 
            errors = errors + 1; 
            $display("Incorrect pc start value"); 
        end

        
        // Basic checks
        check_pc(2'd0, 8'd0,  16'd0);       // PC + 1
        check_pc(2'd3, 8'd0,  16'd0);       // PC + 1 but not set to INC state
        check_pc(2'd1, 8'd5,  16'd0);       // branch to +5(all branches are sign extended)
        check_pc(2'd1, 8'hFF, 16'd0);       // branch to -1
        check_pc(2'd1, 8'h7F, 16'd0);       // branch to +127
        check_pc(2'd1, 8'h80, 16'd0);       // branch to -128
        check_pc(2'd2, 8'd0,  16'hABCD);    // jump loads value

        // Test final value for PC and see if it wraps 
        check_pc(2'd2, 8'd0,  16'hFFFE);
        check_pc(2'd0, 8'd0,  16'd0);       
        check_pc(2'd0, 8'd0,  16'd0);       
        check_pc(2'd1, 8'hFF, 16'd0);
        
        
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
