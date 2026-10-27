// every output depend only on the state register (moore style fsm)
module cpu_fsm (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       is_alu,
    input  wire       is_load,
    input  wire       is_store,
    input  wire       is_branch,
    input  wire       is_jump,
    input  wire       is_jal,
    input  wire       reg_write,
    input  wire       flag_en,
    input  wire       take,

	output reg        ir_en, // ir enable (loads the new instruction from mem)
	output reg        pc_en, // pc enable (1 = pc updates, 0 = pc waits)
	output reg  [1:0] pc_sel, // pc select (picks new pc value, 00 = pc+1, 01 = pc + displ, 10 = reg (jump))
    output reg        mem_en, // mem enable, 1 = port A does read/write
	output reg        mem_we, // mem write enable, 1 = write (store), 0 = read
	output reg        addr_sel, // addr select picks mem addr, 0 = pc (instr fetch), 1 = reg (load/store addr)
    output reg        reg_we, // reg write enable, 1 = write val into Rdest
	output reg  [1:0] wb_sel, // write back select, what is written into reg 00 = ALU result, 01 = mem data (load), 10 = pc+1
    output reg        flag_we, // flag write enable, 1 = save ALU flags into psr

    output wire [3:0] state
);

    localparam [3:0] S_FETCH    = 4'd0,
                     S_IRLOAD   = 4'd1,
                     S_DECODE   = 4'd2,
                     S_ALU_W    = 4'd3,    // write result, flags unchanged
                     S_ALU_WF   = 4'd4,    // write result and flags
                     S_ALU_F    = 4'd5,    // flags only cmp
                     S_LOAD1    = 4'd6,
                     S_LOAD2    = 4'd7,
                     S_STORE    = 4'd8,
                     S_BRANCH_T = 4'd9,
                     S_JUMP_T   = 4'd10,
                     S_JAL      = 4'd11,
                     S_PC_INC   = 4'd12;   // NOP/branch or jump not taken

    localparam [1:0] PC_INC = 2'b00, PC_BRANCH = 2'b01, PC_JUMP = 2'b10;
    localparam [1:0] WB_ALU = 2'b00, WB_MEM = 2'b01, WB_PC = 2'b10;

    reg [3:0] curr_state;
    assign state = curr_state;

    // next state logic
    always @(posedge clk) begin
        if (!rst_n)
            curr_state <= S_FETCH;
        else begin
            case (state)
                S_FETCH:  curr_state <= S_IRLOAD;
                S_IRLOAD: curr_state <= S_DECODE;
                S_DECODE: begin
                    if (is_alu) begin
                        if      (reg_write && flag_en) curr_state <= S_ALU_WF; // write + flags (add/sub)
                        else if (reg_write)            curr_state <= S_ALU_W; // write only (and/or/mov/shift)
                        else                           curr_state <= S_ALU_F; // flags only (cmp)
                    end
                    else if (is_load)   curr_state <= S_LOAD1;
                    else if (is_store)  curr_state <= S_STORE;
                    else if (is_branch) curr_state <= take ? S_BRANCH_T : S_PC_INC;
                    else if (is_jump)   curr_state <= take ? S_JUMP_T   : S_PC_INC;
                    else if (is_jal)    curr_state <= S_JAL;
                    else                curr_state <= S_PC_INC;
                end
                S_LOAD1:  curr_state <= S_LOAD2;
                default:  curr_state <= S_FETCH;  
            endcase
        end
    end

    // output
    always @(*) begin
        ir_en    = 1'b0;
        pc_en    = 1'b0;
        pc_sel   = PC_INC;
        mem_en   = 1'b0;
        mem_we   = 1'b0;
        addr_sel = 1'b0;
        reg_we   = 1'b0;
        wb_sel   = WB_ALU;
        flag_we  = 1'b0;

        case (curr_state)
            S_FETCH: begin
				mem_en   = 1'b1;          // read mem[pc]
            end

            S_IRLOAD: begin
				ir_en    = 1'b1;          // IR <- mem[pc]
            end

            S_DECODE: ;                   // decode+register read only

            S_ALU_W: begin
                reg_we   = 1'b1;     // 0 for cmp/cmpi
                pc_en    = 1'b1;
            end

	       S_ALU_WF: begin
                reg_we   = 1'b1;     // 0 for cmp/cmpi
                flag_we  = 1'b1;
                pc_en    = 1'b1;
            end

	       S_ALU_F: begin
                flag_we  = 1'b1;
                pc_en   = 1'b1;
            end

            S_LOAD1: begin
                mem_en   = 1'b1;          // read mem[Raddr]
                addr_sel = 1'b1;
            end

            S_LOAD2: begin
                reg_we   = 1'b1;          // Rdest <- mem data
                wb_sel   = WB_MEM;
                pc_en    = 1'b1;
            end

            S_STORE: begin
                mem_en   = 1'b1;          // mem[Raddr] <- Rsrc
                mem_we   = 1'b1;
                addr_sel = 1'b1;
                pc_en    = 1'b1;
            end

            S_BRANCH_T: begin
                pc_en    = 1'b1;
                pc_sel   = PC_BRANCH;
            end

            S_JUMP_T: begin
                pc_en    = 1'b1;
                pc_sel   = PC_JUMP;
            end

            S_JAL: begin
                reg_we   = 1'b1;          // Rlink <- PC + 1
                wb_sel   = WB_PC;
                pc_en    = 1'b1;
                pc_sel   = PC_JUMP;       // PC <- Rtarget
            end

            S_PC_INC: begin
                pc_en    = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
