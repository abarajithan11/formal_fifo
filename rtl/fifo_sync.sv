`timescale 1ns/1ps

module sram #(
  parameter DEPTH = 8,
  parameter W_DATA = 8,
  localparam W_ADDR = $clog2(DEPTH)
)(
  input  logic clk, rstn,
  input  logic [W_ADDR-1:0] w_addr,
  input  logic [W_ADDR-1:0] r_addr,
  input  logic w_en, r_en,
  input  logic [W_DATA-1:0] w_data,
  output logic [W_DATA-1:0] r_data
);
  logic [W_DATA-1:0] mem [DEPTH];

  always_ff @(posedge clk)
    if (!rstn) begin
      r_data <= 0;
    end else if (r_en) begin
      r_data <= mem[r_addr];
    end

  always_ff @(posedge clk)
    if (w_en) mem[w_addr] <= w_data;

endmodule


module fifo_sync #(
  parameter W_DATA = 8,
  parameter DEPTH = 8
)(
  input  logic clk, rstn,
  output logic s_ready,
  input  logic s_valid,
  input  logic s_last,
  input  logic [W_DATA-1:0] s_data,
  input  logic m_ready,
  output logic m_valid,
  output logic m_last,
  output logic [W_DATA-1:0] m_data
);
  logic m_valid_next, m_last_next, s_ready_next;
  logic [W_DATA-1:0] m_data_next;
  logic [W_DATA:0] r_data, w_data;

  wire s_hs = s_valid && s_ready;
  wire m_hs = m_valid && m_ready;

  localparam W_ADDR = $clog2(DEPTH);
  logic [W_ADDR-1:0] w_addr, w_addr_next, r_addr, r_addr_next;
  logic empty, full, empty_next, full_next, r_en, w_en, m_stall;

  sram #(.DEPTH(DEPTH), .W_DATA(W_DATA+1)) mem (.*);

  // Max number of elements in the FIFO is DEPTH-1,
  // empty = (w_addr == r_addr)
  // full = (w_addr == r_addr-1)

  /*
  
  * at the beginning, w_addr=r_addr=0, empty=1, full=0, s_ready=1, m_valid=0
  * when s_valid:
    * wen = 1, w_data = {s_last, s_data}, w_addr_next = 1
    * in the next clock, 
        data gets written to mem[0], and m_data
        m_valid becomes high

  * when m_ready:

  
  
  */

  always_comb begin
    w_addr_next = w_addr + W_ADDR'(s_hs);
    r_addr_next = r_addr + W_ADDR'(m_hs);

    empty_next = (w_addr_next == r_addr_next);
    full_next  = (w_addr_next == r_addr_next - W_ADDR'(1));

    s_ready_next = !full_next;
    m_valid_next = !empty_next;

    m_stall = m_valid && !m_ready;

    w_en = s_hs;
    w_data = {s_last, s_data};
    r_en = !m_stall;
    {m_last_next, m_data_next} = empty ? {s_last, s_data} : r_data;
  end


  always_ff @(posedge clk)
    if (!rstn) begin
      m_valid <= 0;
      m_last  <= 0;
      m_data  <= 0;
      s_ready <= 0;
      w_addr  <= 0;
      r_addr  <= 0;
      empty   <= 1;
      full    <= 0;
    end else begin
      m_valid <= m_valid_next;
      m_last  <= m_last_next;
      m_data  <= m_data_next;
      s_ready <= s_ready_next;
      w_addr  <= w_addr_next;
      r_addr  <= r_addr_next;
      empty   <= empty_next;
      full    <= full_next;
    end

endmodule
