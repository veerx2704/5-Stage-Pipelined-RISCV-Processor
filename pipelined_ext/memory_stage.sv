module memory_stage(
	input wire clk,
	input wire rst,

	//EXMEM stage signals
    input wire [31:0] ALUOut_EXMEM,		//ALU output
    input wire [31:0] srcB_data_EXMEM,	//Data for memory
	input wire [4:0] rd_EXMEM,		    // Destination register address

	//Control Signals
	input wire mem_write_EXMEM,
	input wire mem_read_EXMEM,
	input wire [1:0] store_control_EXMEM,
	input wire [2:0] load_control_EXMEM,
	input wire ResultSrc_EXMEM,
	input wire reg_write_EXMEM,

	// Data path outputs
	output wire [31:0] loaded_data_MEMWB,
	output wire [31:0] ALU_forwarded_MEMWB,
	output wire [4:0] rd_MEMWB,

	//Control path outputs
	output wire ResultSrc_MEMWB,
	output wire reg_write_MEMWB
	
);

wire [31:0] data_to_mem;
// Preprocess the Data (SH,SB,SW)
store_computation DATA_PREPROCESS (	.SrcData(srcB_data_EXMEM),
					.Control(store_control_EXMEM),
					.WData(data_to_mem));


wire [31:0] data_from_mem;
data_mem DATA_MEMORY (	.clk(clk),
			.mem_wen(mem_write_EXMEM),
			.mem_ren(mem_read_EXMEM),
			.addr(ALUOut_EXMEM[31:2]),
			.WData(data_to_mem),
			.RData(data_from_mem));


wire [31:0] loaded_data;
load_computation DATA_POSTPROCESS (	.DataMem(data_from_mem),
					.control(load_control_EXMEM),
					.Result(loaded_data)
				);
//The data from memory is asynchronous read, so it comes in the same cycle.
//We have to register the outputs


reg [31:0] loaded_data_reg;
reg ResultSrc_reg;
reg [4:0] rd_reg;
reg reg_write_reg;

always @(posedge clk) begin
	if (!rst) begin
		loaded_data_reg <= '0;
		ResultSrc_reg <= '0;
		rd_reg <= '0;
		reg_write_reg <= '0;
	end
	else begin
		loaded_data_reg <= loaded_data;
		ResultSrc_reg <= ResultSrc_EXMEM;
		rd_reg <= rd_EXMEM;
		reg_write_reg <= reg_write_EXMEM;
	end
end

assign rd_MEMWB = rd_reg;
assign ResultSrc_MEMWB = ResultSrc_reg;
assign rd_MEMWB = rd_reg;
assign reg_write_MEMWB = reg_write_reg;
endmodule
