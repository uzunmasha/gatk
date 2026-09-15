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

- **GATK Germline Variant Calling**: Main workflow that processes DNA sequence data through alignment, preprocessing, GVCF generation, and joint genotyping. Starts with paired-end FASTQ reads, performs BWA alignment against a reference genome, adds read group information, sorts and indexes BAM files, then executes GATK HaplotypeCaller in GVCF mode for each sample. Multiple GVCFs are consolidated into a GenomicsDB workspace and jointly genotyped to produce a final VCF.

## Workflow

The GATK germline variant calling pipeline starts with input of a samplesheet containing sample identifiers and paired-end FASTQ file paths. The pipeline performs the following steps:

**Preprocessing Phase:**
- Reference genome indexing (BWA, sequence dictionary, and FAI index) is performed once and cached for reuse
- Individual read alignment using BWA MEM against the reference genome
- Read group assignment and BAM header preparation using Picard AddOrReplaceReadGroups
- BAM sorting and indexing using samtools

**Variant Calling Phase:**
- GVCF generation using GATK HaplotypeCaller for each sample independently
- Consolidation of multiple GVCFs into a GenomicsDB workspace (scoped to specified genomic regions)
- Joint genotyping across all samples using GATK GenotypeGVCFs to produce a final joint-called VCF

All outputs are organized by processing stage and easily located in the results directory structure.

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
- **docs/**: Documentation files including usage and output guides
- **modules/**: Nextflow modules for individual pipeline steps
- **subworkflows/**: Nextflow subworkflows for modular pipeline components
- **workflows/**: Main Nextflow workflows
- **test_datasets/**: Test data for pipeline validation
- **tests/**: nf-test test files

## Key Files

- **main.nf**: Main entry point for the Nextflow pipeline
- **nextflow.config**: Global configuration for the pipeline
- **nextflow_schema.json**: JSON schema for pipeline parameters
- **nf-test.config**: Configuration for nf-test

## Quick Start

**Local or Cloud Execution:**
The basic command to run the pipeline:

```bash
nextflow run main.nf -profile docker
```

To run with test data:

```bash
nextflow run main.nf -profile test,docker
```

For detailed usage instructions, please refer to the [usage documentation](docs/usage.md).

## Parameters

### Core Parameters

- `--input` - Path to CSV samplesheet containing sample information (columns: sample, fastq_1, fastq_2)
- `--reference` - Reference genome FASTA file path
- `--input_data_dir` - Directory containing input data and cached indices
- `--output_dir` - Output directory for pipeline results (default: `results/`)
- `--container_image` - Docker container image to use for pipeline execution (default: `gatk-pipeline:latest`)

### Genome Indexing

- Genome indices are automatically created and cached in `${params.input_data_dir}/indices/`
- Existing indices are reused on subsequent runs, avoiding redundant computation

### Genomic Region

- `--region` - Genomic region(s) for variant calling and consolidation (default: `chr20`)

For a complete list of parameters, see the [usage documentation](docs/usage.md) and [parameters](docs/params.md) files.

## Output Directory Structure

The pipeline generates organized outputs in the specified output directory:

```
results/
├── preprocessing/
│   ├── aligned/          # BWA alignment BAM files
│   ├── read_groups/      # Read-grouped BAM files
│   ├── sorted/           # Sorted BAM files
│   └── indexed/          # Indexed BAM files
├── variant_calling/
│   ├── gvcf/             # GVCF files from HaplotypeCaller
│   ├── gvcf_lists/       # GVCF sample map files
│   ├── genomicsdb/       # GenomicsDB workspace
│   └── genotype/         # Final joint-called VCF
└── pipeline_info/        # Execution reports and software versions
```

## Testing

This pipeline is configured to use nf-test for comprehensive testing:

```bash
# Run all tests
./nf-test test

# Run specific test file
./nf-test test tests/modules/create_genome_index/main.nf.test

# Run tests with specific profile
nf-test test . --profile docker
```

### Test Data

Test data is included in the `test_datasets/` directory and includes:
- Reference genome (hg38, chr20 subset)
- Sample FASTQ files for testing

To run tests with the bundled test data:

```bash
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
- Build the container image: `docker build -t gatk-pipeline:latest -f docker/Dockerfile .`

## Documentation

**Pipeline Documentation:**
- [Usage Guide](docs/usage.md): Comprehensive guide on how to use the pipeline
- [Output Documentation](docs/output.md): Detailed description of pipeline outputs
- [Parameters Description](docs/params.md): Detailed description of pipeline parameters

## Contributing

We welcome contributions to improve this pipeline. Please read our [Contributing Guidelines](.github/CONTRIBUTING.md) for more information on how to get started.
