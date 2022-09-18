extends Node

# Based on
# https://github.com/JosephCatrambone/GodotSkeletonRemapper/blob/main/LICENSE
# MIT License
# Copyright (c) 2022 Joseph Catrambone

func _ready():
	var first : bool = true
	var f = File.new()
	f.open("res://train.tsv", File.WRITE)
	for child in self.get_children():
		if not child.visible:
			continue
		var queue : Array = [child]
		while not queue.is_empty():
			var front = queue.front()
			var node = front
			if node.get("vrm_meta"):
				var vrm_extension : VRMTopLevel = null
				var vrm_meta : Resource
				var vrm_filename : String
				vrm_extension = node
				var human_map : BoneMap
				if vrm_extension and vrm_extension.get("vrm_meta"):
					human_map = vrm_extension["vrm_meta"]["humanoid_bone_mapping"]
					vrm_meta = vrm_extension["vrm_meta"]
#					vrm_filename = "res://%s - %s" % [vrm_meta.title, vrm_meta.author]
#					ResourceSaver.save(human_map, vrm_filename + ".tres")
				if vrm_extension:
					if first:
						# DEBUG: Save a CSV of this data
						var header : PackedStringArray
						header.push_back("label")
						header.push_back("source_bone")
						f.store_csv_line(header, "\t")
						first = false
					var line : PackedStringArray
					var skeleton_line : PackedStringArray
					for bone_i in range(0, human_map.profile.bone_size):
						var profile_bone_name : String = human_map.profile.get_bone_name(bone_i)
						var source_bone_name : String = human_map.get_skeleton_bone_name(profile_bone_name)
						line.push_back(profile_bone_name)
						line.push_back(source_bone_name)
					line.push_back(", ".join(skeleton_line))
					f.store_csv_line(line, "\t")
			queue.append_array(node.get_children())
			queue.pop_front()
