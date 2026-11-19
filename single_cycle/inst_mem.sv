module inst_mem #(parameter WIDTH = 32, parameter MEM_INIT_FILE = "") (
    input wire [WIDTH - 1:2] PC,
    input wire rst,
    output wire [WIDTH - 1:0] decoded_I
    );
    
    reg [WIDTH - 1:0] INSTRUCTION_MEMORY [0:63];
    
    initial begin
        for (int i = 0; i < 64; i++) INSTRUCTION_MEMORY[i] = 32'h0000_0013; // NOP (ADDI x0, x0, 0)
        if (MEM_INIT_FILE != "") $readmemh(MEM_INIT_FILE, INSTRUCTION_MEMORY);
    end
    
    assign decoded_I = rst ? INSTRUCTION_MEMORY[PC[7:2]] : 32'h0000_0013;
    
endmodule
