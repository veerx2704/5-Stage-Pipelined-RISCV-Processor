`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2026 08:01:10 PM
// Design Name: 
// Module Name: main_decoder
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2026 08:01:10 PM
// Design Name: 
// Module Name: main_decoder
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


module main_decoder(
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    output wire mem_write,
    output wire mem_read,
    output wire branch,
    output wire reg_write,
    output wire jump,
    output wire u_type,
    output wire [1:0] imm_src,
    output wire [1:0] store_control,
    output wire [2:0] load_control,
    output wire ResultSrc
    );
    
    reg [13:0] mMBRegJUISLRes;      //{mem_read__mem_write__branch__reg_write__jump__u_type__imm_src__store_control__load_control__resultsrc}
    
    always_comb begin
        case(opcode)                 //mem_read  mem_write  branch reg_write jump    u_type imm_src store_control load_control resultsrc
            7'd0:  mMBRegJUISLRes =  { 1'b0,     1'b0,      1'b0,  1'b0,     1'b0,   1'b0,  2'b00,  2'b10,         3'b010,      1'bx};           // Reset
            7'd3:  mMBRegJUISLRes =  { 1'b1,     1'b0,      1'b0,  1'b1,     1'b0,   1'b0,  2'b00,  2'b10,         funct3,      1'b1};           //lw/lh/lb/lbu/lhu (I-Type)
            7'd19: mMBRegJUISLRes =  { 1'b0,     1'b0,      1'b0,  1'b1,     1'b0,   1'b0,  2'b00,  2'b10,         3'b010,      1'b0};           //I-Type
            7'd35: mMBRegJUISLRes =  { 1'b0,     1'b1,      1'b0,  1'b0,     1'b0,   1'b0,  2'b01,  funct3[1:0],   3'b010,      1'bx};           //S-Type
            7'd51: mMBRegJUISLRes =  { 1'b0,     1'b0,      1'b0,  1'b1,     1'b0,   1'b0,  2'bxx,  2'b10,         3'b010,      1'b0};           //R-Type
            7'd55: mMBRegJUISLRes =  { 1'b0,     1'b0,      1'b0,  1'b1,     1'b0,   1'b1,  2'b00,  2'b10,         3'b010,      1'b0};           //U-Type
            7'd103:mMBRegJUISLRes =  { 1'b0,     1'b0,      1'b1,  1'b0,     1'b0,   1'b0,  2'b10,  2'b10,         3'b010,      1'bx};           //B-Type
            7'd111:mMBRegJUISLRes =  { 1'b0,     1'b0,      1'b0,  1'b1,     1'b1,   1'b0,  2'b11,  2'b10,         3'b010,      1'b0};           //J-Type
            default: mMBRegJUISLRes = 14'bx;
        endcase
    end
    // resultsrc = 1 : Data comes from memory, resultsrc = 0: data forwarded from ALU
    assign {mem_read, mem_write, branch, reg_write, jump, u_type, imm_src, store_control, load_control, ResultSrc} = mMBRegJUISLRes;
    
endmodule