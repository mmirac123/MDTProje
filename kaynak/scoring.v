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

    // YAZILACAK: her oyuncu icin sira'yi say, puana cevir.
    //   Ipucu: 4 elemanli oldugu icin acikca yazmak da olur,
    //          generate/for dongusu de olur. Ikisi de kabul.

    assign puan0 = 3'd0;    // <-- degistir
    assign puan1 = 3'd0;
    assign puan2 = 3'd0;
    assign puan3 = 3'd0;

endmodule
