module memory_stage(
	input wire clk,
	input wire rst,

	// Combinational EX stage signals (launched into synchronous SRAM/BRAM on posedge clk)
	input wire [31:0] ALUOut_EX_comb,
	input wire [31:0] store_data_EX_comb,
	input wire mem_write_EX_comb,
	input wire mem_read_EX_comb,
	input wire [1:0] store_control_EX_comb,

	// EX/MEM registered signals
	input wire [31:0] ALUOut_EXMEM,		// ALU output (also provides byte_offset for load)
	input wire [31:0] PC_plus4_EXMEM,	// PC+4 for JAL writeback
	input wire [4:0] rd_EXMEM,		    // Destination register address

	// Control signals (EX/MEM registered)
	input wire [2:0] load_control_EXMEM,
	input wire jump_EXMEM,
	input wire ResultSrc_EXMEM,
	input wire reg_write_EXMEM,

	// Data path outputs (MEM/WB registered)
	output wire [31:0] wb_data_MEMWB,
	output wire [4:0] rd_MEMWB,

	// Control path outputs (MEM/WB registered)
	output wire reg_write_MEMWB
);

wire [31:0] data_to_mem;
wire [3:0]  store_wmask;

// Preprocess store data and generate byte-write mask (SB, SH, SW)
store_computation DATA_PREPROCESS (
	.SrcData(store_data_EX_comb),
	.Control(store_control_EX_comb),
	.byte_offset(ALUOut_EX_comb[1:0]),
	.WData(data_to_mem),
	.wmask(store_wmask)
);

// Synchronous SRAM/BRAM captures addr/WData/wmask/enables on posedge clk in lockstep with EX/MEM
wire [31:0] data_from_mem;
data_mem DATA_MEMORY (
	.clk(clk),
	.mem_wen(mem_write_EX_comb),
	.mem_ren(mem_read_EX_comb),
	.wmask(store_wmask),
	.addr(ALUOut_EX_comb[31:2]),
	.WData(data_to_mem),
	.RData(data_from_mem)
);

// Postprocess loaded data using registered EX/MEM byte offset & load_control
wire [31:0] loaded_data;
load_computation DATA_POSTPROCESS (
	.DataMem(data_from_mem),
	.control(load_control_EXMEM),
	.byte_offset(ALUOut_EXMEM[1:0]),
	.Result(loaded_data)
);

// Pre-mux writeback data before MEM/WB FF so WB->EX forwarding launches directly from FF/Q
wire [31:0] wb_data_comb = jump_EXMEM    ? PC_plus4_EXMEM :
                           ResultSrc_EXMEM ? loaded_data  :
                                             ALUOut_EXMEM;

reg [31:0] wb_data_reg;
reg [4:0] rd_reg;
reg reg_write_reg;

always @(posedge clk) begin
	if (!rst) begin
		wb_data_reg   <= '0;
		rd_reg        <= '0;
		reg_write_reg <= '0;
	end
	else begin
		wb_data_reg   <= wb_data_comb;
		rd_reg        <= rd_EXMEM;
		reg_write_reg <= reg_write_EXMEM;
	end
end

assign wb_data_MEMWB   = wb_data_reg;
assign rd_MEMWB        = rd_reg;
assign reg_write_MEMWB = reg_write_reg;

endmodule
