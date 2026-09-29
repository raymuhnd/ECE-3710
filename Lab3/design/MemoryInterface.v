`timescale 1ns/1ps

module MemoryInterface (
    input wire Clock,

    input wire EnableA,
    input wire WriteEnableA,
    input wire [9:0] AddressA,
    input wire [15:0] DataInA,
    output reg [15:0] DataOutA,

    input wire EnableB,
    input wire WriteEnableB,
    input wire [9:0] AddressB,
    input wire [15:0] DataInB,
    output reg [15:0] DataOutB
);

    reg [15:0] Memory [0:1023];

    localparam INIT_FILE = "memory_init.hex";

    initial begin
        $readmemh(INIT_FILE, Memory);
    end

    always @(posedge Clock) begin
        if (EnableA) begin
            if (WriteEnableA) begin
                Memory[AddressA] <= DataInA;
                DataOutA <= DataInA;
            end
            else begin
                DataOutA <= Memory[AddressA];
            end
        end
    end

    always @(posedge Clock) begin
        if (EnableB) begin
            if (WriteEnableB) begin
                Memory[AddressB] <= DataInB;
                DataOutB <= DataInB;
            end
            else begin
                DataOutB <= Memory[AddressB];
            end
        end
    end

endmodule

// Memory interface hex file(not sure what this is).
//@000
//0010
//0020
//0030

//@1FE
//0040
//0050
//0060
//0070
