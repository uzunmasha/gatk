process CONSOLIDATE_GVCFS {
    tag { meta.id }

    label 'process_high'
    label 'error_terminate'

    input:
    tuple val(meta), path ("gvcf_list.txt"), path ("*.g.vcf")

    output:
    tuple val(meta), path("${meta.id}_genomicsdb"), emit: consolidated_gvcfs
    path "versions.yml", emit: versions

    script:
    def interval = params.intervals ?: 'chr20'
    """
    gatk GenomicsDBImport \
        --genomicsdb-workspace-path ${meta.id}_genomicsdb \
        --sample-name-map gvcf_list.txt \
        -L $interval \
        --reader-threads $task.cpus

    GATK_VERSION=\$(gatk --version | grep 'GATK' | awk -F 'v' '{print \$2}')
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk: \$GATK_VERSION
    END_VERSIONS
    """
}
