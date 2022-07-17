extends Node3D

func _ready():
	for child in self.get_children():
		if not child.visible:
			continue
		var queue : Array
		queue.push_back(child)
		var string_builder : Array
		while not queue.is_empty():
			var front = queue.front()
			var node = front
			if node is Skeleton3D:
				var skeleton : Skeleton3D = node
				if skeleton == null:
					print(child.name)
					print("MISSING SKELETON!  X HAS NO BONES!")
					continue
				_write_import("res://train.csv", child, false, false)
				break
			var child_count : int = node.get_child_count()
			for i in child_count:
				queue.push_back(node.get_child(i))
			queue.pop_front()


const NO_BONE = -1
const VECTOR_DIRECTION = Vector3.UP

class RestBone extends RefCounted:
	var rest_local_before: Transform3D
	var rest_local_after: Transform3D
	var rest_delta: Quaternion
	var children_centroid_direction: Vector3
	var parent_index: int = NO_BONE
	var children: Array = []
	var override_direction: bool = true

static func _get_perpendicular_vector(p_v: Vector3) -> Vector3:
	var perpendicular: Vector3 = Vector3()
	if !is_zero_approx(p_v[0]) and !is_zero_approx(p_v[1]):
		perpendicular = Vector3(0, 0, 1).cross(p_v).normalized()
	else:
		perpendicular = Vector3(1, 0, 0)

	return perpendicular

static func _align_vectors(a: Vector3, b: Vector3) -> Quaternion:
	a = a.normalized()
	b = b.normalized()
	var angle: float = a.angle_to(b)
	if is_zero_approx(angle):
		return Quaternion()
	if !is_zero_approx(a.length_squared()) and !is_zero_approx(b.length_squared()):
		# Find the axis perpendicular to both vectors and rotate along it by the angular difference
		var perpendicular: Vector3 = a.cross(b).normalized()
		var angle_diff: float = a.angle_to(b)
		if is_zero_approx(perpendicular.length_squared()):
			perpendicular = _get_perpendicular_vector(a)
		return Quaternion(perpendicular, angle_diff)
	else:
		return Quaternion()

static func _fortune_with_chains(
	p_skeleton: Skeleton3D,
	r_rest_bones: Dictionary,
	p_fixed_chains: Array,
	p_ignore_unchained_bones: bool,
	p_ignore_chain_tips: Array,
	p_base_pose: Array) -> Dictionary:
	var bone_count: int = p_skeleton.get_bone_count()

	# First iterate through all the bones and create a RestBone for it with an empty centroid
	for j in range(0, bone_count):
		var rest_bone: RestBone = RestBone.new()

		rest_bone.parent_index = p_skeleton.get_bone_parent(j)
		rest_bone.rest_local_before = p_base_pose[j]
		rest_bone.rest_local_after = rest_bone.rest_local_before
		r_rest_bones[j] = rest_bone

	# Collect all bone chains into a hash table for optimisation
	var chain_hash_table: Dictionary = {}.duplicate()
	for chain in p_fixed_chains:
		for bone_id in chain:
			chain_hash_table[bone_id] = chain

	# We iterate through again, and add the child's position to the centroid of its parent.
	# These position are local to the parent which means (0, 0, 0) is right where the parent is.
	for i in range(0, bone_count):
		var parent_bone: int = p_skeleton.get_bone_parent(i)
		if (parent_bone >= 0):

			var apply_centroid = true

			var chain = chain_hash_table.get(parent_bone, null)
			if typeof(chain) == TYPE_PACKED_INT32_ARRAY:
				var index: int = NO_BONE
				for findind in range(len(chain)):
					if chain[findind] == parent_bone:
						index = findind
				if (index + 1) < chain.size():
					# Check if child bone is the next bone in the chain
					if chain[index + 1] == i:
						apply_centroid = true
					else:
						apply_centroid = false
				else:
					# If the bone is at the end of a chain, p_ignore_chain_tips argument determines
					# whether it should attempt to be corrected or not
					if p_ignore_chain_tips.has(chain):
						r_rest_bones[parent_bone].override_direction = false
						apply_centroid = false
					else:
						apply_centroid = true
			else:
				if p_ignore_unchained_bones:
					r_rest_bones[parent_bone].override_direction = false
					apply_centroid = false

			if apply_centroid:
				r_rest_bones[parent_bone].children_centroid_direction = r_rest_bones[parent_bone].children_centroid_direction + p_skeleton.get_bone_rest(i).origin
			r_rest_bones[parent_bone].children.append(i)


	# Point leaf bones to parent
	for i in range(0, bone_count):
		var leaf_bone: RestBone = r_rest_bones[i]
		if (leaf_bone.children.size() == 0):
			if p_ignore_unchained_bones and !chain_hash_table.get(i, null):
				r_rest_bones[i].override_direction = false
			leaf_bone.children_centroid_direction = r_rest_bones[leaf_bone.parent_index].children_centroid_direction

	# We iterate again to point each bone to the centroid
	# When we rotate a bone, we also have to move all of its children in the opposite direction
	for i in range(0, bone_count):
		if r_rest_bones[i].override_direction:
			r_rest_bones[i].rest_delta = _align_vectors(VECTOR_DIRECTION, r_rest_bones[i].children_centroid_direction)
			r_rest_bones[i].rest_local_after.basis = r_rest_bones[i].rest_local_after.basis * Basis(r_rest_bones[i].rest_delta)

			# Iterate through the children and rotate them in the opposite direction.
			for j in range(0, r_rest_bones[i].children.size()):
				var child_index: int = r_rest_bones[i].children[j]
				r_rest_bones[child_index].rest_local_after = Transform3D(r_rest_bones[i].rest_delta.inverse(), Vector3()) * r_rest_bones[child_index].rest_local_after

	return r_rest_bones

static func _fix_meshes(p_bind_fix_array: Array, p_mesh_instances: Array) -> void:
	print("bone_direction: _fix_meshes")

	for mi in p_mesh_instances:
		var skin: Skin = mi.get_skin();
		if skin == null:
			continue

		skin = skin.duplicate()
		mi.set_skin(skin)
		var skeleton_path: NodePath = mi.get_skeleton_path()
		var node: Node = mi.get_node_or_null(skeleton_path)
		var skeleton: Skeleton3D = node
		for bind_i in range(0, skin.get_bind_count()):
			var bone_index:int  = skin.get_bind_bone(bind_i)
			if (bone_index == NO_BONE):
				var bind_name: String = skin.get_bind_name(bind_i)
				if bind_name.is_empty():
					continue
				bone_index = skeleton.find_bone(bind_name)

			if (bone_index == NO_BONE):
				continue
			skin.set_bind_pose(bind_i, p_bind_fix_array[bone_index] * skin.get_bind_pose(bind_i))


static func find_mesh_instances_for_avatar_skeleton(p_node: Node, p_skeleton: Skeleton3D, p_valid_mesh_instances: Array) -> Array:
	if p_skeleton and p_node is MeshInstance3D:
		var skeleton: Node = p_node.get_node_or_null(p_node.skeleton)
		if skeleton == p_skeleton:
			p_valid_mesh_instances.push_back(p_node)

	for child in p_node.get_children():
		p_valid_mesh_instances = find_mesh_instances_for_avatar_skeleton(child, p_skeleton, p_valid_mesh_instances)

	return p_valid_mesh_instances


static func _refresh_skeleton(p_skeleton : Skeleton3D):
	p_skeleton.visible = not p_skeleton.visible
	p_skeleton.visible = not p_skeleton.visible


static func find_nodes_in_group(p_group: String, p_node: Node) -> Array:
	var valid_nodes: Array = Array()

	for group in p_node.get_groups():
		if p_group == group:
			valid_nodes.push_back(p_node)

	for child in p_node.get_children():
		var valid_child_nodes: Array = find_nodes_in_group(p_group, child)
		for valid_child_node in valid_child_nodes:
			valid_nodes.push_back(valid_child_node)

	return valid_nodes


static func get_full_bone_chain(p_skeleton: Skeleton3D, p_first: int, p_last: int) -> PackedInt32Array:
	var bone_chain: PackedInt32Array = get_bone_chain(p_skeleton, p_first, p_last)
	bone_chain.push_back(p_last)

	return bone_chain

static func get_bone_chain(p_skeleton: Skeleton3D, p_first: int, p_last: int) -> PackedInt32Array:
	var bone_chain: Array = []

	if p_first != NO_BONE and p_last != NO_BONE:
		var current_bone_index: int = p_last

		while 1:
			current_bone_index = p_skeleton.get_bone_parent(current_bone_index)
			bone_chain.push_front(current_bone_index)
			if current_bone_index == p_first:
				break
			elif current_bone_index == NO_BONE:
					return PackedInt32Array()

	return PackedInt32Array(bone_chain)


static func is_bone_parent_of(p_skeleton: Skeleton3D, p_parent_id: int, p_child_id: int) -> bool:
	var p: int = p_skeleton.get_bone_parent(p_child_id)
	while (p != NO_BONE):
		if (p == p_parent_id):
			return true
		p = p_skeleton.get_bone_parent(p)

	return false

static func is_bone_parent_of_or_self(p_skeleton: Skeleton3D, p_parent_id: int, p_child_id: int) -> bool:
	if p_parent_id == p_child_id:
		return true

	return is_bone_parent_of(p_skeleton, p_parent_id, p_child_id)


static func change_bone_rest(p_skeleton: Skeleton3D, bone_idx: int, bone_rest: Transform3D):
	var old_scale: Vector3 = p_skeleton.get_bone_pose_scale(bone_idx)
	var new_rotation: Quaternion = Quaternion(bone_rest.basis.orthonormalized())
	p_skeleton.set_bone_pose_position(bone_idx, bone_rest.origin)
	p_skeleton.set_bone_pose_scale(bone_idx, old_scale)
	p_skeleton.set_bone_pose_rotation(bone_idx, new_rotation)
	p_skeleton.set_bone_rest(bone_idx, Transform3D(
			Basis(new_rotation) * Basis(Vector3(1,0,0) * old_scale.x, Vector3(0,1,0) * old_scale.y, Vector3(0,0,1) * old_scale.z),
			bone_rest.origin))


static func fast_get_bone_global_pose(skel: Skeleton3D, bone_idx: int) -> Transform3D:
	var xform2: Transform3D = skel.get_bone_global_pose_override(bone_idx)
	if xform2 != Transform3D.IDENTITY: # this api is stupid.
		return xform2
	var transform: Transform3D = skel.get_bone_local_pose_override(bone_idx)
	if transform == Transform3D.IDENTITY: # another stupid api.
		transform = skel.get_bone_pose(bone_idx)
	var par_bone: int = skel.get_bone_parent(bone_idx)
	if par_bone == NO_BONE:
		return transform
	return fast_get_bone_global_pose(skel, par_bone) * transform


static func fast_get_bone_local_pose(skel: Skeleton3D, bone_idx: int) -> Transform3D:
	var transform: Transform3D = skel.get_bone_local_pose_override(bone_idx)
	if transform == Transform3D.IDENTITY: # another stupid api.
		transform = skel.get_bone_pose(bone_idx)
	return transform


static func get_fortune_with_chain_offsets(p_skeleton: Skeleton3D, p_base_pose: Array) -> Dictionary:
	var rest_bones: Dictionary = _fortune_with_chains(p_skeleton, {}.duplicate(), [], false, [], p_base_pose)

	var offsets: Dictionary = {"base_pose_offsets":[], "bind_pose_offsets":[]}

	for key in rest_bones.keys():
		offsets["base_pose_offsets"].append(rest_bones[key].rest_local_before.inverse() * rest_bones[key].rest_local_after)
		offsets["bind_pose_offsets"].append(Transform3D(rest_bones[key].rest_delta.inverse()))

	return offsets

static func fix_skeleton(p_root: Node, p_skeleton: Skeleton3D) -> void:
	print("bone_direction: fix_skeleton")

	var base_pose: Array = []
	for i in range(0, p_skeleton.get_bone_count()):
		base_pose.append(p_skeleton.get_bone_rest(i))

	var offsets: Dictionary = get_fortune_with_chain_offsets(p_skeleton, base_pose)
	for i in range(0, offsets["base_pose_offsets"].size()):
		var final_pose: Transform3D = p_skeleton.get_bone_rest(i) * offsets["base_pose_offsets"][i]
		change_bone_rest(p_skeleton, i, final_pose)
	# Correct the bind poses
	var mesh_instances: Array = find_mesh_instances_for_avatar_skeleton(p_root, p_skeleton, [])
	_fix_meshes(offsets["bind_pose_offsets"], mesh_instances)


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
			fix_skeleton(scene, skeleton)
			_refresh_skeleton(skeleton)
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
					bone[key] = "VRM_BONE_NONE"
					if vrm_to_godot.has(key):
						bone[vrm_to_godot[key]] =  "HUMANOID_BONE_NONE"
				var bone_map : BoneMap = BoneMap.new()
				var vrm_keys = vrm_to_godot.keys()
				var profile = SkeletonProfileHumanoid.new()
				bone_map.profile = profile
				for profile_i in range(0, profile.bone_size):
					var bone_skeleton_name = profile.get_bone_name(profile_i)
					for key_i in range(0, vrm_keys.size()):
						var key = vrm_to_godot.keys()[key_i]
						if vrm_to_godot.has(key) and vrm_to_godot[key] == bone_skeleton_name and human_map.has(key):
							bone_map.set_skeleton_bone_name(bone_skeleton_name, human_map[key])
							break
				ResourceSaver.save("user://bone_map.tres", bone_map)
				for key in human_map.keys():
					if human_map.has(key):
						bone[key] = key
						if vrm_to_godot.has(key):
							bone[vrm_to_godot[key]] = vrm_to_godot[key]
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
