`timescale 1ns/1ps

module tiny8_spi_fetch (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [7:0] addr,

    output reg        busy,
    output reg        done,
    output reg [15:0] instr,

    output reg        spi_cs_n,
    output reg        spi_sck,
    output reg        spi_mosi,
    input  wire       spi_miso
);

    reg        phase;
    reg        send_addr_phase;
    reg [7:0]  tx_shift;
    reg [15:0] rx_shift;
    reg [4:0]  bit_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy            <= 1'b0;
            done            <= 1'b0;
            instr           <= 16'h0000;
            spi_cs_n        <= 1'b1;
            spi_sck         <= 1'b0;
            spi_mosi        <= 1'b0;
            phase           <= 1'b0;
            send_addr_phase <= 1'b1;
            tx_shift        <= 8'h00;
            rx_shift        <= 16'h0000;
            bit_count       <= 5'd0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                spi_cs_n <= 1'b1;
                spi_sck  <= 1'b0;
                spi_mosi <= 1'b0;
                phase    <= 1'b0;

                if (start) begin
                    busy            <= 1'b1;
                    spi_cs_n        <= 1'b0;
                    spi_sck         <= 1'b0;
                    spi_mosi        <= 1'b0;
                    phase           <= 1'b0;
                    send_addr_phase <= 1'b1;
                    tx_shift        <= addr;
                    rx_shift        <= 16'h0000;
                    bit_count       <= 5'd7;
                end
            end else begin
                if (!phase) begin
                    // Fase alta de SCK
                    spi_sck <= 1'b1;
                    phase   <= 1'b1;

                    if (send_addr_phase)
                        spi_mosi <= tx_shift[7];
                    else
                        spi_mosi <= 1'b0;
                end else begin
                    // Fase baja de SCK
                    spi_sck <= 1'b0;
                    phase   <= 1'b0;

                    if (send_addr_phase) begin
                        if (bit_count == 5'd0) begin
                            send_addr_phase <= 1'b0;
                            bit_count       <= 5'd15;
                        end else begin
                            tx_shift  <= {tx_shift[6:0], 1'b0};
                            bit_count <= bit_count - 5'd1;
                        end
                    end else begin
                        rx_shift <= {rx_shift[14:0], spi_miso};

                        if (bit_count == 5'd0) begin
                            instr    <= {rx_shift[14:0], spi_miso};
                            busy     <= 1'b0;
                            done     <= 1'b1;
                            spi_cs_n <= 1'b1;
                            spi_sck  <= 1'b0;
                            spi_mosi <= 1'b0;
                        end else begin
                            bit_count <= bit_count - 5'd1;
                        end
                    end
                end
            end
        end
    end

endmodule