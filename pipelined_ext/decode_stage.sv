module decode_stage(
        input wire clk,
        input wire rst,
        input wire hazard_stall,
        input wire flush_IDEX,
        input wire [31:0] inst_IFID,
        input wire [31:0] PC_IFID,
        input wire [31:0] PC_plus4_IFID,
        input wire reg_write_WB,
        input wire [4:0] Rd_MEMWB_forwarded,
        input wire [31:0] WData_WB_forwarded,
        input wire [1:0] fwdA_ID,               // pre-computed forwarding select for EX
        input wire [1:0] fwdB_ID,               // pre-computed forwarding select for EX
        
        output wire [31:0] inst_hazard,         // instruction for hazard unit
        output wire [4:0] rs1_addr_ID,          // combinational rs1 addr for ID-stage forward_unit
        output wire [4:0] rs2_addr_ID,          // combinational rs2 addr for ID-stage forward_unit
        
        // Datapath signals to EX stage
        output wire [31:0] rs1_IDEX,            // rs1 data
        output wire [31:0] rs2_IDEX,            // rs2 data
        output wire [31:0] imm_value_IDEX,
        output wire [31:0] PC_plus4_IDEX,       // PC+4 for JAL link address
        output wire [31:0] target_address_IDEX, // registered branch/jump target address
        output wire [4:0] rs1_addr_IDEX,        // address of rs1
        output wire [4:0] rs2_addr_IDEX,        // address of rs2
        output wire [4:0] rd_IDEX,              // destination register address
        output wire [1:0] fwdA_IDEX,            // registered forwarding select for EX
        output wire [1:0] fwdB_IDEX,            // registered forwarding select for EX
        
        // Control path signals to EX stage
        output wire [3:0] ALUCode_IDEX,
        output wire [2:0] funct3_IDEX,
        output wire [2:0] load_control_IDEX,
        output wire [1:0] store_control_IDEX,
        output wire ALUSrc_IDEX,
        output wire branch_IDEX,
        output wire jump_IDEX,
        output wire mem_read_IDEX,
        output wire mem_write_IDEX,
        output wire ResultSrc_IDEX,
        output wire reg_write_IDEX
    );
    
    wire [4:0] rs1_addr = inst_IFID[19:15];
    wire [4:0] rs2_addr = inst_IFID[24:20];
    wire [4:0] rd_addr  = inst_IFID[11:7];
    wire [31:0] imm_value;
    wire [31:0] target_address_comb;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [6:0] opcode = inst_IFID[6:0];
    wire [2:0] funct3 = inst_IFID[14:12];
    wire funct7_b5 = inst_IFID[30];
    
    // Control signals from control_unit
    wire u_type;
    wire [1:0] imm_src;
    wire [3:0] ALUCode;
    wire [1:0] store_control;
    wire [2:0] load_control;
    wire mem_write;
    wire mem_read;
    wire reg_write_id;
    wire branch;
    wire jump;
    wire ResultSrc;
    wire ALUSrc;
    
    // ID/EX control registers
    reg [3:0] ALUCode_reg;
    reg [2:0] funct3_reg;
    reg [1:0] store_control_reg;
    reg [2:0] load_control_reg;
    reg mem_write_reg;
    reg mem_read_reg;
    reg reg_write_reg;
    reg branch_reg;
    reg jump_reg;
    reg ResultSrc_reg;
    reg ALUSrc_reg;

    // ID/EX datapath registers
    reg [31:0] rs1_reg;
    reg [31:0] rs2_reg;
    reg [31:0] imm_value_reg;
    reg [31:0] PC_plus4_reg;
    reg [31:0] target_address_reg;
    reg [4:0] rs1_addr_reg;
    reg [4:0] rs2_addr_reg;
    reg [4:0] rd_addr_reg;
    reg [1:0] fwdA_reg;
    reg [1:0] fwdB_reg;

    PC_target TARGET_PC_ADDRESS (       .current_PC(PC_IFID),
                                        .imm_ext(imm_value), 
                                        .target_PC(target_address_comb));
    
    reg_file REGISTER_FILE (.clk(clk),  .SrcA(rs1_addr),
                                        .SrcB(rs2_addr),
                                        .DestC(Rd_MEMWB_forwarded),
                                        .WData(WData_WB_forwarded),
                                        .Wen(reg_write_WB),
                                        .RDataA(rs1_data),
                                        .RDataB(rs2_data));
    
    imm_extend IMMEDIATE_GENERATOR (    .imm_instr(inst_IFID[31:7]),
                                        .imm_src(imm_src),
                                        .u_type(u_type),
                                        .extended_num(imm_value));
                    
    control_unit CONTROL_UNIT (         .opcode(opcode),
                                        .funct3(funct3),
                                        .funct7_b5(funct7_b5),
                                        .zero(1'b0),
                                        .LT(1'b0),
                                        .LTU(1'b0),
                                        .ALUCode(ALUCode),
                                        .load_control(load_control),
                                        .imm_src(imm_src),
                                        .store_control(store_control),
                                        .ALUSrc(ALUSrc),
                                        .mem_write(mem_write),
                                        .mem_read(mem_read),
                                        .reg_write(reg_write_id),
                                        .u_type(u_type),
                                        .ResultSrc(ResultSrc),
                                        .PCSrc(),
                                        .branch(branch),
                                        .jump(jump));
    
    // Insert bubble on load-use stall OR control-hazard flush
    wire bubble_IDEX = hazard_stall | flush_IDEX;
    
    wire [3:0] ALUCode_muxed       = bubble_IDEX ? '0 : ALUCode;
    wire [2:0] funct3_muxed        = bubble_IDEX ? '0 : funct3;
    wire [2:0] load_control_muxed  = bubble_IDEX ? '0 : load_control;
    wire [1:0] store_control_muxed = bubble_IDEX ? '0 : store_control;
    wire branch_muxed              = bubble_IDEX ? '0 : branch;
    wire jump_muxed                = bubble_IDEX ? '0 : jump;
    wire mem_read_muxed            = bubble_IDEX ? '0 : mem_read;
    wire mem_write_muxed           = bubble_IDEX ? '0 : mem_write;
    wire ResultSrc_muxed           = bubble_IDEX ? '0 : ResultSrc;
    wire ALUSrc_muxed              = bubble_IDEX ? '0 : ALUSrc;
    wire reg_write_muxed           = bubble_IDEX ? '0 : reg_write_id;
    
    // EX stage control registers
    always_ff @(posedge clk) begin
        if (!rst) begin
            ALUCode_reg <= '0;
            funct3_reg  <= '0;
            branch_reg  <= '0;
            jump_reg    <= '0;
            ALUSrc_reg  <= '0;
        end
        else begin
            ALUCode_reg <= ALUCode_muxed;
            funct3_reg  <= funct3_muxed;
            branch_reg  <= branch_muxed;
            jump_reg    <= jump_muxed;
            ALUSrc_reg  <= ALUSrc_muxed;
        end
    end
    
    // MEM stage control registers
    always_ff @(posedge clk) begin
        if (!rst) begin
            mem_read_reg      <= '0;
            mem_write_reg     <= '0;
            store_control_reg <= '0;
            load_control_reg  <= '0;
        end
        else begin
            mem_read_reg      <= mem_read_muxed;
            mem_write_reg     <= mem_write_muxed;
            store_control_reg <= store_control_muxed;
            load_control_reg  <= load_control_muxed;
        end
    end
    
    // Writeback stage control registers
    always_ff @(posedge clk) begin
        if (!rst) begin
            ResultSrc_reg <= '0;
            reg_write_reg <= '0;
        end
        else begin
            ResultSrc_reg <= ResultSrc_muxed;
            reg_write_reg <= reg_write_muxed;
        end
    end
    
    // Datapath registers
    always_ff @(posedge clk) begin
        if (!rst) begin
            rs1_reg            <= '0;
            rs2_reg            <= '0;
            imm_value_reg      <= '0;
            PC_plus4_reg       <= '0;
            target_address_reg <= '0;
            rs1_addr_reg       <= '0;
            rs2_addr_reg       <= '0;
            rd_addr_reg        <= '0;
            fwdA_reg           <= 2'b00;
            fwdB_reg           <= 2'b00;
        end
        else begin
            rs1_reg            <= rs1_data;
            rs2_reg            <= rs2_data;
            imm_value_reg      <= imm_value;
            PC_plus4_reg       <= PC_plus4_IFID;
            target_address_reg <= target_address_comb;
            rs1_addr_reg       <= rs1_addr;
            rs2_addr_reg       <= rs2_addr;
            rd_addr_reg        <= bubble_IDEX ? 5'b0 : rd_addr;
            fwdA_reg           <= bubble_IDEX ? 2'b00 : fwdA_ID;
            fwdB_reg           <= bubble_IDEX ? 2'b00 : fwdB_ID;
        end
    end

    // Outputs
    assign inst_hazard         = inst_IFID;
    assign rs1_addr_ID         = rs1_addr;
    assign rs2_addr_ID         = rs2_addr;
    assign rs1_IDEX            = rs1_reg;
    assign rs2_IDEX            = rs2_reg;
    assign imm_value_IDEX      = imm_value_reg;
    assign PC_plus4_IDEX       = PC_plus4_reg;
    assign target_address_IDEX = target_address_reg;
    assign rs1_addr_IDEX       = rs1_addr_reg;
    assign rs2_addr_IDEX       = rs2_addr_reg;
    assign rd_IDEX             = rd_addr_reg;
    assign fwdA_IDEX           = fwdA_reg;
    assign fwdB_IDEX           = fwdB_reg;
    assign ALUCode_IDEX        = ALUCode_reg;
    assign funct3_IDEX         = funct3_reg;
    assign ALUSrc_IDEX         = ALUSrc_reg;
    assign branch_IDEX         = branch_reg;
    assign jump_IDEX           = jump_reg;
    assign load_control_IDEX   = load_control_reg;
    assign store_control_IDEX  = store_control_reg;
    assign mem_write_IDEX      = mem_write_reg;
    assign mem_read_IDEX       = mem_read_reg;
    assign ResultSrc_IDEX      = ResultSrc_reg;
    assign reg_write_IDEX      = reg_write_reg;
    
endmodule
