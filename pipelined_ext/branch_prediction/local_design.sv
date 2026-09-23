`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 06:37:48 PM
// Design Name: 
// Module Name: local_design
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


module local_design #(
        parameter LOCAL_DEPTH = 5,
        parameter TABLE_ENTRY = 3
)(
        input logic clk,
        input logic rst,
        input logic [LOCAL_DEPTH - 1:0] PC,
        input logic taken,
        output logic local_prediction
    );
    
    logic [LOCAL_DEPTH - 1:0] local_history;
    
    local_history #(.LOCAL_DEPTH(LOCAL_DEPTH)
              ) LH (.clk(clk),
                    .rst(rst),
                    .PC(PC),
                    .taken(taken),
                    .history(local_history));
                    
    local_pred     #(.LOCAL_DEPTH(LOCAL_DEPTH),
                     .TABLE_ENTRY(TABLE_ENTRY)
               ) LP (.clk(clk),
                     .rst(rst),
                     .taken(taken),
                     .local_history_result(local_history),
                     .prediction(local_prediction));
    
endmodule
