module writeback_stage (
	// MEM/WB pre-muxed writeback data
	input wire [31:0] wb_data_MEMWB,
	
	// Write back output
	output wire [31:0] data_WB
);

assign data_WB = wb_data_MEMWB;

endmodule
