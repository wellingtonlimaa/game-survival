# Setup automático: instala Godot se necessário e roda o jogo
# Uso: duplo clique em INICIAR.bat (que chama este script)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Find-Godot {
    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $patterns = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*\Godot_v*.exe",
        "$env:LOCALAPPDATA\Programs\Godot\Godot*.exe",
        "$env:ProgramFiles\Godot\Godot*.exe",
        "${env:ProgramFiles(x86)}\Godot\Godot*.exe"
    )
    foreach ($pattern in $patterns) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -notmatch "_console" } |
                 Sort-Object LastWriteTime -Descending |
                 Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

function Test-Winget {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor DarkMagenta
Write-Host "  NOITE DOS SOBREVIVENTES - Setup & Run" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor DarkMagenta
Write-Host ""

$repoRoot = $PSScriptRoot
$projectPath = Join-Path $repoRoot "godot"

if (-not (Test-Path (Join-Path $projectPath "project.godot"))) {
    Write-Host "ERRO: nao encontrei 'godot/project.godot' em $repoRoot" -ForegroundColor Red
    Write-Host "Esse script precisa estar na raiz do repositorio clonado."
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "Procurando Godot..." -ForegroundColor Cyan
$godot = Find-Godot

if (-not $godot) {
    Write-Host "Godot nao encontrado." -ForegroundColor Yellow

    if (-not (Test-Winget)) {
        Write-Host ""
        Write-Host "winget tambem nao esta disponivel nessa maquina." -ForegroundColor Red
        Write-Host "Baixe o Godot 4 manualmente em: https://godotengine.org/download"
        Write-Host "Depois extraia, coloque o Godot.exe no PATH e rode esse script novamente."
        Read-Host "Pressione Enter para sair"
        exit 1
    }

    Write-Host "Instalando Godot via winget (pode demorar 1-2 min)..." -ForegroundColor Cyan
    try {
        winget install --id GodotEngine.GodotEngine -e --silent --accept-source-agreements --accept-package-agreements
    } catch {
        Write-Host "ERRO ao rodar winget: $_" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit 1
    }

    Write-Host "Verificando instalacao..." -ForegroundColor Cyan
    $godot = Find-Godot
    if (-not $godot) {
        Write-Host ""
        Write-Host "Godot foi instalado mas nao foi encontrado automaticamente." -ForegroundColor Red
        Write-Host "Feche essa janela, abra um terminal NOVO e rode esse script de novo."
        Read-Host "Pressione Enter para sair"
        exit 1
    }
}

Write-Host "Godot encontrado: $godot" -ForegroundColor Green
Write-Host "Abrindo o jogo..." -ForegroundColor Green
Write-Host ""

# Na primeira execucao o Godot importa os assets (audio/sprites/etc).
# Isso pode demorar alguns segundos. Depois disso, a tela do jogo abre.
& $godot --path $projectPath
