process CREATE_FASTA_INDEX {
    tag { meta.id }

    label 'process_low'
    label 'error_terminate'

    input:
    val meta
    path reference

    output:
    path ("*.fa.fai"), emit: fasta_index
    path "versions.yml", emit: versions

    script:
    """
    samtools faidx $reference

    SAMTOOLS_VERSION=\$(samtools --version | head -n 1 | awk '{print \$2}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$SAMTOOLS_VERSION
    END_VERSIONS
    """
}
