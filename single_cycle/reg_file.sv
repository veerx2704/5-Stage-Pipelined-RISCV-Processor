module reg_file #(parameter WIDTH = 32, localparam ADDR = 5) (
    input wire clk,
    input wire [ADDR-1:0] SrcA,
    input wire [ADDR-1:0] SrcB,
    input wire [ADDR-1:0] DestC,
    input wire [WIDTH-1:0] WData,
    input wire Wen,
    output wire [WIDTH-1:0] RDataA,
    output wire [WIDTH-1:0] RDataB
);

reg [WIDTH-1:0] REGISTER_FILE[0:31];

    initial begin
        $readmemh("C:\\VerilogHDL\\prep_practice\\RISCV\\initial_reg.txt", REGISTER_FILE);
    end


always_ff @(posedge clk) begin
    if(Wen) REGISTER_FILE[DestC] <= WData;
end

assign RDataA = REGISTER_FILE[SrcA];
assign RDataB = REGISTER_FILE[SrcB];

endmodule