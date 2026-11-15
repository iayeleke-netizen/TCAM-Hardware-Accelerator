
`timescale 1ns / 1ps

module tcam_core_tb;

    logic clk = 0;
    logic rst;

    // Configuration inputs
    logic write_en;
    logic [1:0] write_addr;
    logic [7:0] rule_in;
    logic [7:0] mask_in;
    logic valid_in;

    // Lookup input
    logic [7:0] data_in;

    // Lookup outputs
    wire [3:0] match_vector;
    wire match_found;
    wire [1:0] match_index;

    integer passed = 0;
    integer failed = 0;

    // 100 MHz clock
    always #5 clk = ~clk;

    // Device Under Test
    tcam_core #(
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

        .data_in(data_in),

        .match_vector(match_vector),
        .match_found(match_found),
        .match_index(match_index)
    );


    // Program a rule into memory
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


    // Perform and verify a lookup
    task automatic check_lookup(
        input logic [7:0] test_data,
        input logic [3:0] expected_vector,
        input logic expected_found,
        input logic [1:0] expected_index,
        input string test_name
    );

        data_in = test_data;

        #10;

        if ((match_vector === expected_vector) &&
            (match_found === expected_found) &&
            (match_index === expected_index)) begin

            passed = passed + 1;

            $display(
                "PASS: %s Data=%h Vector=%b Found=%b Index=%d",
                test_name,
                data_in,
                match_vector,
                match_found,
                match_index
            );

        end
        else begin

            failed = failed + 1;

            $display(
                "FAIL: %s Data=%h Vector=%b Found=%b Index=%d",
                test_name,
                data_in,
                match_vector,
                match_found,
                match_index
            );

            $display(
                "Expected Vector=%b Found=%b Index=%d",
                expected_vector,
                expected_found,
                expected_index
            );

        end

    endtask


    initial begin

        // Initialize inputs
        rst = 1;
        write_en = 0;
        write_addr = 0;
        rule_in = 0;
        mask_in = 0;
        valid_in = 0;
        data_in = 0;

        @(posedge clk);
        #1;

        @(negedge clk);
        rst = 0;


        // Test 1: Empty memory
        check_lookup(
            8'hAA, 4'b0000, 0, 2'd0,
            "Empty memory"
        );


        // Program all four rules
        program_rule(0, 8'hAA, 8'hFF, 1);
        program_rule(1, 8'hA0, 8'hF0, 1);
        program_rule(2, 8'hC0, 8'hC0, 1);
        program_rule(3, 8'h55, 8'hFF, 1);


        // Test 2: Multiple matches
        check_lookup(
            8'hAA, 4'b0011, 1, 2'd0,
            "Multiple matches"
        );

        // Test 3: Masked match
        check_lookup(
            8'hAB, 4'b0010, 1, 2'd1,
            "Masked match"
        );

        // Test 4: Rule 2
        check_lookup(
            8'hC5, 4'b0100, 1, 2'd2,
            "Rule 2 match"
        );

        // Test 5: Rule 3
        check_lookup(
            8'h55, 4'b1000, 1, 2'd3,
            "Rule 3 match"
        );

        // Test 6: No match
        check_lookup(
            8'h00, 4'b0000, 0, 2'd0,
            "No match"
        );


        // Disable rule 0
        program_rule(0, 8'hAA, 8'hFF, 0);

        // Test 7: Priority changes
        check_lookup(
            8'hAA, 4'b0010, 1, 2'd1,
            "Rule 0 disabled"
        );


        // Overwrite rule 1
        program_rule(1, 8'hB0, 8'hF0, 1);

        // Test 8: Old rule no longer matches
        check_lookup(
            8'hAA, 4'b0000, 0, 2'd0,
            "Old rule removed"
        );

        // Test 9: New rule matches
        check_lookup(
            8'hB5, 4'b0010, 1, 2'd1,
            "New rule matches"
        );


        // Program rule 3 as a wildcard
        program_rule(3, 8'h00, 8'h00, 1);

        // Test 10: Wildcard match
        check_lookup(
            8'h12, 4'b1000, 1, 2'd3,
            "Wildcard match"
        );

        // Test 11: Wildcard loses priority
        check_lookup(
            8'hB5, 4'b1010, 1, 2'd1,
            "Wildcard priority"
        );


        // Program all rules as wildcards
        program_rule(0, 8'h00, 8'h00, 1);
        program_rule(1, 8'h00, 8'h00, 1);
        program_rule(2, 8'h00, 8'h00, 1);
        program_rule(3, 8'h00, 8'h00, 1);

        // Test 12: All rules match
        check_lookup(
            8'hFF, 4'b1111, 1, 2'd0,
            "All rules match"
        );


        // Disable rules 0 and 1
        program_rule(0, 8'h00, 8'h00, 0);
        program_rule(1, 8'h00, 8'h00, 0);

        // Test 13: Rule 2 wins
        check_lookup(
            8'hFF, 4'b1100, 1, 2'd2,
            "Selective priority"
        );


        // Reset complete system
        @(negedge clk);
        rst = 1;

        @(posedge clk);
        #1;

        @(negedge clk);
        rst = 0;

        // Test 14: Verify reset
        check_lookup(
            8'hFF, 4'b0000, 0, 2'd0,
            "System reset"
        );


        // Final results
        $display("------------------------");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("------------------------");

        if (failed != 0)
            $fatal(1, "TCAM core verification failed");

        $finish;

    end

endmodule
