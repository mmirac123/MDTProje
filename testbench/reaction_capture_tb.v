`timescale 1ns / 1ps
//  reaction_capture_tb - burada $display GEREKLI. Yazan:
//  Gozle dogrulamasi zor: 4 sure, 3 bayrak seti, ucu ayni anda.
//
//  Zaman cetveli: MS_DIV_TB=10 -> 1 ms = 100 ns ; 5 sn penceresi = 500 us
//
//  TURUN BASI = hazirlik'nin yukselen kenari. Bayraklar orada temizlenir
//  (t0'da DEGIL - yoksa blackout'tan once yakalanan false start'lar silinir).

module reaction_capture_tb;
    localparam integer MS_DIV_TB = 10;

    reg clk = 1'b0, rst = 1'b1;
    reg t0 = 1'b0, hazirlik = 1'b0, olcum_aktif = 1'b0;
    reg [3:0] basildi = 4'd0;
    reg [3:0] aktif = 4'b1111;
    wire vurus_1ms;
    wire [12:0] sure0, sure1, sure2, sure3;
    wire [3:0] gecerli, yanlis_baslangic, zaman_asimi;
    wire tur_hazir;

    integer k;
    integer hata = 0;

    always #5 clk = ~clk;

    timebase #(.MS_BOLEN(MS_DIV_TB)) tb_saat (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms), .hane_sec()
    );

    reaction_capture uut (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .t0(t0), .hazirlik(hazirlik), .olcum_aktif(olcum_aktif),
        .basildi(basildi), .aktif(aktif),
        .sure0(sure0), .sure1(sure1), .sure2(sure2), .sure3(sure3),
        .gecerli(gecerli), .yanlis_baslangic(yanlis_baslangic),
        .zaman_asimi(zaman_asimi), .tur_hazir(tur_hazir)
    );

    //-----------------------------------------------------------------------
    //  Yardimci gorevler
    //-----------------------------------------------------------------------

    //  Yeni tur: hazirlik'yi 0'dan 1'e cek (bayraklar temizlenir)
    task tur_basla;
        begin
            @(negedge clk); hazirlik = 1'b0; olcum_aktif = 1'b0; t0 = 1'b0;
            @(negedge clk); hazirlik = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    //  Blackout ani: hazirlik dusuyor, olcum_aktif aciliyor, t0 tek cevrimlik puls.
    //  Once nabza hizalaniyoruz ki t0 ile vurus_1ms ayni cevrime denk gelip
    //  bir ms'yi yutmasin - olcumler o zaman 1 ms kayardi.
    task blackout;
        begin
            @(posedge vurus_1ms);
            @(negedge clk); hazirlik = 1'b0; olcum_aktif = 1'b1; t0 = 1'b1;
            @(negedge clk); t0 = 1'b0;
        end
    endtask

    //  n adet 1 ms nabzi bekle (DUT'un ic sayacina bakmadan).
    //  Sondaki @(posedge clk) son nabzin DUT tarafindan islenmesini bekler;
    //  cikista DUT'un ms sayaci tam olarak n'dir.
    task bekle_ms(input integer n);
        begin
            for (k = 0; k < n; k = k + 1) @(posedge vurus_1ms);
            @(posedge clk);
        end
    endtask

    //  Tek cevrimlik basildi pulsu
    task bas(input [3:0] kim);
        begin
            @(negedge clk); basildi = kim;
            @(negedge clk); basildi = 4'd0;
        end
    endtask

    task kontrol(input [200*8:1] ne, input dogru_mu);
        begin
            $display("   %0s  %s", ne, dogru_mu ? "GECTI" : "HATA");
            if (!dogru_mu) hata = hata + 1;
        end
    endtask

    //-----------------------------------------------------------------------
    initial begin
        $display("--- reaction_capture testi ---");

        rst = 1'b1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        //===================================================================
        //  1) FALSE START : hazirlik iken P1 basiyor
        //===================================================================
        $display("1) FALSE START (hazirlik iken P1 basiyor)");
        aktif = 4'b1111;
        tur_basla;
        bas(4'b0001);
        repeat (3) @(posedge clk);
        $display("   yanlis_baslangic=%b gecerli=%b", yanlis_baslangic, gecerli);
        kontrol("yanlis_baslangic[0] = 1", yanlis_baslangic[0] === 1'b1);
        kontrol("gecerli[0] = 0",           gecerli[0] === 1'b0);

        //  Blackout'a gecelim: false start bayragi SILINMEMELI
        blackout;
        repeat (3) @(posedge clk);
        kontrol("blackout sonrasi da yanlis_baslangic[0] = 1",
                yanlis_baslangic[0] === 1'b1);

        //  False start yapan oyuncu pencerede bassa bile sayilmamali
        bekle_ms(50);
        bas(4'b0001);
        repeat (3) @(posedge clk);
        kontrol("false start yapan pencerede bassa da gecerli[0] = 0",
                gecerli[0] === 1'b0);

        //===================================================================
        //  2) NORMAL : P2 200 ms, P3 350 ms
        //===================================================================
        $display("2) NORMAL (P2 200 ms , P3 350 ms)");
        aktif = 4'b1111;
        tur_basla;
        blackout;
        bekle_ms(200); bas(4'b0010);
        bekle_ms(150); bas(4'b0100);
        repeat (3) @(posedge clk);
        $display("   sure1=%0d sure2=%0d gecerli=%b", sure1, sure2, gecerli);
        kontrol("sure1 = 200",  sure1 === 13'd200);
        kontrol("sure2 = 350",  sure2 === 13'd350);
        kontrol("gecerli[1] ve gecerli[2] = 1",
                (gecerli[1] === 1'b1) && (gecerli[2] === 1'b1));
        kontrol("yanlis_baslangic temiz", yanlis_baslangic === 4'b0000);

        //  Ikinci kez basmak sureyi DEGISTIRMEMELI
        bekle_ms(100); bas(4'b0010);
        repeat (3) @(posedge clk);
        kontrol("ikinci basista sure1 hala 200", sure1 === 13'd200);

        //===================================================================
        //  3) BERABERLIK : P2 ve P3 AYNI cevrimde basiyor
        //===================================================================
        $display("3) BERABERLIK (P2 ve P3 ayni cevrimde)");
        aktif = 4'b0110;                       // sadece P2 ve P3 oynuyor
        tur_basla;
        blackout;
        bekle_ms(275); bas(4'b0110);
        repeat (3) @(posedge clk);
        $display("   sure1=%0d sure2=%0d tur_hazir=%b", sure1, sure2, tur_hazir);
        kontrol("iki sure de 275", (sure1 === 13'd275) && (sure2 === 13'd275));
        kontrol("aktif oyuncularin hepsi cozulunce tur_hazir = 1",
                tur_hazir === 1'b1);

        //===================================================================
        //  4) TIMEOUT : P4 hic basmiyor, 5000 ms doluyor
        //===================================================================
        $display("4) TIMEOUT (kimse basmiyor, 5000 ms doluyor)");
        aktif = 4'b1000;                       // sadece P4 oynuyor
        tur_basla;
        blackout;
        bekle_ms(5000);
        repeat (3) @(posedge clk);
        $display("   zaman_asimi=%b gecerli=%b tur_hazir=%b",
                 zaman_asimi, gecerli, tur_hazir);
        kontrol("zaman_asimi[3] = 1", zaman_asimi[3] === 1'b1);
        kontrol("gecerli[3] = 0",     gecerli[3] === 1'b0);
        kontrol("tur_hazir = 1",      tur_hazir === 1'b1);

        if (hata == 0) $display("--- SONUC: TUM TESTLER GECTI ---");
        else           $display("--- SONUC: %0d TEST HATALI ---", hata);
        $finish;
    end
endmodule
