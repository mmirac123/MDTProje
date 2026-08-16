`timescale 1ns / 1ps
//seg7driver modulunun ekrana cubuklarla yazdirabilmesi icin binaryden bcdye ceviriyor

module bin2bcd(
    input  wire [12:0] ikili,   
    output reg  [15:0] bcd       
);

    integer i;

  
    always @(*) begin
        bcd = 16'd0;
        for (i = 12; i >= 0; i = i - 1) begin
            if (bcd[3:0]   >= 4'd5) bcd[3:0]   = bcd[3:0]   + 4'd3;
            if (bcd[7:4]   >= 4'd5) bcd[7:4]   = bcd[7:4]   + 4'd3;
            if (bcd[11:8]  >= 4'd5) bcd[11:8]  = bcd[11:8]  + 4'd3;
            if (bcd[15:12] >= 4'd5) bcd[15:12] = bcd[15:12] + 4'd3;
            bcd = {bcd[14:0], ikili[i]};//9 dan buyuk oldugunda tasma hallolsun diye 
        end
    end

endmodule
