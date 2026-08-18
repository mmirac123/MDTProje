`timescale 1ns / 1ps


module timebase #(

    parameter integer MS_BOLEN = 100_000 //1ms icin
)(
    input  wire       clk,        
    input  wire       rst,        
    output reg        vurus_1ms,   
    output wire [1:0] hane_sec    
);

//modulun amaci 1ms'te bir izin uretmek yeni bir saat uretmiyor. yeni saat uretmek demek mantikla yeni saat uretmek demek ve bu da gecikme vs. yapar


    reg [16:0] ms_sayac;        // 1 ms sayaci
    reg [17:0] tarama_sayac = 0;      

    //senkron reset
    always @(posedge clk) begin
        if(rst) begin
            ms_sayac <= 0;
            vurus_1ms <= 0;
        end else if(ms_sayac == MS_BOLEN -1) begin // burda 1ms'ten tam 1 onceki cevrim islem yapiliyor sonraki cevrim 1ms olsun diye.
            ms_sayac <= 0;
            vurus_1ms <= 1;
        end else begin
            ms_sayac <= ms_sayac + 1;
            vurus_1ms <= 0;
        end

    end

    //bu hep artsin.
    always @(posedge clk) begin
        tarama_sayac <= tarama_sayac + 1;
    end

    //???
    assign hane_sec = tarama_sayac[17:16];

endmodule