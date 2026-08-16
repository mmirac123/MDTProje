# ============================================================================
#  uart_dinle.ps1  -  Basys3 Refleks Oyunu UART dinleyicisi
#  Nazik Ormanlar / BIL 264-265
#
#  Kart raporu 9600 baud 8N1 ile RsTx (A18) pininden gonderiyor.
#  Bu betik o portu acip gelen metni renklendirerek ekrana basar.
#  Kurulum gerekmez.
#
#  KULLANIM
#    Varsayilan COM8 icin:   .\uart_dinle.ps1
#    Baska port icin     :   .\uart_dinle.ps1 -Port COM5
#    Banner'i atlamak    :   .\uart_dinle.ps1 -Hizli
#    Cikmak icin         :   Ctrl + C
# ============================================================================

param(
    [string]$Port  = "COM8",
    [int]   $Baud  = 9600,
    [switch]$Hizli
)

$OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------------------
#  Banner
# ---------------------------------------------------------------------------
$orman = @'
         /\                             /\
        /\/\            /\             /\/\           /\
       /\/\/\          /\/\           /\/\/\         /\/\        /\
      /\/\/\/\        /\/\/\         /\/\/\/\       /\/\/\      /\/\
         ||             ||              ||            ||         ||
'@

$baslik = @'
 _  _   _    _______ _  __   ___  ___ __  __   _   _  _ _      _   ___
| \| | /_\  |_  /_ _| |/ /  / _ \| _ \  \/  | /_\ | \| | |    /_\ | _ \
| .` |/ _ \  / / | || ' <  | (_) |   / |\/| |/ _ \| .` | |__ / _ \|   /
|_|\_/_/ \_\/___|___|_|\_\  \___/|_|_\_|  |_/_/ \_\_|\_|____/_/ \_\_|_\
'@

function Yaz-Satirlar {
    param([string]$Metin, [string]$Renk, [int]$Gecikme = 0)
    foreach ($satir in $Metin -split "`n") {
        Write-Host $satir.TrimEnd("`r") -ForegroundColor $Renk
        if ($Gecikme -gt 0) { Start-Sleep -Milliseconds $Gecikme }
    }
}

if (-not $Hizli) { Clear-Host }
Write-Host ""
Yaz-Satirlar $orman  "DarkGreen" 45
Yaz-Satirlar $baslik "Green"     55
Write-Host ""
Write-Host "        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor DarkGreen
Write-Host "          B I L   2 6 4 / 2 6 5   -   D O N E M   P R O J E S I" -ForegroundColor Gray
Write-Host "              Basys3 Cok Oyunculu Refleks Oyunu" -ForegroundColor DarkGray
Write-Host "        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor DarkGreen
Write-Host ""

# ---------------------------------------------------------------------------
#  Portu ac
# ---------------------------------------------------------------------------
$sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, "None", 8, "One")
$sp.ReadTimeout = 500

try {
    $sp.Open()
} catch {
    Write-Host "  [ HATA ] $Port acilamadi." -ForegroundColor Red
    Write-Host ""
    Write-Host "    - Port numarasi dogru mu?" -ForegroundColor Gray
    Write-Host "      Aygit Yoneticisi -> Baglanti Noktalari (COM ve LPT)" -ForegroundColor DarkGray
    Write-Host "    - Baska bir program (PuTTY, Arduino IDE, eski bir pencere)" -ForegroundColor Gray
    Write-Host "      portu tutuyor olabilir." -ForegroundColor Gray
    Write-Host "    - Kart USB ile bagli ve acik mi? (DONE LED'i yaniyor mu?)" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "  [ BAGLANDI ]  $Port  @  $Baud baud  8N1" -ForegroundColor Black -BackgroundColor Green
Write-Host ""
Write-Host "  Kartta bir tur oynayin, rapor buraya dusecek." -ForegroundColor Cyan
Write-Host "  Rapor tur BITTIGINDE gelir - blackout'tan sonra herkes bassin" -ForegroundColor DarkGray
Write-Host "  ya da 5 saniye bekleyin (timeout)." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Cikmak icin Ctrl+C" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# ---------------------------------------------------------------------------
#  Gelen satiri icerigine gore renklendir
# ---------------------------------------------------------------------------
function Renk-Sec {
    param([string]$s)
    if ($s -match '^TUR ')             { return "Cyan" }
    if ($s -match '====')              { return "Yellow" }
    if ($s -match '^KAZANAN|^BERABERLIK') { return "Green" }
    if ($s -match '^BERABER:')         { return "DarkGreen" }
    if ($s -match '^TOPLAM')           { return "Cyan" }
    if ($s -match 'FALSESTART')        { return "Red" }
    if ($s -match 'TIMEOUT')           { return "DarkYellow" }
    if ($s -match 'OYNAMIYOR|ELENDI')  { return "DarkGray" }
    if ($s -match '^\s+P[1-4]')        { return "White" }
    return "Gray"
}

# ---------------------------------------------------------------------------
#  Dinleme dongusu - satir satir tamponlanir ki renklendirme dogru olsun
# ---------------------------------------------------------------------------
$tampon = ""

try {
    while ($true) {
        $veri = $sp.ReadExisting()
        if ($veri.Length -gt 0) {
            $tampon += $veri
            while ($tampon.Contains("`n")) {
                $kes    = $tampon.IndexOf("`n")
                $satir  = $tampon.Substring(0, $kes).TrimEnd("`r")
                $tampon = $tampon.Substring($kes + 1)
                Write-Host ("  " + $satir) -ForegroundColor (Renk-Sec $satir)
            }
        }
        Start-Sleep -Milliseconds 50
    }
}
finally {
    if ($tampon.Length -gt 0) { Write-Host ("  " + $tampon) -ForegroundColor Gray }
    $sp.Close()
    Write-Host ""
    Write-Host "  $Port kapatildi." -ForegroundColor Yellow
    Write-Host ""
}
