# ==========================================
# TCAM Accelerator Timing Constraints
# ==========================================

# 100 MHz system clock
create_clock -name sys_clk -period 10.000 [get_ports clk]

# Asynchronous human-operated inputs
# These inputs enter synchronization registers
set_false_path -from [get_ports {btnC btnU btnD btnL btnR}]
set_false_path -from [get_ports {sw[*]}]

# Human-readable LED outputs
# No external synchronous capture requirement
set_false_path -to [get_ports {led[*]}]