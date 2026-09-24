# Variant calling pipeline: Output

## Introduction

This document describes the output produced by the pipeline.

The pipeline writes execution metadata, software versions, and process outputs to `--outdir`. Publication is configured centrally in [`conf/modules.config`](../conf/modules.config) with `withName` selectors.

## Output directory structure

The pipeline publishes the following files and directories inside `--outdir` (default: `results`):

```text
<outdir>/
├── software_versions.yml       # Software versions
├── preprocessing/
│   ├── aligned/                # BWA alignment SAM files
│   ├── read_groups/             # Read-grouped BAM files
│   ├── sorted/                  # Sorted BAM files
│   └── indexed/                 # BAM index files (.bai)
├── variant_calling/
│   ├── gvcf/                    # GVCF files from HaplotypeCaller
│   ├── gvcf_lists/              # GVCF sample map files
│   ├── genomicsdb/              # GenomicsDB workspace
│   └── genotype/                # Final joint-called VCF
└── pipeline_info/               # Execution reports, timeline, trace, and DAG
```

- `software_versions.yml`: versions collected from the preprocessing and variant-calling processes.
- `pipeline_info/`: Nextflow execution reports, timeline, trace, and DAG files.
- The `INDEX_BAM` process publishes only the `.bai` file to `preprocessing/indexed/`; the sorted BAM itself is published by `SORT_BAM` to `preprocessing/sorted/`.
- The GenomicsDB directory is published recursively to `variant_calling/genomicsdb/`.

## Genome index cache

The BWA index is cached outside `--outdir`, under `<input_data_dir>/indices/` (default: `test_data/indices/`). When all five files already exist, genome indexing is skipped.

```text
<input_data_dir>/indices/
├── <reference>.amb
├── <reference>.ann
├── <reference>.bwt
├── <reference>.pac
├── <reference>.sa
├── <reference>.fai
└── <reference>.dict
```

## Process outputs

The following process outputs are copied to the published directories shown above. The original process work-directory paths remain run-specific:

### Preprocessing

- `<sample>.sam`: alignment produced by BWA-MEM.
- `<sample>_rg.bam`: BAM with read groups added by Picard.
- `<sample>_sorted.bam`: coordinate-sorted BAM.
- `<sample>_sorted.bam.bai`: BAM index.

### Variant calling

- `<sample>.g.vcf`: per-sample GVCF produced by GATK HaplotypeCaller.
- `<sample>_gvcf_list.txt`: sample-name map used by GenomicsDBImport.
- `<sample>_genomicsdb/`: GenomicsDB workspace produced by GenomicsDBImport.
- `<sample>.vcf`: joint-genotyped VCF produced by GATK GenotypeGVCFs.

The final VCF is emitted as `VARIANT_CALLING.out.final_vcf` and `GATK.out.final_vcf`, and is published to `variant_calling/genotype/`.

## Interpretation

- GVCFs are intermediate files and are not the final genotype calls.
- The GenomicsDB workspace is an intermediate input to GenotypeGVCFs.
- The final VCF is restricted to the interval supplied with `--intervals`.
- Keep the Nextflow work directory until unpublished outputs have been copied to a permanent location.
