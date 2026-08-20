//module adder #(parameter WIDTH = 32) (
//    input wire [WIDTH-1:0] in0,
//    input wire [WIDTH-1:0] in1,
//    input wire Cin,
//    output wire [WIDTH-1:0] sum,
//    output wire Cout
//);

//wire [WIDTH-1:0] G_stage0;
//wire [WIDTH-1:0] P_stage0;
//wire [WIDTH-1:0] G_stage1;
//wire [WIDTH-1:0] P_stage1;
//wire [WIDTH-1:0] G_stage2;
//wire [WIDTH-1:0] P_stage2;
//wire [WIDTH-1:0] G_stage3;
//wire [WIDTH-1:0] P_stage3;
//wire [WIDTH-1:0] G_stage4;
//wire [WIDTH-1:0] P_stage4;
//wire [WIDTH-1:0] G_stage5;
//wire [WIDTH-1:0] P_stage5;
//wire [WIDTH-1:0] G_stage6;
//wire [WIDTH-1:0] P_stage6;
//wire [WIDTH-1:0] G_stage7;
//wire [WIDTH-1:0] P_stage7;
//wire [WIDTH:0] Carry;




//generate
//genvar index;
//    // PRE PROCESSING STAGE
//    assign G_stage0 = in0 & in1;
//    assign P_stage0 = in0 ^ in1;
    
    
//    //STAGE 1
//    gray_cell GRAY_CELL_1(.Gi(G_stage0[0]), .Pj(P_stage0[1]), .Gj(G_stage0[1]), .Gji(G_stage1[1]));
//    assign G_stage1[0] = G_stage0[0];
//    assign P_stage1[1:0] = P_stage0[1:0];
//    for(index = 3; index < WIDTH ; index = index+2) begin: STAGE_1
//        black_cell BLACK_CELL (.Gi(G_stage0[index-1]),
//                               .Pi(P_stage0[index-1]),
//                               .Gj(G_stage0[index]),
//                               .Pj(P_stage0[index]),
//                               .Gji(G_stage1[index]),
//                               .Pij(P_stage1[index]));
//        assign G_stage1[index-1] = G_stage0[index-1];
//        assign P_stage1[index-1] = P_stage0[index-1];
//    end:STAGE_1
    
    
//    //STAGE 2
//    gray_cell GRAY_CELL_2(.Gi(G_stage1[1]), .Pj(P_stage1[3]), .Gj(G_stage1[3]), .Gji(G_stage2[3]));
//    assign G_stage2[2:0] = G_stage1[2:0];
//    assign P_stage2[3:0] = P_stage1[3:0];
//    for (index = 7; index < WIDTH; index = index + 4) begin: STAGE_2
//        black_cell BLACK_CELL (.Gi(G_stage1[index-2]), 
//                               .Pi(P_stage1[index-2]), 
//                               .Gj(G_stage1[index]), 
//                               .Pj(P_stage1[index]), 
//                               .Gji(G_stage2[index]), 
//                               .Pij(P_stage2[index]));
//        assign G_stage2[index-1:index-3] = G_stage1[index-1:index-3];
//        assign P_stage2[index-1:index-3] = P_stage1[index-1:index-3];
//    end:STAGE_2
    
    
//    //STAGE 3
//    gray_cell GRAY_CELL_3 (.Gi(G_stage2[3]), .Pj(P_stage2[7]), .Gj(G_stage2[7]), .Gji(G_stage3[7]));
//    assign G_stage3[6:0] = G_stage2[6:0];
//    assign P_stage3[7:0] = P_stage2[7:0];
    
//    for(index = 11; index < WIDTH; index = index + 4) begin : STAGE_3
//        black_cell BLACK_CELL (.Gi(G_stage2[index-4]),
//                               .Pi(P_stage2[index-4]),
//                               .Pj(P_stage2[index]),
//                               .Gj(G_stage2[index]),
//                               .Gji(G_stage3[index]),
//                               .Pij(P_stage3[index]));
//        assign G_stage3[index-1:index-3] = G_stage2[index-1:index-3];
//        assign P_stage3[index-1:index-3] = P_stage2[index-1:index-3];
//    end: STAGE_3
    
    
//    //STAGE 4
//    gray_cell GRAY_CELL_4 (.Gi(G_stage3[7]), .Pj(P_stage3[15]), .Gj(G_stage3[15]), .Gji(G_stage4[15]));
//    gray_cell GRAY_CELL_4_1 (.Gi(G_stage3[3]), .Pj(P_stage3[11]), .Gj(G_stage3[11]), .Gji(G_stage4[11]));
//    assign G_stage4[14:12] = G_stage3[14:12];
//    assign G_stage4[10:0] = G_stage3[10:0];
//    assign P_stage4[15:0] = P_stage3[15:0];
    
//    for(index = 19; index < WIDTH; index=index + 4) begin: STAGE_4
//        black_cell BLACK_CELL (.Gi(G_stage3[index-8]),
//                               .Pi(P_stage3[index-8]),
//                               .Gj(G_stage3[index]),
//                               .Pj(P_stage3[index]),
//                               .Gji(G_stage4[index]),
//                               .Pij(P_stage4[index]));
//        assign G_stage4[index-1:index-3] = G_stage3[index-1:index-3];
//        assign P_stage4[index-1:index-3] = P_stage3[index-1:index-3];
//    end: STAGE_4
    
    
//    //STAGE 5
//    assign G_stage5[15:0] = G_stage4[15:0];
//    assign P_stage5 = P_stage4;
//    for (index = 19; index < WIDTH; index = index + 4) begin: STAGE_5
//        gray_cell GRAY_CELL (.Gi(G_stage4[index-8]), .Pj(P_stage4[index]), .Gj(G_stage4[index]), .Gji(G_stage5[index]));
//        assign G_stage5[index-1:index-3] = G_stage4[index-1:index-3];
//    end:STAGE_5
    
    
//    //STAGE 6
//    assign P_stage6 = P_stage5;
//    assign G_stage6[3:0] = G_stage5[3:0];
//    assign G_stage6[31:30] = G_stage5[31:30];
//    for (index = 5; index < WIDTH; index = index + 4) begin: STAGE_6
//        gray_cell GRAY_CELL (.Gi(G_stage5[index-2]), .Pj(P_stage5[index]), .Gj(G_stage5[index]), .Gji(G_stage6[index]));
//        assign G_stage6[index-1:index-3] = G_stage5[index-1:index-3];
//    end:STAGE_6
    
    
    
//    //STAGE 7
//    assign P_stage7 = P_stage6;
//    assign G_stage7[0] = G_stage6[0];
//    assign G_stage7[31] = G_stage6[31];
//    for (index = 2; index < WIDTH; index = index + 2) begin : STAGE_7
//        gray_cell GRAY_CELL(.Gi(G_stage6[index-1]), .Pj(P_stage6[index]), .Gj(G_stage6[index]), .Gji(G_stage7[index]));
//        assign G_stage7[index-1] = G_stage6[index-1];
//    end: STAGE_7
    
//    //POST PROCESSING
//        assign Carry[0] = Cin;
//        assign Carry[WIDTH:1] = G_stage7 | (P_stage7 & {(WIDTH){Cin}});
//        assign Cout = Carry[WIDTH];
//        assign sum = P_stage7 ^ Carry[WIDTH:1];
//endgenerate
//endmodule


module adder #(parameter WIDTH = 32) (
    input wire [WIDTH-1:0] SrcA,
    input wire [WIDTH-1:0] SrcB,
    input wire Cin,
    output wire [WIDTH-1:0] Sum,
    output wire Cout
);

wire [31:0] G;
wire [31:0] P;
wire [32:0] C;
assign C[0] = Cin;
generate
    genvar i;
    for (i = 0; i < 32; i++) begin : CARRY_LOOKAHEAD_STAGE
        assign G[i] = SrcA[i] & SrcB[i];
        assign P[i] = SrcA[i] ^ SrcB[i];
        assign C[i+1] = G[i] | (P[i] & C[i]);
        assign Sum[i] = P[i] ^ C[i];
    end : CARRY_LOOKAHEAD_STAGE
endgenerate
assign Cout = C[32];

//assign {Cout, Sum} = SrcA + SrcB + Cin;

endmodule