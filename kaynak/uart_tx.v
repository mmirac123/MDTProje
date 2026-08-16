`timescale 1ns / 1ps
//  uart_tx - tek bayti seri hatta gonderir. 9600 baud, 8N1.     Yazan:
//    1 start biti (0) + 8 veri biti (LSB once) + 1 stop biti (1)
//    Bit suresi = 100.000.000 / 9600 = 10417 cevrim
//
//  ONCE BUNU DOGRULA: sonsuz dongude tek bir 'A' (8'h41) gonderip
//  terminalde gor. Calismadan ustune metin uretme.

module uart_tx #(
    parameter integer CLKS_PER_BIT = 10417   // simulasyonda kucult
)(
    input  wire       clk, rst,
    input  wire       gonder,          // TEK cevrimlik puls
    input  wire [7:0] veri,
    output reg        tx,              // bostayken 1
    output reg        mesgul
);

    localparam BOS = 2'd0, START = 2'd1, VERI = 2'd2, STOP = 2'd3;

    reg [1:0]  durum;
    reg [13:0] sayac;
    reg [2:0]  bit_no;
    reg [7:0]  kaydirma;

    // YAZILACAK: 4 durumlu FSM
    //   BOS  : tx=1, mesgul=0 ; gonder gelirse veri'yi kaydirma'ya al,
    //          tx=0 (start biti), mesgul=1, START'a gec
    //   START: CLKS_PER_BIT cevrim say, sonra ilk veri bitini tx'e koy
    //   VERI : her CLKS_PER_BIT'te bir sonraki biti tx'e koy (toplam 8)
    //   STOP : tx=1, bir bit suresi bekle, BOS'a don
    always @(posedge clk) begin

    end

endmodule
