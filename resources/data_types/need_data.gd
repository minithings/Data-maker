class_name NeedData extends CustomResource
## Resource định nghĩa một loại nhu cầu (Hunger, Energy, Happiness...)

enum NeedType {
	HUNGER, # Đói - giảm dần theo thời gian, bổ sung bằng ăn
	ENERGY, # Năng lượng - giảm khi làm việc, bổ sung bằng ngủ
	HAPPINESS, # Hạnh phúc - ảnh hưởng bởi nhiều yếu tố (future)
	SOCIAL, # Xã hội - nói chuyện với người khác (future)
}

@export_group("Thông tin cơ bản")
@export var need_type: NeedType = NeedType.HUNGER
@export var display_name: String = "Nhu cầu"
@export var icon: Texture2D

@export_group("Giá trị")
## Giá trị tối đa của nhu cầu
@export var max_value: float = 100.0
## Giá trị khởi đầu
@export var initial_value: float = 100.0

@export_group("Decay & Thresholds")
## Tốc độ giảm mỗi giờ game (vd: 5 = giảm 5 điểm mỗi giờ)
@export var decay_per_hour: float = 4.0
## Tốc độ giảm khi đang làm việc (cao hơn bình thường)
@export var decay_per_hour_working: float = 8.0
## Ngưỡng cảnh báo (hiện icon warning)
@export var warning_threshold: float = 30.0
## Ngưỡng nguy hiểm (NPC phải dừng việc để xử lý)
@export var critical_threshold: float = 15.0

@export_group("Recovery")
## Giá trị phục hồi khi thỏa mãn nhu cầu (vd: ăn 1 phần = +40)
@export var recovery_amount: float = 40.0
## Tốc độ phục hồi mỗi giờ khi nghỉ ngơi (cho Energy)
@export var passive_recovery_per_hour: float = 15.0

@export_group("Priority")
## Độ ưu tiên khi nhiều nhu cầu cùng critical (số lớn = ưu tiên cao)
@export var priority: int = 10

## Kiểm tra nhu cầu đang ở mức warning
func is_warning(current_value: float) -> bool:
	return current_value <= warning_threshold

## Kiểm tra nhu cầu đang ở mức critical
func is_critical(current_value: float) -> bool:
	return current_value <= critical_threshold

## Tính decay dựa trên trạng thái
func get_decay_rate(is_working: bool=false) -> float:
	return decay_per_hour_working if is_working else decay_per_hour

## Lấy tên need type dạng string
func get_type_string() -> String:
	match need_type:
		NeedType.HUNGER: return "hunger"
		NeedType.ENERGY: return "energy"
		NeedType.HAPPINESS: return "happiness"
		NeedType.SOCIAL: return "social"
	return "unknown"
