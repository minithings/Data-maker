class_name ItemFishData extends ItemData

@export_group("Thông tin cá")
@export var fish_code: String = ""       # Liên kết tới FishData.fish_code
@export var weight: float = 1.0          # Cân nặng (kg) — ảnh hưởng sell_price
@export var quality: int = 1             # 1 (thường) → 5 (huyền thoại)
@export var caught_season: int = 0   # Mùa câu được (lưu để hiển thị)

func _init() -> void:
	stackable = false
	category_type = CategoryType.GENERAL

func get_type_item() -> String:
	return "fish"

func can_use() -> bool:
	return false

func get_tooltip_text() -> String:
	var text := "[b]%s[/b]" % name
	var rarity_names := ["Thường", "Bạc", "Vàng", "Quý hiếm", "Huyền thoại"]
	if quality > 1 and quality <= rarity_names.size():
		text += "\n[color=yellow]%s[/color]" % rarity_names[quality - 1]
	text += "\n%s" % description
	text += "\n⚖ %.2f kg" % weight
	if caught_season > 0:
		text += "  📅 %s" % caught_season
	if sell_price > 0:
		text += "\n[color=green]Giá bán: %d vàng[/color]" % get_actual_sell_price()
	return text

## Giá bán thực tế tính theo cân nặng và chất lượng
func get_actual_sell_price() -> int:
	var price := sell_price
	price += int(weight * 5.0)
	price = int(price * (1.0 + (quality - 1) * 0.3))
	return price

## Tên hiển thị ngắn trong inventory
func get_display_name() -> String:
	return "%s (%.1f kg)" % [name, weight]
