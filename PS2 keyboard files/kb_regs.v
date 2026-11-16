`timescale 1ns / 1ps

module kb_regs (
    input clk, 
    input rst_n, 
    input [3:0] press, rel, clear,
    input [15:0] time_now,
    output reg [3:0] state, sticky, lost,
    output reg [15:0] ts0, ts1, ts2, ts3
);

    always@(posedge clk)begin
        if(!rst_n) begin
            state <= 0;
            sticky <= 0;
            lost <= 0;
            ts0 <= 0;
            ts1 <= 0;
            ts2 <= 0;
            ts3 <= 0;
        end else begin
            sticky <= sticky & ~clear;
            lost <= lost & ~clear;
            state <= state & ~rel;
            
            if(~state[0] && press[0])begin
                sticky[0] <= 1'b1;
                state[0] <= 1'b1;
                
                if(~sticky[0])begin
                    ts0 <= time_now;
                end else begin
                    lost[0] <= 1'b1;
                end
            end
            
           
            
            if(~state[1] && press[1])begin
                sticky[1] <= 1'b1;
                state[1] <= 1'b1;
                
                if(~sticky[1])begin
                    ts1 <= time_now;
                end else begin
                    lost[1] <= 1'b1;
                end
            end
            
            
            
            if(~state[2] && press[2])begin
                sticky[2] <= 1'b1;
                state[2] <= 1'b1;
                if(~sticky[2])begin
                    ts2 <= time_now;
                end else begin
                    lost[2] <= 1'b1;
                end
            end
            
            
            
            if(~state[3] && press[3])begin
                sticky[3] <= 1'b1;
                state[3] <= 1'b1;
                if(~sticky[3])begin
                    ts3 <= time_now;
                end else begin
                    lost[3] <= 1'b1;
                end
            end
            
        end
    end
endmodule