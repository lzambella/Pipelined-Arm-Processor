`timescale 1ns / 1ps

module cpu_testbench();

reg clock;
wire memWrite;
wire memRead;
wire [63:0] mem_addr_in;
wire [63:0] write_data_in;
reg reset;
wire [63:0] mem_data_out;
wire [15:0] instr_addr;
wire [31:0] output_instr;
reg [31:0] pc;
wire [31:0] pc_branch;
wire pc_src;
wire [31:0] pc_mux_out; // mux output for pc_src. for branching
wire [31:0] PC_ID;
wire stall_enable;      // for staling

// Data memory
DATA_MEM memory(.CLK(clock),
                .MEM_WRITE(memWrite),
                .MEM_READ(memRead),
                .MEM_ADDR_IN(mem_addr_in),
                .WRITE_DATA(write_data_in),
                .DATA_OUT(mem_data_out));

// System ROM
ROM program(.address(pc),
            .out(output_instr)
            );

// CPU
ARM_RISC cpu(.clock(clock),
        .writeback_data(mem_data_out),
        .instr_IF(output_instr),
        .PC_IF(pc),
        
        .mem_addr_input(mem_addr_in),
        .Rm_data_MEM(write_data_in),
        .ctrl_memWrite_MEM(memWrite),
        .ctrl_memRead_MEM(memRead),

        .ctrl_branch_out(pc_src),
        .branch_PC_MEM(pc_branch),
        .PC_stall_ID(stall_enable),
        .PC_OUT_ID(PC_ID)
        );

always begin
    // 20 ns clock cycle
    #10
    clock = ~clock;
end

always @ (posedge clock) begin
    // increment program counter each clock cycle
    // check if stall hazard first, then branch ,set counter to the appropriate PC
    if (stall_enable) begin
        pc <= pc;
    end else if (pc_src == 'b1) begin
        pc <= pc_branch;
    end else begin
        pc <= pc + 1;
    end
end
initial begin
    $dumpvars(0);
    clock = 0;
    pc = 0;
    #1000
    $display("time: %d Finish sim", $time);
    $finish;
end
endmodule