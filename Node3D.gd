extends Node

# https://github.com/JosephCatrambone/GodotSkeletonRemapper/blob/main/LICENSE
# MIT License
# Copyright (c) 2022 Joseph Catrambone

func _ready():
	train()
			
func train():
	var bone_descriptors = Dictionary()  # name -> list of list of featuress
	# Ring finger -> [all the different bones we've seen that also ring fingers]
	
	# DEBUG: Save a CSV of this data:
	var f = File.new()
	f.open("res://train.tsv", File.WRITE)
	var header : PackedStringArray
	header.push_back("label")
	header.push_back("vector")
	f.store_csv_line(header, "\t")
	
	for child in self.get_children():
		if not child.visible:
			continue
		var queue : Array # Node
		queue.push_back(child)
		var vrm_extension : VRMTopLevel = null
		var human_map : Dictionary
		while not queue.is_empty():
			var front = queue.front()
			var node = front
			if node.get("vrm_meta"):
				vrm_extension = node
			if node is Skeleton3D:
				var skeleton = node
				if vrm_extension and vrm_extension.get("vrm_meta"):
					human_map = vrm_extension["vrm_meta"]["humanoid_bone_mapping"]
				var skeleton_properties = make_features_for_skeleton(skeleton, human_map)
				for name in skeleton_properties.keys():
					if not bone_descriptors.has(name):
						bone_descriptors[name] = []
					bone_descriptors[name].append(skeleton_properties[name])
				break
			var child_count : int = node.get_child_count()
			for i in child_count:
				queue.push_back(node.get_child(i))
			queue.pop_front()

	# Build all possible pairs of bones.
	# [[bone_properties_a, bone_properties_b, 1/0], ...]
	for bone_name_source in bone_descriptors.keys():
		for bone_array_a in bone_descriptors[bone_name_source]:
			for bone_name_sink in bone_descriptors.keys():
				for bone_array_b in bone_descriptors[bone_name_sink]:
					var feature_vector = []
					feature_vector.append_array(bone_array_a)
					feature_vector.append_array(bone_array_b)
					var line : PackedStringArray
					if bone_name_sink == bone_name_source:
						line.push_back(str(true))
					else:
						line.push_back(str(false))
					var feature_string : String = ""
					for feature in feature_vector:
						feature_string = feature_string + str(feature) + " "
					line.push_back(feature_string)
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

func make_features_for_skeleton(skeleton:Skeleton3D, human_map) -> Dictionary:
	# Return a mapping from BONE NAME to a feature array.
	var result = {}
	
	var bone_count = skeleton.get_bone_count()
	
	# For each bone, if it's a root node, compute the properties it needs.
	var bone_depth_info = Dictionary()
	for bone_id in range(0, skeleton.get_bone_count()):
		if skeleton.get_bone_parent(bone_id) == -1:  # If this is a root bone...
			compute_bone_depth_and_child_count(skeleton, bone_id, bone_depth_info)

	# Start by finding the depth of every bone.
	for bone_id in skeleton.get_bone_count():
		var pose:Transform3D = skeleton.get_bone_global_pose(bone_id)  # get_global_pose?
		pose = skeleton.global_pose_to_world_transform(pose)
		var bone_name : String = "VRM_BONE_NONE"
		for vrm_i in range(0, human_map.keys().size()):
			var key = human_map.keys()[vrm_i]
			if human_map[key] == skeleton.get_bone_name(bone_id):
				bone_name = key
				break
		result[bone_name] = [
			# Position
			pose.origin.x, pose.origin.y, pose.origin.z, 
			# Rotation
			pose.basis.x.x, pose.basis.x.y, pose.basis.x.z,
			pose.basis.y.x, pose.basis.y.y, pose.basis.y.z,
			pose.basis.z.x, pose.basis.z.y, pose.basis.z.z,
			# Scale?
			# Hierarchy info -- TODO: Normalize
			float(bone_depth_info[bone_id]["depth"]) / float(bone_count),
			float(bone_depth_info[bone_id]["children"]) / float(bone_count),
			float(bone_depth_info[bone_id]["siblings"]) / float(bone_count), 
			# Wish I could do stuff with names.  :'(
		]
	return result
