`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2026 04:30:17 PM
// Design Name: 
// Module Name: riscv_pipelined
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 5-stage pipelined RV32I processor top-level
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module riscv_pipelined(
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] dbg_PC,
    output wire [31:0] dbg_INS,
    output wire [31:0] dbg_WB_data,
    output wire [4:0]  dbg_WB_rd,
    output wire        dbg_WB_wen
);

    // Hazard & Control-Flow signals
    wire        PCWrite;
    wire        IF_ID_write;
    wire        flush_IFID;
    wire        flush_IDEX;
    wire        PCSrc_EX;
    wire [31:0] target_address_EX;

    // IF -> ID signals
    wire [31:0] PC_IFID;
    wire [31:0] PC_plus4_IFID;
    wire [31:0] inst_IFID;

    // ID -> EX signals
    wire [31:0] inst_hazard;
    wire [4:0]  rs1_addr_ID;
    wire [4:0]  rs2_addr_ID;
    wire [1:0]  fwdA_ID;
    wire [1:0]  fwdB_ID;
    wire [1:0]  fwdA_IDEX;
    wire [1:0]  fwdB_IDEX;
    wire [31:0] rs1_IDEX;
    wire [31:0] rs2_IDEX;
    wire [31:0] imm_value_IDEX;
    wire [31:0] PC_plus4_IDEX;
    wire [31:0] target_address_IDEX;
    wire [4:0]  rs1_addr_IDEX;
    wire [4:0]  rs2_addr_IDEX;
    wire [4:0]  rd_IDEX;
    wire [3:0]  ALUCode_IDEX;
    wire [2:0]  funct3_IDEX;
    wire [2:0]  load_control_IDEX;
    wire [1:0]  store_control_IDEX;
    wire        ALUSrc_IDEX;
    wire        branch_IDEX;
    wire        jump_IDEX;
    wire        mem_read_IDEX;
    wire        mem_write_IDEX;
    wire        ResultSrc_IDEX;
    wire        reg_write_IDEX;

    // EX -> MEM signals (combinational for synchronous SRAM/BRAM launch)
    wire [31:0] ALUOut_EX_comb;
    wire [31:0] store_data_EX_comb;
    wire        mem_write_EX_comb;
    wire        mem_read_EX_comb;
    wire [1:0]  store_control_EX_comb;

    // EX -> MEM signals (EX/MEM registered)
    wire [31:0] ALUOut_EXMEM;
    wire [31:0] PC_plus4_EXMEM;
    wire [31:0] srcB_data_EXMEM;
    wire [4:0]  rd_EXMEM;
    wire        mem_write_EXMEM;
    wire        mem_read_EXMEM;
    wire [1:0]  store_control_EXMEM;
    wire [2:0]  load_control_EXMEM;
    wire        jump_EXMEM;
    wire        ResultSrc_EXMEM;
    wire        reg_write_EXMEM;

    // EX -> Forward & Hazard Unit signals
    wire [4:0]  rs1_forward_compare;
    wire [4:0]  rs2_forward_compare;
    wire [4:0]  rd_hazard;
    wire        mem_read_hazard;
    wire [1:0]  fwdA_EX;
    wire [1:0]  fwdB_EX;

    // MEM -> WB signals
    wire [31:0] wb_data_MEMWB;
    wire [4:0]  rd_MEMWB;
    wire        reg_write_MEMWB;

    // WB output & forwarding data
    wire [31:0] data_WB;
    wire [31:0] forward_data_MEM = jump_EXMEM ? PC_plus4_EXMEM : ALUOut_EXMEM;

    // Stage 1: Instruction Fetch (IF)
    fetch_stage IF_STAGE (
        .clk            (clk),
        .rst            (rst),
        .PCWrite        (PCWrite),
        .IF_ID_write    (IF_ID_write),
        .flush_IFID     (flush_IFID),
        .PCSrc          (PCSrc_EX),
        .target_address (target_address_EX),
        .PC_IFID        (PC_IFID),
        .PC_plus4_IFID  (PC_plus4_IFID),
        .inst_IFID      (inst_IFID)
    );

    // Stage 2: Instruction Decode (ID)
    decode_stage ID_STAGE (
        .clk                 (clk),
        .rst                 (rst),
        .hazard_stall        (flush_IDEX),
        .flush_IDEX          (1'b0),
        .inst_IFID           (inst_IFID),
        .PC_IFID             (PC_IFID),
        .PC_plus4_IFID       (PC_plus4_IFID),
        .reg_write_WB        (reg_write_MEMWB),
        .Rd_MEMWB_forwarded  (rd_MEMWB),
        .WData_WB_forwarded  (data_WB),
        .fwdA_ID             (fwdA_ID),
        .fwdB_ID             (fwdB_ID),
        .inst_hazard         (inst_hazard),
        .rs1_addr_ID         (rs1_addr_ID),
        .rs2_addr_ID         (rs2_addr_ID),
        .rs1_IDEX            (rs1_IDEX),
        .rs2_IDEX            (rs2_IDEX),
        .imm_value_IDEX      (imm_value_IDEX),
        .PC_plus4_IDEX       (PC_plus4_IDEX),
        .target_address_IDEX (target_address_IDEX),
        .rs1_addr_IDEX       (rs1_addr_IDEX),
        .rs2_addr_IDEX       (rs2_addr_IDEX),
        .rd_IDEX             (rd_IDEX),
        .fwdA_IDEX           (fwdA_IDEX),
        .fwdB_IDEX           (fwdB_IDEX),
        .ALUCode_IDEX        (ALUCode_IDEX),
        .funct3_IDEX         (funct3_IDEX),
        .load_control_IDEX   (load_control_IDEX),
        .store_control_IDEX  (store_control_IDEX),
        .ALUSrc_IDEX         (ALUSrc_IDEX),
        .branch_IDEX         (branch_IDEX),
        .jump_IDEX           (jump_IDEX),
        .mem_read_IDEX       (mem_read_IDEX),
        .mem_write_IDEX      (mem_write_IDEX),
        .ResultSrc_IDEX      (ResultSrc_IDEX),
        .reg_write_IDEX      (reg_write_IDEX)
    );

    // Stage 3: Execute (EX)
    execute_stage EX_STAGE (
        .clk                   (clk),
        .rst                   (rst),
        .flush_EXMEM           (PCSrc_EX),
        .rs1_IDEX              (rs1_IDEX),
        .rs2_IDEX              (rs2_IDEX),
        .imm_value_IDEX        (imm_value_IDEX),
        .PC_plus4_IDEX         (PC_plus4_IDEX),
        .target_address_IDEX   (target_address_IDEX),
        .rs1_addr_IDEX         (rs1_addr_IDEX),
        .rs2_addr_IDEX         (rs2_addr_IDEX),
        .rd_IDEX               (rd_IDEX),
        .forward_data_WB       (data_WB),
        .forward_data_MEM      (forward_data_MEM),
        .ALUCode_IDEX          (ALUCode_IDEX),
        .funct3_IDEX           (funct3_IDEX),
        .ALUSrc_IDEX           (ALUSrc_IDEX),
        .branch_IDEX           (branch_IDEX),
        .jump_IDEX             (jump_IDEX),
        .load_control_IDEX     (load_control_IDEX),
        .store_control_IDEX    (store_control_IDEX),
        .mem_read_IDEX         (mem_read_IDEX),
        .mem_write_IDEX        (mem_write_IDEX),
        .ResultSrc_IDEX        (ResultSrc_IDEX),
        .reg_write_IDEX        (reg_write_IDEX),
        .forwardA              (fwdA_IDEX),
        .forwardB              (fwdB_IDEX),
        .ALUOut_EX_comb        (ALUOut_EX_comb),
        .store_data_EX_comb    (store_data_EX_comb),
        .mem_write_EX_comb     (mem_write_EX_comb),
        .mem_read_EX_comb      (mem_read_EX_comb),
        .store_control_EX_comb (store_control_EX_comb),
        .PCSrc_EX              (PCSrc_EX),
        .target_address_EX     (target_address_EX),
        .ALUOut_EXMEM          (ALUOut_EXMEM),
        .PC_plus4_EXMEM        (PC_plus4_EXMEM),
        .srcB_data_EXMEM       (srcB_data_EXMEM),
        .rd_EXMEM              (rd_EXMEM),
        .rs1_forward_compare   (rs1_forward_compare),
        .rs2_forward_compare   (rs2_forward_compare),
        .rd_hazard             (rd_hazard),
        .mem_write_EXMEM       (mem_write_EXMEM),
        .mem_read_EXMEM        (mem_read_EXMEM),
        .store_control_EXMEM   (store_control_EXMEM),
        .load_control_EXMEM    (load_control_EXMEM),
        .jump_EXMEM            (jump_EXMEM),
        .ResultSrc_EXMEM       (ResultSrc_EXMEM),
        .reg_write_EXMEM       (reg_write_EXMEM),
        .mem_write_hazard      (),
        .mem_read_hazard       (mem_read_hazard),
        .store_control_hazard  (),
        .load_control_hazard   ()
    );

    // Stage 4: Memory Access (MEM)
    memory_stage MEM_STAGE (
        .clk                   (clk),
        .rst                   (rst),
        .ALUOut_EX_comb        (ALUOut_EX_comb),
        .store_data_EX_comb    (store_data_EX_comb),
        .mem_write_EX_comb     (mem_write_EX_comb),
        .mem_read_EX_comb      (mem_read_EX_comb),
        .store_control_EX_comb (store_control_EX_comb),
        .ALUOut_EXMEM          (ALUOut_EXMEM),
        .PC_plus4_EXMEM        (PC_plus4_EXMEM),
        .rd_EXMEM              (rd_EXMEM),
        .load_control_EXMEM    (load_control_EXMEM),
        .jump_EXMEM            (jump_EXMEM),
        .ResultSrc_EXMEM       (ResultSrc_EXMEM),
        .reg_write_EXMEM       (reg_write_EXMEM),
        .wb_data_MEMWB         (wb_data_MEMWB),
        .rd_MEMWB              (rd_MEMWB),
        .reg_write_MEMWB       (reg_write_MEMWB)
    );

    // Stage 5: Writeback (WB)
    writeback_stage WB_STAGE (
        .wb_data_MEMWB (wb_data_MEMWB),
        .data_WB       (data_WB)
    );

    // Forwarding Unit (evaluated in ID and registered into ID/EX to break EX critical path)
    forward_unit FORWARDING_UNIT (
        .reg_write_EXMEM (reg_write_IDEX),
        .reg_write_MEMWB (reg_write_EXMEM),
        .rd_EXMEM        (rd_IDEX),
        .rd_MEMWB        (rd_EXMEM),
        .rs1_IDEX        (rs1_addr_ID),
        .rs2_IDEX        (rs2_addr_ID),
        .fwdA_EX         (fwdA_ID),
        .fwdB_EX         (fwdB_ID)
    );

    // Hazard Detection & Control-Hazard Flush Unit
    hazard_unit HAZARD_DETECTION (
        .instruction    (inst_hazard),
        .rd_IDEX        (rd_hazard),
        .mem_read_IDEX  (mem_read_hazard),
        .PCSrc_EX       (PCSrc_EX),
        .PCWrite        (PCWrite),
        .IF_ID_write    (IF_ID_write),
        .flush_IFID     (flush_IFID),
        .pipeline_flush (flush_IDEX)
    );

    // Debug outputs
    assign dbg_PC      = PC_IFID;
    assign dbg_INS     = inst_IFID;
    assign dbg_WB_data = data_WB;
    assign dbg_WB_rd   = rd_MEMWB;
    assign dbg_WB_wen  = reg_write_MEMWB;

endmodule
