`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 06:37:48 PM
// Design Name: 
// Module Name: local_history
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


module local_history #(
        parameter LOCAL_DEPTH = 5
)(
        input logic clk,
        input logic rst,
        input logic [LOCAL_DEPTH - 1:0] PC,
        input logic taken,
        output logic [LOCAL_DEPTH - 1:0] history
    );
    
    localparam TABLE_ENTRY = 2 ** LOCAL_DEPTH;
    
    logic [2:0] counter;
    logic [2:0] counter_comb;
    logic [LOCAL_DEPTH - 1:0] history_table [0: TABLE_ENTRY - 1] = '{default: '0};
    logic [LOCAL_DEPTH - 1:0] history_entry_comb = '{default: '0};
    logic [LOCAL_DEPTH - 1:0] local_history;
    logic [LOCAL_DEPTH - 1:0] local_history_comb;
    
    assign history = local_history;
    
    always_comb begin
        counter_comb = counter;
        history_entry_comb = history_table[PC];
        local_history_comb = local_history;
        if (counter == 0) begin
            local_history = history_table[PC];
            counter_comb++;
        end
        else if (counter == 3'd5) begin
            history_entry_comb = taken ? {history_table[PC], 1'b1} : {history_table[PC], 1'b0};
            counter_comb++;
        end
        else if (&counter) begin
            counter_comb = '0;
        end
        else begin
            counter_comb++;
        end
    end
    
    
    always_ff @(posedge clk) begin
        if (!rst) begin
            history_table <= '{default: '0};
            local_history <= '0;
            counter <= '0;
        end
        else begin
            local_history <= local_history_comb;
            counter <= counter_comb;
            history_table[PC] <= history_entry_comb;
        end
    end
    
    
endmodule
