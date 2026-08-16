`timescale 1ns / 1ps
//  lfsr16 - sozde-rastgele sayi ureteci.  Yazan:
//  Resetten itibaren KESINTISIZ doner, turlar arasinda durdurulmaz.
//  Gercek rastgelelik LFSR'de degil, oyuncunun BTNC'ye bastigi anin
//  ongorulemezliginde; game_fsm o anda bu degeri ornekler.

module lfsr16 #(
    parameter [15:0] SEED = 16'hACE1      // ASLA 0 olmayacak
)(
    input  wire        clk,
    input  wire        rst,
    output reg  [15:0] deger
);

    //-----------------------------------------------------------------------
    //  Geri besleme: 16 bit icin maksimum uzunluk taplari (periyot 65535).
    //  x^16 + x^14 + x^13 + x^11 + 1
    //-----------------------------------------------------------------------
    wire geri_besleme = deger[15] ^ deger[13] ^ deger[12] ^ deger[10];

    //  SORU: tum bitler 0 olursa ne olur, neden SEED sifir olamaz?
    //  CEVAP: deger = 0 iken geri_besleme = 0^0^0^0 = 0 cikar, bir sonraki
    //         deger yine 0 olur. LFSR sifirda sonsuza kadar kilitlenir.
    //         Bu yuzden SEED sifirdan farkli olmak ZORUNDA.
    always @(posedge clk) begin
        if (rst)
            deger <= SEED;
        else
            deger <= {deger[14:0], geri_besleme};
    end

endmodule
