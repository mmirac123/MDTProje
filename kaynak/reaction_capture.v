`timescale 1ns / 1ps
//  reaction_capture - kronometre + hakem.                      Yazan:
//  t0 aninda sayac sifirlanir; her oyuncunun basis ani 1 ms
//  cozunurlukle yakalanir. False start ve timeout karari burada verilir.

module reaction_capture(
    input  wire        clk, rst, vurus_1ms,

    input  wire        t0,          // blackout ani, TEK cevrimlik puls
    input  wire        silahli,     // SEQ + ALL_ON boyunca 1 -> basmak YASAK
    input  wire        pencere,     // BLACKOUT boyunca 1     -> basmak SERBEST
    input  wire [3:0]  basis,       // 4 oyuncunun debounce'lu kenar pulsu
    input  wire [3:0]  aktif,       // oynayan oyuncular (sayi & eleme maskesi)

    output reg  [12:0] sure0, sure1, sure2, sure3,   // ms
    output reg  [3:0]  gecerli,
    output reg  [3:0]  yanlis_baslangic,
    output reg  [3:0]  zaman_asimi,
    output wire        tur_hazir
);

    localparam [12:0] PENCERE_MS = 13'd5000;   // blackout sonrasi 5 sn

    reg [12:0] ms;
    reg        silahli_gec;                    // silahli'nin bir onceki degeri

    //  Turun BASI = silahli'nin yukselen kenari (S_ARM -> S_SEQ gecisi).
    //  Bayraklari BURADA temizliyoruz, t0'da DEGIL: false start silahli
    //  boyunca olusur, t0'da temizlersek blackout'tan once yakalanan
    //  false start'lar silinirdi.
    wire tur_basi = silahli & ~silahli_gec;

    always @(posedge clk) begin
        if (rst) silahli_gec <= 1'b0;
        else     silahli_gec <= silahli;
    end

    always @(posedge clk) begin
        if (rst || tur_basi) begin
            ms               <= 13'd0;
            sure0            <= 13'd0;
            sure1            <= 13'd0;
            sure2            <= 13'd0;
            sure3            <= 13'd0;
            gecerli          <= 4'b0000;
            yanlis_baslangic <= 4'b0000;
            zaman_asimi      <= 4'b0000;
        end else begin
            //---------------------------------------------------------------
            //  1) Kronometre. t0 referans ani -> sifirla.
            //---------------------------------------------------------------
            if (t0)
                ms <= 13'd0;
            else if (pencere && vurus_1ms && (ms < PENCERE_MS))
                ms <= ms + 13'd1;

            //---------------------------------------------------------------
            //  2) Basislar
            //     silahli  -> false start
            //     pencere  -> gecerli olcum (ilk basis; gecerli[i] bayragi
            //                 ikinci basisi zaten engeller, ayri kilit yok)
            //---------------------------------------------------------------
            if (aktif[0] && basis[0]) begin
                if (silahli)
                    yanlis_baslangic[0] <= 1'b1;
                else if (pencere && (ms < PENCERE_MS)
                         && !gecerli[0] && !yanlis_baslangic[0]) begin
                    sure0      <= ms;
                    gecerli[0] <= 1'b1;
                end
            end

            if (aktif[1] && basis[1]) begin
                if (silahli)
                    yanlis_baslangic[1] <= 1'b1;
                else if (pencere && (ms < PENCERE_MS)
                         && !gecerli[1] && !yanlis_baslangic[1]) begin
                    sure1      <= ms;
                    gecerli[1] <= 1'b1;
                end
            end

            if (aktif[2] && basis[2]) begin
                if (silahli)
                    yanlis_baslangic[2] <= 1'b1;
                else if (pencere && (ms < PENCERE_MS)
                         && !gecerli[2] && !yanlis_baslangic[2]) begin
                    sure2      <= ms;
                    gecerli[2] <= 1'b1;
                end
            end

            if (aktif[3] && basis[3]) begin
                if (silahli)
                    yanlis_baslangic[3] <= 1'b1;
                else if (pencere && (ms < PENCERE_MS)
                         && !gecerli[3] && !yanlis_baslangic[3]) begin
                    sure3      <= ms;
                    gecerli[3] <= 1'b1;
                end
            end

            //---------------------------------------------------------------
            //  3) Timeout: 5000 ms doldugunda hala cozulmemis aktif oyuncular
            //---------------------------------------------------------------
            if (pencere && (ms == PENCERE_MS))
                zaman_asimi <= aktif & ~gecerli & ~yanlis_baslangic;
        end
    end

    //  Bir oyuncu "cozuldu" sayilir: basti, erken basti ya da sureyi kacirdi.
    wire [3:0] cozulen = gecerli | yanlis_baslangic | zaman_asimi;

    //  Tur biter: 5000 ms doldu VEYA aktif oyuncularin hepsi cozuldu.
    //  pencere ile kapiliyor ki SEQ sirasinda yanlislikla tetiklenmesin.
    assign tur_hazir = pencere && ( (ms >= PENCERE_MS) ||
                                    ((aktif & ~cozulen) == 4'b0000) );

endmodule
