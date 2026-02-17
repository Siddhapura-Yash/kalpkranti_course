(* top *)
module top #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200
)(
   	(* iopad_external_pin, clkbuf_inhibit *) input i_clk,
   	(* iopad_external_pin *) output clk_en,
    (* iopad_external_pin *) input  i_uart_rx,
    (* iopad_external_pin *) output o_uart_tx,
    (* iopad_external_pin *) output o_uart_tx_oe,
    (* iopad_external_pin *) output o_led,
    (* iopad_external_pin *) output o_led_oe
);

assign clk_en = 1'b1;

reg [25:0] counter = 0;
reg led_reg = 0;

always @(posedge i_clk) begin
    if (counter == 26'd49_999_999) begin
        counter <= 0;
        led_reg <= ~led_reg;
    end else begin
        counter <= counter + 1;
    end
end

assign o_led = led_reg;
assign o_led_oe = 1'b1;

reg [7:0] rst_cnt = 8'hFF;
wire rst = |rst_cnt;

always @(posedge i_clk) begin
    if (rst_cnt != 0)
        rst_cnt <= rst_cnt - 1;
end

wire [7:0] rx_data;
wire rx_valid;

uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) u_rx (
    .clk(i_clk),
    .rst(rst),
    .rx_in(i_uart_rx),
    .rx_data(rx_data),
    .rx_valid(rx_valid)
);

reg [7:0] tx_data;
reg tx_valid;
wire tx_ready;
wire uart_tx_internal;

uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) u_tx (
    .clk(i_clk),
    .rst(rst),
    .tx_data(tx_data),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready),
    .tx_out(uart_tx_internal)
);

assign o_uart_tx = uart_tx_internal;
assign o_uart_tx_oe = 1'b1;

reg [15:0] sample_in;
reg byte_sel = 0;
reg sample_valid;
reg [15:0] timeout_counter = 0;

always @(posedge i_clk) begin
    sample_valid <= 0;
    
    if (rx_valid) begin
        timeout_counter <= 0;
        if (byte_sel == 0) begin
            sample_in[15:8] <= rx_data;
            byte_sel <= 1;
        end else begin
            sample_in[7:0] <= rx_data;
            byte_sel <= 0;
            sample_valid <= 1;
        end
    end else if (byte_sel == 1) begin
        if (timeout_counter == 16'd50_000) begin
            byte_sel <= 0;
            timeout_counter <= 0;
        end else begin
            timeout_counter <= timeout_counter + 1;
        end
    end
end

wire signed [15:0] filter_out;

pr_emphasis u_filter (
    .clk(i_clk),
    .rst(rst),
    .en(sample_valid),
    .x_in(sample_in),
    .y_out(filter_out)
);

reg [2:0] state = 0;

localparam IDLE   = 3'd0,
           SEND_H = 3'd1,
           WAIT_H = 3'd2,
           SEND_L = 3'd3,
           WAIT_L = 3'd4;

always @(posedge i_clk) begin
    if (rst) begin
        state <= IDLE;
        tx_valid <= 0;
    end else begin
        tx_valid <= 0;
        case (state)
            IDLE:
                if (sample_valid)
                    state <= SEND_H;
            
            SEND_H:
                if (tx_ready) begin
                    tx_data <= filter_out[15:8];
                    tx_valid <= 1;
                    state <= WAIT_H;
                end

            WAIT_H:
                if (!tx_ready)
                    state <= SEND_L;
            
            SEND_L:
                if (tx_ready) begin
                    tx_data <= filter_out[7:0];
                    tx_valid <= 1;
                    state <= WAIT_L;
                end

            WAIT_L:
                if (!tx_ready)
                    state <= IDLE;
            
            default:
                state <= IDLE;
        endcase
    end
end

endmodule