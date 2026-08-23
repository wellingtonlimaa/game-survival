# Gera o ícone do jogo (multi-resolução) e cria o atalho "Noite dos Sobreviventes"
# na Área de Trabalho e na pasta do projeto.
#
# Uso: powershell -ExecutionPolicy Bypass -File "godot\criar-atalho.ps1"
#
# Por que existe: arquivo .bat SEMPRE usa o ícone genérico do Windows.
# Quem carrega ícone bonito é o atalho (.lnk) — é ele que vai pra Área de Trabalho.

Add-Type -AssemblyName System.Drawing

$projDir = Split-Path -Parent $MyInvocation.MyCommand.Path          # ...\godot
$rootDir = Split-Path -Parent $projDir                              # ...\game-survival
$iconPath = Join-Path $projDir "icon.ico"
$launcher = Join-Path $rootDir "INICIAR.bat"

if (-not (Test-Path $launcher)) {
    Write-Host "ERRO: nao encontrei $launcher" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------- desenho ----

function New-IconBitmap {
    param([int]$Size)

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    # tudo em coordenadas de 256 e escalado no fim
    $k = $Size / 256.0
    function S([double]$v) { return [float]($v * $k) }
    function Col([int]$a, [int]$r, [int]$gr, [int]$b) {
        return [System.Drawing.Color]::FromArgb($a, $r, $gr, $b)
    }
    function Fill($brushColor, [double]$x, [double]$y, [double]$w, [double]$h) {
        $br = New-Object System.Drawing.SolidBrush($brushColor)
        $g.FillEllipse($br, (S $x), (S $y), (S $w), (S $h))
        $br.Dispose()
    }
    function FillRect($brushColor, [double]$x, [double]$y, [double]$w, [double]$h) {
        $br = New-Object System.Drawing.SolidBrush($brushColor)
        $g.FillRectangle($br, (S $x), (S $y), (S $w), (S $h))
        $br.Dispose()
    }
    function FillPoly($brushColor, [double[][]]$pts) {
        $arr = New-Object 'System.Drawing.PointF[]' $pts.Length
        for ($i = 0; $i -lt $pts.Length; $i++) {
            $arr[$i] = New-Object System.Drawing.PointF((S $pts[$i][0]), (S $pts[$i][1]))
        }
        $br = New-Object System.Drawing.SolidBrush($brushColor)
        $g.FillPolygon($br, $arr)
        $br.Dispose()
    }

    # Nivel de detalhe: em 16/24/32 px o desenho precisa ser MUITO mais simples
    $full = $Size -ge 48
    $moonR = if ($full) { 62 } else { 76 }
    $moonCy = if ($full) { 104 } else { 112 }
    $heroScale = if ($full) { 1.0 } else { 0.82 }

    # Fundo: gradiente roxo-noite
    $bgRect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $bgRect, (Col 255 20 15 42), (Col 255 44 28 82), 90)
    $g.FillRectangle($bgBrush, $bgRect)
    $bgBrush.Dispose()

    # Halo da lua
    for ($i = 14; $i -ge 1; $i--) {
        $r = $moonR + $i * 7
        $a = [int](5 + (14 - $i) * 3.4)
        Fill (Col $a 150 110 235) (128 - $r) ($moonCy - $r) ($r * 2) ($r * 2)
    }

    # Lua (o elemento que precisa ler mesmo em 16x16)
    Fill (Col 255 252 238 198) (128 - $moonR) ($moonCy - $moonR) ($moonR * 2) ($moonR * 2)
    if ($full) {
        Fill (Col 120 214 197 156) 132 66 26 26
        Fill (Col 110 214 197 156) 78 104 18 18
        Fill (Col 90 214 197 156) 112 132 13 13
    } else {
        Fill (Col 110 214 197 156) 148 74 26 26
    }

    if ($full) {
        # Vagalumes
        $spots = @(@(36, 70), @(206, 60), @(220, 132), @(28, 140), @(186, 30), @(64, 30))
        foreach ($sp in $spots) {
            Fill (Col 120 255 224 128) ($sp[0] - 7) ($sp[1] - 7) 14 14
            Fill (Col 235 255 250 218) ($sp[0] - 2.5) ($sp[1] - 2.5) 5 5
        }

        # Pinheiros nas laterais
        foreach ($tx in @(28, 228)) {
            FillRect (Col 255 14 10 26) ($tx - 4) 170 8 46
            FillPoly (Col 255 18 13 34) @(@(($tx - 26), 186), @(($tx + 26), 186), @($tx, 132))
            FillPoly (Col 255 24 17 44) @(@(($tx - 20), 158), @(($tx + 20), 158), @($tx, 112))
        }
    }

    # Chão
    FillRect (Col 255 12 9 24) 0 214 256 42

    # Herói encapuzado — silhueta escura recortada na lua
    $px = 128.0
    $py = 216.0
    $hs = $heroScale
    if ($full) {
        # capa
        FillPoly (Col 255 40 30 74) @(@(($px - 30), ($py - 74)), @(($px + 30), ($py - 74)), @(($px + 40), $py), @(($px - 40), $py))
    }
    # túnica
    FillPoly (Col 255 55 40 96) @(@(($px - 26 * $hs), ($py - 74 * $hs)), @(($px + 26 * $hs), ($py - 74 * $hs)), @(($px + 34 * $hs), $py), @(($px - 34 * $hs), $py))
    # cabeça + capuz (um "pingo" escuro sobre a lua)
    Fill (Col 255 24 17 44) ($px - 30 * $hs) ($py - 124 * $hs) (60 * $hs) (60 * $hs)
    FillPoly (Col 255 24 17 44) @(@(($px - 30 * $hs), ($py - 90 * $hs)), @($px, ($py - 142 * $hs)), @(($px + 30 * $hs), ($py - 90 * $hs)))
    # olhos dourados (a marca do jogo)
    $eye = 14 * $hs
    Fill (Col 255 255 204 90) ($px - 17 * $hs) ($py - 104 * $hs) $eye $eye
    Fill (Col 255 255 204 90) ($px + 3 * $hs) ($py - 104 * $hs) $eye $eye

    if ($full) {
        # Moldura dourada sutil
        $pen = New-Object System.Drawing.Pen((Col 90 255 198 76), [float](6 * $k))
        $g.DrawRectangle($pen, [float](3 * $k), [float](3 * $k), [float](($Size - 6 * $k) - 1), [float](($Size - 6 * $k) - 1))
        $pen.Dispose()
    }

    $g.Dispose()
    return $bmp
}

# ------------------------------------------------------------------ .ico -----

function Save-MultiIcon {
    param([int[]]$Sizes, [string]$Path)

    $streams = @{}
    foreach ($s in $Sizes) {
        $bmp = New-IconBitmap -Size $s
        $ms = New-Object System.IO.MemoryStream
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        $streams[$s] = $ms.ToArray()
        $ms.Dispose()
    }

    $fs = [System.IO.File]::Create($Path)
    $bw = New-Object System.IO.BinaryWriter($fs)
    $ordered = $Sizes | Sort-Object

    $bw.Write([UInt16]0)                 # reservado
    $bw.Write([UInt16]1)                 # tipo: 1 = ícone
    $bw.Write([UInt16]$ordered.Count)

    $offset = 6 + 16 * $ordered.Count
    foreach ($s in $ordered) {
        $len = $streams[$s].Length
        $dim = if ($s -ge 256) { 0 } else { $s }
        $bw.Write([Byte]$dim)            # largura
        $bw.Write([Byte]$dim)            # altura
        $bw.Write([Byte]0)               # cores da paleta
        $bw.Write([Byte]0)               # reservado
        $bw.Write([UInt16]1)             # planos
        $bw.Write([UInt16]32)            # bits por pixel
        $bw.Write([UInt32]$len)
        $bw.Write([UInt32]$offset)
        $offset += $len
    }
    foreach ($s in $ordered) { $bw.Write($streams[$s]) }

    $bw.Flush()
    $fs.Close()
}

Write-Host ""
Write-Host "Gerando icone multi-resolucao..." -ForegroundColor Cyan
Save-MultiIcon -Sizes @(16, 24, 32, 48, 64, 128, 256) -Path $iconPath
Write-Host "Icone: $iconPath" -ForegroundColor Green

# ----------------------------------------------------------------- atalho ----

function New-GameShortcut {
    param([string]$Path)
    $wshell = New-Object -ComObject WScript.Shell
    $sc = $wshell.CreateShortcut($Path)
    $sc.TargetPath = $launcher
    $sc.WorkingDirectory = $rootDir
    $sc.IconLocation = "$iconPath, 0"
    $sc.Description = "Noite dos Sobreviventes - survivor-like noturno"
    $sc.WindowStyle = 7   # inicia minimizado: a janela preta do bat nao rouba a tela
    $sc.Save()
}

$desktop = [Environment]::GetFolderPath("Desktop")
$desktopShortcut = Join-Path $desktop "Noite dos Sobreviventes.lnk"
New-GameShortcut -Path $desktopShortcut
Write-Host "Atalho na Area de Trabalho: $desktopShortcut" -ForegroundColor Green

$localShortcut = Join-Path $rootDir "JOGAR.lnk"
New-GameShortcut -Path $localShortcut
Write-Host "Atalho na pasta do projeto: $localShortcut" -ForegroundColor Green

# Remove a copia solta do INICIAR.bat na Area de Trabalho (ela nem funciona ali,
# porque procura o setup-and-run.ps1 na propria Area de Trabalho).
$strayBat = Join-Path $desktop "INICIAR.bat"
if (Test-Path $strayBat) {
    $same = (Get-Content $strayBat -Raw) -eq (Get-Content $launcher -Raw)
    if ($same) {
        Remove-Item $strayBat -Force
        Write-Host "Removi a copia quebrada do INICIAR.bat da Area de Trabalho." -ForegroundColor Yellow
    } else {
        Write-Host "Existe um INICIAR.bat diferente na Area de Trabalho - deixei quieto." -ForegroundColor Yellow
    }
}

# Limpa o cache de icones do Explorer pra atualizacao aparecer na hora
try { ie4uinit.exe -show } catch { }

Write-Host ""
Write-Host "Pronto! Duplo clique em 'Noite dos Sobreviventes' na Area de Trabalho." -ForegroundColor Cyan
Write-Host ""
