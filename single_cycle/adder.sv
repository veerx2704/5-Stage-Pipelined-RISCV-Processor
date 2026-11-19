module adder #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] SrcA,
    input  wire [WIDTH-1:0] SrcB,
    input  wire             Cin,
    output wire [WIDTH-1:0] Sum,
    output wire             Cout
);

    // Stage 0: bit-level propagate & generate (folding Cin into bit 0)
    wire [WIDTH-1:0] p0 = SrcA ^ SrcB;
    wire [WIDTH-1:0] g0;
    assign g0[0]         = (SrcA[0] & SrcB[0]) | (p0[0] & Cin);
    assign g0[WIDTH-1:1] = SrcA[WIDTH-1:1] & SrcB[WIDTH-1:1];

    // 5-stage Kogge-Stone parallel-prefix tree (distances 1, 2, 4, 8, 16)
    wire [WIDTH-1:0] g1, p1, g2, p2, g3, p3, g4, p4, g5;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : KS_S1
            if (i >= 1) begin : g_op
                assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign p1[i] = p0[i] & p0[i-1];
            end else begin : g_pass
                assign g1[i] = g0[i];
                assign p1[i] = p0[i];
            end
        end

        for (i = 0; i < WIDTH; i = i + 1) begin : KS_S2
            if (i >= 2) begin : g_op
                assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
                assign p2[i] = p1[i] & p1[i-2];
            end else begin : g_pass
                assign g2[i] = g1[i];
                assign p2[i] = p1[i];
            end
        end

        for (i = 0; i < WIDTH; i = i + 1) begin : KS_S3
            if (i >= 4) begin : g_op
                assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
                assign p3[i] = p2[i] & p2[i-4];
            end else begin : g_pass
                assign g3[i] = g2[i];
                assign p3[i] = p2[i];
            end
        end

        for (i = 0; i < WIDTH; i = i + 1) begin : KS_S4
            if (i >= 8) begin : g_op
                assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
                assign p4[i] = p3[i] & p3[i-8];
            end else begin : g_pass
                assign g4[i] = g3[i];
                assign p4[i] = p3[i];
            end
        end

        for (i = 0; i < WIDTH; i = i + 1) begin : KS_S5
            if (i >= 16) begin : g_op
                assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
            end else begin : g_pass
                assign g5[i] = g4[i];
            end
        end
    endgenerate

    assign Sum[0]         = p0[0] ^ Cin;
    assign Sum[WIDTH-1:1] = p0[WIDTH-1:1] ^ g5[WIDTH-2:0];
    assign Cout           = g5[WIDTH-1];

endmodule
