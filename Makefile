SHELL := /bin/bash

.PHONY: all lint synth synthesis tpower clean

all: synthesis tpower

lint:
	@verilator --lint-only -Wall -Wno-DECLFILENAME --top-module riscv_pipelined pipelined_ext/*.sv single_cycle/*.sv mem_ASIC/*.sv

synth: synthesis

synthesis: yosys_flow.sh
	@echo "Beginning Synthesis"
	@./yosys_flow.sh
	@echo "Synthesis Complete! Output recorded at synth_logs/synthesis_report.log"

tpower: riscv_sta.tcl
	@echo "Opening Timing and Power Simulation"
	@sta -exit riscv_sta.tcl | tee synth_logs/sta_report.log

clean:
	@echo "Cleaning generated synthesis/STA logs"
	@rm -rf synth_logs/*.log synth_logs/*.v
