module dynamic_branch_pred #(
        parameter LOCAL_DEPTH = 5,
        parameter GLOBAL_DEPTH = 12,
        parameter LOCAL_TABLE_ENTRY = 3
)(
        input logic clk,
        input logic rst,
        input logic branch_taken,
        input logic [LOCAL_DEPTH - 1:0] PC,
        output logic branch_pred
);

    logic current_pred, global_pred, local_pred;
    global_design #(.DEPTH(GLOBAL_DEPTH)
               ) GP(.clk(clk),
                    .rst(rst),
                    .taken(branch_taken),
                    .local_prediction(local_pred),
                    .global_prediction(global_pred),
                    .current_prediction(current_pred));
    local_design  #(.LOCAL_DEPTH(LOCAL_DEPTH),
                    .TABLE_ENTRY(LOCAL_TABLE_ENTRY)
              ) LP (.clk(clk),
                    .rst(rst),
                    .PC(PC),
                    .taken(taken),
                    .local_prediction(local_pred));
    assign branch_pred = current_pred ? global_pred : local_pred;

endmodule