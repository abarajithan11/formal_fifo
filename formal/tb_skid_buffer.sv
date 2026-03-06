`timescale 1ns / 1ps

module tb_skid_buffer;

  localparam WIDTH = 8;

  logic clk;
  logic             rstn;
  logic             s_valid, m_ready;
  logic [WIDTH-1:0] s_data;
  logic             m_valid, s_ready;
  logic [WIDTH-1:0] m_data;

  skid_buffer #(.WIDTH(WIDTH)) dut (.*);

  logic f_past_valid, past_rstn;
  initial begin
    f_past_valid = 1'b0;
    past_rstn    = 1'b0;
  end

  always @(posedge clk) begin
    f_past_valid <= 1'b1;
    past_rstn    <= rstn;
  end

  // Startup reset assumption: standard formal pattern
  always @(*) begin
    if (!f_past_valid) begin
      assume(!rstn);
      assume(!s_valid);   // optional, but reasonable
    end
  end

  // For a clean startup-cover task, keep reset deasserted after cycle 0
  always @(posedge clk)
    if (f_past_valid)
      assume(rstn);

  default clocking cb @(posedge clk);
  endclocking
  
  wire active = rstn && $past(rstn);

  // Slave-side stability assumptions
  always @(posedge clk) if (active && $past(s_valid && !s_ready)) begin
    assume(s_valid);
    assume(s_data == $past(s_data));
  end

  // Master-side stability assertions
  always @(posedge clk) if (active && $past(m_valid && !m_ready)) begin
    assert(m_valid);
    assert(m_data == $past(m_data));
  end

  // Reset-state assertions
  always @(posedge clk)
    if (!f_past_valid || $past(!rstn)) begin
      if (f_past_valid) begin
        assert(s_ready);
        assert(!m_valid);
        assert(m_data == '0);
      end
    end

  wire buff_full = active && !s_ready && m_valid;
  always @(posedge clk)
    cover (buff_full);

endmodule