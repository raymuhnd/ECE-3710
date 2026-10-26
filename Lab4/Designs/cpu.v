module cpu #(
    parameter ADDR_WIDTH = 10,
    parameter INIT_FILE  = "lab4_program.hex",
    parameter DISP_ADDR  = 16'h00FF
)(
    input         clk,
    input         rst_n,

    // last value the program stored, (shown on the 7-seg display)
    output reg [15:0] disp_out,

    // debug outputs
    output [15:0] pc_out,
    output [15:0] ir_out,
    output [3:0]  state_out
);

    localparam [1:0] WB_ALU = 2'b00, WB_MEM = 2'b01, WB_PC = 2'b10;

    // control (from the FSM)
    wire       ir_en, pc_en, mem_en, mem_we, addr_sel, reg_we, flag_we;
    wire [1:0] pc_sel, wb_sel;

    // decoder outputs
    wire [7:0]  alu_op, disp;
    wire [3:0]  ra_addr, rb_addr, cond;
    wire [15:0] imm16;
    wire        is_alu, use_imm, is_load, is_store, is_branch, is_jump, is_jal;
    wire        reg_write, flag_en;

    // datapath
    wire [15:0] pc, pc_plus, ir;
    wire [15:0] mem_q;
    wire [15:0] ra_data, rb_data;
    wire [15:0] alu_b, alu_result;
    wire [4:0]  alu_flags;
    wire [4:0]  psr;            // {Z, C, F, L, N}
    wire        take;
    reg  [15:0] reg_wdata;
    wire [15:0] mem_addr;

    // muxes
    assign alu_b    = use_imm  ? imm16   : rb_data;
    assign mem_addr = addr_sel ? rb_data : pc;

    always @(*) begin
        case (wb_sel)
            WB_MEM:  reg_wdata = mem_q;      // LOAD
            WB_PC:   reg_wdata = pc_plus;    // JAL link
            default: reg_wdata = alu_result; // ALU ops
        endcase
    end

    cpu_fsm u_fsm (
        .clk(clk), .rst_n(rst_n),
        .is_alu(is_alu), .is_load(is_load), .is_store(is_store),
        .is_branch(is_branch), .is_jump(is_jump), .is_jal(is_jal),
        .reg_write(reg_write), .flag_en(flag_en), .take(take),
        .ir_en(ir_en), .pc_en(pc_en), .pc_sel(pc_sel),
        .mem_en(mem_en), .mem_we(mem_we), .addr_sel(addr_sel),
        .reg_we(reg_we), .wb_sel(wb_sel), .flag_we(flag_we),
        .state(state_out)
    );

    pc_unit u_pc (
        .clk(clk), .rst_n(rst_n), .pc_en(pc_en), .pc_sel(pc_sel),
        .disp(disp), .r_target(rb_data), .pc(pc), .pc_plus(pc_plus)
    );

    ir_reg u_ir (
        .clk(clk), .rst_n(rst_n), .ir_en(ir_en), .data_in(mem_q), .ir(ir)
    );

    instr_decode u_decode (
        .instruction(ir), .alu_op(alu_op), .ra_addr(ra_addr), .rb_addr(rb_addr),
        .disp(disp), .cond(cond), .imm16(imm16),
        .is_alu(is_alu), .use_imm(use_imm), .is_load(is_load), .is_store(is_store),
        .is_branch(is_branch), .is_jump(is_jump), .is_jal(is_jal),
        .reg_write(reg_write), .flag_en(flag_en)
    );

    // register file + PSR flags (RegFile uses an active-high reset)
    RegFile u_regfile (
        .Clock(clk), .Reset(~rst_n),
        .WriteEnable(reg_we), .FlagWriteEnable(flag_we),
        .ReadEnableA(1'b1), .ReadEnableB(1'b1),
        .WriteAddress(ra_addr), .ReadAddressA(ra_addr), .ReadAddressB(rb_addr),
        .WriteData(reg_wdata), .FlagsIn(alu_flags),
        .ReadDataA(ra_data), .ReadDataB(rb_data), .StoredFlags(psr)
    );

    Lab4_ALU u_alu (
        .A(ra_data), .B(alu_b), .CarryIn(psr[3]),
        .C(alu_result), .Opcode(alu_op), .Flags(alu_flags)
    );

    cond_check u_cond (
        .cond(cond), .flags(psr), .take(take)
    );

    ram #(.ADDR_WIDTH(ADDR_WIDTH), .INIT_FILE(INIT_FILE)) u_mem (
        .clk(clk), .en(mem_en), .we(mem_we),
        .addr(mem_addr[ADDR_WIDTH-1:0]), .data(ra_data), .q(mem_q)
    );

    // display reg: copies whatever the program stores to DISP_ADDR (the memory write still happens too)
    always @(posedge clk) begin
        if (!rst_n)
            disp_out <= 16'h0000;
        else if (mem_en && mem_we && mem_addr == DISP_ADDR)
            disp_out <= ra_data;
    end

    assign pc_out = pc;
    assign ir_out = ir;

endmodule

// Reads are synchronous: the data for an address shows up on q after the next clock edge.
// When en is 0 the RAM does nothing and q holds its last value.
module ram #(
    parameter ADDR_WIDTH = 10,                    // 2^10 = 1024 words
    parameter INIT_FILE  = "lab4_program.hex"
)(
    input                     clk,
    input                     en,
    input                     we,
    input  [ADDR_WIDTH-1:0]   addr,
    input  [15:0]             data,
    output reg [15:0]         q
);

    reg [15:0] mem [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    always @(posedge clk) begin
        if (en) begin
            if (we) begin
                mem[addr] <= data;
                q         <= data;
            end else begin
                q         <= mem[addr];
            end
        end
    end

endmodule
