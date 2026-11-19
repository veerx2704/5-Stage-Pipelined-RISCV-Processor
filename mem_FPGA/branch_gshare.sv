`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/25/2026 05:37:04 PM
// Design Name: 
// Module Name: branch_gshare
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


module branch_gshare #(
        parameter GSHARE_BITS = 10
)(
        input logic clk,
        input logic rst,
        input logic [GSHARE_BITS - 1:0] PC,
        input logic branch,
        output logic pred
    );
    
    localparam STATE_BITS = 2;
    localparam TABLE_DEPTH = 2 ** GSHARE_BITS;
    logic [GSHARE_BITS - 1:0] GHR;
    logic [GSHARE_BITS - 1:0] GHR_comb;
    (* ram_style = "block" *)
    logic [STATE_BITS - 1:0] PHT [0 : TABLE_DEPTH - 1];
    logic [STATE_BITS - 1:0] pht_rdata;
    
    typedef enum logic [STATE_BITS - 1:0] {
        S_NOT_TAKEN,
        W_NOT_TAKEN,
        W_TAKEN,
        S_TAKEN
    } state_t;

    initial begin
        for (int i = 0; i < TABLE_DEPTH; i++)
            PHT[i] = W_NOT_TAKEN;
    end
    
    state_t next_state;
    
    logic [GSHARE_BITS - 1:0] table_index;
    
    assign pred = pht_rdata[STATE_BITS - 1];
    
    always_comb begin
        table_index = GHR ^ PC;
        GHR_comb = {pred,GHR[GSHARE_BITS - 2:0]};
        next_state = W_NOT_TAKEN;
        if (branch) begin
            case(pht_rdata)
                S_NOT_TAKEN: next_state = W_NOT_TAKEN;
                W_NOT_TAKEN: next_state = W_TAKEN;
                W_TAKEN: next_state = S_TAKEN;
                S_TAKEN: next_state = S_TAKEN;
            endcase
        end
        else begin
            case(pht_rdata)
                S_NOT_TAKEN: next_state = S_NOT_TAKEN;
                W_NOT_TAKEN: next_state = S_NOT_TAKEN;
                W_TAKEN: next_state = W_NOT_TAKEN;
                S_TAKEN: next_state = W_TAKEN;
            endcase
        end
    end
    
    always_ff @(posedge clk) begin
        if (!rst) begin
            GHR <= '0;
            pht_rdata <= W_NOT_TAKEN;
        end
        else begin
            PHT[table_index] <= next_state;
            pht_rdata <= PHT[table_index];
            GHR <= GHR_comb;
        end
    end
    
endmodule
