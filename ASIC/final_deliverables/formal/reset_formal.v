module reset_formal (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [1:0] write_addr,
    input wire [7:0] rule_in,
    input wire [7:0] mask_in,
    input wire valid_in,
    input wire lookup_valid,
    input wire [7:0] data_in
);

    wire gold_result_valid;
    wire [3:0] gold_match_vector;
    wire gold_match_found;
    wire [1:0] gold_match_index;

    wire gate_result_valid;
    wire [3:0] gate_match_vector;
    wire gate_match_found;
    wire [1:0] gate_match_index;

    gold golden_design (
        .clk(clk),
        .rst(rst),
        .write_en(write_en),
        .write_addr(write_addr),
        .rule_in(rule_in),
        .mask_in(mask_in),
        .valid_in(valid_in),
        .lookup_valid(lookup_valid),
        .data_in(data_in),
        .result_valid(gold_result_valid),
        .match_vector(gold_match_vector),
        .match_found(gold_match_found),
        .match_index(gold_match_index)
    );

    gate final_design (
        .clk(clk),
        .rst(rst),
        .write_en(write_en),
        .write_addr(write_addr),
        .rule_in(rule_in),
        .mask_in(mask_in),
        .valid_in(valid_in),
        .lookup_valid(lookup_valid),
        .data_in(data_in),
        .result_valid(gate_result_valid),
        .match_vector(gate_match_vector),
        .match_found(gate_match_found),
        .match_index(gate_match_index)
    );

    reg past_valid = 1'b0;

    always @(posedge clk) begin
        past_valid <= 1'b1;

        // Require reset at the first sampled clock edge.
        if (!past_valid)
            assume(rst);

        // Compare outputs once the initial reset has taken effect.
        if (past_valid) begin
            assert(gold_result_valid == gate_result_valid);
            assert(gold_match_vector == gate_match_vector);
            assert(gold_match_found == gate_match_found);
            assert(gold_match_index == gate_match_index);
        end
    end

endmodule
