nextflow.enable.dsl=2

include { CALL_VARIANTS     } from '../../modules/call_variants/main.nf'
include { CONSOLIDATE_GVCFS } from '../../modules/consolidate_gvcfs/main.nf'
include { CREATE_GVCF_LIST  } from '../../modules/create_gvcf_list/main.nf'
include { GENOTYPE          } from '../../modules/genotype/main.nf'

workflow VARIANT_CALLING {
    take:
    indexed_bam_ch
    ref_with_index_ch

    main:
    versions_ch = channel.empty()

    CALL_VARIANTS(indexed_bam_ch, ref_with_index_ch)
    gvcf_ch = CALL_VARIANTS.out.called_variants
    versions_ch = versions_ch.mix(CALL_VARIANTS.out.versions)

    gvcf_list_ch = CREATE_GVCF_LIST(gvcf_ch)

    CONSOLIDATE_GVCFS(gvcf_list_ch)
    genomicsdb_ch = CONSOLIDATE_GVCFS.out.consolidated_gvcfs
    versions_ch = versions_ch.mix(CONSOLIDATE_GVCFS.out.versions)

    GENOTYPE(genomicsdb_ch, ref_with_index_ch)
    versions_ch = versions_ch.mix(GENOTYPE.out.versions)

    emit:
    final_vcf = GENOTYPE.out.final_vcf
    versions_ch = versions_ch.ifEmpty(null)
}
