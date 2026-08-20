`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/04/2026 07:51:14 PM
// Design Name: 
// Module Name: branch_decoder
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


module branch_decoder(
    input wire branch,
    input wire [2:0] funct3,
    input wire zero,
    input wire LT,
    input wire LTU,
    output wire PC_src
    );
    
    reg PC_src_reg;
    
    always_comb begin
        case(funct3)
            3'b000: PC_src_reg = zero;      //BEQ
            3'b001: PC_src_reg = ~zero;     //BNE
            3'b100: PC_src_reg = LT;        //BLT
            3'b110: PC_src_reg = LTU;       //BLTU
            default: PC_src_reg = 1'bx;
        endcase
    end
    
    assign PC_src = branch & PC_src_reg;
    
endmodule
