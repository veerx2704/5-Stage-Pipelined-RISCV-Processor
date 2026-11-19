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
        input  logic                     clk,
        input  logic                     rst,
        input  logic [GSHARE_BITS - 1:0] PC,
        input  logic                     update_en,
        input  logic [GSHARE_BITS - 1:0] update_index,
        input  logic [1:0]               update_old_state,
        input  logic                     branch_taken,
        output logic                     pred,
        output logic [GSHARE_BITS - 1:0] pred_index,
        output logic [1:0]               pred_state
    );
    
    localparam STATE_BITS = 2;
    localparam TABLE_DEPTH = 2 ** GSHARE_BITS;

    typedef enum logic [STATE_BITS - 1:0] {
        S_NOT_TAKEN = 2'b00,
        W_NOT_TAKEN = 2'b01,
        W_TAKEN     = 2'b10,
        S_TAKEN     = 2'b11
    } state_t;

    logic [GSHARE_BITS - 1:0] GHR;
    logic [GSHARE_BITS - 1:0] GHR_comb;
    (* ram_style = "block" *)
    logic [STATE_BITS - 1:0] PHT [0 : TABLE_DEPTH - 1];
    logic [STATE_BITS - 1:0] pht_rdata;

    initial begin
        for (int i = 0; i < TABLE_DEPTH; i++)
            PHT[i] = W_NOT_TAKEN;
    end

    state_t next_state;
    logic [GSHARE_BITS - 1:0] table_index;
    logic [GSHARE_BITS - 1:0] pred_index_reg;

    assign pred       = pht_rdata[STATE_BITS - 1];
    assign pred_state = pht_rdata;
    assign pred_index = pred_index_reg;

    always_comb begin
        table_index = GHR ^ PC;
        GHR_comb    = update_en ? {GHR[GSHARE_BITS - 2:0], branch_taken} : GHR;
        next_state  = W_NOT_TAKEN;
        if (branch_taken) begin
            case (update_old_state)
                S_NOT_TAKEN: next_state = W_NOT_TAKEN;
                W_NOT_TAKEN: next_state = W_TAKEN;
                W_TAKEN:     next_state = S_TAKEN;
                S_TAKEN:     next_state = S_TAKEN;
            endcase
        end else begin
            case (update_old_state)
                S_NOT_TAKEN: next_state = S_NOT_TAKEN;
                W_NOT_TAKEN: next_state = S_NOT_TAKEN;
                W_TAKEN:     next_state = W_NOT_TAKEN;
                S_TAKEN:     next_state = W_TAKEN;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (!rst) begin
            GHR            <= '0;
            pred_index_reg <= '0;
            pht_rdata      <= W_NOT_TAKEN;
        end else begin
            if (update_en) begin
                PHT[update_index] <= next_state;
            end
            GHR            <= GHR_comb;
            pred_index_reg <= table_index;
            pht_rdata      <= PHT[table_index];
        end
    end

endmodule
