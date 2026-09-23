module dynamic_branch_prediction (
    input wire [31:0] PC,
    input wire [31:0] instruction,
    input wire LT,
    input wire LTU,
    input wire zero,
    output wire PCSrc
);
    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire funct7_b5 = instruction[30];
    wire branch;
    wire branch_act_taken;
    wire jump;
    branch_decoder BRANCH_ACTUAL( .branch(branch),
                                   .funct3(funct3),
                                   .LT(LT),
                                   .LTU(LTU),
                                   .zero(zero),
                                   .PC_src(branch_act_taken));
                                   
    assign jump = (opcode == 7'b1101111);
    assign PCSrc = branch_act_taken | jump;


endmodule
