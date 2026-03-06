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
  wire s_hsk   = s_valid && s_ready;
  wire m_hsk   = m_valid && m_ready;

  // AXI Stream Checks
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


  // FIFO Checks

  localparam METHOD = 2;

  if (METHOD == 0) begin: g_two_data_tracking

    logic arbit_window; // unconstrained, so the tool can check for different data=d1/d2
    logic seen_s_d1, seen_m_d1, seen_s_d2, seen_m_d2;
    logic sampled_s_d1, sampled_m_d1, sampled_s_d2, sampled_m_d2;
    logic [WIDTH-1:0] d1, d2;

    // D1
    assign seen_s_d1 = (s_data == d1) && s_hsk && !sampled_s_d1 && arbit_window;
    assign seen_m_d1 = (m_data == d1) && m_hsk && sampled_s_d1;

    always_ff @(posedge clk)
      if(!rstn)           sampled_s_d1 <= 0;
      else if (seen_s_d1) sampled_s_d1 <= 1;

    always_ff @(posedge clk)
      if(!rstn)           sampled_m_d1 <= 0;
      else if (seen_m_d1) sampled_m_d1 <= 1;

    // D2
    assign seen_s_d2 = (s_data == d2) && s_hsk && !sampled_s_d2 && arbit_window;
    assign seen_m_d2 = (m_data == d2) && m_hsk && sampled_s_d2;

    always_ff @(posedge clk)
      if(!rstn)           sampled_s_d2 <= 0;
      else if (seen_s_d2) sampled_s_d2 <= 1;

    always_ff @(posedge clk)
      if(!rstn)           sampled_m_d2 <= 0;
      else if (seen_m_d2) sampled_m_d2 <= 1;

    // Constraints. d1 & d2 should be different, but stable in sim. d1 enters before d2.
    s_stable_d1: assume property ($stable(d1));
    s_stable_d2: assume property ($stable(d2));
    s_different: assume property (d1 != d2);
    s_ordering : assume property (!sampled_s_d1 |-> !sampled_s_d2);

    // FIFO Assertions
    a_ordering : assert property (sampled_s_d1 && sampled_s_d2 && !sampled_m_d1 |-> !sampled_m_d2);
    a_integrity: assert property (sampled_s_d1 |-> ##[0:$] sampled_m_d1); // data eventually comes out



  end else if (METHOD == 1) begin: g_one_data_tracking

    localparam DEPTH = 2;
    localparam DEPTH_BITS = $clog2(DEPTH);

    logic [WIDTH-1:0] d;
    logic [DEPTH_BITS:0] track_count;
    logic arbit_window, incr, decr, sampled_s, sampled_m, seen_s, seen_m;

    s_stable_d: assume property ($stable(d));

    assign incr = s_hsk && !sampled_s;
    assign decr = m_hsk && !sampled_m;

    assign seen_s = (s_data == d) && incr && arbit_window;
    assign seen_m = (track_count == 1) && sampled_s && decr;

    always_ff @(posedge clk)
      if (!rstn)        sampled_s <= 0;
      else if (seen_s)  sampled_s <= 1;

    always_ff @(posedge clk)
      if (!rstn)        sampled_m <= 0;
      else if (seen_m)  sampled_m <= 1;

    always_ff @(posedge clk)
      if (!rstn) track_count <= '0;
      else       track_count <= track_count + (incr - decr);

    a_integrity: assert property (seen_m |-> m_data == d); // data integrity
    a_liveness : assert property (sampled_s |-> ##[1:$] sampled_m); // data eventually comes out



  end else if (METHOD == 2) begin: g_idx_tracking

    logic [7:0] nn, s_nn, m_nn;
    logic sampled_s, sampled_m, seen_s, seen_m;
    logic [WIDTH-1:0] d_nn;

    s_stable_nn: assume property ($stable(nn));

    always_ff @(posedge clk)
      if      (!rstn) s_nn <= 0;
      else if (s_hsk) s_nn <= s_nn + 1;

    always_ff @(posedge clk)
      if      (!rstn) m_nn <= 0;
      else if (m_hsk) m_nn <= m_nn + 1;

    assign seen_s = (s_nn == nn) && s_hsk;
    assign seen_m = (m_nn == nn) && m_hsk && sampled_s;

    always_ff @(posedge clk)
      if (!rstn)        d_nn <= 0;
      else if (seen_s)  d_nn <= s_data;

    always_ff @(posedge clk)
      if (!rstn)        sampled_s <= 0;
      else if (seen_s)  sampled_s <= 1;

    always_ff @(posedge clk)
      if (!rstn)        sampled_m <= 0;
      else if (seen_m)  sampled_m <= 1;

    a_integrity: assert property (seen_m |-> m_data == d_nn); // data integrity
    a_liveness : assert property (sampled_s |-> ##[1:$] sampled_m); // data eventually comes out
  end

endmodule