rule move_fastq:
    input: 
        expand("{base_dir}/{run}", base_dir = config["run_output_dir"], run = seq_run_names)
    output:
        final_fq_paths
    run:
        for in_file, out_file in zip(bases2fastq_out_paths, output):
            shell("mv {in_file} {out_file}")
