`timescale 1ns / 1ps

module Controller
(
  input [10:0] Instruction,

  output reg reg2loc,
  output reg [1:0] aluOp,
  output reg aluSrc,
  output reg memRead,
  output reg memWrite,
  output reg regWrite,
  output reg mem2reg,
  output reg branch,
  output reg [8:0] control_out    // Full control line output as a single bus
);

  /* ----- control line output meaning ------ */
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
  /* OPCode macros */
  `define OPERATION_ADD               'b10001011000
  `define OPERATION_SUB               'b11001011000
  `define OPERATION_AND               'b10001010000
  `define OPERATION_ORR               'b10101010000
  
  `define OPERATION_LDUR              'b11111000010
  `define OPERATION_STUR              'b11111000000
  
  `define OPERATION_CBZ               'b10110100000
  `define OPERATION_B                 'b00000000101

  // Update control lines with each instruction
  always @(*) begin 
    case (Instruction)
      // R-Types have the same control outputs
      `OPERATION_ADD,
      `OPERATION_SUB,
      `OPERATION_AND,
      `OPERATION_ORR: begin
        reg2loc <= 0;
        aluOp <= 2'b10;
        aluSrc <= 0;
        branch <= 0;
        memRead <= 0;
        memWrite <= 0;
        regWrite <= 1;
        mem2reg <= 0;
        control_out <= 9'b010000010;
      end
      `OPERATION_LDUR: begin
        reg2loc <= 'b0;
        aluOp <= 2'b00;
        aluSrc <= 1;
        branch <= 0;
        memRead <= 1;
        memWrite <= 0;
        regWrite <= 1;
        mem2reg <= 1;
        control_out <= 9'b000101011;
      end
      `OPERATION_STUR: begin
        reg2loc <= 1'b1;
        aluOp <= 2'b00;
        aluSrc <= 1;
        branch <= 0;
        memRead <= 0;
        memWrite <= 1;
        regWrite <= 0;
        mem2reg <= 1'bx;
        control_out <= 9'b100100100;
      end
      `OPERATION_CBZ: begin
        reg2loc <= 1'b1;
        aluOp <= 2'b01;
        aluSrc <= 0;
        branch <= 1;
        memRead <= 0;
        memWrite <= 0;
        regWrite <= 0;
        mem2reg <= 1'bx;
        control_out <= 9'b101010001;
      end
    endcase
  end
endmodule
