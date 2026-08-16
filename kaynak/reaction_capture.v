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

    reg [12:0] ms;

    // YAZILACAK:
    //   1) rst veya t0 -> ms <= 0 ; gecerli/yanlis_baslangic/zaman_asimi temizle
    //   2) pencere && vurus_1ms -> ms <= ms + 1
    //   3) her oyuncu i icin, aktif[i] && basis[i] ise:
    //        silahli                             -> yanlis_baslangic[i] <= 1
    //        pencere && !gecerli[i] && !yanlis[i] -> sure_i <= ms, gecerli[i] <= 1
    //   4) pencere && ms == 5000 ->
    //        zaman_asimi <= aktif & ~gecerli & ~yanlis_baslangic
    //
    // NOT: gecerli[i] bayragi ikinci basisi da engeller, ayri kilit gerekmez.
    always @(posedge clk) begin

    end

    // YAZILACAK: 5000 ms doldu VEYA aktif oyuncularin hepsi cozuldu
    assign tur_hazir = 1'b0;        // <-- degistir

endmodule
