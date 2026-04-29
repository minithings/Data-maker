class_name EventData extends CustomResource

@export_group("Thông tin cơ bản")
@export var code: String = ""
@export var name: String = ""
@export_multiline var descr: String = ""
@export var type: String = ""

@export_group("Điều kiện thời gian")
@export var day: int = -1
@export var season: int = -1
@export var year: int = -1
@export var repeat_interval: int = 0
@export_enum("any", "day", "night") var trigger_time: String = "any"

@export_group("Dữ liệu bổ sung")
@export var data: Dictionary[String, Variant]

@export_group("Sự kiện ngẫu nhiên")
@export var chance: float = 1.0
@export var dynamic_conditions: Dictionary = {}
