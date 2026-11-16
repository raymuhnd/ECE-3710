`timescale 1ns / 1ps
// Keyboard interface wrapper: ps2_rx -> kb_decoder -> kb_regs, plus KEY0-3 fallback.
// KEY pushbuttons on the DE1-SoC are active low and already debounced in hardware,
// so they only get a 2-flop synchronizer and edge detect here.
//
// PORT CONTRACT for your own modules (names must match):
//   ps2_rx  : clk, rst_n, ps2_clk, ps2_dat, code[7:0], valid, err
//   kb_regs : clk, rst_n, press[3:0], rel[3:0], clr[3:0], time_now[15:0],
//             state[3:0], sticky[3:0], lost[3:0], ts0..ts3[15:0]
module kb_interface(
  input         clk,
  input         rst_n,
  input         ps2_clk,
  input         ps2_dat,
  input  [3:0]  key_n,          // KEY0-3, active low
  input  [15:0] time_now,       // from frame_timer
  input  [3:0]  clear,            // write-1-to-clear from mmio_bus (KB_CLR)
  output [3:0]  state,
  output [3:0]  sticky,
  output [3:0]  lost,
  output [15:0] ts0, ts1, ts2, ts3,
  output [7:0]  lastcode,
  output        rx_err
);
  wire [7:0] rx_code;
  wire       rx_valid;
  wire [3:0] dec_press, dec_rel;

  ps2_rx u_rx (
    .clk(clk), .rst_n(rst_n), .ps2_clk(ps2_clk), .ps2_dat(ps2_dat),
    .code(rx_code), .valid(rx_valid), .err(rx_err)
  );

  kb_decoder u_dec (
    .clk(clk), .rst_n(rst_n), .rx_valid(rx_valid), .rx_code(rx_code),
    .press(dec_press), .rel(dec_rel), .lastcode(lastcode)
  );

  // sync, invert to active high, edge detect
  reg [3:0] key_s1, key_s2, key_prev;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin key_s1 <= 4'b0; key_s2 <= 4'b0; key_prev <= 4'b0; end
    else begin key_s1 <= ~key_n; key_s2 <= key_s1; key_prev <= key_s2; end
  end
  wire [3:0] key_press   =  key_s2 & ~key_prev;
  wire [3:0] key_rel = ~key_s2 &  key_prev;

  kb_regs u_regs (
    .clk(clk), .rst_n(rst_n),
    .press(dec_press | key_press), .rel(dec_rel | key_rel),
    .clear(clear), .time_now(time_now),
    .state(state), .sticky(sticky), .lost(lost),
    .ts0(ts0), .ts1(ts1), .ts2(ts2), .ts3(ts3)
  );
endmodule
