module data_mem #(WIDTH = 32)(
    input wire [WIDTH-1:0] WData,
    input wire [WIDTH-1:2] addr,
    input wire clk,
    input wire mem_wen,
    input wire mem_ren,
    input wire [3:0] wmask,
    output wire [WIDTH-1:0] RData
);

// 32 x 1024 synchronous byte-enabled BRAM (maps to 1x RAMB36E1 on Kintex-7)
(* ram_style = "block" *)
reg [WIDTH-1:0] MEM [0:1023];
reg [WIDTH-1:0] rdata_q;

always @(posedge clk) begin
    if (mem_wen) begin
        if (wmask[0]) MEM[addr[11:2]][7:0]   <= WData[7:0];
        if (wmask[1]) MEM[addr[11:2]][15:8]  <= WData[15:8];
        if (wmask[2]) MEM[addr[11:2]][23:16] <= WData[23:16];
        if (wmask[3]) MEM[addr[11:2]][31:24] <= WData[31:24];
    end
    if (mem_ren)
        rdata_q <= MEM[addr[11:2]];
end

assign RData = rdata_q;

endmodule
