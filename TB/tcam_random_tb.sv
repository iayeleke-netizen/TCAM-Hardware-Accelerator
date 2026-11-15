
`timescale 1ns / 1ps

module tcam_random_tb;

    parameter NUM_CONFIGS = 100;
    parameter LOOKUPS_PER_CONFIG = 100;

    logic clk = 0;
    logic rst;

    // Configuration interface
    logic write_en;
    logic [1:0] write_addr;
    logic [7:0] rule_in;
    logic [7:0] mask_in;
    logic valid_in;

    // Lookup interface
    logic lookup_valid;
    logic [7:0] data_in;

    // DUT outputs
    wire result_valid;
    wire [3:0] match_vector;
    wire match_found;
    wire [1:0] match_index;

    // Independent reference memory
    logic [7:0] ref_rules [0:3];
    logic [7:0] ref_masks [0:3];
    logic [3:0] ref_valid;

    // Expected pipeline results
    logic expected_valid;
    logic [3:0] expected_vector;
    logic expected_found;
    logic [1:0] expected_index;

    // Verification counters
    integer passed = 0;
    integer failed = 0;
    integer total_lookups = 0;

    integer hit_count = 0;
    integer miss_count = 0;
    integer multi_match_count = 0;

    integer rule0_wins = 0;
    integer rule1_wins = 0;
    integer rule2_wins = 0;
    integer rule3_wins = 0;

    integer config_num;
    integer lookup_num;
    integer i;

    logic [7:0] random_rule;
    logic [7:0] random_mask;
    logic random_valid;
    logic [7:0] random_data;

    integer seed = 12345;
    integer seed_init;

    // 100 MHz clock
    always #5 clk = ~clk;


    // Device Under Test
    tcam_registered #(
        .DATA_WIDTH(8),
        .NUM_RULES(4)
    ) dut (
        .clk(clk),
        .rst(rst),

        .write_en(write_en),
        .write_addr(write_addr),
        .rule_in(rule_in),
        .mask_in(mask_in),
        .valid_in(valid_in),

        .lookup_valid(lookup_valid),
        .data_in(data_in),

        .result_valid(result_valid),
        .match_vector(match_vector),
        .match_found(match_found),
        .match_index(match_index)
    );


    // Program DUT and reference memory
    task automatic program_rule(
        input logic [1:0] addr,
        input logic [7:0] new_rule,
        input logic [7:0] new_mask,
        input logic new_valid
    );

        @(negedge clk);

        write_en = 1;
        write_addr = addr;
        rule_in = new_rule;
        mask_in = new_mask;
        valid_in = new_valid;

        @(posedge clk);
        #1;

        write_en = 0;

        // Update independent reference memory
        ref_rules[addr] = new_rule;
        ref_masks[addr] = new_mask;
        ref_valid[addr] = new_valid;

    endtask


    // Independent reference model
    task automatic reference_lookup(
        input logic [7:0] test_data,
        output logic [3:0] ref_vector,
        output logic ref_found,
        output logic [1:0] ref_index
    );

        integer r;
        integer b;
        logic rule_matches;

        ref_vector = 0;
        ref_found = 0;
        ref_index = 0;

        // Check each rule independently
        for (r = 0; r < 4; r = r + 1) begin

            rule_matches = ref_valid[r];

            // Compare individual bits
            for (b = 0; b < 8; b = b + 1) begin

                if (ref_masks[r][b] == 1'b1) begin

                    if (test_data[b] != ref_rules[r][b])
                        rule_matches = 0;

                end

            end

            ref_vector[r] = rule_matches;

        end

        // Determine highest-priority match
        if (ref_vector[0]) begin
            ref_found = 1;
            ref_index = 0;
        end
        else if (ref_vector[1]) begin
            ref_found = 1;
            ref_index = 1;
        end
        else if (ref_vector[2]) begin
            ref_found = 1;
            ref_index = 2;
        end
        else if (ref_vector[3]) begin
            ref_found = 1;
            ref_index = 3;
        end

    endtask


    // Send a request and check previous result
    task automatic run_cycle(
        input logic request_valid,
        input logic [7:0] request_data
    );

        logic [3:0] next_vector;
        logic next_found;
        logic [1:0] next_index;

        @(negedge clk);

        lookup_valid = request_valid;
        data_in = request_data;

        // Calculate next expected result
        next_vector = 0;
        next_found = 0;
        next_index = 0;

        if (request_valid) begin

            reference_lookup(
                request_data,
                next_vector,
                next_found,
                next_index
            );

            total_lookups = total_lookups + 1;

        end

        @(posedge clk);
        #1;

        // Check result from previous request
        if ((result_valid === expected_valid) &&
            (match_vector === expected_vector) &&
            (match_found === expected_found) &&
            (match_index === expected_index)) begin

            passed = passed + 1;

        end
        else begin

            failed = failed + 1;

            $display(
                "FAIL at time %0t: Config=%0d",
                $time, config_num
            );

            $display(
                "Actual:   Valid=%b Vector=%h Found=%b Index=%d",
                result_valid, match_vector,
                match_found, match_index
            );

            $display(
                "Expected: Valid=%b Vector=%h Found=%b Index=%d",
                expected_valid, expected_vector,
                expected_found, expected_index
            );

        end

        // Collect functional coverage statistics
        if (expected_valid) begin

            if (expected_found) begin

                hit_count = hit_count + 1;

                case (expected_index)
                    0: rule0_wins = rule0_wins + 1;
                    1: rule1_wins = rule1_wins + 1;
                    2: rule2_wins = rule2_wins + 1;
                    3: rule3_wins = rule3_wins + 1;
                endcase

                if ($countones(expected_vector) > 1)
                    multi_match_count =
                        multi_match_count + 1;

            end
            else begin

                miss_count = miss_count + 1;

            end

        end

        // Store expected result for next cycle
        expected_valid = request_valid;
        expected_vector = next_vector;
        expected_found = next_found;
        expected_index = next_index;

    endtask


    initial begin

        // Initialize random generator
        seed_init = $urandom(seed);

        // Initialize signals
        rst = 1;
        write_en = 0;
        write_addr = 0;
        rule_in = 0;
        mask_in = 0;
        valid_in = 0;

        lookup_valid = 0;
        data_in = 0;

        expected_valid = 0;
        expected_vector = 0;
        expected_found = 0;
        expected_index = 0;

        ref_valid = 0;

        for (i = 0; i < 4; i = i + 1) begin
            ref_rules[i] = 0;
            ref_masks[i] = 0;
        end

        @(posedge clk);
        #1;

        @(negedge clk);
        rst = 0;


        // Main randomized verification loop
        for (config_num = 0;
             config_num < NUM_CONFIGS;
             config_num = config_num + 1) begin

            // Generate four randomized rules
            for (i = 0; i < 4; i = i + 1) begin

                random_rule = $urandom_range(255, 0);
                random_mask = $urandom_range(255, 0);
                random_valid = $urandom_range(1, 0);

                // Include wildcard configurations
                if ((config_num % 10) == 0)
                    random_mask = 8'h00;

                // Include exact-match configurations
                else if ((config_num % 10) == 1)
                    random_mask = 8'hFF;

                program_rule(
                    i[1:0],
                    random_rule,
                    random_mask,
                    random_valid
                );

            end


            // Perform randomized lookups
            for (lookup_num = 0;
                 lookup_num < LOOKUPS_PER_CONFIG;
                 lookup_num = lookup_num + 1) begin

                random_data = $urandom_range(255, 0);

                // Force potential matching cases
                if ((lookup_num % 10) == 0)
                    random_data =
                        ref_rules[lookup_num % 4];

                run_cycle(1, random_data);

                // Insert one idle cycle per config
                if (lookup_num == 49)
                    run_cycle(0, 8'h00);

            end

            // Drain pipeline
            run_cycle(0, 8'h00);
            run_cycle(0, 8'h00);

            // Progress report
            if (((config_num + 1) % 10) == 0) begin

                $display(
                    "Configurations completed: %0d/%0d",
                    config_num + 1,
                    NUM_CONFIGS
                );

            end

        end


        // Final verification report
        $display("================================");
        $display("TCAM RANDOMIZED VERIFICATION");
        $display("================================");

        $display("Configurations: %0d", NUM_CONFIGS);
        $display("Total lookups:  %0d", total_lookups);
        $display("Passed:         %0d", passed);
        $display("Failed:         %0d", failed);

        $display("--------------------------------");
        $display("Match hits:     %0d", hit_count);
        $display("Match misses:   %0d", miss_count);
        $display("Multi-matches:  %0d", multi_match_count);

        $display("--------------------------------");
        $display("Rule 0 wins:    %0d", rule0_wins);
        $display("Rule 1 wins:    %0d", rule1_wins);
        $display("Rule 2 wins:    %0d", rule2_wins);
        $display("Rule 3 wins:    %0d", rule3_wins);
        $display("================================");

        if (failed != 0)
            $fatal(1, "Randomized verification failed");

        if ((hit_count + miss_count) != total_lookups)
            $fatal(1, "Lookup count mismatch");

        if (passed != NUM_CONFIGS *
                      (LOOKUPS_PER_CONFIG + 3))
            $fatal(1, "Verification count mismatch");

        $display("ALL RANDOMIZED TESTS PASSED");

        $finish;

    end

endmodule

