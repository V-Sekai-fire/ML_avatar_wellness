 ludwig predict --dataset test.tsv --model_path ./results/experiment_run_51/model --skip_save_unprocessed_output  --output_directory output --skip_save_unprocessed_output
# pip install -e ".[serve]"
 ludwig serve --model_path ./results/experiment_run_51/model
curl http://0.0.0.0:8000/predict -X POST -d "@data.txt"