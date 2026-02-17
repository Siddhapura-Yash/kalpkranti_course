`timescale 1ns/1ps

module tb;

    reg clk = 0;
    reg rst = 1;
    reg en  = 0;
    reg signed [15:0] x_in;
    wire signed [15:0] y_out;

    pr_emphasis dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .x_in(x_in),
        .y_out(y_out)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("pre_emphasis.vcd");
        $dumpvars(0, tb);
    end

    initial begin
        x_in = 0;
        en   = 0;
        #20;
        rst = 0;
        en  = 1;
        #10 x_in = 16'd1000;
        #10 x_in = 16'd2000;
        #10 x_in = 16'd1500;
        #10 x_in = -16'd1200;
        #10 x_in = 16'd3000;
        #10 x_in = 16'd0;
        #40;
        $finish;
    end

endmodule
