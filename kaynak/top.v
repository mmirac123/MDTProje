`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
//  BIL 264/265 - Cok Oyunculu Refleks Oyunu / Grup: Nazik Ormanlar
//  top - butun modulleri birbirine ve kart pinlerine baglar. Kendi mantigi yok.
//
//  KAYNAK HARITASI (Basys3_Refleks.xdc ile birebir ayni olmali):
//    SW15        Reset (1 = reset)
//    SW14        Eleme modu (1 = acik)
//    SW13        Zorluk (0 = kolay 2.0-5.0 s, 1 = zor 0.5-5.0 s)
//    SW12,SW11   Oyuncu sayisi: 00->2, 01->3, 10->4, 11->4
//    SW3..SW0    Tur sayisi N -> oynanan tur = N+1  (0000->1 , 1111->16)
//    BTNC        Ayarlari kaydet / turu baslat
//    BTNU/L/R/D  Oyuncu 1 / 2 / 3 / 4
//    LED0-3 / 4-7 / 8-11 / 12-15   Oyuncu 1 / 2 / 3 / 4 siralama gostergesi
//    RsTx (A18)  UART cikisi, 9600 8N1
//
//  OYUN AKISI
//    SW15 = 1 -> reset. SW15 = 0 -> konfigurasyon (ekranda oyuncu ve tur
//    sayisi). BTNC'ye basilinca ayarlar donar VE 1. tur DOGRUDAN baslar;
//    sonraki her BTNC basisi bir sonraki turu baslatir (tur basina tek
//    basis). Tur baslayinca 7-segment
//    basamaklari 400 ms araliklarla birikerek yanar (1 -> 12 -> 123 -> 1234),
//    LFSR'den gelen rastgele sure (kolay 2.0-5.0 s / zor 0.5-5.0 s) kadar
//    yanik kalir ve HEPSI AYNI ANDA soner. Bu an referans anidir (t0).
//    Sonmeden once basan false start, 5 sn icinde basmayan timeout olur;
//    ikisi de o turdan 0 puan alir, eleme modu aciksa sonraki turlardan elenir.
//    Siralamaya gore 4/3/2/1 puan verilir, puan kadar LED yanar ve tur raporu
//    UART'tan terminale yazilir. Oyun bitince sadece kazananin LED'leri yanar.
//
//  PUANLAMA / LED
//    1. 4 puan -> 4 LED   2. 3 puan -> 3 LED
//    3. 2 puan -> 2 LED   4. 1 puan -> 1 LED   false start / timeout -> 0
//    Ayni ms'de basanlar ayni sirayi ve ayni puani alir (beraberlik).
//////////////////////////////////////////////////////////////////////////////

module top #(
    parameter integer MS_DIV       = 100_000,   // simulasyonda kucult
    parameter integer CLKS_PER_BIT = 10417
)(
    input  wire        clk,
    input  wire [15:0] sw,
    input  wire        btnC, btnU, btnL, btnR, btnD,
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp,
    output wire        RsTx
);

    //-----------------------------------------------------------------------
    //  POWER-ON RESET  (POR)
    //
    //  SORUN
    //    FPGA konfigure olduktan sonra butun yazmaclar INIT degeriyle baslar.
    //    Bildiriminde baslangic degeri verilmemis her yazmacin INIT'i 0'dir.
    //    Bir yazmacin dogru baslangici SADECE "if (rst)" blogunda yaziliysa,
    //    kullanici SW15'i bir kez kaldirip indirmedigi surece o deger hicbir
    //    zaman yuklenmez. En kritik ornek score_accum'daki "yasayan": reset
    //    gelmezse 0000 kalir, top'taki "aktif = oyuncu_maske & yasayan" de
    //    0000 olur ve reaction_capture hicbir basisi kabul etmez. Ekran ve
    //    animasyon normal gorunur ama tur, blackout aninda kimse basamadan
    //    biter (tur_hazir aninda yukselir) ve herkes 0 puan alir.
    //    Karti prize takip dogrudan oynamaya kalkan biri bunu yasar.
    //
    //  COZUM
    //    Konfigurasyondan sonraki ilk 16 cevrim boyunca rst'yi biz yukseltip
    //    butun tasarimi bilinen bir duruma sokuyoruz. por_sayac'in bildirimde
    //    "= 0" almasi sart: INIT'i 0 yapan ve dolayisiyla POR'u tetikleyen sey
    //    bu. 15'e ulasinca por_bitti kalici olarak 1 olur ve sayac durur.
    //    Maliyeti 4 flip-flop, 160 ns.
    //-----------------------------------------------------------------------
    reg [3:0] por_sayac = 4'd0;
    wire      por_bitti = &por_sayac;      // sayac 1111 olunca 1, sonra hep 1

    always @(posedge clk)
        if (!por_bitti) por_sayac <= por_sayac + 4'd1;

    //  Reset = kullanicinin SW15'i VEYA acilistaki otomatik POR
    wire rst = sw[15] | ~por_bitti;

    assign dp = 1'b1;              // ondalik nokta sonuk (aktif-dusuk)

    //-----------------------------------------------------------------------
    //  ARA SINYALLER
    //-----------------------------------------------------------------------
    wire        vurus_1ms;
    wire [1:0]  disp_sel;

    wire [15:0] lfsr_deger;
    wire [12:0] bekleme_ms;

    wire        btnc_puls, p1_puls, p2_puls, p3_puls, p4_puls;

    wire [3:0]  oyuncu_maske;
    wire [4:0]  tur_sayisi;
    wire        eleme_modu, zor_mod;

    wire [3:0]  basamak_en;
    wire [3:0]  d0, d1, d2, d3;

    wire        silahli, pencere, t0;
    wire [4:0]  tur_no;
    wire        tur_sonu, oyun_bitti, uart_basla, uart_son_rapor;

    wire [12:0] sure0, sure1, sure2, sure3;
    wire [3:0]  gecerli, yanlis_baslangic, zaman_asimi;
    wire        tur_hazir;

    wire [2:0]  puan0, puan1, puan2, puan3;
    wire [6:0]  toplam0, toplam1, toplam2, toplam3;
    wire [3:0]  yasayan;
    wire [1:0]  kazanan;
    wire        beraberlik;

    wire        tx_gonder, tx_mesgul, rapor_bitti;
    wire [7:0]  tx_veri;

    //  Buton -> oyuncu eslesmesi: BTNU=P1, BTNL=P2, BTNR=P3, BTND=P4
    wire [3:0]  basis = {p4_puls, p3_puls, p2_puls, p1_puls};

    //  Oynayan oyuncular = secilen oyuncu sayisi VE henuz elenmemis olanlar
    wire [3:0]  aktif = oyuncu_maske & yasayan;

    //-----------------------------------------------------------------------
    //  KATMAN 0 : ortak metronom + ekran tarama secicisi
    //-----------------------------------------------------------------------
    timebase #(.MS_DIV(MS_DIV)) u_timebase (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms), .disp_sel(disp_sel)
    );

    //-----------------------------------------------------------------------
    //  BUTONLAR : 5 adet debouncer (BTNC + 4 oyuncu butonu)
    //-----------------------------------------------------------------------
    debouncer u_db_c (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnC), .btn_seviye(), .btn_puls(btnc_puls)
    );
    debouncer u_db_p1 (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnU), .btn_seviye(), .btn_puls(p1_puls)
    );
    debouncer u_db_p2 (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnL), .btn_seviye(), .btn_puls(p2_puls)
    );
    debouncer u_db_p3 (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnR), .btn_seviye(), .btn_puls(p3_puls)
    );
    debouncer u_db_p4 (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnD), .btn_seviye(), .btn_puls(p4_puls)
    );

    //-----------------------------------------------------------------------
    //  RASTGELELIK : LFSR kesintisiz doner, delay_gen onu sureye olcekler
    //-----------------------------------------------------------------------
    lfsr16 u_lfsr (
        .clk(clk), .rst(rst), .deger(lfsr_deger)
    );

    delay_gen u_delay (
        .lfsr_deger(lfsr_deger), .zor_mod(zor_mod), .bekleme_ms(bekleme_ms)
    );

    //-----------------------------------------------------------------------
    //  OYUNUN BEYNI
    //-----------------------------------------------------------------------
    game_fsm u_fsm (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btnc_puls(btnc_puls),
        .sw(sw),
        .lfsr_deger(lfsr_deger),
        .bekleme_ms(bekleme_ms),
        .tur_hazir(tur_hazir),
        .rapor_bitti(rapor_bitti),
        .yasayan(yasayan),

        .oyuncu_maske(oyuncu_maske),
        .tur_sayisi(tur_sayisi),
        .eleme_modu(eleme_modu),
        .zor_mod(zor_mod),

        .basamak_en(basamak_en),
        .d0(d0), .d1(d1), .d2(d2), .d3(d3),

        .silahli(silahli),
        .pencere(pencere),
        .t0(t0),
        .tur_no(tur_no),
        .tur_sonu(tur_sonu),
        .oyun_bitti(oyun_bitti),
        .uart_basla(uart_basla),
        .uart_son_rapor(uart_son_rapor)
    );

    //-----------------------------------------------------------------------
    //  EKRAN
    //-----------------------------------------------------------------------
    seg7_driver u_seg (
        .disp_sel(disp_sel),
        .d0(d0), .d1(d1), .d2(d2), .d3(d3),
        .basamak_en(basamak_en),
        .seg(seg), .an(an)
    );

    //-----------------------------------------------------------------------
    //  KRONOMETRE + HAKEM
    //-----------------------------------------------------------------------
    reaction_capture u_react (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .t0(t0), .silahli(silahli), .pencere(pencere),
        .basis(basis), .aktif(aktif),
        .sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
        .gecerli(gecerli),
        .yanlis_baslangic(yanlis_baslangic),
        .zaman_asimi(zaman_asimi),
        .tur_hazir(tur_hazir)
    );

    //-----------------------------------------------------------------------
    //  PUANLAMA
    //-----------------------------------------------------------------------
    scoring u_scoring (
        .sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
        .gecerli(gecerli), .aktif(aktif),
        .puan0(puan0), .puan1(puan1), .puan2(puan2), .puan3(puan3)
    );

    score_accum u_skor (
        .clk(clk), .rst(rst),
        .tur_sonu(tur_sonu),
        .eleme_modu(eleme_modu),
        .oyuncu_maske(oyuncu_maske),
        .puan0(puan0), .puan1(puan1), .puan2(puan2), .puan3(puan3),
        .yanlis_baslangic(yanlis_baslangic),
        .zaman_asimi(zaman_asimi),
        .toplam0(toplam0), .toplam1(toplam1),
        .toplam2(toplam2), .toplam3(toplam3),
        .yasayan(yasayan),
        .kazanan(kazanan),
        .beraberlik(beraberlik)
    );

    led_ctrl u_led (
        .puan0(puan0), .puan1(puan1), .puan2(puan2), .puan3(puan3),
        .oyun_bitti(oyun_bitti),
        .kazanan(kazanan),
        .led(led)
    );

    //-----------------------------------------------------------------------
    //  UART ALT SISTEMI
    //  NOT: bin2bcd, uart_reporter'IN ICINDE ornekleniyor. Sebebi: reporter
    //  metnin her yerinde farkli bir sayiyi (tur, sure, toplam) ASCII'ye
    //  cevirmek zorunda; donusturucuyu iceride tutup girisini o anki
    //  bayta gore secmek tek ornekle yetiyor.
    //-----------------------------------------------------------------------
    uart_reporter u_rapor (
        .clk(clk), .rst(rst),
        .basla(uart_basla),
        .son_rapor(uart_son_rapor),
        .tur_no(tur_no),
        .sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
        .puan0(puan0), .puan1(puan1), .puan2(puan2), .puan3(puan3),
        .toplam0(toplam0), .toplam1(toplam1),
        .toplam2(toplam2), .toplam3(toplam3),
        .yanlis_baslangic(yanlis_baslangic),
        .zaman_asimi(zaman_asimi),
        .oyuncu_maske(oyuncu_maske),
        .kazanan(kazanan),
        .beraberlik(beraberlik),
        .tx_mesgul(tx_mesgul),
        .tx_gonder(tx_gonder),
        .tx_veri(tx_veri),
        .bitti(rapor_bitti)
    );

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart (
        .clk(clk), .rst(rst),
        .gonder(tx_gonder),
        .veri(tx_veri),
        .tx(RsTx),
        .mesgul(tx_mesgul)
    );

endmodule