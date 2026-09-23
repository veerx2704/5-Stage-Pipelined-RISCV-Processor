`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 06:37:48 PM
// Design Name: 
// Module Name: local_pred
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


module local_pred #(
        parameter LOCAL_DEPTH = 5,
        parameter TABLE_ENTRY = 3
)(
        input logic clk,
        input logic rst,
        input taken,
        input logic [LOCAL_DEPTH - 1:0] local_history_result,
        output logic prediction
    );
    
    localparam TABLE_DEPTH = 2 ** LOCAL_DEPTH;
    
    logic [TABLE_ENTRY - 1:0] prediction_table [TABLE_DEPTH - 1:0] ;
    logic [TABLE_ENTRY - 1:0] prediction_entry ;
    logic [TABLE_ENTRY - 1:0] local_prediction;
    logic [TABLE_ENTRY - 1:0] local_pred_comb;
    
    assign prediction = local_prediction > 3 ? 1'b1 : 1'b0;
    
    logic [TABLE_ENTRY - 1:0] state, next_state;
    
    always_comb begin
        prediction_entry = prediction_table[local_history_result];
        local_pred_comb = local_prediction;
        case(state)
            1: local_pred_comb = prediction_table[local_history_result];
            5: begin
                if(taken) begin
                    prediction_entry = local_prediction < 7 ? local_prediction + 1'b1 : local_prediction;
                end
                else begin
                    prediction_entry = local_prediction > 0 ? local_prediction - 1'b1 : local_prediction;
                end
            end
        endcase
        next_state = state + 1;
    end
    
    always_ff @(posedge clk) begin
        if (!rst) begin
            prediction_table <= '{default: '0};
            local_prediction <= '0;
            state <= '0;
        end
        else begin
            state <= next_state;
            local_prediction <= local_pred_comb;
            prediction_table[local_history_result] <= prediction_entry;
            
        end
    end
    
endmodule
