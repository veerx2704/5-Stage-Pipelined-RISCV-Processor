`timescale 1ns / 1ps

module tb_decode_stage;
    logic        clk = 1'b0;
    logic        rst;
    logic        hazard_stall;
    logic [31:0] inst_IFID;
    logic [31:0] PC_IFID;
    logic        reg_write_WB;
    logic [4:0]  Rd_MEMWB_forwarded;
    logic [31:0] WData_WB_forwarded;

    wire  [31:0] inst_hazard;
    wire  [31:0] rs1_IDEX;
    wire  [31:0] rs2_IDEX;
    wire  [31:0] imm_value_IDEX;
    wire  [31:0] target_address;
    wire  [4:0]  rs1_addr_IDEX;
    wire  [4:0]  rs2_addr_IDEX;
    wire  [4:0]  rd_IDEX;
    wire  [3:0]  ALUCode_IDEX;
    wire  [2:0]  load_control_IDEX;
    wire  [1:0]  store_control_IDEX;
    wire         ALUSrc_IDEX;
    wire         jump_IDEX;
    wire         mem_read_IDEX;
    wire         mem_write_IDEX;
    wire         ResultSrc_IDEX;
    wire         reg_write_IDEX;
    wire         PCSrc_IF;

    int pass_count = 0;
    int fail_count = 0;

    decode_stage dut (
        .clk                (clk),
        .rst                (rst),
        .hazard_stall       (hazard_stall),
        .inst_IFID          (inst_IFID),
        .PC_IFID            (PC_IFID),
        .reg_write_WB       (reg_write_WB),
        .Rd_MEMWB_forwarded (Rd_MEMWB_forwarded),
        .WData_WB_forwarded (WData_WB_forwarded),
        .inst_hazard        (inst_hazard),
        .rs1_IDEX           (rs1_IDEX),
        .rs2_IDEX           (rs2_IDEX),
        .imm_value_IDEX     (imm_value_IDEX),
        .target_address     (target_address),
        .rs1_addr_IDEX      (rs1_addr_IDEX),
        .rs2_addr_IDEX      (rs2_addr_IDEX),
        .rd_IDEX            (rd_IDEX),
        .ALUCode_IDEX       (ALUCode_IDEX),
        .load_control_IDEX  (load_control_IDEX),
        .store_control_IDEX (store_control_IDEX),
        .ALUSrc_IDEX        (ALUSrc_IDEX),
        .jump_IDEX          (jump_IDEX),
        .mem_read_IDEX      (mem_read_IDEX),
        .mem_write_IDEX     (mem_write_IDEX),
        .ResultSrc_IDEX     (ResultSrc_IDEX),
        .reg_write_IDEX     (reg_write_IDEX),
        .PCSrc_IF           (PCSrc_IF)
    );

    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            $display("[PASS] %s", name);
            pass_count++;
        end else begin
            $display("[FAIL] %s", name);
            fail_count++;
        end
    endtask

    initial begin
        for (int i = 0; i < 32; i++)
            dut.REGISTER_FILE.REGISTER_FILE[i] = 32'h0;

        rst                = 1'b0;
        hazard_stall       = 1'b0;
        inst_IFID          = 32'h0;
        PC_IFID            = 32'h0000_0100;
        reg_write_WB       = 1'b0;
        Rd_MEMWB_forwarded = 5'd0;
        WData_WB_forwarded = 32'h0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b1;

        // Write x1 = 0x11223344 via reg_write_WB (mem_write is 0!)
        reg_write_WB       = 1'b1;
        Rd_MEMWB_forwarded = 5'd1;
        WData_WB_forwarded = 32'h1122_3344;
        @(posedge clk);

        // Write x2 = 0x55667788
        @(negedge clk);
        Rd_MEMWB_forwarded = 5'd2;
        WData_WB_forwarded = 32'h5566_7788;
        @(posedge clk);

        // Attempt write to x0 -> must remain 0
        @(negedge clk);
        Rd_MEMWB_forwarded = 5'd0;
        WData_WB_forwarded = 32'hFFFF_FFFF;
        @(posedge clk);

        // Decode SUB x3, x1, x2 (funct7=0100000 -> funct7_b5=1, rs2=2, rs1=1, funct3=000, rd=3, opcode=0110011)
        @(negedge clk);
        reg_write_WB = 1'b0;
        inst_IFID    = {7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
        #1;
        check("inst_hazard mirrors inst_IFID", inst_hazard === inst_IFID);
        @(posedge clk);
        #1;
        check("SUB decodes ALUCode=0001 (funct7_b5 wired), ALUSrc=0, reg_write=1",
              ALUCode_IDEX === 4'b0001 && ALUSrc_IDEX === 1'b0 && reg_write_IDEX === 1'b1);
        check("Full 32-bit rs1/rs2 data & 5-bit rs1/rs2/rd addresses propagated",
              rs1_IDEX === 32'h1122_3344 && rs2_IDEX === 32'h5566_7788 &&
              rs1_addr_IDEX === 5'd1 && rs2_addr_IDEX === 5'd2 && rd_IDEX === 5'd3);

        // Test hazard_stall=1 suppresses reg_write_IDEX and all control outputs
        @(negedge clk);
        hazard_stall = 1'b1;
        inst_IFID    = {12'd16, 5'd1, 3'b010, 5'd4, 7'b0000011}; // LW x4, 16(x1)
        @(posedge clk);
        #1;
        check("hazard_stall zeroes reg_write_IDEX, mem_read_IDEX, ALUSrc_IDEX",
              reg_write_IDEX === 1'b0 && mem_read_IDEX === 1'b0 && ALUSrc_IDEX === 1'b0 && ResultSrc_IDEX === 1'b0);

        // Test x0 read returns 0
        @(negedge clk);
        hazard_stall = 1'b0;
        inst_IFID    = {12'd4, 5'd0, 3'b000, 5'd5, 7'b0010011}; // ADDI x5, x0, 4
        @(posedge clk);
        #1;
        check("x0 read is hardwired 0 & ADDI imm=4", rs1_IDEX === 32'h0 && imm_value_IDEX === 32'd4 && rd_IDEX === 5'd5);

        $display("tb_decode_stage Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count != 0) $fatal(1, "tb_decode_stage FAILED");
        $finish;
    end
endmodule
