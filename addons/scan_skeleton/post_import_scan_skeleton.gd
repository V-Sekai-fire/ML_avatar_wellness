# MIT License
# 
# Copyright (c) 2020 K. S. Ernest (iFire) Lee & V-Sekai
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorScenePostImport

const correct_bone_dir_const = preload("res://addons/force_bone_forward/correct_bone_dir.gd")

static func _write_train(write_path, text, test):
	var file = File.new()
	if not file.file_exists(write_path) or test:
		file.open(write_path, File.WRITE)
	else:
		file.open(write_path, File.READ_WRITE)
	file.seek_end()
	var first = true
	for t in text:
		if first and file.get_position():
			first = false
			continue
		file.store_csv_line(t, "\t")
	file.close()

const vrm_to_godot : Dictionary = {
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
	"leftLowerArm": "LeftLowerArm",
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

static func _write_import(file, scene : Node, test, skip_vrm):	
	const vrm_bones : Array = ["hips","leftUpperLeg","rightUpperLeg","leftLowerLeg","rightLowerLeg","leftFoot","rightFoot",
	"spine","chest","neck","head","leftShoulder","rightShoulder","leftUpperArm","rightUpperArm",
	"leftLowerArm","rightLowerArm","leftHand","rightHand","leftToes","rightToes","leftEye","rightEye","jaw",
	"leftThumbProximal","leftThumbIntermediate","leftThumbDistal",
	"leftIndexProximal","leftIndexIntermediate","leftIndexDistal",
	"leftMiddleProximal","leftMiddleIntermediate","leftMiddleDistal",
	"leftRingProximal","leftRingIntermediate","leftRingDistal",
	"leftLittleProximal","leftLittleIntermediate","leftLittleDistal",
	"rightThumbProximal","rightThumbIntermediate","rightThumbDistal",
	"rightIndexProximal","rightIndexIntermediate","rightIndexDistal",
	"rightMiddleProximal","rightMiddleIntermediate","rightMiddleDistal",
	"rightRingProximal","rightRingIntermediate","rightRingDistal",
	"rightLittleProximal","rightLittleIntermediate","rightLittleDistal", "upperChest"]
	const vrm_head_category: Array = ["neck", "head", "leftEye","rightEye","jaw"]
	const vrm_left_arm_category : Array = ["leftShoulder","leftUpperArm",
	"leftLowerArm","leftHand",
	"leftThumbProximal","leftThumbIntermediate","leftThumbDistal",
	"leftIndexProximal","leftIndexIntermediate","leftIndexDistal",
	"leftMiddleProximal","leftMiddleIntermediate","leftMiddleDistal",
	"leftRingProximal","leftRingIntermediate","leftRingDistal",
	"leftLittleProximal","leftLittleIntermediate","leftLittleDistal"]
	const vrm_right_arm_category : Array = ["rightShoulder","rightUpperArm","rightLowerArm","rightHand",
		"rightThumbProximal","rightThumbIntermediate","rightThumbDistal",
		"rightIndexProximal","rightIndexIntermediate","rightIndexDistal",
		"rightMiddleProximal","rightMiddleIntermediate","rightMiddleDistal",
		"rightRingProximal","rightRingIntermediate","rightRingDistal",
		"rightLittleProximal","rightLittleIntermediate","rightLittleDistal"]
	const vrm_torso_category : Array = ["hips",	"spine","chest", "upperChest"]
	const vrm_left_leg_category : Array = ["leftUpperLeg","leftLowerLeg","leftFoot","leftToes"]
	const vrm_right_leg_category : Array = ["rightUpperLeg","rightLowerLeg","rightFoot","rightToes"]
	var init_dict : Dictionary
	var file_path : String = file
	print(file_path)
	if file_path.is_empty():
		return scene
	var vrm_extension : VRMTopLevel = null
	var human_map : Dictionary
	
	var queue : Array # Node
	queue.push_back(scene)
	while not queue.is_empty():
		var front = queue.front()
		var node = front
		if node.get("vrm_meta"):
			vrm_extension = node
			queue.clear()
			break
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()
	if vrm_extension and vrm_extension.get("vrm_meta"):
		human_map = vrm_extension["vrm_meta"]["humanoid_bone_mapping"]
		if skip_vrm and not test:
			return
	var godot_to_vrm : Dictionary
	for key in human_map.keys():
		godot_to_vrm[human_map[key]] = key
	queue.push_back(scene)
	var string_builder : Array
	while not queue.is_empty():
		var front = queue.front()
		var node = front
		if node is Skeleton3D:
			var skeleton : Skeleton3D = node
			var neighbours = _generate_bone_chains(skeleton)
			correct_bone_dir_const.fix_skeleton(scene, skeleton)
			correct_bone_dir_const._refresh_skeleton(skeleton)
			var bone : Dictionary
			var bone_hierarchy_id_string : String = " "
			var bone_hierarchy_string : String = " "
			for neighbour in neighbours:
				var bone_name = skeleton.get_bone_name(neighbour)
				bone_hierarchy_string = bone_hierarchy_string + str(bone_name) + " "
			for neighbour in neighbours:
				bone_hierarchy_id_string = bone_hierarchy_id_string + str(neighbour) + " "
				bone_hierarchy_string = bone_hierarchy_string + skeleton.get_bone_name(neighbour) + " "
			for bone_i in skeleton.get_bone_count():
				var bone_name : String = skeleton.get_bone_name(bone_i)
				bone["bone_name"] = bone_name
				var vrm_mapping : String = "VRM_BONE_NONE"
				if not test:
					for human_key in human_map.keys():
						if human_map[human_key] == bone_name:
							vrm_mapping = human_key
							break
				bone["bone"] = vrm_mapping
				bone["humanoid_bone"] = "HUMANOID_BONE_NONE"
				if vrm_to_godot.has(vrm_mapping):
					bone["humanoid_bone"] = vrm_to_godot[vrm_mapping]
				bone["vrm_bone_category"] = ""
				if vrm_extension:
					if vrm_head_category.has(vrm_mapping):
						bone["vrm_bone_category"] = "VRM_BONE_CATEGORY_HEAD"
					elif vrm_left_arm_category.has(vrm_mapping):
						bone["vrm_bone_category"] = "VRM_BONE_CATEGORY_LEFT_ARM"
					elif vrm_right_arm_category.has(vrm_mapping):
						bone["vrm_bone_category"] = "VRM_BONE_CATEGORY_RIGHT_ARM"
					elif vrm_torso_category.has(vrm_mapping):
						bone["vrm_bone_category"] = "VRM_BONE_CATEGORY_TORSO"
					elif vrm_left_leg_category.has(vrm_mapping):
						bone["vrm_bone_category"] = "VRM_BONE_CATEGORY_LEFT_LEG"
					elif vrm_right_leg_category.has(vrm_mapping):
						bone["vrm_bone_category"] = "VRM_BONE_CATEGORY_RIGHT_LEG"
				var number_of_parents : int = 0
				var current : int = bone_i
				while current > 0:
					number_of_parents = number_of_parents + 1
					current = skeleton.get_bone_parent(current)
				bone["number_of_parents"] = number_of_parents
				bone["number_of_children"] = skeleton.get_bone_children(bone_i).size()
				var bone_global_pose = skeleton.get_bone_global_pose(bone_i)
				bone_global_pose = skeleton.global_pose_to_world_transform(bone_global_pose)
				var vrm_bones_ordered : Array = human_map.keys()
				bone["has_upper_chest"] = 0
				if human_map.keys().has("upperChest") and not human_map["upperChest"].is_empty():
					bone["has_upper_chest"] = 1
				bone["has_jaw"] = 0
				if human_map.keys().has("jaws") and not human_map["jaw"].is_empty():
					bone["has_jaw"] = 1
				bone_global_pose = skeleton.local_pose_to_global_pose(bone_i, bone_global_pose)
				bone["bone_global_origin_in_meters"] = "%f %f %f" % \
				[bone_global_pose.origin.x, bone_global_pose.origin.y, bone_global_pose.origin.z]
				var bone_global_pose_basis = bone_global_pose.basis.orthonormalized()
				bone_global_pose_basis = bone_global_pose_basis.scaled(bone_global_pose.basis.get_scale())
				bone["bone_global_basis_6d"] = "%f %f %f %f %f %f" % \
				[bone_global_pose_basis.x.x, bone_global_pose_basis.x.y, bone_global_pose_basis.x.z,
				bone_global_pose_basis.y.x, bone_global_pose_basis.y.y, bone_global_pose_basis.y.z]
				var bone_global_pose_scale = bone_global_pose.basis.get_scale()
				var bone_parent = skeleton.get_bone_parent(bone_i)
				var bone_parent_pose : Transform3D
				if bone_parent != -1:
					bone_parent_pose = skeleton.get_bone_global_pose(bone_parent)
				bone_parent_pose = skeleton.global_pose_to_world_transform(bone_parent_pose)
				var parent_basis : Basis
				var parent_scale = bone_parent_pose.basis.get_scale()
				bone["bone_parent_global_scale_in_meters"] = "%f %f %f" % \
				[parent_scale.x, parent_scale.y, parent_scale.z]
				parent_basis = bone_parent_pose.basis.orthonormalized()
				bone["bone_parent_global_basis_6d"] = "%f %f %f %f %f %f" % \
				[parent_basis.x.x, parent_basis.x.y, parent_basis.x.z,
				parent_basis.y.x, parent_basis.y.y, parent_basis.y.z]
				bone["bone_parent_global_origin_in_meters"] = "%f %f %f" % \
				[bone_parent_pose.origin.x, bone_parent_pose.origin.y, bone_parent_pose.origin.z]
				var hips_pose : Transform3D
				if human_map.keys().has("hips"):
					var hips_id = skeleton.find_bone(human_map["hips"])
					hips_pose = skeleton.get_bone_global_pose(hips_id)
					hips_pose = skeleton.global_pose_to_world_transform(hips_pose)
				var hips_scale = hips_pose.basis.get_scale()
				bone["bone_hips_global_scale_in_meters"] = "%f %f %f" % \
				[hips_scale.x, hips_scale.y, hips_scale.z]
				hips_pose = hips_pose.orthonormalized()
				var hips_basis : Basis = hips_pose.basis
				bone["bone_hips_global_basis_6d"] = "%f %f %f %f %f %f" % \
				[hips_basis.x.x, hips_basis.x.y, hips_basis.x.z,
				hips_basis.y.x, hips_basis.y.y, hips_basis.y.z]
				var hips_origin = hips_pose.origin
				bone["bone_hips_global_origin_in_meters"] = "%f %f %f" % \
				[hips_origin.x, hips_origin.y, hips_origin.z]
				for key in vrm_bones:
					bone[key] = 0
					if vrm_to_godot.has(key):
						bone[vrm_to_godot[key]] = 0
				for key in human_map.keys():
					if human_map.has(key) and key == vrm_mapping:
						bone[key] = 1
						if vrm_to_godot.has(key):
							bone[vrm_to_godot[key]] = 1
				bone["bone_hierarchy_id"] = bone_hierarchy_id_string
				bone["bone_hierarchy"] = bone_hierarchy_string
				if vrm_extension and vrm_extension.get("vrm_meta"):
					var version = vrm_extension["vrm_meta"].get("exporter_version")
					if version == null or version.is_empty():
						version = ""
					bone["exporter_version"] = version
				else:
					bone["exporter_version"] = ""
				if vrm_extension and vrm_extension.get("vrm_meta"):
					var version = vrm_extension["vrm_meta"].get("spec_version")
					if version == null or version.is_empty():
						version = "VRM_UNVERSIONED"
					bone["specification_version"] = version
				else:
					bone["specification_version"] = ""
				if string_builder.is_empty():
					string_builder.push_back(bone.keys())
				string_builder.push_back(bone.values())
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()
		
	var filename = "res://train.tsv"
	if test:
		filename = "res://test.tsv"
	_write_train(filename, string_builder, test)
	return scene

func _post_import(scene : Node):
	var queue : Array
	queue.push_back(scene)
	var string_builder : Array
	while not queue.is_empty():
		var front = queue.front()
		var node = front
		if node is Skeleton3D:
			_write_import(get_source_file(), scene, false, false)
			break
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()
	return scene


static func _generate_bone_chains(skeleton : Skeleton3D) -> Array:
	var neighbor_list : Array
	var queue : Array
	for parentless_bone in skeleton.get_parentless_bones():
		queue.push_back(parentless_bone)
	while not queue.is_empty():
		var front = queue.front()
		neighbor_list.push_back(front)
		for new_bone_id in skeleton.get_bone_children(front):	
			queue.push_back(new_bone_id)
		queue.pop_front()
	return neighbor_list
