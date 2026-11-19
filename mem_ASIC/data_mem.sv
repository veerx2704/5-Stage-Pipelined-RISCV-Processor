module data_mem #(WIDTH = 32)(
    input wire [WIDTH-1:0] WData,
    input wire [WIDTH-1:2] addr,
    input wire clk,
    input wire mem_wen,
    input wire mem_ren,
    input wire [3:0] wmask,
    output wire [WIDTH-1:0] RData
);

//32 x 1024 MEMORY
wire [3:0] cs_en;

wire [31:0] r_data[0:3];

reg [1:0] bank_sel_q;
	assign cs_en = 4'd1 << addr[11:10];	// Instead of using a decoder, it is much simpler to shift the enable bus by address value
						// If address[11:9] = 3, cs_en = 4'b1000 (1 << 3)


generate
genvar i;

	for(i = 0; i < 4; i++) begin: MEMORY_BANK	// 4 banks of 32 x 256 memories (8kb blocks)
		sram_memory_bank BANK ( .clk(clk), 
					.cs(cs_en[i]), 
					.we(mem_wen),
					.re(mem_ren),
					.wmask(wmask),
					.WData(WData), 
					.Waddr(addr[9:2]), 
					.Raddr(addr[9:2]), 
					.RData_0(),
					.RData_1(r_data[i]));
	end:MEMORY_BANK

endgenerate
	always @(posedge clk) bank_sel_q <= addr[11:10];
	assign RData = r_data[bank_sel_q];
endmodule
