`timescale 1ns / 1ps
//  uart_tx - tek bayti seri hatta gonderir. 9600 baud, 8n1.     yazan:
//    1 start biti (0) + 8 veri biti (lsb once) + 1 stop biti (1)
//    bit suresi = 100.000.000 / 9600 = 10417 cevrim
//
//  once bunu dogrula: sonsuz dongude tek bir 'a' (8'h41) gonderip
//  terminalde gor. calismadan ustune metin uretme.
module uart_tx #(
    parameter integer CLKS_PER_BIT = 10417   // simulasyonda kucult
)(
    input  wire       clk, rst,
    input  wire       gonder,          // tek cevrimlik puls
    input  wire [7:0] veri,
    output reg        tx,              // bostayken 1
    output reg        mesgul
);
    localparam BOS = 2'd0, START = 2'd1, VERI = 2'd2, STOP = 2'd3;
    reg [1:0]  durum;
    reg [13:0] sayac;
    reg [2:0]  bit_no;
    reg [7:0]  kaydirma;
    always @(posedge clk) begin
        if (rst) begin
            durum    <= BOS;
            tx       <= 1'b1;
            mesgul   <= 1'b0;
            sayac    <= 14'd0;
            bit_no   <= 3'd0;
            kaydirma <= 8'd0;
        end else begin
            case (durum)
            //---------------------------------------------------------------
            //  bos : hat bosta (1). gonder gelirse start bitini bas.
            //---------------------------------------------------------------
            BOS: begin
                tx     <= 1'b1;
                mesgul <= 1'b0;
                sayac  <= 14'd0;
                bit_no <= 3'd0;
                if (gonder) begin
                    kaydirma <= veri;
                    tx       <= 1'b0;      // start biti
                    mesgul   <= 1'b1;
                    durum    <= START;
                end
            end
            //---------------------------------------------------------------
            //  start : bir bit suresi bekle, sonra ilk veri bitini (lsb) koy
            //---------------------------------------------------------------
            START: begin
                if (sayac == CLKS_PER_BIT - 1) begin
                    sayac  <= 14'd0;
                    tx     <= kaydirma[0];
                    bit_no <= 3'd0;
                    durum  <= VERI;
                end else begin
                    sayac <= sayac + 14'd1;
                end
            end
            //---------------------------------------------------------------
            //  veri : 8 bit, lsb once
            //---------------------------------------------------------------
            VERI: begin
                if (sayac == CLKS_PER_BIT - 1) begin
                    sayac <= 14'd0;
                    if (bit_no == 3'd7) begin
                        tx    <= 1'b1;     // stop biti
                        durum <= STOP;
                    end else begin
                        tx     <= kaydirma[bit_no + 3'd1];
                        bit_no <= bit_no + 3'd1;
                    end
                end else begin
                    sayac <= sayac + 14'd1;
                end
            end
            //---------------------------------------------------------------
            //  stop : bir bit suresi 1 tut, sonra bosa don
            //---------------------------------------------------------------
            STOP: begin
                tx <= 1'b1;
                if (sayac == CLKS_PER_BIT - 1) begin
                    sayac  <= 14'd0;
                    mesgul <= 1'b0;
                    durum  <= BOS;
                end else begin
                    sayac <= sayac + 14'd1;
                end
            end
            endcase
        end
    end
endmodule
