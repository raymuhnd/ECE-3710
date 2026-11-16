`timescale 1ns / 1ps
// CPU data-port decoder: BRAM (0x0000-0x7FFF) and MMIO (0xF000-0xFFFF).
// Assumptions: CPU asserts we with addr/wdata (strobes are idempotent if we lasts several cycles);
// BRAM port B has 1-cycle synchronous read; instruction fetch uses BRAM port A, not this bus.
// Reads are registered so MMIO latency equals BRAM latency. Unmapped reads return 0.
// Map: F000 FRAME_CNT | F001 STATUS[0]=OVERRUN | F002 KB_STATE[3:0]
//      F003 KB_STICKY: [3:0]=sticky, [7:4]=lost | F004 KB_CLR (write-1-to-clear)
//      F005..F008 KB_TS0..3 | F009 KB_LASTCODE | F010..F0EF sprite regs (write-only, decoded by video)
//      F0F0 SCORE (rw) | F0F1 DEBUG (rw) | F0FF COMMIT (write strobe)
module mmio_bus(
  input         clk,
  input         rst_n,
  input  [15:0] addr,
  input  [15:0] wdata,
  input         we,
  input  [15:0] bram_q,
  input  [15:0] frame_cnt,
  input         overrun,
  input  [3:0]  kb_state,
  input  [3:0]  kb_sticky,
  input  [3:0]  kb_lost,
  input  [15:0] kb_ts0, kb_ts1, kb_ts2, kb_ts3,
  input  [7:0]  kb_lastcode,
  output [15:0] rdata,
  output [14:0] bram_addr,
  output [15:0] bram_wdata,
  output        bram_we,
  output [3:0]  kb_clr,
  output        commit,
  output        spr_we,
  output [7:0]  spr_waddr,
  output [15:0] spr_wdata,
  output reg [15:0] score,
  output reg [15:0] debug
);
  wire        sel_bram = ~addr[15];
  wire        sel_mmio = (addr[15:12] == 4'hF);
  wire [11:0] a        = addr[11:0];
  wire        wr       = we & sel_mmio;

  assign bram_addr  = addr[14:0];
  assign bram_wdata = wdata;
  assign bram_we    = we & sel_bram;

  assign kb_clr    = (wr && a == 12'h004) ? wdata[3:0] : 4'b0000;
  assign commit    = wr && (a == 12'h0FF);
  assign spr_we    = wr && (a >= 12'h010) && (a <= 12'h0EF);
  assign spr_waddr = a[7:0];
  assign spr_wdata = wdata;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin score <= 16'h0000; debug <= 16'h0000; end
    else begin
      if (wr && a == 12'h0F0) score <= wdata;
      if (wr && a == 12'h0F1) debug <= wdata;
    end
  end

  reg [15:0] mmio_rd;
  always @(*) begin
    case (a)
      12'h000: mmio_rd = frame_cnt;
      12'h001: mmio_rd = {15'b0, overrun};
      12'h002: mmio_rd = {12'b0, kb_state};
      12'h003: mmio_rd = {8'b0, kb_lost, kb_sticky};
      12'h005: mmio_rd = kb_ts0;
      12'h006: mmio_rd = kb_ts1;
      12'h007: mmio_rd = kb_ts2;
      12'h008: mmio_rd = kb_ts3;
      12'h009: mmio_rd = {8'b0, kb_lastcode};
      12'h0F0: mmio_rd = score;
      12'h0F1: mmio_rd = debug;
      default: mmio_rd = 16'h0000; 
    endcase
  end

  reg        sel_bram_q, sel_mmio_q;
  reg [15:0] mmio_rd_q;
  always @(posedge clk) begin
    sel_bram_q <= sel_bram;
    sel_mmio_q <= sel_mmio;
    mmio_rd_q  <= mmio_rd;
  end

  assign rdata = sel_bram_q ? bram_q :
                 sel_mmio_q ? mmio_rd_q : 16'h0000;
endmodule