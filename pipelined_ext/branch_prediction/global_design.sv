`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 06:37:48 PM
// Design Name: 
// Module Name: global_design
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module global_design #(
        parameter DEPTH = 12
)(
        input logic clk,
        input logic rst,
        input logic taken,
        input logic local_prediction,
        output logic global_prediction,
        output logic current_prediction
    );
    
    logic [DEPTH - 1:0] P_history;
    
    global_choice #(.PATH_DEPTH(DEPTH)
              ) GC (.clk(clk),
                    .rst(rst),
                    .taken(taken),
                    .local_pred(local_prediction),
                    .p_history(p_history),
                    .global_pred(global_prediction),
                    .current_pred(current_prediction));
    path_history  #(.DEPTH(DEPTH)
              ) PH (.clk(clk),
                    .rst(rst),
                    .pred(taken),
                    .p_history(p_history));
    
endmodule
