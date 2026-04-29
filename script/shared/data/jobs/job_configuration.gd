class_name JobConfiguration extends CustomResource

@export_group("Job Identity")
@export var job_name: String = "Worker"
@export var job_code: String = "worker"
@export_enum("unemployed", "chef","fishing", "rancher", "farmer", "lumberjack", "miner", "builder", "carrier", "gatherer")
var job_type: String = "unemployed"
@export var strategy_script: GDScript

@export_group("Job Parameters")
@export var work_radius: float = 1000.0
@export var target_resource: String = ""

@export_group("Schedule")
@export var work_schedule: String = "day_only"

## Lấy mô tả công việc (Dùng cho UI)
func get_job_description() -> String:
	match job_type:
		"lumberjack": return "Thu thập gỗ xung quanh trạm"
		"farmer":     return "Canh tác nông nghiệp"
		"miner":      return "Khai thác khoáng sản"
		"chef":       return "Nấu ăn tại nhà bếp"
		"carrier":    return "Vận chuyển hàng hóa"
		"gatherer":   return "Thu lượm tài nguyên"
		"builder":    return "Xây dựng công trình"
		"rancher":    return "Chăn nuôi gia súc"
		_:            return "Công việc chung"
