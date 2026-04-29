# Tiny8 Autonomous CPU with External SPI Instruction Fetch

This project implements a compact 8-bit autonomous CPU in Verilog for Tiny Tapeout.

## Main idea
Instead of storing the program inside the chip, the CPU fetches 16-bit instructions from an external SPI instruction source. This keeps the design autonomous while reducing internal area.

## Main features
- 8-bit accumulator-based CPU
- external SPI instruction fetch
- arithmetic and logic operations:
  - ADD
  - SUB
  - AND
  - OR
  - XOR
- control instructions:
  - CMP
  - OUT
  - JMP
  - BZ
  - BNZ
  - HALT
- final validated constrained floorplan: 155 x 95 um

## Current I/O usage
- `uo[7:0]`: parallel output result
- `uio[0]`: SPI_CS_N
- `uio[1]`: SPI_SCK
- `uio[2]`: SPI_MOSI
- `uio[3]`: SPI_MISO

## Validation status
- RTL simulation: OK
- external SPI fetch testbench: OK
- LibreLane flow: completed
- DRC/LVS/antenna: clean in final validated flow
- final constrained layout fits within a 1x1 Tiny Tapeout target envelope

## Note
This project is presented as an extended architectural interpretation of the original ALU challenge: the required ALU operations are executed under CPU control from an external instruction program, rather than through a direct manual operand-loading interface.
