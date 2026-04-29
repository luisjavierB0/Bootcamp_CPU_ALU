# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project_smoke(dut):
    dut._log.info("Start Tiny8 SPI-fetch smoke test")

    clock = Clock(dut.clk, 10, unit="us")  # 100 kHz
    cocotb.start_soon(clock.start())

    # Default idle values
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0  # MISO=0, all other external inputs low
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Let the CPU run for a while fetching zeros from SPI.
    await ClockCycles(dut.clk, 80)

    # Smoke checks consistent with this design:
    # - outputs must stay defined
    # - uio[0:2] are outputs, the rest are inputs
    assert dut.uio_oe.value.integer == 0x07
    assert dut.uo_out.value.integer == 0x00
