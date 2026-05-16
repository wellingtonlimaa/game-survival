# Noite dos Sobreviventes — Godot 4 Edition

Survivor-like cooperativo de sobrevivência em floresta noturna, portado de pygame para
**Godot 4.6 + GDScript** com arquitetura modular e data-driven.

## Pré-requisitos

- [Godot 4.6+](https://godotengine.org/download)
- Windows 10/11, macOS, Linux

## Rodar local

```powershell
# Abre o projeto no editor Godot
godot --path .

# Roda direto sem editor
godot --path .
```

Ou abra `project.godot` no Godot Editor e aperte **F5**.

## Conteúdo

- **3 mapas** com biomas únicos (Floresta · Cemitério · Ermos)
- **6 personagens** com stats próprios e arma inicial diferente
- **3 armas iniciais** (Varinha, Facas, Aura) + sistema data-driven pra adicionar mais
- **10 inimigos** com 5 padrões de IA (chase, kite, explode, summon, boss)
- **3 chefes** rotacionando a cada 2 minutos
- **6 passivas** e **5 relíquias** com 4 raridades (comum/raro/épico/lendário)
- **3 sinergias** automáticas entre armas
- **Eventos de arena**: Chuva de Meteoros · Neblina · Horda Elite · Chuva de Gemas
- **4 modificadores** de mapa aleatórios por partida
- **Pet** companheiro que atira sozinho
- **Mercador** NPC que vende upgrade especial
- **Meta-progressão**: loja permanente, talentos com prestige, conquistas, codex, ranking

## Arquitetura

Ver [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para detalhes. Resumo:

- **Autoloads** centralizam estado (`GameManager`, `SaveSystem`, `EventBus`, `AudioManager`, `ProgressionManager`, `UnlockManager`, `MapRegistry`, `CharacterRegistry`)
- **EventBus** com signals globais conecta sistemas sem acoplamento direto
- **Resources `.tres`** definem todos os dados editáveis (armas, inimigos, mapas, etc.)
- **Cenas modulares** — cada arma, inimigo, UI é um `.tscn` reutilizável
- **3 slots de save** com schema versionado em `user://savegame_slot*.json`

## Export

### Windows
```powershell
godot --headless --path . --export-release "Windows Desktop" ../builds/windows/NoiteDosSobreviventes.exe
```

### Web (HTML5)
```powershell
godot --headless --path . --export-release "Web" ../builds/web/index.html
```

## CI/CD

GitHub Actions em [.github/workflows/build.yml](.github/workflows/build.yml):
- Valida que todos os scripts parseiam
- Compila build Windows e Web em paralelo
- Deploy automático do build Web no GitHub Pages

## Controles

- **WASD / Setas** — mover
- **Mouse** — mira automática
- **ESC** — pausar / voltar ao menu
