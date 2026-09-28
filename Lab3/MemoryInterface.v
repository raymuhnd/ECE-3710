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

    (* ramstyle = "M10K" *) reg [15:0] Memory [0:1023];

    initial begin
        $readmemh("memory_init.hex", Memory);
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