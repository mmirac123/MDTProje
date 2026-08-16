`timescale 1ns / 1ps
//  seg7_driver - 4 basamakli ortak anotlu ekrani surer.       Yazan:
//  Basamaklar segment hatlarini paylasir; ayni anda farkli rakam
//  gosterilemez. Cozum: cok hizli sirayla birer basamak yakmak.
//  disp_sel timebase'den gelir.
//
//  DIKKAT: Bu taramayi oyunun 400 ms'lik animasyonuyla karistirma.
//          Animasyon sadece basamak_en maskesini degistirir.

module seg7_driver(
    input  wire [1:0] disp_sel,
    input  wire [3:0] d0, d1, d2, d3,   // gosterilecek rakamlar
    input  wire [3:0] basamak_en,       // 1 = o basamak YANIK
    output reg  [6:0] seg,              // AKTIF-DUSUK, sira: gfedcba
    output reg  [3:0] an                // AKTIF-DUSUK
);

    reg [3:0] rakam;

    // YAZILACAK:
    //   1) disp_sel'e gore d0..d3'ten birini rakam'a al
    //   2) an = 4'b1111 (hepsi kapali);
    //      basamak_en[disp_sel] 1 ise sadece an[disp_sel] = 0
    //   3) rakam'i segment desenine cevir (case):
    //      0:7'b1000000  1:7'b1111001  2:7'b0100100  3:7'b0110000
    //      4:7'b0011001  5:7'b0010010  6:7'b0000010  7:7'b1111000
    //      8:7'b0000000  9:7'b0011000  default:7'b1111111 (kapali)
    always @(*) begin
        rakam = 4'd0;
        an    = 4'b1111;
        seg   = 7'b1111111;

    end

endmodule
