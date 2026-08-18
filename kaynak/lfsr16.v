`timescale 1ns / 1ps

module lfsr16 #(
    parameter [15:0] BASLANGIC_DEGERI = 16'hACE1  //  reset sonrasi baslangic degeri   
)(
    input  wire        clk,
    input  wire        rst,
    output reg  [15:0] deger
);

   
    wire geri_besleme = deger[15] ^ deger[13] ^ deger[12] ^ deger[10]; // tap degerleri xorlaniyor ve en uzun donguye ulasiyor

   
    always @(posedge clk) begin
        if (rst)
            deger <= BASLANGIC_DEGERI;
        else
            deger <= {deger[14:0], geri_besleme}; // bir bit sola kaydirilir ve geri besleme degeri eklenir.
    end

endmodule
