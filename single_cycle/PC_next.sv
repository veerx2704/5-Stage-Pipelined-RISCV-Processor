`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 02:55:49 PM
// Design Name: 
// Module Name: PC_next
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


module PC_next #(parameter WIDTH = 32) (
    input wire [WIDTH - 1:0] current_PC,
    output wire [WIDTH - 1:0] next_PC
    );
    assign next_PC = {current_PC[WIDTH-1:2] + {{(WIDTH-3){1'b0}}, 1'b1}, current_PC[1:0]};
endmodule
