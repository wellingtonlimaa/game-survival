class_name ThemePalette
extends RefCounted

## Paleta central do jogo. Todo desenho procedural e UI puxa daqui.

const BG_DEEP     := Color(0.043, 0.035, 0.078, 1.0)   # roxo-noite quase preto
const BG_MID      := Color(0.094, 0.078, 0.149, 1.0)   # painéis
const BG_HIGH     := Color(0.165, 0.141, 0.235, 1.0)   # painéis destacados
const BORDER      := Color(0.275, 0.227, 0.412, 1.0)
const BORDER_SOFT := Color(0.196, 0.165, 0.290, 1.0)

const ACCENT_GOLD   := Color(1.000, 0.776, 0.298, 1.0) # lua/dourado
const ACCENT_PURPLE := Color(0.553, 0.412, 0.886, 1.0) # mágico
const ACCENT_CYAN   := Color(0.392, 0.808, 0.929, 1.0) # gelo/sorte
const ACCENT_RED    := Color(0.886, 0.275, 0.345, 1.0) # vida/dano
const ACCENT_GREEN  := Color(0.439, 0.871, 0.494, 1.0) # cura
const ACCENT_ORANGE := Color(1.000, 0.561, 0.243, 1.0) # fogo

const TEXT_PRIMARY   := Color(0.953, 0.929, 0.871, 1.0)
const TEXT_SECONDARY := Color(0.722, 0.694, 0.808, 1.0)
const TEXT_MUTED     := Color(0.514, 0.486, 0.616, 1.0)
const TEXT_DARK      := Color(0.137, 0.094, 0.039, 1.0)

const CRIT      := Color(1.000, 0.949, 0.420, 1.0)
const BURN      := Color(1.000, 0.478, 0.180, 1.0)
const FROST     := Color(0.549, 0.882, 1.000, 1.0)
const POISON    := Color(0.549, 0.902, 0.400, 1.0)
const SHOCK     := Color(0.722, 0.867, 1.000, 1.0)

const RARITY := {
	"comum":    Color(0.722, 0.694, 0.808, 1.0),
	"raro":     Color(0.392, 0.808, 0.929, 1.0),
	"epico":    Color(0.624, 0.388, 0.937, 1.0),
	"lendario": Color(1.000, 0.776, 0.298, 1.0),
}

const CURRENCY := {
	"coins":  Color(1.000, 0.776, 0.298, 1.0),
	"gems":   Color(0.392, 0.808, 0.929, 1.0),
	"energy": Color(1.000, 0.949, 0.420, 1.0),
}


static func hp_color(pct: float) -> Color:
	if pct > 0.5:
		return ACCENT_GREEN
	if pct > 0.25:
		return ACCENT_GOLD
	return ACCENT_RED
