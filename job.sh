  # module load gcc/11.3.0
  module load CUDA/11.8
  module load cuDNN/8.9.2/CUDA-11
  source /data/zhongz2/anaconda3/bin/activate cucim


# unzip the data to /lscratch/$SLURM_JOB_ID
cd /lscratch/$SLURM_JOB_ID
rm -rf /lscratch/$SLURM_JOB_ID/PanNuke/
mkdir -p /lscratch/$SLURM_JOB_ID/PanNuke/
for i in 0 1 2; do 
j=$((1+${i}))
unzip /data/zhongz2/data/PanNuke/fold_${j}.zip;
mv "/lscratch/$SLURM_JOB_ID/Fold ${j}/" "/lscratch/$SLURM_JOB_ID/PanNuke/fold${i}/"
done
for i in 0 1 2; do
cd "/lscratch/$SLURM_JOB_ID/PanNuke/fold${i}"
for f in `find $(pwd) -name "*.npy"`; do
echo "${f}"
ln -sf "${f}" .;
done
done 

export WANDB_DISABLED="true"
cd /data/zhongz2/cellvit;

# training

python cell_segmentation/datasets/prepare_pannuke.py \
--input_path /lscratch/$SLURM_JOB_ID/PanNuke \
--output_path /lscratch/$SLURM_JOB_ID/PanNuke_Output 

for i in 0 1 2; do
for d in "images" "labels"; do
rm configs/datasets/PanNuke/fold${i}/${d}
ln -sf /lscratch/$SLURM_JOB_ID/PanNuke_Output/fold${i}/${d} configs/datasets/PanNuke/fold${i}/;
done
done
# check the configs/examples/cell_segmentation/train_cellvit1.yaml 
# it seems OK now
# latest_checkpoint.pth  model_best.pth

self.logger.info(model.load_state_dict(cellvit_pretrained['model_state_dict'], strict=True))


python cell_segmentation/run_cellvit.py --config configs/examples/cell_segmentation/train_cellvit1.yaml 
python cell_segmentation/inference/inference_cellvit_experiment_pannuke1.py \
--run_dir /data/zhongz2/cellvit/log_dir/2024-01-26T072636_NoLogComment \
--checkpoint_name "model_best.pth" \
--gpu 0 \
--magnification 20 \
--plots



mkdir -p /lscratch/$SLURM_JOB_ID/output
ln -sf /lscratch/$SLURM_JOB_ID/output ./example/
python3 ./preprocessing/patch_extraction/main_extraction.py \
--config ./example/preprocessing_exampl1.yaml



python3 ./cell_segmentation/inference/cell_detection.py \
  --model ./models/pretrained/CellViT/CellViT-SAM-H-x20.pth\
  --gpu 0 \
  --geojson \
  --magnification 20 \
  --batch_size 4 \
  process_wsi \
  --wsi_path ./example/TCGA-V5-A7RE-01Z-00-DX1.71360DC3-F66C-4C4D-86CA-7964D56974FB.svs \
  --patched_slide_path ./example/output/preprocessing/TCGA-V5-A7RE-01Z-00-DX1.71360DC3-F66C-4C4D-86CA-7964D56974FB















