@tool
extends Window
class_name ErrorSummaryDialog

signal navigate_to_error(folder: String, file_name: String)

var _list: ItemList

func _ready() -> void:
	title = "Validation Errors"
	size = Vector2(520, 400)
	wrap_controls = true
	close_requested.connect(func(): hide())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	add_child(vbox)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_activated.connect(_on_item_activated)
	vbox.add_child(_list)

	var footer = HBoxContainer.new()
	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var close_btn = Button.new(); close_btn.text = "Close"
	close_btn.pressed.connect(func(): hide())
	footer.add_child(close_btn)
	vbox.add_child(footer)

func open_with(errors: Array) -> void:
	_list.clear()
	for err in errors:
		var text = "%s  |  col: %s  |  val: %s  [%s]" % [
			err["file_name"], err["prop"], str(err["value"]), err["issue_type"]
		]
		_list.add_item(text)
		_list.set_item_metadata(_list.item_count - 1, err)
	popup_centered()

func _on_item_activated(idx: int) -> void:
	var err = _list.get_item_metadata(idx)
	navigate_to_error.emit(err["folder"], err["file_name"])
	hide()
