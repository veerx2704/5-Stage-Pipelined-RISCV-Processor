module forward_unit (
    input wire reg_write_EXMEM,
    input wire reg_write_MEMWB,
    input wire [4:0] rd_EXMEM,
    input wire [4:0] rd_MEMWB,
    input wire [4:0] rs1_IDEX,
    input wire [4:0] rs2_IDEX,
    
    output wire [1:0] fwdA_EX,
    output wire [1:0] fwdB_EX
);

    assign fwdA_EX = (reg_write_EXMEM && (rd_EXMEM != 5'b0) && (rs1_IDEX == rd_EXMEM)) ? 2'b10 : // Result from EX/MEM (latest -> higher priority)
                     (reg_write_MEMWB && (rd_MEMWB != 5'b0) && (rs1_IDEX == rd_MEMWB)) ? 2'b01 : // Result from MEM/WB
                                                                                         2'b00 ;
    assign fwdB_EX = (reg_write_EXMEM && (rd_EXMEM != 5'b0) && (rs2_IDEX == rd_EXMEM)) ? 2'b10 : // Result from EX/MEM (latest -> higher priority)
                     (reg_write_MEMWB && (rd_MEMWB != 5'b0) && (rs2_IDEX == rd_MEMWB)) ? 2'b01 : // Result from MEM/WB
                                                                                         2'b00 ;
endmodule
