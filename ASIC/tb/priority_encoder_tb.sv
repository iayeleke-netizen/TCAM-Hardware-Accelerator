
`timescale 1ns / 1ps

module priority_encoder_tb;

    logic [3:0] match_vector;

    wire match_found;
    wire [1:0] match_index;

    integer passed = 0;
    integer failed = 0;

    // Device Under Test
    priority_encoder #(
        .NUM_RULES(4)
    ) dut (
        .match_vector(match_vector),
        .match_found(match_found),
        .match_index(match_index)
    );

    // Self-checking test task
    task automatic check_priority(
        input logic [3:0] test_vector,
        input logic expected_found,
        input logic [1:0] expected_index
    );

        match_vector = test_vector;

        #10;

        if ((match_found === expected_found) &&
            (match_index === expected_index)) begin

            passed = passed + 1;

            $display(
                "PASS: Vector=%b Found=%b Index=%d",
                match_vector,
                match_found,
                match_index
            );

        end
        else begin

            failed = failed + 1;

            $display(
                "FAIL: Vector=%b Found=%b Index=%d Expected Found=%b Index=%d",
                match_vector,
                match_found,
                match_index,
                expected_found,
                expected_index
            );

        end

    endtask

    initial begin

        // Exhaustive verification

        check_priority(4'b0000, 0, 2'd0);
        check_priority(4'b0001, 1, 2'd0);
        check_priority(4'b0010, 1, 2'd1);
        check_priority(4'b0011, 1, 2'd0);

        check_priority(4'b0100, 1, 2'd2);
        check_priority(4'b0101, 1, 2'd0);
        check_priority(4'b0110, 1, 2'd1);
        check_priority(4'b0111, 1, 2'd0);

        check_priority(4'b1000, 1, 2'd3);
        check_priority(4'b1001, 1, 2'd0);
        check_priority(4'b1010, 1, 2'd1);
        check_priority(4'b1011, 1, 2'd0);

        check_priority(4'b1100, 1, 2'd2);
        check_priority(4'b1101, 1, 2'd0);
        check_priority(4'b1110, 1, 2'd1);
        check_priority(4'b1111, 1, 2'd0);

        $display("------------------------");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("------------------------");

        if (failed != 0)
            $fatal(1, "Priority encoder verification failed");

        $finish;

    end

endmodule
