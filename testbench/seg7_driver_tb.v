`timescale 1ns / 1ps
//  seg7_driver_tb - dalga formuna bak. Yazan:
//  Kontrol: disp_sel doner mi, an dogru basamagi mi seciyor,
//           basamak_en 0 olan basamak gercekten sonuk mu.

module seg7_driver_tb;
    reg  [1:0] disp_sel = 2'd0;
    reg  [3:0] d0 = 4'd1, d1 = 4'd2, d2 = 4'd3, d3 = 4'd4;
    reg  [3:0] basamak_en = 4'b1111;
    wire [6:0] seg;
    wire [3:0] an;

    seg7_driver uut (.disp_sel(disp_sel), .d0(d0), .d1(d1), .d2(d2), .d3(d3),
                     .basamak_en(basamak_en), .seg(seg), .an(an));

    initial begin
        // YAZILACAK:
        //   disp_sel'i 0,1,2,3 yapip her birinde an ve seg'i kontrol et
        //   sonra basamak_en = 4'b0011 yapip ust iki basamagin sondugunu gor
    end
endmodule
