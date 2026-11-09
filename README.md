# Synchronous FIFO: SystemVerilog Design and Verification

A parameterized synchronous FIFO written in SystemVerilog, verified with a
directed self-checking testbench, 12 SystemVerilog Assertions (SVA), and a
functional-coverage module. Simulated with QuestaSim (free edition).

## Design

`rtl/sync_fifo.sv`

| Parameter | Default | Meaning |
|-----------|:-------:|---------|
| `DATA_WIDTH` | 8 | Width of each data word |
| `DEPTH` | 16 | Number of entries (use a power of two) |

**Ports:** `clk`, `rst_n` (active-low synchronous reset), `wr_en`, `din`, `rd_en`,
`dout`, `full`, `empty`, `almost_full`, `almost_empty`.

**How it works**
- Read and write pointers are one bit wider than the address, so the extra
  wrap bit tells a full FIFO from an empty one.
- `empty` is asserted when the two pointers are equal. `full` is asserted when
  the pointers differ only in the wrap bit.
- A separate `count` register tracks occupancy. `almost_empty` is `count == 1`
  and `almost_full` is `count == DEPTH-1`.
- Writes while full and reads while empty are ignored.
- `dout` is registered, so read data appears one clock after `rd_en`.

## Verification

| Piece | File | What it does |
|-------|------|--------------|
| Testbench | `tb/tb_sync_fifo.sv` | Directed tests with a queue-based scoreboard and flag checks |
| Assertions | `assertions/sync_fifo_assertions.sv` | 12 SVA properties, bound to the DUT signals in the testbench |
| Coverage | `coverage/sync_fifo_coverage.sv` | Four covergroups: state, operations (with crosses), data, reset |

### Testbench scenarios

| # | Test | Checks |
|:-:|------|--------|
| 1 | Reset check | `empty` high and `full` low after reset |
| 2 | Simple write and read | Data written (`AA`, `BB`, `CC`) is read back in order |
| 3 | Fill FIFO | `full` asserted after `DEPTH` writes |
| 4 | Empty FIFO | `empty` asserted after `DEPTH` reads |
| 5 | Overflow protection | Extra write when full leaves `full` asserted |
| 6 | Underflow protection | Read when empty leaves `empty` asserted |
| 7 | Simultaneous read and write | Both operations in the same cycle |
| 8 | Almost full / almost empty | `almost_full` at `DEPTH-1`, `almost_empty` at 1 |

### Assertions

| Assertion | Property |
|-----------|----------|
| `ASS_FULL_EMPTY_MUTEX` | `full` and `empty` are never both high |
| `ASS_RESET_EMPTY` | After reset the FIFO is empty and `count == 0` |
| `ASS_COUNT_RANGE` | `count` never exceeds `DEPTH` |
| `ASS_FULL_CORRECT` | `count == DEPTH` implies `full` |
| `ASS_EMPTY_CORRECT` | `count == 0` implies `empty` |
| `ASS_NO_OVERFLOW` | Write when full (no read) leaves `count` unchanged |
| `ASS_NO_UNDERFLOW` | Read when empty (no write) leaves `count` unchanged |
| `ASS_WRITE_COUNT` | A write into a non-full FIFO increments `count` |
| `ASS_READ_COUNT` | A read from a non-empty FIFO decrements `count` |
| `ASS_ALMOST_FULL` | `count == DEPTH-1` implies `almost_full` |
| `ASS_ALMOST_EMPTY` | `count == 1` implies `almost_empty` |
| `ASS_SIMULT_RW` | Simultaneous valid read and write keep `count` stable |

### Results

- Assertion coverage: **83.33%** in QuestaSim (free edition).
- The functional-coverage module is included, but its instantiation in
  `tb/tb_sync_fifo.sv` is commented out, so it is not part of the default run.

## Repository layout

```
├── rtl/          sync_fifo.sv
├── tb/           tb_sync_fifo.sv
├── assertions/   sync_fifo_assertions.sv
├── coverage/     sync_fifo_coverage.sv
└── README.md
```

## Running the simulation

With QuestaSim (adjust options for your setup):

```
vlib work
vlog rtl/sync_fifo.sv assertions/sync_fifo_assertions.sv coverage/sync_fifo_coverage.sv tb/tb_sync_fifo.sv
vsim -c tb_sync_fifo -do "run -all; quit"
```

The testbench prints each write, read and flag check, then a final line:
`ALL TESTS PASSED   ERRORS = 0` or `TESTS FAILED`.

To include the functional-coverage module, remove the `/* ... */` comment
around the `sync_fifo_coverage` instance at the bottom of `tb/tb_sync_fifo.sv`.
This needs a QuestaSim edition that supports covergroups.
