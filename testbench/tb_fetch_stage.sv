`timescale 1ns / 1ps

module tb_fetch_stage;
    logic        clk = 1'b0;
    logic        rst;
    logic        PCWrite;
    logic        IF_ID_write;
    logic        PCSrc;
    logic [31:0] target_address;
    wire  [31:0] PC_IFID;
    wire  [31:0] inst_IFID;

    int pass_count = 0;
    int fail_count = 0;

    fetch_stage dut (
        .clk            (clk),
        .rst            (rst),
        .PCWrite        (PCWrite),
        .IF_ID_write    (IF_ID_write),
        .PCSrc          (PCSrc),
        .target_address (target_address),
        .PC_IFID        (PC_IFID),
        .inst_IFID      (inst_IFID)
    );

    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            $display("[PASS] %s", name);
            pass_count++;
        end else begin
            $display("[FAIL] %s (PC_IFID=0x%08h inst_IFID=0x%08h)", name, PC_IFID, inst_IFID);
            fail_count++;
        end
    endtask

    initial begin
        // Preload instruction memory with recognizable words
        for (int i = 0; i < 64; i++)
            dut.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[i] = 32'hA000_0000 + i;

        rst            = 1'b0;
        PCWrite        = 1'b1;
        IF_ID_write    = 1'b1;
        PCSrc          = 1'b0;
        target_address = 32'h0000_0020;

        repeat (2) @(posedge clk);
        #1;
        check("Reset clears PC_IFID and inst_IFID", PC_IFID === 32'h0 && inst_IFID === 32'h0);

        // Release reset -> Cycle 1 captures PC=0x0 & inst[0] into IF/ID, PC advances to 0x4
        @(negedge clk);
        rst = 1'b1;
        @(posedge clk);
        #1;
        check("Cycle 1: PC_IFID=0x0, inst_IFID=inst[0]", PC_IFID === 32'h0000_0000 && inst_IFID === 32'hA000_0000);

        // Cycle 2: PC_IFID=0x4, inst_IFID=inst[1]
        @(posedge clk);
        #1;
        check("Cycle 2: PC_IFID=0x4, inst_IFID=inst[1]", PC_IFID === 32'h0000_0004 && inst_IFID === 32'hA000_0001);

        // Stall for 2 cycles (PCWrite=0, IF_ID_write=0) -> must HOLD 0x4 and inst[1], NOT reset to 0!
        @(negedge clk);
        PCWrite     = 1'b0;
        IF_ID_write = 1'b0;
        @(posedge clk);
        #1;
        check("Stall cycle 1 holds PC_IFID=0x4 & inst[1]", PC_IFID === 32'h0000_0004 && inst_IFID === 32'hA000_0001);
        @(posedge clk);
        #1;
        check("Stall cycle 2 holds PC_IFID=0x4 & inst[1]", PC_IFID === 32'h0000_0004 && inst_IFID === 32'hA000_0001);

        // Resume -> should fetch PC=0x8 (inst[2])
        @(negedge clk);
        PCWrite     = 1'b1;
        IF_ID_write = 1'b1;
        @(posedge clk);
        #1;
        check("Resume after stall: PC_IFID=0x8, inst[2]", PC_IFID === 32'h0000_0008 && inst_IFID === 32'hA000_0002);

        // Branch redirect to 0x20 (word 8)
        @(negedge clk);
        PCSrc          = 1'b1;
        target_address = 32'h0000_0020;
        @(posedge clk); // PC_IFID_reg <= 0x20
        @(negedge clk);
        PCSrc = 1'b0;
        @(posedge clk); // PC_ID_reg <= 0x20, inst_reg <= inst[8]
        #1;
        check("Branch redirect: PC_IFID=0x20, inst[8]", PC_IFID === 32'h0000_0020 && inst_IFID === 32'hA000_0008);

        $display("tb_fetch_stage Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count != 0) $fatal(1, "tb_fetch_stage FAILED");
        $finish;
    end
endmodule
