process ADD_READ_GROUPS{
    tag { meta.id }

    label 'process_medium'
    label 'error_retry'

    input:
    tuple val(meta), path(sam_file)

    output:
    tuple val(meta), path("${meta.id}_rg.bam"), emit: read_groups_bam
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    picard AddOrReplaceReadGroups \
    I=$sam_file \
    O=${meta.id}_rg.bam \
    RGID=${meta.id} \
    RGSM=${meta.id} \
    $args

    PICARD_VERSION=\$(gatk --version | grep "Picard Version" | awk '{print \$NF}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$PICARD_VERSION
    END_VERSIONS
    """
}
