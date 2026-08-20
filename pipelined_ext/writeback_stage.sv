module writeback_stage (
	input wire clk,
	input wire rst,

	//MEM stage inputs
	input wire [31:0] ALU_forwarded_MEMWB,
	input wire [31:0] loaded_data_MEMWB,
	

	//Control path signal
	input wire ResultSrc_MEMWB,
	
	//Write back output
	output wire [31:0] data_WB
);


assign data_WB = ResultSrc_MEMWB ? loaded_data_MEMWB : ALU_forwarded_MEMWB;


endmodule
