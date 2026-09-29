`timescale 1ns/1ps

// key - active low reset
// HEX3-0 - last value read from memory 
// LEDR[0] - pass 
// LEDR[1] - Finish
module FSM_Mem_Interface_L3  (
    input  wire        clk,
    input  wire        key, // Reset
    input  wire [9:0]  sw,
    output wire [9:0]  LED,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3
);

    localparam [15:0] add_const = 16'h0005;
    parameter hold = 100000000;   // about 2 s at 50 MHz
    
    localparam READ1    = 4'd0;
    localparam CAPTURE  = 4'd1;
    localparam SHOW_OLD = 4'd2;
    localparam WRITE    = 4'd3;
    localparam READ2    = 4'd4;
    localparam VERIFY   = 4'd5;
    localparam SHOW_NEW = 4'd6;
    localparam DONE     = 4'd7;

    wire Clock = clk;
    wire rst = ~key;

    reg [3:0]  state;
    reg [9:0]  addr;
    reg [15:0] new_val;
    reg [15:0] display_val;
    reg [31:0] timer;
    reg        pass;

    reg         en_a;
    reg         we_a;
    wire [15:0] dout_a;

    MemoryInterface mem (
        .Clock(Clock),
        .EnableA(en_a),
        .WriteEnableA(we_a),
        .AddressA(addr),
        .DataInA(new_val),
        .DataOutA(dout_a),
        .EnableB(1'b0),
        .WriteEnableB(1'b0),
        .AddressB(10'd0),
        .DataInB(16'd0),
        .DataOutB() // N/A
    );

    // Memory controls depend only on the state
    always @(*) begin
        en_a = 1'b0;
        we_a = 1'b0;
        case (state)
            READ1: en_a = 1'b1;
            WRITE: begin
                en_a = 1'b1;
                we_a = 1'b1;
            end
            READ2: en_a = 1'b1;
            default: ;
        endcase
    end

    always @(posedge Clock) begin
        if (rst) begin
            state       <= READ1;
            addr        <= sw;
            new_val     <= 16'd0;
            display_val <= 16'd0;
            timer       <= 32'd0;
            pass        <= 1'b0;
        end
        else begin
            case (state)
                READ1:   state <= CAPTURE;

                CAPTURE: begin
                    display_val <= dout_a;
                    new_val     <= dout_a + add_const;
                    state       <= SHOW_OLD;
                end

                SHOW_OLD: begin
                    if (timer == hold - 1) begin
                        timer <= 32'd0;
                        state <= WRITE;
                    end
                    else timer <= timer + 1;
                end

                WRITE:   state <= READ2;

                READ2:   state <= VERIFY;

                VERIFY: begin
                    display_val <= dout_a;
                    pass        <= (dout_a == new_val);
                    state       <= SHOW_NEW;
                end

                SHOW_NEW: begin
                    if (timer == hold - 1) begin
                        timer <= 32'd0;
                        state <= DONE;
                    end
                    else timer <= timer + 1;
                end

                DONE:    state <= DONE;

                default:   state <= READ1;
            endcase
        end
    end

    assign LED = {8'b0, (state == DONE), pass};

    hex_to_seven_segment h0 (.hex_value(display_val[3:0]),   .segments(HEX0));
    hex_to_seven_segment h1 (.hex_value(display_val[7:4]),   .segments(HEX1));
    hex_to_seven_segment h2 (.hex_value(display_val[11:8]),  .segments(HEX2));
    hex_to_seven_segment h3 (.hex_value(display_val[15:12]), .segments(HEX3));

endmodule
