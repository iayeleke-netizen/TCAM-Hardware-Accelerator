
module tcam_array #(
    parameter DATA_WIDTH = 8,
    parameter NUM_RULES = 4
)(
    input logic [DATA_WIDTH-1:0] data_in,

    input logic [DATA_WIDTH-1:0]
        rules [0:NUM_RULES-1],

    input logic [DATA_WIDTH-1:0]
        masks [0:NUM_RULES-1],

    input logic [NUM_RULES-1:0] valid,

    output wire [NUM_RULES-1:0] match_vector
);

    wire [NUM_RULES-1:0] raw_match;

    genvar i;

    generate

        for (i = 0; i < NUM_RULES; i = i + 1)
        begin : comparator_array

            tcam_comparator #(
                .DATA_WIDTH(DATA_WIDTH)
            ) comparator_inst (
                .data_in(data_in),
                .rule(rules[i]),
                .mask(masks[i]),
                .match(raw_match[i])
            );

            assign match_vector[i] =
                raw_match[i] & valid[i];

        end

    endgenerate

endmodule
