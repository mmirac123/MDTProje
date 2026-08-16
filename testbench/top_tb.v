`timescale 1ns / 1ps
//  top_tb - SISTEM testbench'i. En sona birakilir.  Yazan:
//  Tum oyunu simule eder: konfigurasyon -> tur -> blackout -> basis -> puan.
//
//  MS_DIV ve CLKS_PER_BIT'i MUTLAKA kucult, yoksa tek tur bile dakikalar surer.

module top_tb;
    localparam integer MS_DIV_TB = 10;      // 1 ms = 100 ns
    localparam integer CPB_TB    = 8;       // UART bit suresi

    reg         clk = 1'b0;
    reg  [15:0] sw  = 16'h8000;             // SW15 = 1 -> reset
    reg         btnC = 1'b0, btnU = 1'b0, btnL = 1'b0, btnR = 1'b0, btnD = 1'b0;
    wire [15:0] led;
    wire [6:0]  seg;
    wire [3:0]  an;
    wire        dp, RsTx;

    always #5 clk = ~clk;

    top #(.MS_DIV(MS_DIV_TB), .CLKS_PER_BIT(CPB_TB)) uut (
        .clk(clk), .sw(sw), .btnC(btnC), .btnU(btnU), .btnL(btnL),
        .btnR(btnR), .btnD(btnD),
        .led(led), .seg(seg), .an(an), .dp(dp), .RsTx(RsTx)
    );

    // Buton basma yardimcisi: debounce esiginden UZUN basili tut
    task bas(input integer hangi);
        begin
            // YAZILACAK: hangi'ya gore btnC/U/L/R/D'yi 1 yap,
            //            debounce suresinden uzun bekle, sonra 0 yap
        end
    endtask

    initial begin
        // YAZILACAK - tam bir tur:
        //   1) sw[15]=0 (reset birak)
        //   2) konfigurasyon: sw[14] eleme, sw[13] zorluk,
        //      sw[12:11] oyuncu sayisi, sw[3:0] tur sayisi
        //   3) BTNC -> oyun basla
        //   4) animasyon + rastgele bekleme gecsin (an ve seg'i izle)
        //   5) blackout sonrasi BTNU ve BTNL'ye farkli anlarda bas
        //   6) led'lerin dogru siralamayi gosterdigini kontrol et
        //   7) $finish
    end
endmodule
