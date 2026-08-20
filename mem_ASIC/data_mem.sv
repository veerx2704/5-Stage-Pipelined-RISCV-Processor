module data_mem #(WIDTH = 32)(
    input wire [WIDTH-1:0] WData,
    input wire [WIDTH-1:2] addr,
    input wire clk,
    input wire mem_wen,
    input wire mem_ren,
    output wire [WIDTH-1:0] RData
);

//32 x 1024 MEMORY
wire [3:0] cs_en;

wire [31:0] rw_data[0:3];
wire [31:0] r_data[0:3];

reg [31:0] RData_reg;
	assign cs_en = 4'd1 << addr[11:10];	// Instead of using a decoder, it is much simpler to shift the enable bus by address value
						// If address[11:9] = 3, cs_en = 4'b1000 (1 << 3)


generate
genvar i;

	for(i = 0; i < 4; i++) begin: MEMORY_BANK	// 4 banks of 32 x 256 memories (8kb blocks)
		sram_memory_bank BANK ( .clk(clk), 
					.cs(cs_en[i]), 
					.we(mem_wen),
					.re(mem_ren),
					.WData(WData), 
					.Waddr(addr[9:2]), 
					.Raddr(addr[9:2]), 
					.RData_0(rw_data[i]),
					.RData_1(r_data[i]));
	end:MEMORY_BANK

endgenerate
	always @(posedge clk) RData_reg <= r_data[addr[11:10]];
	assign RData = RData_reg;	//take data from read port when read is needed, otherwise keep the data from read/write port
endmodule
