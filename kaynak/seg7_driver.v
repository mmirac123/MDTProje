`timescale 1ns / 1ps
//  seg7_driver - 4 basamakli ortak anotlu ekrani surer.       Yazan:
//  Basamaklar segment hatlarini paylasir; ayni anda farkli rakam
//  gosterilemez. Cozum: cok hizli sirayla birer basamak yakmak.
//  disp_sel timebase'den gelir.
//
//  DIKKAT: Bu taramayi oyunun 400 ms'lik animasyonuyla karistirma.
//          Tarama HER ZAMAN calisir (saniyede ~1500 kez, goz secemez).
//          Animasyon sadece basamak_en maskesini degistirir.

module seg7_driver(
    input  wire [1:0] disp_sel,
    input  wire [3:0] d0, d1, d2, d3,   // gosterilecek rakamlar
    input  wire [3:0] basamak_en,       // 1 = o basamak YANIK
    output reg  [6:0] seg,              // AKTIF-DUSUK, sira: gfedcba
    output reg  [3:0] an                // AKTIF-DUSUK
);

    reg [3:0] rakam;

    always @(*) begin
        // 1) disp_sel'e gore gosterilecek rakami sec
        case (disp_sel)
            2'd0:    rakam = d0;
            2'd1:    rakam = d1;
            2'd2:    rakam = d2;
            default: rakam = d3;
        endcase

        // 2) Anot secimi. Aktif-dusuk: 0 = o basamak yanik.
        //    Once hepsini kapat, sonra sadece siradaki basamagi ac.
        an = 4'b1111;
        if (basamak_en[disp_sel])
            an[disp_sel] = 1'b0;

        // 3) Rakami segment desenine cevir (aktif-dusuk, gfedcba)
        case (rakam)
            4'd0:    seg = 7'b1000000;
            4'd1:    seg = 7'b1111001;
            4'd2:    seg = 7'b0100100;
            4'd3:    seg = 7'b0110000;
            4'd4:    seg = 7'b0011001;
            4'd5:    seg = 7'b0010010;
            4'd6:    seg = 7'b0000010;
            4'd7:    seg = 7'b1111000;
            4'd8:    seg = 7'b0000000;
            4'd9:    seg = 7'b0011000;
            default: seg = 7'b1111111;   // kapali
        endcase
    end

endmodule
