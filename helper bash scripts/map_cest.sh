#!/bin/bash
#SBATCH --account=def-bfinlay    # adjust this to match the accounting group you are using to submit jobs
#SBATCH --time=08:00:00           # adjust this to match the walltime of your job
#SBATCH --gres=gpu:1              # a GPU helps to accelerate the inference part only
#SBATCH --cpus-per-task=8         # a MAXIMUM of 8 core, Alpafold has no benefit to use more
#SBATCH --mem=20G                 # adjust this according to the memory you need
# Load modules dependencies
module load gcc/9.3.0 openmpi/4.0.3 cuda/11.4 cudnn/8.2.0 kalign/2.03 hmmer/3.2.1 openmm-alphafold/7.5.1 hh-suite/3.3.0 python/3.8
DATA_DIR=$SCRATCH/alphafold/data   # set the appropriate path to your downloaded data
INPUT_DIR=$SCRATCH/alphafold/input     # set the appropriate path to your supporting data
OUTPUT_DIR=${SCRATCH}/alphafold/output # set the appropriate path to your supporting data
# Generate your virtual environment in $SLURM_TMPDIR
source ~/alphafold_env/bin/activate
### specify input targets
target_lst_file=$1  # a list of target with stoichiometry
fea_dir=$2   # input feature pickle files of individual monomers under $inp_dir/$monomer
out_dir=af2complex_out # model output files will be under $out_dir/$target

### run preset, note this is different from model_preset defined below
### This preset defined the number of recycles, ensembles, MSA cluster sizes (for monomer_ptm models)
preset=economy # up to 6 recycles, 1 ensemble.

### Choose neural network model(s) from ['model_1/2/3/4/5_multimer', 'model_1/2/3/4/5_multimer_v2', or 'model_1/2/3/4/5_ptm']
# Using two AF2 multimer model released in alphafold2 version 2.2.0
model=model_1_multimer_v2,model_3_multimer_v2

### Choose model_preset from: ['monomer_ptm', 'multimer', 'multimer_np']
# Notes:
#   - monomer_ptm: applying original AF monomer DL model with the capability of predicting TM-score
#   - multimer_np: apply multimer DL model to assembled monomer features (various MSA pairing modes, default is unpaired)
#   - multimer: apply multimer DL model to paired MSA pre-generated by AlphaFold-Multimer's official data pipeline
#
#   You must specify approriate model names compatible with the model preset you choose.
#   E.g., mnomer_ptm for model_x_ptm, and multimer_np for model_x_multimer_v2
#
model_preset=multimer_np
msa_pairing=all # will assemble msa pairing using monoermic features generated with af2complex feature procedure

recycling_setting=1   # output information of intermediate recycled structures

echo "Info: input feature directory is $fea_dir"
echo "Info: result output directory is $out_dir"
echo "Info: model preset is $model_preset"

# AF2Complex source code directory
af_dir=../src


python -u $af_dir/run_af2c_mod.py --target_lst_path=$target_lst_file \
  --data_dir=$DATA_DIR --output_dir=$out_dir --feature_dir=$fea_dir \
  --model_names=$model \
  --preset=$preset \
  --model_preset=$model_preset \
  --save_recycled=$recycling_setting \
  --msa_pairing=$msa_pairing \