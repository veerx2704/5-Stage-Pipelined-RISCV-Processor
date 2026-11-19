module adder #(parameter WIDTH = 32) (
    input wire [WIDTH-1:0] SrcA,
    input wire [WIDTH-1:0] SrcB,
    input wire Cin,
    output wire [WIDTH-1:0] Sum,
    output wire Cout
);

assign {Cout, Sum} = {1'b0, SrcA} + {1'b0, SrcB} + {{WIDTH{1'b0}}, Cin};

endmodule
