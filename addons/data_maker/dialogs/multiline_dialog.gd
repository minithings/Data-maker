@tool
extends Window
class_name MultilineDialog

signal content_saved(file: Dictionary, prop: String, text: String)

var _file: Dictionary
var _prop: String
var _text_edit: TextEdit

func _ready() -> void:
	title = "Edit Long Text Content"
	size = Vector2(700, 500)
	wrap_controls = true

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	add_child(vbox)

	var header = Label.new()
	header.text = "Edit Long Text Content"
	vbox.add_child(header)

	_text_edit = TextEdit.new()
	_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(_text_edit)

	var footer = HBoxContainer.new()
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var cancel_btn = Button.new()
	cancel_btn.text = "Close"
	cancel_btn.pressed.connect(func(): hide())
	footer.add_child(cancel_btn)

	var save_btn = Button.new()
	save_btn.text = "Update Content"
	save_btn.pressed.connect(_on_save)
	footer.add_child(save_btn)

	vbox.add_child(footer)
	close_requested.connect(func(): hide())

func open_for(file: Dictionary, prop: String) -> void:
	_file = file
	_prop = prop
	_text_edit.text = str(file["data"].get(prop, ""))
	title = "Edit: %s" % prop
	popup_centered()

func _on_save() -> void:
	content_saved.emit(_file, _prop, _text_edit.text)
	hide()
