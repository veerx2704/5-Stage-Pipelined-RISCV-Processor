`timescale 1ns / 1ps

module tb_memory_stage;
    logic        clk = 1'b0;
    logic        rst;
    logic [31:0] ALUOut_EXMEM;
    logic [31:0] srcB_data_EXMEM;
    logic [4:0]  rd_EXMEM;
    logic        mem_write_EXMEM;
    logic        mem_read_EXMEM;
    logic [1:0]  store_control_EXMEM;
    logic [2:0]  load_control_EXMEM;
    logic        ResultSrc_EXMEM;
    logic        reg_write_EXMEM;

    wire  [31:0] loaded_data_MEMWB;
    wire  [31:0] ALU_forwarded_MEMWB;
    wire  [4:0]  rd_MEMWB;
    wire         ResultSrc_MEMWB;
    wire         reg_write_MEMWB;

    int pass_count = 0;
    int fail_count = 0;

    memory_stage dut (.*);

    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            $display("[PASS] %s", name);
            pass_count++;
        end else begin
            $display("[FAIL] %s (loaded=0x%08h ALU_fwd=0x%08h rd=%0d ResultSrc=%b reg_write=%b)",
                     name, loaded_data_MEMWB, ALU_forwarded_MEMWB, rd_MEMWB, ResultSrc_MEMWB, reg_write_MEMWB);
            fail_count++;
        end
    endtask

    initial begin
        rst                 = 1'b0;
        ALUOut_EXMEM        = 32'h0;
        srcB_data_EXMEM     = 32'h0;
        rd_EXMEM            = 5'd0;
        mem_write_EXMEM     = 1'b0;
        mem_read_EXMEM      = 1'b0;
        store_control_EXMEM = 2'b10;
        load_control_EXMEM  = 3'b010;
        ResultSrc_EXMEM     = 1'b0;
        reg_write_EXMEM     = 1'b0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b1;

        // Test 1: ALU pass-through (ALU_forwarded_MEMWB, rd_MEMWB, reg_write_MEMWB)
        ALUOut_EXMEM    = 32'h1234_5678;
        rd_EXMEM        = 5'd7;
        ResultSrc_EXMEM = 1'b0;
        reg_write_EXMEM = 1'b1;
        @(posedge clk);
        #1;
        check("ALU_forwarded_MEMWB and control signals registered",
              ALU_forwarded_MEMWB === 32'h1234_5678 && rd_MEMWB === 5'd7 &&
              ResultSrc_MEMWB === 1'b0 && reg_write_MEMWB === 1'b1);

        // Test 2: SW 0xCAFE_8090 to addr 0x0000_0400 (Bank 1, word 0)
        @(negedge clk);
        ALUOut_EXMEM        = 32'h0000_0400;
        srcB_data_EXMEM     = 32'hCAFE_8090;
        mem_write_EXMEM     = 1'b1;
        mem_read_EXMEM      = 1'b0;
        store_control_EXMEM = 2'b10; // SW
        reg_write_EXMEM     = 1'b0;
        @(posedge clk); // SRAM captures write
        @(negedge clk); // SRAM commits write
        mem_write_EXMEM = 1'b0;

        // Test 3: LW from 0x0000_0400 (2 cycles: posedge captures addr, negedge launches dout1, next posedge registers loaded_data_reg)
        ALUOut_EXMEM       = 32'h0000_0400;
        mem_read_EXMEM     = 1'b1;
        load_control_EXMEM = 3'b010; // LW
        rd_EXMEM           = 5'd9;
        ResultSrc_EXMEM    = 1'b1;
        reg_write_EXMEM    = 1'b1;
        @(posedge clk); // SRAM + bank_sel_q capture addr
        @(negedge clk); // SRAM launches dout1=0xCAFE_8090
        mem_read_EXMEM = 1'b0;
        @(posedge clk); // memory_stage registers loaded_data_reg <= 0xCAFE_8090
        #1;
        check("LW reads 0xCAFE_8090 through SRAM into loaded_data_MEMWB",
              loaded_data_MEMWB === 32'hCAFE_8090 && ResultSrc_MEMWB === 1'b1);

        // Test 4: LHU (zero-extend lower 16 bits -> 0x0000_8090) & LBU (0x0000_0090)
        @(negedge clk);
        ALUOut_EXMEM       = 32'h0000_0400;
        mem_read_EXMEM     = 1'b1;
        load_control_EXMEM = 3'b101; // LHU
        @(posedge clk);
        @(negedge clk);
        mem_read_EXMEM = 1'b0;
        @(posedge clk);
        #1;
        check("LHU zero-extends to 0x0000_8090 (fixed concatenation)", loaded_data_MEMWB === 32'h0000_8090);

        @(negedge clk);
        ALUOut_EXMEM       = 32'h0000_0400;
        mem_read_EXMEM     = 1'b1;
        load_control_EXMEM = 3'b100; // LBU
        @(posedge clk);
        @(negedge clk);
        mem_read_EXMEM = 1'b0;
        @(posedge clk);
        #1;
        check("LBU zero-extends to 0x0000_0090 (fixed concatenation)", loaded_data_MEMWB === 32'h0000_0090);

        $display("tb_memory_stage Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count != 0) $fatal(1, "tb_memory_stage FAILED");
        $finish;
    end
endmodule
