module execute_stage(
    input wire clk,
    input wire rst,
    
    
    //Datapath signal inputs
    input wire [31:0] rs1_IDEX,
    input wire [31:0] rs2_IDEX,
    input wire [31:0] imm_value_IDEX,
    input wire [4:0] rs1_addr_IDEX,
    input wire [4:0] rs2_addr_IDEX,
    input wire [4:0] rd_IDEX,
    
    //Forward unit data signals
    input wire [31:0] forward_dataA_WB,
    input wire [31:0] forward_dataB_WB,
    input wire [31:0] forward_dataA_MEM,
    input wire [31:0] forward_dataB_MEM,
    
    //Control signal inputs
    
    // EX stage
    input wire [3:0] ALUCode_IDEX,
    input wire ALUSrc_IDEX,
    input wire jump_IDEX,
    
    //MEM stage
    input wire [2:0] load_control_IDEX,
    input wire [1:0] store_control_IDEX,
    input wire mem_read_IDEX,
    input wire mem_write_IDEX,    
    
    //WB stage
    input wire ResultSrc_IDEX,
    input wire reg_write_IDEX,
    
    //Forward logic signals
    
    input wire [1:0] forwardA,
    input wire [1:0] forwardB,
    
    //Datapath signal outputs
    output wire [31:0] ALUOut_EXMEM,
    output wire [31:0] srcB_data_EXMEM,
    output wire [4:0] rd_EXMEM,
    
    //Forward unit signal
    output wire [4:0] rs1_forward_compare,
    output wire [4:0] rs2_forward_compare,
    
    //Hazard unit signal
    output wire [4:0] rd_hazard,
    
    //Control path signal outputs
    output wire mem_write_EXMEM,
    output wire mem_read_EXMEM,
    output wire [1:0] store_control_EXMEM,
    output wire [2:0] load_control_EXMEM,
    output wire ResultSrc_EXMEM,
    output wire reg_write_EXMEM,
    
    //Hazard unit signals
    output wire mem_write_hazard,
    output wire mem_read_hazard,
    output wire [1:0] store_control_hazard,
    output wire [2:0] load_control_hazard
);

wire [31:0] ALU_inA;
wire [31:0] ALU_inB;
wire [31:0] ALU_data_sourceB;
wire [31:0] ALUOut;
wire zero;
wire LT;
wire LTU;

assign ALU_inA = forwardA[1] ? 
                    forwardA[0] ?  32'bx : forward_dataA_WB
                 :  forwardA[0] ?  forward_dataA_MEM : rs1_IDEX;
                 
assign ALU_data_sourceB = forwardB[1] ?
                             forwardB[0] ? 32'bx : forward_dataB_WB
                          :  forwardB[0] ? forward_dataB_MEM : rs2_IDEX;

assign ALU_inB = ALUSrc_IDEX ? imm_value_IDEX : ALU_data_sourceB;

ALU ALU_ACTUAL (    .DataA(ALU_inA),
                    .DataB(ALU_inB),
                    .ALUCode(ALUCode_IDEX),
                    .ALUOut(ALUOut),
                    .zero(zero),
                    .LT(LT),
                    .LTU(LTU)); 

wire [4:0] rs1_forward = rs1_IDEX;
wire [4:0] rs2_forward = rs2_IDEX;

reg [31:0] ALUOut_reg;
reg [31:0] sourceB_reg;
reg [4:0] rd_EXMEM_reg;
reg mem_read_reg;
reg mem_write_reg;
reg [1:0] store_control_reg;
reg [2:0] load_control_reg;
reg ResultSrc_reg;
reg reg_write_reg;


always_ff @(posedge clk) begin
    if (!rst) begin
        ALUOut_reg <= '0;
        sourceB_reg <= '0;
        rd_EXMEM_reg <= '0;
        mem_read_reg <= '0;
        mem_write_reg <= '0;
        store_control_reg <= '0;
        load_control_reg <= '0;
        ResultSrc_reg <= '0;
        reg_write_reg <= '0;
    end
    else begin
        ALUOut_reg <= ALUOut;
        sourceB_reg <= ALU_inB;
        rd_EXMEM_reg <= rd_IDEX;
        mem_read_reg <= mem_read_IDEX;
        mem_write_reg <= mem_write_IDEX;
        store_control_reg <= store_control_IDEX;
        load_control_reg <= load_control_IDEX;
        ResultSrc_reg <= ResultSrc_IDEX;
        reg_write_reg <= reg_write_IDEX;
    end
end

    //Datapath signal outputs
    assign ALUOut_EXMEM = ALUOut_reg;
    assign srcB_data_EXMEM = sourceB_reg;
    assign rd_EXMEM = rd_EXMEM_reg;
    
    //Forward unit signal
    assign rs1_forward_compare = rs1_forward;
    assign rs2_forward_compare = rs2_forward;
    
    //Hazard unit signal
    assign rd_hazard = rd_IDEX;
    
    //Control path signal outputs
    assign mem_write_EXMEM = mem_write_reg;
    assign mem_read_EXMEM = mem_read_reg;
    assign store_control_EXMEM = store_control_reg;
    assign load_control_EXMEM = load_control_reg;
    assign reg_write_EXMEM = reg_write_reg;
    assign ResultSrc_EXMEM = ResultSrc_reg;
    
    //Hazard unit signals
    assign mem_write_hazard = mem_write_IDEX;
    assign mem_read_hazard = mem_read_IDEX;
    assign store_control_hazard = store_control_IDEX;
    assign load_control_hazard = load_control_IDEX;
    assign ResultSrc_EXMEM = ResultSrc_reg;

endmodule