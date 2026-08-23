extends "res://scenes/ui/screens/ScreenBase.gd"

## Como jogar — explica os sistemas de verdade (antes a tela era vazia).

const CARDS := [
	{"icon": "🎯", "title": "O básico", "text": "Você ataca sozinho. Seu trabalho é se posicionar: junte as gemas roxas, fuja da horda e sobreviva até o tempo do objetivo acabar."},
	{"icon": "🕹", "title": "Controles", "text": "WASD/setas movem. O mouse mira; se você largar o mouse, a mira trava sozinha no inimigo mais próximo. ESPAÇO dá um dash com invulnerabilidade. F11 liga a tela cheia."},
	{"icon": "🔫", "title": "Escolha sua arma", "text": "Antes de começar, na tela de mapas, dá pra escolher COM QUAL ARMA você entra: varinha, facas, espingarda, míssil teleguiado, lança-chamas... Cada uma muda o jeito de jogar."},
	{"icon": "⬆", "title": "Subiu de nível", "text": "Cada nível abre 3 cartas. Armas novas ocupam até 6 espaços; passivas fortalecem TODAS as armas. Use as teclas 1-4 pra escolher rápido."},
	{"icon": "⭐", "title": "Evolução", "text": "Arma no nível máximo + a passiva certa no máximo = carta dourada de EVOLUÇÃO. É o maior salto de poder da run — persiga isso."},
	{"icon": "✦", "title": "Sinergias", "text": "Certas combinações de armas ativam sinergias com bônus permanentes: Varinha+Relâmpago, Facas+Foice, Fogo+Chamas, e mais."},
	{"icon": "🔮", "title": "Altares", "text": "Espalhados pelo mapa (veja no minimapa). Encoste pra ganhar vida, XP, ouro, um raio devastador ou um desafio com baú."},
	{"icon": "🛒", "title": "Mercador", "text": "As moedas coletadas NA partida compram vantagens com ele: cura total, dano, armas e baús. Ele fecha depois de 3 vendas."},
	{"icon": "📦", "title": "Baús", "text": "Chefes e minichefes soltam baús: cartas com raridade melhor. Elite Épico e Lendário multiplicam o efeito."},
	{"icon": "🏟", "title": "Arenas de chefe", "text": "Três círculos rituais no mapa (aparecem no minimapa). Cada um pede um NÍVEL — chegou nele, entre no círculo e fique parado alguns segundos pra invocar um chefe reforçado. Quem vence leva baú, ímã, bomba e moedas."},
	{"icon": "☠", "title": "Chefes do relógio", "text": "Mesmo sem entrar em arena, minichefe aparece a cada 100s e chefe a cada 3 min. No fim do objetivo desperta o Ceifador da Noite — matá-lo é a vitória."},
	{"icon": "🎯", "title": "Passivas que mudam o jogo", "text": "Tiro Múltiplo dá +1 projétil em TODAS as armas · Ponta de Aço faz atravessar mais inimigos · Cadência atira mais rápido · Tiro Veloz acelera os projéteis · Visão de Coruja afasta a câmera (tem teto, pra não ficar roubado)."},
	{"icon": "🏪", "title": "Entre partidas", "text": "Moedas viram melhorias permanentes na Loja. Sobreviver 10 min ou 1000 KOs libera o Prestígio, que dá pontos de Talento."},
]


func _init() -> void:
	screen_title = "Como jogar"
	screen_icon = "📖"


func _build_content() -> void:
	for card in CARDS:
		content.add_child(_make_card(card))
	SaveSystem.set_value("tutorial_seen", true)
	SaveSystem.set_value("has_announcement", false)


func _make_card(card: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.BORDER, 14, 2, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon := UI.make_label(String(card["icon"]), 28, P.ACCENT_GOLD)
	icon.custom_minimum_size = Vector2(40, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)
	texts.add_child(UI.make_label(String(card["title"]), 17, P.TEXT_PRIMARY, 2))
	var body := UI.make_label(String(card["text"]), 12, P.TEXT_SECONDARY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(body)
	return panel
