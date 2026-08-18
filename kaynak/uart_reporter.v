`timescale 1ns / 1ps


module uart_reporter(
    input  wire        clk, rst,
    input  wire        basla,            
    input  wire        son_rapor,        // 1se kazanan veys beraberlik mesaji basiliyor

    input  wire [4:0]  tur_no,
    input  wire [12:0] sure0, sure1, sure2, sure3,
    input  wire [2:0]  puan0, puan1, puan2, puan3,
    input  wire [6:0]  toplam0, toplam1, toplam2, toplam3,
    input  wire [3:0]  yanlis_baslangic, zaman_asimi, oynayanlar,
    input  wire [1:0]  kazanan,
    input  wire        beraberlik,

    input  wire        tx_mesgul,
    output reg         tx_gonder,
    output reg  [7:0]  tx_veri,
    output reg         bitti
);


    //  adres cozumu
    
    reg [8:0] adim;      // metinde kacinci bayttayiz 
    reg       calisiyor;
    reg [1:0] faz;       

    wire [3:0] satir  = adim[8:5];
    wire [4:0] sutun = adim[4:0];
    wire [4:0] metin_i     = (sutun > 5'd29) ? 5'd29 : sutun;   // string indeksine cevir
    wire [3:0] durum_i    = sutun - 5'd4;                      // durum alani icin yerel indeks

  
    localparam [8:0] BAYT_TUR_SONU = 9'd224;   
    localparam [8:0] BAYT_OYUN_SONU       = 9'd288;   
    localparam [8:0] BAYT_BERABERLIK    = 9'd320;   

    wire [8:0] toplam_bayt = son_rapor ? (beraberlik ? BAYT_BERABERLIK : BAYT_OYUN_SONU)
                                       : BAYT_TUR_SONU;


    //  sabit satir kaliplari
    
    wire [239:0] SATIR_TUR = "TUR 00                        ";
    wire [239:0] SATIR_OYUNCU = " P0             PUAN 0        ";
    wire [239:0] SATIR_TOPLAM = "TOPLAM P1=00 P2=00 P3=00 P4=00";
    wire [239:0] SATIR_BOS = "                              ";
    wire [239:0] SATIR_BITTI = "==== OYUN BITTI ====          ";
    wire [239:0] SATIR_KAZANAN = "KAZANAN P0 (00 PUAN)          ";
    wire [239:0] SATIR_BERABERLIK = "BERABERLIK (00 PUAN)          ";
    wire [239:0] SATIR_ESITLER = "BERABER: P1 P2 P3 P4          ";

    //  oyuncu satirindaki durum yazisi
    wire [87:0] DURUM_YOK   = "OYNAMIYOR  ";
    wire [87:0] DURUM_ERKEN = "FALSESTART ";
    wire [87:0] DURUM_ZAMAN  = "TIMEOUT    ";
    wire [87:0] DURUM_ELENDI  = "ELENDI     ";

    
    reg [12:0] bu_sure;
    reg [2:0]  bu_puan;
    reg        bu_yanlis, bu_zaman, bu_var;

    always @(*) begin
        case (satir)
            4'd1: begin bu_sure=sure0; bu_puan=puan0; bu_yanlis=yanlis_baslangic[0];
                        bu_zaman=zaman_asimi[0]; bu_var=oynayanlar[0]; end
            4'd2: begin bu_sure=sure1; bu_puan=puan1; bu_yanlis=yanlis_baslangic[1];
                        bu_zaman=zaman_asimi[1]; bu_var=oynayanlar[1]; end
            4'd3: begin bu_sure=sure2; bu_puan=puan2; bu_yanlis=yanlis_baslangic[2];
                        bu_zaman=zaman_asimi[2]; bu_var=oynayanlar[2]; end
            default: begin bu_sure=sure3; bu_puan=puan3; bu_yanlis=yanlis_baslangic[3];
                        bu_zaman=zaman_asimi[3]; bu_var=oynayanlar[3]; end
        endcase
    end

    //  kazananin toplam puani
    reg [6:0] kazanan_toplam;
    always @(*) begin
        case (kazanan)
            2'd0:    kazanan_toplam = toplam0;
            2'd1:    kazanan_toplam = toplam1;
            2'd2:    kazanan_toplam = toplam2;
            default: kazanan_toplam = toplam3;
        endcase
    end


    wire [3:0] lider = { oynayanlar[3] && (toplam3 == kazanan_toplam),
                        oynayanlar[2] && (toplam2 == kazanan_toplam),
                        oynayanlar[1] && (toplam1 == kazanan_toplam),
                        oynayanlar[0] && (toplam0 == kazanan_toplam) };

    

    reg  [12:0] bcd_giris;
    wire [15:0] bcd_cikis;

    bin2bcd u_bcd (.ikili(bcd_giris), .bcd(bcd_cikis));

    always @(*) begin
        case (satir)
            4'd0: bcd_giris = {8'd0, tur_no};                    
            4'd1, 4'd2, 4'd3, 4'd4: bcd_giris = bu_sure;          
            4'd5: bcd_giris = (sutun < 5'd12) ? {6'd0, toplam0} : 
                              (sutun < 5'd18) ? {6'd0, toplam1} :
                              (sutun < 5'd24) ? {6'd0, toplam2} :
                                                {6'd0, toplam3};
            4'd8: bcd_giris = {6'd0, kazanan_toplam};                
            default: bcd_giris = 13'd0;
        endcase
    end

    reg [7:0] bayt;

    always @(*) begin
        bayt = 8'h20;                                

        case (satir)

        4'd0: begin
            bayt = SATIR_TUR[8*(29-metin_i) +: 8];
            if (sutun == 5'd4) bayt = 8'h30 + bcd_cikis[7:4];
            if (sutun == 5'd5) bayt = 8'h30 + bcd_cikis[3:0];
        end

        4'd1, 4'd2, 4'd3, 4'd4: begin
            bayt = SATIR_OYUNCU[8*(29-metin_i) +: 8];

            if (sutun == 5'd2) bayt = 8'h30 + {4'd0, satir};      

            if ((sutun >= 5'd4) && (sutun <= 5'd14)) begin
                if (!bu_var)                                      // hic oyunda degilse
                    bayt = DURUM_YOK[8*(10-durum_i) +: 8];
                else if (bu_yanlis)                                // erkenden basmis
                    bayt = DURUM_ERKEN[8*(10-durum_i) +: 8];
                else if (bu_zaman)                                 // hic basmadan suresi dolmus
                    bayt = DURUM_ZAMAN[8*(10-durum_i) +: 8];
                else if (bu_puan == 3'd0)                          // elenmis puani sifirlanmis
                    bayt = DURUM_ELENDI[8*(10-durum_i) +: 8];
                else begin                                        // her sey normal NNNN ms yaz
                    case (durum_i)
                        4'd0:    bayt = 8'h30 + bcd_cikis[15:12];
                        4'd1:    bayt = 8'h30 + bcd_cikis[11:8];
                        4'd2:    bayt = 8'h30 + bcd_cikis[7:4];
                        4'd3:    bayt = 8'h30 + bcd_cikis[3:0];
                        4'd5:    bayt = "m";
                        4'd6:    bayt = "s";
                        default: bayt = " ";
                    endcase
                end
            end

            if (sutun == 5'd21) bayt = 8'h30 + {5'd0, bu_puan};
        end

        
        4'd5: begin
            bayt = SATIR_TOPLAM[8*(29-metin_i) +: 8];
            if ((sutun == 5'd10) || (sutun == 5'd16) ||
                (sutun == 5'd22) || (sutun == 5'd28))
                bayt = 8'h30 + bcd_cikis[7:4];
            if ((sutun == 5'd11) || (sutun == 5'd17) ||
                (sutun == 5'd23) || (sutun == 5'd29))
                bayt = 8'h30 + bcd_cikis[3:0];
        end

        4'd6: bayt = SATIR_BOS[8*(29-metin_i) +: 8];

        4'd7: bayt = SATIR_BITTI[8*(29-metin_i) +: 8];

        4'd8: begin
            bayt = beraberlik ? SATIR_BERABERLIK[8*(29-metin_i) +: 8] : SATIR_KAZANAN[8*(29-metin_i) +: 8];
            if (!beraberlik && (sutun == 5'd9))
                bayt = 8'h31 + {6'd0, kazanan};       
            if (sutun == 5'd12) bayt = 8'h30 + bcd_cikis[7:4];
            if (sutun == 5'd13) bayt = 8'h30 + bcd_cikis[3:0];
        end

        4'd9: begin
            bayt = SATIR_ESITLER[8*(29-metin_i) +: 8];
            if ((sutun == 5'd9)  || (sutun == 5'd10)) bayt = lider[0] ? bayt : " ";
            if ((sutun == 5'd12) || (sutun == 5'd13)) bayt = lider[1] ? bayt : " ";
            if ((sutun == 5'd15) || (sutun == 5'd16)) bayt = lider[2] ? bayt : " ";
            if ((sutun == 5'd18) || (sutun == 5'd19)) bayt = lider[3] ? bayt : " ";
        end

        default: bayt = 8'h20;

        endcase

        if (sutun == 5'd30) bayt = 8'h0D;
        if (sutun == 5'd31) bayt = 8'h0A;
    end


    //  sira makinesi

    
    localparam [4:0] OTURMA = 5'd16;

    reg [4:0] otur;

    always @(posedge clk) begin
        if (rst) begin
            adim      <= 9'd0;
            calisiyor <= 1'b0;
            faz        <= 2'd0;
            otur      <= 5'd0;
            tx_gonder <= 1'b0;
            tx_veri   <= 8'd0;
            bitti     <= 1'b0;
        end else begin
            tx_gonder <= 1'b0;

            if (basla) begin
                adim      <= 9'd0;
                calisiyor <= 1'b1;
                faz        <= 2'd0;
                otur      <= 5'd0;
                bitti     <= 1'b0;
            end else if (calisiyor) begin
                case (faz)
                    2'd0: if (otur != OTURMA) begin
                              otur <= otur + 5'd1;      
                          end else if (!tx_mesgul) begin
                              tx_veri   <= bayt;
                              tx_gonder <= 1'b1;
                              faz        <= 2'd1;
                          end
                    2'd1: faz <= 2'd2;
                    2'd2: if (tx_mesgul) faz <= 2'd3;
                    default: if (!tx_mesgul) begin
                                 if (adim + 9'd1 == toplam_bayt) begin
                                     calisiyor <= 1'b0;
                                     bitti     <= 1'b1;
                                 end else begin
                                     adim <= adim + 9'd1;
                                 end
                                 otur <= 5'd0;          
                                 faz   <= 2'd0;
                             end
                endcase
            end
        end
    end

endmodule
