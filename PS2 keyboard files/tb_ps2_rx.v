`timescale 1ns/ 1ps

module tb_ps2_rx;

    reg clk     = 1'b0;
    reg rst_n   = 1'b0;
    reg ps2_clk = 1'b1;
    reg ps2_dat = 1'b1;

    wire [7:0] code;
    wire       valid;
    wire       err;

    // half period 40 us,about 12.5 kHz
    localparam PS2_HALF = 40000;   

    ps2_rx uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .ps2_clk (ps2_clk),
        .ps2_dat (ps2_dat),
        .code    (code),
        .valid   (valid),
        .err     (err)
    );

    // 25 MHz clock, 40 ns period
    always #20 clk = ~clk;
    
    integer i;
    integer valid_cnt = 0, err_cnt = 0;
    integer pass_cnt = 0, fail_cnt = 0;
    integer v_before, e_before;
    reg [7:0] code_before;
    reg exp_valid;
    reg start_bit, parity_bit, stop_bit;

    always@(posedge clk)begin
        if(valid) valid_cnt <= valid_cnt + 1;
        if(err)   err_cnt   <= err_cnt + 1;
    end
    
    task reset;
        begin 
            rst_n = 1'b0;
            ps2_clk = 1'b1;
            ps2_dat = 1'b1;
            repeat (5) @(posedge clk);
            rst_n = 1'b1;
            
        end
    endtask
    
    task send_bit(input b);
        begin
            ps2_dat = b;
            #(PS2_HALF/2);
            ps2_clk = 1'b0;     // falling edge, DUT shifts the bit in here
            #(PS2_HALF);
            ps2_clk = 1'b1;
            #(PS2_HALF/2);
        end
    endtask
    
    task send_frame (input [7:0] data, input bad_start, input bad_parity, input bad_stop); 
        begin
            start_bit = bad_start;
            parity_bit = ~(^data) ^ bad_parity;
            stop_bit = !bad_stop;
            exp_valid  = !(bad_start || bad_parity || bad_stop);
            
            v_before    = valid_cnt;
            e_before    = err_cnt;
            code_before = code;
            
            send_bit(start_bit);
            for(i = 0; i <= 7; i = i + 1)begin
                send_bit(data[i]);
            end
            send_bit(parity_bit);
            send_bit(stop_bit);
            
            repeat (6) @(posedge clk);
            
            if(exp_valid)begin
                // good frame
                if((valid_cnt - v_before) == 1 && (err_cnt - e_before) == 0 && code == data)begin
                    pass_cnt = pass_cnt + 1;
                end else begin
                    fail_cnt = fail_cnt + 1;
                    $display("Failure | good frame %h | valid pulses %0d | err pulses %0d | code %h",
                             data, valid_cnt - v_before, err_cnt - e_before, code);
                end
            end else begin
                // bad frame
                if((valid_cnt - v_before) == 0 && (err_cnt - e_before) == 1 && code == code_before)begin
                    pass_cnt = pass_cnt + 1;
                end else begin
                    fail_cnt = fail_cnt + 1;
                    $display("Failure | bad frame %h (start:%b parity:%b stop:%b) | valid pulses %0d | err pulses %0d | code %h",
                             data, bad_start, bad_parity, bad_stop, valid_cnt - v_before, err_cnt - e_before, code);
                end
            end
        end
    endtask
    
        task send_incomplete (input [7:0] data, input integer nbits, input [7:0] next_data);
        begin
            v_before = valid_cnt;
            e_before = err_cnt;

            send_bit(1'b0);                      
            for(i = 0; i < nbits; i = i + 1)begin
                send_bit(data[i]);               
            end

            // idle longer than the 1.5 ms timeout
            #1600000;

            // a partial frame cannot produce valid or err
            if((valid_cnt - v_before) == 0 && (err_cnt - e_before) == 0)begin
                pass_cnt = pass_cnt + 1;
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("Failure | partial frame (%0d bits) produced valid pulses: %0d | err pulses: %0d",
                         nbits, valid_cnt - v_before, err_cnt - e_before);
            end

            send_frame(next_data, 0, 0, 0);
        end
    endtask
    
    initial begin
        reset;
        
        send_frame(8'h13, 0, 0, 0); // no flags
        send_frame(8'h5A, 1, 0, 0); // 1 flags
        send_frame(8'h93, 0, 1, 0); // 1 flags
        send_frame(8'h1B, 0, 0, 1); // 1 flags
        
        send_frame(8'h43, 1, 0, 1); // multiple flags
        send_frame(8'hA3, 1, 1, 1); // multiple flags
        send_frame(8'h00, 0, 0, 0);
        send_frame(8'hFF, 0, 0, 0);
        send_frame(8'hF0, 0, 0, 0);   // break prefix
        send_frame(8'hE0, 0, 0, 0);   // extended prefix

        // edge values, bad frames 
        send_frame(8'h00, 0, 1, 0);   // bad parity
        send_frame(8'hFF, 0, 1, 0);   // bad parity
        send_frame(8'hF0, 0, 0, 1);   // bad stop
        send_frame(8'hE0, 1, 0, 0);   // bad start
        
        send_incomplete(8'hFF, 3, 8'h2B);   // cut off early
        send_incomplete(8'hA5, 8, 8'h3B);   // cut off after all data bits
        send_incomplete(8'hFF, 0, 8'h42);   // start bit only
        
        $display("Testbench results | Pass %0d | Fail %0d", pass_cnt, fail_cnt);
        $finish;
    end

endmodule