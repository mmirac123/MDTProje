`timescale 1ns / 1ps
//  debouncer_tb - dalga formuna bakarak dogrula, $display'e gerek yok

module debouncer_tb;

    localparam integer MS_DIV_TB   = 10;    // 1 ms = 10 cevrim
    localparam integer STABLE_MS_TB = 5;    // 5 ms kararlilik

    reg  clk = 1'b0;
    reg  rst = 1'b1;
    reg  btn_ham = 1'b0;
    wire vurus_1ms, btn_seviye, btn_vurusu;

    always #5 clk = ~clk;

    // Nabzi gercek timebase'den al (ayrica entegrasyonu da denemis olursun)
    timebase #(.MS_BOLEN(MS_DIV_TB)) tb_saat (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms), .hane_sec()
    );

    debouncer #(.KARARLI_MS(STABLE_MS_TB)) uut (
        .clk(clk), .rst(rst), .vurus_1ms(vurus_1ms),
        .btn_ham(btn_ham), .btn_seviye(btn_seviye), .btn_vurusu(btn_vurusu)
    );

    //  Zaman cetveli:  1 ms = 10 cevrim = 100 ns  |  esik (5 ms) = 500 ns
    //  Uyaranlar negedge'e hizali verilir ki DUT'un posedge orneklemesiyle
    //  yaris durumu olusmasin.
    initial begin
        btn_ham = 1'b0;
        rst     = 1'b1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // 1) ZIPLAYAN BASIS - her parca 30 ns, esikten cok kisa
        //    Beklenen: ziplama filtrelenir, sabitlendikten 500 ns sonra
        //              btn_seviye 1 olur ve TEK btn_vurusu cikar.
        #30 btn_ham = 1'b1;
        #30 btn_ham = 1'b0;
        #30 btn_ham = 1'b1;
        #30 btn_ham = 1'b0;
        #30 btn_ham = 1'b1;      // artik sabit
        #2000;                   // 20 ms basili tut

        // 2) BIRAKMA - Beklenen: btn_seviye 0'a doner ama puls CIKMAZ
        //    (btn_vurusu sadece yukselen kenarda uretiliyor)
        btn_ham = 1'b0;
        #2000;

        // 3) KISA BASIS - 2 ms, esik olan 5 ms'ten kisa
        //    Beklenen: btn_seviye hic degismez, puls CIKMAZ
        btn_ham = 1'b1;
        #200;
        btn_ham = 1'b0;
        #2000;

        $finish;
    end

endmodule
