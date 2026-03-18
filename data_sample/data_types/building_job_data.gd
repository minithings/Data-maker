class_name BuildingJobData extends Resource

@export_group("Job Information")
@export var job_code: String = ""
@export var job_name: String = ""
@export var building_type: String = ""
@export_multiline var description: String = ""

@export_group("Job Configuration")
@export var job_tasks: Array = [] # Array of JobTaskData
@export var loop_job: bool = true # Job có lặp lại không
@export var max_workers: int = 1 # Số NPC tối đa có thể làm job này
@export var work_schedule: String = "always" # "always", "day_only", "night_only"

@export_group("Resource Configuration")
@export var primary_resource_input: String = "" # Tài nguyên chính cần thu thập
@export var primary_resource_output: String = "" # Sản phẩm chính tạo ra
@export var work_radius: float = 500.0 # Bán kính làm việc
@export var efficiency_bonus: float = 1.0 # Bonus hiệu suất cho job này

@export_group("Requirements")
@export var required_npc_skills: Array[String] = [] # Skills NPC cần có
@export var required_tools: Array[String] = [] # Tools NPC cần mang
@export var required_building_level: int = 1 # Level tối thiểu của building

@export_group("Automation Settings")
@export var auto_start: bool = true # Tự động bắt đầu khi assign
@export var auto_restart_on_complete: bool = true # Tự động restart khi hoàn thành
@export var pause_on_inventory_full: bool = true # Tạm dừng khi inventory đầy
@export var smart_storage_delivery: bool = true # Tự động tìm kho gần nhất

func get_task_by_index(index: int):
	if index >= 0 and index < job_tasks.size():
		return job_tasks[index]
	return null

func get_next_task_index(current_index: int) -> int:
	var next_index = current_index + 1
	if next_index >= job_tasks.size():
		if loop_job:
			return 0 # Quay lại task đầu tiên
		else:
			return -1 # Kết thúc job
	return next_index

func get_task_count() -> int:
	return job_tasks.size()

func is_valid() -> bool:
	return not job_code.is_empty() and not building_type.is_empty() and job_tasks.size() > 0

## Get job summary for debugging
func get_job_summary() -> String:
	var summary = "Job: %s (%s)\n" % [job_name, job_code]
	summary += "Building: %s\n" % building_type
	summary += "Workers: %d | Radius: %.0f\n" % [max_workers, work_radius]
	summary += "Tasks: %d | Loop: %s\n" % [job_tasks.size(), loop_job]
	summary += "Resources: %s → %s\n" % [primary_resource_input, primary_resource_output]
	
	summary += "Task sequence:\n"
	for i in range(job_tasks.size()):
		var task = job_tasks[i]
		summary += "  %d. %s\n" % [i + 1, task.task_type]
	
	return summary

func can_be_performed_by_npc(npc) -> bool:
	# Kiểm tra NPC có đủ điều kiện làm job này không
	# Kiểm tra skills
	if required_npc_skills.size() > 0:
		var npc_skills = npc.get("skills", [])
		for required_skill in required_npc_skills:
			if required_skill not in npc_skills:
				return false
	
	# Kiểm tra tools
	if required_tools.size() > 0:
		var npc_inventory = npc.get("inventory_data")
		if npc_inventory:
			for required_tool in required_tools:
				if npc_inventory.get_item_count(required_tool) == 0:
					return false
	
	return true

func can_be_performed_on_building(building) -> bool:
	# Kiểm tra building có phù hợp với job này không
	if building.building_data.building_code != building_type:
		return false
	
	# Kiểm tra level building (building_data bây giờ đã có property level)
	var building_level = building.building_data.level
	if building_level < required_building_level:
		return false
	
	return true

func get_estimated_completion_time() -> float:
	# Ước tính thời gian hoàn thành 1 chu kỳ job
	var total_time = 0.0
	for task in job_tasks:
		total_time += task.wait_time
		# Add estimated time based on task type
		match task.task_type:
			"FIND_RESOURCE":
				total_time += 10.0 # Ước tính 10s để tìm
			"COLLECT_RESOURCE":
				total_time += 15.0 # Ước tính 15s để thu thập
			"RETURN_TO_BUILDING":
				total_time += 5.0 # Ước tính 5s để di chuyển
			"PROCESS_RESOURCE":
				total_time += 8.0 # Ước tính 8s để chế biến
			"COLLECT_OUTPUT":
				total_time += 3.0 # Ước tính 3s để lấy sản phẩm
			"DELIVER_TO_STORAGE":
				total_time += 10.0 # Ước tính 10s để đưa về kho
	
	return total_time / efficiency_bonus

# Static method để load job từ building code
static func load_job_for_building(building_code: String) -> BuildingJobData:
	var job_path = "res://resources/jobs/%s_job.tres" % building_code
	if ResourceLoader.exists(job_path):
		return load(job_path) as BuildingJobData
	return null
