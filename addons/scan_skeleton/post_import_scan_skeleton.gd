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

static func _write_train(write_path, text):
	var file = File.new()
	file.open(write_path, File.WRITE)
	for t in text:
		file.store_csv_line(t, "\t")
	file.close()

static func _write_import(file, scene):
	var init_dict : Dictionary
	var file_path : String = file
	print(file_path)
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
			var bone : Dictionary
			for bone_i in skeleton.get_bone_count():
				bone["bone"] = skeleton.get_bone_name(bone_i)
				var bone_rest = skeleton.get_bone_rest(bone_i)
				bone["bone_rest_x_global_origin_in_meters"] = bone_rest.origin.x
				bone["bone_rest_y_global_origin_in_meters"] = bone_rest.origin.x
				bone["bone_rest_z_global_origin_in_meters"] = bone_rest.origin.x
				var bone_rest_basis = bone_rest.basis.orthonormalized()
				bone["bone_rest_truncated_normalized_basis_axis_x_0"] = bone_rest_basis.x.x
				bone["bone_rest_truncated_normalized_basis_axis_x_1"] = bone_rest_basis.x.y
				bone["bone_rest_truncated_normalized_basis_axis_x_2"] = bone_rest_basis.x.z
				bone["bone_rest_truncated_normalized_basis_axis_y_0"] = bone_rest_basis.y.x
				bone["bone_rest_truncated_normalized_basis_axis_y_1"] = bone_rest_basis.y.y
				bone["bone_rest_truncated_normalized_basis_axis_y_2"] = bone_rest_basis.y.z
				var bone_rest_scale = bone_rest.basis.get_scale()	
				bone["bone_rest_x_global_scale_in_meters"] = bone_rest_scale.x
				bone["bone_rest_y_global_scale_in_meters"] = bone_rest_scale.y
				bone["bone_rest_z_global_scale_in_meters"] = bone_rest_scale.z
				var bone_pose = skeleton.get_bone_global_pose(bone_i)
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
				bone["bone_parent_x_global_origin_in_meters"] = bone_pose.origin.x
				bone["bone_parent_y_global_origin_in_meters"] = bone_pose.origin.y
				bone["bone_parent_z_global_origin_in_meters"] = bone_pose.origin.z
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
					
				var neighbours = skeleton_neighbours(print_skeleton_neighbours_text_cache, skeleton)[bone_i]
				var bone_hierarchy = ""
				for elem_i in neighbours.size():
					var bone_id = neighbours[elem_i]
					if bone_hierarchy.is_empty():
						bone_hierarchy = skeleton.get_bone_name(bone_id) + " "
						continue
					bone_hierarchy = bone_hierarchy + skeleton.get_bone_name(bone_id) + " "
				bone["bone_hierarchy"] = bone_hierarchy
				if vrm_extension.get("vrm_meta"):
					var version = vrm_extension["vrm_meta"].get("specVersion")
					if version == null or version.is_empty():
						version = ""
					bone["specification_version"] = version
				var bone_name : String = skeleton.get_bone_name(bone_i)
				var vrm_mapping : String
				if bone_map.has(bone_name):
					vrm_mapping = bone_map[bone_name]
				bone["label"] = vrm_mapping
				if string_builder.is_empty():
					string_builder.push_back(bone.keys())
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

