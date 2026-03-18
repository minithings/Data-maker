class_name EventData extends CustomResource

@export_group("Thông tin cơ bản")
@export var code: String
@export var name: String
@export_multiline var descr:String=""
@export var type: String

@export_group("Điều kiện thời gian")
@export var day: int = -1 # -1 nếu không cố định ngày
@export var season: int = -1 # -1 nếu không cố định mùa
@export var year: int = -1 # -1 nếu không cố định năm
@export var repeat_interval: int = 0 # 0 nếu không lặp, >0 là số ngày lặp lại
@export_enum("any", "day", "night")  var trigger_time: String = "any"
@export_group("Dữ liệu bổ xung thêm")
@export var data: Dictionary[String,Variant]

@export_group("Sự kiện ngẫu nhiên")
@export var chance: float = 1.0 # Xác suất xuất hiện mỗi lần kiểm tra (0.0 - 1.0)
@export var dynamic_conditions: Dictionary = {} # Điều kiện động, ví dụ: {"min_crop": 10}


func should_trigger(current_day: int, current_season: int, current_year: int, is_night: bool) -> bool:
	if randf() > chance:
		return false
	
	# Kiểm tra điều kiện động
	for key in dynamic_conditions.keys():
		if not check_condition(key, dynamic_conditions[key]):
			return false
	
	#Kiểm tra điều kiện định nghĩa trước theo mùa ngày
	if repeat_interval > 0 and current_day % repeat_interval == 0:
		if trigger_time == "any" or (trigger_time == "night" and is_night) or (trigger_time == "day" and not is_night):
			return true
	
	if day > 0 and day == current_day and (season == -1 or season == current_season) and (year == -1 or year == current_year):
		if trigger_time == "any" or (trigger_time == "night" and is_night) or (trigger_time == "day" and not is_night):
			return true
	
	return false

func check_condition(key: String, value) -> bool:
	match key:
		"min_crop":
			# Kiểm tra số lượng cây trồng hiện tại
			var crop_count = 3
			return crop_count >= int(value)
		"min_money":
			var money = 3
			return money >= int(value)
		# Thêm các điều kiện khác tùy ý
		_:
			return true # Nếu không biết điều kiện thì luôn đúng
