`timescale 1ns / 1ps
 
module FSM (
    input  wire        clk,
    input  wire        reset,

    output reg  [3:0]  Rsrc,
    output reg  [3:0]  Rdest,

    output reg  [3:0]  WriteAddress,
    output reg         WriteEnable,
    output reg         ReadEnableA,
    output reg         ReadEnableB,
    output reg         RI,
    output reg  [15:0] Immediate,
    output reg  [7:0]  Opcode,
    output reg         Fe,
    output reg         Halt,

    output wire [4:0]  StateOut 
);

    localparam [7:0] ADD  = 8'b00000101,
                     ADDI = 8'b01010000,   // 0101????
                     NOP  = 8'b00000000;

    localparam [4:0] S_RESET = 5'd0,   // idle
                     S_INIT0 = 5'd1,
                     S_INIT1 = 5'd2,
                     S_F02   = 5'd3,
                     S_F03   = 5'd4,
                     S_F04   = 5'd5,
                     S_F05   = 5'd6,
                     S_F06   = 5'd7,
                     S_F07   = 5'd8,
                     S_F08   = 5'd9,
                     S_F09   = 5'd10,
                     S_F10   = 5'd11,
                     S_F11   = 5'd12,
                     S_F12   = 5'd13,
                     S_F13   = 5'd14,
                     S_F14   = 5'd15,
                     S_F15   = 5'd16,
                     S_HALT  = 5'd17;

    reg [4:0] y;

    assign StateOut = y;

    always @(posedge clk) begin
        if (reset)
            y <= S_RESET;
        else begin
            case (y)
                S_RESET: y <= S_INIT0;
                S_INIT0: y <= S_INIT1;
                S_INIT1: y <= S_F02;
                S_F02  : y <= S_F03;
                S_F03  : y <= S_F04;
                S_F04  : y <= S_F05;
                S_F05  : y <= S_F06;
                S_F06  : y <= S_F07;
                S_F07  : y <= S_F08;
                S_F08  : y <= S_F09;
                S_F09  : y <= S_F10;
                S_F10  : y <= S_F11;
                S_F11  : y <= S_F12;
                S_F12  : y <= S_F13;
                S_F13  : y <= S_F14;
                S_F14  : y <= S_F15;
                S_F15  : y <= S_HALT;
                S_HALT : y <= S_HALT;      
                default: y <= S_RESET;     
            endcase
        end
    end

    always @* begin
        Rsrc         = 4'd0;
        Rdest        = 4'd0;
        WriteAddress = 4'd0;
        WriteEnable  = 1'b0;
	
        ReadEnableA  = 1'b1;
        ReadEnableB  = 1'b1;
        RI           = 1'b0;
        Immediate    = 16'd0;
        Opcode       = NOP;
        Fe           = 1'b0;
        Halt         = 1'b0;

        case (y)
            S_RESET: begin
                Opcode      = NOP;
                WriteEnable = 1'b0;
                Fe          = 1'b0;
            end

            S_INIT0: begin
                Rdest        = 4'd0;
                RI           = 1'b1;
                Immediate    = 16'd1;
                Opcode       = ADDI;
                WriteAddress = 4'd0;
                WriteEnable  = 1'b1;
                Fe           = 1'b1;
            end

            S_INIT1: begin
                Rdest        = 4'd1;
                RI           = 1'b1;
                Immediate    = 16'd1;
                Opcode       = ADDI;
                WriteAddress = 4'd1;
                WriteEnable  = 1'b1;
                Fe           = 1'b1;
            end

            S_F02: begin Rsrc=4'd1;  Rdest=4'd0;  WriteAddress=4'd2;  WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F03: begin Rsrc=4'd2;  Rdest=4'd1;  WriteAddress=4'd3;  WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F04: begin Rsrc=4'd3;  Rdest=4'd2;  WriteAddress=4'd4;  WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F05: begin Rsrc=4'd4;  Rdest=4'd3;  WriteAddress=4'd5;  WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F06: begin Rsrc=4'd5;  Rdest=4'd4;  WriteAddress=4'd6;  WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F07: begin Rsrc=4'd6;  Rdest=4'd5;  WriteAddress=4'd7;  WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F08: begin Rsrc=4'd7;  Rdest=4'd6;  WriteAddress=4'd8;  WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F09: begin Rsrc=4'd8;  Rdest=4'd7;  WriteAddress=4'd9;  WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F10: begin Rsrc=4'd9;  Rdest=4'd8;  WriteAddress=4'd10; WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F11: begin Rsrc=4'd10; Rdest=4'd9;  WriteAddress=4'd11; WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F12: begin Rsrc=4'd11; Rdest=4'd10; WriteAddress=4'd12; WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F13: begin Rsrc=4'd12; Rdest=4'd11; WriteAddress=4'd13; WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F14: begin Rsrc=4'd13; Rdest=4'd12; WriteAddress=4'd14; WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end
            S_F15: begin Rsrc=4'd14; Rdest=4'd13; WriteAddress=4'd15; WriteEnable=1'b1; Opcode=ADD; Fe=1'b1; end

            S_HALT: begin
                Rdest        = 4'd15;   
                Opcode       = NOP;
                WriteEnable  = 1'b0;
                Fe           = 1'b0;
                Halt         = 1'b1;
            end

            default: ;
        endcase
    end

endmodule

module ALU_Datapath (
    input  wire        Clock,
    input  wire        Reset,         

  
    input  wire [3:0]  Rsrc,           
    input  wire [3:0]  Rdest,         
    input  wire [3:0]  WriteAddress,
    input  wire        WriteEnable,
    input  wire        ReadEnableA,
    input  wire        ReadEnableB,
    input  wire        RI,           
    input  wire [15:0] Immediate,
    input  wire [7:0]  Opcode,
    input  wire        Fe,            

 
    output wire [15:0] ReadDataA,
    output wire [15:0] ReadDataB,
    output wire [15:0] ALUResult,      
    output wire [4:0]  ALUFlags,     
    output wire [4:0]  StoredFlags     
);

    regfile u_regfile (
        .Clock           (Clock),
        .Reset           (Reset),
        .WriteEnable     (WriteEnable),
        .FlagWriteEnable (Fe),
        .ReadEnableA     (ReadEnableA),
        .ReadEnableB     (ReadEnableB),
        .WriteAddress    (WriteAddress),
        .ReadAddressA    (Rsrc),
        .ReadAddressB    (Rdest),
        .WriteData       (ALUResult),
        .FlagsIn         (ALUFlags),
        .ReadDataA       (ReadDataA),
        .ReadDataB       (ReadDataB),
        .StoredFlags     (StoredFlags)
    );

    wire [15:0] ALUBusA = ReadDataB;
    wire [15:0] ALUBusB = RI ? Immediate : ReadDataA;

    Lab1_ALU_16b_wc u_alu (
        .A       (ALUBusA),
        .B       (ALUBusB),
        .Opcode  (Opcode),
        .CarryIn (StoredFlags[3]),
        .C       (ALUResult),
        .Flags   (ALUFlags)
    );

endmodule



module Fibonacci_Core (
    input  wire        Clock,
    input  wire        Reset_n,        

    output wire [15:0] DisplayValue,  
    output wire [15:0] ALUResult,      
    output wire [4:0]  FlagsOut,       
    output wire        Halt,
    output wire [4:0]  StateOut
);

    
    reg ResetMeta, ResetSync;
    always @(posedge Clock or negedge Reset_n) begin
        if (!Reset_n) begin
            ResetMeta <= 1'b1;
            ResetSync <= 1'b1;
        end
        else begin
            ResetMeta <= 1'b0;
            ResetSync <= ResetMeta;
        end
    end

    
    wire [3:0]  Rsrc, Rdest, WriteAddress;
    wire        WriteEnable, ReadEnableA, ReadEnableB, RI, Fe;
    wire [15:0] Immediate;
    wire [7:0]  Opcode;

    FSM fsm (
        .clk          (Clock),
        .reset        (ResetSync),
        .Rsrc         (Rsrc),
        .Rdest        (Rdest),
        .WriteAddress (WriteAddress),
        .WriteEnable  (WriteEnable),
        .ReadEnableA  (ReadEnableA),
        .ReadEnableB  (ReadEnableB),
        .RI           (RI),
        .Immediate    (Immediate),
        .Opcode       (Opcode),
        .Fe           (Fe),
        .Halt         (Halt),
        .StateOut     (StateOut)
    );

    wire [15:0] ReadDataA, ReadDataB;
    wire [4:0]  ALUFlags;

    ALU_Datapath u_dp (
        .Clock        (Clock),
        .Reset        (ResetSync),
        .Rsrc         (Rsrc),
        .Rdest        (Rdest),
        .WriteAddress (WriteAddress),
        .WriteEnable  (WriteEnable),
        .ReadEnableA  (ReadEnableA),
        .ReadEnableB  (ReadEnableB),
        .RI           (RI),
        .Immediate    (Immediate),
        .Opcode       (Opcode),
        .Fe           (Fe),
        .ReadDataA    (ReadDataA),
        .ReadDataB    (ReadDataB),
        .ALUResult    (ALUResult),
        .ALUFlags     (ALUFlags),
        .StoredFlags  (FlagsOut)
    );

    assign DisplayValue = ReadDataB;

endmodule


module DE1_SoC_Top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [9:0]  LEDR
);

    reg [23:0] DivCount = 24'd0;
    always @(posedge CLOCK_50)
        DivCount <= DivCount + 24'd1;

    wire SlowClock = DivCount[23];

    reg [19:0] DebCount = 20'd0;
    reg        StepSync = 1'b1, StepClean = 1'b1;

    always @(posedge CLOCK_50) begin
        StepSync <= KEY[1];
        if (StepSync != StepClean) begin
            DebCount <= DebCount + 20'd1;
            if (DebCount == 20'hFFFFF)
                StepClean <= StepSync;
        end
        else
            DebCount <= 20'd0;
    end

    wire StepMode = ~SW[0];

    wire DatapathClock = StepMode ? StepClean : SlowClock;

    wire [15:0] DisplayValue, ALUResult;
    wire [4:0]  FlagsOut, StateOut;
    wire        Halt;

    Fibonacci_Core u_datapath (
        .Clock        (DatapathClock),
        .Reset_n      (KEY[0]),
        .DisplayValue (DisplayValue),
        .ALUResult    (ALUResult),
        .FlagsOut     (FlagsOut),
        .Halt         (Halt),
        .StateOut     (StateOut)
    );

    hex_to_seven_segment u_hex0 (.hex_value(DisplayValue[3:0]),   .segments(HEX0));
    hex_to_seven_segment u_hex1 (.hex_value(DisplayValue[7:4]),   .segments(HEX1));
    hex_to_seven_segment u_hex2 (.hex_value(DisplayValue[11:8]),  .segments(HEX2));
    hex_to_seven_segment u_hex3 (.hex_value(DisplayValue[15:12]), .segments(HEX3));
    hex_to_seven_segment u_hex4 (.hex_value({3'b000, StateOut[4]}), .segments(HEX4));
    hex_to_seven_segment u_hex5 (.hex_value(StateOut[3:0]),         .segments(HEX5));

    assign LEDR[4:0] = FlagsOut;
    assign LEDR[8:5] = 4'b0000;
    assign LEDR[9]   = Halt;

endmodule

module hex_to_seven_segment (
    input      [3:0] hex_value,
    output reg [6:0] segments
);

    always @(*) begin
        case (hex_value)
            4'h0: segments = 7'b1000000;
            4'h1: segments = 7'b1111001;
            4'h2: segments = 7'b0100100;
            4'h3: segments = 7'b0110000;
            4'h4: segments = 7'b0011001;
            4'h5: segments = 7'b0010010;
            4'h6: segments = 7'b0000010;
            4'h7: segments = 7'b1111000;
            4'h8: segments = 7'b0000000;
            4'h9: segments = 7'b0010000;
            4'hA: segments = 7'b0001000;
            4'hB: segments = 7'b0000011;
            4'hC: segments = 7'b1000110;
            4'hD: segments = 7'b0100001;
            4'hE: segments = 7'b0000110;
            4'hF: segments = 7'b0001110;
            default: segments = 7'b1111111;
        endcase
    end

endmodule