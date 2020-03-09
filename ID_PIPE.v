`timescale 1ns / 1ps

    /*
    Luke Zambella
    ELC463 Computer Engineering II
    Pipeline for ID/EX stage
    */  
module ID_PIPE(
    input CLK,  
    input RESET,
    input [31:0] signExtend_in,
    // Control inputs

    input reg2loc_in,
    input aluSrc_in,
    input memRead_in,
    input memWrite_in,
    input regWrite_in,
    input mem2reg_in,
    input branch_in,
    input [1:0] aluOp_in,
    input [63:0] register_data_a_in,
    input [63:0] register_data_b_in,
    input [31:0] pc_in,
    input [10:0] aluControl_in,
    input [4:0] write_register_in,
    // Outputs
    output reg reg2loc_out,
    output reg aluSrc_out,
    output reg memRead_out,
    output reg memWrite_out,
    output reg regWrite_out,
    output reg mem2reg_out,
    output reg branch_out,
    output reg [1:0] aluOp_out,
    output reg [63:0] register_data_a_out,
    output reg [63:0] register_data_b_out,
    output reg [31:0] pc_out,
    output reg [10:0] aluControl_out,
    output reg [4:0]  write_register_out,
    output reg [63:0] signExtend_out
);

always @( posedge CLK) begin
        // Pass control unit outputs
        reg2loc_out <= reg2loc_in;
        aluSrc_out <= aluSrc_in;
        memRead_out <= memRead_in;
        memWrite_out <= memWrite_in;
        regWrite_out <= regWrite_in;
        mem2reg_out <= mem2reg_in;
        branch_out <= branch_in;
        aluOp_out <= aluOp_in;
        // pass register data
        register_data_a_out <= register_data_a_in;
        register_data_b_out <= register_data_b_in;
        pc_out <= pc_in;
        aluControl_out <= aluControl_in;
        write_register_out <= write_register_in;
        signExtend_out <= $signed(signExtend_in);
end
   
endmodule