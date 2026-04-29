## How it works

This project implements a compact 8-bit autonomous CPU in Verilog.

The processor contains:
- an 8-bit accumulator register (`ACC`)
- an auxiliary 8-bit register (`R1`)
- a program counter (`PC`)
- an instruction register (`IR`)
- status flags (`Z`, `N`, `C`)
- an ALU
- a dedicated SPI fetch block

This final version does **not** store the program inside the chip.  
Instead, the CPU fetches each 16-bit instruction from an **external SPI memory source**.

Instruction fetch protocol:
- the chip drives `SPI_CS_N`, `SPI_SCK`, and `SPI_MOSI`
- the external memory responds on `SPI_MISO`
- for each fetch, the chip sends an 8-bit address and receives a 16-bit instruction

This reduces area while keeping the design autonomous: once reset is released, the CPU runs by itself as long as the external SPI program source is present.

Current functional behavior:
- `uo[7:0]` exposes the processor output register
- `uio[0]` = `SPI_CS_N`
- `uio[1]` = `SPI_SCK`
- `uio[2]` = `SPI_MOSI`
- `uio[3]` = `SPI_MISO`

Implemented instruction subset:
- load immediate to `ACC`
- load immediate to `R1`
- `ADD`, `SUB`, `AND`, `OR`, `XOR`
- `CMP`
- `OUT`
- `JMP`, `BZ`, `BNZ`
- `HALT`

The design was validated functionally in simulation and physically with LibreLane.  
The final constrained floorplan used for validation was 155 x 95 um, fitting comfortably inside a 1x1 Tiny Tapeout tile target.

## How to test

### RTL simulation
The design is verified using a testbench with an emulated external SPI instruction memory.

A representative program is loaded from a `.hex` file into the emulated SPI memory.  
The CPU then fetches instructions autonomously and produces output values on `uo[7:0]`.

Expected behavior for the validated test program:
- the CPU fetches instructions from the SPI model
- it executes arithmetic and branch instructions
- it updates `uo[7:0]` with the expected sequence
- it finally reaches `HALT`

### On hardware
To run the design on real hardware, connect an SPI-capable external source that behaves like instruction memory:
- `uio[0]` -> chip select
- `uio[1]` -> serial clock
- `uio[2]` -> MOSI from the chip
- `uio[3]` -> MISO into the chip

That external source can be:
- a microcontroller such as RP2040 emulating instruction memory
- or another SPI memory-like device prepared to answer the fetch protocol

For visible human observation of output changes, the project clock should be driven slowly from the external environment or the Tiny Tapeout demo board clock configuration.

## External hardware

For simulation:
- no external hardware is required

For real operation:
- an external SPI instruction source is required
- optionally, a microcontroller can emulate program memory
- a slow external/project clock is recommended for easy visual observation


## Operating modes

The top-level wrapper includes two debug modes in addition to the normal CPU execution mode.

### Normal mode
- `ui_in[1:0] = 2'b00`
- `uo_out[7:0]` shows the CPU output register (`port_out`)
- this is the intended operating mode for autonomous execution from external SPI instruction memory

### Debug mode 1
- `ui_in[0] = 1`
- `uo_out[7:0] = uio_in[7:0]`
- this mode is used to verify bidirectional input connectivity at the chip boundary

### Debug mode 2
- `ui_in[0] = 0`
- `ui_in[1] = 1`
- `uo_out[7:0] = {ui_in[7:1], ena}`
- this mode is used to verify dedicated input connectivity and enable signal visibility

If both `ui_in[0]` and `ui_in[1]` are set, debug mode 1 has priority.

For normal CPU operation, `ui_in` should be kept at `8'h00`.
