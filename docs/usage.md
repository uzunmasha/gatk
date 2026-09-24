# Variant calling pipeline: Usage

## Introduction

This pipeline performs germline short-variant discovery (SNPs and indels) starting from paired-end FASTQ files, following the general shape of the GATK best-practices workflow:

1. **Preprocessing** ([`subworkflows/local/preprocessing`](../subworkflows/local/preprocessing/main.nf))
   - Build a BWA index for the reference genome (`CREATE_GENOME_INDEX`), reusing a cached index under `<input_data_dir>/indices/` if one is already present.
   - Build a FASTA index (`CREATE_FASTA_INDEX`, `samtools faidx`) and a sequence dictionary (`CREATE_SEQ_DICT`, `gatk CreateSequenceDictionary`).
   - Align reads with `bwa mem` (`ALIGN_READS`).
   - Add read groups with Picard (`ADD_READ_GROUPS`).
   - Sort (`SORT_BAM`) and index (`INDEX_BAM`) the BAM file with `samtools`.
2. **Variant calling** ([`subworkflows/local/variant_calling`](../subworkflows/local/variant_calling/main.nf))
   - Call variants per-sample in GVCF mode with `gatk HaplotypeCaller` (`CALL_VARIANTS`).
   - Build a sample map for each cohort (`CREATE_GVCF_LIST`) and import the GVCFs into a GenomicsDB workspace for the configured interval(s) (`CONSOLIDATE_GVCFS`, `gatk GenomicsDBImport`).
   - Perform joint genotyping over the GenomicsDB workspace to produce the final VCF (`GENOTYPE`, `gatk GenotypeGVCFs`).

A combined `software_versions.yml` is written to the top level of `--outdir`.

## Samplesheet input

Provide a comma-separated samplesheet describing the samples to process, validated against [`assets/schema_input.json`](../assets/schema_input.json):

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2
SAMPLE1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
SAMPLE2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
```

| Column    | Description                                                                                              |
| --------- | -------------------------------------------------------------------------------------------------------- |
| `sample`  | Custom sample name. Cannot contain spaces.                                                               |
| `fastq_1` | Full path to a gzipped FASTQ file for read 1 (`.fastq.gz` or `.fq.gz`). Required.                        |
| `fastq_2` | Full path to a gzipped FASTQ file for read 2 (`.fastq.gz` or `.fq.gz`). Leave empty for single-end data. |

Pass the samplesheet path with `--input`.

## Reference genome

The pipeline expects a single reference FASTA (`.fa`, `.fasta` or `.fna`, optionally gzipped) passed with `--reference`.

Genome index files (`bwa index` output: `.amb`, `.ann`, `.bwt`, `.pac`, `.sa`) are looked for under `<input_data_dir>/indices/<reference_filename>.*`. If they already exist there, `CREATE_GENOME_INDEX` is skipped and the cached index is reused; otherwise the index is built and published to that same directory so subsequent runs can reuse it.

## Running the pipeline

The typical command for running the pipeline is:

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --reference genome.fa \
  --outdir ./results \
  -profile docker
```

> [!IMPORTANT]
> Input data and the cached index location are controlled by `--input_data_dir`, separately from `--outdir` (see [Reference genome](#reference-genome)).

### Parameters

| Parameter                | Description                                                                                    | Default                |
| ------------------------ | ---------------------------------------------------------------------------------------------- | ---------------------- |
| `--input`                | Path to the input samplesheet CSV (required).                                                  | –                      |
| `--reference`            | Path to the reference genome FASTA (required).                                                 | –                      |
| `--input_data_dir`       | Directory holding input/test data and cached genome indices.                                   | `test_data`            |
| `--outdir`               | Directory where pipeline outputs are published.                                                | `results`              |
| `--intervals`            | Genomic interval(s) passed to `GenomicsDBImport`/joint genotyping (e.g. `chr20`, `chr1,chr2`). | `chr20`                |
| `--container_image`      | Container image used by the `docker` profile.                                                  | `gatk-pipeline:v1.0.0` |
| `--rglb`                 | Read-group library value passed to Picard `AddOrReplaceReadGroups`.                            | `lib1`                 |
| `--rgpl`                 | Read-group platform value passed to Picard `AddOrReplaceReadGroups`.                           | `ILLUMINA`             |
| `--rgpu`                 | Read-group platform-unit value passed to Picard `AddOrReplaceReadGroups`.                      | `unit1`                |
| `--haplotypecaller_args` | Extra arguments appended to the GATK `HaplotypeCaller` command.                                | empty                  |

## Profiles

This pipeline currently ships the following profiles (see [`conf/profiles.config`](../conf/profiles.config)):

- `docker` – runs all processes in the container specified by `--container_image`.
- `slurm` – submits processes to a Slurm cluster (`queue = 'normal'`) with per-step CPU/memory/time overrides tuned for whole-genome-scale steps.
- `test` – loads [`conf/test.config`](../conf/test.config), which points `--input_data_dir`, `--reference`, `--input`, `--outdir` and `--intervals` at the bundled `test_data/` fixtures.
- `test_full` – loads [`conf/test_full.config`](../conf/test_full.config).
- `ci` – applies reduced resource values for continuous integration.

Multiple profiles can be combined, e.g. `-profile test,docker`. There is no Singularity, Conda, or Podman profile defined in this repository.

## Resource requests

Default CPU/memory/time requests are defined via labels (`process_low`, `process_medium`, `process_high`) in [`conf/base.config`](../conf/base.config), with per-process overrides for the `slurm` profile in [`conf/profiles.config`](../conf/profiles.config). Adjust these directly in a custom config passed via `-c` if the defaults don't fit your data or infrastructure.
