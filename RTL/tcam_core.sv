
module tcam_core #(
    parameter DATA_WIDTH = 8,
    parameter NUM_RULES = 4,
    parameter ADDR_WIDTH = (NUM_RULES > 1) ?
                           $clog2(NUM_RULES) : 1
)(
    input logic clk,
    input logic rst,

    // Configuration interface
    input logic write_en,
    input logic [ADDR_WIDTH-1:0] write_addr,
    input logic [DATA_WIDTH-1:0] rule_in,
    input logic [DATA_WIDTH-1:0] mask_in,
    input logic valid_in,

    // Lookup interface
    input logic [DATA_WIDTH-1:0] data_in,

    // Lookup results
    output wire [NUM_RULES-1:0] match_vector,
    output wire match_found,
    output wire [ADDR_WIDTH-1:0] match_index
);

    // Internal connections
    wire [DATA_WIDTH-1:0]
        rules [0:NUM_RULES-1];

    wire [DATA_WIDTH-1:0]
        masks [0:NUM_RULES-1];

    wire [NUM_RULES-1:0] valid;


    // Module 1: Rule and mask memory
    tcam_rule_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_RULES(NUM_RULES),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) rule_memory_inst (
        .clk(clk),
        .rst(rst),

        .write_en(write_en),
        .write_addr(write_addr),
        .rule_in(rule_in),
        .mask_in(mask_in),
        .valid_in(valid_in),

        .rules(rules),
        .masks(masks),
        .valid(valid)
    );


    // Module 2: Parallel TCAM array
    tcam_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_RULES(NUM_RULES)
    ) tcam_array_inst (
        .data_in(data_in),

        .rules(rules),
        .masks(masks),
        .valid(valid),

        .match_vector(match_vector)
    );


    // Module 3: Priority encoder
    priority_encoder #(
        .NUM_RULES(NUM_RULES),
        .INDEX_WIDTH(ADDR_WIDTH)
    ) priority_encoder_inst (
        .match_vector(match_vector),

        .match_found(match_found),
        .match_index(match_index)
    );

endmodule
