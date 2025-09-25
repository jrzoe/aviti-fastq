rule create_fastq:
    input:
        # get run directory from thincseq
        f"{config['sequencer_dir']}/{{run}}"
    output:
        # the resulting fastq files in the output directory
        directory("{run_output_dir}/{run}")
    params:
        bases2fastq_params = config.get("bases2fastq_params", "")
    singularity:
        "docker://elembio/bases2fastq:2.2.0"
    shell:
        "bases2fastq {input} {output} -p 16 {params.bases2fastq_params}"
