module data_mem #(WIDTH = 32)(
    input wire [WIDTH-1:0] WData,
    input wire [WIDTH-1:2] addr,
    input wire clk,
    input wire mem_wen,
    input wire mem_ren,
    output wire [WIDTH-1:0] RData
);

//32 x 1024 MEMORY
wire [7:0] cs_en;
wire [31:0] bank_rdata[0:7];

	assign cs_en = 8'd1 << addr[11:9];	// Instead of using a decoder, it is much simpler to shift the enable bus by address value
						// If address[11:9] = 4, cs_en = 8'b00010000 (1 << 4)


generate
genvar i;

	for(i = 0; i < 8; i++) begin: MEMORY_BANK
		memory_bank_32_x_128 BANK (.clk(clk), .cs(cs_en[i]), .we(mem_wen), .WData(WData), .Waddr(addr[8:2]), .Raddr(addr[8:2]), .RData(bank_rdata[i]));
	end:MEMORY_BANK

endgenerate
	assign RData = mem_ren ? bank_rdata[addr[11:9]] : 32'b0;
endmodule