`timescale 1ns / 1ps

module reaction_capture(
    input  wire        clk, rst, vurus_1ms,
    input  wire        t0,          
    input  wire        hazirlik,     
    input  wire        olcum_aktif,     
    input  wire [3:0]  basildi,       
    input  wire [3:0]  aktif,       
    output reg  [12:0] sure0, sure1, sure2, sure3,   // ms
    output reg  [3:0]  gecerli,
    output reg  [3:0]  yanlis_baslangic,
    output reg  [3:0]  zaman_asimi,
    output wire        tur_hazir
);

    localparam [12:0] SURE_SINIRI_MS = 13'd5000;   // 5 SANIYELIK BIR PENCERE, OYUNCULARIN BASMAK ICIN 5 SANIYESI VAR

    reg [12:0] ms;
    reg hazirlik_onceki;                    // hazirlik'nin bir onceki degeri

    //  Turun BASI = hazirlik'nin yukselen kenari.
    //  Bayraklari BURADA temizliyoruz, t0'da DEGIL: false start hazirlik boyunca olusur, t0'da temizlersek blackout'tan once yakalanan false start'lar silinirdi.
    wire tur_basi = hazirlik & ~hazirlik_onceki;

    always @(posedge clk) begin
        if(rst)begin
        hazirlik_onceki <= 1'b0;
        end
        else  begin  
        hazirlik_onceki <= hazirlik;
        end
    end

    always @(posedge clk) begin
        if (rst || tur_basi) begin // RESET VEYA YENITURA GECINCE BASLANGIC DURUMUNA GECILIYOR
            ms <= 13'd0;
            sure0  <= 13'd0;
            sure1   <= 13'd0;
            sure2   <= 13'd0;
            sure3   <= 13'd0;
            gecerli <= 4'b0000;
            yanlis_baslangic <= 4'b0000;
            zaman_asimi    <= 4'b0000;
        end else begin

            if (t0)
                ms <= 13'd0;
            else if (olcum_aktif && vurus_1ms && (ms < SURE_SINIRI_MS)) //REFLEKS SURESI ARTMAYA BASLIYOR.
                ms <= ms + 13'd1;

            if (aktif[0] && basildi[0]) begin
                if (hazirlik) //SILAHLI AKTIFKEN INPUT GELIRSE --> FALSE START DURUMU
                    yanlis_baslangic[0] <= 1'b1;
                else if (olcum_aktif && (ms < SURE_SINIRI_MS) && !gecerli[0] && !yanlis_baslangic[0]) begin //FALSESTART YOK, INPUTLAR GECERLI
                    sure0  <= ms;
                    gecerli[0] <= 1'b1;
                end
            end

            if (aktif[1] && basildi[1]) begin
                if (hazirlik) begin
                    yanlis_baslangic[1] <= 1'b1;
                    end
                else if (olcum_aktif && (ms < SURE_SINIRI_MS) && !gecerli[1] && !yanlis_baslangic[1]) begin
                    sure1  <= ms;
                    gecerli[1] <= 1'b1;
                end
            end

            if (aktif[2] && basildi[2]) begin
                if (hazirlik)
                    yanlis_baslangic[2] <= 1'b1;
                else if (olcum_aktif && (ms < SURE_SINIRI_MS) && !gecerli[2] && !yanlis_baslangic[2]) begin
                    sure2      <= ms;
                    gecerli[2] <= 1'b1;
                end
            end

            if (aktif[3] && basildi[3]) begin
                if (hazirlik)
                    yanlis_baslangic[3] <= 1'b1;
                else if (olcum_aktif && (ms < SURE_SINIRI_MS)
                         && !gecerli[3] && !yanlis_baslangic[3]) begin
                    sure3      <= ms;
                    gecerli[3] <= 1'b1;
                end
            end

            if (olcum_aktif && (ms == SURE_SINIRI_MS))  // ms = 5 SANIYE (5000 MILISANIYE) OLUNCA ZAMAN ASIMI
                zaman_asimi <= aktif & ~gecerli & ~yanlis_baslangic;
        end
    end

    //  Bir oyuncu "cozuldu" sayilir: basti, erken basti ya da sureyi kacirdi.
    wire [3:0] cozulen = gecerli | yanlis_baslangic | zaman_asimi;

    assign tur_hazir = olcum_aktif && ( (ms >= SURE_SINIRI_MS) || ((aktif & ~cozulen) == 4'b0000) );

endmodule