`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/20/2026 09:58:54 PM
// Design Name: 
// Module Name: store_computation
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


module store_computation #(parameter WIDTH = 32)(
    input wire [WIDTH-1:0] SrcData,
    input wire [1:0] Control,
    input wire [1:0] byte_offset,
    output wire [WIDTH-1:0] WData,
    output wire [3:0] wmask
    );
    
    reg [WIDTH-1:0] data_out;
    reg [3:0] wmask_out;
    always_comb begin
        data_out  = SrcData;
        wmask_out = 4'b1111;
        case(Control)
            2'b00: begin                                                // sb
                data_out  = {4{SrcData[7:0]}};
                wmask_out = 4'b0001 << byte_offset;
            end
            2'b01: begin                                                // sh
                data_out  = {2{SrcData[15:0]}};
                wmask_out = byte_offset[1] ? 4'b1100 : 4'b0011;
            end
            default: begin                                              // sw
                data_out  = SrcData;
                wmask_out = 4'b1111;
            end
        endcase
    end
    assign WData = data_out;
    assign wmask = wmask_out;
endmodule
