`timescale 1ns / 1ps

    /*
    Luke Zambella
    ELC463 Computer Engineering II
    Pipeline for MEM/WB stage
    */ 

module MEM_PIPE(
    input CLK,
    input RESET,
    // ALU res gets passed and the mem data out gets passed as well
    input [63:0] MEM_DATA, ALU_VAL, 
    input [4:0] REG_DESTINATION,

    input REGWRITE_IN,
    input MEM2REG_IN,
    
    input [31:0] INSTR_IN,

    output reg [63:0] MEM_DATA_OUT, ALU_VAL_OUT,
    output reg [4:0] REG_DESTINATION_OUT,

    output reg REGWRITE_OUT,
    output reg MEM2REG_OUT,
    output reg [31:0] INSTR_OUT
     
);

always @( posedge CLK or posedge RESET) begin
    if(RESET) begin
            MEM_DATA_OUT        <= 0;
            ALU_VAL_OUT         <= 0;
            REG_DESTINATION_OUT <= 0;
    end
    else begin
            MEM_DATA_OUT        <= MEM_DATA;
            ALU_VAL_OUT         <= ALU_VAL;
            REG_DESTINATION_OUT <= REG_DESTINATION;
            REGWRITE_OUT <= REGWRITE_IN;
            MEM2REG_OUT <= MEM2REG_IN;      
            INSTR_OUT <= INSTR_IN;   
    end
    
end

endmodule

