`timescale 1ns / 1ps
//  bin2bcd_tb - kombinasyonel, $display ile kontrol etmek kolay. Yazan:

module bin2bcd_tb;
    reg  [12:0] ikili;
    wire [15:0] bcd;

    bin2bcd uut (.ikili(ikili), .bcd(bcd));

    initial begin
        // YAZILACAK: 0, 7, 42, 999, 1342, 5000 degerlerini ver,
        //            her birinde $display ile bcd'nin 4 hanesini bas.
        //            Ornek beklenen: 1342 -> 1 3 4 2
    end
endmodule
