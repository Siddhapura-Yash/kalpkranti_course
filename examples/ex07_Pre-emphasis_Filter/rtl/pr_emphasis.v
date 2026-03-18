module pr_emphasis #(
    parameter DATA_WIDTH = 16,
    parameter ALPHA = 16'd16384
)(
    input clk,
    input rst,
    input en,
    input signed [DATA_WIDTH-1:0] x_in,
    output reg signed [DATA_WIDTH-1:0] y_out
);

reg signed [DATA_WIDTH-1:0] x_prev;

wire signed [2*DATA_WIDTH-1:0] mult_out;
assign mult_out = x_prev * $signed(ALPHA);

wire signed [DATA_WIDTH-1:0] alpha_x_prev;
assign alpha_x_prev = mult_out[30:15];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        x_prev <= 0;
        y_out <= 0;
    end else if (en) begin
        y_out <= x_in - alpha_x_prev;
        x_prev <= x_in;
    end
end

endmodule
