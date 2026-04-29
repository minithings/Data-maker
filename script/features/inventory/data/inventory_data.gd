class_name InventoryData extends CustomResource

@export var slots: Array[InventorySlotData] = []
@export var max_slots: int = 24
@export var selected_index: int = -1
@export var inventory_id: String
@export var inventory_name: String

var _free_slot_count: int = 0
var _item_totals: Dictionary = {}  # { item_code: total_amount }

func _init(_max_slots: int = 24, _max_stack: int = -1) -> void:
	max_slots = _max_slots
	_free_slot_count = _max_slots
	for i in range(_max_slots):
		var new_slot = InventorySlotData.new()
		new_slot.max_amount = _max_stack
		slots.append(new_slot)

func get_slot(slot_index: int) -> InventorySlotData:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index]

func get_current_slot(slot_index: int = -1) -> InventorySlotData:
	if slot_index < 0:
		return get_slot(selected_index)
	return get_slot(slot_index)

func add_item(item_data: ItemData, amount: int = 1, is_silent: bool = false) -> int:
	var initial_amount := amount

	# 1. Stack vào slot có sẵn
	if item_data.stackable:
		for slot in slots:
			if amount <= 0: break
			if slot.item_data != null and slot.item_data.code == item_data.code \
					and slot.amount < slot.item_data.max_stack_size:
				var can_add = min(amount, slot.item_data.max_stack_size - slot.amount)
				slot.amount += can_add
				amount -= can_add
				_item_totals[item_data.code] = _item_totals.get(item_data.code, 0) + can_add

	# 2. Thêm vào slot trống
	if amount > 0:
		for slot in slots:
			if amount <= 0: break
			if slot.item_data == null:
				slot.item_data = item_data
				var max_stack := item_data.max_stack_size if item_data.stackable else 1
				if slot.max_amount != -1:
					max_stack = min(max_stack, slot.max_amount)
				var can_add = min(amount, max_stack)
				slot.amount = can_add
				amount -= can_add
				_free_slot_count -= 1
				_item_totals[item_data.code] = _item_totals.get(item_data.code, 0) + can_add

	var added_amount := initial_amount - amount
	if added_amount > 0 and not is_silent:
		EventBus.inventory_updated.emit(inventory_id)
	return added_amount

func clear_inventory() -> void:
	for slot in slots:
		slot.item_data = null
		slot.amount = 0
	_free_slot_count = max_slots
	_item_totals.clear()
	EventBus.inventory_updated.emit(inventory_id)

func remove_item_by_id(item_id: String, amount: int = 1, type: String = "code", is_silent: bool = false) -> bool:
	var remaining := amount
	for slot in slots:
		if not slot.item_data: continue
		var match_val: String = str(slot.item_data.get(type)) if slot.item_data.get(type) != null else ""
		if match_val != item_id: continue
		var item_code: String = slot.item_data.code
		var remove_amount = min(remaining, slot.amount)
		slot.amount -= remove_amount
		remaining -= remove_amount
		_item_totals[item_code] = max(0, _item_totals.get(item_code, 0) - remove_amount)
		if slot.amount <= 0:
			slot.clear()
			_free_slot_count += 1
			if _item_totals.get(item_code, 0) <= 0:
				_item_totals.erase(item_code)
		if remaining <= 0: break

	var removed := amount - remaining
	if removed > 0 and not is_silent:
		EventBus.inventory_updated.emit(inventory_id)
	return remaining <= 0

func remove_item_by_type(item_type: String, amount: int = 1) -> bool:
	var total_available := 0
	for slot in slots:
		if slot.item_data and slot.item_data["type"] == item_type:
			total_available += slot.amount
			
	if total_available < amount:
		return false

	# 2. Thực hiện trừ nếu đã chắc chắn đủ số lượng
	var remaining := amount
	for slot in slots:
		if not slot.item_data or slot.item_data.get_type_item() != item_type: 
			continue
			
		# Lấy code thật của vật phẩm đang nằm trong slot này (vd: "wheat_seed")
		var actual_item_code: String = slot.item_data["code"]
		var remove_amount = min(remaining, slot.amount)
		
		slot.amount -= remove_amount
		remaining -= remove_amount
		
		# Cập nhật _item_totals dựa trên code thật
		_item_totals[actual_item_code] = max(0, _item_totals.get(actual_item_code, 0) - remove_amount)
		
		if slot.amount <= 0:
			slot.clear()
			_free_slot_count += 1
			if _item_totals.get(actual_item_code, 0) <= 0:
				_item_totals.erase(actual_item_code)
				
		if remaining <= 0: break

	var removed := amount - remaining
	if removed > 0:
		EventBus.inventory_updated.emit(inventory_id)
		
	return remaining <= 0


func remove_item(item_data: ItemData, amount: int = 1) -> bool:
	var remaining := amount
	for slot in slots:
		if slot.item_data != item_data: continue
		var remove_amount = min(remaining, slot.amount)
		slot.amount -= remove_amount
		remaining -= remove_amount
		_item_totals[item_data.code] = max(0, _item_totals.get(item_data.code, 0) - remove_amount)
		if slot.amount <= 0:
			slot.item_data = null
			slot.amount = 0
			_free_slot_count += 1
			if _item_totals.get(item_data.code, 0) <= 0:
				_item_totals.erase(item_data.code)
		if remaining <= 0: break

	var removed := amount - remaining
	if removed > 0:
		EventBus.inventory_updated.emit(inventory_id)
	return remaining <= 0

func swap_slots(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= slots.size() \
			or to_index < 0 or to_index >= slots.size():
		return false

	var temp := slots[from_index].duplicate()
	slots[from_index].item_data = slots[to_index].item_data
	slots[from_index].amount = slots[to_index].amount
	slots[to_index].item_data = temp.item_data
	slots[to_index].amount = temp.amount

	EventBus.inventory_updated.emit(inventory_id)
	return true

func set_selected_index(index: int) -> void:
	if index >= 0 and index != selected_index:
		selected_index = index
		EventBus.inventory_updated.emit(inventory_id)

func use_item_at_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var slot := slots[slot_index]
	if not slot or not slot.item_data:
		return false
	var item := slot.item_data
	EventBus.inventory_item_used.emit(inventory_id, slot_index, item)
	if item.is_consumable():
		remove_item_at(slot_index, 1)
	return true

# O(1) nhờ _item_totals cache
func get_total_item(item_code: String) -> int:
	return _item_totals.get(item_code, 0)

func check_item_required(item_id: String, amount: int) -> bool:
	return get_total_item(item_id) >= amount

func total_slot_have_item() -> int:
	var total := 0
	for slot in slots:
		if slot.item_data:
			total += 1
	return total

func calculate_addable_amount(item_data: ItemData, quantity: int) -> int:
	if not item_data: return 0

	var remaining_to_calc := quantity
	var total_can_add := 0

	# Bước 1: stack vào slot cùng loại có sẵn (phải làm trước kể cả khi full slot)
	if item_data.stackable and _item_totals.has(item_data.code):
		for slot in slots:
			if remaining_to_calc <= 0: break
			if slot.item_data and slot.item_data.code == item_data.code:
				var max_stack := item_data.max_stack_size
				if slot.max_amount != -1:
					max_stack = min(max_stack, slot.max_amount)
				var space_in_slot := max_stack - slot.amount
				if space_in_slot > 0:
					var can_take: int = min(remaining_to_calc, space_in_slot)
					total_can_add += can_take
					remaining_to_calc -= can_take

	# Bước 2: slot trống
	if remaining_to_calc > 0 and _free_slot_count > 0:
		var max_stack := item_data.max_stack_size if item_data.stackable else 1
		total_can_add += _free_slot_count * max_stack
		total_can_add = min(total_can_add, quantity)

	return total_can_add

func can_add_item(item_data: ItemData, quantity: int = 1) -> bool:
	return calculate_addable_amount(item_data, quantity) >= quantity

func is_full() -> bool:
	return _free_slot_count <= 0

func is_empty() -> bool:
	return _item_totals.is_empty()

func remove_item_at(index: int, amount: int) -> bool:
	if index < 0 or index >= slots.size():
		return false
	var slot := slots[index]
	if slot.item_data == null or slot.amount < amount:
		return false
	var item_code := slot.item_data.code
	slot.amount -= amount
	_item_totals[item_code] = max(0, _item_totals.get(item_code, 0) - amount)
	if slot.amount <= 0:
		slot.item_data = null
		slot.amount = 0
		_free_slot_count += 1
		if _item_totals.get(item_code, 0) <= 0:
			_item_totals.erase(item_code)
	EventBus.inventory_updated.emit(inventory_id)
	return true

func has_item_type(type_name: String) -> bool:
	for slot in slots:
		if slot.item_data and slot.amount > 0:
			if type_name == "any":
				return true
			if slot.item_data.get_type_item() == type_name:
				return true
			if slot.item_data.code == type_name:
				return true
	return false

func add_item_at_index(index: int, item_data: ItemData, amount: int, is_silent: bool = false) -> int:
	if index < 0 or index >= slots.size():
		return 0
	var slot := slots[index]
	var added_amount := 0
	var slot_was_empty := slot.item_data == null

	if slot.item_data == null:
		slot.item_data = item_data
		var limit := item_data.max_stack_size if item_data.stackable else 1
		if slot.max_amount != -1:
			limit = min(limit, slot.max_amount)
		added_amount = min(amount, limit)
		slot.amount = added_amount
	elif slot.item_data.code == item_data.code and item_data.stackable:
		var limit := item_data.max_stack_size
		if slot.max_amount != -1:
			limit = min(limit, slot.max_amount)
		var space := limit - slot.amount
		if space > 0:
			added_amount = min(amount, space)
			slot.amount += added_amount

	if added_amount > 0:
		if slot_was_empty:
			_free_slot_count -= 1
		_item_totals[item_data.code] = _item_totals.get(item_data.code, 0) + added_amount
		if not is_silent:
			EventBus.inventory_updated.emit(inventory_id)

	return added_amount

## Rebuild cache từ đầu dựa trên slots thực tế.
## Dùng sau khi code bên ngoài thao tác trực tiếp lên slots (transfer_item, swap, v.v.)
func sync_cache() -> void:
	_free_slot_count = 0
	_item_totals.clear()
	for slot in slots:
		if slot.item_data == null:
			_free_slot_count += 1
		else:
			_item_totals[slot.item_data.code] = _item_totals.get(slot.item_data.code, 0) + slot.amount

# ============ RANGE OPERATIONS ============
func get_total_item_in_range(item_code: String, start_idx: int, end_idx: int) -> int:
	var total := 0
	for i in range(start_idx, end_idx):
		if i >= slots.size(): break
		var slot := slots[i]
		if slot.item_data and slot.item_data.code == item_code:
			total += slot.amount
	return total

func remove_item_in_range(item_code: String, amount: int, start_idx: int, end_idx: int) -> int:
	var remaining := amount
	var removed_total := 0
	for i in range(start_idx, end_idx):
		if remaining <= 0 or i >= slots.size(): break
		var slot := slots[i]
		if slot.item_data and slot.item_data.code == item_code:
			var remove_amount = min(remaining, slot.amount)
			slot.amount -= remove_amount
			remaining -= remove_amount
			removed_total += remove_amount
			_item_totals[item_code] = max(0, _item_totals.get(item_code, 0) - remove_amount)
			if slot.amount <= 0:
				slot.clear()
				_free_slot_count += 1
				if _item_totals.get(item_code, 0) <= 0:
					_item_totals.erase(item_code)
	if removed_total > 0:
		EventBus.inventory_updated.emit(inventory_id)
	return removed_total

func find_item_by_type_in_range(item_type: String, start_idx: int, end_idx: int) -> ItemData:
	for i in range(start_idx, end_idx):
		if i >= slots.size(): break
		var slot := slots[i]
		if slot.item_data and slot.amount > 0:
			if slot.item_data.get_type_item() == item_type:
				return slot.item_data
	return null
