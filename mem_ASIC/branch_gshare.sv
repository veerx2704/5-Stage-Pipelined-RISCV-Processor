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
    localparam UNUSED_ACCOMODATION = 6;
    localparam TABLE_DEPTH = 2 ** GSHARE_BITS;
    logic [GSHARE_BITS - 1:0] GHR;
    logic [GSHARE_BITS - 1:0] GHR_comb;
    logic [UNUSED_ACCOMODATION + STATE_BITS - 1:0] PHT [0 : TABLE_DEPTH - 1];
    logic [UNUSED_ACCOMODATION + STATE_BITS - 1:0] next_path;


    typedef enum logic [STATE_BITS - 1:0] {
        S_NOT_TAKEN,
        W_NOT_TAKEN,
        W_TAKEN,
        S_TAKEN
    } state_t;
    
    state_t next_state;
    
    logic [GSHARE_BITS - 1:0] table_index;
    logic [GSHARE_BITS - 1:0] table_index_reg;
    logic pred_reg;
    
    assign pred = pred_reg;
    
    logic [UNUSED_ACCOMODATION + STATE_BITS - 1:0] pht_rdata;
    
    always_comb begin
        table_index = GHR ^ PC;
        GHR_comb = {pred_reg,GHR[GSHARE_BITS - 2:0]};
        next_state = W_NOT_TAKEN;
        if (branch) begin
            case(next_path[STATE_BITS - 1:0])
                S_NOT_TAKEN: next_state = W_NOT_TAKEN;
                W_NOT_TAKEN: next_state = W_TAKEN;
                W_TAKEN: next_state = S_TAKEN;
                S_TAKEN: next_state = S_TAKEN;
            endcase
        end
        else begin
            case(next_path[STATE_BITS - 1:0])
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
	    pred_reg <= '0;
	    table_index_reg <= '0;
	    pht_rdata <= '0;
        end
        else begin
            PHT[table_index] <= {{UNUSED_ACCOMODATION{1'b0}},next_state};
            GHR <= GHR_comb;
            table_index_reg <= table_index;
            pht_rdata <= PHT[table_index_reg];
            pred_reg <= pht_rdata[STATE_BIT - 1];
	    next_path <= pht_rdata[table_index_reg];
        end
    end
    
endmodule
