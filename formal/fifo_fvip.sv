package pkg_fifo_fvip;

  typedef logic [2:0] flag_t;

  property fifo_ordering(flag_t s_took, flag_t m_took);
    s_took[0] && s_took[1] && !m_took[0] |-> !m_took[1];
  endproperty

  property fifo_unique_out(flag_t m_took, flag_t m_take);
    m_took[2] |-> !m_take[2];
  endproperty

  property fifo_integrity(flag_t s_took, flag_t m_took, int MAX_DELAY);
    s_took[0] |-> ##[0:MAX_DELAY] m_took[0];
  endproperty

endpackage


module fifo_fvip #(
  parameter bit CAUSAL = 1
) (
  input  logic clk, rstn,
  input  logic s_hsk, m_hsk,
  input  logic [2:0] s_is, m_is,
  output logic [2:0] s_took, m_took, m_take
);
  default clocking cb @(posedge clk); endclocking

  logic f_pick;

  //_____________ Input tracking_____________
  wire [2:0] s_take;
  assign s_take[0] = s_is[0] && s_hsk && !s_took[0] && f_pick;
  assign s_take[1] = s_is[1] && s_hsk && !s_took[1] && f_pick;
  assign s_take[2] = s_is[2] && s_hsk;

  always_ff @(posedge clk)
    if (!rstn)  s_took <= '0;
    else        s_took <= s_took | s_take;

  //_____________ D1 before D2_____________
  s_ordering: assume property (!s_took[0] |-> !s_took[1]);

  //_____________ Output tracking_____________
  wire [1:0] elig = CAUSAL ? s_took[1:0] : 2'b11;

  assign m_take[0] = m_is[0] && m_hsk && elig[0] && !m_took[0];
  assign m_take[1] = m_is[1] && m_hsk && elig[1] && !m_took[1];
  assign m_take[2] = m_is[2] && m_hsk;

  always_ff @(posedge clk)
    if (!rstn)  m_took <= '0;
    else        m_took <= m_took | m_take;

  //_____________ Uniqueness assumption_____________
  s_unique_in: assume property (s_took[2] |-> !s_take[2]);

endmodule