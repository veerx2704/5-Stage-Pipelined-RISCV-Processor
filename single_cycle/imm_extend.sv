`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2026 11:42:02 AM
// Design Name: 
// Module Name: imm_extend
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


module imm_extend (
    input wire [31:7] imm_instr,
    input wire [1:0] imm_src,
    input wire u_type,
    output wire [31:0] extended_num
    );
    
    reg [31:0] extended_imm_reg;
    always_comb begin
        case({u_type,imm_src}) 
            3'b000: extended_imm_reg = {{(20){imm_instr[31]}},imm_instr[31:20]};                                     //I-Type Instruction
            3'b001: extended_imm_reg = {{(20){imm_instr[31]}},imm_instr[31:25], imm_instr[11:7]};                    //S-Type Instruction
            3'b010: extended_imm_reg = {{(20){imm_instr[31]}},imm_instr[7],imm_instr[30:25],imm_instr[11:8],1'b0};   //B-Type Instruction
            3'b011: extended_imm_reg = {{(12){imm_instr[31]}},imm_instr[19:12],imm_instr[20],imm_instr[30:21],1'b0}; //J-Type instruction
            3'b100: extended_imm_reg = {imm_instr[31:12],12'b0};                                                     //U-Type instruction
            default: extended_imm_reg = 'z;
        endcase
    end
    assign extended_num = extended_imm_reg;
endmodule
