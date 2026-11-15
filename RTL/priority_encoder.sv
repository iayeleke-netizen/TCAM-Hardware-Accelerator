
module priority_encoder #(
    parameter NUM_RULES = 4,
    parameter INDEX_WIDTH = (NUM_RULES > 1) ?
                            $clog2(NUM_RULES) : 1
)(
    input logic [NUM_RULES-1:0] match_vector,

    output logic match_found,
    output logic [INDEX_WIDTH-1:0] match_index
);

    integer i;

    always_comb begin

        // Default outputs
        match_found = 1'b0;
        match_index = '0;

        // Search from lowest to highest index
        for (i = 0; i < NUM_RULES; i = i + 1) begin

            if (match_vector[i] && !match_found) begin

                match_found = 1'b1;
                match_index = INDEX_WIDTH'(i);

            end

        end

    end

endmodule

