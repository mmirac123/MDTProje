`timescale 1ns / 1ps
//  uart_reporter - tur sonucunu duz metin haline cevirip uart_tx'e bayt bayt yolluyor.
//  yazan:
//
//  cikti soyle gorunuyor mesela:
//     TUR 03
//      P1 0342 ms    PUAN 4
//      P2 0410 ms    PUAN 3
//      P3 FALSESTART PUAN 0
//      P4 TIMEOUT    PUAN 0
//     TOPLAM P1=12 P2=09 P3=04 P4=07
//
//     ==== OYUN BITTI ====
//     KAZANAN P1 (18 PUAN)          <- beraberlikte: BERABERLIK (18 PUAN)
//     BERABER: P1    P3             <- beraberlik yoksa bu satir hic yazilmiyor
//
//  fikir: "32 baytlik satir"
//  --------------------------------------------------------------------
//  once bolme ile ugrasip durdum (adim/32, adim%32) ama gereksizmis.
//  her satiri tam 32 bayt yaptim (30 karakter + cr + lf), 32 = 2^5
//  oldugu icin sayacin bitlerini ikiye bolmek yetiyor, bolme/mod yok:
//
//      blok  = adim[8:5]      kacinci satirdayiz
//      sutun = adim[4:0]      satirin kacinci karakteri (0..29, 30=cr, 31=lf)
//
//  satirlarin degismeyen kismi asagida string sabiti olarak duruyor,
//  biz sadece degisen yerleri (rakamlar, durum yazisi) ustune yaziyoruz.
//
//  not: turkce karakter (ı, ş, ğ...) kullanma, terminalde cop cikiyor.

module uart_reporter(
    input  wire        clk, rst,
    input  wire        basla,            // game_fsm tek cevrimlik puls atiyor
    input  wire        son_rapor,        // 1 ise kazanan/beraberlik mesaji basiliyor

    input  wire [4:0]  tur_no,
    input  wire [12:0] sure0, sure1, sure2, sure3,
    input  wire [2:0]  puan0, puan1, puan2, puan3,
    input  wire [6:0]  toplam0, toplam1, toplam2, toplam3,
    input  wire [3:0]  yanlis_baslangic, zaman_asimi, oyuncu_maske,
    input  wire [1:0]  kazanan,
    input  wire        beraberlik,

    input  wire        tx_mesgul,
    output reg         tx_gonder,
    output reg  [7:0]  tx_veri,
    output reg         bitti
);

    //=======================================================================
    //  1) adres cozumu
    //=======================================================================
    reg [8:0] adim;      // metinde kacinci bayttayiz (0..319 arasi)
    reg       calisiyor;
    reg [1:0] fz;        // uart_tx ile el sikisma fazi (asagida 6. bolumde anlatiyorum)

    wire [3:0] blok  = adim[8:5];
    wire [4:0] sutun = adim[4:0];
    wire [4:0] s     = (sutun > 5'd29) ? 5'd29 : sutun;   // string indeksine cevir
    wire [3:0] df    = sutun - 5'd4;                      // durum alani icin yerel indeks

    //  hangi blok hangi satir - kafam karismasin diye not aliyorum:
    //    0        TUR NN
    //    1..4     oyuncu satirlari
    //    5        TOPLAM satiri
    //    6        bos satir (araya nefes payi)
    //    7        ==== OYUN BITTI ====     (sadece son_rapor'da)
    //    8        KAZANAN / BERABERLIK     (sadece son_rapor'da)
    //    9        BERABER: listesi         (sadece son_rapor ve beraberlik varsa)
    localparam [8:0] SON_TUR_RAPORU = 9'd224;   // 7 satir  x 32 bayt
    localparam [8:0] SON_OYUN       = 9'd288;   // 9 satir  x 32 bayt
    localparam [8:0] SON_BERABER    = 9'd320;   // 10 satir x 32 bayt

    wire [8:0] toplam_bayt = son_rapor ? (beraberlik ? SON_BERABER : SON_OYUN)
                                       : SON_TUR_RAPORU;

    //=======================================================================
    //  2) sabit satir kaliplari - dikkat, hepsi tam 30 karakter olmak zorunda
    //     (bir eksik/fazla bosluk birakirsan tum sutun indeksleri kayar)
    //=======================================================================
    wire [239:0] L_TUR = "TUR 00                        ";
    wire [239:0] L_OYU = " P0             PUAN 0        ";
    wire [239:0] L_TOP = "TOPLAM P1=00 P2=00 P3=00 P4=00";
    wire [239:0] L_BOS = "                              ";
    wire [239:0] L_BIT = "==== OYUN BITTI ====          ";
    wire [239:0] L_KAZ = "KAZANAN P0 (00 PUAN)          ";
    wire [239:0] L_BER = "BERABERLIK (00 PUAN)          ";
    wire [239:0] L_ESI = "BERABER: P1 P2 P3 P4          ";

    //  oyuncu satirindaki durum yazisi - bunlar da tam 11 karakter olmali
    wire [87:0] S_YOK   = "OYNAMIYOR  ";
    wire [87:0] S_FALSE = "FALSESTART ";
    wire [87:0] S_TIME  = "TIMEOUT    ";
    wire [87:0] S_ELEN  = "ELENDI     ";

    //=======================================================================
    //  3) o an hangi oyuncudaysak onun bilgilerini tek yere topla
    //     (blok 1..4 -> oyuncu 0..3, boylece asagida 4 kere ayni kodu
    //     yazmak zorunda kalmiyorum)
    //=======================================================================
    reg [12:0] o_sure;
    reg [2:0]  o_puan;
    reg        o_yanlis, o_zaman, o_var;

    always @(*) begin
        case (blok)
            4'd1: begin o_sure=sure0; o_puan=puan0; o_yanlis=yanlis_baslangic[0];
                        o_zaman=zaman_asimi[0]; o_var=oyuncu_maske[0]; end
            4'd2: begin o_sure=sure1; o_puan=puan1; o_yanlis=yanlis_baslangic[1];
                        o_zaman=zaman_asimi[1]; o_var=oyuncu_maske[1]; end
            4'd3: begin o_sure=sure2; o_puan=puan2; o_yanlis=yanlis_baslangic[2];
                        o_zaman=zaman_asimi[2]; o_var=oyuncu_maske[2]; end
            default: begin o_sure=sure3; o_puan=puan3; o_yanlis=yanlis_baslangic[3];
                        o_zaman=zaman_asimi[3]; o_var=oyuncu_maske[3]; end
        endcase
    end

    //  kazananin toplam puani (kazanan/beraberlik satirinda lazim oluyor)
    reg [6:0] kaz_toplam;
    always @(*) begin
        case (kazanan)
            2'd0:    kaz_toplam = toplam0;
            2'd1:    kaz_toplam = toplam1;
            2'd2:    kaz_toplam = toplam2;
            default: kaz_toplam = toplam3;
        endcase
    end

    //  kim kimle berabere kalmis - beraber: satirinda kimin adini basacagimizi
    //  buradan anliyoruz. toplami en yuksek puana esit olan herkes beraberdir.
    wire [3:0] esit = { oyuncu_maske[3] && (toplam3 == kaz_toplam),
                        oyuncu_maske[2] && (toplam2 == kaz_toplam),
                        oyuncu_maske[1] && (toplam1 == kaz_toplam),
                        oyuncu_maske[0] && (toplam0 == kaz_toplam) };

    //=======================================================================
    //  4) bin2bcd'yi tek yerde kullaniyorum, hersey icin ayri ayri koymadim.
    //     kombinasyonel oldugu icin (saat beklemiyor) hangi sayiyi
    //     cevirecegini her cevrimde degistirebiliyorum, sikinti cikmiyor.
    //=======================================================================
    reg  [12:0] bcd_giris;
    wire [15:0] bcd_cikis;

    bin2bcd u_bcd (.ikili(bcd_giris), .bcd(bcd_cikis));

    always @(*) begin
        case (blok)
            4'd0: bcd_giris = {8'd0, tur_no};                    // TUR NN
            4'd1, 4'd2, 4'd3, 4'd4: bcd_giris = o_sure;          // NNNN ms
            4'd5: bcd_giris = (sutun < 5'd12) ? {6'd0, toplam0} : // TOPLAM ...
                              (sutun < 5'd18) ? {6'd0, toplam1} :
                              (sutun < 5'd24) ? {6'd0, toplam2} :
                                                {6'd0, toplam3};
            4'd8: bcd_giris = {6'd0, kaz_toplam};                // (NN PUAN)
            default: bcd_giris = 13'd0;
        endcase
    end

    //=======================================================================
    //  5) adim -> bayt: asil isin yapildigi yer, tamamen kombinasyonel
    //=======================================================================
    reg [7:0] bayt;

    always @(*) begin
        bayt = 8'h20;                                   // varsayilan bosluk birakiyorum

        case (blok)

        //  ---- TUR NN ----
        4'd0: begin
            bayt = L_TUR[8*(29-s) +: 8];
            if (sutun == 5'd4) bayt = 8'h30 + bcd_cikis[7:4];
            if (sutun == 5'd5) bayt = 8'h30 + bcd_cikis[3:0];
        end

        //  ---- oyuncu satirlari ----
        //  " Pn " + 11 karakterlik durum + " PUAN p" seklinde ilerliyor
        4'd1, 4'd2, 4'd3, 4'd4: begin
            bayt = L_OYU[8*(29-s) +: 8];

            if (sutun == 5'd2) bayt = 8'h30 + {4'd0, blok};      // P1..P4 basiyor

            if ((sutun >= 5'd4) && (sutun <= 5'd14)) begin
                if (!o_var)                                      // hic oyunda degilse
                    bayt = S_YOK[8*(10-df) +: 8];
                else if (o_yanlis)                                // erkenden basmis
                    bayt = S_FALSE[8*(10-df) +: 8];
                else if (o_zaman)                                 // hic basmadan suresi dolmus
                    bayt = S_TIME[8*(10-df) +: 8];
                else if (o_puan == 3'd0)                          // elenmis, puani sifirlanmis
                    bayt = S_ELEN[8*(10-df) +: 8];
                else begin                                        // her sey normal, NNNN ms yaz
                    case (df)
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

            if (sutun == 5'd21) bayt = 8'h30 + {5'd0, o_puan};
        end

        //  ---- TOPLAM P1=NN P2=NN P3=NN P4=NN ----
        4'd5: begin
            bayt = L_TOP[8*(29-s) +: 8];
            if ((sutun == 5'd10) || (sutun == 5'd16) ||
                (sutun == 5'd22) || (sutun == 5'd28))
                bayt = 8'h30 + bcd_cikis[7:4];
            if ((sutun == 5'd11) || (sutun == 5'd17) ||
                (sutun == 5'd23) || (sutun == 5'd29))
                bayt = 8'h30 + bcd_cikis[3:0];
        end

        //  ---- bos satir, sadece araya bosluk koyuyor ----
        4'd6: bayt = L_BOS[8*(29-s) +: 8];

        //  ---- ==== OYUN BITTI ==== ----
        4'd7: bayt = L_BIT[8*(29-s) +: 8];

        //  ---- KAZANAN Pn (NN PUAN) ya da beraberlikse BERABERLIK (NN PUAN) ----
        4'd8: begin
            bayt = beraberlik ? L_BER[8*(29-s) +: 8] : L_KAZ[8*(29-s) +: 8];
            if (!beraberlik && (sutun == 5'd9))
                bayt = 8'h31 + {6'd0, kazanan};       // '1'..'4' rakamini basiyor
            if (sutun == 5'd12) bayt = 8'h30 + bcd_cikis[7:4];
            if (sutun == 5'd13) bayt = 8'h30 + bcd_cikis[3:0];
        end

        //  ---- BERABER: P1 P3 gibi, berabere kalmayanin yerini bos birak ----
        4'd9: begin
            bayt = L_ESI[8*(29-s) +: 8];
            if ((sutun == 5'd9)  || (sutun == 5'd10)) bayt = esit[0] ? bayt : " ";
            if ((sutun == 5'd12) || (sutun == 5'd13)) bayt = esit[1] ? bayt : " ";
            if ((sutun == 5'd15) || (sutun == 5'd16)) bayt = esit[2] ? bayt : " ";
            if ((sutun == 5'd18) || (sutun == 5'd19)) bayt = esit[3] ? bayt : " ";
        end

        default: bayt = 8'h20;

        endcase

        //  her satirin sonuna cr+lf ekliyorum, boyle terminalde duzgun alt alta duruyor
        if (sutun == 5'd30) bayt = 8'h0D;
        if (sutun == 5'd31) bayt = 8'h0A;
    end

    //=======================================================================
    //  6) sira makinesi - hazirlanan bayti tek tek uart_tx'e yolla
    //
    //     fz 0 : bayt otursun diye bekle, sonra hat bossa (mesgul degilse) yolla
    //     fz 1 : tx_gonder pulsunu bir cevrim sonra indir
    //     fz 2 : uart_tx isi gercekten aldi mi bekle (mesgul yukselsin)
    //     fz 3 : bayt gonderimi bitti mi bekle (mesgul dussun) -> sonraki bayta gec
    //
    //     bu 4 asamayi boyle ayirmamin sebebi: mesgul daha yukselmeden
    //     ikinci kere gonder basip ayni bayti iki kere yollama hatasina
    //     dusmemek. basimda bunu bulana kadar epey ugrastim.
    //
    //  "OTURMA" sayaci neden var - zamanlama meselesi
    //     bayt sinyaline giden yol epey uzun: sure/toplam yazmaclari ->
    //     bin2bcd'nin 13 kademeli double-dabble zinciri -> 30 sutunluk
    //     buyuk secici -> tx_veri. bu yol 100 mhz'de tek cevrime sigmiyor
    //     (~16 ns surdugunu olctum). ama sigmasi da sart degil: bir bayti
    //     9600 baud'da gondermek zaten ~104.000 cevrim tutuyor, yani
    //     tx_veri saatte bir degil, on binlerce cevrimde bir degisiyor.
    //     adim degistikten sonra burada oturma kadar bekletip sinyallerin
    //     otursun diye pay veriyorum. xdc dosyasindaki set_multicycle_path
    //     satiri da vivado'ya "bu yolda acele etme, uzun surebilir" diyor.
    //     maliyeti: bayt basina 16 cevrim = 160 ns kaybediyoruz, ama bir
    //     baytin gonderimi zaten 104 us surdugu icin hic fark etmiyor.
    //=======================================================================
    localparam [4:0] OTURMA = 5'd16;

    reg [4:0] otur;

    always @(posedge clk) begin
        if (rst) begin
            adim      <= 9'd0;
            calisiyor <= 1'b0;
            fz        <= 2'd0;
            otur      <= 5'd0;
            tx_gonder <= 1'b0;
            tx_veri   <= 8'd0;
            bitti     <= 1'b0;
        end else begin
            tx_gonder <= 1'b0;

            if (basla) begin
                adim      <= 9'd0;
                calisiyor <= 1'b1;
                fz        <= 2'd0;
                otur      <= 5'd0;
                bitti     <= 1'b0;
            end else if (calisiyor) begin
                case (fz)
                    2'd0: if (otur != OTURMA) begin
                              otur <= otur + 5'd1;      // sinyaller otursun diye bekliyoruz
                          end else if (!tx_mesgul) begin
                              tx_veri   <= bayt;
                              tx_gonder <= 1'b1;
                              fz        <= 2'd1;
                          end
                    2'd1: fz <= 2'd2;
                    2'd2: if (tx_mesgul) fz <= 2'd3;
                    default: if (!tx_mesgul) begin
                                 if (adim + 9'd1 == toplam_bayt) begin
                                     calisiyor <= 1'b0;
                                     bitti     <= 1'b1;
                                 end else begin
                                     adim <= adim + 9'd1;
                                 end
                                 otur <= 5'd0;          // yeni bayt basladi, sayaci sifirla
                                 fz   <= 2'd0;
                             end
                endcase
            end
        end
    end

endmodule
