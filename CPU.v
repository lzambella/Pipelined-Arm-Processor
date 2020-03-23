`timescale 1ns / 1ps
module ARM_RISC(input clock,
                input [63:0] writeback_data,            // The output of the data memory unit gets fed to to this              
                input [31:0] instruction,               // Instruction fed into the cpu
                input reset,
                input [31:0] pc,
                output wire [63:0] mem_addr_input,       // Data memory read this value
                output wire [63:0] write_data_input,     // Data memry read this value
                output wire memory_write,                // These are for the MEM stage
                output wire memory_read,
                output wire [63:0] alu_res_debug,        // alu debug results
                output wire ctrl_branch_out,             // comes from an AND of the cbz and ALU zero output
                output wire [31:0] branch_pc_out,        // always passed out, sometimes contains garbage
                // hazard PC control
                output wire        hazard_pc_write       // Enabler for stalling
                );
`define OPERATION_LDUR              'b11111000010
`define OPERATION_STUR              'b11111000000
/*
    CPU module contains all the pipeline stages, the register memories, ALU, and controller
*/

// Need to have an instruction input and outputs for each pipeline stage
// The outputs of the some of the modules feed into the inputs for the next stage

// Instruction fetch datalines
// Takes in the entire instruction read from ROM along with the current program counter
// The program counter is not physically a part of the CPU
wire [31:0] instruction_passthrough_a;
wire [31:0] counter_out_id;
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
wire [8:0] control_stall_mux_out; // Either zeros or control_out_id



// ID/EX specific datalines
wire reg2loc_out_ex, aluSrc_out_ex, memRead_out_ex, memWrite_out_ex, regWrite_out_ex, mem2reg_out_ex, branch_out_ex;
wire [1:0] aluOp_out_ex;
wire [63:0] reg_data_a_out_ex, reg_data_b_out_ex;
wire [31:0] pc_out_ex;
wire [10:0] aluCtrl_out_ex;
wire [4:0] write_register_out_ex;   // Execute stage write_reg_out
wire [63:0] signExtend_out_ex;
wire [31:0] pc_out_id;
wire [4:0] reg_loc_a_ex, reg_loc_b_ex;  // EX stage register location for forwarding unit
// EX/MEM specific datalines
wire regwrite_out_mem, mem2reg_out_mem, branch_out_mem;
wire [4:0] write_register_out_mem; // write register passthrough for MEM stage
wire [63:0] branch_addr;

// EX/MEM datalines for components (?)
wire aluZero, aluZero_out; // EX stage pipeline alu zero IO
wire [63:0] alu_res, alu_res_out, branch_addr_out_mem;
wire [5:0] alu_ctrl_in;

// MEM/WB specific datalines
wire regWrite_out_wb, mem2reg_out_wb;
wire [63:0] memory_write_data_out, alu_res_out_wb;
wire [4:0] write_register_out_wb; // write register passthrough for MEM stage to WB stage
wire [63:0] final_data; // Data from mux depends either on mem2reg


Controller control(.Instruction(instruction_passthrough_a[31:21]), // Second stage instruction passthroug
                   .control_out(control_out_id)
                   );


// Register unit
wire [4:0] read_register_a, read_register_b;
assign read_register_a = instruction_passthrough_a[9:5];  // Register input is always a subset of the instruction
assign read_register_b = (control_stall_mux_out[8] == 0) ? instruction_passthrough_a[20:16] : instruction_passthrough_a[4:0]; // This register input is dependent on a bit in the instruction
wire [63:0] register_data_a, register_data_b;

// -------- CPU components ---------

REG_MEM registers(.CLK(clock),
                  .READ_REG_A(read_register_a),
                  .READ_REG_B(read_register_b),
                  .DATA_OUT_A(register_data_a),
                  .DATA_OUT_B(register_data_b),
                  .WRITE_REG(write_register_out_wb),
                  .WRITE_DATA(final_data), // from stage 5 mux output
                  .REG_WRITE_ENABLE(regWrite_out_wb)
                  );

// ALU inputs are got from stage 3 inputs/outputs
// sets whether alu src comes from read register or memory offset location depending on the instruction (instruction[20:12])
reg [63:0] alusrc_mux;

ALU alu(.A(reg_data_a_out_ex),
        .B(alusrc_mux),     // see above for details
        .C(aluCtrl_out_ex), // the instruction
        .alu_op(aluOp_out_ex), // opcode from contoller

        .R(alu_res),
        .ZERO(aluZero));

// ------- Pipelines ---------
// IF/ID
INSTR_PIPE pipe_a(.CLK(clock),
                   .RESET(reset),
                   .INSTR_IN(instruction),
                   .COUNTER_IN(pc),
                   .INSTR_OUT(instruction_passthrough_a),
                   .COUNTER_OUT(pc_out_id));

// ID/EX
ID_PIPE pipe_b(.CLK(clock),
                // From the stall MUX output
                .reg2loc_in(control_stall_mux_out[8]),
                .aluOp_in(control_stall_mux_out[7:6]),
                .aluSrc_in(control_stall_mux_out[5]),
                .branch_in(control_stall_mux_out[4]),
                .memRead_in(control_stall_mux_out[3]),
                .memWrite_in(control_stall_mux_out[2]),
                .regWrite_in(control_stall_mux_out[1]),
                .mem2reg_in(control_stall_mux_out[0]),
                
                // Register data
                .register_data_a_in(register_data_a),
                .register_data_b_in(register_data_b),
                // the register locations also get passed through the pipeline
                .READ_REG_A_IN(register_data_a),
                .READ_REG_B_IN(register_data_b),
                // Program counter (for branching)
                .pc_in(pc_out_id),
                
                .aluControl_in(instruction_passthrough_a[31:21]), // This is the instruction
                .write_register_in(instruction_passthrough_a[4:0]),

                .signExtend_in(instruction_passthrough_a), // passes the entire instruction
                
                // Outputs
                .reg2loc_out(reg2loc_out_ex),
                .aluSrc_out(aluSrc_out_ex),
                .memRead_out(memRead_out_ex),
                .memWrite_out(memWrite_out_ex),
                .regWrite_out(regWrite_out_ex),
                .mem2reg_out(mem2reg_out_ex),
                .branch_out(branch_out_ex),
                .aluOp_out(aluOp_out_ex),
                .register_data_a_out(reg_data_a_out_ex),
                .register_data_b_out(reg_data_b_out_ex),
                // Forwarding unit passthroughs
                .READ_REG_A_OUT(reg_loc_a_ex),
                .READ_REG_B_OUT(reg_loc_b_ex),
                .pc_out(pc_out_ex),
                .aluControl_out(aluCtrl_out_ex),
                .write_register_out(write_register_out_ex),
                .signExtend_out(signExtend_out_ex)
                );

// EX/MEM
assign mem_addr_input = alu_res_out; // the alu result can point to a memory address to store
// For branching, add the current counter to some value that only works if its a branch
assign branch_addr = pc_out_ex + signExtend_out_ex[23:5];
assign ctrl_branch_out = branch_out_mem && aluZero_out;
EX_PIPE pipe_c(.CLK(clock),
               .RESET(reset),
               .ZERO(aluZero),
               .BRANCH(branch_addr),
               .ALU_VAL(alu_res),
               .RT_READ(reg_data_b_out_ex),
               .ALU_CONTROL(alu_ctrl_in),
               .MEMREAD_IN(memRead_out_ex), // output of previous stage
               // These are the control outputs that get passed through form previous stage outputs
               .REGWRITE_IN(regWrite_out_ex),
               .MEM2REG_IN(mem2reg_out_ex),
               .MEMWRITE_IN(memWrite_out_ex),
               .BRANCH_ZERO_IN(branch_out_ex), // control branch out for CBZ instr
               .REG_DESTINATION(write_register_out_ex),

               .BRANCH_OUT(branch_pc_out),
               .RT_READ_OUT(write_data_input), // This is the register contents reference by reg_data_b
               .ALU_VAL_OUT(alu_res_out),
               .ZERO_OUT(aluZero_out),

               .REGWRITE_OUT(regwrite_out_mem),
               .MEM2REG_OUT(mem2reg_out_mem),
               .MEMWRITE_OUT(memory_write), // goes to external memory unit,
               .MEMREAD_OUT(memory_read),  // goes to external memory unit
               .BRANCH_ZERO_OUT(branch_out_mem),
               .REG_DESTINATION_OUT(write_register_out_mem)
               );
// MW/WB
MEM_PIPE pipe_d(.CLK(clock),
                .RESET(reset),
                
                .MEM_DATA(writeback_data), // gets data from mem unit output
                .ALU_VAL(alu_res_out), // from previous stage
                .REG_DESTINATION(write_register_out_mem),
                .REGWRITE_IN(regwrite_out_mem),
                .MEM2REG_IN(mem2reg_out_mem),
                
                .MEM_DATA_OUT(memory_write_data_out), // outputs read data if any
                .REG_DESTINATION_OUT(write_register_out_wb),
                .REGWRITE_OUT(regWrite_out_wb),
                .MEM2REG_OUT(mem2reg_out_wb),
                .ALU_VAL_OUT(alu_res_out_wb)
                );

// MUX selector to either stall or pass control lines in the ID stage
wire stall;

stall_unit staller(.Rd_ex(write_register_out_ex),
                   .Rm_id(read_register_a),
                   .Rn_id(read_register_b),
                   .PC_id(pc_out_id),
                   .memRead_ex(memRead_out_ex),
                   
                   .stall_id(stall),
                   .PC_write(hazard_pc_write));

wire forward_a, forward_b;
FORWARD_UNIT forwarder(.EX_RN1_IN(reg_loc_a_ex),            // Register location a from EX stage
                       .EX_RM1_IN(reg_loc_b_ex),            // Register location b from EX stage
                       .MEM_RD_IN(write_register_out_mem),  // Write reg location from MEM stage
                       .WB_RD_IN(write_register_out_wb),    // Write reg location from WB stage
                       .MEM_REGWRITE_IN(regwrite_out_mem),  // control dataline for regwrite in MEM stage
                       .WB_REGWRITE_IN(regWrite_out_wb),    // control dataline for regwrite in WB stage
                       // Ouput MUX values
                       .FORWARD_A(forward_a),
                       .FORWARD_B(forward_b)
                    );

always @(*) begin
    // check in third stage EX is ldur or r type
    if(signExtend_out_ex[31:21] == `OPERATION_LDUR || signExtend_out_ex[31:21] == `OPERATION_STUR) begin
        alusrc_mux <= signExtend_out_ex[20:12];
    end else begin
        alusrc_mux <= reg_data_b_out_ex;
    end

    // Forwarding mux A for ALU input A during Code Execute stage
end

// This mux is for stalling during ldur and stur instructions
assign control_stall_mux_out = (stall == 1) ? 9'b0 : control_out_id;

assign alu_res_debug = alu_res_out_wb; // for debugging, this should be from the last stage
assign final_data = (mem2reg_out_wb == 0) ? alu_res_out_wb : memory_write_data_out; // writeback gets either read memory or alu result
endmodule