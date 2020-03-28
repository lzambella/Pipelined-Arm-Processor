# Pipelined ARM implementation
### Luke Zambella and Evan Rahimi
----
Verilog implementation of a basic ARM processor with a 5-stage pipeline using only 7 instructions.

#### Running
To run this, icarus verilog is needed. A simulation build can be assembled by running `iverilog -o [OUTPUT FILE] *.v` and simulated through `vvp [OUTPUT FILE]`. By defult, it outputs a waveform of every single wire as `dump.vcd`

This implementation only contains the following LEGv8 instructions:
|Assembly shorthand|Binary OpCode|
|------------------|-------------|
| ADD | `10001011000`|
| SUB | `11001011000`|
| AND | `10001010000`|
| ORR | `10101010000`|
| LDUR| `11111000010`|
|STUR | `11111000000`|
| CBZ | `10110100000`|

The ROM file is a verilog file `ROM.v` where the main program can be defined. The default program loads a predefined value from `DATA_MEM[0]` and `DATA_MEM[1]` and stores it into a register where it is added. Data hazards have not been added yet so it performs some ALU operations in the meantime while the data gets safely stored into the register.

#### Update log
* 3/9/2020 -- Implemented stall unit.
* 3/23/2020 -- Implemented forwarding unit.
* 3/28/2020 -- Added forwarding for read register data in the ID stage due to the WB stage not being able to write the data in time it is read again if applicable (Rd.WB == Rn.ID or Rm.ID). Fix STUR error by changing wires as well.