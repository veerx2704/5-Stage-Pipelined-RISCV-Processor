module ALU #(parameter WIDTH = 32) (
    input wire [WIDTH-1:0] DataA,
    input wire [WIDTH-1:0] DataB,
    input wire [3:0] ALUCode,
    output wire [WIDTH-1:0] ALU_out,
    output wire [WIDTH-1:0] sum_out,
    output wire zero,
    output wire LT,
    output wire LTU
);
wire overflow;
reg [WIDTH-1:0] computed_out;
wire sub_en = |ALUCode;
wire [WIDTH-1:0] InvB = sub_en ? ~DataB : DataB;                       // We only need addition during 4'b0000.
                                                                       // In all other cases, we need subtraction to calculate LT and LTU
wire Cin = sub_en;
wire [WIDTH-1:0] sum;
wire cout;

wire SLT;
wire SLTU;

// Shared 5-bit barrel shifter (bit-reversed input/output for SLL)
wire [4:0] shamt = DataB[4:0];
wire is_sll = (ALUCode == 4'b0101);
wire is_sra = (ALUCode == 4'b1100);
wire [WIDTH-1:0] shift_in;
wire [WIDTH-1:0] shift_res_raw;
wire [WIDTH-1:0] shift_res;
genvar b;
generate
    for (b = 0; b < WIDTH; b = b + 1) begin : BIT_REV
        assign shift_in[b]  = is_sll ? DataA[WIDTH-1-b] : DataA[b];
        assign shift_res[b] = is_sll ? shift_res_raw[WIDTH-1-b] : shift_res_raw[b];
    end
endgenerate
assign shift_res_raw = $signed({is_sra & DataA[WIDTH-1], shift_in}) >>> shamt;

adder #(.WIDTH(WIDTH)) ADD_SUB_BLOCK (.SrcA(DataA), .SrcB(InvB), .Cin(Cin), .Sum(sum), .Cout(cout));     //if ALUCode == 4'b0000 -> do add otherwise only subtract
                                                                                                         //DataA < DataB if cout = 0 (unsigned)
                                                                                                         //DataA >= DataB if cout = 1 (unsigned)

always_comb begin
    case(ALUCode)
        4'b0000: computed_out = sum;                                  //add or address offset in load/store instructions
        4'b0001: computed_out = sum;                                  //sub 
        4'b0111: computed_out = DataA & DataB;                        //and
        4'b0011: computed_out = DataA | DataB;                        //or
        4'b0010: computed_out = DataA ^ DataB;                        //xor
        4'b0100: computed_out = {{(WIDTH-1){1'b0}},SLT};              //slt
        4'b0110: computed_out = {{(WIDTH-1){1'b0}},SLTU};             //sltu
        4'b0101, 4'b1101, 4'b1100: computed_out = shift_res;          //sll, srl, sra
        4'b1000: computed_out = DataB;                                //lui (already shifted in imm_extend)
        default: computed_out = '0;
    endcase
end
assign overflow = (DataA[WIDTH-1] ^ DataB[WIDTH-1]) & (DataA[WIDTH-1] ^ sum[WIDTH-1]); // Subtraction overflow for SLT

assign SLT = sum[WIDTH-1] ^ overflow;
assign SLTU = ~cout;
assign ALU_out = computed_out;
assign sum_out = sum;
assign zero = (DataA == DataB);                               // Parallel equality check for BEQ/BNE
assign LT = SLT;                                              // for BLT
assign LTU = SLTU;                                            // for BLTU

endmodule
