# Noite dos Sobreviventes — projeto Godot

Survivor-like em Godot 4.6 + GDScript. Este diretório é o jogo em si.

## Rodar

```powershell
godot --path .
```

Ou abra `project.godot` no editor e aperte **F5**.
Sem Godot instalado? Use o `INICIAR.bat` da pasta acima — ele instala pelo winget.

## Estrutura

```
godot/
├── project.godot            autoloads, input map, janela 540x960 (retrato)
├── scenes/
│   ├── main/                Main (boot) e GameWorld (a partida)
│   ├── player/              Player + Sprite + Hurtbox
│   ├── enemies/             Enemy (dirigido por EnemyData)
│   ├── projectiles/         Projectile (6 modos de movimento)
│   ├── pickups/             Pickup (gema, moeda, coração, baú, ímã, bomba)
│   ├── world/               WorldRenderer, Altar, Merchant, Drone/Pet
│   ├── effects/             AreaEffect, DamageNumber, ScreenEffects
│   └── ui/                  menu/, hud/, upgrade/, screens/
├── scripts/
│   ├── autoload/            8 singletons
│   ├── systems/             armas, spawn, upgrades, eventos, sinergias…
│   ├── data/                Resources tipadas (WeaponData, EnemyData…)
│   └── utils/               Theme, UIFactory, Rarity, SfxBank
├── resources/               .tres: 20 armas, 16 inimigos, 12 passivas,
│                            12 relíquias, 6 heróis, 3 mapas
├── tests/                   testes headless (fumaça, telas, balanceamento)
└── docs/ARCHITECTURE.md     como tudo se conecta
```

## Adicionar conteúdo

**Arma nova**: copie um `.tres` de `resources/weapons/`, ajuste os campos e
adicione a chave em `scripts/systems/WeaponRegistry.gd` (`KEYS`). Para dar
evolução, acrescente uma entrada em `EVOLUTIONS`.

**Inimigo novo**: copie um `.tres` de `resources/enemies/` e coloque a chave nos
pesos de `SpawnDirector.WAVE_TABLE`.

**Som novo**: `scripts/utils/SfxBank.gd` — os efeitos são sintetizados em runtime
(ondas quadradas/ruído), então não precisa de arquivo de áudio.

## Testes

| Teste | O que faz |
|---|---|
| `SmokeTest` | joga 30s sozinho, escolhe upgrades, confere o mapa de teclas |
| `ScreenTest` | instancia todas as telas de UI procurando erro |
| `EvolutionTest` | valida as 20 evoluções de arma de ponta a ponta |
| `VictoryTest` | objetivo → Ceifador da Noite → tela de vitória |
| `DataReport` | imprime DPS por arma, curva de XP, raridades e vida dos inimigos |
| `BalanceTest` | um bot joga 10 minutos e reporta nível/KOs/dano por minuto |
| `PerfTest` | 180 inimigos na tela e mede o FPS |

```powershell
godot --headless --path . res://tests/SmokeTest.tscn
godot --headless --path . res://tests/ScreenTest.tscn
godot --headless --path . res://tests/EvolutionTest.tscn
godot --headless --path . res://tests/VictoryTest.tscn
godot --headless --path . res://tests/ArenaTest.tscn
godot --headless --path . res://tests/DataReport.tscn
godot --headless --path . res://tests/BalanceTest.tscn -- 0.8
godot --path . res://tests/PerfTest.tscn
```
