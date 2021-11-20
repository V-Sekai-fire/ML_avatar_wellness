https://github.com/catboost/catboost/releases/tag/v1.0.3

catboost fit --learn-set train.tsv --test-set test.tsv --column-description train_description.txt --custom-loss="AUC,Precision,Recall" --logging-level Verbose --loss-function Logloss --text-processing processing.json 

catboost calc -m model.bin --column-description test_description.txt -T 4 --output-columns "TotalUncertainty,#5:VRM Bone,#3:Bone,Class" --input-path test.tsv  --output-path output.tsv

Open in libreoffice calc and sort by class desc, uncertain #1, uncertain #2, bone name, vrm bone name