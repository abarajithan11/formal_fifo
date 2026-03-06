`timescale 1ns / 1ps

module tb_skid_buffer;

  localparam WIDTH = 8;
  logic clk, rstn, s_valid, m_ready, m_valid, s_ready;
  logic [WIDTH-1:0] s_data, m_data;

  skid_buffer #(.WIDTH(WIDTH)) dut (.*);

  default clocking cb @(posedge clk); endclocking
  default disable iff (!rstn);

  wire s_stall = s_valid && !s_ready;
  wire m_stall = m_valid && !m_ready;

  // Covers
  c_s_stall         : cover property (s_stall);
  c_m_stall         : cover property (m_stall);
  c_buff_full       : cover property (!s_ready && m_valid);

  // Assumes
  a_stable_s_valid  : assume property (s_stall |=> $stable(s_valid));
  a_stable_s_data   : assume property (s_stall |=> $stable(s_data));

  // Asserts
  a_stable_m_valid  : assert property (m_stall |=> $stable(m_valid));
  a_stable_m_data   : assert property (m_stall |=> $stable(m_data));

  a_after_reset     : assert property (
    $rose(rstn) |-> (s_ready && !m_valid && (m_data == '0))
  );

endmodule