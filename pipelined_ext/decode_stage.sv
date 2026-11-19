module decode_stage(
        input wire clk,
        input wire rst,
        input wire hazard_stall,
        input wire [31:0] inst_IFID,
        input wire [31:0] PC_IFID,
        input wire reg_write_WB,
        input wire [4:0] Rd_MEMWB_forwarded,
        input wire [31:0] WData_WB_forwarded,
        
        output wire [31:0] inst_hazard,         //instruction for forwarding to hazard unit
        
        // Datapath signals 
        output wire [31:0] rs1_IDEX,            //rs1 data
        output wire [31:0] rs2_IDEX,            //rs2 data
        output wire [31:0] imm_value_IDEX,           
        output wire [31:0] target_address,      //branch target address
        output wire [4:0] rs1_addr_IDEX,        //address of rs1 to determine forwarding in EX stage
        output wire [4:0] rs2_addr_IDEX,        //adress of rs2 to determine forwarding in EX stage
        output wire [4:0] rd_IDEX,              //writeback address for forwarding to EX stage
        
        //control path signals to send to next stage
        output wire [3:0] ALUCode_IDEX,
        output wire [2:0] load_control_IDEX,
        output wire [1:0] store_control_IDEX,
        output wire ALUSrc_IDEX,
        output wire jump_IDEX,
        output wire mem_read_IDEX,
        output wire mem_write_IDEX,
        output wire ResultSrc_IDEX,
        output wire reg_write_IDEX,
        
        //control path signals to send to previous stage
        output wire PCSrc_IF
    );
    
    wire [4:0] rs1_addr = inst_IFID[19:15];
    wire [4:0] rs2_addr = inst_IFID[24:20];
    wire [4:0] rd_addr  = inst_IFID[11:7];
    wire [31:0] imm_value;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [6:0] opcode = inst_IFID[6:0];
    wire [2:0] funct3 = inst_IFID[14:12];
    wire funct7_b5 = inst_IFID[30];
    
    //CONTROL SIGNAL INPUTS (tied low in ID until branch resolution moves to EX)
    wire zero = 1'b0;
    wire LT   = 1'b0;
    wire LTU  = 1'b0;
    
    //CONTROL_SIGNAL_OUTPUTS
    wire u_type;
    wire [1:0] imm_src;
    wire [3:0] ALUCode;
    wire [1:0] store_control;
    wire [2:0] load_control;
    wire mem_write;
    wire mem_read;
    wire reg_write_id;
    wire jump;
    wire ResultSrc;
    wire PCSrc;
    wire ALUSrc;
    
    //CONTROL SIGNAL OUTPUTS FOR NEXT STAGE
    reg [3:0] ALUCode_reg;
    reg [1:0] store_control_reg;
    reg [2:0] load_control_reg;
    reg mem_write_reg;
    reg mem_read_reg;
    reg reg_write_reg;
    reg jump_reg;
    reg ResultSrc_reg;
    reg PCSrc_reg;
    reg ALUSrc_reg;

    //Data path registers for sending to EX stage
    reg [31:0] rs1_reg;
    reg [31:0] rs2_reg;
    reg [31:0] imm_value_reg;
    reg [4:0] rs1_addr_reg;
    reg [4:0] rs2_addr_reg;
    reg [4:0] rd_addr_reg;

    PC_target TARGET_PC_ADDRESS (       .current_PC(PC_IFID),
                                        .imm_ext(imm_value), 
                                        .target_PC(target_address));
    
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
                                        .zero(zero),
                                        .LT(LT),
                                        .LTU(LTU),
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
                                        .PCSrc(PCSrc),
                                        .jump(jump));
    
    wire [3:0] ALUCode_muxed;
    wire [2:0] load_control_muxed;
    wire [1:0] store_control_muxed;
    wire PCSrc_muxed;
    wire jump_muxed;
    wire mem_read_muxed;
    wire mem_write_muxed;
    wire ResultSrc_muxed;
    wire ALUSrc_muxed;
    wire reg_write_muxed;
    
    //stall next instruction when forwarding is not possible
    assign ALUCode_muxed            = hazard_stall ? '0 : ALUCode;
    assign load_control_muxed       = hazard_stall ? '0 : load_control;
    assign store_control_muxed      = hazard_stall ? '0 : store_control;
    assign PCSrc_muxed              = hazard_stall ? '0 : PCSrc;
    assign jump_muxed               = hazard_stall ? '0 : jump;
    assign mem_read_muxed           = hazard_stall ? '0 : mem_read;
    assign mem_write_muxed          = hazard_stall ? '0 : mem_write;
    assign ResultSrc_muxed          = hazard_stall ? '0 : ResultSrc;
    assign ALUSrc_muxed             = hazard_stall ? '0 : ALUSrc;
    assign reg_write_muxed          = hazard_stall ? '0 : reg_write_id;
    
    // EX stage signals
    always_ff @(posedge clk) begin
        if (!rst) begin
            PCSrc_reg <= '0;
            ALUCode_reg <= '0;
            jump_reg <= '0;   
            ALUSrc_reg <= '0;         
        end
        else begin
            PCSrc_reg <= PCSrc_muxed;
            ALUCode_reg <= ALUCode_muxed;
            jump_reg <= jump_muxed;
            ALUSrc_reg <= ALUSrc_muxed;
        end
    end
    
    //MEM stage signals
    always_ff @(posedge clk) begin
        if (!rst) begin
            mem_read_reg <= '0;
            mem_write_reg <= '0;
            store_control_reg <= '0;
            load_control_reg <= '0;
        end
        else begin
            mem_read_reg <= mem_read_muxed;
            mem_write_reg <= mem_write_muxed;
            store_control_reg <= store_control_muxed;
            load_control_reg <= load_control_muxed;
        end
    end
    
    //Writeback stage signals
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
    
    //Datapath signals
    always_ff @(posedge clk) begin
        if (!rst) begin
            rs1_reg <= '0;
            rs2_reg <= '0;
            imm_value_reg <= '0;
            rs1_addr_reg <= '0;
            rs2_addr_reg <= '0;
            rd_addr_reg  <= '0;
        end
        else begin
            rs1_reg <= rs1_data;
            rs2_reg <= rs2_data;
            imm_value_reg <= imm_value;
            rs1_addr_reg <= rs1_addr;
            rs2_addr_reg <= rs2_addr;
            rd_addr_reg  <= rd_addr;
        end
    end

    //Hazard unit output
    assign inst_hazard = inst_IFID;

    //Datapath output signals
    assign rs1_IDEX = rs1_reg;
    assign rs2_IDEX = rs2_reg;
    assign imm_value_IDEX = imm_value_reg;
    assign rs1_addr_IDEX = rs1_addr_reg;
    assign rs2_addr_IDEX = rs2_addr_reg;
    assign rd_IDEX = rd_addr_reg;
        
    //Control path output signals
    
    //EX stage signals
    assign ALUCode_IDEX = ALUCode_reg;
    assign ALUSrc_IDEX = ALUSrc_reg;
    assign jump_IDEX = jump_reg;
    
    //MEM stage signals
    assign load_control_IDEX = load_control_reg;
    assign store_control_IDEX = store_control_reg;
    assign mem_write_IDEX = mem_write_reg;
    assign mem_read_IDEX = mem_read_reg;
    
    // Writeback stage signals
    assign ResultSrc_IDEX = ResultSrc_reg;
    assign reg_write_IDEX = reg_write_reg;
    
    //PC source
    assign PCSrc_IF = PCSrc_reg;
    
endmodule
