# TCAM Hardware Accelerator
# SKY130 ASIC Timing Constraints

# 1. Primary clock
create_clock -name clk -period 10.000 [get_ports clk]

set clocks [get_clocks clk]

# 2. Synchronous input interface
set data_inputs [get_ports {
    rst
    write_en
    write_addr*
    rule_in*
    mask_in*
    valid_in
    lookup_valid
    data_in*
}]

# 3. Registered output interface
set data_outputs [get_ports {
    result_valid
    match_vector*
    match_found
    match_index*
}]

# 4. Input and output timing budgets
set_input_delay -clock $clocks -max 2.000 $data_inputs
set_input_delay -clock $clocks -min 2.000 $data_inputs

set_output_delay -clock $clocks -max 2.000 $data_outputs
set_output_delay -clock $clocks -min 2.000 $data_outputs

# 5. Clock uncertainty and transition
set_clock_uncertainty 0.250 $clocks
set_clock_transition 0.150 $clocks

# 6. External driving cells
set data_driver [split $::env(SYNTH_DRIVING_CELL) "/"]

set_driving_cell \
    -lib_cell [lindex $data_driver 0] \
    -pin [lindex $data_driver 1] \
    $data_inputs

if {[info exists ::env(SYNTH_CLK_DRIVING_CELL)]} {
    set clock_driver [split $::env(SYNTH_CLK_DRIVING_CELL) "/"]
} else {
    set clock_driver $data_driver
}

set_driving_cell \
    -lib_cell [lindex $clock_driver 0] \
    -pin [lindex $clock_driver 1] \
    [get_ports clk]

# 7. Output capacitive loading
set_load 0.033442 $data_outputs

# 8. Electrical design constraints
set_max_fanout 10 [current_design]

if {[info exists ::env(MAX_TRANSITION_CONSTRAINT)]} {
    set_max_transition \
        $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
}

if {[info exists ::env(MAX_CAPACITANCE_CONSTRAINT)]} {
    set_max_capacitance \
        $::env(MAX_CAPACITANCE_CONSTRAINT) [current_design]
}

# 9. Timing derating
set_timing_derate -early 0.95
set_timing_derate -late 1.05

# 10. Clock propagation
if {[info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] &&
    $::env(OPENLANE_SDC_IDEAL_CLOCKS)} {

    unset_propagated_clock [all_clocks]

} else {

    set_propagated_clock [all_clocks]
}
