`timescale 1ns / 1ps

module scoring(
    input   [12:0] sure0, sure1, sure2, sure3,
    input   [3:0]  gecerli,
    input   [3:0]  aktif,
    output  [2:0]  puan0, puan1, puan2, puan3
);

    //  Sayilacak oyuncular: hem oynuyor hem de gecerli bir olcumu var.
    

    wire [3:0] olculen = gecerli & aktif;


    // 0 numarali oyuncuyu gecenler
    wire [2:0] onde0 = ((olculen[1] && (sure1 < sure0)) ? 3'd1 : 3'd0)
                     + ((olculen[2] && (sure2 < sure0)) ? 3'd1 : 3'd0)
                     + ((olculen[3] && (sure3 < sure0)) ? 3'd1 : 3'd0);

    //  1 numarali oyuncuyu gecenler
    wire [2:0] onde1 = ((olculen[0] && (sure0 < sure1)) ? 3'd1 : 3'd0)
                     + ((olculen[2] && (sure2 < sure1)) ? 3'd1 : 3'd0)
                     + ((olculen[3] && (sure3 < sure1)) ? 3'd1 : 3'd0);

    //  2 numarali oyuncuyu gecenler
    wire [2:0] onde2 = ((olculen[0] && (sure0 < sure2)) ? 3'd1 : 3'd0)
                     + ((olculen[1] && (sure1 < sure2)) ? 3'd1 : 3'd0)
                     + ((olculen[3] && (sure3 < sure2)) ? 3'd1 : 3'd0);

    //3 numarali oyuncuyu gecenler:
    wire [2:0] onde3 = ((olculen[0] && (sure0 < sure3)) ? 3'd1 : 3'd0)
                     + ((olculen[1] && (sure1 < sure3)) ? 3'd1 : 3'd0)
                     + ((olculen[2] && (sure2 < sure3)) ? 3'd1 : 3'd0);


    assign puan0 = olculen[0] ? (3'd4 - onde0) : 3'd0; // ILK OYUNCUNUN PUANI = 4 - (ILK OYUNCUDAN HIZLI OLANLAR)
    assign puan1 = olculen[1] ? (3'd4 - onde1) : 3'd0; // BENZER MANTIK...
    assign puan2 = olculen[2] ? (3'd4 - onde2) : 3'd0;
    assign puan3 = olculen[3] ? (3'd4 - onde3) : 3'd0;

endmodule