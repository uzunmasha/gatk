process CREATE_GVCF_LIST {
    tag { meta.id }

    label 'process_low'
    label 'error_terminate'

    input:
    tuple val(meta), path(gvcf_files)

    output:
    tuple val(meta), path ("${meta.id}_gvcf_list.txt"), emit: gvcf_list

    script:
    """
    > ${meta.id}_gvcf_list.txt
    for gvcf in ${gvcf_files}; do
        sample_id=\$(basename \$gvcf .g.vcf)
        echo -e "\${sample_id}\t\$(realpath \$gvcf)" >> ${meta.id}_gvcf_list.txt
    done
    """
}
