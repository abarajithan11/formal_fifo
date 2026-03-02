`timescale 1ns/1ps

module fifo_sync #(
  parameter W_DATA = 8
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

  always_comb begin
    s_ready = m_ready;
    m_valid = s_valid;
    m_last  = s_last;
    m_data  = s_data;
  end

endmodule
