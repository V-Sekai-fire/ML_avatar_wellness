rm -rf results
export NUMEXPR_MAX_THREADS=`nproc`
ludwig train --dataset train.tsv -c config.yml