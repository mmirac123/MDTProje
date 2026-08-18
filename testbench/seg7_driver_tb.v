`timescale 1ns / 1ps
//  seg7_driver_tb - dalga formuna bak (ayrica $display ile de kontrol edilir).
//  Yazan:
//  Kontrol: hane_sec doner mi, an dogru basamagi mi seciyor,
//           basamak_acik 0 olan basamak gercekten sonuk mu.

module seg7_driver_tb;
    reg  [1:0] hane_sec = 2'd0;
    reg  [3:0] d0 = 4'd1, d1 = 4'd2, d2 = 4'd3, d3 = 4'd4;
    reg  [3:0] basamak_acik = 4'b1111;
    wire [6:0] seg;
    wire [3:0] an;

    integer i;
    integer hata = 0;

    //  Beklenen segment desenleri (aktif-dusuk, gfedcba)
    reg [6:0] desen [0:9];
    initial begin
        desen[0] = 7'b1000000;  desen[1] = 7'b1111001;
        desen[2] = 7'b0100100;  desen[3] = 7'b0110000;
        desen[4] = 7'b0011001;  desen[5] = 7'b0010010;
        desen[6] = 7'b0000010;  desen[7] = 7'b1111000;
        desen[8] = 7'b0000000;  desen[9] = 7'b0011000;
    end

    seg7_driver uut (.hane_sec(hane_sec), .d0(d0), .d1(d1), .d2(d2), .d3(d3),
                     .basamak_acik(basamak_acik), .seg(seg), .an(an));

    task tara(input [3:0] maske);
        reg [3:0] bek_an;
        reg [3:0] rakam;
        begin
            basamak_acik = maske;
            for (i = 0; i < 4; i = i + 1) begin
                hane_sec = i[1:0];
                #1;
                rakam  = (i == 0) ? d0 : (i == 1) ? d1 : (i == 2) ? d2 : d3;
                bek_an = 4'b1111;
                if (maske[i]) bek_an[i] = 1'b0;

                $display("  basamak_acik=%b hane_sec=%0d -> an=%b seg=%b (rakam %0d)  %s",
                         maske, i, an, seg, rakam,
                         ((an === bek_an) && (seg === desen[rakam])) ? "GECTI" : "HATA");

                if ((an !== bek_an) || (seg !== desen[rakam])) hata = hata + 1;
            end
        end
    endtask

    initial begin
        $display("--- seg7_driver testi ---");

        $display("1) dort basamak da acik  (ekranda 4 3 2 1 gorunur, d0 en sagda)");
        tara(4'b1111);

        $display("2) sadece alt iki basamak acik (ust ikisi SONUK olmali)");
        tara(4'b0011);

        $display("3) hepsi kapali (blackout)");
        tara(4'b0000);

        $display("4) rakamlar 5 6 7 8 (cift turlar)");
        d0 = 4'd5; d1 = 4'd6; d2 = 4'd7; d3 = 4'd8;
        tara(4'b1111);

        if (hata == 0) $display("--- SONUC: TUM TESTLER GECTI ---");
        else           $display("--- SONUC: %0d TEST HATALI ---", hata);
        $finish;
    end
endmodule
