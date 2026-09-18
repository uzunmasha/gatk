#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { validateParameters; samplesheetToList } from 'plugin/nf-schema'
include { GATK } from './workflows/gatk'

workflow {
    main:
    validateParameters()

    reference_ch = channel.fromPath(params.reference)

    reads_ch = channel.fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
        .map { sample, fastq_1, fastq_2 -> tuple(sample, file(fastq_1), file(fastq_2)) }

    meta_ch = reads_ch.map { sample_id, _read1, _read2 -> [id: sample_id] }

    GATK(reference_ch, reads_ch, meta_ch)
}
