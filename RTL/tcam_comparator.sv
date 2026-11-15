
module tcam_comparator #(
    parameter DATA_WIDTH = 8
)(
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic [DATA_WIDTH-1:0] rule,
    input  logic [DATA_WIDTH-1:0] mask,
    output logic match
);

    logic [DATA_WIDTH-1:0] xor_result;
    logic [DATA_WIDTH-1:0] masked_result;

    assign xor_result = data_in ^ rule;
    assign masked_result = xor_result & mask;
    assign match = (masked_result == '0);

endmodule
