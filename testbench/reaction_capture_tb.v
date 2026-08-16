`timescale 1ns / 1ps
//  reaction_capture_tb - burada $display GEREKLI. Yazan:
//  Gozle dogrulamasi zor: 4 sure, 3 bayrak seti, ucu ayni anda.
//
//  Zaman cetveli: MS_DIV_TB=10 -> 1 ms = 100 ns ; 5 sn penceresi = 500 us

module reaction_capture_tb;
    localparam integer MS_DIV_TB = 10;

    reg clk = 1'b0, rst = 1'b1;
    reg t0 = 1'b0, silahli = 1'b0, pencere = 1'b0;
    reg [3:0] basis = 4'd0;
    reg [3:0] aktif = 4'b1111;
    wire vurus_1ms;
    wire [12:0] sure0, sure1, sure2, sure3;
    wire [3:0] gecerli, yanlis_baslangic, zaman_asimi;
    wire tur_hazir;

    always #5 clk = ~clk;

    timebase #(.MS_DIV(MS_DIV_TB)) tb_saat (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms), .disp_sel()
    );

    reaction_capture uut (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .t0(t0), .silahli(silahli), .pencere(pencere),
        .basis(basis), .aktif(aktif),
        .sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
        .gecerli(gecerli), .yanlis_baslangic(yanlis_baslangic),
        .zaman_asimi(zaman_asimi), .tur_hazir(tur_hazir)
    );

    initial begin
        // YAZILACAK - dort senaryo:
        //   1) FALSE START : silahli=1 iken P1 bassin
        //      -> yanlis_baslangic[0] = 1
        //   2) NORMAL      : silahli=0, pencere=1, t0 pulsu ver;
        //      P2'yi 200 ms sonra, P3'u 350 ms sonra bastir
        //      -> sure1 = 200, sure2 = 350, gecerli[1] ve gecerli[2] = 1
        //   3) BERABERLIK  : P2 ve P3'u AYNI cevrimde bastir
        //      -> iki sure de esit
        //   4) TIMEOUT     : P4 hic basmasin, 5000 ms dolsun
        //      -> zaman_asimi[3] = 1, tur_hazir = 1
        //
        // Her senaryodan sonra $display ile sonuclari bas ve
        // beklenenle karsilastir (GECTI / HATA).
    end
endmodule
