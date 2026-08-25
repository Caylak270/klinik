<#
.SYNOPSIS
    Dis Klinigi Demo Web Sitesi Uretici
.USAGE
    .\klinik-olustur.ps1
    .\klinik-olustur.ps1 -KlinikId "ozel-orkide"
    .\klinik-olustur.ps1 -Overwrite
#>

param(
    [string]$KlinikId = "",
    [switch]$Overwrite
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MasterTemplate = Join-Path $ScriptDir "master-template"
$OutputDir = Join-Path $ScriptDir "klinikler"
$JsonPath = Join-Path $ScriptDir "klinik-listesi.json"

# Master template'deki index.html'i bir kere oku (referans icin)
$MasterHtmlPath = Join-Path $MasterTemplate "index.html"
$MasterHtml = [System.IO.File]::ReadAllText($MasterHtmlPath, [System.Text.Encoding]::UTF8)

# Template'den gercek placeholder stringlerini extract et (Unicode uyumlulugu icin)
function Get-ExactPlaceholder($content, $startMarker, $endMarker) {
    $idx = $content.IndexOf($startMarker)
    if ($idx -lt 0) { return $null }
    if ($endMarker) {
        $end = $content.IndexOf($endMarker, $idx + $startMarker.Length)
        if ($end -lt 0) { return $null }
        return $content.Substring($idx, $end - $idx + $endMarker.Length)
    }
    return $startMarker
}

# Placeholder'lari template'den cek
$PH_KLINIK = Get-ExactPlaceholder $MasterHtml '[KL' ']'

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  Dis Klinigi Demo Web Sitesi Uretici" -ForegroundColor White
Write-Host "=======================================================" -ForegroundColor Cyan

if (-not (Test-Path $MasterTemplate)) { Write-Host "  HATA: master-template bulunamadi!" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $JsonPath)) { Write-Host "  HATA: klinik-listesi.json bulunamadi!" -ForegroundColor Red; exit 1 }

$JsonContent = [System.IO.File]::ReadAllText($JsonPath, [System.Text.Encoding]::UTF8)
$Klinikler = $JsonContent | ConvertFrom-Json

if ($KlinikId -ne "") {
    $Klinikler = @($Klinikler | Where-Object { $_.id -eq $KlinikId })
    if ($Klinikler.Count -eq 0) { Write-Host "  HATA: Klinik bulunamadi: $KlinikId" -ForegroundColor Red; exit 1 }
}

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

Write-Host ""
Write-Host "  Toplam klinik: $($Klinikler.Count)" -ForegroundColor White
Write-Host ""

$Basarili = 0

foreach ($k in $Klinikler) {
    $KlinikDir = Join-Path $OutputDir $k.id

    Write-Host "  -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  $($k.klinik_adi) ($($k.id))" -ForegroundColor Cyan

    if ((Test-Path $KlinikDir) -and -not $Overwrite) {
        Write-Host "    Zaten mevcut, atlaniyor. (-Overwrite kullanin)" -ForegroundColor Yellow
        continue
    }

    # 1. Temizle ve kopyala
    if (Test-Path $KlinikDir) { Remove-Item $KlinikDir -Recurse -Force }
    robocopy $MasterTemplate $KlinikDir /E /NFL /NDL /NJH /NJS /NC /NS /NP 2>&1 | Out-Null

    $HtmlPath = Join-Path $KlinikDir "index.html"
    if (-not (Test-Path $HtmlPath)) { Write-Host "    HATA: Kopyalama basarisiz!" -ForegroundColor Red; continue }

    # 2. Master HTML'i direkt olarak oku (byte-perfect)
    #    robocopy'nin kopyaladigi dosya yerine, master'dan oku ve replace yap
    $html = $MasterHtml

    # --- CUSTOM ASSETS COPY ---
    if ($k.custom_assets) {
        $AssetsDir = Join-Path $KlinikDir "assets"
        if ($k.custom_assets.hero_bg) {
            $SrcHero = Join-Path $ScriptDir $k.custom_assets.hero_bg
            if (Test-Path $SrcHero) {
                $HeroExt = [System.IO.Path]::GetExtension($SrcHero)
                $NewHeroName = "custom-hero" + $HeroExt
                Copy-Item $SrcHero (Join-Path $AssetsDir $NewHeroName) -Force
                $html = $html.Replace("assets/hero-bg.png", "assets/" + $NewHeroName)
            }
        }
        if ($k.custom_assets.clinic_interior) {
            $SrcInterior = Join-Path $ScriptDir $k.custom_assets.clinic_interior
            if (Test-Path $SrcInterior) {
                $InteriorExt = [System.IO.Path]::GetExtension($SrcInterior)
                $NewInteriorName = "custom-interior" + $InteriorExt
                Copy-Item $SrcInterior (Join-Path $AssetsDir $NewInteriorName) -Force
                $html = $html.Replace("assets/clinic-interior.png", "assets/" + $NewInteriorName)
            }
        }
    }

    # --- DEGISIMLER ---

    # Klinik adi (template'den extract edilen gercek placeholder ile)
    if ($PH_KLINIK) { $html = $html.Replace($PH_KLINIK, $k.klinik_adi) }

    # Telefon
    $html = $html.Replace('905330000000', $k.telefon_raw)
    $html = $html.Replace('0533 000 00 00', $k.telefon_gosterim)

    # Google puani
    $html = $html.Replace('4.8 / 5.0', "$($k.google_puan) / 5.0")

    # Yorum sayisi
    $html = $html.Replace('100+ Mutlu Hasta Yorumu', "$($k.yorum_sayisi) Mutlu Hasta Yorumu")
    $html = $html.Replace('100+ Mutlu Hasta', "$($k.yorum_sayisi) Mutlu Hasta")

    # Adres
    $html = $html.Replace('[Klinik Adresi], Kat: X, No: Y', $k.adres)

    # Ilce - template'den exact stringi al
    $ilcePlaceholder = Get-ExactPlaceholder $MasterHtml 'lçe / ' 'stanbul'
    if ($ilcePlaceholder) {
        # Full context ile degistir
        $html = $html.Replace(">" + "İ" + $ilcePlaceholder + "<", ">$($k.ilce)<")
    }

    # Calisma saatleri
    $saatlerPH = Get-ExactPlaceholder $MasterHtml 'Pazartesi' '19:00'
    if ($saatlerPH) { $html = $html.Replace($saatlerPH, $k.calisma_saatleri) }

    # Google Maps linki
    $html = $html.Replace('href="https://maps.google.com"', "href=`"$($k.harita_linki)`"")

    # Hasta yorumlari
    $y = $k.yorumlar
    if ($y -and $y.Count -ge 3) {
        # Yorum 1 - metni ve yazari degistir
        $y1text = Get-ExactPlaceholder $MasterHtml 'mplant tedavimi burada' 'tavsiye ederim.'
        if ($y1text) { $html = $html.Replace("İ" + $y1text, $y[0].yorum) }
        $html = $html.Replace('>AK<', ">$($y[0].avatar)<")
        $html = $html.Replace('>Ay' + [char]0x015F + 'e K.<', ">$($y[0].isim)<")
        
        # Yorum 1 tarih
        $t1 = Get-ExactPlaceholder $MasterHtml '>3 ay' '<'
        if ($t1 -and $t1.Length -lt 20) { $html = $html.Replace($t1, ">$($y[0].tarih)<") }

        # Yorum 2
        $y2text = Get-ExactPlaceholder $MasterHtml 'Zirkonyum kaplama' 'ekkürler!'
        if ($y2text) { $html = $html.Replace($y2text, $y[1].yorum) }
        $html = $html.Replace('>MY<', ">$($y[1].avatar)<")
        $html = $html.Replace('>Mehmet Y.<', ">$($y[1].isim)<")
        $t2 = Get-ExactPlaceholder $MasterHtml '>1 ay' 'nce<'
        if ($t2 -and $t2.Length -lt 20) { $html = $html.Replace($t2, ">$($y[1].tarih)<") }

        # Yorum 3
        $y3text = Get-ExactPlaceholder $MasterHtml 'ocuklarımı di' 'ekkürler.'
        if ($y3text) { $html = $html.Replace("Ç" + $y3text, $y[2].yorum) }
        $html = $html.Replace('>FD<', ">$($y[2].avatar)<")
        $html = $html.Replace('>Fatma D.<', ">$($y[2].isim)<")
        $t3 = Get-ExactPlaceholder $MasterHtml '>2 hafta' 'nce<'
        if ($t3 -and $t3.Length -lt 25) { $html = $html.Replace($t3, ">$($y[2].tarih)<") }
    }

    # 3. UTF-8 BOM'suz olarak kaydet
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($HtmlPath, $html, $utf8NoBom)

    # Dogrulama
    $check = [System.IO.File]::ReadAllText($HtmlPath, [System.Text.Encoding]::UTF8)
    $kalan = 0
    $si = 0
    while ($true) { $fi = $check.IndexOf('[KL', $si); if ($fi -lt 0) { break }; $kalan++; $si = $fi + 1 }
    
    if ($kalan -eq 0) {
        Write-Host "    BASARILI - Tum yer tutucular degistirildi" -ForegroundColor Green
    } else {
        Write-Host "    UYARI - $kalan adet [KLINIK ADI] degismemis" -ForegroundColor Yellow
    }

    $Basarili++
}

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  TAMAMLANDI: $Basarili / $($Klinikler.Count) klinik olusturuldu" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

Get-ChildItem $OutputDir -Directory | ForEach-Object {
    $f = Join-Path $_.FullName "index.html"
    $uri = "file:///" + ($f -replace '\\','/')
    Write-Host "  $($_.Name) -> $uri" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  Yeni klinik eklemek icin: klinik-listesi.json" -ForegroundColor Yellow
Write-Host ""
