`timescale 1ns / 1ps
//  scoring_tb - burada $display GEREKLI. Yazan:
//  Kombinasyonel oldugu icin saat bile gerekmez: deger ver, sonucu oku.

module scoring_tb;
    reg  [12:0] sure0, sure1, sure2, sure3;
    reg  [3:0]  gecerli, aktif;
    wire [2:0]  puan0, puan1, puan2, puan3;

    integer hata = 0;

    scoring uut (.sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
                 .gecerli(gecerli), .aktif(aktif),
                 .puan0(puan0), .puan1(puan1), .puan2(puan2), .puan3(puan3));

    task dene(input [80*8:1] ad,
              input [12:0] s0, input [12:0] s1, input [12:0] s2, input [12:0] s3,
              input [3:0] g, input [3:0] a,
              input [2:0] b0, input [2:0] b1, input [2:0] b2, input [2:0] b3);
        begin
            sure0 = s0; sure1 = s1; sure2 = s2; sure3 = s3;
            gecerli = g; aktif = a;
            #1;
            $display("%0s", ad);
            $display("   sure  = %4d %4d %4d %4d   gecerli=%b aktif=%b",
                     s0, s1, s2, s3, g, a);
            $display("   puan  = %0d %0d %0d %0d   (beklenen %0d %0d %0d %0d)  %s",
                     puan0, puan1, puan2, puan3, b0, b1, b2, b3,
                     ((puan0===b0)&&(puan1===b1)&&(puan2===b2)&&(puan3===b3))
                        ? "GECTI" : "HATA");
            if (!((puan0===b0)&&(puan1===b1)&&(puan2===b2)&&(puan3===b3)))
                hata = hata + 1;
        end
    endtask

    initial begin
        $display("--- scoring testi ---");

        // 1) NORMAL : hepsi gecerli, farkli sureler -> 4 3 2 1
        dene("1) NORMAL",
             13'd100, 13'd200, 13'd300, 13'd400,
             4'b1111, 4'b1111,
             3'd4, 3'd3, 3'd2, 3'd1);

        // 2) BERABERLIK : ilk ikisi ayni ms -> ikisi de 1. (4 puan)
        //    Ucuncu oyuncunun onunde KESINLIKLE 2 kisi var -> 2 puan
        dene("2) BERABERLIK",
             13'd100, 13'd100, 13'd300, 13'd400,
             4'b1111, 4'b1111,
             3'd4, 3'd4, 3'd2, 3'd1);

        // 3) GECERSIZ : P3 false start, P4 timeout -> ikisi de 0
        dene("3) GECERSIZ BASISLAR",
             13'd100, 13'd200, 13'd0, 13'd0,
             4'b0011, 4'b1111,
             3'd4, 3'd3, 3'd0, 3'd0);

        // 4) 2 OYUNCU : sadece P1-P2 oynuyor, P2 daha hizli
        dene("4) 2 OYUNCU",
             13'd250, 13'd180, 13'd0, 13'd0,
             4'b0011, 4'b0011,
             3'd3, 3'd4, 3'd0, 3'd0);

        // 5) ELENMIS OYUNCU : P2 aktif degil, olcumu sayilmamali
        dene("5) ELENMIS OYUNCU (P2 aktif degil)",
             13'd300, 13'd100, 13'd400, 13'd0,
             4'b0111, 4'b1101,
             3'd4, 3'd0, 3'd3, 3'd0);

        // 6) HERKES BERABER : dordu de ayni ms -> hepsi 4 puan
        dene("6) DORT KISI BERABER",
             13'd222, 13'd222, 13'd222, 13'd222,
             4'b1111, 4'b1111,
             3'd4, 3'd4, 3'd4, 3'd4);

        if (hata == 0) $display("--- SONUC: TUM TESTLER GECTI ---");
        else           $display("--- SONUC: %0d TEST HATALI ---", hata);
        $finish;
    end
endmodule
