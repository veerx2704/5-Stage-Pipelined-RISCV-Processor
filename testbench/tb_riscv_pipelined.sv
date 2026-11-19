`timescale 1ns / 1ps

module tb_riscv_pipelined;
    logic        clk = 1'b0;
    logic        rst;
    wire  [31:0] dbg_PC;
    wire  [31:0] dbg_INS;
    wire  [31:0] dbg_WB_data;
    wire  [4:0]  dbg_WB_rd;
    wire         dbg_WB_wen;

    int pass_count = 0;
    int fail_count = 0;

    riscv_pipelined dut (
        .clk         (clk),
        .rst         (rst),
        .dbg_PC      (dbg_PC),
        .dbg_INS     (dbg_INS),
        .dbg_WB_data (dbg_WB_data),
        .dbg_WB_rd   (dbg_WB_rd),
        .dbg_WB_wen  (dbg_WB_wen)
    );

    always #2.5 clk = ~clk; // 200 MHz clock!

    // RV32I instruction encoders
    function automatic logic [31:0] enc_r(logic [6:0] f7, logic [4:0] rs2, logic [4:0] rs1, logic [2:0] f3, logic [4:0] rd);
        return {f7, rs2, rs1, f3, rd, 7'b0110011};
    endfunction
    function automatic logic [31:0] enc_i(logic [11:0] imm, logic [4:0] rs1, logic [2:0] f3, logic [4:0] rd, logic [6:0] op);
        return {imm, rs1, f3, rd, op};
    endfunction
    function automatic logic [31:0] enc_s(logic [11:0] imm, logic [4:0] rs2, logic [4:0] rs1, logic [2:0] f3);
        return {imm[11:5], rs2, rs1, f3, imm[4:0], 7'b0100011};
    endfunction
    function automatic logic [31:0] enc_b(logic signed [12:0] imm, logic [4:0] rs2, logic [4:0] rs1, logic [2:0] f3);
        return {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], 7'b1100011};
    endfunction
    function automatic logic [31:0] enc_u(logic [19:0] imm20, logic [4:0] rd);
        return {imm20, rd, 7'b0110111};
    endfunction
    function automatic logic [31:0] enc_j(logic signed [20:0] imm, logic [4:0] rd);
        return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
    endfunction

    task automatic check_reg(input string desc, input int reg_idx, input logic [31:0] expected);
        logic [31:0] actual;
        actual = dut.ID_STAGE.REGISTER_FILE.REGISTER_FILE[reg_idx];
        if (actual === expected) begin
            $display("[PASS] %s (x%0d = 0x%08h)", desc, reg_idx, actual);
            pass_count++;
        end else begin
            $display("[FAIL] %s (x%0d expected=0x%08h, got=0x%08h)", desc, reg_idx, expected, actual);
            fail_count++;
        end
    endtask

    initial begin
        // --- Section 1: ALU, Forwarding (EX/MEM, MEM/WB, WB->ID), x0 protection ---
        // 0x00: ADDI x0, x0, 42            -> x0 stays 0
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[0]  = enc_i(12'd42, 5'd0, 3'b000, 5'd0, 7'b0010011);
        // 0x04: ADDI x1, x0, 10            -> x1 = 10
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[1]  = enc_i(12'd10, 5'd0, 3'b000, 5'd1, 7'b0010011);
        // 0x08: ADDI x2, x1, 20            -> x2 = 30 (EX/MEM forward x1)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[2]  = enc_i(12'd20, 5'd1, 3'b000, 5'd2, 7'b0010011);
        // 0x0C: ADD  x3, x1, x2            -> x3 = 40 (MEM/WB forward x1, EX/MEM forward x2)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[3]  = enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3);
        // 0x10: SUB  x4, x3, x1            -> x4 = 30 (WB->ID bypass x1, EX/MEM forward x3)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[4]  = enc_r(7'b0100000, 5'd1, 5'd3, 3'b000, 5'd4);
        // 0x14: LUI  x5, 0x80000           -> x5 = 0x80000000
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[5]  = enc_u(20'h80000, 5'd5);
        // 0x18: SRAI x6, x5, 4             -> x6 = 0xF8000000 (arithmetic right shift)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[6]  = enc_i({7'b0100000, 5'd4}, 5'd5, 3'b101, 5'd6, 7'b0010011);
        // 0x1C: SRLI x7, x5, 4             -> x7 = 0x08000000 (logical right shift)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[7]  = enc_i({7'b0000000, 5'd4}, 5'd5, 3'b101, 5'd7, 7'b0010011);
        // 0x20: SLT  x8, x5, x1            -> x8 = 1 (signed: 0x80000000 < 10)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[8]  = enc_r(7'b0000000, 5'd1, 5'd5, 3'b010, 5'd8);
        // 0x24: SLTU x9, x5, x1            -> x9 = 0 (unsigned: 0x80000000 > 10)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[9]  = enc_r(7'b0000000, 5'd1, 5'd5, 3'b011, 5'd9);

        // --- Section 2: Byte-Enabled Stores, Subword Loads & Load-Use Stall ---
        // 0x28: ADDI x10, x0, 0x400        -> x10 = 0x400 (Bank 1, word 0)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[10] = enc_i(12'h400, 5'd0, 3'b000, 5'd10, 7'b0010011);
        // 0x2C: LUI  x11, 0x12345          -> x11 = 0x12345000
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[11] = enc_u(20'h12345, 5'd11);
        // 0x30: SW   x11, 0(x10)           -> mem[0x400] = 0x12345000
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[12] = enc_s(12'd0, 5'd11, 5'd10, 3'b010);
        // 0x34: ADDI x12, x0, 0x0AA        -> x12 = 0xAA
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[13] = enc_i(12'h0AA, 5'd0, 3'b000, 5'd12, 7'b0010011);
        // 0x38: SB   x12, 1(x10)           -> mem[0x400] = 0x1234AA00
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[14] = enc_s(12'd1, 5'd12, 5'd10, 3'b000);
        // 0x3C: ADDI x13, x0, 0x567        -> x13 = 0x0567
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[15] = enc_i(12'h567, 5'd0, 3'b000, 5'd13, 7'b0010011);
        // 0x40: SH   x13, 2(x10)           -> mem[0x400] = 0x0567AA00 (halfword upper lane!)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[16] = enc_s(12'd2, 5'd13, 5'd10, 3'b001);
        // 0x44: LW   x14, 0(x10)           -> x14 = 0x0567AA00
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[17] = enc_i(12'd0, 5'd10, 3'b010, 5'd14, 7'b0000011);
        // 0x48: ADD  x15, x14, x1          -> x15 = 0x0567AA0A (LOAD-USE STALL on x14!)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[18] = enc_r(7'b0000000, 5'd1, 5'd14, 3'b000, 5'd15);
        // 0x4C: LHU  x16, 2(x10)           -> x16 = 0x00000567
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[19] = enc_i(12'd2, 5'd10, 3'b101, 5'd16, 7'b0000011);
        // 0x50: LB   x17, 1(x10)           -> x17 = 0xFFFFFFAA
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[20] = enc_i(12'd1, 5'd10, 3'b000, 5'd17, 7'b0000011);
        // 0x54: LBU  x18, 1(x10)           -> x18 = 0x000000AA
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[21] = enc_i(12'd1, 5'd10, 3'b100, 5'd18, 7'b0000011);

        // --- Section 3: Taken Branch + 3-Instruction Wrong-Path Squash (including wrong-path SW!) ---
        // 0x58: BEQ  x2, x4, +16 (to 0x68) -> TAKEN (30 == 30), must squash 0x5C, 0x60, 0x64!
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[22] = enc_b(13'sd16, 5'd4, 5'd2, 3'b000);
        // 0x5C: SW   x1, 0(x10)            -> WRONG-PATH STORE: MUST BE SQUASHED (mem[0x400] stays 0x0567AA00)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[23] = enc_s(12'd0, 5'd1, 5'd10, 3'b010);
        // 0x60: ADDI x19, x0, 99           -> WRONG-PATH: MUST BE SQUASHED (x19 stays 0)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[24] = enc_i(12'd99, 5'd0, 3'b000, 5'd19, 7'b0010011);
        // 0x64: ADDI x20, x0, 88           -> WRONG-PATH: MUST BE SQUASHED (x20 stays 0)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[25] = enc_i(12'd88, 5'd0, 3'b000, 5'd20, 7'b0010011);
        // 0x68: LW   x21, 0(x10)           -> x21 = 0x0567AA00 (proves wrong-path SW at 0x5C did NOT execute!)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[26] = enc_i(12'd0, 5'd10, 3'b010, 5'd21, 7'b0000011);

        // --- Section 4: JAL Link Writeback + Squash ---
        // 0x6C: JAL  x22, +16 (to 0x7C)    -> x22 = 0x70 (PC+4), squash 0x70, 0x74, 0x78
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[27] = enc_j(21'sd16, 5'd22);
        // 0x70..0x78: wrong-path instructions -> x23 must stay 0
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[28] = enc_i(12'd77, 5'd0, 3'b000, 5'd23, 7'b0010011);
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[29] = enc_i(12'd66, 5'd0, 3'b000, 5'd23, 7'b0010011);
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[30] = enc_i(12'd55, 5'd0, 3'b000, 5'd23, 7'b0010011);

        // --- Section 5: Counted Loop with Backward BNE Branch: sum(1..5) = 15 ---
        // 0x7C: ADDI x24, x0, 5            -> loop counter i = 5
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[31] = enc_i(12'd5, 5'd0, 3'b000, 5'd24, 7'b0010011);
        // 0x80: ADDI x25, x0, 0            -> acc = 0
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[32] = enc_i(12'd0, 5'd0, 3'b000, 5'd25, 7'b0010011);
        // 0x84 (loop): ADD  x25, x25, x24  -> acc += i
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[33] = enc_r(7'b0000000, 5'd24, 5'd25, 3'b000, 5'd25);
        // 0x88: ADDI x24, x24, -1          -> i -= 1
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[34] = enc_i(-12'sd1, 5'd24, 3'b000, 5'd24, 7'b0010011);
        // 0x8C: BNE  x24, x0, -8 (to 0x84) -> loop while i != 0
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[35] = enc_b(-13'sd8, 5'd0, 5'd24, 3'b001);
        // 0x90: ADDI x26, x25, 100         -> x26 = 115 (final marker after loop exits!)
        dut.IF_STAGE.INSTRUCTION_MEMORY.INSTRUCTION_MEMORY[36] = enc_i(12'd100, 5'd25, 3'b000, 5'd26, 7'b0010011);

        rst = 1'b0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b1;

        // Run enough cycles for full program + 5-iteration loop to retire
        repeat (100) @(posedge clk);

        $display("=== Full Top-Level 5-Stage Pipelined RV32I Verification (200 MHz) ===");
        check_reg("x0 hardwired to 0",                              0,  32'd0);
        check_reg("ADDI x1 = 10",                                   1,  32'd10);
        check_reg("EX/MEM forward: ADDI x2 = 30",                   2,  32'd30);
        check_reg("MEM/WB + EX/MEM forward: ADD x3 = 40",           3,  32'd40);
        check_reg("WB->ID bypass + SUB: x4 = 30",                   4,  32'd30);
        check_reg("LUI: x5 = 0x80000000",                           5,  32'h8000_0000);
        check_reg("SRAI (arithmetic): x6 = 0xF8000000",             6,  32'hF800_0000);
        check_reg("SRLI (logical): x7 = 0x08000000",                7,  32'h0800_0000);
        check_reg("SLT (signed): x8 = 1",                           8,  32'd1);
        check_reg("SLTU (unsigned): x9 = 0",                        9,  32'd0);
        check_reg("SW + SB(1) + SH(2) + LW: x14 = 0x0567AA00",     14,  32'h0567_AA00);
        check_reg("Load-use stall + ADD: x15 = 0x0567AA0A",        15,  32'h0567_AA0A);
        check_reg("Halfword-aligned LHU(2): x16 = 0x00000567",     16,  32'h0000_0567);
        check_reg("Byte-aligned LB(1): x17 = 0xFFFFFFAA",          17,  32'hFFFF_FFAA);
        check_reg("Byte-aligned LBU(1): x18 = 0x000000AA",         18,  32'h0000_00AA);
        check_reg("BEQ 3-stage squash: x19 == 0",                  19,  32'd0);
        check_reg("BEQ 3-stage squash: x20 == 0",                  20,  32'd0);
        check_reg("BEQ squashed wrong-path SW: x21 = 0x0567AA00",  21,  32'h0567_AA00);
        check_reg("JAL link writeback: x22 = 0x70 (PC+4)",         22,  32'h0000_0070);
        check_reg("JAL 3-stage squash: x23 == 0",                  23,  32'd0);
        check_reg("Backward BNE loop exit: counter x24 == 0",      24,  32'd0);
        check_reg("Backward BNE loop sum(1..5): x25 == 15",        25,  32'd15);
        check_reg("Post-loop instruction retired: x26 == 115",     26,  32'd115);

        $display("=====================================================================");
        $display("tb_riscv_pipelined Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("=====================================================================");
        if (fail_count != 0) $fatal(1, "tb_riscv_pipelined FAILED");
        $finish;
    end
endmodule
