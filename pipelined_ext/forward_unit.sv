module forward_unit (
    input wire reg_write_EXMEM,
    input wire reg_write_MEMWB,
    input wire rd_EXMEM,
    input wire rd_MEMWB,
    input wire rs1_IDEX,
    input wire rs2_IDEX,
    
    output wire [1:0] fwdA_EX,
    output wire [1:0] fwdB_EX
);

    assign fwdA = (rs1_IDEX == rd_EXMEM && reg_write_EXMEM) ? 2'b10 :                //Result comes from previous ALU output (latest -> more priority)
                  (rs1_IDEX == rd_MEMWB && reg_write_MEMWB) ? 2'b01 :                //Result comes from data memory or an earlier ALU output
                                                              2'b00 ;
    assign fwdB = (rs2_IDEX == rd_EXMEM && reg_write_EXMEM) ? 2'b10 :                //Result comes from previous ALU output (latest -> more priority)
                  (rs2_IDEX == rd_MEMWB && reg_write_MEMWB) ? 2'b01 :                //Result comes from data memory or an earlier ALU output
                                                              2'b00 ;                  
endmodule