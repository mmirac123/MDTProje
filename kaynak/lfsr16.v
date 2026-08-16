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

    // YAZILACAK:
    //   geri_besleme = deger[15] ^ deger[13] ^ deger[12] ^ deger[10]
    //   (16 bit icin maksimum uzunluk taplari)
    //   rst   -> deger <= SEED
    //   yoksa -> deger <= {deger[14:0], geri_besleme}
    //
    // SORU: tum bitler 0 olursa ne olur, neden SEED sifir olamaz?
    always @(posedge clk) begin

    end

endmodule
