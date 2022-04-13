 ludwig predict --dataset test.tsv --model_path ./results/experiment_run_89/model --skip_save_unprocessed_output  --output_directory output --skip_save_unprocessed_output
# pip install -e ".[serve]"
 ludwig serve --model_path ./results/experiment_run_89/model
# msys2
# pacman -Su mingw-w64-x86_64-jq # /mingw64/bin/jq.exe
curl http://0.0.0.0:8000/predict -X POST -d "@invalid_chest_data.txt" | /mingw64/bin/jq.exe 'to_entries[] | select(.key|endswith("_predictions")) | select(.value)'
curl http://0.0.0.0:8000/predict -X POST -d "@invalid_chest_data.txt" | /mingw64/bin/jq.exe 'to_entries[] | select(.key|endswith("_probabilities_True")) | select(.value)'