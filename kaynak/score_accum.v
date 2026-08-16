`timescale 1ns / 1ps
//  score_accum - puan defteri + eleme karari.                  Yazan:

module score_accum(
    input  wire       clk, rst,
    input  wire       tur_sonu,          // TEK cevrimlik puls
    input  wire       eleme_modu,
    input  wire [3:0] oyuncu_maske,      // 2/3/4 oyuncu -> 0011 / 0111 / 1111
    input  wire [2:0] puan0, puan1, puan2, puan3,
    input  wire [3:0] yanlis_baslangic,
    input  wire [3:0] zaman_asimi,

    output reg  [6:0] toplam0, toplam1, toplam2, toplam3,  // max 16*4 = 64
    output reg  [3:0] yasayan,
    output wire [1:0] kazanan,
    output wire       beraberlik
);

    // YAZILACAK (sirali):
    //   rst      -> toplamlar 0 ; yasayan <= oyuncu_maske
    //   tur_sonu -> toplam_i <= toplam_i + puan_i
    //               eleme_modu && (yanlis_baslangic[i] || zaman_asimi[i])
    //                          -> yasayan[i] <= 0
    always @(posedge clk) begin

    end

    // YAZILACAK (kombinasyonel): en buyuk toplami bul.
    //   Birden fazla oyuncu ayni en buyuk degerdeyse beraberlik = 1
    assign kazanan    = 2'd0;    // <-- degistir
    assign beraberlik = 1'b0;    // <-- degistir

endmodule
