`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/01/2026 01:31:16 AM
// Design Name: 
// Module Name: memory_bank_32_x_1024
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module memory_bank_32_x_128 (
	input wire clk,
	input wire cs,
	input wire we,
	input wire [31:0] WData,
	input wire [6:0] Waddr,
	input wire [6:0] Raddr,
	output wire [31:0] RData
);

reg [31:0] MEM_BANK [0:127];

initial begin
	$readmemh("memory.txt", MEM_BANK);
end

always @(posedge clk) begin
	if(cs && we) MEM_BANK[Waddr] <= WData;
end

assign RData = cs ? MEM_BANK[Raddr] : 32'b0;

endmodule
