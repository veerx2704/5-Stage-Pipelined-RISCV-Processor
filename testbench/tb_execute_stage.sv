`timescale 1ns / 1ps

module tb_execute_stage;
    logic        clk = 1'b0;
    logic        rst;
    logic [31:0] rs1_IDEX, rs2_IDEX, imm_value_IDEX;
    logic [4:0]  rs1_addr_IDEX, rs2_addr_IDEX, rd_IDEX;
    logic [31:0] forward_data_WB, forward_data_MEM;
    logic [3:0]  ALUCode_IDEX;
    logic        ALUSrc_IDEX, jump_IDEX;
    logic [2:0]  load_control_IDEX;
    logic [1:0]  store_control_IDEX;
    logic        mem_read_IDEX, mem_write_IDEX;
    logic        ResultSrc_IDEX, reg_write_IDEX;
    logic [1:0]  forwardA, forwardB;

    wire  [31:0] ALUOut_EXMEM, srcB_data_EXMEM;
    wire  [4:0]  rd_EXMEM, rs1_forward_compare, rs2_forward_compare, rd_hazard;
    wire         mem_write_EXMEM, mem_read_EXMEM, ResultSrc_EXMEM, reg_write_EXMEM;
    wire  [1:0]  store_control_EXMEM, store_control_hazard;
    wire  [2:0]  load_control_EXMEM, load_control_hazard;
    wire         mem_write_hazard, mem_read_hazard;

    int pass_count = 0;
    int fail_count = 0;

    execute_stage dut (.*);

    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            $display("[PASS] %s", name);
            pass_count++;
        end else begin
            $display("[FAIL] %s (ALUOut=0x%08h srcB=0x%08h)", name, ALUOut_EXMEM, srcB_data_EXMEM);
            fail_count++;
        end
    endtask

    initial begin
        rst                = 1'b0;
        rs1_IDEX           = 32'd10;
        rs2_IDEX           = 32'd20;
        imm_value_IDEX     = 32'd100;
        rs1_addr_IDEX      = 5'd7;
        rs2_addr_IDEX      = 5'd9;
        rd_IDEX            = 5'd11;
        forward_data_MEM   = 32'd300;
        forward_data_WB    = 32'd40;
        ALUCode_IDEX       = 4'b0000; // ADD
        ALUSrc_IDEX        = 1'b0;
        jump_IDEX          = 1'b0;
        load_control_IDEX  = 3'b010;
        store_control_IDEX = 2'b10;
        mem_read_IDEX      = 1'b0;
        mem_write_IDEX     = 1'b0;
        ResultSrc_IDEX     = 1'b0;
        reg_write_IDEX     = 1'b1;
        forwardA           = 2'b00;
        forwardB           = 2'b00;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b1;
        #1;
        check("Forward compare outputs 5-bit register addresses",
              rs1_forward_compare === 5'd7 && rs2_forward_compare === 5'd9);

        // Test 1: Normal ADD (10 + 20 = 30)
        @(posedge clk);
        #1;
        check("Normal ADD: 10 + 20 = 30", ALUOut_EXMEM === 32'd30 && rd_EXMEM === 5'd11);

        // Test 2: Forward A from MEM (2'b10 -> 300), Forward B from WB (2'b01 -> 40) => 300 + 40 = 340
        @(negedge clk);
        forwardA = 2'b10;
        forwardB = 2'b01;
        @(posedge clk);
        #1;
        check("Forwarding 2'b10=MEM (300) + 2'b01=WB (40) = 340", ALUOut_EXMEM === 32'd340);

        // Test 3: Store (ALUSrc=1): ALU computes base+imm (300+100=400), srcB_data_EXMEM must be forwarded rs2 (40), NOT imm (100)!
        @(negedge clk);
        ALUSrc_IDEX    = 1'b1;
        mem_write_IDEX = 1'b1;
        @(posedge clk);
        #1;
        check("Store: ALUOut=base+imm (400) and srcB_data_EXMEM=forwarded rs2 (40)",
              ALUOut_EXMEM === 32'd400 && srcB_data_EXMEM === 32'd40);

        // Test 4: Arithmetic right shift SRA (0x8000_0000 >>> 4 = 0xF800_0000) with unmasked upper bits in DataB
        @(negedge clk);
        forwardA       = 2'b00;
        forwardB       = 2'b00;
        ALUSrc_IDEX    = 1'b0;
        mem_write_IDEX = 1'b0;
        rs1_IDEX       = 32'h8000_0000;
        rs2_IDEX       = 32'h0000_0024; // lower 5 bits = 4
        ALUCode_IDEX   = 4'b1100;       // SRA
        @(posedge clk);
        #1;
        check("SRA with 5-bit shift mask: 0x80000000 >>> 4 = 0xF8000000", ALUOut_EXMEM === 32'hF800_0000);

        $display("tb_execute_stage Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count != 0) $fatal(1, "tb_execute_stage FAILED");
        $finish;
    end
endmodule
