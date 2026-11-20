
`timescale 1ns / 1ps

module tcam_array_tb;

    logic [7:0] data_in;

    logic [7:0] rules [0:3];
    logic [7:0] masks [0:3];

    logic [3:0] valid;

    wire [3:0] match_vector;

    integer passed = 0;
    integer failed = 0;

    // Device Under Test
    tcam_array #(
        .DATA_WIDTH(8),
        .NUM_RULES(4)
    ) dut (
        .data_in(data_in),
        .rules(rules),
        .masks(masks),
        .valid(valid),
        .match_vector(match_vector)
    );

    // Self-checking test task
    task automatic check_match(
        input logic [7:0] test_data,
        input logic [3:0] expected,
        input string test_name
    );

        data_in = test_data;

        #10;

        if (match_vector === expected) begin

            passed = passed + 1;

            $display(
                "PASS: %s Data=%h Match=%b",
                test_name, data_in, match_vector
            );

        end
        else begin

            failed = failed + 1;

            $display(
                "FAIL: %s Data=%h Expected=%b Actual=%b",
                test_name, data_in,
                expected, match_vector
            );

        end

    endtask

    initial begin

        data_in = 0;

        // Configure rule 0: Exact match
        rules[0] = 8'hAA;
        masks[0] = 8'hFF;

        // Configure rule 1: Upper nibble
        rules[1] = 8'hA0;
        masks[1] = 8'hF0;

        // Configure rule 2: Upper two bits
        rules[2] = 8'hC0;
        masks[2] = 8'hC0;

        // Configure rule 3: Exact match
        rules[3] = 8'h55;
        masks[3] = 8'hFF;

        // Enable all rules
        valid = 4'b1111;

        // Test 1: Multiple matches
        check_match(8'hAA, 4'b0011,
                    "Multiple matches");

        // Test 2: Masked match
        check_match(8'hAB, 4'b0010,
                    "Masked match");

        // Test 3: Rule 2 match
        check_match(8'hC5, 4'b0100,
                    "Rule 2 match");

        // Test 4: Rule 3 match
        check_match(8'h55, 4'b1000,
                    "Rule 3 match");

        // Test 5: No matches
        check_match(8'h00, 4'b0000,
                    "No matches");

        // Test 6: Disable rule 0
        valid = 4'b1110;

        check_match(8'hAA, 4'b0010,
                    "Disabled rule 0");

        // Test 7: Disable all rules
        valid = 4'b0000;

        check_match(8'hAA, 4'b0000,
                    "All rules disabled");

        // Test 8: Wildcard rule
        masks[3] = 8'h00;
        valid = 4'b1000;

        check_match(8'h12, 4'b1000,
                    "Wildcard match");

        // Test 9: All four rules match
        masks[0] = 8'h00;
        masks[1] = 8'h00;
        masks[2] = 8'h00;
        masks[3] = 8'h00;

        valid = 4'b1111;

        check_match(8'hFF, 4'b1111,
                    "All rules match");

        // Test 10: Disabled wildcard rules
        valid = 4'b0101;

        check_match(8'hFF, 4'b0101,
                    "Selective valid bits");

        $display("------------------------");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("------------------------");

        if (failed != 0)
            $fatal(1, "TCAM array verification failed");

        $finish;

    end

endmodule
