`timescale 1ns / 1ps

module tb_forward_unit;
    logic       reg_write_EXMEM;
    logic       reg_write_MEMWB;
    logic [4:0] rd_EXMEM;
    logic [4:0] rd_MEMWB;
    logic [4:0] rs1_IDEX;
    logic [4:0] rs2_IDEX;
    wire  [1:0] fwdA_EX;
    wire  [1:0] fwdB_EX;

    int pass_count = 0;
    int fail_count = 0;

    forward_unit dut (.*);

    task automatic check(input string name, input logic [1:0] expA, input logic [1:0] expB);
        #1;
        if (fwdA_EX === expA && fwdB_EX === expB) begin
            $display("[PASS] %s (fwdA=%b fwdB=%b)", name, fwdA_EX, fwdB_EX);
            pass_count++;
        end else begin
            $display("[FAIL] %s (expA=%b gotA=%b, expB=%b gotB=%b)", name, expA, fwdA_EX, expB, fwdB_EX);
            fail_count++;
        end
    endtask

    initial begin
        // Case 1: No forwarding when reg_write=0
        reg_write_EXMEM = 0; reg_write_MEMWB = 0;
        rd_EXMEM = 5'd5; rd_MEMWB = 5'd6; rs1_IDEX = 5'd5; rs2_IDEX = 5'd6;
        check("No forwarding when reg_write=0", 2'b00, 2'b00);

        // Case 2: EX/MEM forwards to A, MEM/WB forwards to B
        reg_write_EXMEM = 1; reg_write_MEMWB = 1;
        check("EX/MEM -> A (10), MEM/WB -> B (01)", 2'b10, 2'b01);

        // Case 3: EX/MEM takes priority over MEM/WB when both match same reg
        rd_EXMEM = 5'd10; rd_MEMWB = 5'd10; rs1_IDEX = 5'd10; rs2_IDEX = 5'd10;
        check("EX/MEM priority over MEM/WB", 2'b10, 2'b10);

        // Case 4: Full 5-bit compare (same LSB, different upper bits -> must NOT forward)
        rd_EXMEM = 5'd3; rd_MEMWB = 5'd5; rs1_IDEX = 5'd1; rs2_IDEX = 5'd7;
        check("5-bit compare rejects LSB-only match", 2'b00, 2'b00);

        // Case 5: x0 (5'd0) must NEVER be forwarded
        rd_EXMEM = 5'd0; rd_MEMWB = 5'd0; rs1_IDEX = 5'd0; rs2_IDEX = 5'd0;
        check("x0 never forwarded", 2'b00, 2'b00);

        $display("tb_forward_unit Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count != 0) $fatal(1, "tb_forward_unit FAILED");
        $finish;
    end
endmodule
