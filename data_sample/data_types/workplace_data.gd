class_name WorkplaceBuildingData extends StorageBuildingData

@export_group("Cấu hình việc làm")
@export var is_assign_worker: bool = false
@export var max_slot_worker: int = 0
@export var work_radius: float = 350.0
@export var available_jobs: Array[JobConfiguration] = []

## Tính toán số lượng công nhân tối đa theo cấp độ 
func get_max_workers(building_level: int = 1) -> int:
	return max_slot_worker + (building_level - 1)

func get_job_config(index: int = 0) -> JobConfiguration:
	if index >= 0 and index < available_jobs.size():
		return available_jobs[index]
	return null

func get_job_types_count() -> int:
	return available_jobs.size()

## Lấy bán kính làm việc hiệu quả
func get_work_radius() -> float:
	var base_radius = work_radius
	var effective_radius = base_radius * (1.0 + (level - 1) * 0.1)
	return effective_radius
