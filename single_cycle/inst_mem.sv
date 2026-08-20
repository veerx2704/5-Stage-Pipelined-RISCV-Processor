module inst_mem #(parameter WIDTH = 32) (
    input wire [WIDTH - 1:2] PC,
    input wire rst,
    output wire [WIDTH - 1:0] decoded_I
    );
    
    reg [WIDTH - 1:0] INSTRUCTION_MEMORY [0:63];
    
    initial begin
        $readmemh("C:\\VerilogHDL\\prep_practice\\RISCV\\instructions.txt", INSTRUCTION_MEMORY);
    end
    
    
    assign decoded_I = rst ? INSTRUCTION_MEMORY[PC] : 32'b0;
    
endmodule