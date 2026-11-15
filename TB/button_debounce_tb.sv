
`timescale 1ns / 1ps

module button_debounce_tb;

    logic clk = 0;
    logic rst;
    logic button_in;

    wire button_clean;
    wire button_pulse;

    integer passed = 0;
    integer failed = 0;
    integer pulse_count = 0;

    // 100 MHz simulation clock
    always #5 clk = ~clk;


    // Device Under Test
    button_debounce #(
        .CLK_FREQ(1000),
        .DEBOUNCE_MS(4)
    ) dut (
        .clk(clk),
        .rst(rst),
        .button_in(button_in),
        .button_clean(button_clean),
        .button_pulse(button_pulse)
    );


    // Count generated pulses
    always @(posedge clk) begin
        #1;

        if (button_pulse)
            pulse_count = pulse_count + 1;
    end


    // Wait for a specified number of cycles
    task automatic wait_cycles(
        input integer cycles
    );

        repeat (cycles) @(posedge clk);
        #2;

    endtask


    // Verify expected outputs
    task automatic check_result(
        input logic expected_clean,
        input integer expected_pulses,
        input string test_name
    );

        if ((button_clean === expected_clean) &&
            (pulse_count == expected_pulses)) begin

            passed = passed + 1;

            $display("PASS: %s", test_name);

        end
        else begin

            failed = failed + 1;

            $display("FAIL: %s", test_name);

            $display(
                "Clean=%b Pulses=%0d",
                button_clean, pulse_count
            );

            $display(
                "Expected Clean=%b Pulses=%0d",
                expected_clean, expected_pulses
            );

        end

    endtask


    initial begin

        rst = 1;
        button_in = 0;

        wait_cycles(3);

        // Test 1: Initial reset
        check_result(0, 0, "Initial reset");

        @(negedge clk);
        rst = 0;


        // Test 2: Short button bounce
        @(negedge clk);
        button_in = 1;

        wait_cycles(1);

        @(negedge clk);
        button_in = 0;

        wait_cycles(8);

        check_result(0, 0, "Short bounce ignored");


        // Test 3: Stable button press
        @(negedge clk);
        button_in = 1;

        wait_cycles(8);

        check_result(1, 1, "Stable button press");


        // Test 4: Held button
        wait_cycles(20);

        check_result(1, 1, "Held button");


        // Test 5: Button release
        @(negedge clk);
        button_in = 0;

        wait_cycles(8);

        check_result(0, 1, "Button release");


        // Test 6: Second button press
        @(negedge clk);
        button_in = 1;

        wait_cycles(8);

        check_result(1, 2, "Second button press");


        // Test 7: Reset while pressed
        @(negedge clk);
        rst = 1;

        wait_cycles(3);

        check_result(0, 2, "Reset while pressed");


        // Final results
        $display("==========================");
        $display("BUTTON DEBOUNCE VERIFICATION");
        $display("==========================");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("Button pulses: %0d", pulse_count);
        $display("==========================");

        if (failed != 0)
            $fatal(1, "Debounce verification failed");

        $finish;

    end

endmodule
