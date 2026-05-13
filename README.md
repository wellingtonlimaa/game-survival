# Noite dos Sobreviventes

> ## 🍌 banana-push — Como enviar atualizações pro GitHub
>
> **Toda vez que terminar de mexer no código e quiser enviar:**
>
> ```bash
> npm run push
> ```
>
> O script `banana-push` automatiza tudo:
>
> 1. **Atualiza** `develop` (`checkout` + `pull`)
> 2. **Pergunta o nome** da sua nova branch (valida formato e duplicatas)
> 3. **Cria** a branch a partir de `develop`
> 4. **Pergunta o tipo** semântico do commit (feat/fix/refactor/style/docs/chore/test/perf/build/ci)
> 5. **Pergunta a mensagem** do commit
> 6. Faz `git add .` + `git commit` + `git push -u origin <branch>`
> 7. **Mostra a URL do Pull Request** prontinha pra abrir
>
> ### Setup inicial (em qualquer projeto Node.js)
>
> 1. Copia `banana-push/scripts/banana-push.js` pra pasta `scripts/` do seu projeto Node.js
> 2. Adiciona no `package.json`:
>    ```json
>    {
>      "scripts": {
>        "push": "node scripts/banana-push.js"
>      }
>    }
>    ```
> 3. Roda `npm run push` 🎉
>
> Documentação completa: [banana-push/README.md](banana-push/README.md)

---

Survivor-like cooperativo de sobrevivência em floresta noturna.

> Projeto **migrado de Python/pygame para Godot 4.6 + GDScript** em 8 fases,
> reestruturado em arquitetura modular e data-driven nível de estúdio profissional.

```
game-survival/
├── godot/              ← Projeto Godot 4 atual (jogo migrado)
├── main.py             ← Protótipo original em pygame (mantido como referência)
└── README.md           ← este arquivo
```

## 🚀 Como rodar

### Opção rápida — Atalho na Área de Trabalho

Já existe um atalho **"Noite dos Sobreviventes"** na sua Área de Trabalho com o ícone do diorama.
Basta dar **2 cliques** e o jogo abre.

Se o atalho não existe ou se você quiser regenerar:

```powershell
powershell -ExecutionPolicy Bypass -File "godot\criar-atalho.ps1"
```

### Opção 2 — Via .bat

Dá 2 cliques em [godot/RODAR-JOGO.bat](godot/RODAR-JOGO.bat).

### Opção 3 — Via terminal

```powershell
godot --path "godot"
```

> Se `godot` não for reconhecido, abra um novo PowerShell — o `winget` atualiza o `PATH` só em terminais novos.

### Opção 4 — Pelo editor Godot

1. Abre Godot 4.6+
2. Abre o `godot/project.godot`
3. Aperta **F5**

## 🎮 Controles

- **WASD** ou **setas**: mover
- **Mouse**: mira automática (não precisa clicar)
- **ESC**: pausar / voltar ao menu

## 🎯 Conteúdo do jogo

- **3 mapas** com biomas únicos: Floresta Sombria · Cemitério Maldito · Ermos do Crepúsculo
- **6 personagens** com stats próprios (Caçador, Arcanista, Guardião, Ladina, Alquimista, Monge)
- **3 armas iniciais** + sistema data-driven (basta criar um `.tres` pra adicionar mais)
- **10 inimigos** com 5 padrões de IA (chase, kite, explode, summon, boss)
- **3 chefes** rotacionando a cada 2 minutos
- **6 passivas** e **5 relíquias** com 4 raridades (comum/raro/épico/lendário)
- **3 sinergias** automáticas entre armas
- **4 eventos de arena**: Chuva de Meteoros · Neblina · Horda Elite · Chuva de Gemas
- **4 modificadores de mapa** aleatórios por partida
- **Pet** companheiro que atira sozinho · **Mercador** NPC
- **Meta-progressão completa**: Loja permanente · Talentos com prestige · Conquistas · Codex · Ranking · Histórico

## 🏗️ Arquitetura (nível estúdio)

Princípios aplicados:

- **Data-driven** — armas, inimigos, mapas, personagens, passivas, relíquias são todos `Resource (.tres)` editáveis no inspector do Godot, sem mexer em código
- **EventBus pattern** — comunicação por signals globais, zero acoplamento entre sistemas
- **Cena por entidade** — cada arma/inimigo/UI é uma `.tscn` independente e reutilizável
- **Theme central** — paleta de cores em `scripts/utils/Theme.gd`
- **Save versionado** — 3 slots, schema com migração entre versões
- **i18n preparado** — textos via `tr("KEY")`, fácil PT/EN/ES
- **CI/CD** — GitHub Actions valida + builda Windows + Web automaticamente

8 autoloads centralizam estado: `GameManager`, `EventBus`, `SaveSystem`, `AudioManager`,
`ProgressionManager`, `UnlockManager`, `MapRegistry`, `CharacterRegistry`.

Documentação detalhada: [godot/docs/ARCHITECTURE.md](godot/docs/ARCHITECTURE.md)

## 📦 Estrutura do projeto Godot

```
godot/
├── project.godot
├── icon.svg / icon.ico
├── assets/                         (sprites, audio, fonts, shaders)
├── scenes/
│   ├── main/                       Main.tscn, GameWorld.tscn
│   ├── player/                     Player.tscn + sprite
│   ├── enemies/                    Enemy base (instanciado por EnemyData)
│   ├── projectiles/                Projectile.tscn
│   ├── pickups/                    Gem.tscn
│   ├── world/                      WorldRenderer, Pet, Merchant
│   ├── effects/                    DamageNumber
│   └── ui/
│       ├── menu/                   MainMenu + 7 componentes modulares
│       ├── hud/                    GameHUD, Minimap, WeaponBar
│       ├── upgrade/                UpgradeScreen, UpgradeCard
│       └── screens/                Shop, Characters, Talents, etc (8 telas)
├── scripts/
│   ├── autoload/                   8 singletons globais
│   ├── systems/                    WeaponSystem, SpawnDirector, UpgradeSystem, etc
│   ├── data/                       Resources tipadas (WeaponData, EnemyData, ...)
│   └── utils/                      Theme, Rarity
├── resources/                      .tres editáveis (mapas, armas, inimigos, etc)
├── localization/                   pt_BR.csv, en.csv
├── tests/                          gdUnit4
├── docs/                           ARCHITECTURE.md
└── .github/workflows/              CI: build Windows + Web + deploy Pages
```

## 🛠️ Build para distribuição

### Windows (.exe standalone)

```powershell
godot --headless --path godot --export-release "Windows Desktop" ../builds/windows/NoiteDosSobreviventes.exe
```

### Web (HTML5)

```powershell
godot --headless --path godot --export-release "Web" ../builds/web/index.html
```

> Primeira vez precisa baixar os **Export Templates** no editor Godot
> (Project → Export → Manage Export Templates → Download).

## 🤖 CI/CD

[.github/workflows/build.yml](godot/.github/workflows/build.yml) faz automaticamente a cada push:

1. **Validate** — confere que todos os scripts parseiam sem erro
2. **Build Windows** — gera `.exe`
3. **Build Web** — gera HTML5
4. **Deploy** — publica build Web no GitHub Pages

## 📝 Versão Python original

O arquivo [main.py](main.py) é o protótipo original em pygame (~3968 linhas).
Mantido como referência da migração — não é mais o jogo principal.

Pra rodar o protótipo antigo:

```powershell
py -3.12 -m pip install -r requirements.txt
py -3.12 main.py
```
