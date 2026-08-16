`timescale 1ns / 1ps
//  uart_reporter - tur raporunu metin olarak uretip uart_tx'e sirayla verir.
//  Yazan:
//
//  HEDEF CIKTI (sabit genislikli tut, hem kod hem okuma kolaylasir):
//     TUR 03
//      P1 0342 ms  PUAN 4
//      P2 0410 ms  PUAN 3
//      P3 FALSESTART  PUAN 0
//      P4 TIMEOUT     PUAN 0
//      TOPLAM P1=12 P2=09 P3=04 P4=07
//  Oyun sonunda:  KAZANAN P1 (18 PUAN)   veya   BERABERLIK P1=18 P3=18
//
//  TURKCE KARAKTER KULLANMA - terminalde bozuk gorunur, demoda kotu durur.
//  BU MODULU SON GUNE BIRAKMA: mantigi zor degil ama cok fazla durum var.

module uart_reporter(
    input  wire        clk, rst,
    input  wire        basla,            // game_fsm'den TEK cevrimlik puls
    input  wire        son_rapor,        // 1 ise kazanan/beraberlik mesaji

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

    reg [8:0] adim;      // metindeki kacinci bayttayiz
    reg       calisiyor;

    // YAZILACAK - onerilen yaklasim:
    //   basla gelince adim <= 0, calisiyor <= 1
    //   calisiyor && !tx_mesgul ise: adim'a karsilik gelen bayti tx_veri'ye
    //     koy, tx_gonder'i 1 cevrim yukselt, adim'i artir
    //   son adimda calisiyor <= 0, bitti <= 1
    //
    //   Sabit metinleri case icine gom; sayilari bin2bcd'den gelen
    //   hanelere 8'h30 ekleyerek ASCII yap.
    always @(posedge clk) begin

    end

endmodule
