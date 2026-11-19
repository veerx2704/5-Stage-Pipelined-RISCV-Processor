module reg_file #(parameter WIDTH = 32, parameter MEM_INIT_FILE = "", localparam ADDR = 5) (
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
    for (int i = 0; i < 32; i++) REGISTER_FILE[i] = '0;
    if (MEM_INIT_FILE != "") $readmemh(MEM_INIT_FILE, REGISTER_FILE);
end

always_ff @(posedge clk) begin
    if (Wen && (DestC != 5'b0)) REGISTER_FILE[DestC] <= WData;
end

// x0 hardwired to 0; WB-to-ID write-through bypass for 3-cycle-apart hazards
assign RDataA = (SrcA == 5'b0) ? '0 :
                (Wen && (DestC == SrcA)) ? WData : REGISTER_FILE[SrcA];
assign RDataB = (SrcB == 5'b0) ? '0 :
                (Wen && (DestC == SrcB)) ? WData : REGISTER_FILE[SrcB];

endmodule
