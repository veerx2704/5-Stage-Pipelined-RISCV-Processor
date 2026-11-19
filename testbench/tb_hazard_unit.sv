`timescale 1ns / 1ps

module tb_hazard_unit;
    logic [31:0] instruction;
    logic [4:0]  rd_IDEX;
    logic        mem_read_IDEX;
    wire         PCWrite;
    wire         IF_ID_write;
    wire         pipeline_flush;

    int pass_count = 0;
    int fail_count = 0;

    hazard_unit dut (.*);

    task automatic check(input string name, input logic exp_stall);
        #1;
        if (pipeline_flush === exp_stall && PCWrite === ~exp_stall && IF_ID_write === ~exp_stall) begin
            $display("[PASS] %s (stall=%b)", name, pipeline_flush);
            pass_count++;
        end else begin
            $display("[FAIL] %s (exp_stall=%b, flush=%b PCWrite=%b IF_ID_write=%b)",
                     name, exp_stall, pipeline_flush, PCWrite, IF_ID_write);
            fail_count++;
        end
    endtask

    initial begin
        mem_read_IDEX = 1'b1;
        rd_IDEX       = 5'd5;

        // R-type using rs2=x5 -> stall
        instruction = {7'b0, 5'd5, 5'd1, 3'b000, 5'd3, 7'b0110011};
        check("Load-use stall on R-Type (rs2 match)", 1'b1);

        // Load (7'b0000011) using rs1=x5 -> stall (previously missing!)
        instruction = {12'd0, 5'd5, 3'b010, 5'd6, 7'b0000011};
        check("Load-use stall on Load (L_Type rs1 match)", 1'b1);

        // JALR (7'b1100111) using rs1=x5 -> stall
        instruction = {12'd0, 5'd5, 3'b000, 5'd1, 7'b1100111};
        check("Load-use stall on JALR (rs1 match)", 1'b1);

        // B-Type (7'b1100011) using rs2=x5 -> stall (previously wrong opcode 103!)
        instruction = {7'b0, 5'd5, 5'd2, 3'b000, 5'd0, 7'b1100011};
        check("Load-use stall on B-Type (opcode 7'b1100011)", 1'b1);

        // Independent instruction -> no stall
        instruction = {7'b0, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
        check("No stall on independent R-Type", 1'b0);

        // Load to x0 (rd_IDEX=0) -> must NOT stall
        rd_IDEX     = 5'd0;
        instruction = {7'b0, 5'd0, 5'd0, 3'b000, 5'd3, 7'b0110011};
        check("No false stall when rd_IDEX == x0", 1'b0);

        // Non-load in EX (mem_read_IDEX=0) -> no stall
        mem_read_IDEX = 1'b0;
        rd_IDEX       = 5'd5;
        instruction   = {7'b0, 5'd5, 5'd1, 3'b000, 5'd3, 7'b0110011};
        check("No stall when mem_read_IDEX == 0", 1'b0);

        $display("tb_hazard_unit Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count != 0) $fatal(1, "tb_hazard_unit FAILED");
        $finish;
    end
endmodule
