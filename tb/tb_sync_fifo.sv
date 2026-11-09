//==============================================================
// Module  : tb_sync_fifo
// Desc    : Testbench for Synchronous FIFO
//==============================================================

`timescale 1ns/1ps

module tb_sync_fifo;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 16;
    localparam CLK_PERIOD = 10;

    logic                  clk, rst_n;
    logic                  wr_en, rd_en;
    logic [DATA_WIDTH-1:0] din, dout;
    logic                  full, empty;
    logic                  almost_full, almost_empty;
    logic [DATA_WIDTH-1:0] sb [$];
    int                    error_count = 0;

    // DUT
    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .wr_en        (wr_en),
        .din          (din),
        .rd_en        (rd_en),
        .dout         (dout),
        .full         (full),
        .empty        (empty),
        .almost_full  (almost_full),
        .almost_empty (almost_empty)
    );

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Tasks
    task apply_reset();
        rst_n = 0; wr_en = 0; rd_en = 0; din = '0;
        repeat(4) @(posedge clk);
        @(negedge clk);
        rst_n = 1;
        $display("[%0t] Reset Released", $time);
    endtask

    task do_write(input logic [DATA_WIDTH-1:0] data);
        @(negedge clk);
        if (!full) begin
            wr_en = 1; din = data;
            sb.push_back(data);
            @(posedge clk); #1;
            wr_en = 0;
            $display("[%0t] WRITE: data=0x%0h count=%0d",
                      $time, data, dut.count);
        end else
            $display("[%0t] WRITE SKIPPED: FIFO full", $time);
    endtask

    task do_read();
        @(negedge clk);
        if (!empty) begin
            rd_en = 1;
            @(posedge clk); #1;
            rd_en = 0;
            if (sb.size() > 0) begin
                automatic logic [DATA_WIDTH-1:0] expected;
                expected = sb.pop_front();
                if (dout !== expected) begin
                    $display("[%0t] ERROR: READ expected=0x%0h got=0x%0h",
                              $time, expected, dout);
                    error_count++;
                end else
                    $display("[%0t] READ OK: data=0x%0h", $time, dout);
            end
        end else
            $display("[%0t] READ SKIPPED: FIFO empty", $time);
    endtask

    task check_flag(
        input string flag_name,
        input logic  actual,
        input logic  expected
    );
        if (actual !== expected) begin
            $display("[%0t] FLAG ERROR: %s expected=%b got=%b",
                      $time, flag_name, expected, actual);
            error_count++;
        end else
            $display("[%0t] FLAG OK: %s = %b", $time, flag_name, actual);
    endtask

    // Main Test
    initial begin
        $display("========================================");
        $display("       SYNC FIFO TESTBENCH START        ");
        $display("========================================");

        // TEST 1
        $display("\n--- TEST 1: Reset Check ---");
        apply_reset();
        @(posedge clk); #1;
        check_flag("empty", empty, 1'b1);
        check_flag("full",  full,  1'b0);

        // TEST 2
        $display("\n--- TEST 2: Simple Write & Read ---");
        do_write(8'hAA);
        do_write(8'hBB);
        do_write(8'hCC);
        check_flag("empty", empty, 1'b0);
        do_read();
        do_read();
        do_read();
        check_flag("empty", empty, 1'b1);

        // TEST 3
        $display("\n--- TEST 3: Fill FIFO ---");
        repeat(DEPTH) do_write($random % 256);
        check_flag("full",  full,  1'b1);
        check_flag("empty", empty, 1'b0);

        // TEST 4
        $display("\n--- TEST 4: Empty FIFO ---");
        repeat(DEPTH) do_read();
        check_flag("empty", empty, 1'b1);
        check_flag("full",  full,  1'b0);

        // TEST 5
        $display("\n--- TEST 5: Overflow Protection ---");
        repeat(DEPTH) do_write($urandom_range(0, 255));
        check_flag("full", full, 1'b1);
        do_write(8'hFF);
        check_flag("full", full, 1'b1);
        repeat(DEPTH) do_read();

        // TEST 6
        $display("\n--- TEST 6: Underflow Protection ---");
        check_flag("empty", empty, 1'b1);
        do_read();
        check_flag("empty", empty, 1'b1);

        // TEST 7
        $display("\n--- TEST 7: Simultaneous Read & Write ---");
        apply_reset();
        sb = {};
        do_write(8'h11);
        do_write(8'h22);
        do_write(8'h33);
        fork
            do_write(8'h44);
            do_read();
        join
        $display("[%0t] Simultaneous RW done, count=%0d",
                  $time, dut.count);
        repeat(3) do_read();

        // TEST 8
        $display("\n--- TEST 8: Almost Full / Almost Empty ---");
        apply_reset();
        sb = {};
        repeat(DEPTH-1) do_write($urandom_range(0, 255));
        check_flag("almost_full",  almost_full,  1'b1);
        check_flag("full",         full,         1'b0);
        repeat(DEPTH-2) do_read();
        check_flag("almost_empty", almost_empty, 1'b1);
        check_flag("empty",        empty,        1'b0);

        // FINAL REPORT
        $display("\n========================================");
        if (error_count == 0)
            $display("  ALL TESTS PASSED   ERRORS = 0");
        else
            $display("  TESTS FAILED   ERRORS = %0d", error_count);
        $display("========================================");

        $finish;
    end

    // Watchdog
    initial begin
        #500000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    // Assertions instantiation
    sync_fifo_assertions #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) u_assertions (
        .clk          (clk),
        .rst_n        (rst_n),
        .wr_en        (wr_en),
        .rd_en        (rd_en),
        .din          (din),
        .dout         (dout),
        .full         (full),
        .empty        (empty),
        .almost_full  (almost_full),
        .almost_empty (almost_empty),
        .count        (dut.count)
    );

    // Coverage instantiation
    /*sync_fifo_coverage #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) u_coverage (
        .clk          (clk),
        .rst_n        (rst_n),
        .wr_en        (wr_en),
        .rd_en        (rd_en),
        .din          (din),
        .dout         (dout),
        .full         (full),
        .empty        (empty),
        .almost_full  (almost_full),
        .almost_empty (almost_empty),
        .count        (dut.count)
    );*/

endmodule
