`timescale 1ns / 1ps


module top #(
    parameter integer MS_BOLEN       = 100_000,   //1ms olayi
    parameter integer BIT_BASINA_CEVRIM = 10417
)(
    input  wire        clk,
    input  wire [15:0] sw,
    input  wire        btnC, btnU, btnL, btnR, btnD,
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        nokta,
    output wire        RsTx
);


    reg [3:0] acilis_sayac = 4'd0;
    wire      acilis_bitti = &acilis_sayac;      // sayac 1111 olunca 1, sonra hep 1

    always @(posedge clk)
        if (!acilis_bitti) acilis_sayac <= acilis_sayac + 4'd1;


    wire rst = sw[15] | ~acilis_bitti;

    assign nokta = 1'b1;              


    wire        vurus_1ms;
    wire [1:0]  hane_sec;

    wire [15:0] lfsr_deger;
    wire [12:0] bekleme_ms;

    wire        baslat_vurusu, p1_vurusu, p2_vurusu, p3_vurusu, p4_vurusu;

    wire [3:0]  oynayanlar;
    wire [4:0]  tur_sayisi;
    wire        eleme_modu, zor_mod;

    wire [3:0]  basamak_acik;
    wire [3:0]  d0, d1, d2, d3;

    wire        hazirlik, olcum_aktif, t0;
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


    wire [3:0]  basildi = {p4_vurusu, p3_vurusu, p2_vurusu, p1_vurusu};


    wire [3:0]  aktif = oynayanlar & yasayan;

    
    timebase #(.MS_BOLEN(MS_BOLEN)) u_timebase (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms), .hane_sec(hane_sec)
    );


    debouncer u_db_c (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnC), .btn_seviye(), .btn_vurusu(baslat_vurusu)
    );
    debouncer u_db_p1 (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnU), .btn_seviye(), .btn_vurusu(p1_vurusu)
    );
    debouncer u_db_p2 (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnL), .btn_seviye(), .btn_vurusu(p2_vurusu)
    );
    debouncer u_db_p3 (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnR), .btn_seviye(), .btn_vurusu(p3_vurusu)
    );
    debouncer u_db_p4 (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btnD), .btn_seviye(), .btn_vurusu(p4_vurusu)
    );


    lfsr16 u_lfsr (
        .clk(clk), .rst(rst), .deger(lfsr_deger)
    );

    delay_gen u_delay (
        .lfsr_deger(lfsr_deger), .zor_mod(zor_mod), .bekleme_ms(bekleme_ms)
    );

    game_fsm u_fsm (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .baslat_vurusu(baslat_vurusu),
        .sw(sw),
        .lfsr_deger(lfsr_deger),
        .bekleme_ms(bekleme_ms),
        .tur_hazir(tur_hazir),
        .rapor_bitti(rapor_bitti),
        .yasayan(yasayan),

        .oynayanlar(oynayanlar),
        .tur_sayisi(tur_sayisi),
        .eleme_modu(eleme_modu),
        .zor_mod(zor_mod),

        .basamak_acik(basamak_acik),
        .d0(d0), .d1(d1), .d2(d2), .d3(d3),

        .hazirlik(hazirlik),
        .olcum_aktif(olcum_aktif),
        .t0(t0),
        .tur_no(tur_no),
        .tur_sonu(tur_sonu),
        .oyun_bitti(oyun_bitti),
        .uart_basla(uart_basla),
        .uart_son_rapor(uart_son_rapor)
    );


    seg7_driver u_seg (
        .hane_sec(hane_sec),
        .d0(d0), .d1(d1), .d2(d2), .d3(d3),
        .basamak_acik(basamak_acik),
        .seg(seg), .an(an)
    );


    reaction_capture u_react (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .t0(t0), .hazirlik(hazirlik), .olcum_aktif(olcum_aktif),
        .basildi(basildi), .aktif(aktif),
        .sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
        .gecerli(gecerli),
        .yanlis_baslangic(yanlis_baslangic),
        .zaman_asimi(zaman_asimi),
        .tur_hazir(tur_hazir)
    );


    scoring u_scoring (
        .sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
        .gecerli(gecerli), .aktif(aktif),
        .puan0(puan0), .puan1(puan1), .puan2(puan2), .puan3(puan3)
    );

    score_accum u_skor (
        .clk(clk), .rst(rst),
        .tur_sonu(tur_sonu),
        .eleme_modu(eleme_modu),
        .oynayanlar(oynayanlar),
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
        .oynayanlar(oynayanlar),
        .kazanan(kazanan),
        .beraberlik(beraberlik),
        .tx_mesgul(tx_mesgul),
        .tx_gonder(tx_gonder),
        .tx_veri(tx_veri),
        .bitti(rapor_bitti)
    );

    uart_tx #(.BIT_BASINA_CEVRIM(BIT_BASINA_CEVRIM)) u_uart (
        .clk(clk), .rst(rst),
        .gonder(tx_gonder),
        .veri(tx_veri),
        .tx(RsTx),
        .mesgul(tx_mesgul)
    );

endmodule