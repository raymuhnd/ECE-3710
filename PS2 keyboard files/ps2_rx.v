`timescale 1ns / 1ps

module ps2_rx (
   input clk,
   input rst_n,
   input ps2_clk,
   input ps2_dat,
   output reg [7:0] code,
   output reg valid,
   output reg err
);

    reg [1:0] clk_save, dat_save;
    reg clk_prev;
    
    always@(posedge clk)begin
        clk_save <= {clk_save[0], ps2_clk};
        dat_save <= {dat_save[0], ps2_dat};
        clk_prev <= clk_save[1];
    end
    
    wire fall_edge = clk_prev && ~clk_save[1];
    
    reg [3:0] count;
    reg [15:0] idle_count;
    reg [10:0] frame;
    // frame once the stop bit arrives: f[0]=start, f[8:1]=data, f[9]=parity, f[10]=stop
    wire [10:0] full = {dat_save[1], frame[10:1]};

    always@(posedge clk)begin
        if (!rst_n)begin
            count <= 0;
            idle_count <= 0;
            frame <= 0;
            code <= 0;
            valid <= 1'b0;
            err <= 1'b0;
        end else begin
            valid <= 1'b0;
            err <= 1'b0;
            if(fall_edge)begin
                idle_count <= 0;
                frame <= full;
                if(count == 4'd10)begin
                    count <= 0;
                    if(!full[0] && full[10] && (^full[9:1]))begin // checks for parity bit and start/stop bit
                        code <= full[8:1];
                        valid <= 1'b1;
                    end else begin
                        err <= 1'b1;
                    end
                end else begin
                    count <= count + 1;
                end
            end else begin
                idle_count <= idle_count + 1;
                if (idle_count == 16'd37500) count <= 0; // this means that it has been 1.5 ms
            end
        end
    end

endmodule