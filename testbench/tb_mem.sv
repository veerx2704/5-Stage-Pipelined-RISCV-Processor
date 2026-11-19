`timescale 1ns / 1ps

module tb_mem;

    localparam int WIDTH = 32;
    localparam realtime CLK_PERIOD = 10.0; // 100 MHz

    logic              clk;
    logic [WIDTH-1:0]  WData;
    logic [WIDTH-1:2]  addr;
    logic              mem_wen;
    logic              mem_ren;
    wire  [WIDTH-1:0]  RData;

    int pass_count = 0;
    int fail_count = 0;

    // Instantiate primary ASIC SRAM-based data_mem
    data_mem #(.WIDTH(WIDTH)) dut (
        .WData   (WData),
        .addr    (addr),
        .clk     (clk),
        .mem_wen (mem_wen),
        .mem_ren (mem_ren),
        .RData   (RData)
    );

    // 100 MHz clock
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2.0) clk = ~clk;

    // Write a 32-bit word to word-aligned byte address (addr[31:2] = byte_addr[31:2])
    task automatic write_word(input logic [31:0] byte_addr, input logic [31:0] data);
        begin
            @(negedge clk);
            addr    = byte_addr[31:2];
            WData   = data;
            mem_wen = 1'b1;
            mem_ren = 1'b0;
            @(posedge clk); // SRAM captures inputs on posedge clk, commits write on next negedge clk
            #1;
            mem_wen = 1'b0;
            @(negedge clk); // Wait for write commit
        end
    endtask

    // Read a 32-bit word and check it right before the next posedge clk (simulating MEM/WB capture)
    task automatic read_and_check(input logic [31:0] byte_addr, input logic [31:0] expected);
        logic [31:0] sampled;
        begin
            @(negedge clk);
            addr    = byte_addr[31:2];
            mem_wen = 1'b0;
            mem_ren = 1'b1;
            @(posedge clk); // SRAM + bank_sel_q capture addr on posedge clk
            #1;
            mem_ren = 1'b0;
            @(negedge clk); // SRAM launches dout1 on negedge clk
            #(CLK_PERIOD / 2.0 - 0.5); // Sample just before the next posedge clk (MEM/WB FF setup)
            sampled = RData;
            if (sampled === expected) begin
                $display("[PASS] addr=0x%08h (bank %0d, word %0d) -> RData=0x%08h",
                         byte_addr, byte_addr[11:10], byte_addr[9:2], sampled);
                pass_count++;
            end else begin
                $display("[FAIL] addr=0x%08h (bank %0d, word %0d) -> expected=0x%08h, got=0x%08h",
                         byte_addr, byte_addr[11:10], byte_addr[9:2], expected, sampled);
                fail_count++;
            end
        end
    endtask

    initial begin
        WData   = 32'h0;
        addr    = 30'h0;
        mem_wen = 1'b0;
        mem_ren = 1'b0;

        repeat (2) @(posedge clk);

        $display("=== Test 1: Write & Read across all 4 SRAM banks ===");
        // Bank 0 (0x000..0x3FC), Bank 1 (0x400..0x7FC), Bank 2 (0x800..0xBFC), Bank 3 (0xC00..0xFFC)
        write_word(32'h0000_0000, 32'hDEAD_BEEF); // Bank 0, word 0
        write_word(32'h0000_03FC, 32'h1111_2222); // Bank 0, word 255
        write_word(32'h0000_0400, 32'hCAFE_BABE); // Bank 1, word 0
        write_word(32'h0000_07FC, 32'h3333_4444); // Bank 1, word 255
        write_word(32'h0000_0800, 32'h1234_5678); // Bank 2, word 0
        write_word(32'h0000_0BFC, 32'h5555_6666); // Bank 2, word 255
        write_word(32'h0000_0C00, 32'hA5A5_5A5A); // Bank 3, word 0
        write_word(32'h0000_0FFC, 32'h7777_8888); // Bank 3, word 255

        read_and_check(32'h0000_0000, 32'hDEAD_BEEF);
        read_and_check(32'h0000_03FC, 32'h1111_2222);
        read_and_check(32'h0000_0400, 32'hCAFE_BABE);
        read_and_check(32'h0000_07FC, 32'h3333_4444);
        read_and_check(32'h0000_0800, 32'h1234_5678);
        read_and_check(32'h0000_0BFC, 32'h5555_6666);
        read_and_check(32'h0000_0C00, 32'hA5A5_5A5A);
        read_and_check(32'h0000_0FFC, 32'h7777_8888);

        $display("=== Test 2: Overwrite & Bank Isolation ===");
        write_word(32'h0000_0400, 32'hF00D_FACE); // Overwrite Bank 1, word 0
        read_and_check(32'h0000_0400, 32'hF00D_FACE);
        read_and_check(32'h0000_0000, 32'hDEAD_BEEF); // Bank 0 untouched
        read_and_check(32'h0000_0800, 32'h1234_5678); // Bank 2 untouched

        $display("=== Test 3: Back-to-Back Pipelined Reads across Banks ===");
        // Cycle 0: issue read Bank 0 word 0
        @(negedge clk);
        addr    = 32'h0000_0000 >> 2;
        mem_wen = 1'b0;
        mem_ren = 1'b1;
        @(posedge clk); // Bank 0 captured

        // Cycle 1: issue read Bank 3 word 0 while Bank 0 launches at negedge
        @(negedge clk);
        addr    = 32'h0000_0C00 >> 2;
        #(CLK_PERIOD / 2.0 - 0.5);
        if (RData === 32'hDEAD_BEEF) begin
            $display("[PASS] Back-to-back read 1 (Bank 0) -> RData=0x%08h", RData);
            pass_count++;
        end else begin
            $display("[FAIL] Back-to-back read 1 (Bank 0) -> expected=0xDEAD_BEEF, got=0x%08h", RData);
            fail_count++;
        end
        @(posedge clk); // Bank 3 captured

        // Cycle 2: deassert mem_ren while Bank 3 launches at negedge
        @(negedge clk);
        mem_ren = 1'b0;
        #(CLK_PERIOD / 2.0 - 0.5);
        if (RData === 32'hA5A5_5A5A) begin
            $display("[PASS] Back-to-back read 2 (Bank 3) -> RData=0x%08h", RData);
            pass_count++;
        end else begin
            $display("[FAIL] Back-to-back read 2 (Bank 3) -> expected=0xA5A5_5A5A, got=0x%08h", RData);
            fail_count++;
        end

        $display("========================================");
        $display("tb_mem Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================");
        if (fail_count != 0) $fatal(1, "tb_mem FAILED");
        $finish;
    end

endmodule
