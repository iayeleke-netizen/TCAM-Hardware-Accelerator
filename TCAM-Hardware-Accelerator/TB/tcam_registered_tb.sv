
`timescale 1ns / 1ps

module tcam_registered_tb;

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

    // Registered outputs
    wire result_valid;
    wire [3:0] match_vector;
    wire match_found;
    wire [1:0] match_index;

    integer passed = 0;
    integer failed = 0;

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


    // Program rule memory
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

    endtask


    // Verify registered outputs
    task automatic check_result(
        input logic expected_valid,
        input logic [3:0] expected_vector,
        input logic expected_found,
        input logic [1:0] expected_index,
        input string test_name
    );

        if ((result_valid === expected_valid) &&
            (match_vector === expected_vector) &&
            (match_found === expected_found) &&
            (match_index === expected_index)) begin

            passed = passed + 1;

            $display(
                "PASS: %s Valid=%b Vector=%h Found=%b Index=%d",
                test_name, result_valid,
                match_vector, match_found,
                match_index
            );

        end
        else begin

            failed = failed + 1;

            $display(
                "FAIL: %s Valid=%b Vector=%h Found=%b Index=%d",
                test_name, result_valid,
                match_vector, match_found,
                match_index
            );

            $display(
                "Expected Valid=%b Vector=%h Found=%b Index=%d",
                expected_valid, expected_vector,
                expected_found, expected_index
            );

        end

    endtask


    // Send input and verify output for one cycle
    task automatic run_cycle(
        input logic request_valid,
        input logic [7:0] request_data,
        input logic expected_valid,
        input logic [3:0] expected_vector,
        input logic expected_found,
        input logic [1:0] expected_index,
        input string test_name
    );

        @(negedge clk);

        lookup_valid = request_valid;
        data_in = request_data;

        @(posedge clk);
        #1;

        check_result(
            expected_valid,
            expected_vector,
            expected_found,
            expected_index,
            test_name
        );

    endtask


    initial begin

        // Initialize inputs
        rst = 1;
        write_en = 0;
        write_addr = 0;
        rule_in = 0;
        mask_in = 0;
        valid_in = 0;

        lookup_valid = 0;
        data_in = 0;

        @(posedge clk);
        #1;

        // Test 1: Initial reset
        check_result(
            0, 4'h0, 0, 2'd0,
            "Initial reset"
        );

        @(negedge clk);
        rst = 0;


        // Program all four rules
        program_rule(0, 8'hAA, 8'hFF, 1);
        program_rule(1, 8'hA0, 8'hF0, 1);
        program_rule(2, 8'hC0, 8'hC0, 1);
        program_rule(3, 8'h55, 8'hFF, 1);


        // Test 2: First request enters pipeline
        run_cycle(
            1, 8'hAA,
            0, 4'h0, 0, 2'd0,
            "Pipeline fill"
        );

        // Test 3: AA result, AB request
        run_cycle(
            1, 8'hAB,
            1, 4'h3, 1, 2'd0,
            "AA result"
        );

        // Test 4: AB result, C5 request
        run_cycle(
            1, 8'hC5,
            1, 4'h2, 1, 2'd1,
            "AB result"
        );

        // Test 5: C5 result, 55 request
        run_cycle(
            1, 8'h55,
            1, 4'h4, 1, 2'd2,
            "C5 result"
        );

        // Test 6: 55 result, 00 request
        run_cycle(
            1, 8'h00,
            1, 4'h8, 1, 2'd3,
            "55 result"
        );

        // Test 7: Valid lookup with no match
        run_cycle(
            0, 8'hFF,
            1, 4'h0, 0, 2'd0,
            "No-match result"
        );

        // Test 8: Pipeline idle
        run_cycle(
            0, 8'hAA,
            0, 4'h0, 0, 2'd0,
            "Idle cycle"
        );

        // Test 9: Restart pipeline
        run_cycle(
            1, 8'hFF,
            0, 4'h0, 0, 2'd0,
            "Restart pipeline"
        );

        // Test 10: FF result
        run_cycle(
            0, 8'h00,
            1, 4'h4, 1, 2'd2,
            "FF result"
        );

        // Test 11: Pipeline drained
        run_cycle(
            0, 8'h00,
            0, 4'h0, 0, 2'd0,
            "Pipeline drained"
        );

        // Test 12: Pending request
        run_cycle(
            1, 8'hAA,
            0, 4'h0, 0, 2'd0,
            "Pending request before reset"
        );


        // Reset with a pending lookup
        @(negedge clk);

        rst = 1;
        lookup_valid = 0;

        @(posedge clk);
        #1;

        // Test 13: Reset clears pending result
        check_result(
            0, 4'h0, 0, 2'd0,
            "Pipeline reset"
        );

        @(negedge clk);
        rst = 0;


        // Test 14: Request after reset
        run_cycle(
            1, 8'hAA,
            0, 4'h0, 0, 2'd0,
            "Post-reset request"
        );

        // Test 15: Memory was cleared by reset
        run_cycle(
            0, 8'h00,
            1, 4'h0, 0, 2'd0,
            "Post-reset empty memory"
        );


        // Reprogram rule 0
        program_rule(0, 8'hAA, 8'hFF, 1);

        // Test 16: New request
        run_cycle(
            1, 8'hAA,
            0, 4'h0, 0, 2'd0,
            "Reprogrammed request"
        );

        // Test 17: Successful recovery
        run_cycle(
            0, 8'h00,
            1, 4'h1, 1, 2'd0,
            "Recovery after reset"
        );

        // Test 18: Final idle cycle
        run_cycle(
            0, 8'h00,
            0, 4'h0, 0, 2'd0,
            "Final idle cycle"
        );


        // Final results
        $display("------------------------");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("------------------------");

        if (failed != 0)
            $fatal(1, "Registered TCAM verification failed");

        $finish;

    end

endmodule
