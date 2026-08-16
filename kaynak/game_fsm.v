`timescale 1ns / 1ps
//  game_fsm - OYUNUN BEYNI.  Yazan:
//  TEK KISI YAZSIN. Ikiye bolunurse iki kisi birbirinin durumunu bozar.
//
//  Bu modul karar verir, digerleri hesaplar. Disariya yaydigi UC ana
//  sinyalden butun oyun kurallari cikar:
//     silahli : basmak yasak (SEQ + ALL_ON)   -> basan false start
//     t0      : blackout ani, kronometre basla
//     pencere : basmak serbest (5 sn)         -> basmayan timeout
//
//  ZAMAN CIZGISI
//    BTNC                                                          BTNC
//     v                                                             v
//     |-- SEQ ------------|-- ALL_ON ------|-- BLACKOUT ---|-RESULT-|
//     | 1 -> 12 -> 123 -> 1234 (4 x 400ms) | ekran KAPALI  | puan   |
//     |<--------- silahli = 1 ------------>|<- pencere=1 ->| +UART  |
//                                          ^
//                                    REFERANS ANI (t0)
//
//  BTNC SAYISI: tur basina TAM BIR basis. Ilk basis konfigurasyonu dondurup
//  1. turu baslatir (S_CONFIG -> S_SEQ), sonraki her basis bir sonraki turu
//  baslatir (S_NEXT -> S_SEQ). Proje tanimi §2 boyle istiyor.

module game_fsm(
    input  wire        clk, rst, vurus_1ms,

    // --- girisler ---
    input  wire        btnc_puls,
    input  wire [15:0] sw,               // konfigurasyon switch'leri
    input  wire [15:0] lfsr_deger,
    input  wire [12:0] bekleme_ms,       // delay_gen'den
    input  wire        tur_hazir,        // reaction_capture'dan
    input  wire        rapor_bitti,      // uart_reporter'dan
    input  wire [3:0]  yasayan,          // score_accum'dan

    // --- konfigurasyon cikislari (latch'lenmis) ---
    output reg  [3:0]  oyuncu_maske,     // 0011 / 0111 / 1111
    output reg  [4:0]  tur_sayisi,       // 1..16
    output reg         eleme_modu,
    output reg         zor_mod,

    // --- ekran kontrolu ---
    output reg  [3:0]  basamak_en,       // hangi basamak yanik
    output wire [3:0]  d0, d1, d2, d3,   // gosterilecek rakamlar

    // --- oyun akisi ---
    output reg         silahli,
    output reg         pencere,
    output reg         t0,               // TEK cevrimlik puls
    output reg  [4:0]  tur_no,
    output reg         tur_sonu,         // TEK cevrimlik puls
    output reg         oyun_bitti,
    output reg         uart_basla,
    output reg         uart_son_rapor
);

    //  NOT: 3'd1 bilerek bos birakildi. Eskiden burada S_ARM vardi (BTNC'yi
    //  ikinci kez bekleyen ara durum); proje tanimi tek basis istedigi icin
    //  kaldirildi. Kalan durumlarin kodlarini degistirmedik ki dalga
    //  formlarinda ve eski notlarda ayni numaralar gecerli kalsin.
    localparam S_CONFIG   = 3'd0,
               S_SEQ      = 3'd2,
               S_ALL_ON   = 3'd3,
               S_BLACKOUT = 3'd4,
               S_RESULT   = 3'd5,
               S_NEXT     = 3'd6,
               S_OVER     = 3'd7;

    localparam [12:0] SEQ_MS = 13'd400;      // her animasyon adimi 400 ms (K4)

    //  Son turda, kazanan gosterimine gecmeden once son turun siralama
    //  LED'lerini bu kadar ms ekranda tut. Ara turlarda gerek yok, orada
    //  zaten S_NEXT'te BTNC bekleniyor. BTNC ile erken atlanabilir.
    localparam [12:0] SON_GOSTERIM_MS = 13'd3000;

    reg [2:0]  durum;
    reg [12:0] zaman;          // ms sayaci (animasyon / bekleme)
    reg [12:0] hedef;          // BTNC aninda orneklenen bekleme_ms
    reg [1:0]  adim;           // SEQ icindeki basamak adimi
    reg [2:0]  rapor_fz;       // S_RESULT icindeki faz sayaci

    //-----------------------------------------------------------------------
    //  Oyun sonu kosullari
    //  kalan : hem oyuna dahil hem elenmemis oyuncular
    //-----------------------------------------------------------------------
    wire [3:0] kalan   = yasayan & oyuncu_maske;
    wire [2:0] kalan_n = {2'd0, kalan[0]} + {2'd0, kalan[1]} +
                         {2'd0, kalan[2]} + {2'd0, kalan[3]};

    wire son_tur   = (tur_no >= tur_sayisi);
    wire tek_kisi  = eleme_modu && (kalan_n <= 3'd1);   // erken bitis
    wire oyun_sonu = son_tur || tek_kisi;

    //-----------------------------------------------------------------------
    //  Konfigurasyon cozumu (S_CONFIG'de canli izlenir, BTNC ile donar)
    //-----------------------------------------------------------------------
    wire [3:0] sw_maske = (sw[12:11] == 2'b00) ? 4'b0011 :
                          (sw[12:11] == 2'b01) ? 4'b0111 : 4'b1111;
    wire [4:0] sw_tur   = {1'b0, sw[3:0]} + 5'd1;       // 0000->1 , 1111->16

    //-----------------------------------------------------------------------
    //  ANA DURUM MAKINESI
    //-----------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            durum          <= S_CONFIG;
            zaman          <= 13'd0;
            hedef          <= 13'd0;
            adim           <= 2'd0;
            rapor_fz       <= 3'd0;
            oyuncu_maske   <= 4'b0011;
            tur_sayisi     <= 5'd1;
            eleme_modu     <= 1'b0;
            zor_mod        <= 1'b0;
            tur_no         <= 5'd1;
            basamak_en     <= 4'b0000;
            silahli        <= 1'b0;
            pencere        <= 1'b0;
            t0             <= 1'b0;
            tur_sonu       <= 1'b0;
            oyun_bitti     <= 1'b0;
            uart_basla     <= 1'b0;
            uart_son_rapor <= 1'b0;
        end else begin
            //  Pulsler varsayilan olarak 0; ilgili durumda 1 cevrim yukselir
            t0         <= 1'b0;
            tur_sonu   <= 1'b0;
            uart_basla <= 1'b0;

            case (durum)

            //---------------------------------------------------------------
            //  S_CONFIG : switch'leri oku, ekranda ayarlari goster.
            //             BTNC -> ayarlar donar VE 1. tur DOGRUDAN baslar.
            //  Ekran: d3 = oyuncu sayisi , d1 d0 = tur sayisi (K6)
            //
            //  TEK BASIS: proje tanimi §2 "BTNC'ye basildiginda ayarlar
            //  kaydedilmeli VE oyun baslamalidir" diyor. Bu yuzden ayri bir
            //  bekleme durumu (eski S_ARM) yok; ayni basista hem konfigurasyon
            //  donar hem SEQ animasyonu baslar. Boylece her tur icin tam bir
            //  BTNC basisi dusuyor: 1. basis 1. turu, N. basis N. turu baslatir.
            //
            //  LFSR tam bu anda orneklenir (proje tanimi §4: "her turda, BTNC
            //  ile tur baslatildigi anda LFSR degeri okunmalidir").
            //---------------------------------------------------------------
            S_CONFIG: begin
                basamak_en   <= 4'b1011;
                silahli      <= 1'b0;
                pencere      <= 1'b0;
                oyun_bitti   <= 1'b0;
                zaman        <= 13'd0;
                adim         <= 2'd0;
                tur_no       <= 5'd1;

                oyuncu_maske <= sw_maske;
                tur_sayisi   <= sw_tur;
                eleme_modu   <= sw[14];
                zor_mod      <= sw[13];

                if (btnc_puls) begin
                    hedef      <= bekleme_ms;   // delay_gen(lfsr_deger) anlik
                    basamak_en <= 4'b0001;      // ilk basamak
                    silahli    <= 1'b1;         // buradan itibaren basmak yasak
                    durum      <= S_SEQ;
                end
            end

            //---------------------------------------------------------------
            //  S_SEQ : basamaklar birikerek yanar (K5)
            //          0001 -> 0011 -> 0111 -> 1111 , her adim 400 ms
            //---------------------------------------------------------------
            S_SEQ: begin
                silahli <= 1'b1;
                if (vurus_1ms) begin
                    if (zaman == SEQ_MS - 13'd1) begin
                        zaman <= 13'd0;
                        if (adim == 2'd3) begin
                            basamak_en <= 4'b1111;
                            durum      <= S_ALL_ON;
                        end else begin
                            adim       <= adim + 2'd1;
                            basamak_en <= {basamak_en[2:0], 1'b1};
                        end
                    end else begin
                        zaman <= zaman + 13'd1;
                    end
                end
            end

            //---------------------------------------------------------------
            //  S_ALL_ON : dort basamak da yanik, rastgele sure bekleniyor.
            //             Sure dolunca HEPSI AYNI ANDA soner -> t0
            //---------------------------------------------------------------
            S_ALL_ON: begin
                basamak_en <= 4'b1111;
                silahli    <= 1'b1;
                if (vurus_1ms) begin
                    if (zaman >= hedef) begin
                        zaman      <= 13'd0;
                        basamak_en <= 4'b0000;   // blackout
                        silahli    <= 1'b0;
                        pencere    <= 1'b1;
                        t0         <= 1'b1;      // REFERANS ANI
                        durum      <= S_BLACKOUT;
                    end else begin
                        zaman <= zaman + 13'd1;
                    end
                end
            end

            //---------------------------------------------------------------
            //  S_BLACKOUT : 5 sn'lik basma penceresi.
            //               reaction_capture "tur_hazir" deyince biter.
            //---------------------------------------------------------------
            S_BLACKOUT: begin
                basamak_en <= 4'b0000;
                silahli    <= 1'b0;
                pencere    <= 1'b1;
                if (tur_hazir) begin
                    pencere  <= 1'b0;
                    tur_sonu <= 1'b1;        // score_accum bu pulsu bekliyor
                    rapor_fz <= 3'd0;
                    durum    <= S_RESULT;
                end
            end

            //---------------------------------------------------------------
            //  S_RESULT : puanlar islensin, rapor gonderilsin, bitmesini bekle
            //
            //  Faz 0 : score_accum tur_sonu'yu bu kenarda isliyor
            //  Faz 1 : yasayan ARTIK guncel -> son rapor mu karar ver, UART'i baslat
            //  Faz 2 : uart_basla yuksek; reporter bu kenarda yakalar ve bitti'yi dusurur
            //  Faz 3 : raporun bitmesini bekle
            //  Faz 4 : SADECE son turda - siralama LED'leri 3 sn ekranda kalsin,
            //          sonra S_OVER'daki kazanan gosterimine gec (BTNC atlar)
            //---------------------------------------------------------------
            S_RESULT: begin
                basamak_en <= 4'b0000;
                silahli    <= 1'b0;
                pencere    <= 1'b0;
                case (rapor_fz)
                    3'd0: rapor_fz <= 3'd1;
                    3'd1: begin
                        uart_basla     <= 1'b1;
                        uart_son_rapor <= oyun_sonu;
                        rapor_fz       <= 3'd2;
                    end
                    3'd2: rapor_fz <= 3'd3;
                    3'd3: if (rapor_bitti) begin
                        if (oyun_sonu) begin
                            //  Son tur: once bu turun siralamasi gorunsun,
                            //  sonra kazanan gosterimine gec (faz 4)
                            zaman    <= 13'd0;
                            rapor_fz <= 3'd4;
                        end else begin
                            durum <= S_NEXT;
                        end
                    end
                    default: begin
                        //  Faz 4 - son turun LED'leri ekranda dursun
                        if (btnc_puls) begin
                            durum <= S_OVER;            // sabirsizsan atla
                        end else if (vurus_1ms) begin
                            if (zaman >= SON_GOSTERIM_MS) durum <= S_OVER;
                            else                          zaman <= zaman + 13'd1;
                        end
                    end
                endcase
            end

            //---------------------------------------------------------------
            //  S_NEXT : ekran kapali, LED'ler tur sonucunu gosteriyor.
            //           BTNC -> tur numarasi artar ve sonraki tur DOGRUDAN
            //           baslar (oyuncu tur basina tek kez BTNC'ye basar;
            //           ilk BTNC ayarlari kaydeder, ikincisi 1. turu baslatir).
            //---------------------------------------------------------------
            S_NEXT: begin
                basamak_en <= 4'b0000;
                silahli    <= 1'b0;
                pencere    <= 1'b0;
                zaman      <= 13'd0;
                adim       <= 2'd0;
                if (btnc_puls) begin
                    tur_no     <= tur_no + 5'd1;
                    hedef      <= bekleme_ms;   // LFSR bu anda orneklenir
                    basamak_en <= 4'b0001;
                    silahli    <= 1'b1;
                    durum      <= S_SEQ;
                end
            end

            //---------------------------------------------------------------
            //  S_OVER : oyun bitti. LED'ler genel kazanani gosterir,
            //           ekran sondurulur (K12). Sadece rst cikarir.
            //---------------------------------------------------------------
            S_OVER: begin
                oyun_bitti <= 1'b1;
                basamak_en <= 4'b0000;
                silahli    <= 1'b0;
                pencere    <= 1'b0;
            end

            //  Kullanilmayan 3'd1 kodu: erisilemez, ama tek bir bozulmus bit
            //  makineyi orada kilitlemesin diye konfigurasyona geri donuyoruz.
            default: durum <= S_CONFIG;

            endcase
        end
    end

    //-----------------------------------------------------------------------
    //  Gosterilecek rakamlar
    //    tur 1 -> 1 2 3 4     tur 2 -> 5 6 7 8     tur 3 -> 1 2 3 4 ...
    //    (tek turlarda taban 1, cift turlarda taban 5)
    //    d0 en SAGDAKI basamak (an[0]); animasyon sagdan sola ilerler.
    //  S_CONFIG'de bunun yerine ayarlar gosterilir:
    //    d3 = oyuncu sayisi , d1-d0 = tur sayisi (ornek: 4 _ 1 6)
    //-----------------------------------------------------------------------
    wire [3:0] taban  = tur_no[0] ? 4'd1 : 4'd5;

    wire [3:0] oy_say = oyuncu_maske[3] ? 4'd4 :
                        oyuncu_maske[2] ? 4'd3 : 4'd2;

    wire       on_var = (tur_sayisi >= 5'd10);
    wire [4:0] t_bir5 = on_var ? (tur_sayisi - 5'd10) : tur_sayisi;

    assign d0 = (durum == S_CONFIG) ? t_bir5[3:0]        : taban;
    assign d1 = (durum == S_CONFIG) ? (on_var ? 4'd1 : 4'd0) : (taban + 4'd1);
    assign d2 = (durum == S_CONFIG) ? 4'd0               : (taban + 4'd2);
    assign d3 = (durum == S_CONFIG) ? oy_say             : (taban + 4'd3);

endmodule
