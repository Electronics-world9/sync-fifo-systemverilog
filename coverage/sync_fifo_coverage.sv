//==============================================================
// Module  : sync_fifo_coverage
// Desc    : Functional Coverage for Synchronous FIFO
//==============================================================

module sync_fifo_coverage #(
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

    // COVERGROUP 1: FIFO State Coverage
    covergroup fifo_state_cg @(posedge clk);
        cp_count: coverpoint count {
            bins empty_state    = {0};
            bins almost_empty_s = {1};
            bins low_fill       = {[2:DEPTH/2-1]};
            bins high_fill      = {[DEPTH/2:DEPTH-2]};
            bins almost_full_s  = {DEPTH-1};
            bins full_state     = {DEPTH};
        }
        cp_full: coverpoint full {
            bins not_full = {0};
            bins is_full  = {1};
        }
        cp_empty: coverpoint empty {
            bins not_empty = {0};
            bins is_empty  = {1};
        }
        cp_almost_full: coverpoint almost_full {
            bins not_almost_full = {0};
            bins is_almost_full  = {1};
        }
        cp_almost_empty: coverpoint almost_empty {
            bins not_almost_empty = {0};
            bins is_almost_empty  = {1};
        }
    endgroup

    // COVERGROUP 2: Operation Coverage
    covergroup fifo_ops_cg @(posedge clk);
        cp_wr_en: coverpoint wr_en {
            bins active   = {1};
            bins inactive = {0};
        }
        cp_rd_en: coverpoint rd_en {
            bins active   = {1};
            bins inactive = {0};
        }
        cp_full: coverpoint full {
            bins not_full = {0};
            bins is_full  = {1};
        }
        cp_empty: coverpoint empty {
            bins not_empty = {0};
            bins is_empty  = {1};
        }
        // Write vs Full
        cx_write_full: cross cp_wr_en, cp_full {
            bins valid_write  = binsof(cp_wr_en.active)
                                && binsof(cp_full.not_full);
            bins overflow_try = binsof(cp_wr_en.active)
                                && binsof(cp_full.is_full);
            bins no_write     = binsof(cp_wr_en.inactive);
        }
        // Read vs Empty
        cx_read_empty: cross cp_rd_en, cp_empty {
            bins valid_read    = binsof(cp_rd_en.active)
                                 && binsof(cp_empty.not_empty);
            bins underflow_try = binsof(cp_rd_en.active)
                                 && binsof(cp_empty.is_empty);
            bins no_read       = binsof(cp_rd_en.inactive);
        }
        // Simultaneous RW
        cx_simult: cross cp_wr_en, cp_rd_en {
            bins simult_rw = binsof(cp_wr_en.active)
                             && binsof(cp_rd_en.active);
            bins wr_only   = binsof(cp_wr_en.active)
                             && binsof(cp_rd_en.inactive);
            bins rd_only   = binsof(cp_wr_en.inactive)
                             && binsof(cp_rd_en.active);
            bins idle      = binsof(cp_wr_en.inactive)
                             && binsof(cp_rd_en.inactive);
        }
    endgroup

    // COVERGROUP 3: Data Coverage
    covergroup fifo_data_cg @(posedge clk);
        cp_din: coverpoint din {
            bins zero = {8'h00};
            bins max  = {8'hFF};
            bins low  = {[8'h01:8'h3F]};
            bins mid  = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
        }
        cp_dout: coverpoint dout {
            bins zero = {8'h00};
            bins max  = {8'hFF};
            bins low  = {[8'h01:8'h3F]};
            bins mid  = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
        }
    endgroup

    // COVERGROUP 4: Reset Coverage
    covergroup fifo_reset_cg @(negedge rst_n);
        cp_count_at_reset: coverpoint count {
            bins reset_when_empty   = {0};
            bins reset_when_partial = {[1:DEPTH-1]};
            bins reset_when_full    = {DEPTH};
        }
    endgroup

    // Instantiate covergroups
    fifo_state_cg state_cg = new();
    fifo_ops_cg   ops_cg   = new();
    fifo_data_cg  data_cg  = new();
    fifo_reset_cg reset_cg = new();

    // Print coverage at end
    final begin
        $display("\n========================================");
        $display("       FUNCTIONAL COVERAGE REPORT       ");
        $display("========================================");
        $display("State Coverage:     %.1f%%",
                  state_cg.get_coverage());
        $display("Operation Coverage: %.1f%%",
                  ops_cg.get_coverage());
        $display("Data Coverage:      %.1f%%",
                  data_cg.get_coverage());
        $display("Reset Coverage:     %.1f%%",
                  reset_cg.get_coverage());
        $display("========================================");
        $display("Overall Coverage:   %.1f%%", $get_coverage());
        $display("========================================\n");
    end

endmodule
