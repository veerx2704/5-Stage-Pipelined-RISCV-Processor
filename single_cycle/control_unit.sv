module control_unit(
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire funct7_b5,
    input wire zero,
    input wire LT,
    input wire LTU,
    output wire [3:0] ALUCode,
    output wire [2:0] load_control,
    output wire [1:0] imm_src,
    output wire [1:0] store_control,
    output wire ALUSrc,
    output wire mem_write,
    output wire mem_read,
    output wire reg_write,
    output wire u_type,
    output wire ResultSrc,
    output wire PCSrc,
    output wire jump
);
    wire branch;
    wire PC_src_branch;
    main_decoder MAIN_DECODER(  .opcode,
                                .funct3,
                                .mem_write,
                                .mem_read,
                                .branch,
                                .reg_write,
                                .jump,
                                .u_type,
                                .imm_src,
                                .store_control,
                                .load_control,
                                .ResultSrc);
    alu_decoder ALU_DECODER(    .opcode,
                                .funct3,
                                .funct7_b5,
                                .ALUCode,
                                .ALUSrc);
    
    branch_decoder BRANCH_DECODER( .branch(branch),
                                   .funct3(funct3),
                                   .LT(LT),
                                   .LTU(LTU),
                                   .zero(zero),
                                   .PC_src(PC_src_branch));
    assign PCSrc = PC_src_branch | jump;
endmodule