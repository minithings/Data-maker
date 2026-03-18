class_name TagData extends CustomResource

@export var code: String
@export var name: String
@export var description: String
@export var icon: Texture2D
@export var default_duration: float = 5.0
@export var params: Dictionary[String, float] = {} # ví dụ: {"damage_per_second": 2}
