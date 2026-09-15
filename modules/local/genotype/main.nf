process GENOTYPE {
    tag { meta.id }

    label 'process_low'
    label 'error_terminate'

    input:
    tuple val(meta), path ("genomicsdb")
    tuple path(reference), path(reference_index), path(reference_dict)

    output:
    tuple val(meta), path("${meta.id}.vcf"), emit: final_vcf
    path "versions.yml", emit: versions

    script:
    """
    gatk GenotypeGVCFs \
        -R $reference \
        -V gendb://genomicsdb \
        -O ${meta.id}.vcf

    GATK_VERSION=\$(gatk --version | grep 'GATK' | awk -F 'v' '{print \$2}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk: \$GATK_VERSION
    END_VERSIONS
    """
}
