@tool
extends EditorScript

func _lock_rotation(ewbik, constraint_i):
	ewbik.set_kusudama_limit_cone_count(constraint_i, 1)
	ewbik.set_kusudama_limit_cone_center(constraint_i, 0, Vector3(0, 1, 0))
	ewbik.set_kusudama_limit_cone_radius(constraint_i, 0, 0)

func _full_rotation(ewbik, constraint_i):
	ewbik.set_kusudama_limit_cone_count(constraint_i, 1)
	ewbik.set_kusudama_limit_cone_center(constraint_i, 0, Vector3(0, 1, 0))
	ewbik.set_kusudama_limit_cone_radius(constraint_i, 0, TAU)

func _run():
	var root : Node3D = get_editor_interface().get_edited_scene_root()
	var queue : Array
	queue.push_back(root)
	var string_builder : Array
	var vrm_top_level : Node3D
	var skeleton : Skeleton3D
	var ewbik : EWBIK = null
	while not queue.is_empty():
		var front = queue.front()
		var node : Node = front
		if node is Skeleton3D:
			skeleton = node
		if node.script and node.script.resource_path == "res://addons/vrm/vrm_toplevel.gd":
			vrm_top_level = node
		if node is EWBIK:
			ewbik = node
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()
	if ewbik != null:
		ewbik.queue_free()
	ewbik = EWBIK.new()
	skeleton.add_child(ewbik, true)
	ewbik.owner = skeleton.owner
	ewbik.name = "EWBIK"
	ewbik.skeleton = NodePath("..")
	var godot_to_vrm : Dictionary
	var profile : SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()
	var bone_map : BoneMap = BoneMap.new()
	bone_map.profile = profile
	_generate_ewbik(vrm_top_level, skeleton, ewbik, profile)
	

func _generate_ewbik(vrm_top_level : Node3D, skeleton : Skeleton3D, ewbik : EWBIK, profile : SkeletonProfileHumanoid) -> void:
	var vrm_meta = vrm_top_level.get("vrm_meta")
	var bone_vrm_mapping : Dictionary
	ewbik.max_ik_iterations = 30
	ewbik.default_damp = deg2rad(1)
	ewbik.budget_millisecond = 2
	var index : int = 0
	var minimum_twist = deg2rad(-0.5)
	var minimum_twist_diff = deg2rad(0.5)
	var maximum_twist = deg2rad(360)
	for pin_i in profile.bone_size:
		var bone_name = profile.get_bone_name(pin_i)
		var bone_id = skeleton.find_bone(bone_name)
		if bone_id == -1:
			continue
		var bone_global_pose = skeleton.get_bone_global_pose(bone_id)
		bone_global_pose = skeleton.global_pose_to_world_transform(bone_global_pose)
		var node_3d : Node3D = Node3D.new()
		node_3d.name = bone_name
		node_3d.transform = skeleton.get_bone_global_pose(bone_id)
		skeleton.add_child(node_3d, true)
		ewbik.add_pin(bone_name, NodePath(".."), true)
		ewbik.set_pin_depth_falloff(index, 0)
		index = index + 1
	ewbik.constraint_count = 0
	for count_i in skeleton.get_bone_count():
		var bone_name = skeleton.get_bone_name(count_i)
		if profile.find_bone(bone_name) == -1:
			continue
		var constraint_i = ewbik.constraint_count
		ewbik.constraint_count = ewbik.constraint_count + 1
		ewbik.set_constraint_name(constraint_i, bone_name)
		ewbik.set_kusudama_limit_cone_count(constraint_i, 0)
		skeleton.notify_property_list_changed()
		# Female age 9 - 19 https://pubmed.ncbi.nlm.nih.gov/32644411/
		if bone_name in ["Hips"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
		elif bone_name in ["Spine"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-60))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(60))
		elif bone_name in ["Chest", "UpperChest"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-30))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
		elif bone_name in ["Neck"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-47))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(47))
		elif bone_name in ["Head"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
		elif bone_name in ["LeftShoulder", "RightShoulder"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-18))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
		elif bone_name in ["LeftUpperArm", "RightUpperArm"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-18))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
		elif bone_name in ["LeftLowerArm", "RightLowerArm"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-30))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(70))
		elif bone_name in ["LeftHand","RightHand"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-40))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(45))
		elif bone_name in ["LeftUpperLeg", "RightUpperLeg"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
		elif bone_name in ["LeftLowerLeg", "RightLowerLeg"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
		elif bone_name in ["LeftFoot", "RightFoot"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-40))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(40))
		else:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
