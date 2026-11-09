//==============================================================
// Module  : sync_fifo
// Desc    : Synchronous FIFO ? Parameterized, Industry Grade
// Tool    : AMD Vivado / Questa (SystemVerilog)
//==============================================================

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] din,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] dout,
    output logic                  full,
    output logic                  empty,
    output logic                  almost_full,
    output logic                  almost_empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH:0]   wr_ptr;
    logic [ADDR_WIDTH:0]   rd_ptr;
    logic [ADDR_WIDTH:0]   count;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [ADDR_WIDTH-1:0] rd_addr;

    assign wr_addr = wr_ptr[ADDR_WIDTH-1:0];
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // Write Logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            mem[wr_addr] <= din;
            wr_ptr       <= wr_ptr + 1'b1;
        end
    end

    // Read Logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr <= '0;
            dout   <= '0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_addr];
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Count Logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count <= '0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10:   count <= count + 1'b1;
                2'b01:   count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

    // Status Flags
    assign empty        = (wr_ptr == rd_ptr);
    assign full         = (wr_ptr == {~rd_ptr[ADDR_WIDTH],
                                       rd_ptr[ADDR_WIDTH-1:0]});
    assign almost_empty = (count == 1);
    assign almost_full  = (count == DEPTH - 1);

endmodule
