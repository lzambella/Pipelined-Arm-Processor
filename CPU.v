`timescale 1ns / 1ps
module ARM_RISC(input clock,
                input [63:0] writeback_data,            // The output of the data memory unit gets fed to to this              
                input [31:0] instr_IF,               // Instruction fed into the cpu
                input reset,
                input [31:0] PC_IF,                      // The current PC in the IF stage, read externally

                output wire [63:0] mem_addr_input,       // Mem address to read from in the MEM stage for LDUR/STUR instructions
                output wire [63:0] Rm_data_MEM,       // Register DATA to write to the referenced memory address in the MEM stage for STUR instructions
                output wire ctrl_memWrite_MEM,           // Control line for external memory unit for writing
                output wire ctrl_memRead_MEM,            // Control line for external memory unuit for reading
                output wire ctrl_branch_out,             // comes from (CBZ && aluZERO) MEM stage
                output wire [31:0] branch_PC_MEM,        // sent to external instr_IF memory for branching
                output wire        PC_stall_ID,          // Enabler for stalling. comes from ID stage
                output wire [31:0] PC_OUT_ID              // when a stall is enabled, the PC from the ID stage overwrites whatever PC from the IF stage is                 
                );
`define OPERATION_LDUR              'b11111000010
`define OPERATION_STUR              'b11111000000
/*
    CPU module contains all the pipeline stages, the register memories, ALU, and controller
*/

// Need to have an instr_IF input and outputs for each pipeline stage
// The outputs of the some of the modules feed into the inputs for the next stage

// Instruction fetch datalines
// Takes in the entire instr_IF read from ROM along with the current program counter
// The program counter is not physically a part of the CPU
wire [31:0] instr_ID, instr_EX, instr_mem, instr_wb;
wire [31:0] counter_out_id;
wire [31:0] PC_ID;
// Control unit
// For the ID stage

  /*
      from most significant to least significant (left to right)
      8 -> reg2loc
      7 -> aluOp[1]
      6 -> aluOp[0]
      5 -> aluSrc
      4 -> branch
      3 -> memRead
      2 -> memWrite
      1 -> regWrite
      0 -> mem2reg
  */

wire [8:0] control_out_id;  // This gets fed into the data
wire [8:0] control_stall_mux_ID; // Either zeros or control_out_id



// Execute stage datalines
wire ctrl_reg2loc_EX, ctrl_aluSrc_EX, ctrl_memRead_EX, ctrl_memWrite_EX, ctrl_regWrite_EX, ctrl_mem2reg_EX, ctrl_branch_EX;
wire [1:0] ctrl_aluOp_EX;
wire [63:0] Rn_data_EX, Rm_data_EX;
wire [31:0] PC_EX;
wire [10:0] aluCtrl_EX;
wire [4:0] RD_EX;   // Execute stage write_reg_out
wire [63:0] signExtend_EX;
wire [4:0] Rn_EX, Rm_EX;  // EX stage register location for forwarding unit

// MEM stage datalines
wire ctrl_regWrite_MEM, ctrl_mem2reg_MEM, ctrl_branch_MEM;
wire [4:0] RD_MEM; // write register passthrough for MEM stage
wire [63:0] branch_addr_EX;

wire aluZero_EX, aluZero_MEM; // EX stage pipeline alu zero IO
wire [63:0] alu_res_EX, alu_res_MEM, branch_addr_out_mem;
wire [5:0] alu_ctrl_in_EX;

// WB stage datalines
wire ctrl_regWrite_WB, mem2reg_out_wb;
wire [63:0] memory_write_data_out, alu_res_out_wb;
wire [4:0] RD_WB; // write register passthrough for MEM stage to WB stage
wire [63:0] writeback_data_WB; // Data from mux depends either on mem2reg

// Forwarding unit datalines
wire [1:0] forward_A_MUX_EX, forward_B_MUX_EX;            // MUX inputs
reg [63:0] forward_mux_res_a, forward_mux_res_b;  // data outputs

//TODO: add forwarding for ID stage for WB stage
wire reg_data_muxSrc_Rm_ID, reg_data_muxSrc_Rn_ID;    // MUX input
reg [63:0] Rm_mux_output_ID, Rn_mux_output_ID;           // output either read register data or writeback data, these go into the inputs for the ID/EX pipeline

// MUX selector to either stall or pass control lines in the ID stage
wire stall_enable_ID;

Controller control(.Instruction(instr_ID[31:21]), // Second stage instr_IF passthrough
                   .control_out(control_out_id)
                   );


// Register unit
wire [4:0] Rn_ID, Rm_ID;
assign Rn_ID = instr_ID[9:5];  // Register input is always a subset of the instr_IF
assign Rm_ID = (control_stall_mux_ID[8] == 0) ? instr_ID[20:16] : instr_ID[4:0]; // This register input is dependent on a bit in the instr_IF
wire [63:0] Rn_data_ID, Rm_data_ID;

// -------- CPU components ---------

REG_MEM registers(.CLK(clock),
                  .READ_REG_A(Rn_ID),
                  .READ_REG_B(Rm_ID),
                  .DATA_OUT_A(Rn_data_ID),
                  .DATA_OUT_B(Rm_data_ID),
                  .WRITE_REG(RD_WB),
                  .WRITE_DATA(writeback_data_WB), // from stage 5 mux output
                  .REG_WRITE_ENABLE(ctrl_regWrite_WB)
                  );

// ALU inputs are got from stage 3 inputs/outputs
// sets whether alu src comes from read register or memory offset location depending on the instr_IF (instr_IF[20:12])
reg [63:0] alusrc_mux_EX;

ALU alu(.A(forward_mux_res_a),      // The forwarding MUX passed value for input A
        .B(alusrc_mux_EX),          // the alusrc MUX value AFTER the forwarding MUX value for input B
        .C(aluCtrl_EX), 
        .alu_op(ctrl_aluOp_EX), 

        .R(alu_res_EX),
        .ZERO(aluZero_EX));

// ------- Pipelines ---------
// IF/ID
INSTR_PIPE pipe_a(.CLK(clock),
                   .stall_enable(stall_enable_ID),
                   .RESET(reset),
                   .INSTR_IN(instr_IF),
                   .COUNTER_IN(PC_IF),
                   .INSTR_OUT(instr_ID),
                   .COUNTER_OUT(PC_ID));

// ID/EX
ID_PIPE pipe_b(.CLK(clock),
                // From the stall MUX output
                .reg2loc_in(control_stall_mux_ID[8]),
                .aluOp_in(control_stall_mux_ID[7:6]),
                .aluSrc_in(control_stall_mux_ID[5]),
                .branch_in(control_stall_mux_ID[4]),
                .memRead_in(control_stall_mux_ID[3]),
                .memWrite_in(control_stall_mux_ID[2]),
                .regWrite_in(control_stall_mux_ID[1]),
                .mem2reg_in(control_stall_mux_ID[0]),
                
                // Register data
                .register_data_a_in(Rn_mux_output_ID),
                .register_data_b_in(Rm_mux_output_ID),
                // the register locations also get passed through the pipeline
                .READ_REG_A_IN(Rn_ID),
                .READ_REG_B_IN(Rm_ID),
                // Program counter (for branching)
                .pc_in(PC_ID),
                
                .aluControl_in(instr_ID[31:21]), 
                .write_register_in(instr_ID[4:0]),

                .signExtend_in(instr_ID), 
                
                .instr_in(instr_ID),
                // Outputs
                .reg2loc_out(ctrl_reg2loc_EX),
                .aluSrc_out(ctrl_aluSrc_EX),
                .memRead_out(ctrl_memRead_EX),
                .memWrite_out(ctrl_memWrite_EX),
                .regWrite_out(ctrl_regWrite_EX),
                .mem2reg_out(ctrl_mem2reg_EX),
                .branch_out(ctrl_branch_EX),
                .aluOp_out(ctrl_aluOp_EX),

                .register_data_a_out(Rn_data_EX),
                .register_data_b_out(Rm_data_EX),
                // Forwarding unit passthroughs
                .READ_REG_A_OUT(Rn_EX),
                .READ_REG_B_OUT(Rm_EX),

                .pc_out(PC_EX),
                .aluControl_out(aluCtrl_EX),
                .write_register_out(RD_EX),
                .signExtend_out(signExtend_EX),
                .instr_out(instr_EX)
                );

// EX/MEM
assign mem_addr_input = alu_res_MEM; // the alu result can point to a memory address to store
// For branching, add the current counter to some value that only works if its a branch
assign branch_addr_EX = PC_EX + signExtend_EX[23:5];
assign ctrl_branch_out = ctrl_branch_MEM && aluZero_MEM;
EX_PIPE pipe_c(.CLK(clock),
               .RESET(reset),
               .ZERO(aluZero_EX),
               .BRANCH(branch_addr_EX),
               .ALU_VAL(alu_res_EX),
               .RT_READ(forward_mux_res_b), // the data to WRITE to memory
               .ALU_CONTROL(alu_ctrl_in_EX),
               .MEMREAD_IN(ctrl_memRead_EX), // output of previous stage
               // These are the control outputs that get passed through form previous stage outputs
               .REGWRITE_IN(ctrl_regWrite_EX),
               .MEM2REG_IN(ctrl_mem2reg_EX),
               .MEMWRITE_IN(ctrl_memWrite_EX),
               .BRANCH_ZERO_IN(ctrl_branch_EX), // control branch out for CBZ instr
               .INSTR_IN(instr_EX),
               .REG_DESTINATION(RD_EX),

               .BRANCH_OUT(branch_PC_MEM),
               .RT_READ_OUT(Rm_data_MEM), // This is the register contents reference by reg_data_b
               .ALU_VAL_OUT(alu_res_MEM),
               .ZERO_OUT(aluZero_MEM),

               .REGWRITE_OUT(ctrl_regWrite_MEM),
               .MEM2REG_OUT(ctrl_mem2reg_MEM),
               .MEMWRITE_OUT(ctrl_memWrite_MEM), // goes to external memory unit,
               .MEMREAD_OUT(ctrl_memRead_MEM),  // goes to external memory unit
               .BRANCH_ZERO_OUT(ctrl_branch_MEM),
               .REG_DESTINATION_OUT(RD_MEM),
               .INSTR_OUT(instr_mem)
               );
// MW/WB
MEM_PIPE pipe_d(.CLK(clock),
                .RESET(reset),
                
                .MEM_DATA(writeback_data), // gets data from mem unit output
                .ALU_VAL(alu_res_MEM), // from previous stage
                .REG_DESTINATION(RD_MEM),
                .REGWRITE_IN(ctrl_regWrite_MEM),
                .MEM2REG_IN(ctrl_mem2reg_MEM),
                .INSTR_IN(instr_mem),

                .MEM_DATA_OUT(memory_write_data_out), // outputs read data if any
                .REG_DESTINATION_OUT(RD_WB),
                .REGWRITE_OUT(ctrl_regWrite_WB),
                .MEM2REG_OUT(mem2reg_out_wb),
                .ALU_VAL_OUT(alu_res_out_wb),
                .INSTR_OUT(instr_wb)
                );


stall_unit staller(.Rd_ex(RD_EX),
                   .Rn_id(Rn_ID),
                   .Rm_id(Rm_ID),
                   .memRead_ex(ctrl_memRead_EX),
                   
                   .stall(stall_enable_ID),
                   .PC_stall(PC_stall_ID));

FORWARD_UNIT forwarder(.EX_RN1_IN(Rn_EX),            // Register location a from EX stage
                       .EX_RM2_IN(Rm_EX),            // Register location b from EX stage
                       .MEM_RD_IN(RD_MEM),       // Write reg location from MEM stage
                       .WB_RD_IN(RD_WB),         // Write reg location from WB stage
                       .MEM_REGWRITE_IN(ctrl_regWrite_MEM), // control dataline for regwrite in MEM stage
                       .WB_REGWRITE_IN(ctrl_regWrite_WB),   // control dataline for regwrite in WB stage
                       // Ouput MUX values
                       .FORWARD_A(forward_A_MUX_EX),   
                       .FORWARD_B(forward_B_MUX_EX)
                    );


always @(*) begin
    // Forwarding mux A for ALU input A during Code Execute stage
    // Takes inputs from different stages
    case (forward_A_MUX_EX)
        2'b00: forward_mux_res_a <= Rn_data_EX;      // no forwarding at all
        2'b01: forward_mux_res_a <= writeback_data_WB;  // get mem/writeback result from the WB MUX output
        2'b10: forward_mux_res_a <= alu_res_MEM;        // get EX/MEM alu result 
    endcase

    case (forward_B_MUX_EX)
        2'b00: forward_mux_res_b <= Rm_data_EX;  // no forwarding at all
        2'b01: forward_mux_res_b <= writeback_data_WB;          // get mem/writeback result from the WB MUX output
        2'b10: forward_mux_res_b <= alu_res_MEM;        // get EX/MEM alu result        
    endcase

    // check in EX stage the type of instr_IF
    // The ALUsrc mux should come after the forwarding mux
    // either the forwarded data gets passed or the base data address of the d type instr_IF gets passed
    if(signExtend_EX[31:21] == `OPERATION_LDUR || signExtend_EX[31:21] == `OPERATION_STUR) begin
        alusrc_mux_EX <= signExtend_EX[20:12];
    end else begin
        alusrc_mux_EX <= forward_mux_res_b;
    end

    // Consider a data hazard in the WB stage where the ID stage references either RM or RN for the reg memory
    // The register data will not be stored in time so here it has to be forwarded from the WB stage
    // This could have been done in the forwarding unit but it conceptually makes more sense here
    // Also consider store instructions in the ID stage
    // Rm 
    if ((RD_WB == Rm_ID) && (ctrl_regWrite_WB == 1)) begin
        Rm_mux_output_ID <= writeback_data_WB;     // Use the writeback data
        $display("time: %d Forwarding WB reg data to RM in ID", $time);
    end else begin
        Rm_mux_output_ID <= Rm_data_ID;
    end

    // Rn 
    if ((RD_WB == Rn_ID) && (ctrl_regWrite_WB == 1)) begin
        Rn_mux_output_ID <= writeback_data_WB;     // Use the writeback data
        $display("time: %d Forwarding WB reg data to RN in ID", $time);
    end else begin
        Rn_mux_output_ID <= Rn_data_ID;
    end
end

assign control_stall_mux_ID = (stall_enable_ID == 1) ? 9'b0 : control_out_id;                        // This mux is for stalling during ldur and stur instructions
assign writeback_data_WB = (mem2reg_out_wb == 0) ? alu_res_out_wb : memory_write_data_out; // writeback gets either read memory or alu result
assign PC_OUT_ID = PC_ID;

endmodule