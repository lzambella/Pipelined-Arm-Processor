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
            16'h0000:  out = 32'b11111000010000000000000010000001; // LDUR X1, [X4, #0]
            16'h0001:  out = 32'b10001011000000100000000000100011; // ADD X3, X1, X2
            16'h0002:  out = 32'b11111000010000000001000010000010; // LDUR X2, [X4, #1]
            16'h0003:  out = 32'b10001011000000100000000000100011; // ADD X3, X1, X2
        endcase
    end
endmodule