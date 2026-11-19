module PC_target #(parameter WIDTH = 32) (
    input wire [WIDTH - 1:0] current_PC,
    input wire [WIDTH - 1:0] imm_ext,
    output wire [WIDTH - 1:0] target_PC
    );
    assign target_PC = current_PC + imm_ext;
endmodule