`timescale 1ns / 1ps
/*
    Luke Zambella
    ELC463 Computer Engineering II
    Data memory unit for storing results
*/

module DATA_MEM(
        input CLK,                          // system clock
        input MEM_WRITE,                    // memory write enable
        input MEM_READ,                     // memory read enable
        input [63:0] MEM_ADDR_IN,           // Memory address input
        input [63:0] WRITE_DATA,            // Memory write data
        output reg [63:0] DATA_OUT          // Memory data output (if read enabled)        
    );
    
        reg [63:0] DATA_MEMORY [15:0];    // 2^16 blocks of 64 bit memory (128 KB of data)
        
        // Asyncronous read
        always @ (*) begin
            if (MEM_READ) begin
                DATA_OUT <= DATA_MEMORY[MEM_ADDR_IN];
            end
        end


        // Syncronous write
        always @ (posedge CLK) begin
            if (MEM_WRITE) begin
                DATA_MEMORY[MEM_ADDR_IN] <= WRITE_DATA;
            end
        end
        
        initial begin
            $monitor("Time: %d Data_mem[0]: %h", $time, DATA_MEMORY[0]);
            DATA_MEMORY[0] = 'h0015;
            DATA_MEMORY[1] = 'h00C4;           
        end
endmodule
