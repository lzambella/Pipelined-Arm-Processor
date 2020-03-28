`timescale 1ns / 1ps

    /*
    Luke Zambella
    ELC463 Computer Engineering II
    Pipeline for IF/ID stage
    */
module INSTR_PIPE(
    input CLK,
    input RESET,
    input [31:0] INSTR_IN,
    input [31:0] COUNTER_IN,
    input stall_enable,

    output reg [31:0] INSTR_OUT,
    output reg [31:0] COUNTER_OUT
);
    always @ (posedge CLK or posedge RESET) begin
        if (RESET) begin
            INSTR_OUT <= 0;
            COUNTER_OUT <= 0;
        end
        else begin
            // Unless there is a stall, operate normally
            if (stall_enable) begin
                $display("Time: %d stall operation", $time);
            end else begin
                // Pass each input
                INSTR_OUT <= INSTR_IN;
                COUNTER_OUT <= COUNTER_IN;
            end
        end
    end 
endmodule