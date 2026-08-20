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
    output wire [WIDTH-1:0] WData
    );
    
    reg [WIDTH-1:0] data_out;
    always_comb begin
        data_out = SrcData;
        case(Control)
            2'b10: data_out = SrcData;                                                      //sw or R/I/B/U/J Types
            2'b00: data_out = {{(WIDTH-8){SrcData[7]}},SrcData[7:0]};                       //sb
            2'b01: data_out = {{(WIDTH/2){SrcData[(WIDTH/2)-1]}},SrcData[(WIDTH/2)-1:0]};   //sh
            default: data_out = SrcData;
        endcase
    end
    assign WData = data_out;
endmodule
