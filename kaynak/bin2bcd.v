`timescale 1ns / 1ps
//  bin2bcd - ikilik sayiyi 4 haneli BCD'ye cevirir (double dabble). Yazan:
//  1342 -> 0001 0011 0100 0010 . ASCII icin her haneye 8'h30 eklenir.
//  Bolme kullanmaz; "kaydir + hane 4'ten buyukse 3 ekle" dongusudur.

module bin2bcd(
    input  wire [12:0] ikili,     // 0..5000
    output reg  [15:0] bcd        // 4 hane
);

    integer i;

    //   bcd = 0
    //   i = 12'den 0'a dogru:
    //       her 4 bitlik hane > 4 ise o haneye 3 ekle
    //       bcd = {bcd[14:0], ikili[i]}
    //
    //  Neden 3 ekleniyor: bir sonraki kaydirma haneyi 2 ile carpacak.
    //  Hane 5 veya daha buyukse carpim 10'u asar ve elde bir ust haneye
    //  gecmelidir; 3 eklemek (yani kaydirmadan sonra 6 eklemek) tam olarak
    //  bu onluk tasimayi yapar.
    always @(*) begin
        bcd = 16'd0;
        for (i = 12; i >= 0; i = i - 1) begin
            if (bcd[3:0]   >= 4'd5) bcd[3:0]   = bcd[3:0]   + 4'd3;
            if (bcd[7:4]   >= 4'd5) bcd[7:4]   = bcd[7:4]   + 4'd3;
            if (bcd[11:8]  >= 4'd5) bcd[11:8]  = bcd[11:8]  + 4'd3;
            if (bcd[15:12] >= 4'd5) bcd[15:12] = bcd[15:12] + 4'd3;
            bcd = {bcd[14:0], ikili[i]};
        end
    end

endmodule
