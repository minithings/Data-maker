class_name InventorySlotData extends CustomResource

@export var item_data: ItemData
@export var amount: int = 0
@export var max_amount: int = -1
# Per-slot durability: -1 = dùng max_durability từ ItemToolData (chưa hạo mòn)
var slot_durability: int = -1

func is_empty() -> bool:
	return item_data == null or amount <= 0
	
func clear() -> void:
	item_data = null
	amount = 0
	slot_durability = -1

func get_max_amount():
	return self.max_amount

## Trả về sức chứa TỐI ĐA của slot dựa trên cấu hình slot và item đang chứa
func get_max_capacity(max_capacity_default: int = 9999) -> int:
	# 1. Tính sức chứa gốc của Item (nếu slot đang có item)
	var item_limit: int = -1
	if item_data:
		if item_data.stackable:
			item_limit = item_data.max_stack_size
		else:
			item_limit = 1

	# 2. Xử lý logic kết hợp
	if max_amount != -1:
		# Slot có giới hạn cứng -> Lấy số nhỏ nhất giữa giới hạn slot và giới hạn item
		if item_limit != -1:
			return mini(max_amount, item_limit)
		# Slot rỗng nhưng có giới hạn cứng
		return max_amount 
		
	# Slot không có giới hạn cứng -> Phụ thuộc hoàn toàn vào Item
	if item_limit != -1:
		return item_limit
		
	# Slot rỗng và không có giới hạn (trả về 9999 hoặc 1 số đủ lớn)
	return max_capacity_default

## Tính số chỗ trống còn lại trong slot
func get_free_space(max_capacity_default: int = 9999) -> int:
	if is_empty():
		return get_max_capacity(max_capacity_default)
	return maxi(0, get_max_capacity() - amount)

## Lấy durability hiện tại (init từ max nếu chưa bị đánh dấu)
func get_current_durability() -> int:
	if not item_data or not item_data is ItemToolData:
		return -1
	if slot_durability < 0:
		return (item_data as ItemToolData).max_durability
	return slot_durability

## Tiêu hao durability, trả về true nếu vẫn còn dùng được, false nếu đã hỏng
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
