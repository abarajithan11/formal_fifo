module tb_fifo_sync;

  localparam W_DATA = 8;
  (* gclk *) logic clk;
  logic rstn, s_ready, s_valid, s_last, m_ready, m_valid, m_last;
  logic [W_DATA-1:0] s_data, m_data;

  fifo_sync #(.W_DATA(W_DATA)) dut (.*);

  logic past_valid;
  initial past_valid = 0;
  always @(posedge clk) past_valid <= 1;
  wire active = past_valid && rstn;

  always @(posedge clk) begin
    if (!past_valid) assume(!rstn);  // 1st clock edge: in reset
    else            assume( rstn);   // thereafter: out of reset
  end

  always @(posedge clk) if (past_valid) assume (rstn); // start in reset

  wire s_hs = s_valid && s_ready;
  wire m_hs = m_valid && m_ready;
  wire s_stall = s_valid && !s_ready;
  wire m_stall = m_valid && !m_ready;

  always @(posedge clk) if(active) begin
    if ($past(s_valid && !s_ready)) begin
      assume($stable(s_valid));
      assume($stable(s_data));
      assume($stable(s_last));
    end
  end

  always @(posedge clk)
    if(!rstn) begin
      assume(!s_valid);
      assume(!s_last);
      assume(!m_ready);
      assume(s_data == 0);
    end

  // always @(posedge clk) if(active) begin
  //   if ($past(m_valid && !m_ready)) begin
  //     assert($stable(m_valid));
  //     assert($stable(m_data));
  //     assert($stable(m_last));
  //   end
  // end

  always @(posedge clk) if (active) begin
    // cover(s_hs);
    cover(dut.full);
  end

endmodule
