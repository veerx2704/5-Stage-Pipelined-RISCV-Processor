`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/20/2026 08:29:55 PM
// Design Name: 
// Module Name: ALU_WB
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


module load_computation #(parameter WIDTH = 32)(
    input wire [WIDTH-1:0] DataMem,
    input wire [2:0] control,
    output wire [WIDTH-1:0] Result
    );
    
    reg [WIDTH-1:0] computed_out;
    
    always_comb begin
        computed_out = DataMem;                                               
        case(control)
        3'b010: computed_out = DataMem;                                                        //lw
        3'b001: computed_out = {{(WIDTH/2){DataMem[(WIDTH/2) - 1]}},DataMem[(WIDTH/2)-1:0]};   //lh
        3'b101: computed_out = {'0, DataMem[(WIDTH/2) - 1:0]};                                 //lhu
        3'b100: computed_out = {'0, DataMem[7:0]};                                             //lbu
        3'b000: computed_out = {{(WIDTH-8){DataMem[7]}},DataMem[7:0]};                         //lb
        default: computed_out = DataMem;
        endcase
    end
    
    assign Result = computed_out;
endmodule
