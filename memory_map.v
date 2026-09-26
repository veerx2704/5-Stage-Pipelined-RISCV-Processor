module $__SKY130_SRAM_8X1024_1RW1R #(
    parameter ABITS = 10,
    parameter WIDTH = 8,
    parameter [8191:0] INIT = 8192'b0
) (
    input  [ABITS-1:0] PORT_RW_ADDR,
    input  [WIDTH-1:0] PORT_RW_WR_DATA,
    input              PORT_RW_WR_EN,
    output [WIDTH-1:0] PORT_RW_RD_DATA,
    input              PORT_RW_CLK,

    input  [ABITS-1:0] PORT_R_ADDR,
    output [WIDTH-1:0] PORT_R_RD_DATA,
    input              PORT_R_CLK
);

    sky130_sram_1kbyte_1rw1r_8x1024_8 sram (
        .clk0    (PORT_RW_CLK),
        .csb0    (1'b0),
        .web0    (~PORT_RW_WR_EN),
        .wmask0  (1'b1),
        .addr0   (PORT_RW_ADDR),
        .din0    (PORT_RW_WR_DATA),
        .dout0   (PORT_RW_RD_DATA),

        .clk1    (PORT_R_CLK),
        .csb1    (1'b0),
        .addr1   (PORT_R_ADDR),
        .dout1   (PORT_R_RD_DATA)
    );

endmodule
