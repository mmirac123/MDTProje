`timescale 1ns / 1ps


module debouncer #(
    parameter integer KARARLI_MS = 10        // basma isleminin kac ms araliksiz gerceklestiginde gecerli sayilacagini gosterir.
)(
    input   clk,
    input   rst,
    input   vurus_1ms,      // timebase modulunden geliyor
    input   btn_ham,        // karttan gelen ham basma sinyali
    output reg  btn_seviye,     // temizlenmis basma
    output  btn_vurusu        // yukselen kenarya tek vurusluk sinyal 
);

    reg       senk0, senk1;     // 2 kademeli senkronizator
    reg       onceki;           // btn_seviye'nin bir onceki degeri
    reg [4:0] sayac;            // kararlilik sayaci (ms cinsinden)


    //2 flip flop metastabiliteyi engeller ve daha kararli sinyal alinmasini saglar. ama hata ihtimalini tam sifirlayamaz.
    //butonun yanlis karari oyunu direkt olarak probleme sokar
    always @(posedge clk) begin
        senk0 <= btn_ham;
        senk1 <= senk0;

    end

    //senkronizasyon ve 1ms'te gerceklestirme icin if bloklari
    //senkron reset
    always @(posedge clk) begin
        if(rst) begin
            btn_seviye <= 0;
            sayac <= 0;
        end else if(senk1 == btn_seviye) begin //eger sinyal temiz degeriyle ayniysa yapmak gereken bir sey yok.
            sayac <= 0;
        end else if(senk1 != btn_seviye) begin
            if(vurus_1ms) begin
                if(sayac == KARARLI_MS-1) begin
                    btn_seviye <= senk1;
                    sayac <= 0;
                end else begin
                    sayac <= sayac + 1;
                end
            end
        end
    end

    //yukselen kenar kontrolu
    always @(posedge clk) begin
        onceki <= btn_seviye;
    end
    
    //buton seviyesinde ve 1'de ise 1 atasin
    assign btn_vurusu = btn_seviye & ~onceki;    

endmodule