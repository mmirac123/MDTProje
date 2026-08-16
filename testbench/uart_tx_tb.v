`timescale 1ns / 1ps
//  uart_tx_tb - Yazan:
//  CLKS_PER_BIT'i kucult, yoksa tek bayt 104 us surer (10417*10ns*10bit).
//  Kontrol: start biti 0 mu, 8 veri biti LSB-once mu, stop biti 1 mi,
//           mesgul dogru zamanlarda inip cikiyor mu.

module uart_tx_tb;
    localparam integer CPB_TB = 8;      // sim icin kisa bit suresi

    reg  clk = 1'b0, rst = 1'b1, gonder = 1'b0;
    reg  [7:0] veri = 8'h41;            // 'A' = 0100 0001
    wire tx, mesgul;

    always #5 clk = ~clk;

    uart_tx #(.CLKS_PER_BIT(CPB_TB)) uut (
        .clk(clk), .rst(rst), .gonder(gonder), .veri(veri),
        .tx(tx), .mesgul(mesgul)
    );

    initial begin
        // YAZILACAK: rst'yi birak, gonder'i 1 cevrim yukselt,
        //            mesgul dusene kadar bekle, ikinci bir bayt gonder, $finish
    end
endmodule
