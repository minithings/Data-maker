class_name InventoryData extends CustomResource
# Thuộc tính cơ bản
@export var slots: Array[InventorySlotData] = []
@export var max_slots: int = 24
@export var selected_index: int = -1
@export var inventory_id: String
@export var inventory_name: String

func _init(_max_slots: int = 24, _max_stack = -1):
	max_slots = _max_slots
	for i in range(_max_slots):
		var new_slot = InventorySlotData.new()
		new_slot.max_amount = _max_stack
		slots.append(new_slot)

# Lấy Item by slot
func get_item(slot_index: int) -> InventorySlotData:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index]

func get_slot(slot_index: int) -> InventorySlotData:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index]

func get_current_slot(slot_index = null) -> InventorySlotData:
	if not slot_index:
		return get_item(selected_index)
	return get_item(slot_index)

#Thêm item vào inventory
func add_item(item_data: ItemData, amount: int = 1, is_silent: bool = false) -> int:
	var initial_amount = amount
	
	# 1. Thêm vào các slot đang có sẵn (Stack)
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.item_data != null and slot.item_data.code == item_data.code and slot.item_data.stackable and slot.amount < slot.item_data.max_stack_size:
			var can_add = min(amount, slot.item_data.max_stack_size - slot.amount)
			slot.amount += can_add
			amount -= can_add
			if amount <= 0: break
			
	# 2. Thêm vào slot trống
	if amount > 0:
		for i in range(slots.size()):
			var slot = slots[i]
			if slot.item_data == null:
				slot.item_data = item_data
				var max_stack = item_data.max_stack_size if item_data.stackable else 1
				if slot.max_amount != -1: max_stack = min(max_stack, slot.max_amount)
				
				var can_add = min(amount, max_stack)
				slot.amount = can_add
				amount -= can_add
				if amount <= 0: break
				
	var added_amount = initial_amount - amount
	if added_amount > 0 and not is_silent:
		EventBus.inventory_updated.emit(inventory_id)
		
	return added_amount # Trả về số lượng thực tế đã add thành công
#Clean inventory slots
func clear_inventory():
	for i in range(slots.size()):
		slots[i].item_data = null
		slots[i].amount = 0
	EventBus.inventory_updated.emit(inventory_id)

func remove_item_by_id(item_id: String, amount: int = 1, type: String = "code") -> bool:
	var remaining = amount
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.item_data: continue
		if slot.item_data[type] == item_id:
			var remove_amount = min(remaining, slot.amount)
			slot.amount -= remove_amount
			remaining -= remove_amount
			
			if slot.amount <= 0:
				slot.item_data = null
				slot.amount = 0
			
			EventBus.inventory_updated.emit(inventory_id)
			
			if remaining <= 0:
				return true
	return false

func remove_item(item_data: ItemData, amount: int = 1) -> bool:
	var remaining = amount
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.item_data == item_data:
			var remove_amount = min(remaining, slot.amount)
			slot.amount -= remove_amount
			remaining -= remove_amount
			
			if slot.amount <= 0:
				slot.item_data = null
				slot.amount = 0
			
			EventBus.inventory_updated.emit(inventory_id)
			
			if remaining <= 0:
				return true
	return false
func swap_slots(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= slots.size() or to_index < 0 or to_index >= slots.size():
		return false
		
	var temp = slots[from_index].duplicate()
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

## Use item at specific slot (for consumables, tools, etc.)
func use_item_at_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot = slots[slot_index]
	if not slot or not slot.item_data:
		return false
	
	var item = slot.item_data
	# Emit signal to let other systems handle the item use
	EventBus.inventory_item_used.emit(inventory_id, slot_index, item)
	
	# For consumables, remove one from stack
	if item.is_consumable():
		remove_item_at(slot_index, 1)
		return true
	
	return true

func get_total_item(item_code: String, type: String = "code"):
	var total: int = 0
	for slot in slots:
		if slot.item_data and slot.item_data[type] == item_code:
			total += slot.amount
	return total
func check_item_required(item_id: String, amount: int, type: String = "code"):
	var total = get_total_item(item_id, type)
	return total >= amount
func total_slot_have_item() -> int:
	var total = 0
	for slot in slots:
		if slot.item_data:
			total += 1
	return total

## Tính toán xem có thể thêm bao nhiêu item này vào inventory
func calculate_addable_amount(item_data: ItemData, quantity: int) -> int:
	if not item_data: return 0
	
	if is_full():
		return 0
	
	var remaining_to_calc = quantity
	var total_can_add = 0
	
	# 1. ƯU TIÊN: Lấp đầy các slot đang chứa item cùng loại (nếu stackable)
	if item_data.stackable:
		for slot in slots:
			if remaining_to_calc <= 0: break
			
			# Kiểm tra đúng loại item và còn chỗ trong stack
			if slot.item_data and slot.item_data.code == item_data.code:
				var max_stack = item_data.max_stack_size
				# Nếu slot có giới hạn riêng (ví dụ rương giới hạn) thì dùng min
				if slot.max_amount != -1:
					max_stack = min(max_stack, slot.max_amount)
					
				var space_in_slot = max_stack - slot.amount
				if space_in_slot > 0:
					var can_take = min(remaining_to_calc, space_in_slot)
					total_can_add += can_take
					remaining_to_calc -= can_take

	# 2. SAU ĐÓ: Tìm các slot trống
	for slot in slots:
		if remaining_to_calc <= 0: break
		
		if slot.is_empty():
			var max_stack = item_data.max_stack_size if item_data.stackable else 1
			# Check giới hạn riêng của slot
			if slot.max_amount != -1:
				max_stack = min(max_stack, slot.max_amount)
			
			var can_take = min(remaining_to_calc, max_stack)
			total_can_add += can_take
			remaining_to_calc -= can_take
	
	return total_can_add

## Helper check nhanh xem có chứa đủ số lượng yêu cầu không
func can_add_item(item_data: ItemData, quantity: int = 1) -> bool:
	return calculate_addable_amount(item_data, quantity) >= quantity

## Helper kiểm tra xem túi có full hoàn toàn không (không còn slot trống nào)
func is_full() -> bool:
	for slot in slots:
		# 1. Nếu còn slot trống hoàn toàn -> Chưa full
		if slot.item_data == null:
			return false
		
		# 2. Nếu slot có item, kiểm tra xem còn chỗ để stack thêm không
		if slot.item_data.stackable:
			var max_stack = slot.item_data.max_stack_size
			
			# Kiểm tra giới hạn riêng của slot (giống logic trong calculate_addable_amount)
			if slot.max_amount != -1:
				max_stack = min(max_stack, slot.max_amount)
			
			# Nếu lượng hiện tại nhỏ hơn max -> Vẫn còn nhét thêm được -> Chưa full
			if slot.amount < max_stack:
				return false
				
	# Nếu duyệt hết các slot mà không có chỗ nào trống hoặc còn chỗ stack -> Full
	return true

func is_empty() -> bool:
	for slot in slots:
		if slot.item_data != null and slot.amount > 0:
			return false
	return true
## Xóa item tại slot cụ thể
func remove_item_at(index: int, amount: int) -> bool:
	if index < 0 or index >= slots.size():
		return false
		
	var slot = slots[index]
	if slot.item_data == null or slot.amount < amount:
		return false
		
	slot.amount -= amount
	
	if slot.amount <= 0:
		slot.item_data = null
		slot.amount = 0
		
	EventBus.inventory_updated.emit(inventory_id)
	return true
## Kiểm tra xem trong kho có item thuộc loại (type) hoặc mã (code) cụ thể không
func has_item_type(type_name: String) -> bool:
	for slot in slots:
		if slot.item_data and slot.amount > 0:
			if type_name == "any":
				return true
			# Kiểm tra theo Type (Ví dụ: "food", "resource", "tool")
			var type_item = slot.item_data.get_type_item()
			if type_item == type_name:
				return true
			
			# Kiểm tra theo Item Code
			if slot.item_data.code == type_name:
				return true
	return false

func add_item_at_index(index: int, item_data: ItemData, amount: int) -> int:
	if index < 0 or index >= slots.size():
		return 0
	
	var slot = slots[index]
	var added_amount = 0
	
	# Trường hợp 1: Slot trống
	if slot.item_data == null:
		slot.item_data = item_data
		# Lấy min giữa số lượng cần thêm và giới hạn stack của item
		# Cũng cần check giới hạn riêng của slot (max_amount) nếu có
		var limit = item_data.max_stack_size if item_data.stackable else 1
		if slot.max_amount != -1:
			limit = min(limit, slot.max_amount)
			
		added_amount = min(amount, limit)
		slot.amount = added_amount
		
	# Trường hợp 2: Slot đang chứa item cùng loại (Stacking)
	elif slot.item_data.code == item_data.code and item_data.stackable:
		var limit = item_data.max_stack_size
		if slot.max_amount != -1:
			limit = min(limit, slot.max_amount)
			
		var space = limit - slot.amount
		if space > 0:
			added_amount = min(amount, space)
			slot.amount += added_amount
	
	# Trường hợp 3: Khác loại hoặc đã đầy -> added_amount = 0
	if added_amount > 0:
		EventBus.inventory_updated.emit(inventory_id)
		
	return added_amount

# ============ RANGE OPERATIONS (Cho Processing Building) ============
## Lấy tổng số lượng item trong một khoảng slot cụ thể
func get_total_item_in_range(item_code: String, start_idx: int, end_idx: int) -> int:
	var total = 0
	for i in range(start_idx, end_idx):
		if i >= slots.size(): break
		var slot = slots[i]
		if slot.item_data and slot.item_data.code == item_code:
			total += slot.amount
	return total

## Xóa item trong một khoảng slot cụ thể và trả về số lượng đã xóa thực tế
func remove_item_in_range(item_code: String, amount: int, start_idx: int, end_idx: int) -> int:
	var remaining = amount
	var removed_total = 0
	
	for i in range(start_idx, end_idx):
		if remaining <= 0 or i >= slots.size(): break
		var slot = slots[i]
		if slot.item_data and slot.item_data.code == item_code:
			var remove_amount = min(remaining, slot.amount)
			slot.amount -= remove_amount
			remaining -= remove_amount
			removed_total += remove_amount
			if slot.amount <= 0: slot.clear()
			
	if removed_total > 0:
		EventBus.inventory_updated.emit(inventory_id)
		
	return removed_total

## Tìm item theo type trong một khoảng slot
func find_item_by_type_in_range(item_type: String, start_idx: int, end_idx: int) -> ItemData:
	for i in range(start_idx, end_idx):
		if i >= slots.size(): break
		var slot = slots[i]
		if slot.item_data and slot.amount > 0:
			if slot.item_data.get_type_item() == item_type:
				return slot.item_data
			elif slot.item_data.get("type") == item_type:
				return slot.item_data
	return null
