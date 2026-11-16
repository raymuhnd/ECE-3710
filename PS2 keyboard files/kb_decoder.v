`timescale 1ns / 1ps
// Turns PS/2 scan-code bytes (set 2) into per-lane press/rel pulses.
// Lane map: bit0 = D (0x23), bit1 = F (0x2B), bit2 = J (0x3B), bit3 = K (0x42).
// F0 = break prefix, E0/E1 = extended prefix (lane keys have no E0, so extended codes are ignored).
// Key repeat arrives as repeated make codes; kb_regs ignores them via its per-lane state bit.
module kb_decoder(
  input            clk,
  input            rst_n,
  input            rx_valid,        // one-cycle pulse from ps2_rx
  input      [7:0] rx_code,
  output reg [3:0] press,           // one-cycle pulse per lane
  output reg [3:0] rel,         // one-cycle pulse per lane
  output reg [7:0] lastcode         // every received byte, for HEX debug
);
  localparam [7:0] SC_BREAK = 8'hF0, SC_EXT = 8'hE0, SC_EXT1 = 8'hE1;
  localparam [7:0] SC_D = 8'h23, SC_F = 8'h2B, SC_J = 8'h3B, SC_K = 8'h42;

  reg brk, ext;
  reg [3:0] lane_hit;

  always @(*) begin
    lane_hit = 4'b0000;
    if (!ext) begin
      case (rx_code)
        SC_D: lane_hit = 4'b0001;
        SC_F: lane_hit = 4'b0010;
        SC_J: lane_hit = 4'b0100;
        SC_K: lane_hit = 4'b1000;
        default: lane_hit = 4'b0000;   // unknown codes ignored
      endcase
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      brk <= 1'b0; ext <= 1'b0;
      press <= 4'b0; rel <= 4'b0; lastcode <= 8'h00;
    end else begin
      press <= 4'b0; rel <= 4'b0;
      if (rx_valid) begin
        lastcode <= rx_code;
        case (rx_code)
          SC_BREAK:        brk <= 1'b1;
          SC_EXT, SC_EXT1: ext <= 1'b1;
          default: begin
            brk <= 1'b0; ext <= 1'b0;
            if (brk) rel <= lane_hit;
            else     press   <= lane_hit;
          end
        endcase
      end
    end
  end
endmodule