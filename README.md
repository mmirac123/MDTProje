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
| `seg7_driver` | A | iskelet |
| `led_ctrl` | A | iskelet |
| `top` | A | iskelet |
| `game_fsm` | B | iskelet |
| `lfsr16` | C | iskelet |
| `delay_gen` | C | iskelet |
| `reaction_capture` | C | iskelet |
| `scoring` | C | iskelet |
| `score_accum` | C | iskelet |
| `uart_tx` | D | iskelet |
| `bin2bcd` | D | iskelet |
| `uart_reporter` | D | iskelet |

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
