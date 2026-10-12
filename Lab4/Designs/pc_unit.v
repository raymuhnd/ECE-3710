`timescale 1ns/ 1ps

module pc_unit(
    input clk,
    input rst_n, // using key on SoC again
    input pc_en,
    input [1:0] pc_sel,
    input [7:0] disp,
    input [15:0] r_target,
    output reg [15:0] pc,
    output  [15:0] pc_plus
);

    parameter INC = 2'b00, BRANCH = 2'b01, JUMP = 2'b10; 
    
    assign pc_plus = pc + 16'd1; // Will be used for JAL(necessary for our project idea)
    
    initial begin
        pc = 16'd0;
    end
    
    always@(posedge clk)begin // rst active low
        if (!rst_n)begin
            pc <= 16'd0;
        end else if (pc_en)begin
            case(pc_sel)
                INC: begin
                    pc <= pc_plus;
                end
                BRANCH: begin
                    pc <= pc + {{8{disp[7]}}, disp};
                end
                
                JUMP: begin
                    pc <= pc + r_target;
                end
                2'b11: begin
                    pc <= pc_plus;
                end
                default:begin
                    pc <= pc_plus;
                end
            endcase
        end
    end


endmodule