# Godot Avatar Wellness

## Install

```
git clone https://github.com/V-Sekai-fire/ML_avatar_wellness
cd ML_avatar_wellness
conda create -n ml_avatar_wellness
conda activate ml_avatar_wellness
pip install 'ludwig[full]'
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu113
cd ml
./train.sh
ludwig export_torchscript --model_path results/experiment_run_3/model/ --output_path torchscript
```
