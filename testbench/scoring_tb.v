`timescale 1ns / 1ps
//  scoring_tb - burada $display GEREKLI. Yazan:
//  Kombinasyonel oldugu icin saat bile gerekmez: deger ver, sonucu oku.

module scoring_tb;
    reg  [12:0] sure0, sure1, sure2, sure3;
    reg  [3:0]  gecerli, aktif;
    wire [2:0]  puan0, puan1, puan2, puan3;

    scoring uut (.sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
                 .gecerli(gecerli), .aktif(aktif),
                 .puan0(puan0), .puan1(puan1), .puan2(puan2), .puan3(puan3));

    initial begin
        // YAZILACAK - dort senaryo, her birinde $display + beklenen deger:
        //   1) NORMAL     : 100,200,300,400 hepsi gecerli
        //      -> 4,3,2,1
        //   2) BERABERLIK : 100,100,300,400
        //      -> 4,4,2,1   (ilk ikisi ayni sirayi paylasir)
        //   3) GECERSIZ   : 100,200 gecerli; P3 false start, P4 timeout
        //      -> 4,3,0,0
        //   4) 2 OYUNCU   : aktif = 4'b0011, sure0=250 sure1=180
        //      -> P2 birinci (4 puan), P1 ikinci (3 puan)
    end
endmodule
