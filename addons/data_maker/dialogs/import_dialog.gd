@tool
extends Window
class_name ImportDialog

signal import_requested(json_text: String)

var _text_edit: TextEdit

func _ready() -> void:
	title = "Paste Database JSON"
	size = Vector2(600, 400)
	wrap_controls = true
	close_requested.connect(func(): hide())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	add_child(vbox)

	var label = Label.new()
	label.text = 'Paste JSON: {"path/to/file": {"key": "val"}}'
	vbox.add_child(label)

	_text_edit = TextEdit.new()
	_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text_edit)

	var footer = HBoxContainer.new()
	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var cancel = Button.new(); cancel.text = "Cancel"
	cancel.pressed.connect(func(): hide())
	footer.add_child(cancel)
	var import_btn = Button.new(); import_btn.text = "Import"
	import_btn.pressed.connect(_on_import)
	footer.add_child(import_btn)
	vbox.add_child(footer)

func open() -> void:
	_text_edit.text = ""
	popup_centered()

func _on_import() -> void:
	import_requested.emit(_text_edit.text)
	hide()
