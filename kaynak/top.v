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
//    SW3..SW0    Tur sayisi N -> oynanan tur = N+1
//    BTNC        Ayarlari kaydet / turu baslat
//    BTNU/L/R/D  Oyuncu 1 / 2 / 3 / 4
//    LED0-3 / 4-7 / 8-11 / 12-15   Oyuncu 1 / 2 / 3 / 4 siralama gostergesi
//    RsTx (A18)  UART cikisi, 9600 8N1
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

    wire rst = sw[15];
    assign dp = 1'b1;              // ondalik nokta sonuk (aktif-dusuk)

    // ---- ara sinyaller (YAZILACAK: hepsini tanimla) ----
    wire        vurus_1ms;
    wire [1:0]  disp_sel;

    // ---- BAGLANACAK MODULLER ----
    //   timebase          lfsr16           delay_gen
    //   debouncer x5      seg7_driver      reaction_capture
    //   scoring           score_accum      led_ctrl
    //   game_fsm          bin2bcd          uart_tx        uart_reporter
    //
    //   Buton -> oyuncu eslesmesi: BTNU=P1, BTNL=P2, BTNR=P3, BTND=P4
    //   basis[3:0] = {p4_puls, p3_puls, p2_puls, p1_puls}
    //   aktif      = oyuncu_maske & yasayan

    timebase #(.MS_DIV(MS_DIV)) u_timebase (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms), .disp_sel(disp_sel)
    );

    // YAZILACAK: kalan modul ornekleri

endmodule
