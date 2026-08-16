`timescale 1ns / 1ps
//  delay_gen - LFSR'nin ham sayisini bekleme suresine olcekler.   Yazan:
//  Kolay mod: 2000-5000 ms   |   Zor mod: 500-5000 ms
//  Tamamen kombinasyonel, saat kullanmaz.

module delay_gen(
    input  wire [15:0] lfsr_deger,
    input  wire        zor_mod,
    output wire [12:0] bekleme_ms     // 500..5000  (13 bit yeter)
);

    //   r      = lfsr_deger'in alt 12 biti            -> 0..4095
    //   t_min  = zor_mod ? 500  : 2000
    //   aralik = zor_mod ? 4500 : 3000
    //   bekleme_ms = t_min + ((r * aralik) >> 12)
    //
    // NOT: bolme kullanma, sentezde pahali. Sabitle carpip saga kaydir.
    //      >>12 ile bolmek, 4096'ya bolmekle ayni sey; Vivado carpmayi
    //      DSP blokuna atar, kaydirma ise bedava (sadece tel secimi).

    wire [11:0] r      = lfsr_deger[11:0];
    wire [12:0] t_min  = zor_mod ? 13'd500  : 13'd2000;
    wire [12:0] aralik = zor_mod ? 13'd4500 : 13'd3000;

    //  En kotu durum: 4095 * 4500 = 18_427_500  ->  25 bit yeter
    wire [24:0] carpim = r * aralik;

    //  Uc degerler:  r=0    -> t_min
    //                r=4095 -> kolay 4999 , zor 4999
    assign bekleme_ms = t_min + carpim[24:12];

endmodule
