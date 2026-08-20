`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2026 11:42:02 AM
// Design Name: 
// Module Name: riscv_single_cycle
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


module riscv_single_cycle #(parameter WIDTH = 32)(
    input wire clk,
    input wire rst,
    output wire [31:0] dbg_MEMD,
    output wire [31:0] dbg_MEMA,
    output wire [31:0] dbg_INS,
    output wire [31:0] dbg_PC
    );
    
    // INSTRUCTION MEMORY SIGNALS
    wire [31:0] instruction;
    wire [31:0] PC_addr;
    
    //DATA MEMORY SIGNALS
    wire [31:0] Data_mem;
    
    
    // CONTROL UNIT SIGNALS
    wire zero;
    wire LT;
    wire LTU;
    wire PCSrc;
    wire jump;
    wire ResultSrc;
    wire reg_write;
    wire mem_write;
    wire u_type;
    wire ALUSrc;
    wire [3:0] ALUCode;
    wire [1:0] imm_src;
    wire [1:0] store_control;
    wire [2:0] load_control;
    
    //DATAPATH SIGNALS
    wire [31:0] Waddr;
    wire [31:0] WData;
    
        inst_mem #(.WIDTH(WIDTH)) INSTRUCTION_MEMORY( .PC(PC_addr[31:2]),
                                                      .rst(rst),
                                                      .decoded_I(instruction));
        Single_Cycle_Data_Path SINGLE_CYCLE( .clk(clk),
                                .rst(rst),
                                .Data_mem(Data_mem),
                                .instruction(instruction[31:7]),
                                .ALUCode(ALUCode),
                                .load_control(load_control),
                                .imm_src(imm_src),
                                .store_control(store_control),
                                .ALUSrc(ALUSrc),
                                .jump(jump),
                                .PCSrc(PCSrc),
                                .reg_write(reg_write),
                                .u_type(u_type),
                                .ResultSrc(ResultSrc),
                                .zero(zero),
                                .LT(LT),
                                .LTU(LTU),
                                .PC_addr(PC_addr),
                                .WData(WData),
                                .Waddr(Waddr));
                                
        control_unit CONTROL_UNIT( .opcode(instruction[6:0]),
                               .funct3(instruction[14:12]),
                               .funct7_b5(instruction[30]),
                               .zero(zero),
                               .LT(LT),
                               .LTU(LTU),
                               .ALUCode(ALUCode),
                               .load_control(load_control),
                               .imm_src(imm_src),
                               .store_control(store_control),
                               .ALUSrc(ALUSrc),
                               .mem_write(mem_write),
                               .mem_read(mem_read),
                               .reg_write(reg_write),
                               .u_type(u_type),
                               .ResultSrc(ResultSrc),
                               .PCSrc(PCSrc),
                               .jump(jump));
                               
            data_mem #(.WIDTH(WIDTH)) DATA_MEMORY ( .WData(WData),
                                            .addr(Waddr[31:2]),
                                            .clk(clk),
                                            .mem_wen(mem_write),
                                            .mem_ren(mem_read),
                                            .RData(Data_mem));
                                            
	assign dbg_PC = PC_addr;
	assign dbg_INS = instruction;
	assign dbg_MEMD = WData;
	assign dbg_MEMA = Waddr;
    initial begin
        $monitor($time," x5:%h\tx6:%h",SINGLE_CYCLE.REG_FILE.REGISTER_FILE[5], SINGLE_CYCLE.REG_FILE.REGISTER_FILE[6]);
        $monitor($time," Current_addr:%h\tinstruction:%h\t\tcu_instruction:%h\n",SINGLE_CYCLE.PC_addr, SINGLE_CYCLE.instruction, instruction[31:7]);
        $monitor($time," target_addr:%h\tPC_SOURCE:%b\t\tNew_Immediate:%h",SINGLE_CYCLE.target_addr, SINGLE_CYCLE.PC_source, SINGLE_CYCLE.imm_value);
        $monitor($time," Register A:%h\t\tRegister B:%h",SINGLE_CYCLE.read_regA, SINGLE_CYCLE.read_regB);
        $monitor($time," Address RegA: %h\t\tAddress RegB:%h",SINGLE_CYCLE.REG_FILE.SrcA,SINGLE_CYCLE.REG_FILE.SrcB);
        $monitor($time," ALU_SRCA: %h\t\tALU_SRCB:%h\n\t\t\t\tALU_code: %b\t\tALU_SLT:%b",SINGLE_CYCLE.ALU_ACTUAL.DataA,SINGLE_CYCLE.ALU_ACTUAL.DataB,SINGLE_CYCLE.ALU_ACTUAL.ALUCode, SINGLE_CYCLE.ALU_ACTUAL.SLT);
        $monitor($time," DataMemAddr: %h\t\tMem_en_write: %b\t\t\t\tMem_en_read:%b\t\t\t\tx1:%h\t\t\t\tx7:%h",DATA_MEMORY.addr,DATA_MEMORY.mem_wen,DATA_MEMORY.mem_ren, SINGLE_CYCLE.REG_FILE.REGISTER_FILE[1],SINGLE_CYCLE.REG_FILE.REGISTER_FILE[7]);
        $monitor($time," DataMem: %h\t\tLoaded data:%h",DATA_MEMORY.RData, SINGLE_CYCLE.REG_FILE.REGISTER_FILE[1]);
        
    end
endmodule