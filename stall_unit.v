`timescale 1ns / 1ps

/**
    Luke Zambella
    ELC463
    Data Hazard Stall unit

    If the current ID instruction is a load/stur instruction, it checks if theres a referenced register in the IF stage and stalls if true
    Allows data to be safely stored or loaded before it is referenced again

    The untit takes the following inputs:
        Rd from EX stage (write register)
        Rn from ID stage (read register 1)
        Rm from ID stage (read register 2)

        The program counter of the ID stage

    If Rn or Rm are equal to Rd AND memread from the EX stage is enabled, then the unit will stall the pipeline
    It will also keep the PC from the ID stage so the instruction doesn not prematurely change.

    It outputs a MUX value that either passes through the control lines or a zero
    If there is a hazard, then it also outputs the current PC and a write enable for the pc
*/
module stall_unit(
    input wire [4:0] Rd_ex,
    input wire [4:0] Rm_id,
    input wire [4:0] Rn_id,
    input wire memRead_ex,

    output reg stall,
    output reg PC_stall
);


always @(*) begin
    // If EX stage is a memread operation
    if (memRead_ex == 1'b1) begin
        // Check if there is a hazard
        if (Rd_ex == Rm_id || Rd_ex == Rn_id) begin
            stall <= 1;
            PC_stall <= 1;
        end else begin
            stall <= 0;
            PC_stall <= 0;
        end
    end else begin
        stall <= 0;
        PC_stall <= 0;
    end
end
endmodule