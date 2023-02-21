# docker-MetaPhlAn
This is a script to run MetaPhlAn inside a docker container. It create a container with MetaPhlAn4 and mount all the provided file inside the container. All the arguments will be forwarded to the container. 

MetaPhlAn is a computational tool for profiling the composition of microbial communities (Bacteria, Archaea and Eukaryotes) from metagenomic shotgun sequencing data (i.e. not 16S) with species-level. With StrainPhlAn, it is possible to perform accurate strain-level microbial profiling.

For more information about MetaPhlAn please check the official repository of the project: https://github.com/biobakery/MetaPhlAn/wiki/MetaPhlAn-4#installation.

## Usage

To run the analysis just call the script with the following arguments. All the others MetaPhlAn arguments will be redirected to the MetaPhlAn installation inside the container.
```
Usage: bash ./metaphlan.sh [options]

Options:
  --build                                                         build docker image
  -1                                       STRING                 Input file    (required)
  -2                                       STRING                 Input file    (required)
  --bowtie2out                             STRING                 Cache for bowtie2 output    (optional)
  -o|--output                              STRING                 Output file (required)
  -*|--*|*                                 All other tag will be redirected to metaphlan
```

Before run the script be sure to build the image.
```
$ metaphlan.sh --build
```
