# Variant calling pipeline

## Overview

The Variant calling pipeline is a Nextflow-based workflow designed for germline short-variant calling using GATK HaplotypeCaller. This pipeline implements the best-practice GATK workflow for discovering and genotyping germline variants in DNA sequence data, supporting joint-calling across multiple samples for improved variant detection accuracy. The pipeline can be launched locally and on Seqera with various cloud infrastructure providers, providing scalable solutions for germline variant calling.

## Features

- **Modular structure** for maintainable and extensible workflow development
- **GATK integration** for high-performance germline variant calling
- **Comprehensive preprocessing** including BWA alignment, read group assignment, sorting, and BAM indexing
- **GVCF-based joint calling** using HaplotypeCaller and GenotypeGVCFs
- **GenomicsDB support** for efficient multi-sample variant consolidation
- **Flexible configuration** of input parameters and execution environments
- **Integration with nf-core** tools and practices
- **Containerized execution** via Docker/Singularity for reproducibility
- **Pre-configured for nf-test** for automated testing
- **Support for test data and CI/CD** for reliable development and deployment

## Pipeline Modes

The pipeline supports a single main workflow:

- **GATK Germline Variant Calling**: Main workflow that processes DNA sequence data through alignment, preprocessing, GVCF generation, and joint genotyping. Starts with paired-end FASTQ reads, performs BWA alignment against the reference genome, adds read group information, sorts and indexes BAM files, then executes GATK HaplotypeCaller in GVCF mode for each sample. Multiple GVCFs are consolidated into a GenomicsDB workspace and jointly genotyped to produce a final VCF.

## Workflow

The GATK germline variant calling pipeline starts with input of a samplesheet containing sample identifiers and paired-end FASTQ file paths. The pipeline performs the following steps:

**Preprocessing Phase:**

- Reference genome indexing (BWA, sequence dictionary, and FAI index) is performed once and cached for reuse
- Individual read alignment using BWA MEM against the reference genome
- Read group assignment and BAM header preparation using Picard AddOrReplaceReadGroups
- BAM sorting and indexing using samtools

**Variant Calling Phase:**

- GVCF generation using GATK HaplotypeCaller for each sample independently
- Consolidation of multiple GVCFs into a GenomicsDB workspace (scoped to `--intervals`)
- Joint genotyping across all samples using GATK GenotypeGVCFs to produce a final joint-called VCF

Outputs are published to the configured output directory. The BWA, FASTA, and sequence-dictionary indexes are cached under the configured input data directory. See [Output Documentation](docs/output.md).

## Architecture

The pipeline follows a modular architecture with two main subworkflows:

- **PREPROCESSING**: Indexes the reference genome (if not already cached), aligns reads with BWA MEM, adds read group information with Picard, and sorts/indexes BAM files with samtools. Outputs indexed BAM files for each sample.

  - Genome indexing is conditionally skipped if indices already exist on disk in `${params.input_data_dir}/indices/<reference>.*`

- **VARIANT_CALLING**: Runs GATK HaplotypeCaller per sample in GVCF mode, builds a sample-name-to-path map, consolidates GVCFs into a GenomicsDB workspace, and performs joint genotyping with GenotypeGVCFs to produce the final VCF.

Non-containerized processes handle orchestration and file management, while containerized processes execute the bioinformatics tools (BWA, GATK, samtools, Picard).

## Repository Structure

- **.devcontainer/**: Configuration for development containers
- **.github/**: GitHub Actions workflows and templates
- **assets/**: Static assets and schema files for the pipeline
- **bin/**: Scripts executed by pipeline modules
- **conf/**: Configuration files for different execution environments
- **docker/**: Docker configuration and Dockerfile for container image
- **docs/**: Documentation files including usage, parameters, and output guides
- **modules/**: Nextflow modules for individual pipeline steps
- **subworkflows/**: Nextflow subworkflows for modular pipeline components
- **workflows/**: Main Nextflow workflows
- **test_datasets/**: Test data for pipeline validation
- **tests/**: nf-test test files

## Key Files

- **main.nf**: Main entry point for the pipeline
- **nextflow.config**: Global configuration for the pipeline
- **nextflow_schema.json**: JSON schema for pipeline parameters
- **nf-test.config**: Configuration for nf-test

## Quick Start

**Local or Cloud Execution:**
The basic command to run the pipeline:

```bash
nextflow run main.nf -profile docker
```

For detailed usage instructions, please refer to the [usage documentation](docs/usage.md).

## Parameters

### Core Parameters

- `--input` - Path to CSV samplesheet containing sample information (columns: `sample`, `fastq_1`, `fastq_2`)
- `--reference` - Reference genome FASTA file path
- `--input_data_dir` - Directory containing input data and cached BWA indices
- `--outdir` - Output directory for published pipeline metadata (default: `results/`)
- `--container_image` - Docker container image to use for pipeline execution (default: `gatk-pipeline:v1.0.0`)

### Genome Indexing

- Genome indices are automatically created and cached in `${params.input_data_dir}/indices/`
- Existing indices are reused on subsequent runs, avoiding redundant computation

### Genomic Region

- `--intervals` - Genomic interval passed to GATK GenomicsDBImport (default: `chr20`)

For a complete list of parameters, see the [usage documentation](docs/usage.md) and [parameters](docs/params.md) files.

## Output Directory Structure

The pipeline generates organized outputs in the specified output directory:

```
results/
├── software_versions.yml       # Software versions
├── preprocessing/
│   ├── aligned/                # BWA alignment SAM files
│   ├── read_groups/            # Read-grouped BAM files
│   ├── sorted/                 # Sorted BAM files
│   └── indexed/                # BAM index files
├── variant_calling/
│   ├── gvcf/                   # GVCF files from HaplotypeCaller
│   ├── gvcf_lists/             # GVCF sample map files
│   ├── genomicsdb/             # GenomicsDB workspace
│   └── genotype/               # Final joint-called VCF
└── pipeline_info/              # Execution reports, timeline, trace, and DAG
```

Reference indexes are published separately under `${params.input_data_dir}/indices/`

## Testing

This pipeline is configured to use nf-test for comprehensive testing:

```bash
# Run all tests
nf-test test .

# Run the pipeline with the test data profile
nextflow run main.nf -profile test,docker
```

**To add new test data:**

1. Navigate to the appropriate directory within `test_datasets/`
2. Add your test data file(s)
3. Commit and push the changes

## Development Practices

- Use pre-commit hooks for code formatting and linting (configured in `.pre-commit-config.yaml`)
- Follow the coding style defined in `.prettierrc.yml`
- Document changes in `CHANGELOG.md`
- Build the container image: `docker build -t gatk-pipeline:v1.0.0 -f docker/Dockerfile .`

## Documentation

**Pipeline Documentation:**

- [Usage Guide](docs/usage.md): comprehensive guide on how to use the pipeline
- [Output Documentation](docs/output.md): description of published and unpublished pipeline outputs
- [Parameters Description](docs/params.md): description of pipeline parameters
