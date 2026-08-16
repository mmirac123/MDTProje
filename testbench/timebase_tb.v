`timescale 1ns / 1ps


module timebase_tb;

    localparam integer MS_DIV_TB = 10;

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    wire        vurus_1ms;
    wire [1:0]  disp_sel;

    timebase #(.MS_DIV(MS_DIV_TB)) uut (
        .clk       (clk),
        .rst       (rst),
        .vurus_1ms (vurus_1ms),
        .disp_sel  (disp_sel)
    );

    always #5 clk = ~clk;


    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        repeat(300000) @(posedge clk);
        $finish;
    end
endmodule
