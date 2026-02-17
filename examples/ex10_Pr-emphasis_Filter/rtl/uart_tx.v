module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output reg        tx_ready,
    output reg        tx_out
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam COUNTER_W = $clog2(CLKS_PER_BIT);
    
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;
    
    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [COUNTER_W-1:0] clk_count;
    reg [7:0] tx_shift;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx_out <= 1'b1;
            tx_ready <= 1'b1;
            bit_idx <= 0;
            clk_count <= 0;
            tx_shift <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_out <= 1'b1;
                    tx_ready <= 1'b1;
                    clk_count <= 0;
                    bit_idx <= 0;
                    
                    if (tx_valid && tx_ready) begin
                        tx_shift <= tx_data;
                        tx_ready <= 1'b0;
                        state <= START;
                    end
                end
                
                START: begin
                    tx_out <= 1'b0;
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end
                
                DATA: begin
                    tx_out <= tx_shift[bit_idx];
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            bit_idx <= 0;
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx_out <= 1'b1;
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule