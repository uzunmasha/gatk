process ALIGN_READS {
    tag { meta.id }

    label 'process_medium'
    label 'error_retry'

    input:
    tuple val(sample_id), path(read1), path(read2)
    tuple val(meta), path(reference), path(index_files)

    output:
    tuple val(meta), path("${sample_id}.sam"), emit: aligned_reads
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''

    """
    bwa mem $args $reference $read1 $read2 > ${meta.id}.sam

    BWA_VERSION=\$(bwa 2>&1 | grep 'Version' | awk '{print \$2}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$BWA_VERSION
    END_VERSIONS
    """
}
