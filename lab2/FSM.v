//   FSM                   the program (control)
//   ALU_Datapath          structural glue: FSM + RegFile + ALU 
//   DE1_SoC_Top           board wrapper: pins, slow clock, hex display
//   hex_to_seven_segment  display decoder 
module FSM (
    input  wire        clk,
	//active high
    input  wire        reset,

	// read port A address
    output reg  [3:0]  Rsrc,
	// read port B address 
    output reg  [3:0]  Rdest,
	// write port address
    output reg  [3:0]  WriteAddress,
	// enables the one-hot write decoder
    output reg         WriteEnable,
    output reg         ReadEnableA,
    output reg         ReadEnableB,
	// 0 = ALU bus B from regfile, 1 = imm
    output reg         RI,
    output reg  [15:0] Immediate,
    output reg  [7:0]  Opcode,
	// flag register enable
    output reg         Fe,
	// program finished
    output reg         Halt,

    output wire [4:0]  StateOut 
);

    // ALU opcodes 
    localparam [7:0] ADD  = 8'b00000101,
                     ADDI = 8'b01010000,   // 0101????
                     NOP  = 8'b00000000;

    // state encoding 
    localparam [4:0] S_RESET = 5'd0,   // idle
			// hard code ADDI R0 <- R0 + 1
                     S_INIT0 = 5'd1,
			// hard code ADDI R1 <- R0 + 1
                     S_INIT1 = 5'd2,
			   // R2  <- R1  + R0
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
			// R15 <- R14 + R13
                     S_F15   = 5'd16,
                     S_HALT  = 5'd17;

    reg [4:0] y;

    assign StateOut = y;

    // next-state logic 
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
                S_HALT : y <= S_HALT;      // stay here forever
                default: y <= S_RESET;     // illegal-state recovery
            endcase
        end
    end

    // output logic 
    // Moore machine; depends only on y. 
    always @* begin
        Rsrc         = 4'd0;
        Rdest        = 4'd0;
        WriteAddress = 4'd0;
        WriteEnable  = 1'b0;
	// read MUXes are free to run every cycle
        ReadEnableA  = 1'b1;
        ReadEnableB  = 1'b1;
        RI           = 1'b0;
        Immediate    = 16'd0;
        Opcode       = NOP;
        Fe           = 1'b0;
        Halt         = 1'b0;

        case (y)
            // Do nothing. R0..R15 are cleared by the regfile reset, so R0 already holds the first fibonacci value
            S_RESET: begin
                Opcode      = NOP;
                WriteEnable = 1'b0;
                Fe          = 1'b0;
            end

            // Simulated add-immediate. R0 <- R0 + 1: read port A supplies R0 (= 0 from reset), the R/I MUX puts the constant on ALU bus B, the result goes back into R0. No load port is added to the regfile.
            S_INIT0: begin
                Rsrc         = 4'd0;
                RI           = 1'b1;
                Immediate    = 16'd1;
                Opcode       = ADDI;
                WriteAddress = 4'd0;
                WriteEnable  = 1'b1;
                Fe           = 1'b1;
            end

            // R1 <- R1 + 1
            S_INIT1: begin
                Rsrc         = 4'd1;
                RI           = 1'b1;
                Immediate    = 16'd1;
                Opcode       = ADDI;
                WriteAddress = 4'd1;
                WriteEnable  = 1'b1;
                Fe           = 1'b1;
            end

            // Ri <- R(i-1) + R(i-2)
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

            // Program finished: hold the regfile, show R15 on the display.
            S_HALT: begin
                Rdest        = 4'd15;   // drives the hex display MUX
                Opcode       = NOP;
                WriteEnable  = 1'b0;
                Fe           = 1'b0;
                Halt         = 1'b1;
            end

            default: ;
        endcase
    end

endmodule

// ALU_Datapath  --  Module REGFILE-ALU-DATAPATH of Fig. 1.
module ALU_Datapath (
    input  wire        Clock,
    input  wire        Reset_n,        // active-low async input (e.g. KEY[0])

    output wire [15:0] DisplayValue,   // read port B -> Hex27seg
    output wire [15:0] ALUResult,      // combinational ALU output
    output wire [4:0]  FlagsOut,       // architectural flags (PSR)
    output wire        Halt,
    output wire [4:0]  StateOut
);

    // Reset synchroniser: assert asynchronously, deassert synchronously.
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

    // Control signals from the FSM
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

    // Register file. The write port takes the ALU output directly; the
    // one-hot R0e..R15e enables are generated inside the regfile by the
    // write-address decoder.
    wire [15:0] ReadDataA, ReadDataB;
    wire [4:0]  StoredFlags;
    wire [15:0] ALU_C;
    wire [4:0]  ALU_Flags;

    RegFile u_regfile (
        .Clock           (Clock),
        .Reset           (ResetSync),
        .WriteEnable     (WriteEnable),
        .FlagWriteEnable (Fe),
        .ReadEnableA     (ReadEnableA),
        .ReadEnableB     (ReadEnableB),
        .WriteAddress    (WriteAddress),
        .ReadAddressA    (Rsrc),
        .ReadAddressB    (Rdest),
        .WriteData       (ALU_C),
        .FlagsIn         (ALU_Flags),
        .ReadDataA       (ReadDataA),
        .ReadDataB       (ReadDataB),
        .StoredFlags     (StoredFlags)
    );

    // ALU bus A and the R/I MUX on ALU bus B
    wire [15:0] ALUBusA = ReadDataA;
    wire [15:0] ALUBusB = RI ? Immediate : ReadDataB;

    Lab1_ALU_16b u_alu (
        .A       (ALUBusA),
        .B       (ALUBusB),
        .Opcode  (Opcode),
        .CarryIn (StoredFlags[3]),
        .C       (ALU_C),
        .Flags   (ALU_Flags)
    );

    assign DisplayValue = ReadDataB;
    assign ALUResult    = ALU_C;
    assign FlagsOut     = StoredFlags;

endmodule


// DE1_SoC_Top -- board wrapper for the Fibonacci demo.
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

    // Clock divider: 50 MHz / 2^24 = about 3 Hz
    reg [23:0] DivCount = 24'd0;
    always @(posedge CLOCK_50)
        DivCount <= DivCount + 24'd1;

    wire SlowClock = DivCount[23];

    // Step button debounce, for single-step mode. KEY is active low.
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

    // SW is treated as active low
    wire StepMode = ~SW[0];

    // Free-run on the slow clock, or advance one state per KEY[1] press.
    wire DatapathClock = StepMode ? StepClean : SlowClock;

    // The datapath
    wire [15:0] DisplayValue, ALUResult;
    wire [4:0]  FlagsOut, StateOut;
    wire        Halt;

    ALU_Datapath u_datapath (
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

    // Current FSM state in hex on the upper two digits, handy when demoing.
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

