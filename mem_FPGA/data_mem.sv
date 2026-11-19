module data_mem #(WIDTH = 32)(
    input wire [WIDTH-1:0] WData,
    input wire [WIDTH-1:2] addr,
    input wire clk,
    input wire mem_wen,
    input wire mem_ren,
    output wire [WIDTH-1:0] RData
);

// 32 x 1024 synchronous BRAM (maps to 1x RAMB36E1 on Kintex-7)
(* ram_style = "block" *)
reg [WIDTH-1:0] MEM [0:1023];
reg [WIDTH-1:0] rdata_q;

always @(posedge clk) begin
    if (mem_wen)
        MEM[addr[11:2]] <= WData;
    if (mem_ren)
        rdata_q <= MEM[addr[11:2]];
end

assign RData = rdata_q;

endmodule
