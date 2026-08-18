`timescale 1ns / 1ps

module score_accum(
    input        clk, rst,
    input        tur_sonu,          
    input        eleme_modu,
    input  [3:0] oynayanlar,      // 2 - 3 - 4 oyuncu ---->    0011 / 0111 / 1111
    input  [2:0] puan0, puan1, puan2, puan3,
    input  [3:0] yanlis_baslangic,
    input  [3:0] zaman_asimi,

    output reg  [6:0] toplam0, toplam1, toplam2, toplam3,  // max 16*4 = 64
    output reg  [3:0] yasayan,
    output wire [1:0] kazanan,
    output wire       beraberlik
);


    always @(posedge clk) begin
        if (rst) begin //RESET DURUMU
            toplam0 <= 7'd0;
            toplam1 <= 7'd0;
            toplam2 <= 7'd0;
            toplam3 <= 7'd0;
            yasayan <= 4'b1111;
        end else if (tur_sonu) begin //TUR SONU
            toplam0 <= toplam0 + {4'd0, puan0};
            toplam1 <= toplam1 + {4'd0, puan1};
            toplam2 <= toplam2 + {4'd0, puan2};
            toplam3 <= toplam3 + {4'd0, puan3};

            if (eleme_modu) begin //eleme_modu = 1'b1
                if (yanlis_baslangic[0] || zaman_asimi[0]) yasayan[0] <= 1'b0;
                if (yanlis_baslangic[1] || zaman_asimi[1]) yasayan[1] <= 1'b0;
                if (yanlis_baslangic[2] || zaman_asimi[2]) yasayan[2] <= 1'b0;
                if (yanlis_baslangic[3] || zaman_asimi[3]) yasayan[3] <= 1'b0;
            end
        end
    end

    reg [6:0] en_yuksek;      // en buyuk toplam

    always @(*) begin
        en_yuksek = 7'd0;     // toplamlar negatif olamaz, 0 guvenli baslangic
        if (oynayanlar[0] && (toplam0 > en_yuksek)) en_yuksek = toplam0;
        if (oynayanlar[1] && (toplam1 > en_yuksek)) en_yuksek = toplam1;
        if (oynayanlar[2] && (toplam2 > en_yuksek)) en_yuksek = toplam2;
        if (oynayanlar[3] && (toplam3 > en_yuksek)) en_yuksek = toplam3;
    end

    //  En yuksek puani paylasan oyuncular
    wire [3:0] lider = { oynayanlar[3] && (toplam3 == en_yuksek),
                        oynayanlar[2] && (toplam2 == en_yuksek),
                        oynayanlar[1] && (toplam1 == en_yuksek),
                        oynayanlar[0] && (toplam0 == en_yuksek) };

    wire [2:0] lider_sayisi = {2'd0, lider[0]} + {2'd0, lider[1]} +
                           {2'd0, lider[2]} + {2'd0, lider[3]};

    //kazanan = en dusuk numarali en yuksek puanli oyuncu
    assign kazanan    = lider[0] ? 2'd0 :
                        lider[1] ? 2'd1 :
                        lider[2] ? 2'd2 : 2'd3;

    //  Birden fazla oyuncu ayni tepe puandaysa beraberlik durumu
    assign beraberlik = (lider_sayisi > 3'd1);

endmodule