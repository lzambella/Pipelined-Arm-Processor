`timescale 1ns / 1ps

    /*
    Luke Zambella
    ELC463 Computer Engineering II
    Pipeline for EX/MEM stage
    */ 

module EX_PIPE(
    input CLK,  
    input RESET,
    input ZERO,
    input [63:0] BRANCH, ALU_VAL, RT_READ, 
    input [4:0] REG_DESTINATION,
    input [5:0] ALU_CONTROL,
    input REGWRITE_IN,
    input MEM2REG_IN,
    input MEMWRITE_IN,
    input BRANCH_ZERO_IN,
    input MEMREAD_IN,
    input [31:0] INSTR_IN,
    input [31:0] PC_IN,

    output reg [63:0] BRANCH_OUT, RT_READ_OUT, ALU_VAL_OUT,
    output reg [4:0] REG_DESTINATION_OUT,
    output reg [5:0] ALU_CONTROL_OUT,
    output reg ZERO_OUT,
    output reg REGWRITE_OUT,
    output reg MEM2REG_OUT,
    output reg MEMWRITE_OUT,
    output reg BRANCH_ZERO_OUT,
    output reg MEMREAD_OUT,
    output reg [31:0] INSTR_OUT,
    output reg [31:0] PC_OUT
);

  always @( posedge CLK) begin
            BRANCH_OUT        <= BRANCH;
            ALU_VAL_OUT         <= ALU_VAL;
            RT_READ_OUT         <= RT_READ;
            REG_DESTINATION_OUT <= REG_DESTINATION;
            ALU_CONTROL_OUT     <= ALU_CONTROL;
            ZERO_OUT            <= ZERO;         
            REGWRITE_OUT <= REGWRITE_IN;
            MEM2REG_OUT <= MEM2REG_IN;
            MEMREAD_OUT <= MEMREAD_IN;
            MEMWRITE_OUT <= MEMWRITE_IN;
            BRANCH_ZERO_OUT <= BRANCH_ZERO_IN;
            INSTR_OUT <= INSTR_IN;
            PC_OUT <= PC_IN;
end

endmodule