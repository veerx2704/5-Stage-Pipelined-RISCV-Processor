`timescale 1ns / 1ps

module tb_branch_gshare;
    localparam int GSHARE_BITS = 10;

    logic                     clk = 1'b0;
    logic                     rst;
    logic [GSHARE_BITS-1:0]   PC;
    logic                     update_en;
    logic [GSHARE_BITS-1:0]   update_index;
    logic [1:0]               update_old_state;
    logic                     branch_taken;
    logic                     pred;
    logic [GSHARE_BITS-1:0]   pred_index;
    logic [1:0]               pred_state;

    int pass_count = 0;
    int fail_count = 0;

    branch_gshare #(.GSHARE_BITS(GSHARE_BITS)) dut (
        .clk              (clk),
        .rst              (rst),
        .PC               (PC),
        .update_en        (update_en),
        .update_index     (update_index),
        .update_old_state (update_old_state),
        .branch_taken     (branch_taken),
        .pred             (pred),
        .pred_index       (pred_index),
        .pred_state       (pred_state)
    );

    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            $display("[PASS] %s", name);
            pass_count++;
        end else begin
            $display("[FAIL] %s (pred=%b pred_state=%b pred_index=%h)", name, pred, pred_state, pred_index);
            fail_count++;
        end
    endtask

    initial begin
        rst              = 1'b0;
        PC               = 10'h015;
        update_en        = 1'b0;
        update_index     = 10'h000;
        update_old_state = 2'b01;
        branch_taken     = 1'b0;

        repeat (2) @(posedge clk);
        #1;
        check("Reset state is W_NOT_TAKEN (pred=0)", pred === 1'b0 && pred_state === 2'b01 && pred_index === 10'h000);

        // Release reset, pre-seed PHT[0x015] to W_NOT_TAKEN via update_en=1
        @(negedge clk);
        rst              = 1'b1;
        update_en        = 1'b1;
        update_index     = 10'h015;
        update_old_state = 2'b00; // S_NOT_TAKEN + taken -> W_NOT_TAKEN (2'b01)
        branch_taken     = 1'b1;  // GHR shifts: 0 -> 10'h001
        @(posedge clk);

        // Next cycle: update_en=0 -> GHR must stay 10'h001, table_index = 10'h001 ^ 10'h014 = 10'h015
        @(negedge clk);
        update_en = 1'b0;
        PC        = 10'h014;
        @(posedge clk);
        #1;
        check("GHR shifted left by 1 & PHT updated to W_NOT_TAKEN", pred_index === 10'h015 && pred_state === 2'b01 && pred === 1'b0);

        // Transition W_NOT_TAKEN (01) + taken -> W_TAKEN (10); GHR: 10'h001 -> 10'h003
        @(negedge clk);
        update_en        = 1'b1;
        update_index     = 10'h015;
        update_old_state = 2'b01;
        branch_taken     = 1'b1;
        @(posedge clk);

        // Read back index 10'h015 using PC = 10'h015 ^ 10'h003 = 10'h016
        @(negedge clk);
        update_en = 1'b0;
        PC        = 10'h016;
        @(posedge clk);
        #1;
        check("FSM W_NOT_TAKEN -> W_TAKEN (pred=1) & GHR=0x003", pred_index === 10'h015 && pred_state === 2'b10 && pred === 1'b1);

        // Transition W_TAKEN (10) + taken -> S_TAKEN (11); GHR: 10'h003 -> 10'h007
        @(negedge clk);
        update_en        = 1'b1;
        update_index     = 10'h015;
        update_old_state = 2'b10;
        branch_taken     = 1'b1;
        @(posedge clk);

        // Saturate S_TAKEN (11) + taken -> S_TAKEN (11); GHR: 10'h007 -> 10'h00f
        @(negedge clk);
        update_old_state = 2'b11;
        branch_taken     = 1'b1;
        @(posedge clk);

        @(negedge clk);
        update_en = 1'b0;
        PC        = 10'h015 ^ 10'h00f;
        @(posedge clk);
        #1;
        check("FSM saturates at S_TAKEN (11) & GHR=0x00f", pred_index === 10'h015 && pred_state === 2'b11 && pred === 1'b1);

        // Transition S_TAKEN (11) + not-taken -> W_TAKEN (10); GHR: 10'h00f -> 10'h01e
        @(negedge clk);
        update_en        = 1'b1;
        update_index     = 10'h015;
        update_old_state = 2'b11;
        branch_taken     = 1'b0;
        @(posedge clk);

        @(negedge clk);
        update_en = 1'b0;
        PC        = 10'h015 ^ 10'h01e;
        @(posedge clk);
        #1;
        check("FSM S_TAKEN -> W_TAKEN on not-taken & GHR=0x01e", pred_index === 10'h015 && pred_state === 2'b10 && pred === 1'b1);

        $display("tb_branch_gshare Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count != 0) $fatal(1, "tb_branch_gshare FAILED");
        $finish;
    end
endmodule
