# Arquitetura — Noite dos Sobreviventes (Godot 4)

## Visão geral

Migração do protótipo `main.py` (pygame-ce, ~3968 linhas em um arquivo) para uma
arquitetura modular Godot 4 + GDScript, organizada como um projeto profissional.

## Princípios

1. **Data-driven**: armas, inimigos, talentos etc. são `Resource` (.tres),
   editáveis no inspector do Godot sem mexer em código.
2. **EventBus**: comunicação entre sistemas via signals globais. Zero acoplamento
   direto entre subsistemas.
3. **Cena por entidade**: cada arma/inimigo/UI é uma `.tscn` independente.
4. **Theme central**: paleta de cores em `scripts/utils/Theme.gd`. Trocar de
   skin = trocar um arquivo.
5. **Save versionado**: schema migrado entre versões em `SaveSystem.gd`.
6. **i18n desde o dia 1**: textos via `tr("KEY")`.

## Autoloads (singletons)

| Nome | Função |
|------|--------|
| `GameManager` | Estado global (BOOT/MENU/PLAYING/...), char/dificuldade/meta selecionados |
| `EventBus` | Signals globais entre sistemas |
| `SaveSystem` | Save/load JSON em `user://`, 3 slots, schema versionado |
| `AudioManager` | Pool de SFX + music player com fade, respeita mute/volumes |
| `ProgressionManager` | Loja permanente, talentos, prestige |
| `UnlockManager` | Conquistas, desbloqueios de armas/chars/relíquias |

## Fluxo de inicialização

```
Main.tscn  ──>  GameManager.state = MENU
            ──>  load_slot(1)        (SaveSystem)
            ──>  change_scene → MainMenu.tscn
```

## Mapeamento main.py → Godot

| Sistema main.py | Local em Godot |
|---|---|
| `class Game` (god object) | dividido entre autoloads + cenas |
| `progress` dict + savegame.json | `SaveSystem.data` + `user://savegame_slot*.json` |
| `WEAPON_INFO`, `ENEMY` stats | `resources/weapons/*.tres`, `resources/enemies/*.tres` |
| `make_tone`, `setup_audio` | streams reais em `assets/audio/` + `AudioManager` |
| `draw_*` funcs | cenas Control + `_draw()` quando necessário |
| `handle_events` | InputMap + signals por nó |
| `update_*` funcs | `_physics_process` por entidade |

## Próximas fases

Ver `docs/MIGRATION_PLAN.md` para a divisão F1-F8.
