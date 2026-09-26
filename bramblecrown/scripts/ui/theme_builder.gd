class_name UITheme
extends RefCounted
## Shared palette, fonts and theme. Fonts come from the OS (no font files are shipped).

const INK := Color(0.93, 0.88, 0.76)
const INK_DIM := Color(0.72, 0.68, 0.58)
const PARCHMENT := Color(0.86, 0.79, 0.64)
const PARCHMENT_DARK := Color(0.66, 0.57, 0.42)
const BARK := Color(0.19, 0.13, 0.09)
const BARK_LIGHT := Color(0.36, 0.25, 0.15)
const PANEL := Color(0.07, 0.09, 0.08, 0.92)
const GOLD := Color(0.93, 0.74, 0.35)
const LEAF := Color(0.55, 0.82, 0.33)
const BLIGHT := Color(0.72, 0.36, 0.92)
const BLOOD := Color(0.86, 0.24, 0.2)
const WARD := Color(0.45, 0.72, 0.95)
const TYPE_COLORS := {
	"attack": Color(0.62, 0.2, 0.14),
	"skill": Color(0.2, 0.42, 0.24),
	"power": Color(0.52, 0.4, 0.13),
}
const KEYWORDS := {
	"Thicket": "Living growth. Enemies pay 2 Movement to enter it. Your connected Thicket is your Grove.",
	"Grove": "The connected Thicket you stand in. Every 3 hexes of Grove add +1 to your card damage and Ward.",
	"Blight": "Rot spread by enemies. Enemies on Blight deal +2 damage. Ending your turn on Blight costs 2 HP.",
	"Ward": "Blocks damage until your next turn.",
	"Bleed": "Loses HP equal to Bleed at the start of its turn, then Bleed drops by 1.",
	"Root": "A Rooted enemy cannot move during its next turn.",
	"Rooted": "A Rooted enemy cannot move during its next turn.",
	"Weak": "Deals 25% less damage.",
	"Clarity": "Prevents every Daze application until your next turn. Does not recover Energy already lost.",
	"Daze": "Lose up to 2 Energy at the start of your next turn (minimum 1 Energy). Dry Wick can recover that loss once.",
	"Exhaust": "Removed from your deck for the rest of this fight.",
	"Energy": "Spent to play cards. Refills to 3 each turn.",
	"Movement": "Spend to walk hex by hex. Refills to 2 each turn.",
}

static var _theme: Theme
static var _fonts := {}


static func font(kind: String = "body") -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var f := SystemFont.new()
	match kind:
		"title":
			f.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Constantia", "Georgia", "serif"])
			f.font_weight = 700
		"heading":
			f.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Constantia", "Georgia", "serif"])
			f.font_weight = 600
		_:
			f.font_names = PackedStringArray(["Constantia", "Georgia", "Cambria", "serif"])
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	_fonts[kind] = f
	return f


## Anchor a control to `preset` and place it with offsets relative to that anchor.
static func anchor(c: Control, preset: int, pos: Vector2, sz: Vector2 = Vector2.ZERO) -> void:
	c.set_anchors_preset(preset)
	if sz == Vector2.ZERO:
		sz = c.size
	c.offset_left = pos.x
	c.offset_top = pos.y
	c.offset_right = pos.x + sz.x
	c.offset_bottom = pos.y + sz.y


static func box(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 8, pad: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	s.anti_aliasing = true
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font("body")
	t.default_font_size = 22
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("normal_font", "RichTextLabel", font("body"))
	t.set_font("bold_font", "RichTextLabel", font("heading"))
	# Buttons: bark planks with a gold rim on hover.
	t.set_stylebox("normal", "Button", box(Color(0.16, 0.12, 0.08, 0.95), Color(0.45, 0.33, 0.18), 2, 10, 14))
	t.set_stylebox("hover", "Button", box(Color(0.24, 0.17, 0.1, 0.98), GOLD, 3, 10, 14))
	t.set_stylebox("pressed", "Button", box(Color(0.1, 0.07, 0.05, 1.0), GOLD, 3, 10, 14))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), Color(0.95, 0.85, 0.5), 3, 10, 14))
	t.set_stylebox("disabled", "Button", box(Color(0.12, 0.11, 0.1, 0.7), Color(0.25, 0.23, 0.2), 2, 10, 14))
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color(1, 0.95, 0.8))
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.47, 0.42))
	t.set_font("font", "Button", font("heading"))
	t.set_font_size("font_size", "Button", 24)
	t.set_stylebox("panel", "PanelContainer", box(PANEL, Color(0.35, 0.27, 0.16), 2, 12, 16))
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.06, 0.07, 0.06, 0.97), GOLD.darkened(0.3), 2, 8, 12))
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_font_size("font_size", "TooltipLabel", 20)
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 0, 4, 2))
	t.set_stylebox("grabber", "VScrollBar", box(Color(0.45, 0.35, 0.2), Color(0, 0, 0, 0), 0, 4, 2))
	_theme = t
	return t


## Wraps keyword occurrences in BBCode color for card and tooltip text.
static func keywordize(text: String) -> String:
	var out := text
	for k in ["Thicket", "Grove", "Blight", "Ward", "Bleed", "Rooted", "Root", "Weak", "Exhaust", "Energy", "Movement"]:
		var col := "#a6d86a"
		if k == "Blight":
			col = "#c48be8"
		elif k in ["Ward"]:
			col = "#8fc4f0"
		elif k in ["Bleed"]:
			col = "#e0685a"
		out = out.replace(k, "[color=%s]%s[/color]" % [col, k])
	# "Rooted" contains "Root": undo the nested double wrap.
	out = out.replace("[color=#a6d86a][color=#a6d86a]Root[/color]ed[/color]", "[color=#a6d86a]Rooted[/color]")
	return out


static func keyword_tips(text: String) -> String:
	var tips: Array = []
	for k in KEYWORDS:
		if text.contains(k) and not (k == "Root" and text.contains("Rooted")):
			tips.append("%s: %s" % [k, KEYWORDS[k]])
	return "\n".join(tips)
