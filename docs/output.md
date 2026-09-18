# uzunmasha/gatk: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below are created inside `--outdir` (default: `results`) after the pipeline has finished. All paths are relative to that top-level output directory, unless noted otherwise.

## Pipeline overview

The pipeline processes paired-end FASTQ reads through alignment and germline short-variant calling:

- Preprocessing - genome indexing, alignment, read-group tagging, sorting and indexing of BAM files
- Variant calling - per-sample GVCF calling, GenomicsDB consolidation and joint genotyping
- Pipeline information - version information generated during the run

## Genome index (cached, outside `--outdir`)

The BWA index is built once and cached under `<input_data_dir>/indices/` (default: `test_data/indices/`), not under `--outdir`, so it can be reused across pipeline runs. If index files already exist there, indexing is skipped.

- `<reference>.amb`, `<reference>.ann`, `<reference>.bwt`, `<reference>.pac`, `<reference>.sa`: BWA index files for the reference genome.

## Preprocessing

Reads are aligned with `bwa mem`, tagged with read-group information, sorted and indexed. The sorted, indexed BAM in `preprocessing/indexed/` is the input to variant calling.

- `preprocessing/aligned/<sample>.sam`: raw `bwa mem` alignment.
- `preprocessing/read_groups/<sample>_rg.bam`: alignment with read groups added (Picard `AddOrReplaceReadGroups`).
- `preprocessing/sorted/<sample>_sorted.bam`: coordinate-sorted BAM (`samtools sort`).
- `preprocessing/indexed/<sample>_sorted.bam.bai`: BAM index (`samtools index`).

## Variant calling

Each sample is called individually in GVCF mode, then imported into a GenomicsDB workspace and jointly genotyped over the region(s) given by `--intervals` (default `chr20`) to produce the final VCF.

- `variant_calling/gvcf/<sample>.g.vcf`: per-sample GVCF produced by `gatk HaplotypeCaller` (`-ERC GVCF`).
- `variant_calling/gvcf_lists/<sample>_gvcf_list.txt`: sample-to-GVCF-path map used as the `--sample-name-map` input to `GenomicsDBImport`.
- `variant_calling/genomicsdb/<sample>_genomicsdb/`: GenomicsDB workspace built by `gatk GenomicsDBImport`.
- `variant_calling/genotype/<sample>.vcf`: final joint-genotyped VCF produced by `gatk GenotypeGVCFs` — the pipeline's final output.

## Pipeline information

- `software_versions.yml`: versions of the tools used in the pipeline run, written to the top level of `--outdir`.
- `pipeline_info/`: Nextflow's own execution reports — `execution_timeline_*.html`, `execution_report_*.html`, `execution_trace_*.txt` and `pipeline_dag_*.html`.
