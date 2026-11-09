//==============================================================
// Module  : sync_fifo_assertions
// Desc    : SVA Assertions for Synchronous FIFO
//==============================================================

module sync_fifo_assertions #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input logic                   clk,
    input logic                   rst_n,
    input logic                   wr_en,
    input logic                   rd_en,
    input logic [DATA_WIDTH-1:0]  din,
    input logic [DATA_WIDTH-1:0]  dout,
    input logic                   full,
    input logic                   empty,
    input logic                   almost_full,
    input logic                   almost_empty,
    input logic [$clog2(DEPTH):0] count
);

    // ASSERTION 1: Full and empty never both true
    property full_empty_mutex;
        @(posedge clk) disable iff (!rst_n)
        !(full && empty);
    endproperty
    ASS_FULL_EMPTY_MUTEX: assert property (full_empty_mutex)
        else $error("[%0t] FAIL: full and empty both asserted!", $time);

    // ASSERTION 2: After reset FIFO must be empty
    property reset_empty;
        @(posedge clk)
        (!rst_n) |=> (empty && !full && count == 0);
    endproperty
    ASS_RESET_EMPTY: assert property (reset_empty)
        else $error("[%0t] FAIL: FIFO not empty after reset!", $time);

    // ASSERTION 3: Count never exceeds DEPTH
    property count_in_range;
        @(posedge clk) disable iff (!rst_n)
        (count <= DEPTH);
    endproperty
    ASS_COUNT_RANGE: assert property (count_in_range)
        else $error("[%0t] FAIL: count=%0d exceeded DEPTH=%0d!",
                     $time, count, DEPTH);

    // ASSERTION 4: Full flag correct
    property full_when_count_max;
        @(posedge clk) disable iff (!rst_n)
        (count == DEPTH) |-> full;
    endproperty
    ASS_FULL_CORRECT: assert property (full_when_count_max)
        else $error("[%0t] FAIL: count=DEPTH but full not asserted!", $time);

    // ASSERTION 5: Empty flag correct
    property empty_when_count_zero;
        @(posedge clk) disable iff (!rst_n)
        (count == 0) |-> empty;
    endproperty
    ASS_EMPTY_CORRECT: assert property (empty_when_count_zero)
        else $error("[%0t] FAIL: count=0 but empty not asserted!", $time);

    // ASSERTION 6: No overflow
    property no_overflow;
        @(posedge clk) disable iff (!rst_n)
        (wr_en && full && !rd_en) |=>
        (count == $past(count));
    endproperty
    ASS_NO_OVERFLOW: assert property (no_overflow)
        else $error("[%0t] FAIL: Overflow!", $time);

    // ASSERTION 7: No underflow
    property no_underflow;
        @(posedge clk) disable iff (!rst_n)
        (rd_en && empty && !wr_en) |=>
        (count == $past(count));
    endproperty
    ASS_NO_UNDERFLOW: assert property (no_underflow)
        else $error("[%0t] FAIL: Underflow!", $time);

    // ASSERTION 8: Write increments count
    property write_increments_count;
        @(posedge clk) disable iff (!rst_n)
        (wr_en && !full && !rd_en) |=>
        (count == $past(count) + 1);
    endproperty
    ASS_WRITE_COUNT: assert property (write_increments_count)
        else $error("[%0t] FAIL: count did not increment after write", $time);

    // ASSERTION 9: Read decrements count
    property read_decrements_count;
        @(posedge clk) disable iff (!rst_n)
        (rd_en && !empty && !wr_en) |=>
        (count == $past(count) - 1);
    endproperty
    ASS_READ_COUNT: assert property (read_decrements_count)
        else $error("[%0t] FAIL: count did not decrement after read", $time);

    // ASSERTION 10: Almost full correct
    property almost_full_correct;
        @(posedge clk) disable iff (!rst_n)
        (count == DEPTH-1) |-> almost_full;
    endproperty
    ASS_ALMOST_FULL: assert property (almost_full_correct)
        else $error("[%0t] FAIL: almost_full not asserted at count=%0d",
                     $time, count);

    // ASSERTION 11: Almost empty correct
    property almost_empty_correct;
        @(posedge clk) disable iff (!rst_n)
        (count == 1) |-> almost_empty;
    endproperty
    ASS_ALMOST_EMPTY: assert property (almost_empty_correct)
        else $error("[%0t] FAIL: almost_empty not asserted at count=%0d",
                     $time, count);

    // ASSERTION 12: Simultaneous RW count stable
    property simult_rw_count_stable;
        @(posedge clk) disable iff (!rst_n)
        (wr_en && !full && rd_en && !empty) |=>
        (count == $past(count));
    endproperty
    ASS_SIMULT_RW: assert property (simult_rw_count_stable)
        else $error("[%0t] FAIL: count changed during simultaneous RW", $time);

endmodule
