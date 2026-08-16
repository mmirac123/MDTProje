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
        begin
            case (p)
                3'd1:    termo = 4'b0001;
                3'd2:    termo = 4'b0011;
                3'd3:    termo = 4'b0111;
                3'd4:    termo = 4'b1111;
                default: termo = 4'b0000;   // 0 puan / gecersiz -> sonuk
            endcase
        end
    endfunction

    always @(*) begin
        led = 16'd0;                       // her yola varsayilan deger
        if (oyun_bitti) begin
            //  Sadece genel kazananin 4 LED'i yanik kalir.
            //  (kazanan*4) tabanli parca secimi: 0->[3:0], 1->[7:4], ...
            led[kazanan*4 +: 4] = 4'b1111;
        end else begin
            led[3:0]   = termo(puan0);
            led[7:4]   = termo(puan1);
            led[11:8]  = termo(puan2);
            led[15:12] = termo(puan3);
        end
    end

endmodule
