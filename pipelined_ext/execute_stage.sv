module execute_stage(
    input wire clk,
    input wire rst,
    input wire flush_EXMEM,
    
    // Datapath signal inputs
    input wire [31:0] rs1_IDEX,
    input wire [31:0] rs2_IDEX,
    input wire [31:0] imm_value_IDEX,
    input wire [31:0] PC_plus4_IDEX,
    input wire [31:0] target_address_IDEX,
    input wire [4:0] rs1_addr_IDEX,
    input wire [4:0] rs2_addr_IDEX,
    input wire [4:0] rd_IDEX,
    
    // Forward unit data signals
    input wire [31:0] forward_data_WB,
    input wire [31:0] forward_data_MEM,
    
    // Control signal inputs
    // EX stage
    input wire [3:0] ALUCode_IDEX,
    input wire [2:0] funct3_IDEX,
    input wire ALUSrc_IDEX,
    input wire branch_IDEX,
    input wire jump_IDEX,
    
    // MEM stage
    input wire [2:0] load_control_IDEX,
    input wire [1:0] store_control_IDEX,
    input wire mem_read_IDEX,
    input wire mem_write_IDEX,
    
    // WB stage
    input wire ResultSrc_IDEX,
    input wire reg_write_IDEX,
    
    // Forward logic signals
    input wire [1:0] forwardA,
    input wire [1:0] forwardB,
    
    // Combinational EX outputs for 1-cycle synchronous SRAM/BRAM launch in MEM
    output wire [31:0] ALUOut_EX_comb,
    output wire [31:0] store_data_EX_comb,
    output wire mem_write_EX_comb,
    output wire mem_read_EX_comb,
    output wire [1:0] store_control_EX_comb,
    
    // Branch/Jump redirect outputs to IF & Hazard Unit
    output wire PCSrc_EX,
    output wire [31:0] target_address_EX,
    
    // Datapath signal outputs (EX/MEM registered)
    output wire [31:0] ALUOut_EXMEM,
    output wire [31:0] PC_plus4_EXMEM,
    output wire [31:0] srcB_data_EXMEM,
    output wire [4:0] rd_EXMEM,
    
    // Forward unit signals
    output wire [4:0] rs1_forward_compare,
    output wire [4:0] rs2_forward_compare,
    
    // Hazard unit signal
    output wire [4:0] rd_hazard,
    
    // Control path signal outputs (EX/MEM registered)
    output wire mem_write_EXMEM,
    output wire mem_read_EXMEM,
    output wire [1:0] store_control_EXMEM,
    output wire [2:0] load_control_EXMEM,
    output wire jump_EXMEM,
    output wire ResultSrc_EXMEM,
    output wire reg_write_EXMEM,
    
    // Hazard unit signals
    output wire mem_write_hazard,
    output wire mem_read_hazard,
    output wire [1:0] store_control_hazard,
    output wire [2:0] load_control_hazard
);

wire [31:0] ALU_inA;
wire [31:0] ALU_inB;
wire [31:0] ALU_data_sourceB;
wire [31:0] ALUOut;
wire [31:0] ALU_sum;
wire zero;
wire LT;
wire LTU;
wire branch_taken;

assign ALU_inA = forwardA[1] ? 
                    (forwardA[0] ? rs1_IDEX : forward_data_MEM)
                 :  (forwardA[0] ? forward_data_WB : rs1_IDEX);
                 
assign ALU_data_sourceB = forwardB[1] ?
                             (forwardB[0] ? rs2_IDEX : forward_data_MEM)
                          :  (forwardB[0] ? forward_data_WB : rs2_IDEX);

assign ALU_inB = ALUSrc_IDEX ? imm_value_IDEX :
                 forwardB[1] ? (forwardB[0] ? rs2_IDEX : forward_data_MEM) :
                               (forwardB[0] ? forward_data_WB : rs2_IDEX);

ALU ALU_ACTUAL (    .DataA(ALU_inA),
                    .DataB(ALU_inB),
                    .ALUCode(ALUCode_IDEX),
                    .ALU_out(ALUOut),
                    .sum_out(ALU_sum),
                    .zero(zero),
                    .LT(LT),
                    .LTU(LTU));

branch_decoder BRANCH_RESOLVE ( .branch(branch_IDEX),
                                .funct3(funct3_IDEX),
                                .zero(zero),
                                .LT(LT),
                                .LTU(LTU),
                                .PC_src(branch_taken));

// Combinational EX outputs for lockstep synchronous SRAM/BRAM capture
assign ALUOut_EX_comb        = ALU_sum;
assign store_data_EX_comb    = ALU_data_sourceB;
assign mem_write_EX_comb     = flush_EXMEM ? 1'b0 : mem_write_IDEX;
assign mem_read_EX_comb      = flush_EXMEM ? 1'b0 : mem_read_IDEX;
assign store_control_EX_comb = store_control_IDEX;

reg [31:0] ALUOut_reg;
reg [31:0] PC_plus4_reg;
reg [31:0] sourceB_reg;
reg [4:0] rd_EXMEM_reg;
reg mem_read_reg;
reg mem_write_reg;
reg [1:0] store_control_reg;
reg [2:0] load_control_reg;
reg jump_reg;
reg ResultSrc_reg;
reg reg_write_reg;
reg PCSrc_reg;
reg [31:0] target_address_reg;

always_ff @(posedge clk) begin
    if (!rst) begin
        ALUOut_reg         <= '0;
        PC_plus4_reg       <= '0;
        sourceB_reg        <= '0;
        rd_EXMEM_reg       <= '0;
        mem_read_reg       <= '0;
        mem_write_reg      <= '0;
        store_control_reg  <= '0;
        load_control_reg   <= '0;
        jump_reg           <= '0;
        ResultSrc_reg      <= '0;
        reg_write_reg      <= '0;
        PCSrc_reg          <= '0;
        target_address_reg <= '0;
    end
    else begin
        ALUOut_reg         <= ALUOut;
        PC_plus4_reg       <= PC_plus4_IDEX;
        sourceB_reg        <= ALU_data_sourceB;
        rd_EXMEM_reg       <= flush_EXMEM ? 5'b0 : rd_IDEX;
        mem_read_reg       <= flush_EXMEM ? 1'b0 : mem_read_IDEX;
        mem_write_reg      <= flush_EXMEM ? 1'b0 : mem_write_IDEX;
        store_control_reg  <= store_control_IDEX;
        load_control_reg   <= load_control_IDEX;
        jump_reg           <= flush_EXMEM ? 1'b0 : jump_IDEX;
        ResultSrc_reg      <= flush_EXMEM ? 1'b0 : ResultSrc_IDEX;
        reg_write_reg      <= flush_EXMEM ? 1'b0 : reg_write_IDEX;
        PCSrc_reg          <= flush_EXMEM ? 1'b0 : (branch_taken | jump_IDEX);
        target_address_reg <= target_address_IDEX;
    end
end

assign PCSrc_EX          = PCSrc_reg;
assign target_address_EX = target_address_reg;

// Datapath signal outputs
assign ALUOut_EXMEM    = ALUOut_reg;
assign PC_plus4_EXMEM  = PC_plus4_reg;
assign srcB_data_EXMEM = sourceB_reg;
assign rd_EXMEM        = rd_EXMEM_reg;

// Forward unit signals
assign rs1_forward_compare = rs1_addr_IDEX;
assign rs2_forward_compare = rs2_addr_IDEX;

// Hazard unit signal
assign rd_hazard = rd_IDEX;

// Control path signal outputs
assign mem_write_EXMEM     = mem_write_reg;
assign mem_read_EXMEM      = mem_read_reg;
assign store_control_EXMEM = store_control_reg;
assign load_control_EXMEM  = load_control_reg;
assign jump_EXMEM          = jump_reg;
assign reg_write_EXMEM     = reg_write_reg;
assign ResultSrc_EXMEM     = ResultSrc_reg;

// Hazard unit signals
assign mem_write_hazard     = mem_write_IDEX;
assign mem_read_hazard      = mem_read_IDEX;
assign store_control_hazard = store_control_IDEX;
assign load_control_hazard  = load_control_IDEX;

endmodule
