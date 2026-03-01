module tb_fifo_sync;
  logic clk;
  logic [31:0] A, B, C;

  fifo_sync dut (.A(A), .B(B), .C(C));

  always @(posedge clk) begin
    assert property (C == A + B);
    cover  property (C == 32'hFFFF_FFFF);
  end

endmodule
