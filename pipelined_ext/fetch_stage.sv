module fetch_stage (
    input wire clk,
    input wire rst,
    input wire PCWrite,
    input wire IF_ID_write,
    input wire PCSrc,       //source for next PC address
    input wire [31:0] target_address,   //target address in case of branch/jump
    output wire [31:0] PC_IFID,           //push to decode stage
    output wire [31:0] inst_IFID        //push to decode stsge
    
);

reg [31:0] PC_IFID_reg;
wire [31:0] PC_next;
PC_next NEXT_PC_ADDR(.current_PC(PC_intermediate), .next_PC(PC_next));        // next sequential address

wire [31:0] PC_current;
wire [31:0] PC_intermediate;
wire [31:0] inst_intermediate;



assign PC_current = PCSrc ? target_address : PC_next;

//PC update
always_ff @(posedge clk) begin
    if (!rst) begin
        PC_IFID_reg <= '0;
    end
    else begin
        if (PCWrite) begin
            PC_IFID_reg <= PC_current;
        end
        else begin
            PC_IFID_reg <= '0;
        end
    end
end


//ID stage inputs
reg [31:0] PC_ID_reg;
reg [31:0] inst_reg;
always_ff @(posedge clk) begin
    if (!rst) begin
        PC_ID_reg <= '0;
        inst_reg <= '0;
    end
    else begin
        if(PCWrite) begin
            PC_ID_reg <= PC_intermediate;
        end
        else begin
            PC_ID_reg <= '0;
        end
        if (IF_ID_write)
            inst_reg <= inst_intermediate;
        else
            inst_reg <= '0;
    end
end
assign PC_intermediate = PC_IFID_reg;
assign PC_IFID = PC_IFID_reg;


inst_mem INSTRUCTION_MEMORY (.PC(PC_IFID_reg[31:2]), .rst(rst), .decoded_I(inst_intermediate));     //asynchronous read

assign inst_IFID = inst_reg;


endmodule