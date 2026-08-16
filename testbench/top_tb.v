`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
//  top_tb - SISTEM testbench'i.  Yazan:
//  Tum oyunu simule eder ve her adimi [ PASS ] / [ FAIL ] olarak raporlar.
//
//  MS_DIV ve CLKS_PER_BIT'i MUTLAKA kucult, yoksa tek tur bile dakikalar surer.
//
//  SENARYO (2 oyuncu, 2 tur, eleme kapali, zor mod)
//    Tur 1 : P1 200 ms , P2 350 ms   -> P1 4 puan / P2 3 puan
//    Tur 2 : P1 FALSE START          -> P1 0 puan / P2 4 puan
//    Sonuc : P1 = 4 , P2 = 7  -> kazanan P2, sadece LED4-7 yanik kalir
//
//  Testbench ayrica RsTx hattini cozer:
//    - raporu konsola yazar (gozle dogrulama)
//    - bayt sayisini ve metin icerigini otomatik kontrol eder
//////////////////////////////////////////////////////////////////////////////

module top_tb;

    localparam integer MS_DIV_TB = 10;               // 1 ms = 10 cevrim
    localparam integer CPB_TB    = 8;                // UART bit suresi (cevrim)
    localparam integer MS_NS     = MS_DIV_TB * 10;   // 1 ms kac ns  -> 100
    localparam integer BIT_NS    = CPB_TB * 10;      // 1 UART biti kac ns -> 80

    reg         clk = 1'b0;
    reg  [15:0] sw  = 16'h8000;                      // SW15 = 1 -> reset
    reg         btnC = 1'b0, btnU = 1'b0, btnL = 1'b0, btnR = 1'b0, btnD = 1'b0;
    wire [15:0] led;
    wire [6:0]  seg;
    wire [3:0]  an;
    wire        dp, RsTx;

    integer gecen = 0, kalan = 0;

    always #5 clk = ~clk;

    top #(.MS_DIV(MS_DIV_TB), .CLKS_PER_BIT(CPB_TB)) uut (
        .clk(clk), .sw(sw), .btnC(btnC), .btnU(btnU), .btnL(btnL),
        .btnR(btnR), .btnD(btnD),
        .led(led), .seg(seg), .an(an), .dp(dp), .RsTx(RsTx)
    );

    //=======================================================================
    //  TEST ALTYAPISI
    //=======================================================================
    task pass_fail(input [240*8:1] ne, input dogru_mu);
        begin
            if (dogru_mu) begin
                $display("[ PASS ] %0s", ne);
                gecen = gecen + 1;
            end else begin
                $display("[ FAIL ] %0s", ne);
                kalan = kalan + 1;
            end
        end
    endtask

    //  Sayisal karsilastirma - hata halinde beklenen/olcuten degeri de basar
    task pass_fail_d(input [240*8:1] ne, input integer olculen, input integer beklenen);
        begin
            if (olculen === beklenen) begin
                $display("[ PASS ] %0s  (= %0d)", ne, olculen);
                gecen = gecen + 1;
            end else begin
                $display("[ FAIL ] %0s  beklenen %0d , olculen %0d",
                         ne, beklenen, olculen);
                kalan = kalan + 1;
            end
        end
    endtask

    //  Tolansli karsilastirma (debounce gecikmesi vb. icin)
    task pass_fail_yaklasik(input [240*8:1] ne, input integer olculen,
                            input integer beklenen, input integer tolerans);
        begin
            if ((olculen >= beklenen - tolerans) && (olculen <= beklenen + tolerans)) begin
                $display("[ PASS ] %0s  (= %0d , beklenen %0d +/- %0d)",
                         ne, olculen, beklenen, tolerans);
                gecen = gecen + 1;
            end else begin
                $display("[ FAIL ] %0s  beklenen %0d +/- %0d , olculen %0d",
                         ne, beklenen, tolerans, olculen);
                kalan = kalan + 1;
            end
        end
    endtask

    task baslik(input [240*8:1] ne);
        begin
            $display("");
            $display("--- %0s ---", ne);
        end
    endtask

    //  Buton basma yardimcisi: debounce esiginden (10 ms) UZUN basili tut
    task bas(input integer hangi);
        begin
            case (hangi)
                0: btnC = 1'b1;  1: btnU = 1'b1;  2: btnL = 1'b1;
                3: btnR = 1'b1;  4: btnD = 1'b1;
            endcase
            #(15 * MS_NS);
            case (hangi)
                0: btnC = 1'b0;  1: btnU = 1'b0;  2: btnL = 1'b0;
                3: btnR = 1'b0;  4: btnD = 1'b0;
            endcase
            #(15 * MS_NS);
        end
    endtask

    //=======================================================================
    //  IZLEYICI 1 : 7-segment animasyonu (basamak_en gecisleri + zamanlari)
    //=======================================================================
    reg  [3:0] anim_deger [0:7];
    integer    anim_zaman [0:7];
    integer    anim_n     = 0;
    reg        anim_kayit = 1'b0;

    always @(uut.u_fsm.basamak_en) begin
        if (anim_kayit && (anim_n < 8)) begin
            anim_deger[anim_n] = uut.u_fsm.basamak_en;
            anim_zaman[anim_n] = $time;
            anim_n = anim_n + 1;
        end
    end

    //=======================================================================
    //  IZLEYICI 2 : puls sinyalleri gercekten TEK cevrimlik mi?
    //=======================================================================
    integer t0_sayim = 0, tur_sonu_sayim = 0, t0_genislik = 0, en_genis_t0 = 0;

    always @(posedge clk) begin
        if (uut.t0) begin
            t0_sayim    = t0_sayim + 1;
            t0_genislik = t0_genislik + 1;
            if (t0_genislik > en_genis_t0) en_genis_t0 = t0_genislik;
        end else begin
            t0_genislik = 0;
        end
        if (uut.tur_sonu) tur_sonu_sayim = tur_sonu_sayim + 1;
    end

    //=======================================================================
    //  IZLEYICI 3 : UART alicisi - RsTx'i cozer, konsola yazar, tamponlar
    //=======================================================================
    reg [7:0] tampon [0:511];
    integer   uart_n = 0;
    reg [7:0] alinan;
    integer   bi;

    initial begin
        wait (sw[15] == 1'b0);
        #(50 * MS_NS);
        forever begin
            @(negedge RsTx);                    // start biti
            #(BIT_NS + BIT_NS/2);               // ilk veri bitinin ortasi
            for (bi = 0; bi < 8; bi = bi + 1) begin
                alinan[bi] = RsTx;              // LSB once
                #(BIT_NS);
            end
            if (uart_n < 512) tampon[uart_n] = alinan;
            uart_n = uart_n + 1;
            if      (alinan == 8'h0A) $display("");
            else if (alinan != 8'h0D) $write("%0s", alinan);
        end
    end

    //  Tampondaki metni beklenen string ile karsilastir
    task metin_kontrol(input [240*8:1] ne, input integer ofs,
                       input integer n, input [24*8:1] bek);
        integer q;
        reg     ok;
        begin
            ok = 1'b1;
            for (q = 0; q < n; q = q + 1)
                if (tampon[ofs+q] !== bek[(n-q)*8 -: 8]) ok = 1'b0;
            if (ok) begin
                $display("[ PASS ] %0s", ne);
                gecen = gecen + 1;
            end else begin
                $write("[ FAIL ] %0s  ->  alinan \"", ne);
                for (q = 0; q < n; q = q + 1) $write("%0s", tampon[ofs+q]);
                $display("\"");
                kalan = kalan + 1;
            end
        end
    endtask

    //=======================================================================
    //  IZLEYICI 4 : son tur gosterim beklemesi (game_fsm faz 4)
    //=======================================================================
    integer son_gosterim_t0 = 0;

    always @(posedge clk) begin
        if ((uut.u_fsm.durum == 3'd5) && (uut.u_fsm.rapor_fz == 3'd4)
            && (son_gosterim_t0 == 0))
            son_gosterim_t0 = $time;
    end

    //=======================================================================
    //  ANA TEST
    //=======================================================================
    integer bekleme_olculen, hedef_okunan;

    initial begin
        //  Vivado varsayilan olarak zamani ps olarak basar; ns'ye cevir
        $timeformat(-9, 0, " ns", 12);
        $display("=========================================================");
        $display("  top_tb : Basys3 Refleks Oyunu - tam sistem testi");
        $display("  2 oyuncu | 2 tur | eleme KAPALI | zor mod");
        $display("=========================================================");

        //===================================================================
        baslik("1) RESET");
        //===================================================================
        sw = 16'h8000;
        #(20 * MS_NS);
        pass_fail("reset: tum LED'ler sonuk",        led === 16'd0);
        pass_fail("reset: 7-segment sonuk (an=1111)", an  === 4'b1111);
        pass_fail("reset: UART hatti bosta (RsTx=1)", RsTx === 1'b1);
        pass_fail("reset: durum = S_CONFIG",          uut.u_fsm.durum === 3'd0);

        //===================================================================
        baslik("2) KONFIGURASYON");
        //===================================================================
        //  SW15=0 reset birak | SW14=0 eleme kapali | SW13=1 zor mod
        //  SW12:11=00 -> 2 oyuncu | SW3:0=0001 -> 2 tur
        sw = 16'b0010_0000_0000_0001;
        #(30 * MS_NS);

        pass_fail("konfigurasyon ekrani acik (basamak_en=1011)",
                  uut.u_fsm.basamak_en === 4'b1011);
        pass_fail_d("ekranda oyuncu sayisi (d3)", uut.d3, 2);
        pass_fail_d("ekranda tur sayisi onlar (d1)", uut.d1, 0);
        pass_fail_d("ekranda tur sayisi birler (d0)", uut.d0, 2);

        //  BTNC : ayarlari kaydet VE 1. turu baslat.
        //  Proje tanimi §2: "BTNC'ye basildiginda ayarlar kaydedilmeli ve
        //  oyun baslamalidir" -> tek basis. Animasyon bu basisla basladigi
        //  icin kaydediciyi basmadan ONCE aciyoruz.
        anim_kayit = 1'b1;
        uart_n     = 0;
        bas(0);
        #(5 * MS_NS);

        pass_fail("BTNC sonrasi durum = S_SEQ",  uut.u_fsm.durum === 3'd2);
        pass_fail("oyuncu maskesi 2 oyuncu (0011)",
                  uut.oyuncu_maske === 4'b0011);
        pass_fail_d("tur sayisi latch'lendi",   uut.u_fsm.tur_sayisi, 2);
        pass_fail("eleme modu kapali",          uut.eleme_modu === 1'b0);
        pass_fail("zor mod acik",               uut.zor_mod    === 1'b1);
        pass_fail("TEK basisla tur basladi (silahli=1)",
                  uut.silahli === 1'b1);
        pass_fail_d("1. tur numarasi",          uut.u_fsm.tur_no, 1);

        //===================================================================
        baslik("3) TUR 1 - ANIMASYON VE BLACKOUT");
        //===================================================================

        @(posedge uut.u_fsm.pencere);            // blackout ani
        //  DIKKAT: @(posedge ...) tam sinyalin degistigi delta aninda doner.
        //  t0 sayaci bir sonraki saat kenarinda sayiyor, "an" ise kombinasyonel
        //  olarak henuz oturmamis oluyor. Olcmeden once birkac cevrim bekle.
        repeat (3) @(posedge clk);
        #1;
        $display("        blackout t = %0t", $time);

        hedef_okunan    = uut.u_fsm.hedef;
        bekleme_olculen = (anim_zaman[4] - anim_zaman[3]) / MS_NS - 400;

        pass_fail_d("animasyon 5 gecis kaydetti", anim_n, 5);
        pass_fail("adim 1 : basamak_en = 0001", anim_deger[0] === 4'b0001);
        pass_fail("adim 2 : basamak_en = 0011", anim_deger[1] === 4'b0011);
        pass_fail("adim 3 : basamak_en = 0111", anim_deger[2] === 4'b0111);
        pass_fail("adim 4 : basamak_en = 1111", anim_deger[3] === 4'b1111);
        pass_fail("blackout : basamak_en = 0000", anim_deger[4] === 4'b0000);

        pass_fail_yaklasik("adim 1->2 suresi (ms)",
                  (anim_zaman[1]-anim_zaman[0])/MS_NS, 400, 1);
        pass_fail_yaklasik("adim 2->3 suresi (ms)",
                  (anim_zaman[2]-anim_zaman[1])/MS_NS, 400, 1);
        pass_fail_yaklasik("adim 3->4 suresi (ms)",
                  (anim_zaman[3]-anim_zaman[2])/MS_NS, 400, 1);

        $display("        LFSR'den gelen hedef bekleme = %0d ms", hedef_okunan);
        pass_fail("rastgele bekleme zor mod araliginda (500-5000 ms)",
                  (hedef_okunan >= 500) && (hedef_okunan <= 5000));
        pass_fail_yaklasik("olculen bekleme = hedef",
                  bekleme_olculen, hedef_okunan, 2);
        pass_fail_d("t0 pulsu bir kez cikti", t0_sayim, 1);
        pass_fail_d("t0 pulsu TEK cevrimlik", en_genis_t0, 1);
        pass_fail("blackout'ta ekran tamamen sonuk", an === 4'b1111);

        //===================================================================
        baslik("4) TUR 1 - REFLEKS OLCUMU");
        //===================================================================
        //  P1 : 200 ms sonra bassin (debounce 10 ms geciktirir -> 190'da bas)
        #(190 * MS_NS - 30);  btnU = 1'b1;
        #(15  * MS_NS);  btnU = 1'b0;
        //  P2 : 350 ms sonra bassin
        #(135 * MS_NS);  btnL = 1'b1;
        #(15  * MS_NS);  btnL = 1'b0;

        wait (uut.u_fsm.durum == 3'd6);          // S_NEXT : tur bitti + rapor gitti
        #(1 * MS_NS);

        pass_fail_yaklasik("P1 reaksiyon suresi (ms)", uut.sure0, 200, 3);
        pass_fail_yaklasik("P2 reaksiyon suresi (ms)", uut.sure1, 350, 3);
        pass_fail("P1, P2'den hizli olculdu", uut.sure0 < uut.sure1);
        pass_fail("iki olcum de gecerli",       uut.gecerli === 4'b0011);
        pass_fail("false start yok",            uut.yanlis_baslangic === 4'b0000);
        pass_fail("timeout yok",                uut.zaman_asimi === 4'b0000);
        pass_fail_d("tur_sonu pulsu bir kez cikti", tur_sonu_sayim, 1);

        pass_fail_d("P1 birinci -> 4 puan", uut.puan0, 4);
        pass_fail_d("P2 ikinci  -> 3 puan", uut.puan1, 3);
        pass_fail("P1 LED'leri 4 tane (LED0-3)",  led[3:0]  === 4'b1111);
        pass_fail("P2 LED'leri 3 tane (LED4-7)",  led[7:4]  === 4'b0111);
        pass_fail("oynamayan P3/P4 sonuk",        led[15:8] === 8'b0000_0000);
        pass_fail_d("P1 toplam", uut.toplam0, 4);
        pass_fail_d("P2 toplam", uut.toplam1, 3);

        //===================================================================
        baslik("5) TUR 1 - UART RAPORU");
        //===================================================================
        pass_fail_d("rapor uzunlugu (7 satir x 32 bayt)", uart_n, 224);
        metin_kontrol("1. satir  \"TUR 01\"",        0,   6, "TUR 01");
        //  Sureler debounce fazina gore 1 ms oynayabilir; bu yuzden metin
        //  kontrolu rakamlari degil, satirin sabit iskeletini dogruluyor.
        metin_kontrol("2. satir  \" P1 0...\"",       32,  5, " P1 0");
        metin_kontrol("2. satir  birimi \"ms\"",      41,  2, "ms");
        metin_kontrol("2. satir  \"PUAN 4\"",         48,  6, "PUAN 4");
        metin_kontrol("3. satir  \" P2 0...\"",       64,  5, " P2 0");
        metin_kontrol("3. satir  \"PUAN 3\"",         80,  6, "PUAN 3");
        metin_kontrol("4. satir  \" P3 OYNAMIYOR\"", 96, 13, " P3 OYNAMIYOR");
        metin_kontrol("6. satir  \"TOPLAM P1=04\"", 160, 12, "TOPLAM P1=04");
        pass_fail("satir sonlari CR LF",
                  (tampon[30] === 8'h0D) && (tampon[31] === 8'h0A));

        //===================================================================
        baslik("6) TUR 2 - FALSE START");
        //===================================================================
        uart_n         = 0;
        tur_sonu_sayim = 0;
        t0_sayim       = 0;
        en_genis_t0    = 0;

        bas(0);                                  // sonraki tur DOGRUDAN baslar
        #(200 * MS_NS);                          // hala SEQ icindeyiz
        $display("        P1 erken basiyor (FALSE START)");
        btnU = 1'b1;
        #(15 * MS_NS);
        btnU = 1'b0;
        #(5  * MS_NS);

        pass_fail("false start aninda silahli = 1", uut.silahli === 1'b1);
        pass_fail("P1 false start yakalandi",
                  uut.yanlis_baslangic === 4'b0001);

        @(posedge uut.u_fsm.pencere);            // blackout ani
        repeat (3) @(posedge clk);
        #1;
        pass_fail("blackout'tan sonra false start bayragi SILINMEDI",
                  uut.yanlis_baslangic[0] === 1'b1);

        //  P2 : 300 ms sonra bassin
        #(290 * MS_NS - 30);  btnL = 1'b1;
        #(15  * MS_NS);  btnL = 1'b0;

        wait (uut.u_fsm.durum == 3'd7);          // S_OVER : oyun bitti
        #(1 * MS_NS);

        pass_fail_yaklasik("P2 reaksiyon suresi (ms)", uut.sure1, 300, 2);
        pass_fail_d("false start yapan P1 -> 0 puan", uut.puan0, 0);
        pass_fail_d("P2 birinci -> 4 puan",           uut.puan1, 4);
        pass_fail("false start yapan pencerede basmadi -> gecerli[0]=0",
                  uut.gecerli[0] === 1'b0);

        //===================================================================
        baslik("7) OYUN SONU");
        //===================================================================
        pass_fail("oyun_bitti = 1",         uut.oyun_bitti === 1'b1);
        pass_fail_d("P1 toplam puan",       uut.toplam0, 4);
        pass_fail_d("P2 toplam puan",       uut.toplam1, 7);
        pass_fail_d("kazanan oyuncu no",    uut.kazanan + 1, 2);
        pass_fail("beraberlik yok",         uut.beraberlik === 1'b0);
        pass_fail("sadece kazananin LED'leri yanik",
                  led === 16'b0000_0000_1111_0000);
        pass_fail("oyun bitince ekran sonuk", an === 4'b1111);
        //  Son turda siralama LED'leri kazanan gosterimine gecmeden once
        //  SON_GOSTERIM_MS kadar ekranda kalmali (game_fsm faz 4)
        pass_fail_yaklasik("son tur sonucu ekranda bekledi (ms)",
                  ($time - son_gosterim_t0) / MS_NS, 3000, 5);

        //===================================================================
        baslik("8) SON UART RAPORU");
        //===================================================================
        pass_fail_d("son rapor uzunlugu (9 satir x 32 bayt)", uart_n, 288);
        metin_kontrol("1. satir  \"TUR 02\"",           0,   6, "TUR 02");
        metin_kontrol("2. satir  \" P1 FALSESTART\"",  32, 14, " P1 FALSESTART");
        metin_kontrol("6. satir  \"TOPLAM P1=04\"",   160, 12, "TOPLAM P1=04");
        metin_kontrol("8. satir  \"==== OYUN BITTI\"", 224, 15, "==== OYUN BITTI");
        metin_kontrol("9. satir  \"KAZANAN P2\"",      256, 10, "KAZANAN P2");

        //===================================================================
        #(200 * MS_NS);
        $display("");
        $display("=========================================================");
        $display("  TOPLAM %0d test :  %0d PASS  ,  %0d FAIL",
                 gecen + kalan, gecen, kalan);
        if (kalan == 0) $display("  SONUC: TUM TESTLER GECTI");
        else            $display("  SONUC: %0d TEST BASARISIZ", kalan);
        $display("=========================================================");
        $finish;
    end

    //  Guvenlik freni: bir yerde takilirsa simulasyon sonsuza kadar surmesin
    initial begin
        #(60_000 * MS_NS);
        $display("");
        $display("!!! ZAMAN ASIMI - simulasyon beklenenden uzun surdu.");
        $display("!!! O ana kadar: %0d PASS , %0d FAIL", gecen, kalan);
        $finish;
    end

endmodule
