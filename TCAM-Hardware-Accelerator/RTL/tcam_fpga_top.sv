
module tcam_fpga_top #(
    parameter CLK_FREQ = 100_000_000,
    parameter DEBOUNCE_MS = 10
)(
    input logic clk,

    input logic [15:0] sw,

    input logic btnU,
    input logic btnD,
    input logic btnR,
    input logic btnL,
    input logic btnC,

    output logic [15:0] led
);

    // Reset synchronizer
    (* ASYNC_REG = "TRUE" *)
    logic [1:0] reset_sync = 2'b11;

    logic rst;

    always_ff @(posedge clk) begin
        reset_sync <= {reset_sync[0], btnC};
    end

    assign rst = reset_sync[1];


    // Switch synchronizer
    (* ASYNC_REG = "TRUE" *)
    logic [10:0] sw_sync1;
    (* ASYNC_REG = "TRUE" *)
    logic [10:0] sw_sync2;

    always_ff @(posedge clk) begin
        if (rst) begin
            sw_sync1 <= '0;
            sw_sync2 <= '0;
        end
        else begin
            sw_sync1 <= sw[10:0];
            sw_sync2 <= sw_sync1;
        end
    end


    // Debounced button pulses
    logic capture_rule;
    logic capture_mask;
    logic write_rule;
    logic perform_lookup;


    // UP button: capture rule
    button_debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) debounce_up (
        .clk(clk),
        .rst(rst),
        .button_in(btnU),
        .button_clean(),
        .button_pulse(capture_rule)
    );


    // DOWN button: capture mask
    button_debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) debounce_down (
        .clk(clk),
        .rst(rst),
        .button_in(btnD),
        .button_clean(),
        .button_pulse(capture_mask)
    );


    // RIGHT button: write rule
    button_debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) debounce_right (
        .clk(clk),
        .rst(rst),
        .button_in(btnR),
        .button_clean(),
        .button_pulse(write_rule)
    );


    // LEFT button: perform lookup
    button_debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) debounce_left (
        .clk(clk),
        .rst(rst),
        .button_in(btnL),
        .button_clean(),
        .button_pulse(perform_lookup)
    );


    // Captured rule and mask registers
    logic [7:0] captured_rule;
    logic [7:0] captured_mask;

    always_ff @(posedge clk) begin
        if (rst) begin
            captured_rule <= '0;
            captured_mask <= '0;
        end
        else begin
            if (capture_rule)
                captured_rule <= sw_sync2[7:0];

            if (capture_mask)
                captured_mask <= sw_sync2[7:0];
        end
    end


    // TCAM result signals
    logic result_valid;
    logic [3:0] match_vector;
    logic match_found;
    logic [1:0] match_index;


    // Registered TCAM accelerator
    tcam_registered tcam_inst (
        .clk(clk),
        .rst(rst),

        .write_en(write_rule),
        .write_addr(sw_sync2[9:8]),
        .rule_in(captured_rule),
        .mask_in(captured_mask),
        .valid_in(sw_sync2[10]),

        .lookup_valid(perform_lookup),
        .data_in(sw_sync2[7:0]),

        .result_valid(result_valid),
        .match_vector(match_vector),
        .match_found(match_found),
        .match_index(match_index)
    );


    // Result holding registers
    logic [3:0] held_match_vector;
    logic held_match_found;
    logic [1:0] held_match_index;
    logic lookup_completed;

    always_ff @(posedge clk) begin
        if (rst) begin
            held_match_vector <= '0;
            held_match_found <= 1'b0;
            held_match_index <= '0;
            lookup_completed <= 1'b0;
        end
        else begin

            // Clear completion when starting a lookup
            if (perform_lookup)
                lookup_completed <= 1'b0;

            // Store completed TCAM result
            if (result_valid) begin
                held_match_vector <= match_vector;
                held_match_found <= match_found;
                held_match_index <= match_index;
                lookup_completed <= 1'b1;
            end

        end
    end


    // Physical LED assignments
    assign led[3:0]  = held_match_vector;
    assign led[4]    = held_match_found;
    assign led[6:5]  = held_match_index;
    assign led[7]    = lookup_completed;
    assign led[15:8] = captured_rule;

endmodule
