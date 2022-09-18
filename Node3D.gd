extends Node

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
				var skeleton : Skeleton3D = null
				if vrm_extension and vrm_extension.get("vrm_meta"):
					human_map = vrm_extension["vrm_meta"]["humanoid_bone_mapping"]
					vrm_meta = vrm_extension["vrm_meta"]
					skeleton = vrm_extension.get_node_or_null(vrm_extension.vrm_skeleton)
				if vrm_extension:
					if first:
						var header : PackedStringArray
						for profile_bone_i in human_map.profile.bone_size:
							header.push_back(human_map.profile.get_bone_name(profile_bone_i))
						f.store_csv_line(header, "\t")
						first = false
					var line : PackedStringArray
					if skeleton != null:
						var skeleton_line : PackedStringArray
						for bone_i in human_map.profile.bone_size:
							var source_bone_name : String = human_map.get_skeleton_bone_name(human_map.profile.get_bone_name(bone_i))
							skeleton_line.push_back(source_bone_name)
						line.push_back(" ".join(skeleton_line))
					f.store_csv_line(line, "\t")
			queue.append_array(node.get_children())
			queue.pop_front()
