process INDEX_BAM {
    tag { meta.id }

    label 'process_low'
    label 'error_terminate'

    input:
    tuple val(meta), path(bam_file)

    output:
    tuple val(meta), path(bam_file), path("${bam_file}.bai"), emit: indexed_bam
    path "versions.yml", emit: versions

    script:
    """
    samtools index -@ ${task.cpus} $bam_file

    SAMTOOLS_VERSION=\$(samtools --version | head -n 1 | awk '{print \$2}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$SAMTOOLS_VERSION
    END_VERSIONS
    """
}
