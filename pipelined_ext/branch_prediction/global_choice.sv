`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 06:37:48 PM
// Design Name: 
// Module Name: global_choice
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


module global_choice #(
        parameter PATH_DEPTH = 12
)(
        input logic clk,
        input logic rst,
        input taken,
        input local_pred,
        input logic [PATH_DEPTH - 1:0] p_history,
        output logic global_pred,
        output logic current_pred
    );
    
    localparam PATH_ENTRY = 2 ** PATH_DEPTH;
    
    logic [1:0] g_pred, c_pred;
    logic [1:0] g_pred_comb, c_pred_comb;
    logic [1:0] global_pred_net, current_pred_net;
    bit gp, lp;
    assign global_pred_net = g_pred > 1 ? 1 : 0;
    assign global_pred = global_pred_net;
    assign current_pred_net = c_pred > 1 ? 1 : 0;
    assign current_pred = current_pred_net;
    assign gp = global_pred_net == taken ? 1 : 0;
    assign gp = global_pred_net == taken ? 1 : 0;
    
    logic counter;
    logic counter_comb;
    
    logic [1:0] GP [0:PATH_ENTRY - 1] = '{default: 0};
    logic [1:0] GP_comb = '{default: 0};
    logic [1:0] CP [0:PATH_ENTRY - 1] = '{default: 0};
    logic [1:0] CP_comb = '{default: 0};
    
    always_comb begin
        CP_comb = CP[p_history];
        GP_comb = GP[p_history];
        g_pred_comb = g_pred;
        c_pred_comb = c_pred;
        counter_comb = counter;
        if (!counter) begin
            g_pred_comb = GP[p_history];
            c_pred_comb = CP[p_history];
            counter_comb = 1'b1;
        end
        else begin
            if (taken) begin
                GP_comb = g_pred < 3 ? g_pred + 1'b1 : g_pred;
            end
            else begin
                GP_comb = g_pred > 0 ? g_pred - 1'b1 : g_pred;
            end
        end
        
        unique case({gp,lp})
            0: CP_comb = c_pred;
            1: CP_comb = (c_pred == 0) ? c_pred : c_pred - 1;
            2: CP_comb = (c_pred == 3) ? c_pred : c_pred + 1;
            3: CP_comb = c_pred;
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (!rst) begin
            CP <= '{default: '0};
            GP <= '{default: '0};
            g_pred <= '0;
            c_pred <= '0;
            counter <= '0;
        end
        else begin
            g_pred <= g_pred_comb;
            c_pred <= c_pred_comb;
            counter <= counter_comb;
            CP[p_history] <= CP_comb;
            GP[p_history] <= GP_comb;
        end
    end
    
endmodule
