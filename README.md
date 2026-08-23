# 🌙 Noite dos Sobreviventes

Survivor-like de ação frenética: você não atira — você **sobrevive**. As armas
disparam sozinhas, a horda cresce sem parar e cada nível é uma escolha que muda
a run inteira.

```
game-survival/
├── godot/              ← o jogo (Godot 4.6 + GDScript)
├── main.py             ← protótipo original em pygame (referência histórica)
└── README.md           ← este arquivo
```

## ▶️ Como jogar (Windows)

**Duplo clique em [INICIAR.bat](INICIAR.bat).**
Ele acha o Godot na máquina, instala pelo `winget` se não existir e abre o jogo.

Outras formas:

| Jeito | Comando |
|---|---|
| Atalho bonitinho na Área de Trabalho | `powershell -ExecutionPolicy Bypass -File "godot\criar-atalho.ps1"` |
| Terminal | `godot --path godot` |
| Editor | abrir `godot/project.godot` e apertar **F5** |

> O `criar-atalho.ps1` gera o ícone do jogo em 7 resoluções (16→256px) e cria o
> atalho **Noite dos Sobreviventes** na Área de Trabalho + um `JOGAR.lnk` na pasta
> do projeto. Arquivo `.bat` sempre mostra aquele ícone genérico do Windows —
> quem carrega ícone é o atalho.

## 🎮 Controles

| Ação | Tecla |
|---|---|
| Mover | **WASD** / setas / analógico do controle |
| Mirar | **mouse** (largou o mouse? a mira trava sozinha no inimigo mais próximo) |
| **Dash** (com invulnerabilidade) | **ESPAÇO**, botão direito ou **A** do controle |
| Pausar | **ESC** ou **P** |
| Tela cheia | **F11** (ou no menu Ajustes) |
| Escolher carta de upgrade | **1**, **2**, **3**, **4** · **R** re-rola |

## 🩸 Como funciona uma partida

1. Você escolhe **a arma inicial** na tela de mapas e ela atira sozinha.
2. Inimigos derrubam **gemas de XP** → subiu de nível → **3 cartas** aparecem.
3. Dá pra carregar **até 6 armas** e empilhar passivas.
4. **Arma no nível máximo + a passiva certa no máximo = EVOLUÇÃO** (carta dourada).
   É o maior salto de poder do jogo.
5. Espalhadas pelo mapa há **3 arenas de chefe**, cada uma travada por um nível
   (fica escrito na arena e marcado no minimapa). No nível certo, entre no círculo,
   fique parado alguns segundos e invoque um chefe reforçado — quem vence leva
   baú, ímã, bomba e moedas.
6. Minichefe a cada 100s, chefe a cada 3 min, e no fim do objetivo desperta o
   **Ceifador da Noite** — derrote-o e a noite é sua.

Pelo caminho: **altares** (cura, XP, ouro, tempestade, desafio), o **mercador**
(troca as moedas da run por vantagens na hora), **baús**, eventos de arena
(chuva de meteoros, neblina, horda elite, fúria) e **modificadores** que mudam
as regras da noite inteira.

## 🎯 Conteúdo

- **21 armas** com comportamentos distintos (tiro automático, mira livre, órbita,
  aura, arremesso em arco, bumerangue, raio em cadeia, bomba, leque corpo a corpo,
  nova radial, lança-chamas, sentinela, teleguiado) — **cada uma com evolução própria**
- **15 passivas** (inclui +projéteis, +perfuração e +campo de visão, todas com teto)
  e **14 relíquias**, com 4 raridades (comum → lendário)
- **16 inimigos** com 8 padrões de IA + versões **elite** + 4 chefes
- **8 sinergias** de arsenal e **status**: queimadura, lentidão, atordoamento, marca
- **3 mapas** (Floresta Sombria · Cemitério Maldito · Ermos do Crepúsculo)
- **6 heróis** com estilos próprios · **6 modificadores** de noite
- **Meta-progressão**: loja permanente (10 melhorias), talentos de prestígio,
  16 conquistas, Codex, recordes, baú diário com sequência

## 🛠 Desenvolvimento

```powershell
# Roda o jogo
godot --path godot

# Testes automatizados (sem interface)
godot --headless --path godot res://tests/SmokeTest.tscn      # partida completa + input
godot --headless --path godot res://tests/ScreenTest.tscn     # carrega todas as telas
godot --headless --path godot res://tests/EvolutionTest.tscn  # as 20 evoluções
godot --headless --path godot res://tests/DataReport.tscn     # tabela de DPS/XP/inimigos
godot --headless --path godot res://tests/BalanceTest.tscn -- 0.8   # bot joga 10 min
godot --path godot res://tests/PerfTest.tscn                  # estresse de FPS

# Build Windows / Web
godot --headless --path godot --export-release "Windows Desktop" ../builds/windows/NoiteDosSobreviventes.exe
godot --headless --path godot --export-release "Web" ../builds/web/index.html
```

Arquitetura detalhada: [godot/docs/ARCHITECTURE.md](godot/docs/ARCHITECTURE.md)

## 🍌 banana-push — enviar atualizações pro GitHub

```bash
npm run push
```

Cria a branch, faz commit semântico e devolve a URL do PR.
Documentação: [banana-push/README.md](banana-push/README.md)
