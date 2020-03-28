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
            16'h0001:  out = 32'b10001011000000000000000000100010; // ADD X2, X1, X0
            16'h0002:  out = 32'b10001011000000010000000001000011; // ADD X3, X2, X1
            16'h0003:  out = 32'b11111000000000000000000010000011; // STUR X3, [X4, #0]
            default: out=32'hD60003E0; //BR XZR
        endcase
    end
endmodule