process CREATE_SEQ_DICT {
    tag { meta.id }

    label 'process_low'
    label 'error_terminate'

    input:
    val meta
    path reference

    output:
    path ("*.dict"), emit: dictionary
    path "versions.yml", emit: versions

    script:
    """
    gatk CreateSequenceDictionary \
    -R $reference \
    -O ${reference.baseName}.dict

    GATK_VERSION=\$(gatk --version | grep 'GATK' | awk -F 'v' '{print \$2}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk: \$GATK_VERSION
    END_VERSIONS
    """
}
