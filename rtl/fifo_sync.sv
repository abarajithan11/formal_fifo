module fifo_sync (
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic [31:0] C
);

    assign C = A + B;

endmodule
