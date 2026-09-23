`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 06:37:48 PM
// Design Name: 
// Module Name: path_history
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


module path_history #(
        parameter DEPTH = 12
)(
        input logic clk,
        input logic rst,
        input logic pred,
        output logic [DEPTH - 1:0] p_history
    );
    
    logic state, next_state;
    logic [DEPTH - 1:0] history;
    logic [DEPTH - 1:0] history_comb;
    
    assign p_history = history;
    
    always_comb begin
        history_comb = history;
        next_state = state;
        
        case(state)
            0: next_state = state;
            1: begin
                history = {pred, history[DEPTH - 1:1]};
                next_state = ~state;
            end
        endcase
    end
    
    
    always_ff @(posedge clk) begin
        if (!rst) begin
            history <= '0;
            state <= '0;
        end
        else begin
            history <= history_comb;
            state <= next_state;
        end
    end
    
    
    
endmodule
