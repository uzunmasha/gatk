process CALL_VARIANTS {
    tag { meta.id }

    label 'process_medium'
    label 'error_retry'

    input:
    tuple val(meta), path(bam_file), path(bam_index)
    tuple path(reference), path(reference_index), path(reference_dict)

    output:
    tuple val(meta), path("${meta.id}.g.vcf"), emit: called_variants
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    gatk HaplotypeCaller \
        -R $reference \
        -I $bam_file \
        -O ${meta.id}.g.vcf \
        -ERC GVCF \
        $args

    GATK_VERSION=\$(gatk --version | grep 'GATK' | awk -F 'v' '{print \$2}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk: \$GATK_VERSION
    END_VERSIONS
    """
}
