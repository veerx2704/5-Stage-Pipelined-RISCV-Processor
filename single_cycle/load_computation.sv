`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/20/2026 08:29:55 PM
// Design Name: 
// Module Name: load_computation
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
    input wire [1:0] byte_offset,
    output wire [WIDTH-1:0] Result
    );
    
    // Direct 4:1 byte mux and 2:1 halfword mux (avoids variable barrel shifter on SRAM read path)
    wire [7:0]  sel_byte = (byte_offset == 2'b00) ? DataMem[7:0]   :
                           (byte_offset == 2'b01) ? DataMem[15:8]  :
                           (byte_offset == 2'b10) ? DataMem[23:16] :
                                                    DataMem[31:24];
    wire [15:0] sel_half = byte_offset[1] ? DataMem[31:16] : DataMem[15:0];

    reg [WIDTH-1:0] computed_out;
    always_comb begin
        computed_out = DataMem;
        case(control)
            3'b001: computed_out = {{16{sel_half[15]}}, sel_half}; // lh
            3'b101: computed_out = {16'b0, sel_half};              // lhu
            3'b100: computed_out = {24'b0, sel_byte};              // lbu
            3'b000: computed_out = {{24{sel_byte[7]}}, sel_byte};  // lb
        endcase
    end
    
    assign Result = computed_out;
endmodule
