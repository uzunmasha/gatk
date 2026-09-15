process SORT_BAM {
    tag { meta.id }

    label 'process_high'
    label 'error_terminate'

    input:
    tuple val(meta), path(bam_file)

    output:
    tuple val(meta), path("${meta.id}_sorted.bam"), emit: sorted_bam
    path "versions.yml", emit: versions

    script:
    """
    samtools sort -@ ${task.cpus} -o ${meta.id}_sorted.bam $bam_file

    SAMTOOLS_VERSION=\$(samtools --version | head -n 1 | awk '{print \$2}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$SAMTOOLS_VERSION
    END_VERSIONS
    """
}
