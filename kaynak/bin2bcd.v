`timescale 1ns / 1ps
//  bin2bcd - ikilik sayiyi 4 haneli BCD'ye cevirir (double dabble). Yazan:
//  1342 -> 0001 0011 0100 0010 . ASCII icin her haneye 8'h30 eklenir.
//  Bolme kullanmaz; "kaydir + hane 4'ten buyukse 3 ekle" dongusudur.

module bin2bcd(
    input  wire [12:0] ikili,     // 0..5000
    output reg  [15:0] bcd        // 4 hane
);

    integer i;

    // YAZILACAK:
    //   bcd = 0
    //   i = 12'den 0'a dogru:
    //       her 4 bitlik hane > 4 ise o haneye 3 ekle
    //       bcd = {bcd[14:0], ikili[i]}
    always @(*) begin
        bcd = 16'd0;

    end

endmodule
