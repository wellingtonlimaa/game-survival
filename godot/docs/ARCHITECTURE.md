# Arquitetura — Noite dos Sobreviventes (Godot 4.6)

## Princípios

1. **Data-driven** — armas, inimigos, passivas, relíquias, mapas e heróis são
   `Resource` (`.tres`) editáveis no inspector. Adicionar arma nova = criar um
   `.tres` + registrar a chave em `WeaponRegistry.KEYS`.
2. **EventBus** — sistemas conversam por signals globais (`scripts/autoload/EventBus.gd`).
   Ninguém guarda referência de ninguém.
3. **Cena por entidade** — cada inimigo/projétil/efeito/tela é uma `.tscn` isolada.
4. **UI em código** — telas de menu montam os nós em runtime a partir de
   `ScreenBase` + `UIFactory`, então não existe `.tscn` desatualizado quebrando `%NomeUnico`.
5. **Paleta central** — `scripts/utils/Theme.gd`. Trocar o visual = trocar um arquivo.
6. **Save versionado** — `SaveSystem` migra schema antigo (v1 → v2) sem perder progresso.

## Autoloads

| Nome | Função |
|------|--------|
| `GameManager` | Estado (MENU/PLAYING/UPGRADE/PAUSED/GAME_OVER), dificuldade, objetivo da run |
| `EventBus` | Signals globais (combate, pickups, UI, áudio, meta) |
| `SaveSystem` | JSON em `user://`, 3 slots, migração, energia com regeneração real |
| `AudioManager` | Buses Music/SFX + **SFX sintetizados em runtime** (`SfxBank`) |
| `ProgressionManager` | Loja permanente, talentos, prestígio, baú diário, nível de conta |
| `UnlockManager` | Conquistas (com toast na hora), desbloqueios, Codex |
| `MapRegistry` / `CharacterRegistry` | Catálogo de mapas e heróis |

## Fluxo

```
Main.tscn → MainMenu → MapSelection → GameWorld
                                        ├── WorldGenerator (mapa procedural)
                                        ├── WorldRenderer (estático + camada de partículas)
                                        ├── Player (+ Camera, Hurtbox, Sprite)
                                        ├── WeaponSystem   → Projectile / AreaEffect / Drone
                                        ├── SpawnDirector  → Enemy (IA + status + drops)
                                        ├── UpgradeSystem  → UpgradeScreen
                                        ├── EventDirector  → eventos de arena
                                        ├── ScreenEffects  → shake, flash, vinheta, hit-stop
                                        └── GameHUD        → barras, minimapa, chefe, toasts
```

## Sistemas de combate

- **WeaponSystem** (`scripts/systems/WeaponSystem.gd`) — até 6 slots. Lê os stats do
  jogador (`damage_mult`, `area_mult`, `cooldown_mult`, `crit_chance`, …) e monta
  cada disparo. 13 comportamentos: tiro automático, tiro na mira, órbita, aura,
  arremesso em arco, bumerangue, raio em cadeia, bomba, leque, nova radial,
  lança-chamas, sentinela e teleguiado.
- **WeaponRegistry** — catálogo + regras de evolução. A arma evoluída é gerada em
  runtime aplicando *overrides* sobre o recurso base (sem duplicar 20 arquivos).
- **Enemy** — IA (8 padrões), status (queimadura/lentidão/atordoamento/marca),
  separação entre inimigos via `get_overlapping_areas`, dano de contato contínuo,
  drops (gema/moeda/coração/baú) e telegrafia visual de ataque.
- **Projectile** — modos reto/órbita/bumerangue/arco/bomba/teleguiado, perfuração
  com cooldown por alvo, crítico, status, roubo de vida, explosão e cadeia.

## Performance (o que segura os 60 fps)

| Técnica | Onde |
|---|---|
| Cenário "assado" num SubViewport (1 textura em vez de ~4000 primitivas) | `WorldRenderer` |
| Inimigo só redesenha quando o visual muda (não a cada quadro) | `Enemy._maybe_redraw` |
| Campos quentes (velocidade, raio, dano) em cache, sem reflexão no loop | `Enemy.setup` |
| Números de dano desenham 1x e animam por `modulate`/`position` | `DamageNumber` |
| Drops se fundem depois de 120 itens no chão | `Enemy._merge_into_nearby` |
| Minimapa redesenha ~12x/s e limita pontos | `Minimap` |
| Teto de inimigos (130) e de efeitos (40) + despawn por distância | `SpawnDirector`, `GameWorld` |

Medição: `res://tests/PerfTest.tscn` (90 inimigos ≈ cenário real, 180 = estresse).

## Arenas de chefe

`WorldGenerator.BOSS_ARENAS` define 3 círculos por mapa (posição em % do mundo,
chefe e nível exigido). `scenes/world/BossArena.gd` cuida do ciclo:

```
LOCKED (mostra "REQUER NÍVEL X") → READY → CHANNELING (2,5s dentro do círculo)
   → FIGHTING (GameWorld chama SpawnDirector.spawn_arena_boss: +60% vida, +15% dano)
   → CLEARED (solta baú + ímã + bomba + coração + moedas)
```

O minimapa desenha um anel dourado (liberada) ou cinza (travada) em cada arena.
Os minichefes e chefes do relógio continuam existindo em paralelo.

## Progressão

| Camada | Onde vive |
|---|---|
| Nível da run (XP das gemas) | `Player.xp_needed()` + `UpgradeSystem` |
| Moedas da run | `GameWorld.run_coins` (gasta no mercador) |
| Moedas permanentes | `SaveSystem` → Loja (`ProgressionManager.PERMANENT_UPGRADES`) |
| Nível de conta | `ProgressionManager.add_meta_xp` (libera telas e dificuldades) |
| Prestígio | zera loja/moedas, dá pontos de talento e +3% dano/vida por nível |

## Testes

`tests/` roda sem interface gráfica:

```powershell
godot --headless --path . res://tests/SmokeTest.tscn      # partida completa + mapa de teclas
godot --headless --path . res://tests/ScreenTest.tscn     # carrega todas as telas de UI
godot --headless --path . res://tests/EvolutionTest.tscn  # as 20 evoluções de arma
godot --headless --path . res://tests/VictoryTest.tscn    # objetivo → chefe final → vitória
godot --headless --path . res://tests/ArenaTest.tscn      # arena: trava por nível → invoca → prêmio
godot --headless --path . res://tests/VisionTest.tscn     # tetos de visão/projéteis/perfuração
godot --headless --path . res://tests/DataReport.tscn     # DPS/XP/vida dos inimigos em tabela
godot --headless --path . res://tests/BalanceTest.tscn -- 0.8   # bot joga 10 min e reporta a curva
godot --path . res://tests/PerfTest.tscn -- realista      # FPS com a horda cheia
godot --path . res://tests/Shot.tscn -- <pasta> game      # captura PNGs pra revisão visual
```

## Onde mexer pra…

| Quero… | Arquivo |
|---|---|
| Criar arma nova | `resources/weapons/*.tres` + `WeaponRegistry.KEYS` |
| Balancear inimigo | `resources/enemies/*.tres` |
| Mudar ritmo da horda | `scripts/systems/SpawnDirector.gd` (`WAVE_TABLE`, `_spawn_interval`) |
| Ajustar cartas de upgrade | `scripts/systems/UpgradeSystem.gd` (pesos do pool) |
| Trocar cores | `scripts/utils/Theme.gd` |
| Mexer nas arenas de chefe | `scripts/systems/WorldGenerator.gd` (`BOSS_ARENAS`) |
| Teto do campo de visão | `scenes/player/Player.gd` (`VISION_MAX`) |
| Novo evento de arena | `scripts/systems/EventDirector.gd` (`EVENT_INFO`) |
| Nova conquista | `scripts/autoload/UnlockManager.gd` |
| Novo som | `scripts/utils/SfxBank.gd` (síntese, sem arquivo de áudio) |
