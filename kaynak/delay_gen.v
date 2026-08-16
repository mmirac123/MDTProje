`timescale 1ns / 1ps


module delay_gen(
    input  wire [15:0] lfsr_deger,
    input  wire        zor_mod,
    output wire [12:0] bekleme_ms     
);


    wire [11:0] r      = lfsr_deger[11:0];//gelen degerin 12 bitini aliyor
    wire [12:0] t_min  = zor_mod ? 13'd500  : 13'd2000;// zor modda 500 kolay modda 2000 ms
    wire [12:0] aralik = zor_mod ? 13'd4500 : 13'd3000; // zor modda 4500 normalde 3000 

    wire [24:0] carpim = r * aralik;

    
    assign bekleme_ms = t_min + carpim[24:12];

endmodule
