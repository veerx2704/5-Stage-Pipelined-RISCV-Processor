module ALU #(parameter WIDTH = 32) (
    input wire [WIDTH-1:0] DataA,
    input wire [WIDTH-1:0] DataB,
    input wire [3:0] ALUCode,
    output wire [WIDTH-1:0] ALU_out,
    output wire zero,
    output wire LT,
    output wire LTU
);
wire overflow;
reg [WIDTH-1:0] computed_out;
wire [WIDTH-1:0] InvB = (ALUCode == 4'b0000) ? DataB : ~DataB;         // We only need addition during 4'b0000.
                                                                       //In all other cases, we need subtraction to calculate LT and LTU
wire Cin = (ALUCode == 4'b0000) ? 1'b0 : 1'b1;
wire [WIDTH-1:0] sum;
wire cout;

wire SLT;
wire SLTU;

adder #(.WIDTH(WIDTH)) ADD_SUB_BLOCK (.SrcA(DataA), .SrcB(InvB), .Cin(Cin), .Sum(sum), .Cout(cout));     //if ALUCode == 4'b0000 -> do add otherwise only subtract
                                                                                                         //DataA < DataB if cout = 0 (unsigned)
                                                                                                         // DataA >= DataB if cout = 1 (unsigned)



always_comb begin
    case(ALUCode)
        4'b0000: computed_out = sum;                                  //add or address offset in load/store instructions
        4'b0001: computed_out = sum;                                  //sub 
        4'b0111: computed_out = DataA & DataB;                        //and
        4'b0011: computed_out = DataA | DataB;                        //or
        4'b0010: computed_out = DataA ^ DataB;                        //xor
        4'b0100: computed_out = {{(WIDTH-1){1'b0}},SLT};              //slt
        4'b0110: computed_out = {{(WIDTH-1){1'b0}},SLTU};             //sltu
        4'b0101: computed_out = DataA << DataB;                       //sll
        4'b1101: computed_out = DataA >> DataB;                       //srl
        4'b1100: computed_out = DataA >>> DataB;                      //sra
        4'b1000: computed_out = {{DataB[WIDTH-1:WIDTH-20]},12'b0};    //lui
        //4'b1110: computed_out = sum;                                        
        default: computed_out = 'x;
    endcase
end
assign overflow = (ALUCode == 4'b0000) ? (~(DataA[31] ^ DataB[31]) & (DataA[31] ^ sum[31])) : //IN ADDITION, V = 1 WHEN A AND B HAVE SAME SIGN BUT RESULT HAS DIFFERENT SIGN
                                         ((DataA[31] ^ DataB[31]) & (DataA[31] ^ sum[31]));   //IN SUBTRACTION, V = 1 WHEN RESULT AND B HAVE SAME SIGN BUT A HAS DIFFERENT SIGN  

assign SLT = sum[31] ^ overflow;
assign SLTU = ~cout;
assign ALU_out = computed_out;
assign zero = computed_out == 0;                              //if sum is zero, the condition holds for beq, otherwise for BNE
assign LT = SLT;                                              //for BLT
assign LTU = SLTU;                                            //for BLTU

endmodule