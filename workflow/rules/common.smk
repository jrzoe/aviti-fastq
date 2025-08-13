import pandas as pd
import os
from pathlib import Path

# Read in config metadata file
samples = (
    pd.read_csv(
        config["samples"],
        dtype={"sample_basename": str, "clone": str})
)

# Location of raw AVITI sequencing data
seq_run_names = samples["seq_run_name"].unique().tolist()

wildcard_constraints:
    sample="|".join(samples["sample_basename"]),
    run="|".join(seq_run_names),
    run_output_dir=config["run_output_dir"]

# Base final output directory for fastqs
samples["final_out_dir"] = samples.apply(
    lambda sample:
        os.path.join(
            config["data_dir"],
            *[sample[col] for col in config["metadata_columns"]],
            "fastq"
        )
    ,
    axis=1
)

final_out_dirs = samples["final_out_dir"].unique().tolist()

for dir in final_out_dirs:
    Path(dir).mkdir(parents=True, exist_ok=True)

# Final fastq paths in data directory
samples["final_fq_path"] = samples.apply(
    lambda sample:
        os.path.join(
            sample["final_out_dir"],
            f"{sample['sample_basename']}_run{sample['seq_replicate']}.fastq.gz"
        )
    ,
    axis=1
)

# Add read number to the end of fastq paths
def add_read_number(path, read_number):
    dir, filename = os.path.split(path)
    base, ext = filename.split('.', 1)
    return '|'.join(os.path.join(dir, f"{base}{read_number}.{ext}") for read_number in read_number)

# Output fastq paths
def filepaths_to_list(df, path_column):
    split_df = df[path_column].str.split('|', expand=True)
    all_paths = split_df.values.flatten().tolist()
    return all_paths

samples["final_fq_path"] = samples["final_fq_path"].apply(
    add_read_number, read_number=["_R1", "_R2"])

final_fq_paths = filepaths_to_list(samples, "final_fq_path")

# Emeril fastq paths following bases2fastq
samples["bases2fastq_out_path"] = samples.apply(
    lambda sample:
        os.path.join(
            config["run_output_dir"],
            sample["seq_run_name"],
            "Samples/DefaultProject",
            sample["sample_basename"],
            f"{sample['sample_basename']}.fastq.gz"
        )
    ,
    axis=1

)

samples["bases2fastq_out_path"] = samples["bases2fastq_out_path"].apply(
    add_read_number, read_number=["_R1", "_R2"])

bases2fastq_out_paths = filepaths_to_list(samples, "bases2fastq_out_path")

def get_final_output(): 
    # 1: output location for processed AVITI run folders
    final_output = expand(config["run_output_dir"] + "/{run}", run = seq_run_names)
    # 2: final location of fastq files within data directory
    final_output.extend(final_fq_paths)
    return final_output
