module tb_fifo_sync;

  localparam W_DATA = 8;
  logic clk, rstn, s_ready, s_valid, s_last, m_ready, m_valid, m_last;
  logic [W_DATA-1:0] s_data, m_data;

  fifo_sync #(.W_DATA(W_DATA)) dut (.*);

  logic past_valid;
  always @(posedge clk) past_valid <= 1;
  wire active = past_valid && rstn;

  initial begin
    past_valid = 1'b0;
    rstn       = 1'b0;   // start in reset
  end

  always @(posedge clk) begin
    past_valid <= 1'b1;
    if (!past_valid) rstn <= 1'b0;
    else             rstn <= 1'b1;  // release reset after first sampled cycle
  end

  always @(posedge clk) if(active) begin
    if ($past(s_valid && !s_ready)) begin
      assume($stable(s_valid));
      assume($stable(s_data));
      assume($stable(s_last));
    end
  end

  always @(posedge clk) if(active) begin
    if ($past(m_valid && !m_ready)) begin
      assert($stable(m_valid));
      assert($stable(m_data));
      assert($stable(m_last));
    end

    cover property (m_valid && !m_ready);
  end

endmodule
