
`timescale 1ns / 1ps

module tcam_comparator_tb;

    logic [7:0] data_in;
    logic [7:0] rule;
    logic [7:0] mask;
    logic match;

    integer passed = 0;
    integer failed = 0;

    // Device Under Test
    tcam_comparator #(
        .DATA_WIDTH(8)
    ) dut (
        .data_in(data_in),
        .rule(rule),
        .mask(mask),
        .match(match)
    );

    // Self-checking test task
    task automatic check_match(
        input logic [7:0] test_data,
        input logic [7:0] test_rule,
        input logic [7:0] test_mask,
        input logic expected
    );

        data_in = test_data;
        rule = test_rule;
        mask = test_mask;

        #10;

        if (match === expected) begin
            passed = passed + 1;
            $display("PASS: Data=%b Rule=%b Mask=%b Match=%b",
                     data_in, rule, mask, match);
        end
        else begin
            failed = failed + 1;
            $display("FAIL: Expected=%b Actual=%b",
                     expected, match);
        end

    endtask

    initial begin

        // Test 1: Exact match
        check_match(8'b10101010,
                    8'b10101010,
                    8'b11111111, 1'b1);

        // Test 2: Exact mismatch
        check_match(8'b10101011,
                    8'b10101010,
                    8'b11111111, 1'b0);

        // Test 3: Ignore differing bit
        check_match(8'b10101011,
                    8'b10101010,
                    8'b11111110, 1'b1);

        // Test 4: Ignore all bits
        check_match(8'b11111111,
                    8'b00000000,
                    8'b00000000, 1'b1);

        // Test 5: Multiple ignored bits
        check_match(8'b10111111,
                    8'b10100000,
                    8'b11100000, 1'b1);

        // Test 6: Required bit mismatch
        check_match(8'b10011111,
                    8'b10100000,
                    8'b11100000, 1'b0);

        // Test 7: All zeros
        check_match(8'b00000000,
                    8'b00000000,
                    8'b11111111, 1'b1);

        // Test 8: Complete mismatch
        check_match(8'b11111111,
                    8'b00000000,
                    8'b11111111, 1'b0);

        $display("------------------------");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("------------------------");

        if (failed != 0)
            $fatal(1, "TCAM verification failed");

        $finish;

    end

endmodule

