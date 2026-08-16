`timescale 1ns / 1ps


module seg7_driver(
    input  wire [1:0] hane_say ,//sira kimde 
    input  wire [3:0] d0, d1, d2, d3,   
    input  wire [3:0] basamak_en, //hangi hanelerin acik olacagi     
    output reg  [6:0] seg,              
    output reg  [3:0] an                
);

    reg [3:0] rakam;

    always @(*) begin
       
        case (hane_say) //hane say degerine bagli olarak rakama deger esledik
            2'd0:    rakam = d0;
            2'd1:    rakam = d1;
            2'd2:    rakam = d2;
            default: rakam = d3;
        endcase

        
        an = 4'b1111; //hepsi kapali duruma alindi
        if (basamak_en[hane_say])
            an[hane_say] = 1'b0;//siradakini kontrol et

        
        case (rakam)
            4'd0:    seg = 7'b1000000;//verilen rakamlarda hangi cubuklar yansin ki o sayi gozuksun kismi
            4'd1:    seg = 7'b1111001;
            4'd2:    seg = 7'b0100100;
            4'd3:    seg = 7'b0110000;
            4'd4:    seg = 7'b0011001;
            4'd5:    seg = 7'b0010010;
            4'd6:    seg = 7'b0000010;
            4'd7:    seg = 7'b1111000;
            4'd8:    seg = 7'b0000000;
            4'd9:    seg = 7'b0011000;
            default: seg = 7'b1111111;  //9 dan buyuk bi sayi gelirse yapma  
        endcase
    end

endmodule
