`timescale 1ns / 1ps
//  delay_gen - LFSR'nin ham sayisini bekleme suresine olcekler.   Yazan:
//  Kolay mod: 2000-5000 ms   |   Zor mod: 500-5000 ms
//  Tamamen kombinasyonel, saat kullanmaz.

module delay_gen(
    input  wire [15:0] lfsr_deger,
    input  wire        zor_mod,
    output wire [12:0] bekleme_ms     // 500..5000  (13 bit yeter)
);

    // YAZILACAK:
    //   r      = lfsr_deger'in alt 12 biti            -> 0..4095
    //   t_min  = zor_mod ? 500  : 2000
    //   aralik = zor_mod ? 4500 : 3000
    //   bekleme_ms = t_min + ((r * aralik) >> 12)
    //
    // NOT: bolme kullanma, sentezde pahali. Sabitle carpip saga kaydir.

    assign bekleme_ms = 13'd0;      // <-- degistir

endmodule
