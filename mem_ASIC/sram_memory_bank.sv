
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


module sram_memory_bank (
	input wire clk,
	input wire cs,
	input wire we,
	input wire re,
	input wire [31:0] WData,
	input wire [7:0] Waddr,
	input wire [7:0] Raddr,
	output wire [31:0] RData_0,
	output wire [31:0] RData_1
);


//SRAM MACRO INTERFACE
wire [3:0] wmask = 4'b1111;
wire ren = cs & re;
sky130_sram_1kbyte_1rw1r_32x256_8 u_mem_bank(
	`ifdef USE_POWER_PINS
		.vccd1(vccd1),
		.vssd1(vssd1),
	`endif
	
	.clk0(~clk),
	.csb0(~cs),
	.web0(~we),
	.wmask0(wmask),
	.addr0(Waddr),
	.din0(WData),
	.dout0(RData_0),
	
	.clk1(~clk),
	.csb1(~ren),
	.addr1(Raddr),
	.dout1(RData_1)
);



endmodule
