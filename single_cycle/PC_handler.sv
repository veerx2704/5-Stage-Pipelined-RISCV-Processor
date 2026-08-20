module PC_handler #(WIDTH = 32) (
    input wire [WIDTH-1:0] PC_addr,
    input wire clk,
    input wire rst,
    output wire [WIDTH-1:0] next_PC
    );
    
    reg [WIDTH-1:0] next_PC_reg;
    
    always @(posedge clk) begin
        if(!rst) next_PC_reg <= '0;
        else next_PC_reg <= PC_addr;
    end
    
    assign next_PC = next_PC_reg;
endmodule