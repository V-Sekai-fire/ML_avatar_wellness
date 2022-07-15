@tool
extends EditorScript


var vrm_bone_profile : SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()

func _lock_rotation(ewbik, constraint_i):
	ewbik.set_kusudama_limit_cone_count(constraint_i, 1)
	ewbik.set_kusudama_limit_cone_center(constraint_i, 0, Vector3(0, 1, 0))
	ewbik.set_kusudama_limit_cone_radius(constraint_i, 0, 0)

func _full_rotation(ewbik, constraint_i):
	ewbik.set_kusudama_limit_cone_count(constraint_i, 1)
	ewbik.set_kusudama_limit_cone_center(constraint_i, 0, Vector3(0, 1, 0))
	ewbik.set_kusudama_limit_cone_radius(constraint_i, 0, TAU)

var vrm_to_godot : Dictionary = {
	"root": "Root",
	"hips": "Hips",
	"spine": "Spine",
	"chest": "Chest",
	"upperChest": "UpperChest",
	"neck": "Neck",
	"head": "Head",
	"leftEye": "LeftEye",
	"rightEye": "RightEye",
	"jaw": "Jaw",
	"leftShoulder": "LeftShoulder",
	"leftUpperArm": "LeftUpperArm",
	"leftLowerArms": "LeftLowerArm",
	"leftHand": "LeftHand",
	"leftThumbProximal": "LeftThumbProximal",
	"leftThumbIntermediate": "LeftThumbIntermediate",
	"leftThumbDistal": "LeftThumbDistal",
	"leftIndexProximal": "LeftIndexProximal",
	"leftIndexIntermediate": "LeftIndexIntermediate",
	"leftIndexDistal": "LeftIndexDistal",
	"leftMiddleProximal": "LeftMiddleProximal",
	"leftMiddleIntermediate": "LeftMiddleIntermediate",
	"leftMiddleDistal": "LeftMiddleDistal",
	"leftRingProximal": "LeftRingProximal",
	"leftRingIntermediate": "LeftRingIntermediate",
	"leftRingDistal": "LeftRingDistal",
	"leftLittleProximal": "LeftLittleProximal",
	"leftLittleIntermediate": "LeftLittleIntermediate",
	"leftLittleDistal": "LeftLittleDistal",
	"rightShoulder": "RightShoulder",
	"rightUpperArm": "RightUpperArm",
	"rightLowerArm": "RightLowerArm",
	"rightHand": "RightHand",
	"rightThumbProximal": "RightThumbProximal",
	"rightThumbIntermediate": "RightThumbIntermediate",
	"rightThumbDistal": "RightThumbDistal",
	"rightIndexProximal": "RightIndexProximal",
	"rightIndexIntermediate": "RightIndexIntermediate",
	"rightIndexDistal": "RightIndexDistal",
	"rightMiddleProximal": "RightMiddleProximal",
	"rightMiddleIntermediate": "RightMiddleIntermediate",
	"rightMiddleDistal": "RightMiddleDistal",
	"rightRingProximal": "RightRingProximal",
	"rightRingIntermediate": "RightRingIntermediate",
	"rightRingDistal": "RightRingDistal",
	"rightLittleProximal": "RightLittleProximal",
	"rightLittleIntermediate": "RightLittleIntermediate",
	"rightLittleDistal": "RightLittleDistal",
	"leftUpperLeg": "LeftUpperLeg",
	"leftLowerLeg": "LeftLowerLeg",
	"leftFoot": "LeftFoot",
	"leftToes": "LeftToes",
	"rightUpperLeg": "RightUpperLeg",
	"rightLowerLeg": "RightLowerLeg",
	"rightFoot": "RightFoot",
	"rightToes": "RightToes",
}

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
	ewbik.skeleton = ewbik.get_path_to(skeleton)
	var godot_to_vrm : Dictionary
	for vrm_name in vrm_to_godot.keys():
		godot_to_vrm[vrm_to_godot[vrm_name]] = vrm_name 
	var profile : SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()
	var bone_map : BoneMap = BoneMap.new()
	bone_map.profile = profile
	var humanoid_bone_mapping : Dictionary = vrm_top_level.vrm_meta.humanoid_bone_mapping
	var vrm_profile : Dictionary
	var humanoid_profile : Dictionary
	for b in profile.bone_size:
		var profile_name = profile.get_bone_name(b)
		var vrm_name : StringName
		if godot_to_vrm.has(profile_name):
			vrm_name = godot_to_vrm[profile_name]
		var bone_index : int = -1
		var bone_name : StringName
		if humanoid_bone_mapping.has(vrm_name):
			bone_name = humanoid_bone_mapping[vrm_name]
			bone_index = skeleton.find_bone(bone_name)
			print("%s %s" % [profile_name, bone_name])
			bone_map.set_skeleton_bone_name(profile_name, bone_name)
	ResourceSaver.save("res://bone_map.tres", bone_map, ResourceSaver.FLAG_BUNDLE_RESOURCES)
	_generate_ewbik(vrm_top_level, skeleton, ewbik, vrm_profile, humanoid_profile)
	

func _generate_ewbik(vrm_top_level : Node3D, skeleton : Skeleton3D, ewbik : EWBIK, vrm_profile : Dictionary, humanoid_profile : Dictionary) -> void:
	var vrm_meta = vrm_top_level.get("vrm_meta")
	var vrm_human_mapping : Dictionary = vrm_meta.get("humanoid_bone_mapping")
	var bone_vrm_mapping : Dictionary
	for key in vrm_human_mapping.keys():
		bone_vrm_mapping[vrm_human_mapping[key]] = key
		ewbik.max_ik_iterations = 30
		ewbik.default_damp = deg2rad(1)
		ewbik.budget_millisecond = 2
		if ewbik.get_constraint_count():
			continue		
		ewbik.set_pin_count(0)
		var index : int = 0
		var minimum_twist = deg2rad(-0.5)
		var minimum_twist_diff = deg2rad(0.5)
		var maximum_twist = deg2rad(360)
		var pin_size : int = vrm_profile.keys().size()
		for pin_i in pin_size:
			var node_3d : Node3D = Node3D.new()
			skeleton.add_child(node_3d, true)
			var pin_key = vrm_profile.keys()[pin_i]
			var profile_name : String = vrm_profile[pin_key]["profile_name"]
			if profile_name.is_empty():
				continue
			var node_path : NodePath = "../../" + str(profile_name)
			var node : Node3D = ewbik.get_node_or_null(node_path)
			if node == null:
				continue
			var bone_index = vrm_profile[pin_key]["bone_index"]
			var bone_global_pose = skeleton.get_bone_global_pose(bone_index)
			bone_global_pose = skeleton.global_pose_to_world_transform(bone_global_pose)
			node.global_transform = bone_global_pose
			if not vrm_human_mapping.has(pin_key):
				continue
			var bone_name : StringName = vrm_human_mapping[pin_key]
			node_3d.name = bone_name
			var bone_id : int = skeleton.find_bone(bone_name)
			node_3d.transform = skeleton.get_bone_global_pose(bone_id)
			ewbik.add_pin(bone_name, node_path, true)
			ewbik.set_pin_depth_falloff(index, 0)
			index = index + 1
		ewbik.constraint_count = 0
		for count_i in skeleton.get_bone_count():
			var bone_name = skeleton.get_bone_name(count_i)
			if not bone_vrm_mapping.has(bone_name):
				continue
			var vrm_bone_name = bone_vrm_mapping[bone_name]
			var constraint_i = ewbik.constraint_count
			ewbik.constraint_count = ewbik.constraint_count + 1
			ewbik.set_constraint_name(constraint_i, bone_name)
			ewbik.set_kusudama_limit_cone_count(constraint_i, 0)
			skeleton.notify_property_list_changed()
			# Female age 9 - 19 https://pubmed.ncbi.nlm.nih.gov/32644411/
			if vrm_bone_name in ["hips"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
			elif vrm_bone_name in ["spine"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-60))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(60))
			elif vrm_bone_name in ["chest", "upperChest"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-30))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
			elif vrm_bone_name in ["neck"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-47))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(47))
			elif vrm_bone_name in ["head"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
			elif vrm_bone_name in ["leftShoulder", "rightShoulder"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-18))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
			elif vrm_bone_name in ["leftUpperArm", "rightUpperArm"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-18))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
			elif vrm_bone_name in ["leftLowerArm", "rightLowerArm"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-30))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(70))
			elif vrm_bone_name in ["leftHand","rightHand"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-40))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(45))
			elif vrm_bone_name in ["leftUpperLeg", "rightUpperLeg"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
			elif vrm_bone_name in ["leftLowerLeg", "rightLowerLeg"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
			elif vrm_bone_name in ["leftFoot", "rightFoot"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-40))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(40))
			else:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
