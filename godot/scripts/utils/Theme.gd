class_name ThemePalette
extends RefCounted

const BG_DEEP     := Color(0.055, 0.043, 0.094, 1.0)   # roxo-noite quase preto
const BG_MID      := Color(0.110, 0.094, 0.165, 1.0)   # gradient mid
const BG_HIGH     := Color(0.165, 0.141, 0.235, 1.0)   # painéis

const ACCENT_GOLD   := Color(1.000, 0.776, 0.298, 1.0) # lua/dourado
const ACCENT_PURPLE := Color(0.553, 0.412, 0.886, 1.0) # mágico
const ACCENT_CYAN   := Color(0.392, 0.808, 0.929, 1.0) # gelo/sorte
const ACCENT_RED    := Color(0.886, 0.275, 0.345, 1.0) # vida/dano

const TEXT_PRIMARY   := Color(0.953, 0.929, 0.871, 1.0)
const TEXT_SECONDARY := Color(0.722, 0.694, 0.808, 1.0)
const TEXT_MUTED     := Color(0.514, 0.486, 0.616, 1.0)

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
