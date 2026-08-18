`timescale 1ns/1ps
//  por_tb - SW15'e HIC dokunmadan, sadece guc acilisiyla oyunun
//           oynanabilir duruma gelip gelmedigini kontrol eder.
module por_tb;
    reg clk = 0; reg [15:0] sw = 16'd0;
    reg btnC=0, btnU=0, btnL=0, btnR=0, btnD=0;
    wire [15:0] led; wire [6:0] seg; wire [3:0] an; wire nokta, RsTx;
    integer hata = 0;

    always #5 clk = ~clk;                       // 100 MHz

    top #(.MS_BOLEN(100), .BIT_BASINA_CEVRIM(10)) dut (
        .clk(clk), .sw(sw), .btnC(btnC), .btnU(btnU), .btnL(btnL),
        .btnR(btnR), .btnD(btnD), .led(led), .seg(seg), .an(an),
        .nokta(nokta), .RsTx(RsTx));

    task kontrol(input dogru, input [255:0] ad);
        begin
            if (dogru) $display("[ PASS ] %0s", ad);
            else begin $display("[ FAIL ] %0s", ad); hata = hata + 1; end
        end
    endtask

    initial begin
        //  SW15'e HIC DOKUNMUYORUZ - guc acilisi senaryosu
        sw[12:11] = 2'b00;      // 2 oyuncu
        sw[3:0]   = 4'd0;       // 1 tur

        #1000;
        kontrol(dut.u_skor.yasayan === 4'b1111,
                "POR sonrasi yasayan = 1111 (SW15'e dokunulmadan)");
        kontrol(dut.aktif === 4'b0011,
                "aktif = oynayanlar & yasayan = 0011");
        kontrol(dut.rst === 1'b0,
                "POR bitti, rst tekrar 0");

        //  Tek BTNC basisi: ayarlar donar VE 1. tur baslar (proje tanimi §2)
        btnC = 1; #200000; btnC = 0; #200000;

        //  SEQ animasyonu suruyor olmali (hazirlik = 1), tur ANINDA bitmemeli
        kontrol(dut.hazirlik === 1'b1, "tur basladi, hazirlik = 1");
        kontrol(dut.tur_hazir === 1'b0, "tur aninda bitmedi (tur_hazir = 0)");

        $display("");
        if (hata == 0) $display("  SONUC: POR CALISIYOR - 5/5 PASS");
        else           $display("  SONUC: %0d TEST BASARISIZ", hata);
        $finish;
    end
endmodule
