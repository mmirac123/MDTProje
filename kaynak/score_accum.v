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

    //-----------------------------------------------------------------------
    //  Sirali kisim
    //
    //  NOT: reset aninda oyuncu_maske HENUZ latch'lenmemistir (game_fsm onu
    //  S_CONFIG'de BTNC ile kaydeder). Bu yuzden yasayan'i 4'b1111 ile
    //  baslatiyoruz; top zaten "aktif = oyuncu_maske & yasayan" hesapladigi
    //  icin oynamayan oyuncular kendiliginden disarida kaliyor.
    //-----------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            toplam0 <= 7'd0;
            toplam1 <= 7'd0;
            toplam2 <= 7'd0;
            toplam3 <= 7'd0;
            yasayan <= 4'b1111;
        end else if (tur_sonu) begin
            toplam0 <= toplam0 + {4'd0, puan0};
            toplam1 <= toplam1 + {4'd0, puan1};
            toplam2 <= toplam2 + {4'd0, puan2};
            toplam3 <= toplam3 + {4'd0, puan3};

            if (eleme_modu) begin
                if (yanlis_baslangic[0] || zaman_asimi[0]) yasayan[0] <= 1'b0;
                if (yanlis_baslangic[1] || zaman_asimi[1]) yasayan[1] <= 1'b0;
                if (yanlis_baslangic[2] || zaman_asimi[2]) yasayan[2] <= 1'b0;
                if (yanlis_baslangic[3] || zaman_asimi[3]) yasayan[3] <= 1'b0;
            end
        end
    end

    //-----------------------------------------------------------------------
    //  Kombinasyonel kisim: en buyuk toplami bul.
    //  Sadece oyuna dahil olan oyuncular yarisir (2 oyunculu oyunda P3/P4
    //  0 puanla kazanan ilan edilmesin).
    //-----------------------------------------------------------------------
    reg [6:0] enb;      // en buyuk toplam

    always @(*) begin
        enb = 7'd0;     // toplamlar negatif olamaz, 0 guvenli baslangic
        if (oyuncu_maske[0] && (toplam0 > enb)) enb = toplam0;
        if (oyuncu_maske[1] && (toplam1 > enb)) enb = toplam1;
        if (oyuncu_maske[2] && (toplam2 > enb)) enb = toplam2;
        if (oyuncu_maske[3] && (toplam3 > enb)) enb = toplam3;
    end

    //  En yuksek puani paylasan oyuncular
    wire [3:0] esit = { oyuncu_maske[3] && (toplam3 == enb),
                        oyuncu_maske[2] && (toplam2 == enb),
                        oyuncu_maske[1] && (toplam1 == enb),
                        oyuncu_maske[0] && (toplam0 == enb) };

    wire [2:0] esit_sayi = {2'd0, esit[0]} + {2'd0, esit[1]} +
                           {2'd0, esit[2]} + {2'd0, esit[3]};

    //  kazanan = en dusuk numarali en yuksek puanli oyuncu
    assign kazanan    = esit[0] ? 2'd0 :
                        esit[1] ? 2'd1 :
                        esit[2] ? 2'd2 : 2'd3;

    //  Birden fazla oyuncu ayni tepe puandaysa beraberlik
    assign beraberlik = (esit_sayi > 3'd1);

endmodule
