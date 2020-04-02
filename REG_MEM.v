/*
    Luke Zambella
    ELC463 Computer Engineering Lab II
    Module containg each of the 32 registers and read/write enables
*/
module REG_MEM(
        input CLK,                  // System clock
        input  [4:0] READ_REG_A,    // read from registser A
        input  [4:0] READ_REG_B,    // read from register b
        input  [4:0] WRITE_REG,     // write WRITE_DATA to this register (if regwrite enabled)
        input  [63:0] WRITE_DATA,   // Data to write to register
        input  REG_WRITE_ENABLE,    // enable for writing to register
        output reg [63:0] DATA_OUT_A,   // data read from register input a
        output reg [63:0] DATA_OUT_B    // data read from register input b
    );

    
        reg [63:0] REGISTER [31:0];      // 32 general purpose registers holding 64 bits each
        // Asyncronous read
        always @ (*) begin
            if (READ_REG_A == 'b0) begin
                DATA_OUT_A <= 63'b0;
            end else begin        
                DATA_OUT_A <= REGISTER[READ_REG_A];
                
            end

            if (READ_REG_B == 'b0) begin
                DATA_OUT_B <= 63'b0;
            end else begin
                DATA_OUT_B <= REGISTER[READ_REG_B];
            end
            
        end

        // Syncronous write
        always @ (posedge CLK) begin
            if (REG_WRITE_ENABLE == 1'b1) begin
                REGISTER[WRITE_REG] <= WRITE_DATA;
                $display("Time: %d Register %d value updated to %h", $time, WRITE_REG, WRITE_DATA);
            end
        end
        // lets give some registers initial values
        initial begin
            //$monitor("Time %d val[1, 2, 3]: %h %h %h", $time, REGISTER[1], REGISTER[2], REGISTER[3]);
            REGISTER[0] = 16'h0000;
            REGISTER[1] = 16'h0000;
            REGISTER[2] = 16'h0000;
            REGISTER[3] = 16'h0000;
            REGISTER[4] = 16'h0000;
            
            REGISTER[5] = 16'h0005;
        end
endmodule