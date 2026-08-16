`timescale 1ns / 1ps
//  uart_tx_tb - Yazan:
//  CLKS_PER_BIT'i kucult, yoksa tek bayt 104 us surer (10417*10ns*10bit).
//  Kontrol: start biti 0 mu, 8 veri biti LSB-once mu, stop biti 1 mi,
//           mesgul dogru zamanlarda inip cikiyor mu.

module uart_tx_tb;
    localparam integer CPB_TB  = 8;         // sim icin kisa bit suresi
    localparam integer BIT_NS  = CPB_TB*10; // bir bit kac ns surer

    reg  clk = 1'b0, rst = 1'b1, gonder = 1'b0;
    reg  [7:0] veri = 8'h41;                // 'A' = 0100 0001
    wire tx, mesgul;

    reg  [7:0] alinan;
    integer    i;
    integer    hata = 0;

    always #5 clk = ~clk;

    uart_tx #(.CLKS_PER_BIT(CPB_TB)) uut (
        .clk(clk), .rst(rst), .gonder(gonder), .veri(veri),
        .tx(tx), .mesgul(mesgul)
    );

    //  Hatti dinleyip bayti geri cozer (basit alici)
    task al(output [7:0] cikan);
        begin
            @(negedge tx);                  // start biti
            #(BIT_NS + BIT_NS/2);           // start'i gec, ilk bitin ORTASINA gel
            for (i = 0; i < 8; i = i + 1) begin
                cikan[i] = tx;              // LSB once
                #(BIT_NS);
            end
            if (tx !== 1'b1) begin
                $display("   HATA: stop biti 1 degil!");
                hata = hata + 1;
            end
        end
    endtask

    task gonder_bayt(input [7:0] d);
        begin
            @(negedge clk);
            veri   = d;
            gonder = 1'b1;
            @(negedge clk);
            gonder = 1'b0;
        end
    endtask

    initial begin
        $display("--- uart_tx testi (8N1, CLKS_PER_BIT=%0d) ---", CPB_TB);

        rst = 1'b1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        if (tx !== 1'b1) begin
            $display("HATA: bosta tx 1 olmali, %b", tx);
            hata = hata + 1;
        end

        //  1. bayt : 'A'
        fork
            gonder_bayt(8'h41);
            al(alinan);
        join
        $display("gonderilen 8'h41 ('A')  ->  alinan 8'h%02h ('%0s')  %s",
                 alinan, alinan, (alinan === 8'h41) ? "GECTI" : "HATA");
        if (alinan !== 8'h41) hata = hata + 1;

        wait (mesgul == 1'b0);
        @(posedge clk);

        //  2. bayt : 'Z' (arka arkaya gonderim calisiyor mu?)
        fork
            gonder_bayt(8'h5A);
            al(alinan);
        join
        $display("gonderilen 8'h5A ('Z')  ->  alinan 8'h%02h ('%0s')  %s",
                 alinan, alinan, (alinan === 8'h5A) ? "GECTI" : "HATA");
        if (alinan !== 8'h5A) hata = hata + 1;

        wait (mesgul == 1'b0);
        repeat (10) @(posedge clk);

        //  3. bayt : 8'h00 (tum bitler 0 - start bitiyle karismali mi?)
        fork
            gonder_bayt(8'h00);
            al(alinan);
        join
        $display("gonderilen 8'h00        ->  alinan 8'h%02h  %s",
                 alinan, (alinan === 8'h00) ? "GECTI" : "HATA");
        if (alinan !== 8'h00) hata = hata + 1;

        wait (mesgul == 1'b0);
        repeat (10) @(posedge clk);

        if (hata == 0) $display("--- SONUC: TUM TESTLER GECTI ---");
        else           $display("--- SONUC: %0d TEST HATALI ---", hata);
        $finish;
    end
endmodule
