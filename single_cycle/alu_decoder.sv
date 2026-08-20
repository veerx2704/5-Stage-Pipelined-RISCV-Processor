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
            7'd35: ALUCode_reg = 4'b0000;                                               //S-Type
            7'd51: begin                                                                //R-Type 
                        ALUSrc_reg = 1'b0;                                              //source = Reg
                        case(funct3)
                            3'b000: ALUCode_reg = funct7_b5 ? 4'b0001: 4'b0000;     //funct7[5] = 0 -> ADD funct7[1] = 1 -> SUB
                            3'b001: ALUCode_reg = 4'b0101;                          //SLL
                            3'b010: ALUCode_reg = 4'b0100;                          //SLT
                            3'b011: ALUCode_reg = 4'b0110;                          //SLTU
                            3'b100: ALUCode_reg = 4'b0010;                          //XOR
                            3'b101: ALUCode_reg = funct7_b5 ? 4'b1100 : 4'b1101;    //funct7[5] = 0 -> SRL funct7[5] = 1 -> SRA
                            3'b110: ALUCode_reg = 4'b0011;                          //OR
                            3'b111: ALUCode_reg = 4'b0111;                          //AND
                        endcase
                   end
            7'd19: begin                                                                //I-Type
                        case(funct3)
                            3'b000: ALUCode_reg = 4'b0000;                          //ADDI
                            3'b001: ALUCode_reg = 4'b0101;                          //SLLI
                            3'b010: ALUCode_reg = 4'b0100;                          //SLTI
                            3'b011: ALUCode_reg = 4'b0110;                          //SLTUI
                            3'b100: ALUCode_reg = 4'b0010;                          //XORI
                            3'b101: ALUCode_reg = funct7_b5 ? 4'b1100 : 4'b1101;    //funct7[5] = 0 -> SRLI funct7[5] = 1 -> SRAI
                            3'b110: ALUCode_reg = 4'b0011;                          //ORI
                            3'b111: ALUCode_reg = 4'b0111;                          //ANDI
                        endcase
                   end
             7'd3: ALUCode_reg = 4'b0000;                                               //I-Type (load)
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
             7'd111: ALUCode_reg = 4'b0000;                                             //JAL
             default: begin ALUCode_reg = 4'b0000; ALUSrc_reg = 1'b0; end
        endcase
    end
    
    assign ALUCode = ALUCode_reg;
    assign ALUSrc = ALUSrc_reg;
endmodule