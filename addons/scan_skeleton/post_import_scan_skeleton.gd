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

const vrm_humanoid_bones = ["hips","leftUpperLeg","rightUpperLeg","leftLowerLeg","rightLowerLeg","leftFoot","rightFoot",
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

const MAX_HIERARCHY = 256

static func bone_create():
	var bone_category : Dictionary
	var category_description : PackedStringArray
	var CATBOOST_KEYS = [
		["Label", "Label", "VRM_BONE_NONE"],
		["Bone", "Categ\tBONE", "BONE_NONE"],
		["Specification version", "Auxiliary\tSPECIFICATION_VERSION", "VERSION_NONE"],
	]
	for key_i in MAX_HIERARCHY:
		var label = "Bone hierarchy " + str(key_i).pad_zeros(3)
		CATBOOST_KEYS.push_back([label, "Categ\t" + label, "BONE_NONE"])
	for key_i in CATBOOST_KEYS.size():
		category_description.push_back(str(category_description.size()) + "\t" + CATBOOST_KEYS[key_i][1])
		bone_category[CATBOOST_KEYS[key_i][0]] = CATBOOST_KEYS[key_i][2]
	var bone : Dictionary
	bone["Animation time"] = 0.0
	bone["Bone rest X global origin in meters"] = 0.0
	bone["Bone rest Y global origin in meters"] = 0.0
	bone["Bone rest Z global origin in meters"] = 0.0
	var basis : Basis
	var octahedron = (basis * Vector3.UP).octahedron_encode()
	bone["Bone rest octahedron X"] = octahedron.x
	bone["Bone rest octahedron Y"] = octahedron.y
	bone["Bone rest X global scale in meters"] = 1.0
	bone["Bone rest Y global scale in meters"] = 1.0
	bone["Bone rest Z global scale in meters"] = 1.0
	bone["Bone parent X global scale in meters"] = 1.0
	bone["Bone parent Y global scale in meters"] = 1.0
	bone["Bone parent Z global scale in meters"] = 1.0
	bone["Bone X global origin in meters"] = 0.0
	bone["Bone Y global origin in meters"] = 0.0
	bone["Bone Z global origin in meters"] = 0.0
	bone["Bone octahedron X"] = octahedron.x
	bone["Bone octahedron Y"] = octahedron.y
	var scale : Vector3 = Vector3(1.0, 1.0, 1.0)
	bone["Bone X global scale in meters"] = scale.x
	bone["Bone Y global scale in meters"] = scale.y
	bone["Bone Z global scale in meters"] = scale.z
	bone["Bone parent X global origin in meters"] = 0.0
	bone["Bone parent Y global origin in meters"] = 0.0
	bone["Bone parent Z global origin in meters"] = 0.0
	bone["Bone parent octahedron X"] = octahedron.x
	bone["Bone parent octahedron Y"] = octahedron.y
	bone["Bone parent X global scale in meters"] = 1.0
	bone["Bone parent Y global scale in meters"] = 1.0
	bone["Bone parent Z global scale in meters"] = 1.0
	for bone_key_i in bone.keys().size():
		var bone_key = bone.keys()[bone_key_i]
		var bone_value = bone.values()[bone_key_i]
		category_description.push_back(str(category_description.size()) + "\tNum\t%s" % bone_key)
		bone_category[bone_key] = bone_value
	return {
		"bone": bone_category,
		"description": category_description,
	}

static func _write_train(write_path, text):
	var file = File.new()
	file.open(write_path, File.WRITE)
	for t in text:
		file.store_csv_line(t, "\t")
	file.close()

static func _write_import(file, scene):
	var init_dict = bone_create()
	var file_path : String = file
	if file_path.is_empty():
		return scene
	var vrm_extension = scene
	var bone_map : Dictionary
	var human_map : Dictionary
	if vrm_extension.get("vrm_meta"):
		human_map = vrm_extension["vrm_meta"]["humanoid_bone_mapping"]
	for key in human_map.keys():
		bone_map[human_map[key]] = key
	var queue : Array # Node
	queue.push_back(scene)
	var string_builder : Array
	while not queue.is_empty():
		var front = queue.front()
		var node = front
		if node is Skeleton3D:
			var skeleton : Skeleton3D = node
			var print_skeleton_neighbours_text_cache : Dictionary
			var bone : Dictionary = bone_create().bone
			string_builder.push_back(bone.keys())
			for bone_i in skeleton.get_bone_count():
				if bone_map.has(skeleton.get_bone_name(bone_i)):
					bone["Label"] = bone_map[skeleton.get_bone_name(bone_i)]
				else:
					bone["Label"] = "VRM_BONE_NONE"
				bone["Bone"] = skeleton.get_bone_name(bone_i)
				var bone_rest = skeleton.get_bone_rest(bone_i)
				bone["Bone rest X global origin in meters"] = bone_rest.origin.x
				bone["Bone rest Y global origin in meters"] = bone_rest.origin.x
				bone["Bone rest Z global origin in meters"] = bone_rest.origin.x				
				var bone_rest_rot : Quaternion = bone_rest.basis.get_rotation_quaternion()
				var bone_rest_octahedron = Vector3.UP.rotated(bone_rest_rot.get_axis(), bone_rest_rot.get_angle()).octahedron_encode()
				bone["Bone rest octahedron X"] = bone_rest_octahedron.x
				bone["Bone rest octahedron Y"] = bone_rest_octahedron.y
				var bone_rest_scale = bone_rest.basis.get_scale()	
				bone["Bone rest X global scale in meters"] = bone_rest_scale.x
				bone["Bone rest Y global scale in meters"] = bone_rest_scale.y
				bone["Bone rest Z global scale in meters"] = bone_rest_scale.z
				var bone_pose = skeleton.get_bone_global_pose(bone_i)
				bone["Bone X global origin in meters"] = bone_pose.origin.x
				bone["Bone Y global origin in meters"] = bone_pose.origin.y
				bone["Bone Z global origin in meters"] = bone_pose.origin.z
				var bone_pose_rot = bone_pose.basis.get_rotation_quaternion()
				var octahedron_vec3 = Vector3.UP.rotated(bone_pose_rot.get_axis(), bone_pose_rot.get_angle())
				var octahedron = octahedron_vec3.normalized().octahedron_encode()
				bone["Bone octahedron X"] = octahedron.x
				bone["Bone octahedron Y"] = octahedron.y
				var scale = bone_pose.basis.get_scale()
				bone["Bone X global scale in meters"] = scale.x
				bone["Bone Y global scale in meters"] = scale.y
				bone["Bone Z global scale in meters"] = scale.z
				var bone_parent = skeleton.get_bone_parent(bone_i)
				if bone_parent != -1:
					var bone_parent_pose = skeleton.get_bone_global_pose(bone_parent)
					var bone_parent_rot = bone_parent_pose.basis.get_rotation_quaternion()
					var bone_parent_vec3 = Vector3.UP.rotated(bone_parent_rot.get_axis(), bone_parent_rot.get_angle())
					var parent_octahedron = bone_parent_vec3.normalized().octahedron_encode()
					print(parent_octahedron)
					bone["Bone parent X global origin in meters"] = bone_parent_pose.origin.x
					bone["Bone parent Y global origin in meters"] = bone_parent_pose.origin.y
					bone["Bone parent Z global origin in meters"] = bone_parent_pose.origin.z
					bone["Bone parent octahedron X"] = parent_octahedron.x
					bone["Bone parent octahedron Y"] = parent_octahedron.y
					var parent_scale = bone_parent_pose.basis.get_scale()
					bone["Bone parent X global scale in meters"] = parent_scale.x
					bone["Bone parent Y global scale in meters"] = parent_scale.y
					bone["Bone parent Z global scale in meters"] = parent_scale.z
				var neighbours = skeleton_neighbours(print_skeleton_neighbours_text_cache, skeleton)
				for elem_i in neighbours[bone_i].size():
					if elem_i >= MAX_HIERARCHY:
						break
					bone["Bone hierarchy " + str(elem_i).pad_zeros(3)] = skeleton.get_bone_name(neighbours[bone_i][elem_i])
				if vrm_extension.get("vrm_meta"):
					var version = vrm_extension["vrm_meta"].get("specVersion")
					if version == null or version.is_empty():
						version = "VERSION_NONE"
					bone["Specification version"] = version
				string_builder.push_back(bone.values())
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()
	_write_train(file.get_file() + ".tsv", string_builder)
	return scene


static func skeleton_neighbours(skeleton_neighbours_cache : Dictionary, skeleton):
	if skeleton_neighbours_cache.has(skeleton):
		return skeleton_neighbours_cache[skeleton]
	var bone_list_text : String
	var roots : PackedInt32Array
	for bone_i in skeleton.get_bone_count():
		if skeleton.get_bone_parent(bone_i) == -1:
			roots.push_back(bone_i)
	var queue : Array
	var parents : Array	
	for bone_i in roots:
		queue.push_back(bone_i)
	var seen : Array
	while not queue.is_empty():
		var front = queue.front()
		parents.push_front(front)
		var children : PackedInt32Array = skeleton.get_bone_children(front)
		for child in children:
			queue.push_back(child)
		queue.pop_front()
	var neighbor_list = find_neighbor_joint(parents, 2.0)
	if neighbor_list.size() == 0:
		return [].duplicate()
	skeleton_neighbours_cache[skeleton] = neighbor_list
	return neighbor_list


static func find_neighbor_joint(parents, threshold):
# The code in find_neighbor_joint(parents, threshold) is adapted
# from deep-motion-editing by kfiraberman, PeizhuoLi and HalfSummer11.
	var n_joint = parents.size()
	var dist_mat : PackedInt32Array
	dist_mat.resize(n_joint * n_joint)
	for j in dist_mat.size():
		dist_mat[j] = 1
		if j == n_joint * j + j:
			dist_mat[j] = 0
#   Floyd's algorithm
	for k in range(n_joint):
		for i in range(n_joint):
			for j in range(n_joint):
				dist_mat[i * j + j] = min(dist_mat[i * j + j], dist_mat[i * k + k] + dist_mat[k * j + j])

	var neighbor_list : Array = [].duplicate()
	for i in range(n_joint):
		var neighbor = [].duplicate()
		for j in range(n_joint):
			if dist_mat[i * j + j] <= threshold:
				neighbor.append(j)
		neighbor_list.append(neighbor)
	return neighbor_list
	
func _post_import(scene : Node):
	if not get_source_file().get_extension() == "vrm":
		return scene
	var queue : Array
	queue.push_back(scene)
	var string_builder : Array
	while not queue.is_empty():
		var front = queue.front()
		var node = front
		if node is Skeleton3D:
			_write_import(get_source_file(), scene)
			break
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()	
	return scene

