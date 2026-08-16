`timescale 1ns / 1ps
//  bin2bcd_tb - kombinasyonel, $display ile kontrol etmek kolay. Yazan:

module bin2bcd_tb;
    reg  [12:0] ikili;
    wire [15:0] bcd;

    integer hata = 0;

    bin2bcd uut (.ikili(ikili), .bcd(bcd));

    //  Bir degeri ver, sonucu bekleneni ile karsilastir
    task dene(input [12:0] deger);
        reg [3:0] b3, b2, b1, b0;
        begin
            ikili = deger;
            #1;                                  // kombinasyonel oturmasi icin
            b3 = (deger / 1000) % 10;
            b2 = (deger / 100)  % 10;
            b1 = (deger / 10)   % 10;
            b0 =  deger         % 10;

            $display("ikili=%4d  ->  bcd = %0d %0d %0d %0d   (beklenen %0d %0d %0d %0d)  %s",
                     deger,
                     bcd[15:12], bcd[11:8], bcd[7:4], bcd[3:0],
                     b3, b2, b1, b0,
                     (bcd == {b3,b2,b1,b0}) ? "GECTI" : "HATA");

            if (bcd != {b3,b2,b1,b0}) hata = hata + 1;
        end
    endtask

    initial begin
        $display("--- bin2bcd testi ---");
        dene(13'd0);
        dene(13'd7);
        dene(13'd42);
        dene(13'd999);
        dene(13'd1342);
        dene(13'd5000);
        dene(13'd500);
        dene(13'd2000);
        dene(13'd4999);

        if (hata == 0) $display("--- SONUC: TUM TESTLER GECTI ---");
        else           $display("--- SONUC: %0d TEST HATALI ---", hata);
        $finish;
    end
endmodule
