`timescale 1ns/1ps
// The five ALU flags are stored in five additional flip-flops. Synthesis should create 256 register bits for R0-R15 and 5 flag bits.
module regfile (
    input  wire        Clock,
    input  wire        Reset,
    input  wire        WriteEnable,
    input  wire        FlagWriteEnable,
    input  wire        ReadEnableA,
    input  wire        ReadEnableB,
    input  wire [3:0]  WriteAddress,
    input  wire [3:0]  ReadAddressA,
    input  wire [3:0]  ReadAddressB,
    input  wire [15:0] WriteData,
    input  wire [4:0]  FlagsIn,
    output reg  [15:0] ReadDataA,
    output reg  [15:0] ReadDataB,
    output reg  [4:0]  StoredFlags
);

    reg [15:0] Registers [0:15];

    wire [15:0] RegisterEnable;

    assign RegisterEnable[0]  = WriteEnable && (WriteAddress == 4'd0);
    assign RegisterEnable[1]  = WriteEnable && (WriteAddress == 4'd1);
    assign RegisterEnable[2]  = WriteEnable && (WriteAddress == 4'd2);
    assign RegisterEnable[3]  = WriteEnable && (WriteAddress == 4'd3);
    assign RegisterEnable[4]  = WriteEnable && (WriteAddress == 4'd4);
    assign RegisterEnable[5]  = WriteEnable && (WriteAddress == 4'd5);
    assign RegisterEnable[6]  = WriteEnable && (WriteAddress == 4'd6);
    assign RegisterEnable[7]  = WriteEnable && (WriteAddress == 4'd7);
    assign RegisterEnable[8]  = WriteEnable && (WriteAddress == 4'd8);
    assign RegisterEnable[9]  = WriteEnable && (WriteAddress == 4'd9);
    assign RegisterEnable[10] = WriteEnable && (WriteAddress == 4'd10);
    assign RegisterEnable[11] = WriteEnable && (WriteAddress == 4'd11);
    assign RegisterEnable[12] = WriteEnable && (WriteAddress == 4'd12);
    assign RegisterEnable[13] = WriteEnable && (WriteAddress == 4'd13);
    assign RegisterEnable[14] = WriteEnable && (WriteAddress == 4'd14);
    assign RegisterEnable[15] = WriteEnable && (WriteAddress == 4'd15);

    // Each data register has its own explicit enable. A register changes only
    // on the rising clock edge when its corresponding enable is high.
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            Registers[0]  <= 16'b0;
            Registers[1]  <= 16'b0;
            Registers[2]  <= 16'b0;
            Registers[3]  <= 16'b0;
            Registers[4]  <= 16'b0;
            Registers[5]  <= 16'b0;
            Registers[6]  <= 16'b0;
            Registers[7]  <= 16'b0;
            Registers[8]  <= 16'b0;
            Registers[9]  <= 16'b0;
            Registers[10] <= 16'b0;
            Registers[11] <= 16'b0;
            Registers[12] <= 16'b0;
            Registers[13] <= 16'b0;
            Registers[14] <= 16'b0;
            Registers[15] <= 16'b0;
            StoredFlags   <= 5'b0;
        end
        else begin
            if (RegisterEnable[0])  Registers[0]  <= WriteData;
            if (RegisterEnable[1])  Registers[1]  <= WriteData;
            if (RegisterEnable[2])  Registers[2]  <= WriteData;
            if (RegisterEnable[3])  Registers[3]  <= WriteData;
            if (RegisterEnable[4])  Registers[4]  <= WriteData;
            if (RegisterEnable[5])  Registers[5]  <= WriteData;
            if (RegisterEnable[6])  Registers[6]  <= WriteData;
            if (RegisterEnable[7])  Registers[7]  <= WriteData;
            if (RegisterEnable[8])  Registers[8]  <= WriteData;
            if (RegisterEnable[9])  Registers[9]  <= WriteData;
            if (RegisterEnable[10]) Registers[10] <= WriteData;
            if (RegisterEnable[11]) Registers[11] <= WriteData;
            if (RegisterEnable[12]) Registers[12] <= WriteData;
            if (RegisterEnable[13]) Registers[13] <= WriteData;
            if (RegisterEnable[14]) Registers[14] <= WriteData;
            if (RegisterEnable[15]) Registers[15] <= WriteData;

            if (FlagWriteEnable)
                StoredFlags <= FlagsIn;
        end
    end

    // Read port A
    always @(ReadEnableA or ReadAddressA or
             Registers[0] or Registers[1] or Registers[2] or Registers[3] or
             Registers[4] or Registers[5] or Registers[6] or Registers[7] or
             Registers[8] or Registers[9] or Registers[10] or Registers[11] or
             Registers[12] or Registers[13] or Registers[14] or Registers[15]) begin
        if (ReadEnableA)
            ReadDataA = Registers[ReadAddressA];
        else
            ReadDataA = 16'b0;
    end

    // Read port B
    always @(ReadEnableB or ReadAddressB or
             Registers[0] or Registers[1] or Registers[2] or Registers[3] or
             Registers[4] or Registers[5] or Registers[6] or Registers[7] or
             Registers[8] or Registers[9] or Registers[10] or Registers[11] or
             Registers[12] or Registers[13] or Registers[14] or Registers[15]) begin
        if (ReadEnableB)
            ReadDataB = Registers[ReadAddressB];
        else
            ReadDataB = 16'b0;
    end

endmodule