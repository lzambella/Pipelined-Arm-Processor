`timescale 1ns / 1ps


module FORWARD_UNIT(
    input [4:0] EX_RN1_IN,
    input [4:0] EX_RM2_IN,
    input [4:0] MEM_RD_IN,
    input [4:0] WB_RD_IN,
    input MEM_REGWRITE_IN,
    input WB_REGWRITE_IN,
    
    output reg [1:0] FORWARD_A,
    output reg [1:0] FORWARD_B
    
    );
    
    always @(*) begin
    
        if ((WB_REGWRITE_IN == 1'b1) && (WB_RD_IN !== 31) && (WB_RD_IN == EX_RN1_IN)) begin
            FORWARD_A <= 2'b01;    
        end
        else if ((MEM_REGWRITE_IN == 1'b1) && (MEM_RD_IN !== 31) && (MEM_RD_IN == EX_RN1_IN)) begin
            FORWARD_A <= 2'b10;    
        end
        else begin
            FORWARD_A <= 2'b00;
        end
        
        if ((WB_REGWRITE_IN == 1'b1) && (WB_RD_IN !== 31) && (WB_RD_IN == EX_RM2_IN)) begin
            FORWARD_B <= 2'b01;   
        end
        
        else if ((MEM_REGWRITE_IN == 1'b1) && (MEM_RD_IN !== 31) && (MEM_RD_IN == EX_RM2_IN)) begin
            FORWARD_B <= 2'b10;   
        end
        else begin
            FORWARD_B <= 2'b00;
        end
    
    end
    
    
endmodule
