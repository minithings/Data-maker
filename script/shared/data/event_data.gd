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

func should_trigger(current_day: int, current_season: int, current_year: int, is_night: bool) -> bool:
	if randf() > chance:
		return false

	for key in dynamic_conditions.keys():
		if not check_condition(key, dynamic_conditions[key]):
			return false

	if repeat_interval > 0 and current_day % repeat_interval == 0:
		if _check_trigger_time(is_night):
			return true

	if day > 0 and day == current_day \
			and (season == -1 or season == current_season) \
			and (year == -1 or year == current_year):
		if _check_trigger_time(is_night):
			return true

	return false

func _check_trigger_time(is_night: bool) -> bool:
	match trigger_time:
		"any":   return true
		"night": return is_night
		"day":   return not is_night
	return true

func check_condition(key: String, value: Variant) -> bool:
	match key:
		"min_crop":
			var farming_manager = ServiceLocator.get_service("farming_manager")
			if farming_manager:
				var stats: Dictionary = farming_manager.get_stats()
				return stats.get("total_planted", 0) >= int(value)
			return false
		"min_money":
			var currency_manager = ServiceLocator.get_service("currency_manager")
			if currency_manager:
				return currency_manager.get_gold() >= int(value)
			return false
		_:
			# Điều kiện không biết → pass (caller có thể extend bằng cách override)
			return true
