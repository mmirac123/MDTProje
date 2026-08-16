`timescale 1ns / 1ps
//  lfsr16_tb - dalga formuna bak. Yazan:
//  Kontrol: deger hic 0 oluyor mu (olmamali), tekrar SEED'e donmesi
//           kac cevrim suruyor (maksimum uzunlukta 65535 olmali).

module lfsr16_tb;
    reg clk = 1'b0, rst = 1'b1;
    wire [15:0] deger;

    always #5 clk = ~clk;
    lfsr16 uut (.clk(clk), .rst(rst), .deger(deger));

    initial begin
        // YAZILACAK: rst'yi birak, ~70000 cevrim kostur, $finish
    end
endmodule
