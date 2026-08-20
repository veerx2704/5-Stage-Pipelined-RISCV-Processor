# 5-stage Pipelined RISCV Processor
This repository is an extension of the single cycle implementation at [RISCV-Single-Cycle-Processor](https://github.com/veerx2704/RISCV_Single_Cycle.git) and aims to optimize that design into a pipelined processor with 5 stages (Instruction Fetch / Decode / Execute / Memory Read/Write / Register Writeback).

The repository introduces the following new features - 
1. 5-stage pipeline                                                         (WIP)
2. Dynamic Branch Prediction                                                (WIP)
3. Hazard Detection - To flush out pipeline when stalling is inevitable
4. Forward Unit - To control data forwarding
5. Exception Handling - To handle invalid instructions                      (WIP)
6. Development over 2 methods - Vivado (for FPGA implementation) and Yosys/OpenROAD/OpenSTA (for ASIC implmentation with SkyWater 130nm PDK).

This repository will have nearly the same design in both the approaches, with the difference being at memory access. FPGA based implementation will have BRAM based memory instantiation (2-D array in Verilog), while the ASIC based implementation will have SRAM macro (from PDK library).

The design is still in development stage, with completion targetted for late August/early September