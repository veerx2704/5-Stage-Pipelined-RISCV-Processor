`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2026 10:30:31 PM
// Design Name: 
// Module Name: Single_Cycle_Data_Path
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


module Single_Cycle_Data_Path #(parameter WIDTH = 32)(
    input wire clk,
    input wire rst,
    input wire [31:0] Data_mem,
    input wire [31:7] instruction,
    input wire [3:0] ALUCode,
    input wire [2:0] load_control,
    input wire [1:0] imm_src,
    input wire [1:0] store_control,
    input wire ALUSrc,
    input wire PCSrc,
    input wire reg_write,
    input wire jump,
    input wire u_type,
    input wire ResultSrc,
    output wire zero,
    output wire LT,
    output wire LTU,
    output wire [31:0] PC_addr,
    output wire [31:0] WData,
    output wire [31:0] Waddr
    );
    
    wire [31:0] loaded_data;
    wire [31:0] loaded_mem_data;
    wire [31:0] next_addr;
    wire [31:0] target_addr;
    wire [31:0] target_addr;
    wire [31:0] imm_value;
    wire [31:0] read_regA;
    wire [31:0] read_regB;
    wire [31:0] ALU_out;
    
    wire [31:0] PC_next_addr;
    
    
    wire PC_source;
    assign PC_source = PCSrc | jump;
        assign PC_next_addr = PC_source ? target_addr : next_addr;

    PC_handler #(.WIDTH(WIDTH)) updatedPC( .PC_addr(PC_next_addr), 
                                           .clk(clk), 
                                           .rst(rst),
                                           .next_PC(PC_addr));
                                           
    PC_next #(.WIDTH(WIDTH))       nextPC( .current_PC(PC_addr),
                                           .next_PC(next_addr));
                                           
    PC_target #(.WIDTH(WIDTH))   targetPC( .current_PC(PC_addr),
                                           .imm_ext(imm_value),
                                           .target_PC(target_addr));
    



                                           
    imm_extend EXTENDED_IMMEDIATE ( .imm_instr(instruction[31:7]),
                                 .imm_src(imm_src),
                                 .u_type(u_type),
                                 .extended_num(imm_value));
    wire [31:0] data_to_register;
    
    assign data_to_register = jump ? PC_addr : loaded_data;                 //write next PC address to register if jump
    
    reg_file #(.WIDTH(WIDTH)) REG_FILE( .clk(clk),
                                             .SrcA(instruction[19:15]),
                                             .SrcB(instruction[24:20]),
                                             .DestC(instruction[11:7]),
                                             .WData(data_to_register),
                                             .Wen(reg_write),
                                             .RDataA(read_regA),
                                             .RDataB(read_regB));                             
    

    wire [31:0] ALUDataB;
    wire [31:0] ALUDataA;
    assign ALUDataB = ALUSrc ? imm_value : read_regB;
    assign ALUDataA = read_regA;
    ALU #(.WIDTH(WIDTH)) ALU_ACTUAL( .DataA(ALUDataA),
                                     .DataB(ALUDataB),
                                     .ALUCode(ALUCode),
                                     .ALU_out(ALU_out),
                                     .zero(zero),
                                     .LT(LT),
                                     .LTU(LTU));
    store_computation #(.WIDTH(WIDTH)) STORE_COMPUTATION (.SrcData(read_regB),
                                                          .Control(store_control),
                                                          .WData(WData));

    
    load_computation #(.WIDTH(WIDTH)) LOAD_COMPUTATION ( .DataMem(Data_mem),
                                                         .control(load_control),
                                                         .Result(loaded_mem_data));
    

    assign Waddr = ALU_out;
    assign loaded_data = ResultSrc ? loaded_mem_data : ALU_out;
endmodule
