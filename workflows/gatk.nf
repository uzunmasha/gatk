#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { PREPROCESSING } from '../subworkflows/local/preprocessing/main.nf'
include { VARIANT_CALLING } from '../subworkflows/local/variant_calling/main.nf'

workflow GATK {
    take:
    reference_ch
    reads_ch
    meta_ch

    main:
    versions_ch = channel.empty()

    PREPROCESSING(reference_ch, reads_ch, meta_ch)
    versions_ch = PREPROCESSING.out.versions_ch

    indexed_bam_ch = PREPROCESSING.out.indexed_bam_ch
    ref_with_index_ch = PREPROCESSING.out.reference_with_index_and_dict_ch

    VARIANT_CALLING(indexed_bam_ch,
                    ref_with_index_ch)

    versions_ch = versions_ch.mix(VARIANT_CALLING.out.versions_ch)

    versions_ch
        .map { version_file -> version_file.text }
        .unique()
        .collectFile(name: 'software_versions.yml', storeDir: params.outdir)

    emit:
    final_vcf = VARIANT_CALLING.out.final_vcf
    versions_ch = versions_ch.ifEmpty(null)
}
