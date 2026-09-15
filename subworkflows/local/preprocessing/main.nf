nextflow.enable.dsl=2

include { CREATE_GENOME_INDEX } from '../../../modules/local/create_genome_index/main.nf'
include { CREATE_FASTA_INDEX  } from '../../../modules/local/create_fasta_index/main.nf'
include { CREATE_SEQ_DICT     } from '../../../modules/local/create_seq_dict/main.nf'
include { ALIGN_READS         } from '../../../modules/local/align_reads/main.nf'
include { ADD_READ_GROUPS     } from '../../../modules/local/add_read_groups/main.nf'
include { SORT_BAM            } from '../../../modules/local/sort_bam/main.nf'
include { INDEX_BAM           } from '../../../modules/local/index_bam/main.nf'

workflow PREPROCESSING {
    take:
    reference_ch
    reads_ch
    meta_ch

    main:
    versions_ch = channel.empty()

    def index_extensions = ['amb', 'ann', 'bwt', 'pac', 'sa']
    def reference_name = file(params.reference).getName()
    def index_files_exist = index_extensions
        .collect { ext -> file("${params.input_data_dir}/indices/${reference_name}.${ext}") }
        .every { file -> file.exists() }

    if (index_files_exist) {
        println "[INFO] Index files already exist in 'indices', skipping CREATE_GENOME_INDEX"

        indexed_reference_ch = meta_ch.map { meta ->
            tuple(
                meta,
                file("${params.input_data_dir}/indices/${reference_name}"),
                index_extensions.collect { ext -> file("${params.input_data_dir}/indices/${reference_name}.${ext}") }
            )
        }
    } else {
    CREATE_GENOME_INDEX(meta_ch, reference_ch)
    ref_and_index_ch = CREATE_GENOME_INDEX.out.indexed_reference
        .map { _meta, reference, index_files -> tuple(reference, index_files) }
        .first()
    indexed_reference_ch = meta_ch.combine(ref_and_index_ch)
        .map { meta, reference, index_files -> tuple(meta, reference, index_files) }
    versions_ch = versions_ch.mix(CREATE_GENOME_INDEX.out.versions)
    }

    CREATE_SEQ_DICT(meta_ch, reference_ch)
    dict_ch = CREATE_SEQ_DICT.out.dictionary
    versions_ch = versions_ch.mix(CREATE_SEQ_DICT.out.versions)

    CREATE_FASTA_INDEX(meta_ch, reference_ch)
    fasta_index_ch = CREATE_FASTA_INDEX.out.fasta_index
    versions_ch = versions_ch.mix(CREATE_FASTA_INDEX.out.versions)

    ALIGN_READS(reads_ch, indexed_reference_ch)
    aligned_reads = ALIGN_READS.out.aligned_reads
    versions_ch = versions_ch.mix(ALIGN_READS.out.versions)

    ADD_READ_GROUPS(aligned_reads)
    added_groups_ch = ADD_READ_GROUPS.out.read_groups_bam
    versions_ch = versions_ch.mix(ADD_READ_GROUPS.out.versions)

    SORT_BAM(added_groups_ch)
    sorted_bam_ch = SORT_BAM.out.sorted_bam
    versions_ch = versions_ch.mix(SORT_BAM.out.versions)

    INDEX_BAM(sorted_bam_ch)
    versions_ch = versions_ch.mix(INDEX_BAM.out.versions)

    emit:
    indexed_bam_ch = INDEX_BAM.out.indexed_bam
    reference_with_index_and_dict_ch = reference_ch
        .combine(fasta_index_ch)
        .combine(dict_ch)
        .map { reference, fasta_index, dict -> tuple(reference, fasta_index, dict) }
        .first()
    versions_ch = versions_ch.ifEmpty(null)
}
