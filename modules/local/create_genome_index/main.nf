process CREATE_GENOME_INDEX {
    tag { meta.id }

    label 'process_medium'
    label 'error_retry'

    publishDir "${params.input_data_dir}/indices", mode: 'copy'

    input:
    val meta
    path reference

    output:
    tuple val(meta), path(reference), path("${reference}.*"), emit: indexed_reference
    path "versions.yml", emit: versions

    script:
    """
    bwa index $reference

    VERSION=\$(bwa 2>&1 | grep Version | awk '{print \$2}')

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$VERSION
    END_VERSIONS
    """
}
