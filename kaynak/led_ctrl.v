`timescale 1ns / 1ps
module led_ctrl(
    input  wire [2:0]  puan0, puan1, puan2, puan3,
    input  wire        oyun_bitti,
    input  wire [1:0]  kazanan,
    output reg  [15:0] led
);

    always @(*) begin
        led = 16'd0;

        if (oyun_bitti) begin //oyun bittiginde kazananin 4 ledi de yansin
            led[kazanan*4 +: 4] = 4'b1111;
        end else begin

           //ilk oyuncu
            case (puan0)
                3'd1:    led[3:0] = 4'b0001;
                3'd2:    led[3:0] = 4'b0011;
                3'd3:    led[3:0] = 4'b0111;
                3'd4:    led[3:0] = 4'b1111;
                default: led[3:0] = 4'b0000;
            endcase

            // ikinci oyuncu
            case (puan1)
                3'd1:    led[7:4] = 4'b0001;
                3'd2:    led[7:4] = 4'b0011;
                3'd3:    led[7:4] = 4'b0111;
                3'd4:    led[7:4] = 4'b1111;
                default: led[7:4] = 4'b0000;
            endcase

            // ucuncu oyuncu
            case (puan2)
                3'd1:    led[11:8] = 4'b0001;
                3'd2:    led[11:8] = 4'b0011;
                3'd3:    led[11:8] = 4'b0111;
                3'd4:    led[11:8] = 4'b1111;
                default: led[11:8] = 4'b0000;
            endcase

            //dorduncu oyuncu
            case (puan3)
                3'd1:    led[15:12] = 4'b0001;
                3'd2:    led[15:12] = 4'b0011;
                3'd3:    led[15:12] = 4'b0111;
                3'd4:    led[15:12] = 4'b1111;
                default: led[15:12] = 4'b0000;
            endcase

        end
    end
endmodule
