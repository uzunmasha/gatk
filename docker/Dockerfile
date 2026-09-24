FROM continuumio/miniconda3:25.1.1-2

RUN apt-get update && apt-get install -y \
    curl \
    git \
    bzip2 \
    wget \
    && rm -rf /var/lib/apt/lists/*

    RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda install -y \
    samtools \
    bwa \
    gatk4 \
    picard \
    vcftools \
    htslib \
    bedtools \
    bcftools \
    openjdk \
    python=3.10 \
    && conda clean -a
