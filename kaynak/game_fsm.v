`timescale 1ns / 1ps


module game_fsm(
    input  wire        clk, rst, vurus_1ms,

    input  wire        baslat_vurusu,
    input  wire [15:0] sw,               // konfigurasyon switch'leri
    input  wire [15:0] lfsr_deger,
    input  wire [12:0] bekleme_ms,       // delay_gen'den
    input  wire        tur_hazir,        // reaction_capture'dan
    input  wire        rapor_bitti,      // uart_reporter'dan
    input  wire [3:0]  yasayan,          // score_accum'dan

    output reg  [3:0]  oynayanlar,     
    output reg  [4:0]  tur_sayisi,       
    output reg         eleme_modu,
    output reg         zor_mod,

    output reg  [3:0]  basamak_acik,       // seg7_driver
    output wire [3:0]  d0, d1, d2, d3,   

    output reg         hazirlik,
    output reg         olcum_aktif,
    output reg         t0,               // 1 clk
    output reg  [4:0]  tur_no,
    output reg         tur_sonu,         // 1 clk
    output reg         oyun_bitti,
    output reg         uart_basla,
    output reg         uart_son_rapor
);

   
    localparam D_AYAR   = 3'd0,
               D_ANIMASYON      = 3'd2,
               D_GERI_SAYIM   = 3'd3,
               D_OLCUM = 3'd4,
               D_SONUC   = 3'd5,
               D_SONRAKI_TUR     = 3'd6,
               D_OYUN_SONU     = 3'd7;

    localparam [12:0] ANIMASYON_MS = 13'd400;      // her animasyon adimi 400 ms

    localparam [12:0] SON_GOSTERIM_MS = 13'd3000;// son gösterim 3 saniye

    reg [2:0]  durum;
    reg [12:0] zaman;          
    reg [12:0] hedef;          
    reg [1:0]  animasyon_adim;           
    reg [2:0]  rapor_faz;       

    wire [3:0] kalan   = yasayan & oynayanlar;
    wire [2:0] kalan_sayisi = {2'd0, kalan[0]} + {2'd0, kalan[1]} +
                         {2'd0, kalan[2]} + {2'd0, kalan[3]};

    wire son_tur   = (tur_no >= tur_sayisi);
    wire tek_kisi  = eleme_modu && (kalan_sayisi <= 3'd1);
    wire oyun_sonu = son_tur || tek_kisi;


    wire [3:0] sw_oynayanlar = (sw[12:11] == 2'b00) ? 4'b0011 :
                          (sw[12:11] == 2'b01) ? 4'b0111 : 4'b1111;
    wire [4:0] sw_tur   = {1'b0, sw[3:0]} + 5'd1;       // 0000->1 , 1111->16

    always @(posedge clk) begin
        if (rst) begin
            durum          <= D_AYAR; //always blogu her çalýþtýðýnda aynanda deðiþsin diye = yerine <=
            zaman          <= 13'd0;
            hedef          <= 13'd0;
            animasyon_adim           <= 2'd0;
            rapor_faz       <= 3'd0;
            oynayanlar   <= 4'b0011;
            tur_sayisi     <= 5'd1;
            eleme_modu     <= 1'b0;
            zor_mod        <= 1'b0;
            tur_no         <= 5'd1;
            basamak_acik     <= 4'b0000;
            hazirlik        <= 1'b0;
            olcum_aktif        <= 1'b0;
            t0             <= 1'b0;
            tur_sonu       <= 1'b0;
            oyun_bitti     <= 1'b0;
            uart_basla     <= 1'b0;
            uart_son_rapor <= 1'b0;
        end else begin
            //  Pulsler varsayilan olarak 0; ilgili durumda 1 cevrim yukselir
            t0         <= 1'b0;
            tur_sonu   <= 1'b0;
            uart_basla <= 1'b0;

            case (durum)

        
            D_AYAR: begin //ayarlar kýsmý 
                basamak_acik   <= 4'b1011;
                hazirlik      <= 1'b0;
                olcum_aktif      <= 1'b0;
                oyun_bitti   <= 1'b0;
                zaman        <= 13'd0;
                animasyon_adim         <= 2'd0;
                tur_no       <= 5'd1;

                oynayanlar <= sw_oynayanlar;
                tur_sayisi   <= sw_tur;
                eleme_modu   <= sw[14];
                zor_mod      <= sw[13];

                if (baslat_vurusu) begin // orta tuþa basýlýp baþlatma
                    hedef      <= bekleme_ms;   
                    basamak_acik <= 4'b0001;     
                    hazirlik    <= 1'b1;        
                    durum      <= D_ANIMASYON;
                end
            end


           D_ANIMASYON: begin 
    if (vurus_1ms) begin
        if (zaman == ANIMASYON_MS - 13'd1) begin
            zaman <= 13'd0;

            if (animasyon_adim == 2'd0) begin
                basamak_acik <= 4'b0011;
                animasyon_adim       <= 2'd1;
            end else if (animasyon_adim == 2'd1) begin
                basamak_acik <= 4'b0111;
                animasyon_adim       <= 2'd2;
            end else if (animasyon_adim == 2'd2) begin
                basamak_acik <= 4'b1111;
                animasyon_adim       <= 2'd3;
            end else if (animasyon_adim == 2'd3) begin
                basamak_acik <= 4'b1111;
                durum      <= D_GERI_SAYIM;
            end

        end else begin
            zaman <= zaman + 13'd1;
        end
    end
end



            D_GERI_SAYIM: begin
                basamak_acik <= 4'b1111;
                hazirlik    <= 1'b1;
                if (vurus_1ms) begin
                    if (zaman >= hedef) begin
                        zaman      <= 13'd0;
                        basamak_acik <= 4'b0000;   // ekran boþ
                        hazirlik    <= 1'b0;
                        olcum_aktif    <= 1'b1;
                        t0         <= 1'b1;      
                        durum      <= D_OLCUM;
                    end else begin
                        zaman <= zaman + 13'd1;
                    end
                end
            end

            D_OLCUM: begin
                basamak_acik <= 4'b0000;
                hazirlik    <= 1'b0;
                olcum_aktif    <= 1'b1;
                if (tur_hazir) begin
                    olcum_aktif  <= 1'b0;
                    tur_sonu <= 1'b1;        // score_accum bu pulsu bekliyor
                    rapor_faz <= 3'd0;
                    durum    <= D_SONUC;
                end
            end

         
            D_SONUC: begin
                basamak_acik <= 4'b0000;//ekraný kapat
                hazirlik    <= 1'b0;//elenme kapalý
                olcum_aktif    <= 1'b0;//tur bitti tuþlar deaktif
                case (rapor_faz)
                    3'd0: rapor_faz <= 3'd1; // flip floplarýn sonucu yansýtabilmesi için 1 clk bekletme
                    3'd1: begin
                        uart_basla     <= 1'b1;
                        uart_son_rapor <= oyun_sonu;
                        rapor_faz       <= 3'd2;
                    end
                    3'd2: rapor_faz <= 3'd3;// uart raporunun baþla darbesini bitti yapmasý için bekleme 1 clk
                    3'd3: if (rapor_bitti) begin
                        if (oyun_sonu) begin//oyun sonu geldiyse sýralama gösterimi baþla
                            zaman    <= 13'd0; // sayac 0
                            rapor_faz <= 3'd4; 
                        end else begin //oyun sonu gelmesiyse bir sonraki tura geç
                            durum <= D_SONRAKI_TUR;
                        end
                    end
                    default: begin // sýrlama gösterimi 3(son gosterim ms) saniye bekleme süresi
                       if (vurus_1ms) begin
                            if (zaman >= SON_GOSTERIM_MS) durum <= D_OYUN_SONU;
                            else                          zaman <= zaman + 13'd1;
                        end
                    end
                endcase
            end

            D_SONRAKI_TUR: begin
                basamak_acik <= 4'b0000;
                hazirlik    <= 1'b0;
                olcum_aktif    <= 1'b0;
                zaman      <= 13'd0;
                animasyon_adim       <= 2'd0;
                if (baslat_vurusu) begin
                    tur_no     <= tur_no + 5'd1;
                    hedef      <= bekleme_ms;   // lsfr seçiyo
                    basamak_acik <= 4'b0001;
                    hazirlik    <= 1'b1;
                    durum      <= D_ANIMASYON;
                end
            end

           
            D_OYUN_SONU: begin
                oyun_bitti <= 1'b1;
                basamak_acik <= 4'b0000;
                hazirlik    <= 1'b0;
                olcum_aktif    <= 1'b0;
            end

            
            default: durum <= D_AYAR;

            endcase
        end
    end

    wire [3:0] taban  = tur_no[0] ? 4'd1 : 4'd5;// taban = 1 ise tek turlar, taban = 5 ise çift turlar

    wire [3:0] oyuncu_sayisi = oynayanlar[3] ? 4'd4 :
                        oynayanlar[2] ? 4'd3 : 4'd2;// oyuncu sayýsý 

    wire       onlar_var = (tur_sayisi >= 5'd10);// onlar basamaðý tespiti
    wire [4:0] tur_birler = onlar_var ? (tur_sayisi - 5'd10) : tur_sayisi;// birler basamaðýný bulma
//7 seg çýkýþlarý
    assign d0 = (durum == D_AYAR) ? tur_birler[3:0]        : taban;// en saðdaki basamak
    assign d1 = (durum == D_AYAR) ? (onlar_var ? 4'd1 : 4'd0) : (taban + 4'd1);// onlar basamaðý
    assign d2 = (durum == D_AYAR) ? 4'd0               : (taban + 4'd2);// boþ
    assign d3 = (durum == D_AYAR) ? oyuncu_sayisi             : (taban + 4'd3);// oyuncu sayýsý

endmodule