# 5-stage Pipelined RISCV Processor
![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue)

This repository is an extension of the single cycle implementation at [RISCV-Single-Cycle-Processor](https://github.com/veerx2704/RISCV_Single_Cycle.git) and aims to optimize that design into a pipelined processor with 5 stages (Instruction Fetch / Decode / Execute / Memory Read/Write / Register Writeback).

## Design-Overview

![RISCV-5-Stage-Pipeline-Microarchitecture](RISCV_PIPELINED.png)

### Supported-Instructions
| Instruction Type | Instruction supported |
|:------------------|:-----------------------|
|R-Type| ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA |
|I-Type| ADDI, ANDI, ORI, XORI, SLTI, SLTUI, SLLI, SRLI, SRAI |
|I-Type (load)| LW, LB, LH, LBU, LHU |
|S-Type| SW, SB, SH |
|B-type| BEQ, BNE, BLT, BLTU |
|U-Type| LUI |
|J-Type| JAL, JALR | 

### File-Structure

```
riscv_pipelined
├── Makefile
├── README.md
├── RISCV_PIPELINED.png
├── constraints
│   └── input_constraints.xdc
├── mem_ASIC ----------------------> Files developed for the purpose of synthesis through Yosys (Sky130 PDK)
│   ├── branch_gshare.sv -------------> Dynamic Branch Predictor (GShare predictor)
│   ├── data_mem.sv
│   └── sram_memory_bank.sv
├── mem_FPGA ----------------------> Files developed for the purpose of synthesis through Vivado (Kintex-7 FPGA)
│   ├── branch_gshare.sv
│   └── data_mem.sv
├── memory_map.v ------------------> Mapping directive for yosys to identify memory blocks from the design
├── my_memlib.txt -----------------> Mapping directive for yosys to identify memory blocks from the design
├── pipelined_ext -----------------> Modules added for the purpose of pipelining the core
│   ├── decode_stage.sv
│   ├── execute_stage.sv
│   ├── fetch_stage.sv
│   ├── forward_unit.sv
│   ├── hazard_unit.sv
│   ├── memory_stage.sv
│   ├── riscv_pipelined.sv
│   └── writeback_stage.sv
├── riscv_sta.tcl
├── single_cycle ----------------> Modules that remain common with the single cycle core (only for referencing pipelined core - for single cycle implementation, strictly refer Single-Cycle-Core Repository)
│   ├── ALU.sv
│   ├── PC_handler.sv
│   ├── PC_next.sv
│   ├── PC_target.sv
│   ├── Single_Cycle_Data_Path.sv
│   ├── adder.sv
│   ├── alu_decoder.sv
│   ├── branch_decoder.sv
│   ├── control_unit.sv
│   ├── imm_extend.sv
│   ├── inst_mem.sv
│   ├── load_computation.sv
│   ├── main_decoder.sv
│   ├── reg_file.sv
│   ├── riscv_single_cycle.sv
│   └── store_computation.sv
├── synth.ys
├── synth_logs
│   ├── riscv_pipelined_netlist.v
│   ├── sta_report.log
│   ├── synthesis_report.log
│   ├── tb_branch_gshare_asic_sim.log
│   ├── tb_branch_gshare_fpga_sim.log
│   ├── tb_decode_stage_sim.log
│   ├── tb_execute_stage_sim.log
│   ├── tb_fetch_stage_sim.log
│   ├── tb_forward_unit_sim.log
│   ├── tb_hazard_unit_sim.log
│   ├── tb_mem_sim.log
│   ├── tb_memory_stage_sim.log
│   ├── tb_riscv_pipelined_asic_sim.log
│   └── tb_riscv_pipelined_fpga_sim.log
├── testbench
│   ├── tb_branch_gshare.sv
│   ├── tb_decode_stage.sv
│   ├── tb_execute_stage.sv
│   ├── tb_fetch_stage.sv
│   ├── tb_forward_unit.sv
│   ├── tb_hazard_unit.sv
│   ├── tb_mem.sv
│   ├── tb_memory_stage.sv
│   └── tb_riscv_pipelined.sv
└── yosys_flow.sh

```
### Design Specs
The design targets to achieve 100MHz operational frequency. 

The repository introduces the following new features - 
1. 5-stage pipeline
2. Dynamic Branch Prediction                                                
3. Hazard Detection - To flush out pipeline when stalling is inevitable
4. Forward Unit - To control data forwarding
5. Exception Handling - To handle invalid instructions
6. Development over 2 methods - Vivado (for FPGA implementation) and Yosys/OpenROAD/OpenSTA (for ASIC implmentation with SkyWater 130nm PDK).

This repository will have nearly the same design in both the approaches, with the difference being at memory access. FPGA based implementation will have BRAM based memory instantiation (2-D array in Verilog), while the ASIC based implementation will have SRAM macro (from PDK library).

The design has been functionally tested to be correct and relevant logs are stored in `synth_logs/`


## Key-Features
| Features | Specification (ASIC Flow - Sky130 PDK) |
|----------|---------------|
| Pipeline | 5-stage |
| Computation Data | 32-bit |
| Operating Frequency| 200MHz |
| Power Consumption | 46.5mW |
| Chip Area | 80150 &mu;m<sup>2<sup> |
