
module tcam_registered #(
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
    input logic lookup_valid,
    input logic [DATA_WIDTH-1:0] data_in,

    // Registered lookup results
    output logic result_valid,
    output logic [NUM_RULES-1:0] match_vector,
    output logic match_found,
    output logic [ADDR_WIDTH-1:0] match_index
);

    // Input pipeline registers
    logic [DATA_WIDTH-1:0] data_reg;
    logic lookup_valid_reg;

    // Combinational core outputs
    wire [NUM_RULES-1:0] core_match_vector;
    wire core_match_found;
    wire [ADDR_WIDTH-1:0] core_match_index;


    // Existing TCAM core
    tcam_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_RULES(NUM_RULES),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) core_inst (
        .clk(clk),
        .rst(rst),

        .write_en(write_en),
        .write_addr(write_addr),
        .rule_in(rule_in),
        .mask_in(mask_in),
        .valid_in(valid_in),

        .data_in(data_reg),

        .match_vector(core_match_vector),
        .match_found(core_match_found),
        .match_index(core_match_index)
    );


    // Input and output pipeline registers
    always_ff @(posedge clk) begin

        if (rst) begin

            data_reg <= '0;
            lookup_valid_reg <= 1'b0;

            result_valid <= 1'b0;
            match_vector <= '0;
            match_found <= 1'b0;
            match_index <= '0;

        end
        else begin

            // Stage 1: Capture lookup input
            lookup_valid_reg <= lookup_valid;

            if (lookup_valid) begin
                data_reg <= data_in;
            end


            // Stage 2: Capture lookup result
            result_valid <= lookup_valid_reg;

            if (lookup_valid_reg) begin

                match_vector <= core_match_vector;
                match_found <= core_match_found;
                match_index <= core_match_index;

            end
            else begin

                match_vector <= '0;
                match_found <= 1'b0;
                match_index <= '0;

            end

        end

    end

endmodule
