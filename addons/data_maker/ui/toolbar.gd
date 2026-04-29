@tool
extends HBoxContainer
class_name DataMakerToolbar

signal open_project_requested
signal reload_requested
signal export_requested
signal import_file_requested
signal paste_json_requested
signal sync_requested
signal issues_requested
signal search_changed(query: String)

var _sync_btn: Button
var _issues_btn: Button
var _search: LineEdit
var _reload_btn: Button

func _ready() -> void:
	custom_minimum_size.y = 44

	# Logo
	var logo = Label.new()
	logo.text = "Data Maker V1.0"
	logo.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	add_child(logo)

	_add_separator()

	_make_btn("Open", func(): open_project_requested.emit(), Color(0.4, 0.6, 1.0))
	_reload_btn = _make_btn("Reload", func(): reload_requested.emit(), Color(0.4, 0.9, 0.4))
	_reload_btn.disabled = true

	_add_separator()

	_make_btn("Export", func(): export_requested.emit(), Color(1.0, 0.7, 0.3))
	_make_btn("Import", func(): import_file_requested.emit(), Color(0.4, 0.9, 0.4))
	_make_btn("Paste JSON", func(): paste_json_requested.emit(), Color(0.4, 0.6, 1.0))

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(spacer)

	_issues_btn = Button.new()
	_issues_btn.text = "0 ISSUES"
	_issues_btn.visible = false
	_issues_btn.pressed.connect(func(): issues_requested.emit())
	add_child(_issues_btn)

	_search = LineEdit.new()
	_search.placeholder_text = "Search..."
	_search.custom_minimum_size.x = 200
	_search.text_changed.connect(func(q): search_changed.emit(q))
	add_child(_search)

	_sync_btn = Button.new()
	_sync_btn.text = "Sync (0)"
	_sync_btn.disabled = true
	_sync_btn.pressed.connect(func(): sync_requested.emit())
	add_child(_sync_btn)

func update_dirty(count: int, error_count: int) -> void:
	_sync_btn.text = "Sync (%d)" % count
	_sync_btn.disabled = count == 0 or error_count > 0
	_reload_btn.disabled = false

func update_errors(count: int) -> void:
	_issues_btn.visible = count > 0
	_issues_btn.text = "%d ISSUES" % count

func set_reload_enabled(v: bool) -> void:
	_reload_btn.disabled = not v

@discardable
func _make_btn(label: String, cb: Callable, color: Color = Color.WHITE) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.pressed.connect(cb)
	add_child(btn)
	return btn

func _add_separator() -> void:
	var sep = VSeparator.new()
	add_child(sep)
