module PC_target #(parameter WIDTH = 32) (
    input wire [WIDTH - 1:0] current_PC,
    input wire [WIDTH - 1:0] imm_ext,
    output wire [WIDTH - 1:0] target_PC
    );
    wire overflow;
    adder PC_NEXT_ADDRESS(.SrcA(current_PC), .SrcB(imm_ext), .Cin(1'b0), .Sum(target_PC), .Cout(overflow));
endmodule