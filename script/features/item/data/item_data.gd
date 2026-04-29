class_name ItemData extends CustomResource

var id: String = ""

@export_group("Định danh")
@export var code: String = ""
@export var name: String = "Item"
@export_multiline var description: String = ""

@export_group("Hiển thị")
@export var icon: Texture2D

@export_group("Cài đặt kho đồ")
@export var stackable: bool = true
@export var max_stack_size: int = 100

@export_group("Thương mại")
@export var sell_price: int = 10
@export var buy_price: int = 15

@export_group("Chỉ số đặt biệt")
@export var stat: ItemStatData

enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum CategoryType { GENERAL, CONSUMABLE, EQUIPMENT, QUEST }

@export_group("Phân loại")
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var category_type: CategoryType = CategoryType.GENERAL

# ============ VIRTUAL METHODS ============

func get_tooltip_text() -> String:
	var text := "[b]%s[/b]" % name
	if rarity != ItemRarity.COMMON:
		text += "\n[color=yellow]%s[/color]" % ItemRarity.keys()[rarity]
	text += "\n%s" % description
	if sell_price > 0:
		text += "\n[color=green]Giá bán: %d vàng[/color]" % sell_price
	else:
		text += "\n[color=gray]Không thể bán[/color]"
	return text

func get_type_item() -> String:
	return "general"

func is_tool() -> bool:
	return get_type_item() == "tool"

func is_consumable() -> bool:
	return category_type == CategoryType.CONSUMABLE

func can_use() -> bool:
	return false
