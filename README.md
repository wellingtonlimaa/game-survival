# Noite dos Sobreviventes

Prototipo de jogo web inspirado em Vampire Survivors, feito em Python com pygame e preparado para Pygbag.

## Controles

- `WASD` ou setas: mover
- Mouse: mira livre em qualquer direcao
- Ataque automatico na direcao da mira, sem precisar clicar
- `1`, `2`, `3` ou clique: escolher upgrade
- `F1`, `F2`, `F3`: escolher meta de 10, 15 ou 30 minutos nos primeiros segundos
- `I`: entrar no modo infinito depois de vencer
- `P`: pausar/continuar
- `R`: reiniciar apos perder
- Menus: setas navegam, esquerda/direita ajustam opcoes, ENTER confirma, ESC volta

## Gameplay atual

- 12 armas automaticas: Varinha, Aura, Facas, Machado, Raio, Bomba, Drone, Lanca, Livro, Fogo, Foice e Corrente
- Evolucao de armas ao passar do nivel maximo
- Upgrades com raridade: comum, raro, epico e lendario
- Passivas: velocidade, regeneracao, ima, armadura, sorte e cooldown
- Chefes a cada 2 minutos
- Baus/drop especial ao derrotar chefes e elites
- Inimigos especiais: arqueiro, exploder, tanque, invocador, corredor e chefe
- Eventos de arena: chuva de meteoros, neblina e horda elite
- Objetivos de sobrevivencia de 10, 15 ou 30 minutos
- Modo infinito apos vencer

## Mapa atual

- Tilemap real em grade 32x32 desenhando apenas tiles visiveis pela camera
- Visual sem imagens externas: o jogo usa sprites, tiles, objetos e efeitos procedurais desenhados no `main.py`
- Mapa maior em bioma unico de gramado/floresta
- Gramado inicial com grama, flores e folhas procedurais
- O mapa inteiro usa variacoes procedurais de grama, flores, folhas e arvores
- Divisorias visuais largas entre as fases do mapa
- Obstaculos com colisao: arvores, pedras, pilares e cactos
- Objetos quebraveis removidos do mapa
- Altares espalhados pelo mapa com efeitos especiais
- Mini-mapa com jogador, inimigos, obstaculos, altares e baus
- Camera shake em dano, explosoes e morte de chefes

## Visual e som atual

- Sprites procedurais para jogador, gemas, baus, objetos e obstaculos
- Sprites procedurais para jogador e inimigos
- Sprites reais selecionados para armas, projeteis, baus, altares, portais, itens e UI de upgrades
- Silhuetas diferentes para cada tipo de inimigo
- Animacao simples de movimento do jogador e flutuacao das gemas
- Efeitos melhores para explosoes, raios, impactos e dano
- Numeros de dano em ataques fortes
- Musica de fundo sintetizada no proprio jogo
- Sons para tiro, dano, level up, coleta de XP, baus, explosoes, chefes e evolucao

## Visual e som avancado atual

- Tela inicial com lua procedural e particulas orbitais
- Trilha de floresta e trilha especial de chefe
- Sons diferentes por arma
- Efeitos visuais de evolucao, lendario, explosao, raio e morte
- Particulas ambientais de floresta
- Feedback visual especial para upgrades lendarios
- Vinheta e indicador de trilha no HUD

## Progressao atual

- Menu inicial com acesso a partida, loja, personagens e conquistas
- Moedas ganhas ao derrotar inimigos, chefes, sobreviver e vencer
- Save local em `savegame.json`
- Loja permanente: vida, dano, ganho de XP, velocidade e sorte
- Personagens desbloqueaveis: Cacador, Guardiao, Arcanista, Ladina, Alquimista e Monge
- Conquistas com recompensa em moedas
- Armas desbloqueadas por desafios: Machado, Bomba, Drone, Raio, Foice, Corrente, Fogo e Livro
- Estatisticas pos-partida com moedas, KOs e dano por arma

## Progressao avancada atual

- Arvore de talentos comprada com pontos de prestigio
- Sistema de prestigio com reset parcial e bonus permanente
- Codex de inimigos, armas e reliquias vistos
- Ranking local das melhores partidas
- Historico das ultimas 10 partidas
- Objetivos por personagem com recompensa dedicada
- Tres slots de save separados
- Recompensas unicas por completar metas de 10, 15 e 30 minutos

## Sistemas ambiciosos atuais

- Inventario de reliquias durante a partida
- Sistema de sinergias de build entre armas
- Modificadores de mapa por partida
- Mercador NPC que vende upgrade especial
- Portais para arenas especiais temporarias
- Pet/companheiro que orbita e atira sozinho
- Eventos narrativos leves durante a partida
- Replay estatistico no resumo final

## Conteudo atual

- Novas armas de conteudo: Lanca, Livro, Fogo, Foice e Corrente
- Chefes variantes: chefe base, bruxo e gelido
- Mini-chefes entre os chefes principais
- Reliquias raras no pool de upgrades
- Eventos raros de arena: Eclipse e Tesouro errante
- Objetivos por personagem com recompensa em moedas
- Novos desbloqueios ligados a KOs, chefes, evolucao e sobrevivencia

## Polimento atual

- Tela de pausa com continuar, reiniciar e voltar ao menu
- Opcoes de volume para musica, efeitos e mudo
- Dificuldade selecionavel: facil, normal, dificil e infernal
- Tutorial inicial rapido acessivel pelo menu
- Tela de novidades liberadas apos a partida
- Indicador de armas prontas para evoluir
- Reroll e banimento de upgrades durante a escolha
- Auto-pause quando a janela perde foco

## Rodar local

```powershell
cd "$env:USERPROFILE\Downloads\Linux\GAMES"
py -3.12 -m pip install -r requirements.txt
py -3.12 main.py
```

Se o comando `py` ainda nao existir, instale Python primeiro:

```powershell
winget install -e --id Python.Python.3.12
```

Depois feche e abra o PowerShell novamente.

Alternativa quando `python` e `pip` ja estao configurados no PATH:

```powershell
pip install -r requirements.txt
python main.py
```

## Build web com Pygbag

```powershell
pygbag .
```

Depois abra o endereco local mostrado pelo Pygbag no navegador.

## Assets

O projeto nao depende de imagens externas no momento; a pasta `assets/` pode ficar vazia.
