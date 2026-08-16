`timescale 1ns / 1ps


module timebase #(

    parameter integer MS_DIV = 100_000
)(
    input  wire       clk,        // W5, 100 MHz
    input  wire       rst,        // SW15, seviye, senkron kullanilacak
    output reg        vurus_1ms,   // TAM 1 cevrim genisliginde nabiz
    output wire [1:0] disp_sel    // 0->1->2->3->0 , serbest kosar
);


    reg [16:0] ms_sayac;        // 1 ms sayaci
    reg [17:0] scan_sayac = 0;      // 7-segment tarama sayaci (serbest kosar)


    always @(posedge clk) begin
        if(rst) begin
            ms_sayac <= 0;
            vurus_1ms <= 0;
        end else if(ms_sayac == MS_DIV -1) begin
            ms_sayac <= 0;
            vurus_1ms <= 1;
        end else begin
            ms_sayac <= ms_sayac + 1;
            vurus_1ms <= 0;
        end

    end


    always @(posedge clk) begin
        scan_sayac <= scan_sayac + 1;
    end


    assign disp_sel = scan_sayac[17:16];

endmodule
