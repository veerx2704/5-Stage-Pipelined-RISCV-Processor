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
        output wire PCWrite,
        output wire IF_ID_write,
        output wire pipeline_flush
    );
    
    parameter I_Type = 7'b0010011;
    parameter S_Type = 7'b0100011;
    parameter R_Type = 7'b0110011;
    parameter B_Type = 7'b1100111;
    
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    
    //If mem read is needed, then all the instructions must be stalled from ID stage onwards.
    //Stall if the result of mem read is needed by one of the operands of the next instruction
    
    wire [6:0] opcode = instruction[6:0];
    reg flush_reg;
    always_comb begin
        flush_reg = 1'b0;
        case(opcode)
            I_Type: begin                                            //Previous instruction was load, current instruction is load or I-Type
                flush_reg = (rs1 == rd_IDEX && mem_read_IDEX );     //If the current source address is loaded from prev instr, stall
                                                                     //PCWrite = 1 -> operand independent from prev instruction, continuue normal operation
                                                                     //PCWrite = 0 -> operand dependent on prev load instruction, stall pipeline
            end
            S_Type: begin
                flush_reg = ((rs1 == rd_IDEX || rs2 == rd_IDEX) && mem_read_IDEX);   // Update PC if neither of the operands in the instruction is loaded from previous instruction
                                                                                        // or mem_read does not take place in prev instruction
            end
            R_Type: begin
                flush_reg = ((rs1 == rd_IDEX || rs2 == rd_IDEX) && mem_read_IDEX);   // Update PC if neither of the operands in the instruction is loaded from previous instruction
                                                                                        // or mem_read does not take place in prev instruction
            end
            B_Type: begin
                flush_reg = ((rs1 == rd_IDEX || rs2 == rd_IDEX) && mem_read_IDEX);   // Update PC if neither of the operands in the instruction is loaded from previous instruction
                                                                                        // or mem_read does not take place in prev instruction
            end
        endcase
    end
    assign PCWrite = ~flush_reg;        //Keep PCWrite at 1 for normal operations
    assign IF_ID_write = ~flush_reg;    //Keep write option as 1 for normal, 0 for no write (flush)
    assign pipeline_flush = flush_reg;  //Flush the pipeline when load follows dependent operand
endmodule
