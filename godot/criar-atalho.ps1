Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$projDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$iconPath = Join-Path $projDir "icon.ico"
$batPath = Join-Path $projDir "RODAR-JOGO.bat"

# === Gera o icone do diorama ===
$size = 256
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# Fundo gradiente noturno (roxo escuro)
$bgRect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($bgRect, [System.Drawing.Color]::FromArgb(255, 18, 14, 38), [System.Drawing.Color]::FromArgb(255, 35, 24, 70), 90)
$g.FillRectangle($bgBrush, $bgRect)
$bgBrush.Dispose()

# Halo da lua (gradient radial fake — circulos concentricos)
$cx = 128; $cy = 110
for ($i = 14; $i -ge 0; $i--) {
    $r = 70 + $i * 8
    $a = [int](6 + (14 - $i) * 4)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 141, 105, 226))
    $g.FillEllipse($brush, $cx - $r, $cy - $r, $r * 2, $r * 2)
    $brush.Dispose()
}

# Lua
$moonR = 56
$moonBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 251, 234, 190))
$g.FillEllipse($moonBrush, $cx - $moonR, $cy - $moonR, $moonR * 2, $moonR * 2)
$moonBrush.Dispose()
# Crateras
$craterBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(140, 206, 191, 154))
$g.FillEllipse($craterBrush, $cx + 8, $cy - 30, 20, 20)
$g.FillEllipse($craterBrush, $cx - 22, $cy - 4, 14, 14)
$craterBrush.Dispose()

# Vagalumes ao redor da lua
$rng = New-Object System.Random(42)
for ($i = 0; $i -lt 18; $i++) {
    $ang = $rng.NextDouble() * [Math]::PI * 2
    $dist = 70 + $rng.NextDouble() * 60
    $px = $cx + [Math]::Cos($ang) * $dist
    $py = $cy + [Math]::Sin($ang) * $dist * 0.65 - 5
    $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(140, 255, 224, 128))
    $g.FillEllipse($glowBrush, $px - 4, $py - 4, 8, 8)
    $glowBrush.Dispose()
    $coreBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 255, 250, 218))
    $g.FillEllipse($coreBrush, $px - 1.5, $py - 1.5, 3, 3)
    $coreBrush.Dispose()
}

# Plataforma (chao escuro)
$groundY = 208
$groundBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 16, 12, 28))
$g.FillRectangle($groundBrush, 24, $groundY, $size - 48, 28)
$groundBrush.Dispose()

# Funcao auxiliar: desenha arvore (triangulos empilhados + tronco)
function Draw-Tree($g, $bx, $by, $h, $color) {
    $trunkW = $h * 0.16
    $brush = New-Object System.Drawing.SolidBrush($color)
    $g.FillRectangle($brush, $bx - $trunkW / 2, $by - $h * 0.45, $trunkW, $h * 0.45)
    for ($i = 0; $i -lt 3; $i++) {
        $y = $by - $h * (0.45 + $i * 0.20)
        $w = $h * (0.65 - $i * 0.12)
        $pts = @(
            (New-Object System.Drawing.PointF([float]($bx - $w / 2), [float]$y)),
            (New-Object System.Drawing.PointF([float]($bx + $w / 2), [float]$y)),
            (New-Object System.Drawing.PointF([float]$bx, [float]($y - $h * 0.30)))
        )
        $g.FillPolygon($brush, $pts)
    }
    $brush.Dispose()
}

$darkTree = [System.Drawing.Color]::FromArgb(255, 16, 11, 26)
$lighterTree = [System.Drawing.Color]::FromArgb(255, 24, 18, 40)
Draw-Tree $g 50 $groundY 70 $darkTree
Draw-Tree $g 92 $groundY 90 $lighterTree
Draw-Tree $g 168 $groundY 90 $lighterTree
Draw-Tree $g 210 $groundY 70 $darkTree

# Personagem central
$pcx = 128; $pcy = $groundY - 10
# Sombra
$shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(110, 0, 0, 0))
$g.FillEllipse($shadowBrush, $pcx - 18, $pcy + 6, 36, 10)
$shadowBrush.Dispose()
# Tronco / capuz
$bodyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 78, 58, 122))
$g.FillRectangle($bodyBrush, $pcx - 16, $pcy - 30, 32, 36)
$bodyBrush.Dispose()
# Cabeca
$headBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 27, 20, 50))
$g.FillEllipse($headBrush, $pcx - 17, $pcy - 50, 34, 30)
$headBrush.Dispose()
# Olhos dourados
$eyeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 204, 90))
$g.FillEllipse($eyeBrush, $pcx - 8, $pcy - 40, 6, 6)
$g.FillEllipse($eyeBrush, $pcx + 2, $pcy - 40, 6, 6)
$eyeBrush.Dispose()

$g.Dispose()

# Salva como .ico (256x256)
$tmpPng = Join-Path $env:TEMP "noite_icon.png"
$bmp.Save($tmpPng, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# Converte PNG para ICO (encoder nativo .NET)
$bmpForIcon = New-Object System.Drawing.Bitmap($tmpPng)
$hIcon = $bmpForIcon.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($hIcon)
$fs = [System.IO.File]::Create($iconPath)
$icon.Save($fs)
$fs.Close()
$icon.Dispose()
$bmpForIcon.Dispose()

Write-Host "Icone gerado em: $iconPath"

# === Cria o atalho na Area de Trabalho ===
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Noite dos Sobreviventes.lnk"

$wshell = New-Object -ComObject WScript.Shell
$shortcut = $wshell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $batPath
$shortcut.WorkingDirectory = $projDir
$shortcut.IconLocation = "$iconPath, 0"
$shortcut.Description = "Noite dos Sobreviventes - Survivor-like noturno"
$shortcut.WindowStyle = 7  # minimizado (a janela preta do bat fica fora do caminho)
$shortcut.Save()

Write-Host ""
Write-Host "Atalho criado em: $shortcutPath"
Write-Host ""
Write-Host "Pronto! Da um duplo clique no atalho 'Noite dos Sobreviventes' na sua Area de Trabalho."
