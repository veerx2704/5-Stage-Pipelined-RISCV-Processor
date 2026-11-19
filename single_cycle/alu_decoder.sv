module alu_decoder (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire funct7_b5,
    output wire [3:0] ALUCode,
    output wire ALUSrc
);

    reg ALUSrc_reg;
    reg [3:0] ALUCode_reg;
    
    always @(*) begin
        ALUCode_reg = 4'b0000;
        ALUSrc_reg = 1'b1;
        case(opcode)
            7'd35, 7'd3, 7'd111: ;                                                      //S-Type, Load, JAL (default ADD, ALUSrc=1)
            7'd51, 7'd19: begin                                                         //R-Type / I-Type
                        ALUSrc_reg = (opcode == 7'd19);
                        case(funct3)
                            3'b000: ALUCode_reg = ((opcode == 7'd51) && funct7_b5) ? 4'b0001 : 4'b0000; //ADD/SUB/ADDI
                            3'b001: ALUCode_reg = 4'b0101;                          //SLL/SLLI
                            3'b010: ALUCode_reg = 4'b0100;                          //SLT/SLTI
                            3'b011: ALUCode_reg = 4'b0110;                          //SLTU/SLTUI
                            3'b100: ALUCode_reg = 4'b0010;                          //XOR/XORI
                            3'b101: ALUCode_reg = funct7_b5 ? 4'b1100 : 4'b1101;    //SRL(I)/SRA(I)
                            3'b110: ALUCode_reg = 4'b0011;                          //OR/ORI
                            3'b111: ALUCode_reg = 4'b0111;                          //AND/ANDI
                        endcase
                   end
             7'd55: ALUCode_reg = 4'b1000;                                              //U-type (LUI)
             7'd103: begin
                        ALUSrc_reg = 1'b0;
                        case(funct3) 
                            3'b000: ALUCode_reg = 4'b0001;                              //BEQ
                            3'b001: ALUCode_reg = 4'b0001;                              //BNE
                            3'b100: ALUCode_reg = 4'b0100;                              //BLT
                            3'b110: ALUCode_reg = 4'b0110;                              //BLTU
                            default: ALUCode_reg = 4'b0000;                          
                        endcase
                     end
             default: begin ALUCode_reg = 4'b0000; ALUSrc_reg = 1'b0; end
        endcase
    end
    
    assign ALUCode = ALUCode_reg;
    assign ALUSrc = ALUSrc_reg;
endmodule