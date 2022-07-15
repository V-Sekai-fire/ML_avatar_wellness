# Godot Avatar Wellness

## Install on Windows

```powershell
git clone https://github.com/V-Sekai-fire/ML_avatar_wellness
scoop install mambaforge
cd ML_avatar_wellness
# conda create -n ml_avatar_wellness
# conda activate ml_avatar_wellness
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu116
pip install 'ludwig'
cd ml
# $env:NUMEXPR_MAX_THREADS = 32
./train.sh
ludwig export_torchscript --model_path results/experiment_run_3/model/ --output_path torchscript
```

## Create a series of tailor doctors steps