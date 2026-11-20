
module tcam_rule_memory #(
    parameter DATA_WIDTH = 8,
    parameter NUM_RULES = 4,
    parameter ADDR_WIDTH = (NUM_RULES > 1) ?
                           $clog2(NUM_RULES) : 1
)(
    input logic clk,
    input logic rst,

    input logic write_en,
    input logic [ADDR_WIDTH-1:0] write_addr,
    input logic [DATA_WIDTH-1:0] rule_in,
    input logic [DATA_WIDTH-1:0] mask_in,
    input logic valid_in,

    output logic [DATA_WIDTH-1:0]
        rules [0:NUM_RULES-1],

    output logic [DATA_WIDTH-1:0]
        masks [0:NUM_RULES-1],

    output logic [NUM_RULES-1:0] valid
);

    integer i;

    always_ff @(posedge clk) begin

        if (rst) begin

            for (i = 0; i < NUM_RULES; i = i + 1) begin
                rules[i] <= '0;
                masks[i] <= '0;
            end

            valid <= '0;

        end

        else if (write_en && write_addr < NUM_RULES) begin

            rules[write_addr] <= rule_in;
            masks[write_addr] <= mask_in;
            valid[write_addr] <= valid_in;

        end

    end

endmodule
