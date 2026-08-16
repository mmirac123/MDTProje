`timescale 1ns / 1ps
//  led_ctrl - 16 LED, oyuncu basina 4 tane.                    Yazan:
//    Oyuncu1: LED0-3  Oyuncu2: LED4-7  Oyuncu3: LED8-11  Oyuncu4: LED12-15
//  Tur sonunda puan sayisi kadar LED yanar.
//  Oyun bitince SADECE kazananin 4 LED'i yanik kalir.

module led_ctrl(
    input  wire [2:0]  puan0, puan1, puan2, puan3,
    input  wire        oyun_bitti,
    input  wire [1:0]  kazanan,
    output reg  [15:0] led
);

    // Termometre: 4->1111  3->0111  2->0011  1->0001  0->0000
    function [3:0] termo(input [2:0] p);
        // YAZILACAK
        termo = 4'b0000;
    endfunction

    // YAZILACAK:
    //   oyun_bitti -> led = 0 ; kazananin 4 biti 1
    //   degilse    -> her oyuncunun 4 bitine termo(puan_i)
    always @(*) begin
        led = 16'd0;

    end

endmodule
