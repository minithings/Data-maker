class_name InventorySlotData extends CustomResource

@export var item_data: ItemData
@export var amount: int = 0
@export var max_amount: int = -1

var slot_durability: int = -1

func is_empty() -> bool:
	return item_data == null or amount <= 0

func clear() -> void:
	item_data = null
	amount = 0
	slot_durability = -1

func get_max_capacity(max_capacity_default: int = 9999) -> int:
	var item_limit: int = -1
	if item_data:
		item_limit = item_data.max_stack_size if item_data.stackable else 1

	if max_amount != -1:
		if item_limit != -1:
			return mini(max_amount, item_limit)
		return max_amount

	if item_limit != -1:
		return item_limit

	return max_capacity_default

func get_free_space(max_capacity_default: int = 9999) -> int:
	if is_empty():
		return get_max_capacity(max_capacity_default)
	return maxi(0, get_max_capacity() - amount)

func get_current_durability() -> int:
	if not item_data or not item_data is ItemToolData:
		return -1
	if slot_durability < 0:
		return (item_data as ItemToolData).max_durability
	return slot_durability

func use_durability(amount_used: int = 1) -> bool:
	if not item_data or not item_data is ItemToolData:
		return true
	var tool := item_data as ItemToolData
	if slot_durability < 0:
		slot_durability = tool.max_durability
	slot_durability -= amount_used
	if slot_durability <= 0:
		slot_durability = 0
		return false
	return true
