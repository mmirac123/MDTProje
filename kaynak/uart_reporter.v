`timescale 1ns / 1ps
//  uart_reporter - tur raporunu metin olarak uretip uart_tx'e sirayla verir.
//  Yazan:
//
//  ORNEK CIKTI
//     TUR 03
//      P1 0342 ms    PUAN 4
//      P2 0410 ms    PUAN 3
//      P3 FALSESTART PUAN 0
//      P4 TIMEOUT    PUAN 0
//     TOPLAM P1=12 P2=09 P3=04 P4=07
//
//     ==== OYUN BITTI ====
//     KAZANAN P1 (18 PUAN)          <- beraberlikte: BERABERLIK (18 PUAN)
//     BERABER: P1    P3             <- sadece beraberlik varsa basilir
//
//  TASARIM FIKRI - "32 baytlik satir"
//  --------------------------------------------------------------------
//  Her satir TAM 32 bayt (30 karakter + CR + LF). Boylece bayt sayaci
//  adim'in ust bitleri kacinci SATIRDA, alt bitleri satirin kacinci
//  SUTUNUNDA oldugumuzu dogrudan verir - bolme/moduler aritmetik yok:
//
//      satir  = adim[8:5]      satir numarasi
//      sutun = adim[4:0]      satirdaki karakter (0..29, 30=CR, 31=LF)
//
//  Satirlarin sabit iskeleti string sabiti olarak duruyor, sadece
//  degisken karakterler (rakamlar, durum alani) uzerine yaziliyor.
//
//  TURKCE KARAKTER KULLANMA - terminalde bozuk gorunur.

module uart_reporter(
    input  wire        clk, rst,
    input  wire        basla,            // game_fsm'den TEK cevrimlik puls
    input  wire        son_rapor,        // 1 ise kazanan/beraberlik mesaji

    input  wire [4:0]  tur_no,
    input  wire [12:0] sure0, sure1, sure2, sure3,
    input  wire [2:0]  puan0, puan1, puan2, puan3,
    input  wire [6:0]  toplam0, toplam1, toplam2, toplam3,
    input  wire [3:0]  yanlis_baslangic, zaman_asimi, oynayanlar,
    input  wire [1:0]  kazanan,
    input  wire        beraberlik,

    input  wire        tx_mesgul,
    output reg         tx_gonder,
    output reg  [7:0]  tx_veri,
    output reg         bitti
);

    //=======================================================================
    //  1) Adres cozumu
    //=======================================================================
    reg [8:0] adim;      // metindeki kacinci bayttayiz (0..319)
    reg       calisiyor;
    reg [1:0] faz;        // uart_tx ile el sikisma fazi

    wire [3:0] satir  = adim[8:5];
    wire [4:0] sutun = adim[4:0];
    wire [4:0] metin_i     = (sutun > 5'd29) ? 5'd29 : sutun;   // string indeksi
    wire [3:0] durum_i    = sutun - 5'd4;                      // durum alani indeksi

    //  Blok haritasi
    //    0        TUR NN
    //    1..4     oyuncu satirlari
    //    5        TOPLAM satiri
    //    6        bos satir
    //    7        ==== OYUN BITTI ====     (sadece son_rapor)
    //    8        KAZANAN / BERABERLIK     (sadece son_rapor)
    //    9        BERABER: listesi         (sadece son_rapor && beraberlik)
    localparam [8:0] BAYT_TUR_SONU = 9'd224;   // 7 satir  x 32
    localparam [8:0] BAYT_OYUN_SONU       = 9'd288;   // 9 satir  x 32
    localparam [8:0] BAYT_BERABERLIK    = 9'd320;   // 10 satir x 32

    wire [8:0] toplam_bayt = son_rapor ? (beraberlik ? BAYT_BERABERLIK : BAYT_OYUN_SONU)
                                       : BAYT_TUR_SONU;

    //=======================================================================
    //  2) Sabit satir iskeletleri - HEPSI TAM 30 KARAKTER
    //=======================================================================
    wire [239:0] SATIR_TUR = "TUR 00                        ";
    wire [239:0] SATIR_OYUNCU = " P0             PUAN 0        ";
    wire [239:0] SATIR_TOPLAM = "TOPLAM P1=00 P2=00 P3=00 P4=00";
    wire [239:0] SATIR_BOS = "                              ";
    wire [239:0] SATIR_BITTI = "==== OYUN BITTI ====          ";
    wire [239:0] SATIR_KAZANAN = "KAZANAN P0 (00 PUAN)          ";
    wire [239:0] SATIR_BERABERLIK = "BERABERLIK (00 PUAN)          ";
    wire [239:0] SATIR_ESITLER = "BERABER: P1 P2 P3 P4          ";

    //  Oyuncu satirinin durum alani - HEPSI TAM 11 KARAKTER
    wire [87:0] DURUM_YOK   = "OYNAMIYOR  ";
    wire [87:0] DURUM_ERKEN = "FALSESTART ";
    wire [87:0] DURUM_ZAMAN  = "TIMEOUT    ";
    wire [87:0] DURUM_ELENDI  = "ELENDI     ";

    //=======================================================================
    //  3) O anki oyuncunun bilgileri (satir 1..4 -> oyuncu 0..3)
    //=======================================================================
    reg [12:0] bu_sure;
    reg [2:0]  bu_puan;
    reg        bu_yanlis, bu_zaman, bu_var;

    always @(*) begin
        case (satir)
            4'd1: begin bu_sure=sure0; bu_puan=puan0; bu_yanlis=yanlis_baslangic[0];
                        bu_zaman=zaman_asimi[0]; bu_var=oynayanlar[0]; end
            4'd2: begin bu_sure=sure1; bu_puan=puan1; bu_yanlis=yanlis_baslangic[1];
                        bu_zaman=zaman_asimi[1]; bu_var=oynayanlar[1]; end
            4'd3: begin bu_sure=sure2; bu_puan=puan2; bu_yanlis=yanlis_baslangic[2];
                        bu_zaman=zaman_asimi[2]; bu_var=oynayanlar[2]; end
            default: begin bu_sure=sure3; bu_puan=puan3; bu_yanlis=yanlis_baslangic[3];
                        bu_zaman=zaman_asimi[3]; bu_var=oynayanlar[3]; end
        endcase
    end

    //  Kazananin toplami (KAZANAN/BERABERLIK satirinda basilir)
    reg [6:0] kazanan_toplam;
    always @(*) begin
        case (kazanan)
            2'd0:    kazanan_toplam = toplam0;
            2'd1:    kazanan_toplam = toplam1;
            2'd2:    kazanan_toplam = toplam2;
            default: kazanan_toplam = toplam3;
        endcase
    end

    //  Tepe puani paylasanlar (BERABER: satiri icin)
    wire [3:0] lider = { oynayanlar[3] && (toplam3 == kazanan_toplam),
                        oynayanlar[2] && (toplam2 == kazanan_toplam),
                        oynayanlar[1] && (toplam1 == kazanan_toplam),
                        oynayanlar[0] && (toplam0 == kazanan_toplam) };

    //=======================================================================
    //  4) Tek bin2bcd - girisi hangi satirda oldugumuza gore secilir.
    //     Kombinasyonel oldugu icin tek ornek butun sayilara yetiyor.
    //=======================================================================
    reg  [12:0] bcd_giris;
    wire [15:0] bcd_cikis;

    bin2bcd u_bcd (.ikili(bcd_giris), .bcd(bcd_cikis));

    always @(*) begin
        case (satir)
            4'd0: bcd_giris = {8'd0, tur_no};                    // TUR NN
            4'd1, 4'd2, 4'd3, 4'd4: bcd_giris = bu_sure;          // NNNN ms
            4'd5: bcd_giris = (sutun < 5'd12) ? {6'd0, toplam0} : // TOPLAM ...
                              (sutun < 5'd18) ? {6'd0, toplam1} :
                              (sutun < 5'd24) ? {6'd0, toplam2} :
                                                {6'd0, toplam3};
            4'd8: bcd_giris = {6'd0, kazanan_toplam};                // (NN PUAN)
            default: bcd_giris = 13'd0;
        endcase
    end

    //=======================================================================
    //  5) adim -> bayt cevrimi (tamamen kombinasyonel)
    //=======================================================================
    reg [7:0] bayt;

    always @(*) begin
        bayt = 8'h20;                                   // varsayilan: bosluk

        case (satir)

        //  ---- TUR NN ----
        4'd0: begin
            bayt = SATIR_TUR[8*(29-metin_i) +: 8];
            if (sutun == 5'd4) bayt = 8'h30 + bcd_cikis[7:4];
            if (sutun == 5'd5) bayt = 8'h30 + bcd_cikis[3:0];
        end

        //  ---- oyuncu satirlari ----
        //  " Pn " + 11 karakterlik durum alani + " PUAN p"
        4'd1, 4'd2, 4'd3, 4'd4: begin
            bayt = SATIR_OYUNCU[8*(29-metin_i) +: 8];

            if (sutun == 5'd2) bayt = 8'h30 + {4'd0, satir};      // P1..P4

            if ((sutun >= 5'd4) && (sutun <= 5'd14)) begin
                if (!bu_var)                                      // oyunda degil
                    bayt = DURUM_YOK[8*(10-durum_i) +: 8];
                else if (bu_yanlis)                               // erken basti
                    bayt = DURUM_ERKEN[8*(10-durum_i) +: 8];
                else if (bu_zaman)                                // hic basmadi
                    bayt = DURUM_ZAMAN[8*(10-durum_i) +: 8];
                else if (bu_puan == 3'd0)                         // eleme ile dustu
                    bayt = DURUM_ELENDI[8*(10-durum_i) +: 8];
                else begin                                       // NNNN ms
                    case (durum_i)
                        4'd0:    bayt = 8'h30 + bcd_cikis[15:12];
                        4'd1:    bayt = 8'h30 + bcd_cikis[11:8];
                        4'd2:    bayt = 8'h30 + bcd_cikis[7:4];
                        4'd3:    bayt = 8'h30 + bcd_cikis[3:0];
                        4'd5:    bayt = "m";
                        4'd6:    bayt = "s";
                        default: bayt = " ";
                    endcase
                end
            end

            if (sutun == 5'd21) bayt = 8'h30 + {5'd0, bu_puan};
        end

        //  ---- TOPLAM P1=NN P2=NN P3=NN P4=NN ----
        4'd5: begin
            bayt = SATIR_TOPLAM[8*(29-metin_i) +: 8];
            if ((sutun == 5'd10) || (sutun == 5'd16) ||
                (sutun == 5'd22) || (sutun == 5'd28))
                bayt = 8'h30 + bcd_cikis[7:4];
            if ((sutun == 5'd11) || (sutun == 5'd17) ||
                (sutun == 5'd23) || (sutun == 5'd29))
                bayt = 8'h30 + bcd_cikis[3:0];
        end

        //  ---- bos satir ----
        4'd6: bayt = SATIR_BOS[8*(29-metin_i) +: 8];

        //  ---- ==== OYUN BITTI ==== ----
        4'd7: bayt = SATIR_BITTI[8*(29-metin_i) +: 8];

        //  ---- KAZANAN Pn (NN PUAN) / BERABERLIK (NN PUAN) ----
        4'd8: begin
            bayt = beraberlik ? SATIR_BERABERLIK[8*(29-metin_i) +: 8] : SATIR_KAZANAN[8*(29-metin_i) +: 8];
            if (!beraberlik && (sutun == 5'd9))
                bayt = 8'h31 + {6'd0, kazanan};       // '1'..'4'
            if (sutun == 5'd12) bayt = 8'h30 + bcd_cikis[7:4];
            if (sutun == 5'd13) bayt = 8'h30 + bcd_cikis[3:0];
        end

        //  ---- BERABER: P1 P3 ... (berabere kalmayanlarin yeri bos) ----
        4'd9: begin
            bayt = SATIR_ESITLER[8*(29-metin_i) +: 8];
            if ((sutun == 5'd9)  || (sutun == 5'd10)) bayt = lider[0] ? bayt : " ";
            if ((sutun == 5'd12) || (sutun == 5'd13)) bayt = lider[1] ? bayt : " ";
            if ((sutun == 5'd15) || (sutun == 5'd16)) bayt = lider[2] ? bayt : " ";
            if ((sutun == 5'd18) || (sutun == 5'd19)) bayt = lider[3] ? bayt : " ";
        end

        default: bayt = 8'h20;

        endcase

        //  Her satirin sonu: CR + LF  (K10 -> \r\n)
        if (sutun == 5'd30) bayt = 8'h0D;
        if (sutun == 5'd31) bayt = 8'h0A;
    end

    //=======================================================================
    //  6) Sira makinesi - bayt bayt uart_tx'e ver
    //
    //     faz 0 : OTURMA cevrimi bekle, sonra hat bosalinca bayti ver
    //     faz 1 : gonder pulsu tek cevrim kaldi, indir
    //     faz 2 : uart_tx isi aldi mi (mesgul yukseldi mi) bekle
    //     faz 3 : bayt bitti mi (mesgul dustu mu) bekle -> siradaki bayt
    //
    //     Bu dort faz "mesgul daha yukselmeden ikinci kez gonder basmak"
    //     yarisini tamamen ortadan kaldirir.
    //
    //  NEDEN "OTURMA" SAYACI VAR - ZAMANLAMA
    //     bayt'i ureten yol uzun: toplam/sure yazmaci -> bin2bcd'nin 13
    //     kademeli double-dabble zinciri -> 30 sutunluk metin secici -> tx_veri.
    //     Bu yol 100 MHz'de tek cevrime SIGMAZ (~16 ns). Sigmasi da gerekmiyor:
    //     bir bayt 9600 baud'da ~104 000 cevrim surdugu icin tx_veri pratikte
    //     saatte bir degil, on binlerce cevrimde bir yukleniyor.
    //     adim degistikten sonra burada OTURMA kadar cevrim bekliyoruz; bu
    //     sure boyunca bayt'in tum girisleri sabit. Basys3_Refleks.xdc icindeki
    //     set_multicycle_path kisiti Vivado'ya bu gercegi soyluyor.
    //     Maliyeti: bayt basina 16 cevrim = 160 ns. Bir baytin sure suresi
    //     104 us oldugu icin fark edilmez.
    //=======================================================================
    localparam [4:0] OTURMA = 5'd16;

    reg [4:0] otur;

    always @(posedge clk) begin
        if (rst) begin
            adim      <= 9'd0;
            calisiyor <= 1'b0;
            faz        <= 2'd0;
            otur      <= 5'd0;
            tx_gonder <= 1'b0;
            tx_veri   <= 8'd0;
            bitti     <= 1'b0;
        end else begin
            tx_gonder <= 1'b0;

            if (basla) begin
                adim      <= 9'd0;
                calisiyor <= 1'b1;
                faz        <= 2'd0;
                otur      <= 5'd0;
                bitti     <= 1'b0;
            end else if (calisiyor) begin
                case (faz)
                    2'd0: if (otur != OTURMA) begin
                              otur <= otur + 5'd1;      // bayt otursun
                          end else if (!tx_mesgul) begin
                              tx_veri   <= bayt;
                              tx_gonder <= 1'b1;
                              faz        <= 2'd1;
                          end
                    2'd1: faz <= 2'd2;
                    2'd2: if (tx_mesgul) faz <= 2'd3;
                    default: if (!tx_mesgul) begin
                                 if (adim + 9'd1 == toplam_bayt) begin
                                     calisiyor <= 1'b0;
                                     bitti     <= 1'b1;
                                 end else begin
                                     adim <= adim + 9'd1;
                                 end
                                 otur <= 5'd0;          // yeni bayt, yeniden otur
                                 faz   <= 2'd0;
                             end
                endcase
            end
        end
    end

endmodule
