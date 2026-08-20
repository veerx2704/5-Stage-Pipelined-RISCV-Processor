`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2026 10:54:16 PM
// Design Name: 
// Module Name: riscv_top
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


module riscv_top(
    input wire clk,
    input wire rst,
    output wire [31:0] dbg_MEMD,
    output wire [31:0] dbg_MEMA,
    output wire [31:0] dbg_INS,
    output wire [31:0] dbg_PC
    );
    
    riscv_single_cycle RISCV_SINGLE_CYCLE (.clk(clk), .rst(rst), .dbg_MEMD(dbg_MEMD), .dbg_MEMA(dbg_MEMA), .dbg_INS(dbg_INS), .dbg_PC(dbg_PC));
endmodule