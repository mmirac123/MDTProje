`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
//  BIL 264/265 - Cok Oyunculu Refleks Oyunu / Grup: Nazik Ormanlar
//  Modul  : debouncer      (5 kez ornekleniyor: BTNC + 4 oyuncu butonu)
//  Yazan  :
//
//  Mekanik butonun kontak ziplamasini temizler ve tek cevrimlik puls uretir.
//  Zamanlamayi kendi saymaz, timebase'in vurus_1ms nabzini kullanir.
//////////////////////////////////////////////////////////////////////////////

module debouncer #(
    parameter integer STABLE_MS = 10        // kac ms sabit kalirsa gercek sayilsin
)(
    input   clk,
    input   rst,
    input   vurus_1ms,      // timebase'den
    input   btn_ham,        // karttan gelen ham buton
    output reg  btn_seviye,     // temizlenmis seviye
    output  btn_puls        // yukselen kenarda TEK cevrimlik puls
);

    reg       senk0, senk1;     // 2 kademeli senkronizator
    reg       onceki;           // btn_seviye'nin bir onceki degeri
    reg [4:0] sayac;            // kararlilik sayaci (ms cinsinden)

    //-----------------------------------------------------------------------
    //  1) Senkronizasyon
    //     btn_ham saatle iliskisiz bir sinyal. Dogrudan mantiga sokarsan
    //     metastabilite riski var. Iki flip-flop'tan gecir.
    //-----------------------------------------------------------------------
    always @(posedge clk) begin
        senk0 <= btn_ham;
        senk1 <= senk0;

    end

    //-----------------------------------------------------------------------
    //  2) Kararlilik kontrolu
    //     - rst 1 ise            : btn_seviye ve sayac sifirlansin
    //     - senk1 != btn_seviye  : vurus_1ms geldikce sayac artsin,
    //                              STABLE_MS'e ulasinca btn_seviye guncellensin
    //     - senk1 == btn_seviye  : sayac SIFIRLANSIN (sinyal geri zipladi)
    //-----------------------------------------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            btn_seviye <= 0;
            sayac <= 0;
        end else if(senk1 == btn_seviye) begin
            sayac <= 0;
        end else if(senk1 != btn_seviye) begin
            if(vurus_1ms) begin
                if(sayac == STABLE_MS-1) begin
                    btn_seviye <= senk1;
                    sayac <= 0;
                end else begin
                    sayac <= sayac + 1;
                end
            end
        end
    end

    //-----------------------------------------------------------------------
    //  3) Kenar tespiti
    //     onceki'yi guncelle; btn_puls sadece yukselen kenarda 1 olsun.
    //-----------------------------------------------------------------------
    always @(posedge clk) begin
        onceki <= btn_seviye;
    end

    assign btn_puls = btn_seviye & ~onceki;     // <-- degistir

endmodule
