/*
    Luke Zambella
    ELC463 Computer Engineering Lab II
    ROM that stores a program, replaces the instruction memory
*/
module ROM(out, address);
    output reg [31:0] out;
    input  [15:0] address; // address- 16 deep memory  
    always @(*) begin
        case (address)
            16'h0000:  out = 32'b11111000010000000000000010100001; // LDUR X1, [X5, #0]     X1 gets FF
            16'h0001:  out = 32'b11111000010000000001000010100010; // LDUR X2, [X5, #1]     X2 gets AA
            16'h0002:  out = 32'b10001011000000010000000001000011; // ADD X3, X2, X1        X3 gets FF + AA = 1A9
            16'h0003:  out = 32'b11001011000000100000000001100100; // SUB X4, X3, X2        X4 gets (FF + AA) - AA = FF
            16'h0004:  out = 32'b10001010000000110000000010000011; // AND X3, X4, X3        X3 gets FF && 1A9 = 
            16'h0005:  out = 32'b10101010000000110000000001000100; // ORR X4, X2, X3        X4 gets AA ORR (AA && (FF+AA))
            16'h0006:  out = 32'b11111000000000000010000010100100; // STUR X4, [X5, #2]     Store X4 into DATA_MEM[7]
        endcase
    end
endmodule