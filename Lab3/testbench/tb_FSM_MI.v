`timescale 1ns/1ps

module tb_FSM_MI;

    reg clk;
    reg key;
    reg [9:0] sw;
    
    wire [9:0] LED;
    wire [6:0] HEX0;
    wire [6:0] HEX1;
    wire [6:0] HEX2;
    wire [6:0] HEX3;
    
    FSM_Mem_Interface_L3 #(.hold(4))  uut(
    .clk  (clk),
    .key  (key),
    .sw   (sw),
    .LED  (LED),
    .HEX0 (HEX0),
    .HEX1 (HEX1),
    .HEX2 (HEX2),
    .HEX3 (HEX3)
    );
    
    
    integer errors;
    
    always #10 clk = ~clk;
    
    task run_test(input [9:0] addr, input [15:0] exp_old);
        reg [15:0] exp_new;
        integer pause; 
        begin
        
            exp_new = exp_old + 16'h0005;
            
            sw = addr;
            key = 1'b0;      // reset
            @(posedge clk);
            @(posedge clk);
            key = 1'b1;
            
            pause = 0;
            
            while (uut.state !== uut.CAPTURE && pause < 50) begin // used for holding time/ replicates out parameter
                @(posedge clk);
                pause = pause + 1;
            end
            
            @(posedge clk);
            #1;     // waits for next state for old decision
            
            if(uut.display_val !== exp_old)begin
                $display("Issue with old values read | Expected : %0d | Got : %0d", exp_old , uut.display_val);
                errors = errors + 1;
            end else begin
                $display("Passed old value comparision");
            end
            
            pause = 0;
            while ( ~LED[1] && pause < 200) begin // LED[1] shows when FSM completed
                @(posedge clk);
                pause = pause + 1;
            end
            if (pause >= 200) begin
                $display("Failed | never completed");
                errors = errors + 1;
            end else begin
                if (LED[0] !== 1'b1) begin
                    $display("Failed | pass flag not set");
                    errors = errors + 1;
                end
                if (uut.display_val !== exp_new) begin
                    $display("Failed | incorrect new value | Expected : %h | Got : %h", exp_new, uut.display_val);
                    errors = errors + 1;
                end else begin
                    $display("Pass | new value=%h", uut.display_val);
                end
            end
            $display("New value(exp_old + 5) : %h", uut.display_val);
        end
    endtask
    
    initial begin
        clk = 1'b0;
        errors = 0; 
        
        // Tests from hex file
        run_test(10'd0, 16'h0010);
        run_test(10'd1, 16'h0020);
        run_test(10'd2, 16'h0030);
        run_test(10'd510, 16'h0040);
        run_test(10'd511, 16'h0050);
        run_test(10'd512, 16'h0060);
        run_test(10'd511, 16'h0055);
        run_test(10'd512, 16'h0065);
        run_test(10'd513, 16'h0070);

        // Test like this results in unknown data because it is not set by hex file
        // run_test(10'd7, 16'h0000);
        
        
        if(errors == 0) 
            $display("All pass");
        else
            $display("There were %0d errors", errors);
            
        $finish;
    end
    
endmodule