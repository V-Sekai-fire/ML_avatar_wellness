# Godot Avatar Wellness

## Install

```
pip install 'ludwig[text]'
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu113
cd ml
./train.sh
ludwig export_torchscript --model_path results/experiment_run_3/model/ --output_path torchscript
```