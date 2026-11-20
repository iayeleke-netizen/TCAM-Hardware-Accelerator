# Low-Latency TCAM Hardware Accelerator — FPGA to ASIC

## Project Overview

This project implements a low-latency Ternary Content-Addressable Memory (TCAM) hardware accelerator using SystemVerilog on the Digilent Basys 3 FPGA development board.

The accelerator performs simultaneous masked comparisons across four configurable 8-bit rules, supporting exact matching, wildcard matching, rule invalidation, and priority-based match selection.

The design explores hardware acceleration techniques applicable to network packet classification, low-latency trading infrastructure, and high-speed data filtering.

The project covers RTL development, randomized verification, FPGA implementation and hardware testing, followed by SKY130 ASIC physical implementation, multi-corner timing and power analysis, formal equivalence, and physical verification.

## Key Features

- Four configurable 8-bit TCAM entries
- Parallel masked comparison architecture
- 68 bits of configurable rule storage
- Exact and wildcard matching
- Dynamic rule configuration and invalidation
- Lowest-index priority encoding
- Registered input and output architecture
- Single-cycle lookup latency
- One lookup per clock cycle
- 100 MHz operating frequency
- Physical hardware implementation on the Basys 3 FPGA
- 10,403 successful simulation checks

## System Architecture

The accelerator consists of six primary RTL modules:

| Module | Function |
|---|---|
| tcam_comparator | Performs masked binary comparisons |
| tcam_rule_memory | Stores rules, masks, and valid bits |
| tcam_array | Performs simultaneous rule comparisons |
| priority_encoder | Selects the lowest matching rule index |
| tcam_core | Integrates the memory, comparators, and encoder |
| tcam_registered | Implements registered lookup processing |

Two additional modules provide the physical FPGA interface:

- button_debounce
- tcam_fpga_top

Architecture diagrams are available in the diagrams directory.

## TCAM Matching Logic

Each stored rule consists of an 8-bit rule value, an 8-bit mask, and a valid bit.

A mask bit of 1 requires the corresponding input bit to match the stored rule. A mask bit of 0 treats the corresponding bit as a wildcard.

The comparison operation is:

```systemverilog
match = valid && (((data ^ rule) & mask) == 0);
```

All four rules are evaluated simultaneously. The resulting match vector is passed to a priority encoder, which selects the lowest matching rule index.

### Example

| Rule | Mask | Input | Match |
|---|---|---|---|
| 0xAA | 0xFF | 0xAA | Yes |
| 0xAA | 0xFF | 0xAB | No |
| 0xA0 | 0xF0 | 0xAB | Yes |
| 0xC0 | 0xC0 | 0xC5 | Yes |

## Pipeline Architecture

The design uses input and output registers to provide deterministic lookup latency.

At the first rising clock edge, the input data and lookup-valid signal are captured. The parallel comparators and priority encoder then process the input before the result is captured at the following rising edge.

- Clock period: 10 ns
- Lookup latency: 1 clock cycle
- Throughput: 1 lookup per clock cycle
- Architectural throughput: 100 million lookups per second

## Functional Verification

Nine self-checking SystemVerilog testbenches were developed to verify individual modules and the integrated accelerator.

| Verification Stage | Checks Passed |
|---|---:|
| TCAM Comparator | 8 |
| Rule Memory | 17 |
| TCAM Array | 10 |
| Priority Encoder | 16 |
| Integrated Core | 14 |
| Registered Core | 18 |
| Randomized Verification | 10,300 |
| Button Debouncer | 7 |
| FPGA Wrapper | 13 |
| **Total** | **10,403** |

The randomized verification stage evaluated 100 rule configurations and 10,000 lookup transactions.

Verification covered:

- Exact matches and mismatches
- Wildcard matching
- Multiple simultaneous matches
- Priority resolution
- Invalid entries
- Reset behavior
- Consecutive lookup transactions
- Registered output timing

All simulation checks passed with zero reported failures.

## FPGA Implementation

The design was synthesized and implemented using AMD Vivado 2026.1.

**Target Hardware**

- Development board: Digilent Basys 3
- FPGA family: Xilinx Artix-7
- Device: XC7A35T-1CPG236C
- System clock: 100 MHz

### Post-Implementation Resource Utilization

| Resource | TCAM Core | Complete FPGA Design |
|---|---:|---:|
| LUTs | 28 | 71 |
| Flip-Flops | 85 | 237 |
| Block RAM | 0 | 0 |
| DSP Blocks | 0 | 0 |

The core implements its storage and comparison architecture using standard FPGA logic resources without requiring dedicated block memory or DSP resources.

## Static Timing Analysis

Post-route timing analysis was performed on the complete FPGA design and the internal TCAM register-to-register paths.

| Metric | Result |
|---|---:|
| Target Clock Frequency | 100 MHz |
| Complete Design Setup Slack | +5.451 ns |
| Complete Design Hold Slack | +0.122 ns |
| Total Negative Slack | 0 ns |
| Core Internal Setup Slack | +5.894 ns |
| Core Critical Data Path Delay | 4.076 ns |
| Core Critical Path Logic Levels | 3 |
| Estimated Core Fmax | 243.55 MHz |
| Estimated Complete Design Fmax | 219.83 MHz |
| Design Rule Violations | 0 |

### Critical Path Analysis

The worst reported internal TCAM setup path originates from a stored rule register and terminates at a match-vector output register.

| Delay Component | Delay | Percentage |
|---|---:|---:|
| Logic | 1.021 ns | 25.05% |
| Routing | 3.055 ns | 74.95% |
| Total | 4.076 ns | 100% |

The predominance of routing delay provides an opportunity to investigate alternative physical implementations during future ASIC development.

Maximum-frequency values are estimates derived from post-route setup timing at the 100 MHz target constraint. They do not represent measured operating frequencies or independently verified timing closure at those higher frequencies.

## Physical Hardware Verification

The accelerator was programmed onto the Basys 3 FPGA and tested using its onboard switches, push buttons, and LEDs.

### Input Interface

| Input | Function |
|---|---|
| SW[7:0] | Rule, mask, or lookup data |
| SW[9:8] | Rule address |
| SW[10] | Rule valid bit |
| BTNU | Capture rule |
| BTND | Capture mask |
| BTNR | Write rule |
| BTNL | Perform lookup |
| BTNC | Reset |

### Output Interface

| Output | Function |
|---|---|
| LED[3:0] | Match vector |
| LED[4] | Match found |
| LED[6:5] | Match index |
| LED[7] | Lookup completed |
| LED[15:8] | Captured rule |

### Hardware Test Results

| Test | Result |
|---|---|
| Exact matching | PASS |
| Exact match rejection | PASS |
| Wildcard matching | PASS |
| Multiple matches and priority selection | PASS |
| Additional rule addresses | PASS |
| Rule invalidation | PASS |
| Reset verification | PASS |

All seven hardware test categories passed.

The board interface demonstrates functional operation. The core's high-speed latency and throughput are supported by RTL simulation, architecture, and static timing analysis rather than direct high-speed hardware measurements.

## Repository Structure

```text
TCAM-Hardware-Accelerator/
├── RTL/
├── TB/
├── CONSTRAINTS/
├── REPORTS/
├── SIMULATION/
├── DIAGRAMS/
├── BITSTREAM/
├── ASIC/
│   ├── rtl/
│   ├── tb/
│   ├── constraints/
│   ├── netlist/
│   ├── signoff/
│   └── final_deliverables/
├── .gitignore
└── README.md
```

## Reproducing the FPGA Implementation

1. Create a new Vivado RTL project targeting xc7a35tcpg236-1.
2. Import the SystemVerilog files from the RTL directory.
3. Import the testbenches from the TB directory.
4. Import both XDC files from the CONSTRAINTS directory.
5. Set tcam_fpga_top as the synthesis top module.
6. Run synthesis and implementation.
7. Generate the bitstream.
8. Connect the Basys 3 board and program the FPGA through Vivado Hardware Manager.

A prebuilt bitstream is also provided for the compatible Basys 3 device.

## Tools and Technologies

- SystemVerilog
- AMD Vivado
- Xilinx Artix-7 FPGA
- Digilent Basys 3
- RTL Design
- Functional Verification
- Randomized Verification
- Static Timing Analysis
- Clock Domain Crossing
- FPGA Synthesis and Implementation
- Hardware Debugging

## ASIC Implementation — SKY130

The TCAM accelerator was also implemented as a standard-cell ASIC using
the open-source SKY130 technology and an OpenROAD-based physical design flow.

The ASIC implementation includes logic synthesis, placement, clock-tree
synthesis, routing, parasitic extraction, multi-corner static timing analysis,
power estimation, physical verification, and formal equivalence checking.

### ASIC Design Specifications

| Parameter | Result |
|---|---|
| Top module | tcam_registered |
| Technology | SKY130 |
| Target frequency | 100 MHz |
| Clock period | 10 ns |
| Nominal supply | 1.80 V |
| Die dimensions | 112.44 × 123.16 µm |
| Die area | 0.013848 mm² |
| Physical instances | 1,921 |
| Flip-flops | 85 |

### ASIC Timing and Power Results

| Metric | Result |
|---|---:|
| Worst setup slack | +4.5496 ns |
| Worst hold slack | +0.1033 ns |
| Timing corners analyzed | 9 |
| Nominal estimated power | 831.3147 µW |
| Minimum estimated power | 651.7134 µW |
| Maximum estimated power | 974.3918 µW |
| Worst combined IR-drop bound | 1.242 mV |

All nine analyzed timing corners reported positive setup and hold slack.

Power values are estimates rather than silicon measurements.
The IR-drop analysis is preliminary and does not include package effects.

### ASIC Verification

| Verification | Result |
|---|---|
| RTL-to-synthesis equivalence | PASS |
| Synthesis-to-final equivalence | PASS |
| RTL-to-final equivalence | PASS |
| Reset-aware formal equivalence | PASS |
| Magic DRC | 0 reported violations |
| KLayout DRC | 0 reported violations |
| GDS XOR comparison | 0 reported differences |
| Netgen LVS | PASS |
| Antenna checks | 0 reported violations |

Formal verification used ABC PDR.

### Engineering Exceptions and Limitations

One root clock-net fanout violation remains against the global
fanout limit of 10. The actual fanout is 16 clock-buffer sinks.
Electrical loading and transition checks were reviewed, and an
engineering exception was documented. Manufacturing waiver approval
has not been obtained.

Extraction warnings were reviewed, but transistor-level simulation
scaling requires separate verification.

This project is an engineering-verified portfolio implementation,
not a foundry-approved manufacturing or tapeout release.

### Final ASIC Deliverables

The `ASIC/final_deliverables/` directory contains:

- Magic and KLayout GDS layouts
- Final DEF and OpenDB design database
- Gate-level Verilog netlist
- Nine-corner timing and power reports
- IR-drop and physical verification reports
- Formal verification evidence
- Engineering signoff documentation
- Final manifest and SHA-256 checksums

See `ASIC/final_deliverables/MANIFEST.txt` for details.

## Future Development

Potential future work includes:

- Resolving the remaining clock fanout exception
- Completing foundry-specific manufacturing signoff
- Additional transistor-level simulation
- Evaluating larger TCAM configurations
- Exploring integration into a RISC-V-based accelerator system

## Project Status

FPGA implementation and hardware verification: Complete.

ASIC physical implementation and documented engineering verification:
Complete, with open engineering exceptions.

Manufacturing/tapeout signoff: Not complete.

## Author

Femi Ayeleke

Electrical Engineering — Kansas State University

LinkedIn: https://www.linkedin.com/in/femi-ayeleke

GitHub: https://github.com/iayeleke-netizen