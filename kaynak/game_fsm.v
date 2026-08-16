`timescale 1ns / 1ps
//  game_fsm - OYUNUN BEYNI.  Yazan:
//  TEK KISI YAZSIN. Ikiye bolunurse iki kisi birbirinin durumunu bozar.
//
//  Bu modul karar verir, digerleri hesaplar. Disariya yaydigi UC ana
//  sinyalden butun oyun kurallari cikar:
//     silahli : basmak yasak (SEQ + ALL_ON)   -> basan false start
//     t0      : blackout ani, kronometre basla
//     pencere : basmak serbest (5 sn)         -> basmayan timeout

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

    localparam S_CONFIG   = 3'd0,
               S_ARM      = 3'd1,
               S_SEQ      = 3'd2,
               S_ALL_ON   = 3'd3,
               S_BLACKOUT = 3'd4,
               S_RESULT   = 3'd5,
               S_NEXT     = 3'd6,
               S_OVER     = 3'd7;

    reg [2:0]  durum;
    reg [12:0] zaman;          // ms sayaci (animasyon / bekleme)
    reg [12:0] hedef;          // BTNC aninda orneklenen bekleme_ms
    reg [1:0]  adim;           // SEQ icindeki basamak adimi

    //-----------------------------------------------------------------------
    //  Durum tablosu (YAZILACAK)
    //-----------------------------------------------------------------------
    //  S_CONFIG   : sw'leri oku. btnc_puls -> ayarlari LATCH'le, S_ARM
    //  S_ARM      : ekran kapali. btnc_puls -> lfsr_deger'i ornekle,
    //               hedef <= bekleme_ms, S_SEQ
    //  S_SEQ      : basamak_en 0001->0011->0111->1111, her adim 400 ms.
    //               silahli = 1. 4 adim bitince S_ALL_ON
    //  S_ALL_ON   : basamak_en = 1111, silahli = 1.
    //               zaman == hedef -> t0 pulsu ver, S_BLACKOUT
    //  S_BLACKOUT : basamak_en = 0000, pencere = 1.
    //               tur_hazir -> tur_sonu pulsu, uart_basla, S_RESULT
    //  S_RESULT   : rapor_bitti bekle. Son tur mu / eleme ile tek kisi mi
    //               kaldi -> S_OVER, degilse S_NEXT
    //  S_NEXT     : btnc_puls -> tur_no++, S_ARM
    //  S_OVER     : oyun_bitti = 1, uart_son_rapor. Sadece rst cikarir.
    //
    //  ERKEN BITIS: eleme_modu && (yasayan icinde tek 1 varsa) -> S_OVER
    always @(posedge clk) begin

    end

    //-----------------------------------------------------------------------
    //  Gosterilecek rakamlar (YAZILACAK)
    //    tur 1 -> 1 2 3 4     tur 2 -> 5 6 7 8     tur 3 -> 1 2 3 4 ...
    //    Ipucu: taban = tur_no[0] ? 5 : 1 ; d0=taban, d1=taban+1, ...
    //-----------------------------------------------------------------------
    assign d0 = 4'd0;   // <-- degistir
    assign d1 = 4'd0;
    assign d2 = 4'd0;
    assign d3 = 4'd0;

endmodule
