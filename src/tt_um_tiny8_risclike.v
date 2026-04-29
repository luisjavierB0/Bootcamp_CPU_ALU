`timescale 1ns/1ps

module tt_um_tiny8_risclike (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire        fetch_start;
    wire [7:0]  fetch_addr;
    wire        fetch_busy;
    wire        fetch_done;
    wire [15:0] fetch_instr;

    wire [7:0]  port_out;

    wire spi_cs_n;
    wire spi_sck;
    wire spi_mosi;
    wire spi_miso;

    assign spi_miso = uio_in[3];

    tiny8_cpu cpu_i (
        .clk        (clk),
        .rst_n      (rst_n),
        .fetch_start(fetch_start),
        .fetch_addr (fetch_addr),
        .fetch_busy (fetch_busy),
        .fetch_done (fetch_done),
        .fetch_instr(fetch_instr),
        .port_out   (port_out)
    );

    tiny8_spi_fetch fetch_i (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (fetch_start),
        .addr     (fetch_addr),
        .busy     (fetch_busy),
        .done     (fetch_done),
        .instr    (fetch_instr),
        .spi_cs_n (spi_cs_n),
        .spi_sck  (spi_sck),
        .spi_mosi (spi_mosi),
        .spi_miso (spi_miso)
    );

    // debug modes to keep all inputs physically meaningful
    wire [7:0] dbg_uio = uio_in;
    wire [7:0] dbg_ui  = {ui_in[7:1], ena};

    assign uo_out = ui_in[0] ? dbg_uio :
                    ui_in[1] ? dbg_ui  :
                               port_out;

    assign uio_out[0] = spi_cs_n;
    assign uio_out[1] = spi_sck;
    assign uio_out[2] = spi_mosi;
    assign uio_out[7:3] = 5'b00000;

    assign uio_oe[0] = 1'b1;
    assign uio_oe[1] = 1'b1;
    assign uio_oe[2] = 1'b1;
    assign uio_oe[7:3] = 5'b00000;

endmodule
