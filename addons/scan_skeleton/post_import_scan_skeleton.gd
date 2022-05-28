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

static func _write_train(write_path, text):
	var file = File.new()
	if not file.file_exists(write_path):
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
			break
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()
		
	if vrm_extension and vrm_extension.get("vrm_meta"):
		human_map = vrm_extension["vrm_meta"]["humanoid_bone_mapping"]
		if skip_vrm and not test:
			return
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
			for bone_i in skeleton.get_bone_count():
				var bone_name : String = skeleton.get_bone_name(bone_i)
				var vrm_mapping : String = "VRM_BONE_UNKNOWN"
				if not test:
					for human_key in human_map.keys():
						if human_map[human_key] == bone_name:
							vrm_mapping = human_key
							break
					if vrm_mapping == "VRM_BONE_UNKNOWN":
						vrm_mapping = "VRM_BONE_NONE"
				bone["class"] = vrm_mapping
				bone["title"] = "VRM_TITLE_UNKNOWN"
				if vrm_extension and vrm_extension.get("vrm_meta"):
					bone["title"] = vrm_extension["vrm_meta"]["title"]
				bone["vrm_bone_category"] = "VRM_BONE_CATEGORY_UNKNOWN"
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
					else:
						bone["vrm_bone_category"] = "VRM_BONE_CATEGORY_NONE"
				bone["bone"] = bone_name
				bone["bone_parent"] = "VRM_UNKNOWN_BONE"
				if skeleton.get_bone_parent(bone_i) != -1:
					bone["bone_parent"] = skeleton.get_bone_name(skeleton.get_bone_parent(bone_i))
				var bone_global_pose = skeleton.get_bone_global_pose(bone_i)				
				for key in vrm_bones:
					bone[key] = 0
				for key in human_map.keys():
					if human_map.has(key) and key == vrm_mapping:
						bone[key] = 1
				bone_global_pose = skeleton.local_pose_to_global_pose(bone_i, bone_global_pose)
				bone["bone_x_global_origin_in_meters"] = bone_global_pose.origin.x
				bone["bone_y_global_origin_in_meters"] = bone_global_pose.origin.x
				bone["bone_z_global_origin_in_meters"] = bone_global_pose.origin.x
				var bone_global_pose_basis = bone_global_pose.basis.orthonormalized()
				bone["bone_truncated_normalized_basis_axis_x_0"] = bone_global_pose_basis.x.x
				bone["bone_truncated_normalized_basis_axis_x_1"] = bone_global_pose_basis.x.y
				bone["bone_truncated_normalized_basis_axis_x_2"] = bone_global_pose_basis.x.z
				bone["bone_truncated_normalized_basis_axis_y_0"] = bone_global_pose_basis.y.x
				bone["bone_truncated_normalized_basis_axis_y_1"] = bone_global_pose_basis.y.y
				bone["bone_truncated_normalized_basis_axis_y_2"] = bone_global_pose_basis.y.z
				var bone_global_pose_scale = bone_global_pose.basis.get_scale()
				bone["bone_x_global_scale_in_meters"] = bone_global_pose_scale.x
				bone["bone_y_global_scale_in_meters"] = bone_global_pose_scale.y
				bone["bone_z_global_scale_in_meters"] = bone_global_pose_scale.z
				var bone_pose = skeleton.get_bone_global_pose(bone_i)
				bone_pose = skeleton.global_pose_to_world_transform(bone_pose)
				bone["bone_x_global_origin_in_meters"] = bone_pose.origin.x
				bone["bone_y_global_origin_in_meters"] = bone_pose.origin.y
				bone["bone_z_global_origin_in_meters"] = bone_pose.origin.z
				var basis = bone_pose.basis.orthonormalized()
				bone["bone_truncated_normalized_basis_axis_x_0"] = basis.x.x
				bone["bone_truncated_normalized_basis_axis_x_1"] = basis.x.y
				bone["bone_truncated_normalized_basis_axis_x_2"] = basis.x.z
				bone["bone_truncated_normalized_basis_axis_y_0"] = basis.y.x
				bone["bone_truncated_normalized_basis_axis_y_1"] = basis.y.y
				bone["bone_truncated_normalized_basis_axis_y_2"] = basis.y.z
				var scale = bone_pose.basis.get_scale()
				bone["bone_x_global_scale_in_meters"] = scale.x
				bone["bone_y_global_scale_in_meters"] = scale.y
				bone["bone_z_global_scale_in_meters"] = scale.z
				var bone_parent = skeleton.get_bone_parent(bone_i)
				var bone_parent_pose : Transform3D
				if bone_parent != -1:
					bone_parent_pose = skeleton.get_bone_global_pose(bone_parent)
				bone_parent_pose = skeleton.global_pose_to_world_transform(bone_parent_pose)
				bone["bone_parent_x_global_origin_in_meters"] = bone_parent_pose.origin.x
				bone["bone_parent_y_global_origin_in_meters"] = bone_parent_pose.origin.y
				bone["bone_parent_z_global_origin_in_meters"] = bone_parent_pose.origin.z
				var parent_basis : Basis
				if bone_parent != -1:
					parent_basis = bone_parent_pose.basis.orthonormalized()
				bone["bone_parent_truncated_normalized_basis_axis_x_0"] = parent_basis.x.x
				bone["bone_parent_truncated_normalized_basis_axis_x_1"] = parent_basis.x.y
				bone["bone_parent_truncated_normalized_basis_axis_x_2"] = parent_basis.x.z
				bone["bone_parent_truncated_normalized_basis_axis_y_0"] = parent_basis.y.x
				bone["bone_parent_truncated_normalized_basis_axis_y_1"] = parent_basis.y.y
				bone["bone_parent_truncated_normalized_basis_axis_y_2"] = parent_basis.y.z
				var parent_scale = bone_parent_pose.basis.get_scale()
				bone["bone_parent_x_global_scale_in_meters"] = parent_scale.x
				bone["bone_parent_y_global_scale_in_meters"] = parent_scale.y
				bone["bone_parent_z_global_scale_in_meters"] = parent_scale.z
				var bone_hierarchy : String = ""
				for bone_id in neighbours:
					if bone_hierarchy.is_empty():
						bone_hierarchy = skeleton.get_bone_name(bone_id) + ","
						continue
					bone_hierarchy = bone_hierarchy + skeleton.get_bone_name(bone_id) + ","
				bone["bone_hierarchy"] = bone_hierarchy
				if vrm_extension and vrm_extension.get("vrm_meta"):
					var version = vrm_extension["vrm_meta"].get("specVersion")
					if version == null or version.is_empty():
						version = "VRM_UNVERSIONED"
					bone["specification_version"] = version
				else:
					bone["specification_version"] = "VRM_SPECIFICATION_UNKNOWN"
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
	_write_train(filename, string_builder)
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
	neighbor_list.reverse()
	return neighbor_list
