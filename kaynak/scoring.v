`timescale 1ns / 1ps
//  scoring - sureleri siraya dizip puana cevirir. Kombinasyonel.  Yazan:
//
//  SIRALAMA ALGORITMASI YAZMAYA GEREK YOK. Tek fikir:
//     sira[i] = "benden KESINLIKLE daha hizli kac gecerli oyuncu var"
//     puan[i] = gecerli[i] ? (4 - sira[i]) : 0
//
//  Iki bedava kazanc:
//    - Ayni ms'de basanlarin cevabi ayni cikar -> beraberlik ekstra kod istemez
//    - puan sayisi = yanacak LED sayisi -> led_ctrl'de tekrar hesaplama

module scoring(
    input  wire [12:0] sure0, sure1, sure2, sure3,
    input  wire [3:0]  gecerli,
    input  wire [3:0]  aktif,
    output wire [2:0]  puan0, puan1, puan2, puan3
);

    //  "Sayilacak" oyuncular: hem oynuyor hem gecerli bir olcumu var.
    wire [3:0] iyi = gecerli & aktif;

    //-----------------------------------------------------------------------
    //  Kendini de listeye koyabiliriz: "sure_i < sure_i" hicbir zaman dogru
    //  olmadigi icin kendini saymaz. Bu yuzden i'yi disarida birakmaya
    //  gerek yok - fonksiyon dort oyuncuyu birden tarayabilir.
    //-----------------------------------------------------------------------
    function [2:0] puanla;
        input [12:0] benim;
        input [12:0] s0, s1, s2, s3;
        input [3:0]  liste;
        input        benim_gecerli;
        reg   [2:0]  sira;
        begin
            sira = 3'd0;
            if (liste[0] && (s0 < benim)) sira = sira + 3'd1;
            if (liste[1] && (s1 < benim)) sira = sira + 3'd1;
            if (liste[2] && (s2 < benim)) sira = sira + 3'd1;
            if (liste[3] && (s3 < benim)) sira = sira + 3'd1;
            puanla = benim_gecerli ? (3'd4 - sira) : 3'd0;
        end
    endfunction

    assign puan0 = puanla(sure0, sure0, sure1, sure2, sure3, iyi, iyi[0]);
    assign puan1 = puanla(sure1, sure0, sure1, sure2, sure3, iyi, iyi[1]);
    assign puan2 = puanla(sure2, sure0, sure1, sure2, sure3, iyi, iyi[2]);
    assign puan3 = puanla(sure3, sure0, sure1, sure2, sure3, iyi, iyi[3]);

endmodule
