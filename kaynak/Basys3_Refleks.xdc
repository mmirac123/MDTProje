## =============================================================================
##  BIL 264/265 - Cok Oyunculu Refleks Oyunu
##  Grup: Nazik Ormanlar
##  Kart: Digilent Basys 3  (Artix-7  xc7a35tcpg236-1)
##
##  KAYNAK HARITASI (proje tanimi geregi burada belirtilmistir):
##    SW15          -> Reset            (1 = reset)
##    SW14          -> Eleme modu       (1 = acik)
##    SW13          -> Zorluk           (0 = kolay 2.0-5.0 s, 1 = zor 0.5-5.0 s)
##    SW12, SW11    -> Oyuncu sayisi    (00->2, 01->3, 10->4, 11->4)
##    SW3..SW0      -> Tur sayisi N     (oynanan tur = N+1 ; 0000->1, 1111->16)
##    BTNC          -> Ayarlari kaydet / turu baslat
##    BTNU/L/R/D    -> Oyuncu 1 / 2 / 3 / 4
##    LED0-3        -> Oyuncu 1 siralama gostergesi
##    LED4-7        -> Oyuncu 2 siralama gostergesi
##    LED8-11       -> Oyuncu 3 siralama gostergesi
##    LED12-15      -> Oyuncu 4 siralama gostergesi
##    RsTx (A18)    -> UART cikisi, 9600 baud 8N1
## =============================================================================

## ---- Clock : 100 MHz -------------------------------------------------------
set_property PACKAGE_PIN W5 [get_ports clk]
    set_property IOSTANDARD LVCMOS33 [get_ports clk]
    create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## ---- Slide switches --------------------------------------------------------
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2  [get_ports {sw[8]}]
set_property PACKAGE_PIN T3  [get_ports {sw[9]}]
set_property PACKAGE_PIN T2  [get_ports {sw[10]}]
set_property PACKAGE_PIN R3  [get_ports {sw[11]}]
set_property PACKAGE_PIN W2  [get_ports {sw[12]}]
set_property PACKAGE_PIN U1  [get_ports {sw[13]}]
set_property PACKAGE_PIN T1  [get_ports {sw[14]}]
set_property PACKAGE_PIN R2  [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]

## ---- LEDs ------------------------------------------------------------------
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## ---- 7-Segment : katot (segment) hatlari, AKTIF-DUSUK -----------------------
##  seg[0]=CA  seg[1]=CB  seg[2]=CC  seg[3]=CD  seg[4]=CE  seg[5]=CF  seg[6]=CG
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

## Ondalik nokta (kullanmiyorsaniz top'ta 1'b1'e baglayin, yoksa surekli yanar)
set_property PACKAGE_PIN V7 [get_ports nokta]
    set_property IOSTANDARD LVCMOS33 [get_ports nokta]

## ---- 7-Segment : anot (basamak secme) hatlari, AKTIF-DUSUK ------------------
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[*]}]

## ---- Butonlar (basili degilken 0, basiliyken 1) -----------------------------
set_property PACKAGE_PIN U18 [get_ports btnC]     ;# baslat / tur ilerlet
set_property PACKAGE_PIN T18 [get_ports btnU]     ;# Oyuncu 1
set_property PACKAGE_PIN W19 [get_ports btnL]     ;# Oyuncu 2
set_property PACKAGE_PIN T17 [get_ports btnR]     ;# Oyuncu 3
set_property PACKAGE_PIN U17 [get_ports btnD]     ;# Oyuncu 4
set_property IOSTANDARD LVCMOS33 [get_ports btn*]

## ---- USB-UART kopru --------------------------------------------------------
##  Yon isimleri PC tarafina gore verilmistir:
##    B18 = PC'nin TXD'si  -> FPGA'nin ALICI ucu (RsRx)
##    A18 = PC'nin RXD'si  -> FPGA'nin VERICI ucu (RsTx)  <-- bizim cikisimiz
set_property PACKAGE_PIN A18 [get_ports RsTx]
    set_property IOSTANDARD LVCMOS33 [get_ports RsTx]

## Sadece bilgisayardan karta veri alacaksaniz acin:
# set_property PACKAGE_PIN B18 [get_ports RsRx]
#     set_property IOSTANDARD LVCMOS33 [get_ports RsRx]

## ---- Konfigurasyon (DRC uyarilarini onler) ---------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## =============================================================================
##  ZAMANLAMA ISTISNASI  -  UART bayt uretimi (multicycle path)
## =============================================================================
##  SORUN
##    uart_reporter'in urettigi bayt su yoldan geciyor:
##      score_accum/reaction_capture yazmaclari
##        -> bin2bcd (13 kademeli double-dabble zinciri)
##        -> 30 sutunluk metin secici
##        -> tx_veri yazmaci
##    Bu yol ~16 ns suruyor, 100 MHz'in 10 ns'lik butcesine sigmiyor.
##    Kisit koymazsak Vivado WNS = -5.9 ns ile "Failed Timing" veriyor.
##
##  NEDEN GERCEKTE SORUN DEGIL
##    tx_veri saatte bir yuklenmiyor. Bir bayt 9600 baud'da 10 bit x 10417
##    cevrim = ~104 000 cevrim suruyor ve reporter bir sonraki bayti ancak
##    uart_tx bosaldiktan sonra hazirliyor. Ustelik uart_reporter icinde,
##    adim degistikten sonra bayt'in oturmasi icin 16 cevrimlik bir bekleme
##    (OTURMA sayaci) var. Yani bu yola gercekte on binlerce cevrim dusuyor.
##
##  KISIT
##    Asagidaki satirlar Vivado'ya "bu yazmaca giden yollar icin 8 cevrimlik
##    butcen var" diyor. 8 x 10 ns = 80 ns >> 16 ns, rahatca gecer.
##    -hold degeri her zaman (setup - 1) verilir; aksi halde tutma (hold)
##    analizi yanlis referans kenarina gore yapilir.
##
##  HANGI YAZMACLAR KAPSAMDA
##    tx_veri   : gonderilecek bayt        (bayt basina bir kez yuklenir)
##    adim      : metindeki bayt sayaci    (bayt basina bir kez artar)
##    calisiyor : rapor devam ediyor mu    (rapor basinda/sonunda degisir)
##    bitti     : rapor bitti bayragi      (rapor sonunda degisir)
##  Bu dordunun de giris konisi ayni: bin2bcd zinciri ve toplam_bayt
##  karsilastirmasi. Dordu de en az 19 cevrimde bir yazilir (16 cevrimlik
##  OTURMA + el sikisma fazlari), dolayisiyla 8 cevrimlik butce guvenli.
##
##  KAPSAM DISI (bilerek): fz, otur, tx_gonder - bunlar her cevrim degisebilir
##  ama giris konileri kisa, zaten tek cevrime rahat siginiyorlar.
set_multicycle_path -setup 8 -to [get_cells -quiet {u_rapor/tx_veri_reg[*] u_rapor/adim_reg[*] u_rapor/calisiyor_reg u_rapor/bitti_reg}]
set_multicycle_path -hold  7 -to [get_cells -quiet {u_rapor/tx_veri_reg[*] u_rapor/adim_reg[*] u_rapor/calisiyor_reg u_rapor/bitti_reg}]

## =============================================================================
##  QSPI FLASH'TAN OTOMATIK ONYUKLEME
## =============================================================================
##  Artix-7 SRAM tabanlidir; bitstream guc kesilince silinir. Karti prize
##  taktiginda tasarimin kendiliginden gelmesi icin bitstream'i kart uzerindeki
##  QSPI flash'a (Spansion S25FL032P, 32 Mbit) yazmak gerekir.
##
##  Asagidaki dort satir bitstream'in BASLIGINA yaziliyor; bu yuzden bu
##  ayarlari ekledikten SONRA bitstream'i yeniden uretmek zorunlu, eski
##  top.bit'ten uretilen .mcs dogru calismaz.
##
##  SPIx4 : flash'i 4 veri hattindan birden okur (x1'e gore ~4 kat hizli acilis)
##  CONFIGRATE 33 : konfigurasyon saati 33 MHz (S25FL032P'nin destekledigi hiz)
##  COMPRESS : bitstream'i sikistirir, hem flash'ta yer hem acilis suresi kazandirir
##
##  KART UZERINDE: JP1 (MODE) jumper'i QSPI konumunda olmali. Fabrika ayari
##  JTAG'dir ve JTAG'de kaldigi surece kart acilista flash'i hic okumaz.
set_property CONFIG_MODE SPIx4                  [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4    [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33     [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE    [current_design]
