# Variant calling pipeline: Parameters

## Input/output options

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `--input` | `string` | yes | `test_data/samplesheet.csv` | CSV samplesheet with `sample`, `fastq_1`, and optional `fastq_2` columns. |
| `--reference` | `string` | yes | `test_data/chr20.fa` | Existing reference FASTA with `.fa`, `.fasta`, or `.fna` extension, optionally gzipped. |
| `--input_data_dir` | `string` | no | `test_data` | Directory containing input data and the cached BWA indexes under `indices/`. |
| `--outdir` | `string` | no | `results` | Directory for output results. |
| `--intervals` | `string` | no | `chr20` | Genomic interval passed to GATK GenomicsDBImport. |
| `--rglb` | `string` | no | `lib1` | Read-group library value passed to Picard AddOrReplaceReadGroups. |
| `--rgpl` | `string` | no | `ILLUMINA` | Read-group platform value passed to Picard AddOrReplaceReadGroups. |
| `--rgpu` | `string` | no | `unit1` | Read-group platform-unit value passed to Picard AddOrReplaceReadGroups. |
| `--haplotypecaller_args` | `string` | no | empty | Additional arguments appended to GATK HaplotypeCaller. |

## Execution options

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `--container_image` | `string` | `gatk-pipeline:v1.0.0` | Container image used by the Docker profile. |

## Profiles

| Profile | Purpose |
| --- | --- |
| `docker` | Enables Docker and sets `process.container` to `--container_image`. |
| `slurm` | Submits processes to Slurm and applies resource overrides. |
| `ci` | Applies smaller resource values for continuous integration. |
| `test` | Loads `conf/test.config` with the standard test fixtures. |
| `test_full` | Loads `conf/test_full.config` with the full test configuration. |

Profiles can be combined, for example `-profile test,docker`.

## Samplesheet validation

The samplesheet is validated against [`assets/schema_input.json`](../assets/schema_input.json). It requires an existing compressed FASTQ for `fastq_1`; `fastq_2` may be empty for single-end input. Sample names cannot contain whitespace.

The read-group and HaplotypeCaller options above are consumed through `ext.args` in `conf/modules.config`.
