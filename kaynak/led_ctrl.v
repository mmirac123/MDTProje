`timescale 1ns / 1ps


module led_ctrl(
    input  wire [2:0]  puan0, puan1, puan2, puan3,
    input  wire        oyun_bitti,
    input  wire [1:0]  kazanan,
    output reg  [15:0] led
);

  
    function [3:0] termo(input [2:0] p);
        begin
            case (p)
                3'd1:    termo = 4'b0001;
                3'd2:    termo = 4'b0011;
                3'd3:    termo = 4'b0111;
                3'd4:    termo = 4'b1111;
                default: termo = 4'b0000;   
            endcase
        end
    endfunction

    always @(*) begin
        led = 16'd0;                      
        if (oyun_bitti) begin
      
            led[kazanan*4 +: 4] = 4'b1111;
        end else begin
            led[3:0]   = termo(puan0);
            led[7:4]   = termo(puan1);
            led[11:8]  = termo(puan2);
            led[15:12] = termo(puan3);
        end
    end

endmodule
