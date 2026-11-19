`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/16/2026 09:50:49 PM
// Design Name: 
// Module Name: hazard_unit
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


module hazard_unit(
        input wire [31:0] instruction,
        input wire [4:0] rd_IDEX,
        input wire mem_read_IDEX,
        input wire PCSrc_EX,
        output wire PCWrite,
        output wire IF_ID_write,
        output wire flush_IFID,
        output wire pipeline_flush
    );
    
    parameter I_Type    = 7'b0010011;
    parameter L_Type    = 7'b0000011;
    parameter JALR_Type = 7'b1100111;
    parameter S_Type    = 7'b0100011;
    parameter R_Type    = 7'b0110011;
    parameter B_Type    = 7'b1100011;
    
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    
    wire [6:0] opcode = instruction[6:0];
    wire rs1_match      = (rs1 == rd_IDEX);
    wire rs2_match      = (rs2 == rd_IDEX);
    wire uses_rs1       = (opcode == I_Type) || (opcode == L_Type) || (opcode == JALR_Type) || (opcode == S_Type) || (opcode == R_Type) || (opcode == B_Type);
    wire uses_rs2       = (opcode == S_Type) || (opcode == R_Type) || (opcode == B_Type);
    wire load_use_stall = mem_read_IDEX && (rd_IDEX != 5'b0) && ((uses_rs1 && rs1_match) || (uses_rs2 && rs2_match));

    // On taken branch/jump in EX (PCSrc_EX), always redirect PC and squash IF/ID + ID/EX
    assign PCWrite        = (~load_use_stall) | PCSrc_EX;
    assign IF_ID_write    = ~load_use_stall;
    assign flush_IFID     = PCSrc_EX;
    assign pipeline_flush = load_use_stall | PCSrc_EX;
endmodule
