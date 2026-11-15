
module button_debounce #(
    parameter CLK_FREQ = 100_000_000,
    parameter DEBOUNCE_MS = 10
)(
    input logic clk,
    input logic rst,
    input logic button_in,

    output logic button_clean,
    output logic button_pulse
);

    localparam COUNT_MAX =
        (CLK_FREQ / 1000) * DEBOUNCE_MS;

    localparam COUNTER_WIDTH =
        (COUNT_MAX > 1) ? $clog2(COUNT_MAX) : 1;

    // Two-stage synchronizer
    (* ASYNC_REG = "TRUE" *)
    logic sync_1, sync_2;

    // Debounce counter
    logic [COUNTER_WIDTH-1:0] counter;


    // Synchronize asynchronous button input
    always_ff @(posedge clk) begin

        if (rst) begin
            sync_1 <= 1'b0;
            sync_2 <= 1'b0;
        end
        else begin
            sync_1 <= button_in;
            sync_2 <= sync_1;
        end

    end


    // Debounce and rising-edge pulse generation
    always_ff @(posedge clk) begin

        if (rst) begin

            counter <= '0;
            button_clean <= 1'b0;
            button_pulse <= 1'b0;

        end
        else begin

            // Default: no button event
            button_pulse <= 1'b0;

            if (sync_2 == button_clean) begin

                counter <= '0;

            end
            else begin

                if (counter == COUNT_MAX - 1) begin

                    button_clean <= sync_2;
                    counter <= '0;

                    // Generate one pulse on press
                    if (sync_2 == 1'b1)
                        button_pulse <= 1'b1;

                end
                else begin

                    counter <= counter + 1'b1;

                end

            end

        end

    end

endmodule
