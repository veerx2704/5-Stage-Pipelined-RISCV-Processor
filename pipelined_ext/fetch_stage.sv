module fetch_stage (
    input wire clk,
    input wire rst,
    input wire PCWrite,
    input wire IF_ID_write,
    input wire flush_IFID,              // squash IF/ID instruction to NOP on taken branch/jump
    input wire PCSrc,                   // source for next PC address
    input wire [31:0] target_address,   // target address in case of branch/jump
    output wire [31:0] PC_IFID,         // push to decode stage
    output wire [31:0] PC_plus4_IFID,   // PC+4 for JAL link writeback
    output wire [31:0] inst_IFID        // push to decode stage
);

localparam [31:0] NOP_INST = 32'h0000_0013; // ADDI x0, x0, 0

reg [31:0] PC_IFID_reg;
wire [31:0] PC_next;
PC_next NEXT_PC_ADDR(.current_PC(PC_IFID_reg), .next_PC(PC_next));

wire [31:0] PC_current;
wire [31:0] inst_intermediate;

assign PC_current = PCSrc ? target_address : PC_next;

// PC update (hold on stall)
always_ff @(posedge clk) begin
    if (!rst) begin
        PC_IFID_reg <= '0;
    end
    else begin
        if (PCWrite) begin
            PC_IFID_reg <= PC_current;
        end
    end
end

// IF/ID pipeline register (flush to NOP on control hazard, hold on stall)
reg [31:0] PC_ID_reg;
reg [31:0] PC_plus4_ID_reg;
reg [31:0] inst_reg;
always_ff @(posedge clk) begin
    if (!rst) begin
        PC_ID_reg       <= '0;
        PC_plus4_ID_reg <= '0;
        inst_reg        <= NOP_INST;
    end
    else if (flush_IFID) begin
        PC_ID_reg       <= '0;
        PC_plus4_ID_reg <= '0;
        inst_reg        <= NOP_INST;
    end
    else if (IF_ID_write) begin
        PC_ID_reg       <= PC_IFID_reg;
        PC_plus4_ID_reg <= PC_next;
        inst_reg        <= inst_intermediate;
    end
end

inst_mem INSTRUCTION_MEMORY (.PC(PC_IFID_reg[31:2]), .rst(rst), .decoded_I(inst_intermediate));

assign PC_IFID       = PC_ID_reg;
assign PC_plus4_IFID = PC_plus4_ID_reg;
assign inst_IFID     = inst_reg;

endmodule
