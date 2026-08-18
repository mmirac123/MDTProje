`timescale 1ns / 1ps
//  lfsr16_tb - LFSR + delay_gen birlikte dogrulanir. Yazan:
//  Kontrol edilecekler:
//    1) deger HICBIR ZAMAN 0 olmamali (0 olursa LFSR sonsuza kilitlenir)
//    2) BASLANGIC_DEGERI'e donusu tam 65535 cevrim surmeli (maksimum uzunluk)
//    3) delay_gen uc degerlerde dogru sureyi vermeli

module lfsr16_tb;

    localparam [15:0] BASLANGIC_DEGERI = 16'hACE1;

    reg  clk = 1'b0;
    reg  rst = 1'b1;
    wire [15:0] deger;

    //  delay_gen'i canli LFSR'ye bagla
    wire [12:0] bekleme_kolay, bekleme_zor;

    //  ...ve elle deger vererek uc durumlari da dene
    reg  [15:0] elle = 16'd0;
    wire [12:0] elle_kolay, elle_zor;

    integer i;
    integer donus     = 0;      // BASLANGIC_DEGERI'e kacinci cevrimde donduk
    integer sifir_gor = 0;      // kac kez 0 gorduk
    integer hata      = 0;

    always #5 clk = ~clk;

    lfsr16 #(.BASLANGIC_DEGERI(BASLANGIC_DEGERI)) uut (.clk(clk), .rst(rst), .deger(deger));

    delay_gen dg_k  (.lfsr_deger(deger), .zor_mod(1'b0), .bekleme_ms(bekleme_kolay));
    delay_gen dg_z  (.lfsr_deger(deger), .zor_mod(1'b1), .bekleme_ms(bekleme_zor));
    delay_gen dg_ek (.lfsr_deger(elle),  .zor_mod(1'b0), .bekleme_ms(elle_kolay));
    delay_gen dg_ez (.lfsr_deger(elle),  .zor_mod(1'b1), .bekleme_ms(elle_zor));

    task delay_dene(input [15:0] d, input [12:0] bek_k, input [12:0] bek_z);
        begin
            elle = d;
            #1;
            $display("lfsr=%5d (r=%4d) -> kolay %4d ms (bekl %4d) | zor %4d ms (bekl %4d)  %s",
                     d, d[11:0], elle_kolay, bek_k, elle_zor, bek_z,
                     ((elle_kolay === bek_k) && (elle_zor === bek_z)) ? "GECTI" : "HATA");
            if ((elle_kolay !== bek_k) || (elle_zor !== bek_z)) hata = hata + 1;
        end
    endtask

    initial begin
        $display("--- lfsr16 + delay_gen testi ---");

        rst = 1'b1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        //-------------------------------------------------------------------
        //  Bir tam periyot tara
        //-------------------------------------------------------------------
        for (i = 1; i <= 66000; i = i + 1) begin
            @(posedge clk);
            #1;
            if (deger === 16'd0)               sifir_gor = sifir_gor + 1;
            if ((deger === BASLANGIC_DEGERI) && (donus == 0)) donus = i;
        end

        $display("deger hic 0 oldu mu : %0d kez  %s",
                 sifir_gor, (sifir_gor == 0) ? "GECTI" : "HATA");
        if (sifir_gor != 0) hata = hata + 1;

        $display("BASLANGIC_DEGERI'e donus       : %0d cevrim (beklenen 65535)  %s",
                 donus, (donus == 65535) ? "GECTI" : "HATA");
        if (donus != 65535) hata = hata + 1;

        //-------------------------------------------------------------------
        //  delay_gen uc degerleri
        //-------------------------------------------------------------------
        $display("");
        $display("--- delay_gen uc degerleri ---");
        //  r = 0     -> t_min
        delay_dene(16'h0000, 13'd2000, 13'd500);
        //  r = 4095  -> kolay 2000+2999 = 4999 , zor 500+4499 = 4999
        delay_dene(16'h0FFF, 13'd4999, 13'd4999);
        //  r = 2048  -> kolay 2000+1500 = 3500 , zor 500+2250 = 2750
        delay_dene(16'h0800, 13'd3500, 13'd2750);
        //  Ust bitler sonucu ETKILEMEMELI (sadece alt 12 bit kullaniliyor)
        delay_dene(16'hF800, 13'd3500, 13'd2750);

        $display("");
        $display("canli LFSR ornegi  : deger=%5d -> kolay %4d ms , zor %4d ms",
                 deger, bekleme_kolay, bekleme_zor);

        if (hata == 0) $display("--- SONUC: TUM TESTLER GECTI ---");
        else           $display("--- SONUC: %0d TEST HATALI ---", hata);
        $finish;
    end

endmodule
