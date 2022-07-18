extends Node

# Based on
# https://github.com/JosephCatrambone/GodotSkeletonRemapper/blob/main/LICENSE
# MIT License
# Copyright (c) 2022 Joseph Catrambone

func _ready():
	train()


# Build all possible pairs of bones.
# [[bone_properties_a, bone_properties_b, 1/0], ...]
# https://github.com/hubbyist
# Reference https://github.com/godotengine/godot/issues/9264#issuecomment-311601979
func array_combinations(arrays):
	var combinations = []
	var first = arrays.front()
	arrays.pop_front()
	for item in first:
		combinations.push_back([item])
	for array in arrays:
		var sequences = [];
		for item in array:
			for combination in combinations:
				var sequence = combination + [item]
				sequences.push_back(sequence)
		combinations = sequences;
	return combinations


func train():
	var bone_descriptors = Dictionary()  # name -> list of list of features
	# Ring finger -> [all the different bones we've seen that also ring fingers]
	
	var first : bool = true
	var f = File.new()
	f.open("res://train.tsv", File.WRITE)
	
	for child in self.get_children():
		if not child.visible:
			continue
		var queue : Array # Node
		queue.push_back(child)
		var vrm_extension : VRMTopLevel = null
		var human_map : Dictionary
		var vrm_meta : RefCounted
		while not queue.is_empty():
			var front = queue.front()
			var node = front
			if node.get("vrm_meta"):
				vrm_extension = node
			if node is Skeleton3D:
				var skeleton = node
				if vrm_extension and vrm_extension.get("vrm_meta"):
					human_map = vrm_extension["vrm_meta"]["humanoid_bone_mapping"]
					vrm_meta = vrm_extension["vrm_meta"]
				var skeleton_properties = make_features_for_skeleton(skeleton, human_map, vrm_meta)
				for name in skeleton_properties.keys():
					if not bone_descriptors.has(name):
						bone_descriptors[name] = []
					bone_descriptors[name].append(skeleton_properties[name])
				break
			var child_count : int = node.get_child_count()
			for i in child_count:
				queue.push_back(node.get_child(i))
			queue.pop_front()
	
	for combination in array_combinations([bone_descriptors.keys(), bone_descriptors.keys()]):
		var bone_a : String = combination[0]
		var bone_b : String = combination[1]
		for bone_array_a in bone_descriptors[bone_a]:
			for bone_array_b in bone_descriptors[bone_b]:
				var feature_vector = []
				feature_vector.append_array(bone_array_a)
				feature_vector.append_array(bone_array_b)
				var line : PackedStringArray
				var is_empty : bool = bone_a.is_empty() and bone_b.is_empty()
				if bone_b == bone_a and not is_empty:
					line.push_back(str(true))
				else:
					line.push_back(str(false))
				for feature in feature_vector:
					if typeof(feature) == TYPE_STRING:
						line.push_back(feature)
				var feature_string : String = ""
				for feature in feature_vector:
					if typeof(feature) != TYPE_STRING:
						feature_string = feature_string + str(feature) + " "
				line.push_back(feature_string)
				if first:
					# DEBUG: Save a CSV of this data
					var header : PackedStringArray
					header.push_back("label")
					header.push_back("sink_bone")
					header.push_back("sink_bone_category")
					header.push_back("sink_bone_hierarchy")
					header.push_back("sink_title")
					header.push_back("sink_version")
					header.push_back("sink_exporter_version")
					header.push_back("sink_spec_version")
					header.push_back("source_bone")
					header.push_back("source_bone_category")
					header.push_back("source_bone_hierarchy")
					header.push_back("source_title")
					header.push_back("source_version")
					header.push_back("source_exporter_version")
					header.push_back("source_spec_version")
					header.push_back("vector")
					f.store_csv_line(header, "\t")
					first = false
				f.store_csv_line(line, "\t")

func compute_bone_depth_and_child_count(skeleton:Skeleton3D, bone_id:int, skeleton_info:Dictionary):
	# Mutates the given skeleton_info_dictionary
	# Sets a mapping from bone_id to {"children": count, "depth": int, "siblings": int}
	
	# Assume that our skeleton always has at least one bone.
	assert(skeleton.get_bone_count() > 0)
	
	# Initialize our dictionary entry.
	if not skeleton_info.has(bone_id):
		skeleton_info[bone_id] = {
			"children": 0,  # Fill in here.
			"depth": 0,  # Don't worry about depth for this node.  It will be assigned by the parent.
			"siblings": 0,  # Let parent fill this in.
		}
	
	# TODO: Handle multiple roots of the skeleton?
	var parent_id: int = skeleton.get_bone_parent(bone_id)
	if parent_id == -1:
		skeleton_info[bone_id]["depth"] = 0
	# NOTE: Godot has no way to get the children of a bone via function call, so we iterate over and check the nodes which have this as a parent.
	var child_bone_ids: Array[int] = []
	for child_bone_id in range(0, skeleton.get_bone_count()):
		if skeleton.get_bone_parent(child_bone_id) == bone_id:
			child_bone_ids.append(child_bone_id)
	
	skeleton_info[bone_id]["children"] = len(child_bone_ids)
	for child_id in child_bone_ids:
		if not skeleton_info.has(child_id):  # Don't override if set.
			skeleton_info[child_id] = {
				"children": 0,
				"depth": skeleton_info[bone_id]["depth"] + 1,
				"siblings": len(child_bone_ids)
			}
		compute_bone_depth_and_child_count(skeleton, child_id, skeleton_info)
	
	return skeleton_info

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

func make_features_for_skeleton(skeleton:Skeleton3D, human_map : Dictionary, vrm_meta : RefCounted) -> Dictionary:
	# Return a mapping from BONE NAME to a feature array.
	var result : Dictionary
	var skeleton_result : Dictionary
	
	var bone_count = skeleton.get_bone_count()
	
	# For each bone, if it's a root node, compute the properties it needs.
	var bone_depth_info = Dictionary()
	for bone_id in range(0, skeleton.get_bone_count()):
		if skeleton.get_bone_parent(bone_id) == -1:  # If this is a root bone...
			compute_bone_depth_and_child_count(skeleton, bone_id, bone_depth_info)
	var bone_hierarchy_id_string : String = " "
	var vrm_type_to_bone_id : Dictionary
	for bone_i in range(0, skeleton.get_bone_count()):
		for vrm_i in range(0, human_map.keys().size()):
			var key = human_map.keys()[vrm_i]
			var bone_name = skeleton.get_bone_name(bone_i)
			if human_map[key] == bone_name:
				vrm_type_to_bone_id[key] = bone_i
			else:
				vrm_type_to_bone_id[key] = -1

	var parentless_bones = skeleton.get_parentless_bones()
	var queue : Array
	var bone_list : Array
	var bone_list_id : Array
	var bone_list_vrm : Array
	var bone_list_vrm_id : Array
	for bone_i in parentless_bones:
		queue.push_back(bone_i)
	while not queue.is_empty():
		var head = queue[0]
		for vrm in human_map.keys():
			var vrm_bone_name = skeleton.get_bone_name(head)
			if human_map[vrm] == vrm_bone_name:
				bone_list.push_back(vrm_bone_name)
				bone_list_id.push_back(head)
				bone_list_vrm.push_back(vrm)
				bone_list_vrm_id.push_back(human_map.keys().find(vrm))
		queue.append_array(skeleton.get_bone_children(head))
		queue.pop_front()
	var neighbours = find_neighbor_joint(bone_list_id)
	# Start by finding the depth of every bone.
	for bone_id in skeleton.get_bone_count():
		var pose:Transform3D = skeleton.get_bone_global_pose(bone_id)  # get_global_pose?
		pose = skeleton.global_pose_to_world_transform(pose)
		var bone_name : String = ""
		var bone_category : String = ""
		var title : String
		var bone_hierarchy_string_id : String = " "
		for neighbour in neighbours[bone_list_id.find(bone_id)]:
			for vrm in human_map.keys():
				if not (human_map.has(vrm) and human_map[vrm] == skeleton.get_bone_name(neighbour)):
					continue
				bone_hierarchy_string_id = bone_hierarchy_string_id + vrm + " "
				break
		for key in bone_list_vrm:
			if human_map[key] == skeleton.get_bone_name(bone_id):
				bone_name = key
				if vrm_head_category.has(key):
					bone_category = "VRM_BONE_CATEGORY_HEAD"
				elif vrm_left_arm_category.has(key):
					bone_category = "VRM_BONE_CATEGORY_LEFT_ARM"
				elif vrm_right_arm_category.has(key):
					bone_category = "VRM_BONE_CATEGORY_RIGHT_ARM"
				elif vrm_torso_category.has(key):
					bone_category = "VRM_BONE_CATEGORY_TORSO"
				elif vrm_left_leg_category.has(key):
					bone_category = "VRM_BONE_CATEGORY_LEFT_LEG"
				elif vrm_right_leg_category.has(key):
					bone_category = "VRM_BONE_CATEGORY_RIGHT_LEG"
		var hip : int = skeleton.find_bone(human_map["hips"])
		var hip_pose : Transform3D  = skeleton.get_bone_global_pose(hip)
		var head : int = skeleton.find_bone(human_map["head"])
		var head_pose : Transform3D  = skeleton.get_bone_global_pose(head)
		var distance_head_to_hips : float = hip_pose.origin.distance_to(head_pose.origin)
		#
		var right_lower_arm : int = skeleton.find_bone(human_map["rightLowerArm"])
		var right_lower_arm_pose : Transform3D  = skeleton.get_bone_global_pose(right_lower_arm)
		var right_upper_arm : int = skeleton.find_bone(human_map["rightUpperArm"])
		var right_upper_arm_pose : Transform3D  = skeleton.get_bone_global_pose(right_upper_arm)
		var distance_upper_arm_to_lower_arm : float = right_upper_arm_pose.origin.distance_to(right_lower_arm_pose.origin)
		#
		var right_lower_leg : int = skeleton.find_bone(human_map["rightLowerLeg"])
		var right_lower_leg_pose : Transform3D  = skeleton.get_bone_global_pose(right_lower_leg)
		var right_upper_leg : int = skeleton.find_bone(human_map["rightUpperLeg"])
		var right_upper_leg_pose : Transform3D  = skeleton.get_bone_global_pose(right_upper_leg)
		var distance_upper_leg_to_lower_leg : float = right_upper_leg_pose.origin.distance_to(right_lower_leg_pose.origin)
		result[bone_name] = [
			# Position
			pose.origin.x, pose.origin.y, pose.origin.z, 
			# Rotation
			pose.basis.x.x, pose.basis.x.y, pose.basis.x.z,
			pose.basis.y.x, pose.basis.y.y, pose.basis.y.z,
			pose.basis.z.x, pose.basis.z.y, pose.basis.z.z,
			# Distance to hips
			distance_head_to_hips,
			distance_upper_arm_to_lower_arm,
			distance_upper_leg_to_lower_leg,
			# Scale?
			# Hierarchy info -- TODO: Normalize
			float(bone_depth_info[bone_id]["depth"]) / float(bone_count),
			float(bone_depth_info[bone_id]["children"]) / float(bone_count),
			float(bone_depth_info[bone_id]["siblings"]) / float(bone_count),
			int(bone_name.findn("left") != -1),
			int(bone_name.findn("right") != -1),
			skeleton.get_bone_name(bone_id),
			bone_category,
			bone_hierarchy_string_id,
			vrm_meta["title"],
			vrm_meta["version"],
			vrm_meta["exporter_version"],
			vrm_meta["spec_version"],
		]
	return result

#https://github.com/PeizhuoLi/ganimator/blob/a4e5e097f8aeb4f03361699ec9575d42ef2d8c0e/models/skeleton.py#L322
#Copyright (c) 2020, Kfir Aberman, Peizhuo Li, Yijia Weng, Dani Lischinski, Olga Sorkine-Hornung,
#Daniel Cohen-Or and Baoquan Chen.
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are met:
#
#* Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
#* Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
func find_neighbor_joint(parents : Array, threshold : int = 2) -> Array:
	var n_joint = len(parents)
	var dist_mat : Dictionary
	for i_joint in range(0, n_joint):
		for j_joint in range(0, n_joint):
			dist_mat[[i_joint, j_joint]] = 100000

	for i in parents.size():
		var p = parents[i]
		dist_mat[[i, i]] = 0
		if i != 0:
			dist_mat[[p, i]] = 1
			dist_mat[[i, p]] = dist_mat[[p, i]]

	# Floyd's algorithm
	for k in range(n_joint):
		for i in range(n_joint):
			for j in range(n_joint):
				dist_mat[[i, j]] = min(dist_mat[[i, j]], dist_mat[[i, k]] + dist_mat[[k, j]])

	var neighbor_list = []
	for i in range(n_joint):
		var neighbor = []
		for j in range(n_joint):
			if dist_mat[[i, j]] <= threshold:
				neighbor.append(j)
		neighbor_list.append(neighbor)

	return neighbor_list
