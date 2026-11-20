
`timescale 1ns / 1ps

module tcam_rule_memory_tb;

    logic clk = 0;
    logic rst;

    logic write_en;
    logic [1:0] write_addr;
    logic [7:0] rule_in;
    logic [7:0] mask_in;
    logic valid_in;

    wire [7:0] rules [0:3];
    wire [7:0] masks [0:3];
    wire [3:0] valid;

    integer passed = 0;
    integer failed = 0;

    // 100 MHz clock
    always #5 clk = ~clk;

    // Device Under Test
    tcam_rule_memory #(
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
        .rules(rules),
        .masks(masks),
        .valid(valid)
    );

    // Write a memory entry
    task automatic write_entry(
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

    // Verify a memory entry
    task automatic check_entry(
        input logic [1:0] addr,
        input logic [7:0] expected_rule,
        input logic [7:0] expected_mask,
        input logic expected_valid
    );

        if ((rules[addr] === expected_rule) &&
            (masks[addr] === expected_mask) &&
            (valid[addr] === expected_valid)) begin

            passed = passed + 1;

            $display("PASS: Entry %0d Rule=%h Mask=%h Valid=%b",
                     addr, rules[addr],
                     masks[addr], valid[addr]);

        end
        else begin

            failed = failed + 1;

            $display("FAIL: Entry %0d Rule=%h Mask=%h Valid=%b",
                     addr, rules[addr],
                     masks[addr], valid[addr]);

        end

    endtask

    initial begin

        rst = 1;
        write_en = 0;
        write_addr = 0;
        rule_in = 0;
        mask_in = 0;
        valid_in = 0;

        // Test initial reset
        @(posedge clk);
        #1;

        check_entry(0, 8'h00, 8'h00, 0);
        check_entry(1, 8'h00, 8'h00, 0);
        check_entry(2, 8'h00, 8'h00, 0);
        check_entry(3, 8'h00, 8'h00, 0);

        @(negedge clk);
        rst = 0;

        // Program rule 0
        write_entry(0, 8'hAA, 8'hFF, 1);
        check_entry(0, 8'hAA, 8'hFF, 1);

        // Program rule 1
        write_entry(1, 8'hB0, 8'hF0, 1);
        check_entry(1, 8'hB0, 8'hF0, 1);

        // Program rule 2
        write_entry(2, 8'hC0, 8'hC0, 1);
        check_entry(2, 8'hC0, 8'hC0, 1);

        // Program rule 3
        write_entry(3, 8'h55, 8'hFF, 1);
        check_entry(3, 8'h55, 8'hFF, 1);

        // Overwrite rule 1
        write_entry(1, 8'hD5, 8'hF0, 1);
        check_entry(1, 8'hD5, 8'hF0, 1);

        // Disable rule 2
        write_entry(2, 8'hC0, 8'hC0, 0);
        check_entry(2, 8'hC0, 8'hC0, 0);

        // Verify other entries were unchanged
        check_entry(0, 8'hAA, 8'hFF, 1);
        check_entry(3, 8'h55, 8'hFF, 1);

        // Test write protection
        @(negedge clk);

        write_en = 0;
        write_addr = 0;
        rule_in = 8'hFF;
        mask_in = 8'h00;
        valid_in = 0;

        @(posedge clk);
        #1;

        check_entry(0, 8'hAA, 8'hFF, 1);

        // Test reset again
        @(negedge clk);
        rst = 1;

        @(posedge clk);
        #1;

        check_entry(0, 8'h00, 8'h00, 0);
        check_entry(1, 8'h00, 8'h00, 0);
        check_entry(2, 8'h00, 8'h00, 0);
        check_entry(3, 8'h00, 8'h00, 0);

        $display("------------------------");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);
        $display("------------------------");

        if (failed != 0)
            $fatal(1, "Memory verification failed");

        $finish;

    end

endmodule
