module uart_rx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx_in,
    output reg  [7:0] rx_data,
    output reg        rx_valid
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
    reg [7:0] rx_shift;
    reg rx_in_sync1, rx_in_sync2;
    
    always @(posedge clk) begin
        rx_in_sync1 <= rx_in;
        rx_in_sync2 <= rx_in_sync1;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            rx_valid <= 1'b0;
            bit_idx <= 0;
            clk_count <= 0;
            rx_shift <= 0;
            rx_data <= 0;
        end else begin
            rx_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_idx <= 0;
                    
                    if (rx_in_sync2 == 1'b0) begin
                        state <= START;
                    end
                end
                
                START: begin
                    if (clk_count < (CLKS_PER_BIT / 2) - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        if (rx_in_sync2 == 1'b0) begin
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end
                
                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        rx_shift[bit_idx] <= rx_in_sync2;
                        
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            bit_idx <= 0;
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        if (rx_in_sync2 == 1'b1) begin
                            rx_data <= rx_shift;
                            rx_valid <= 1'b1;
                        end
                        
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule