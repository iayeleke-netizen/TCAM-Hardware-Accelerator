
`timescale 1ns / 1ps

module tcam_fpga_top_tb;

    logic clk = 0;

    logic [15:0] sw = 0;

    logic btnU = 0;
    logic btnD = 0;
    logic btnR = 0;
    logic btnL = 0;
    logic btnC = 0;

    wire [15:0] led;

    integer passed = 0;
    integer failed = 0;


    // 100 MHz clock
    always #5 clk = ~clk;


    // Device Under Test
    tcam_fpga_top #(
        .CLK_FREQ(1000),
        .DEBOUNCE_MS(4)
    ) dut (
        .clk(clk),
        .sw(sw),
        .btnU(btnU),
        .btnD(btnD),
        .btnR(btnR),
        .btnL(btnL),
        .btnC(btnC),
        .led(led)
    );


    // Wait for clock cycles
    task automatic wait_cycles(
        input integer cycles
    );
        repeat (cycles) @(posedge clk);
        #2;
    endtask


    // Set physical switches
    task automatic set_switches(
        input logic [15:0] value
    );
        @(negedge clk);
        sw = value;

        wait_cycles(5);
    endtask


    // Simulate a physical button press
    // 0 = UP
    // 1 = DOWN
    // 2 = RIGHT
    // 3 = LEFT
    // 4 = CENTER

    task automatic press_button(
        input integer button
    );

        @(negedge clk);

        case (button)
            0: btnU = 1;
            1: btnD = 1;
            2: btnR = 1;
            3: btnL = 1;
            4: btnC = 1;
        endcase

        wait_cycles(12);

        @(negedge clk);

        case (button)
            0: btnU = 0;
            1: btnD = 0;
            2: btnR = 0;
            3: btnL = 0;
            4: btnC = 0;
        endcase

        wait_cycles(12);

    endtask


    // Check complete LED output
    task automatic check_led(
        input logic [15:0] expected,
        input string test_name
    );

        if (led === expected) begin

            passed = passed + 1;

            $display(
                "PASS: %s | LED=%h",
                test_name, led
            );

        end
        else begin

            failed = failed + 1;

            $display(
                "FAIL: %s | LED=%h Expected=%h",
                test_name, led, expected
            );

        end

    endtask


    // Program a complete TCAM rule
    task automatic program_rule(
        input logic [1:0] address,
        input logic [7:0] rule_value,
        input logic [7:0] mask_value,
        input logic valid_value
    );

        // Capture rule
        set_switches({8'b0, rule_value});
        press_button(0);

        // Capture mask
        set_switches({8'b0, mask_value});
        press_button(1);

        // Select address and valid bit
        set_switches({
            5'b0,
            valid_value,
            address,
            8'b0
        });

        // Write rule
        press_button(2);

    endtask


    // Perform lookup
    task automatic lookup(
        input logic [7:0] lookup_data
    );

        set_switches({8'b0, lookup_data});

        press_button(3);

    endtask


    initial begin

        // Test 1: System reset
        press_button(4);

        check_led(
            16'h0000,
            "Initial system reset"
        );


        // Test 2: Capture rule AA
        set_switches(16'h00AA);
        press_button(0);

        check_led(
            16'hAA00,
            "Rule capture"
        );


        // Test 3: Capture mask FF
        set_switches(16'h00FF);
        press_button(1);

        if (dut.captured_mask === 8'hFF) begin
            passed = passed + 1;
            $display("PASS: Mask capture");
        end
        else begin
            failed = failed + 1;
            $display("FAIL: Mask capture");
        end


        // Program rule 0
        // Rule AA, mask FF, valid = 1

        set_switches(16'h0400);
        press_button(2);


        // Test 4: Exact match
        lookup(8'hAA);

        check_led(
            16'hAA91,
            "Exact match rule 0"
        );


        // Test 5: No match
        lookup(8'hAB);

        check_led(
            16'hAA80,
            "No match"
        );


        // Program rule 1
        // Rule A0, mask F0

        program_rule(
            2'd1,
            8'hA0,
            8'hF0,
            1'b1
        );


        // Test 6: Masked match
        lookup(8'hAB);

        check_led(
            16'hA0B2,
            "Masked match rule 1"
        );


        // Test 7: Multiple matches
        lookup(8'hAA);

        check_led(
            16'hA093,
            "Multiple matches rule 0 wins"
        );


        // Program rule 2
        // Rule C0, mask C0

        program_rule(
            2'd2,
            8'hC0,
            8'hC0,
            1'b1
        );


        // Test 8: Rule 2 match
        lookup(8'hC5);

        check_led(
            16'hC0D4,
            "Rule 2 match"
        );


        // Program rule 3
        // Rule 55, mask FF

        program_rule(
            2'd3,
            8'h55,
            8'hFF,
            1'b1
        );


        // Test 9: Rule 3 match
        lookup(8'h55);

        check_led(
            16'h55F8,
            "Rule 3 match"
        );


        // Test 10: Result holding
        wait_cycles(30);

        check_led(
            16'h55F8,
            "Result remains visible"
        );


        // Disable rule 0
        program_rule(
            2'd0,
            8'hAA,
            8'hFF,
            1'b0
        );


        // Test 11: Rule invalidation
        lookup(8'hAA);

        check_led(
            16'hAAB2,
            "Disabled rule 0 ignored"
        );


        // Test 12: Final reset
        press_button(4);

        check_led(
            16'h0000,
            "Final system reset"
        );


        // Test 13: Lookup after reset
        lookup(8'hAA);

        check_led(
            16'h0080,
            "No valid rules after reset"
        );


        // Final verification report
        $display("");
        $display("==============================");
        $display("BASYS 3 WRAPPER VERIFICATION");
        $display("==============================");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("Total:  %0d", passed + failed);
        $display("==============================");

        if (failed != 0)
            $fatal(1, "Wrapper verification failed");

        $finish;

    end

endmodule
