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

extends Skeleton3D

@export
var catboost_path : String = "catboost"

@export 
var bones : Dictionary

func _ready():
	var catboost = load("res://addons/catboost/catboost.gd").new()
	var scene_path = owner.scene_file_path
	var write_path_global = ProjectSettings.globalize_path("user://" + scene_path.get_file().get_basename() + "-" + scene_path.md5_text() + ".tsv")
	var description_path_global = ProjectSettings.globalize_path("res://addons/catboost/model/train_description.txt")
	var model_global = ProjectSettings.globalize_path("res://addons/catboost/model/vrm_model_2021-11-26.bin")
	var catboost_global =  ProjectSettings.globalize_path("catboost")
	catboost._write_import(self, true, write_path_global)
	var stdout = [].duplicate()
	var args = [catboost_global, model_global, description_path_global, write_path_global]
	var ret = OS.execute("CMD.exe", ["/C %s calc --model-file \"%s\" --column-description \"%s\" --output-columns BONE,LogProbability --input-path \"%s\" --output-path stream://stdout --has-header" % args], stdout)	
	var bones : Dictionary
	for elem_stdout in stdout:
		var line : PackedStringArray = elem_stdout.split("\n")
		var keys : PackedStringArray
		var columns_first = line[0].split("\t")
		keys.resize(columns_first.size())
		for c in columns_first.size():					
			var key_name = columns_first[c]
			var split = key_name.split("=", true, 1)
			if split.size() == 1:
				keys[c] = split[0]
			else:
				keys[c] = split[1]
		line.remove_at(0)
		line.reverse()
		for i in line.size():
			var columns = line[i].split("\t")
			var bone_name : String
			for c in columns.size():
				if c == 0:
					bone_name = columns[c]
					continue
				var column_name : String = keys[c]
				var bone : Array
				if bones.has(column_name):
					bone = bones[column_name]
				var value = columns[c].pad_decimals(1).to_float()
				var probability = value
				bone.push_back([probability, bone_name])
				bones[column_name] = bone
	var seen : PackedStringArray
	var results : Array
	var uncertain_results : Array
	for tolerance in range(20):
		for vrm_name in bones.keys():
			var values = bones[vrm_name]
			for value in values:
				var bone = value[1]
				var improbability = abs(value[0])
				if bone == vrm_name:
					break
				elif seen.has(vrm_name) or seen.has(bone):
					continue
				elif not catboost.vrm_humanoid_bones.has(vrm_name):
					continue
				elif improbability >= (tolerance * 0.4):
					continue
				if improbability > 2.0:
					uncertain_results.push_back([vrm_name,bone,  improbability])
				else:
					results.push_back([vrm_name,bone,  improbability])				
				seen.push_back(vrm_name)
				seen.push_back(bone)
	
	if ret != 0:
		print("Catboost returned " + str(ret))
		return null
	else:
		print("## Results.")
		for res in results:
			print(res)
		print("Returned %d certain results" % [results.size()])
		print("## Uncertain results.")
		for res in uncertain_results:
			print(res)
		print("Returned %d uncertain results" % [uncertain_results.size()])

func sort_desc(a, b):
	if a[0] > b[0]:
		return true
	return false
