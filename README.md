# Basys3 Çok Oyunculu Refleks Oyunu

BİL 264/265 dönem projesi — **Grup: Nazik Ormanlar**

Basys3 FPGA üzerinde 2–4 oyunculu refleks yarışı. 7-segment'in dört basamağı
sırayla yanar, hepsi yanık kalırken LFSR'den gelen rastgele bir süre beklenir,
sonra hepsi aynı anda söner. O an referans zamanıdır; oyuncuların butona basma
süreleri 1 ms çözünürlükle ölçülür, sıralamaya göre puanlanır ve sonuçlar
LED'lerde + UART üzerinden terminalde gösterilir.

---

## Kurulum

Bu repo **Vivado projesini içermez**, sadece kaynak dosyaları içerir.
Proje her bilgisayarda yerel olarak üretilir:

```
git clone https://github.com/mmirac123/MDTProje.git
```

1. Klasörü **kısa ve Türkçe karaktersiz** bir yola koy: `C:\fpga\mdt`
2. Vivado → **Tools → Run Tcl Script...** → `proje_olustur.tcl`
3. Proje yanında oluşur.

Kart: **Basys 3**, part `xc7a35tcpg236-1`. Herkes aynı Vivado sürümünü kullansın.

---

## Klasör yapısı

| Yol | İçerik |
|---|---|
| `kaynak/` | Verilog tasarım dosyaları + `Basys3_Refleks.xdc` |
| `testbench/` | Testbench dosyaları |
| `proje_olustur.tcl` | Vivado projesini sıfırdan kuran betik |
| `OKUBENI_ARAYUZ.txt` | **Arayüz sözleşmesi — kod yazmadan önce okuyun** |
| `Nazik_Ormanlar_Grup_Kilavuzu.pdf` | Modül modül ne yazılacak, hangi kararlar verilecek |

---

## Modül durumu

| Modül | Sorumlu | Durum |
|---|---|---|
| `timebase` | — | ✅ bitti, simülasyonda doğrulandı |
| `debouncer` | — | ✅ bitti, simülasyonda doğrulandı |
| `seg7_driver` | A | ✅ yazıldı, `seg7_driver_tb` var |
| `led_ctrl` | A | ✅ yazıldı |
| `top` | A | ✅ tüm modüller bağlandı, power-on reset eklendi, `top_tb` + `por_tb` var |
| `game_fsm` | B | ✅ yazıldı (7 durum), `top_tb` ile doğrulanır |
| `lfsr16` | C | ✅ yazıldı, `lfsr16_tb` var |
| `delay_gen` | C | ✅ yazıldı, `lfsr16_tb` içinde test ediliyor |
| `reaction_capture` | C | ✅ yazıldı, `reaction_capture_tb` var |
| `scoring` | C | ✅ yazıldı, `scoring_tb` var |
| `score_accum` | C | ✅ yazıldı |
| `uart_tx` | D | ✅ yazıldı, `uart_tx_tb` var |
| `bin2bcd` | D | ✅ yazıldı, `bin2bcd_tb` var |
| `uart_reporter` | D | ✅ yazıldı, `top_tb` UART çıktısını konsola basar |

> Tüm modüller yazıldı ve doğrulandı. `top_tb` 74/74 geçiyor, `por_tb` 5/5
> geçiyor. Vivado 2018.3'te WNS +1.94 ns, route temiz, LUT %3.1.

---

## Alınan tasarım kararları

| # | Karar |
|---|---|
| K2 | `SW12:11 = 11` → 4 oyuncu sayılır |
| K4 | SEQ animasyon adımı **400 ms** (toplam 1,6 sn) |
| K5 | Basamaklar **birikerek** yanar: `0001 → 0011 → 0111 → 1111` |
| K6 | Konfigürasyonda ekran: d3 = oyuncu sayısı, d1-d0 = tur sayısı |
| K7 | Beraberlikte iki oyuncu da aynı puanı ve aynı sayıda LED'i alır |
| K8 | Elenen oyuncunun LED'leri sönük (0 puan → 0 LED) |
| K9 | Puanlama her zaman 4/3/2/1 (oyuncu sayısından bağımsız) |
| K10 | UART satır sonu `\r\n` |
| K11 | Erken bitiş, tur bitip rapor gönderildikten sonra |
| K12 | Oyun bitince 7-segment tamamen söner, kazananı LED'ler gösterir |
| K13 | Kart açılışında otomatik power-on reset (`top.v`), SW15'e bağımlı değil |

Ek karar: **BTNC akışı** — proje tanımı §2 "BTNC'ye basıldığında ayarlar
kaydedilmeli **ve oyun başlamalıdır**" dediği için tek basış: ilk basış hem
konfigürasyonu dondurur hem 1. turu başlatır, sonraki her basış bir sonraki
turu başlatır. Yani **tur başına tam bir BTNC basışı** düşer. (Daha önce
araya `S_ARM` diye ikinci bir bekleme durumu koymuştuk, şartnameye uyması
için kaldırıldı; `durum` kodlarında `3'd1` boş bırakıldı.)

Ek karar: **false start bayrakları** `t0`'da değil, `silahli`'nin yükselen
kenarında (turun başında) temizlenir. Aksi halde blackout'tan önce yakalanan
false start'lar `t0` ile silinirdi.

---

## Çalışma kuralları

- **Her dosyanın tek sahibi var.** Başkasının dosyasını düzenleme.
- Bir **port ismi veya bit genişliği** değişecekse önce gruba yaz, sonra
  `OKUBENI_ARAYUZ.txt`'yi güncelle, sonra kodu değiştir.
- Sıralı bloklarda `<=`, kombinasyonel bloklarda `=`.
- Reset **senkron**: `always @(posedge clk) if (rst)`.
- Zaman `vurus_1ms` ile sayılır, ham çevrim sayılmaz.
- Testbench'te `MS_DIV` / `CLKS_PER_BIT` küçültülür.
- UART metninde Türkçe karakter kullanılmaz.

Ayrıntılar ve gerekçeler için grup kılavuzuna bakın.

---

## Yazma sırası

1. `lfsr16` + `delay_gen`
2. `seg7_driver` → **kartta "1234" yanmalı**
3. `game_fsm` iskeleti → BTNC ile animasyon + blackout
4. `reaction_capture` + `scoring` + `led_ctrl` → **oyun oynanabilir**
5. `score_accum`, false start, timeout, eleme modu, erken bitiş
6. `uart_tx` (önce tek `'A'`) → `bin2bcd` → `uart_reporter`
7. `top_tb`, testbench'ler, bitstream

---

## Teslim edilecekler

1. Tüm Verilog kaynak dosyaları
2. Testbench dosyaları
3. `Basys3_Refleks.xdc`
4. Bitstream dosyası veya üretme adımları
