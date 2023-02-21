#!/bin/bash

CONTAINER="metaphlan"
VERSION="latest"
MOUNT=''
CMD='echo "Start analysis" && metaphlan --bowtie2db /bowtiedb'
INPUT_TYPE="fastq"
BUILD=false
absolute_path() {
  FILE=$1 
  if [[ ${FILE::2} == "./" ]]
  then
    echo "${PWD}/${1:2:${#1}}";
  else
    if [[ ${FILE::1} == "/" ]]
    then
      echo "$FILE"; 
    else
      echo "${PWD}/${FILE}"
    fi
  fi
}

usage() {
  echo "Usage: bash $0 [options]" 1>&2
  echo 1>&2
  echo "Options:" 1>&2
  echo "  --build                                                         build docker image" 1>&2
  echo "  -1                                       STRING                 Input file    (required)" 1>&2
  echo "  -2                                       STRING                 Input file    (required)" 1>&2
  echo "  --bowtie2out                             STRING                 Cache for bowtie2 output    (optional)" 1>&2
  echo "  -o|--output                              STRING                 Output file (required)" 1>&2
  echo "  -*|--*|*                                 All other tag will be redirected to metaphlan" 1>&2
  echo 1>&2
  cat <<EOF
Metaphlan options:
  usage: metaphlan --input_type {fastq,fasta,bowtie2out,sam} [--force] [--bowtie2db METAPHLAN_BOWTIE2_DB] [-x INDEX] [--bt2_ps BowTie2 presets] [--bowtie2_exe BOWTIE2_EXE]
                   [--bowtie2_build BOWTIE2_BUILD] [--bowtie2out FILE_NAME] [--min_mapq_val MIN_MAPQ_VAL] [--no_map] [--tmp_dir] [--tax_lev TAXONOMIC_LEVEL] [--min_cu_len] [--min_alignment_len]
                   [--add_viruses] [--ignore_eukaryotes] [--ignore_bacteria] [--ignore_archaea] [--ignore_ksgbs] [--ignore_usgbs] [--stat_q] [--perc_nonzero] [--ignore_markers IGNORE_MARKERS]
                   [--avoid_disqm] [--stat] [-t ANALYSIS TYPE] [--nreads NUMBER_OF_READS] [--pres_th PRESENCE_THRESHOLD] [--clade] [--min_ab] [-o output file] [--sample_id_key name]
                   [--use_group_representative] [--sample_id value] [-s sam_output_file] [--legacy-output] [--CAMI_format_output] [--unclassified_estimation] [--mpa3] [--biom biom_output]
                   [--mdelim mdelim] [--nproc N] [--subsampling SUBSAMPLING] [--subsampling_seed SUBSAMPLING_SEED] [--install] [--offline] [--force_download] [--read_min_len READ_MIN_LEN] [-v] [-h]
                   [INPUT_FILE] [OUTPUT_FILE]

  DESCRIPTION
   MetaPhlAn version 4.0.4 (17 Jan 2023): 
   METAgenomic PHyLogenetic ANalysis for metagenomic taxonomic profiling.

  AUTHORS: Aitor Blanco-Miguez (aitor.blancomiguez@unitn.it), Francesco Beghini (francesco.beghini@unitn.it), Nicola Segata (nicola.segata@unitn.it), Duy Tin Truong, Francesco Asnicar (f.asnicar@unitn.it)

  COMMON COMMANDS

   We assume here that MetaPhlAn is installed using the several options available (pip, conda, PyPi)
   Also BowTie2 should be in the system path with execution and read permissions, and Perl should be installed)

  ========== MetaPhlAn clade-abundance estimation ================= 

  The basic usage of MetaPhlAn consists in the identification of the clades (from phyla to species ) 
  present in the metagenome obtained from a microbiome sample and their 
  relative abundance. This correspond to the default analysis type (-t rel_ab).

  *  Profiling a metagenome from raw reads:
  $ metaphlan metagenome.fastq --input_type fastq -o profiled_metagenome.txt

  *  You can take advantage of multiple CPUs and save the intermediate BowTie2 output for re-running
     MetaPhlAn extremely quickly:
  $ metaphlan metagenome.fastq --bowtie2out metagenome.bowtie2.bz2 --nproc 5 --input_type fastq -o profiled_metagenome.txt

  *  If you already mapped your metagenome against the marker DB (using a previous MetaPhlAn run), you
     can obtain the results in few seconds by using the previously saved --bowtie2out file and 
     specifying the input (--input_type bowtie2out):
  $ metaphlan metagenome.bowtie2.bz2 --nproc 5 --input_type bowtie2out -o profiled_metagenome.txt

  *  bowtie2out files generated with MetaPhlAn versions below 3 are not compatibile.
     Starting from MetaPhlAn 3.0, the BowTie2 ouput now includes the size of the profiled metagenome and the average read length.
     If you want to re-run MetaPhlAn using these file you should provide the metagenome size via --nreads:
  $ metaphlan metagenome.bowtie2.bz2 --nproc 5 --input_type bowtie2out --nreads 520000 -o profiled_metagenome.txt

  *  You can also provide an externally BowTie2-mapped SAM if you specify this format with 
     --input_type. Two steps: first apply BowTie2 and then feed MetaPhlAn with the obtained sam:
  $ bowtie2 --sam-no-hd --sam-no-sq --no-unal --very-sensitive -S metagenome.sam -x ${mpa_dir}/metaphlan_databases/mpa_v30_CHOCOPhlAn_201901 -U metagenome.fastq
  $ metaphlan metagenome.sam --input_type sam -o profiled_metagenome.txt

  *  We can also natively handle paired-end metagenomes, and, more generally, metagenomes stored in 
    multiple files (but you need to specify the --bowtie2out parameter):
  $ metaphlan metagenome_1.fastq,metagenome_2.fastq --bowtie2out metagenome.bowtie2.bz2 --nproc 5 --input_type fastq

  ------------------------------------------------------------------- 
   

  ========== Marker level analysis ============================ 

  MetaPhlAn introduces the capability of characterizing organisms at the strain level using non
  aggregated marker information. Such capability comes with several slightly different flavours and 
  are a way to perform strain tracking and comparison across multiple samples.
  Usually, MetaPhlAn is first ran with the default -t to profile the species present in
  the community, and then a strain-level profiling can be performed to zoom-in into specific species
  of interest. This operation can be performed quickly as it exploits the --bowtie2out intermediate 
  file saved during the execution of the default analysis type.

  *  The following command will output the abundance of each marker with a RPK (reads per kilo-base) 
     higher 0.0. (we are assuming that metagenome_outfmt.bz2 has been generated before as 
     shown above).
  $ metaphlan -t marker_ab_table metagenome_outfmt.bz2 --input_type bowtie2out -o marker_abundance_table.txt
     The obtained RPK can be optionally normalized by the total number of reads in the metagenome 
     to guarantee fair comparisons of abundances across samples. The number of reads in the metagenome
     needs to be passed with the '--nreads' argument

  *  The list of markers present in the sample can be obtained with '-t marker_pres_table'
  $ metaphlan -t marker_pres_table metagenome_outfmt.bz2 --input_type bowtie2out -o marker_abundance_table.txt
     The --pres_th argument (default 1.0) set the minimum RPK value to consider a marker present

  *  The list '-t clade_profiles' analysis type reports the same information of '-t marker_ab_table'
     but the markers are reported on a clade-by-clade basis.
  $ metaphlan -t clade_profiles metagenome_outfmt.bz2 --input_type bowtie2out -o marker_abundance_table.txt

  *  Finally, to obtain all markers present for a specific clade and all its subclades, the 
     '-t clade_specific_strain_tracker' should be used. For example, the following command
     is reporting the presence/absence of the markers for the B. fragilis species and its strains
     the optional argument --min_ab specifies the minimum clade abundance for reporting the markers

  $ metaphlan -t clade_specific_strain_tracker --clade s__Bacteroides_fragilis metagenome_outfmt.bz2 --input_type bowtie2out -o marker_abundance_table.txt

  ------------------------------------------------------------------- 

  positional arguments:
    INPUT_FILE            the input file can be:
                          * a fastq file containing metagenomic reads
                          OR
                          * a BowTie2 produced SAM file. 
                          OR
                          * an intermediary mapping file of the metagenome generated by a previous MetaPhlAn run 
                          If the input file is missing, the script assumes that the input is provided using the standard 
                          input, or named pipes.
                          IMPORTANT: the type of input needs to be specified with --input_type
    OUTPUT_FILE           the tab-separated output file of the predicted taxon relative abundances 
                          [stdout if not present]

  Required arguments:
    --input_type {fastq,fasta,bowtie2out,sam}
                          set whether the input is the FASTA file of metagenomic reads or 
                          the SAM file of the mapping of the reads against the MetaPhlAn db.

  Mapping arguments:
    --force               Force profiling of the input file by removing the bowtie2out file
    --bowtie2db METAPHLAN_BOWTIE2_DB
                          Folder containing the MetaPhlAn database. You can specify the location by exporting the DEFAULT_DB_FOLDER variable in the shell.[default /usr/local/lib/python3.11/site-packages/metaphlan/metaphlan_databases]
    -x INDEX, --index INDEX
                          Specify the id of the database version to use. If "latest", MetaPhlAn will get the latest version.
                          If an index name is provided, MetaPhlAn will try to use it, if available, and skip the online check.
                          If the database files are not found on the local MetaPhlAn installation they
                          will be automatically downloaded [default latest]
    --bt2_ps BowTie2 presets
                          Presets options for BowTie2 (applied only when a FASTA file is provided)
                          The choices enabled in MetaPhlAn are:
                           * sensitive
                           * very-sensitive
                           * sensitive-local
                           * very-sensitive-local
                          [default very-sensitive]
    --bowtie2_exe BOWTIE2_EXE
                          Full path and name of the BowTie2 executable. This option allowsMetaPhlAn to reach the executable even when it is not in the system PATH or the system PATH is unreachable
    --bowtie2_build BOWTIE2_BUILD
                          Full path to the bowtie2-build command to use, deafult assumes that 'bowtie2-build is present in the system path
    --bowtie2out FILE_NAME
                          The file for saving the output of BowTie2
    --min_mapq_val MIN_MAPQ_VAL
                          Minimum mapping quality value (MAPQ) [default 5]
    --no_map              Avoid storing the --bowtie2out map file
    --tmp_dir             The folder used to store temporary files [default is the OS dependent tmp dir]

  Post-mapping arguments:
    --tax_lev TAXONOMIC_LEVEL
                          The taxonomic level for the relative abundance output:
                          'a' : all taxonomic levels
                          'k' : kingdoms
                          'p' : phyla only
                          'c' : classes only
                          'o' : orders only
                          'f' : families only
                          'g' : genera only
                          's' : species only
                          't' : SGBs only
                          [default 'a']
    --min_cu_len          minimum total nucleotide length for the markers in a clade for
                          estimating the abundance without considering sub-clade abundances
                          [default 2000]
    --min_alignment_len   The sam records for aligned reads with the longest subalignment
                          length smaller than this threshold will be discarded.
                          [default None]
    --add_viruses         Together with --mpa3, allow the profiling of viral organisms
    --ignore_eukaryotes   Do not profile eukaryotic organisms
    --ignore_bacteria     Do not profile bacterial organisms
    --ignore_archaea      Do not profile archeal organisms
    --ignore_ksgbs        Do not profile known SGBs (together with --sgb option)
    --ignore_usgbs        Do not profile unknown SGBs (together with --sgb option)
    --stat_q              Quantile value for the robust average
                          [default 0.2]
    --perc_nonzero        Percentage of markers with a non zero relative abundance for misidentify a species
                          [default 0.33]
    --ignore_markers IGNORE_MARKERS
                          File containing a list of markers to ignore. 
    --avoid_disqm         Deactivate the procedure of disambiguating the quasi-markers based on the 
                          marker abundance pattern found in the sample. It is generally recommended 
                          to keep the disambiguation procedure in order to minimize false positives
    --stat                Statistical approach for converting marker abundances into clade abundances
                          'avg_g'  : clade global (i.e. normalizing all markers together) average
                          'avg_l'  : average of length-normalized marker counts
                          'tavg_g' : truncated clade global average at --stat_q quantile
                          'tavg_l' : truncated average of length-normalized marker counts (at --stat_q)
                          'wavg_g' : winsorized clade global average (at --stat_q)
                          'wavg_l' : winsorized average of length-normalized marker counts (at --stat_q)
                          'med'    : median of length-normalized marker counts
                          [default tavg_g]

  Additional analysis types and arguments:
    -t ANALYSIS TYPE      Type of analysis to perform: 
                           * rel_ab: profiling a metagenomes in terms of relative abundances
                           * rel_ab_w_read_stats: profiling a metagenomes in terms of relative abundances and estimate the number of reads coming from each clade.
                           * reads_map: mapping from reads to clades (only reads hitting a marker)
                           * clade_profiles: normalized marker counts for clades with at least a non-null marker
                           * marker_ab_table: normalized marker counts (only when > 0.0 and normalized by metagenome size if --nreads is specified)
                           * marker_counts: non-normalized marker counts [use with extreme caution]
                           * marker_pres_table: list of markers present in the sample (threshold at 1.0 if not differently specified with --pres_th
                           * clade_specific_strain_tracker: list of markers present for a specific clade, specified with --clade, and all its subclades
                          [default 'rel_ab']
    --nreads NUMBER_OF_READS
                          The total number of reads in the original metagenome. It is used only when 
                          -t marker_table is specified for normalizing the length-normalized counts 
                          with the metagenome size as well. No normalization applied if --nreads is not 
                          specified
    --pres_th PRESENCE_THRESHOLD
                          Threshold for calling a marker present by the -t marker_pres_table option
    --clade               The clade for clade_specific_strain_tracker analysis
    --min_ab              The minimum percentage abundance for the clade in the clade_specific_strain_tracker analysis

  Output arguments:
    -o output file, --output_file output file
                          The output file (if not specified as positional argument)
    --sample_id_key name  Specify the sample ID key for this analysis. Defaults to 'SampleID'.
    --use_group_representative
                          Use a species as representative for species groups.
    --sample_id value     Specify the sample ID for this analysis. Defaults to 'Metaphlan_Analysis'.
    -s sam_output_file, --samout sam_output_file
                          The sam output file
    --legacy-output       Old MetaPhlAn2 two columns output
    --CAMI_format_output  Report the profiling using the CAMI output format
    --unclassified_estimation
                          Scale relative abundances to the number of reads mapping to identified clades in order to estimate unclassified taxa
    --mpa3                Perform the analysis using the MetaPhlAn 3 algorithm
    --biom biom_output, --biom_output_file biom_output
                          If requesting biom file output: The name of the output file in biom format 
    --mdelim mdelim, --metadata_delimiter_char mdelim
                          Delimiter for bug metadata: - defaults to pipe. e.g. the pipe in k__Bacteria|p__Proteobacteria 

  Other arguments:
    --nproc N             The number of CPUs to use for parallelizing the mapping [default 4]
    --subsampling SUBSAMPLING
                          Specify the number of reads to be considered from the input metagenomes [default None]
    --subsampling_seed SUBSAMPLING_SEED
                          Random seed to use in the selection of the subsampled reads. Choose "random
                           for a random behaviour
    --install             Only checks if the MetaPhlAn DB is installed and installs it if not. All other parameters are ignored.
    --offline             If used, MetaPhlAn will not check for new database updates.
    --force_download      Force the re-download of the latest MetaPhlAn database.
    --read_min_len READ_MIN_LEN
                          Specify the minimum length of the reads to be considered when parsing the input file with 'read_fastx.py' script, default value is 70
    -v, --version         Prints the current MetaPhlAn version and exit
    -h, --help            show this help message and exit
EOF
}

## Get parameters
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --build)
      BUILD=true
      shift
      ;;
    -1)
      FIRST_FILE="$2"
      FIRST_TARGET='/app/pair.1.fastq.gz'
      MOUNT="$MOUNT $([ "$FIRST_FILE" != '' ] && echo --mount type=bind,source="$(absolute_path "$FIRST_FILE")",target="$FIRST_TARGET")"
      shift # past argument
      shift # past value
      ;;
    -2)
      SECOND_FILE="$2"
      SECOND_TARGET='/app/pair.2.fastq.gz'
      MOUNT="$MOUNT $([ "$SECOND_FILE" != '' ] && echo --mount type=bind,source="$(absolute_path "$SECOND_FILE")",target="$SECOND_TARGET")"
      shift # past argument
      shift # past value
      ;;
    -i|--input-type)
      INPUT_TYPE="$2"
      shift
      shift
      ;;
    --bowtie2out)
      BOWTIE_FILE="$2"
      touch $BOWTIE_FILE
      BOWTIE_TARGET='/app/bowtie.txt'
      MOUNT="$MOUNT $([ "$BOWTIE_FILE" != '' ] && echo --mount type=bind,source="$(absolute_path "$BOWTIE_FILE")",target="$BOWTIE_TARGET")"
      shift # past argument
      shift # past value
      ;;
    --unclassified-estimation)
      UNCLASSIFIED_ESTIMATION=true
      shift # past value
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      touch $OUTPUT_FILE
      OUTPUT_TARGET="/app/output.txt"
      MOUNT="$MOUNT $([ "$OUTPUT_FILE" != '' ] && echo --mount type=bind,source="$(absolute_path "$OUTPUT_FILE")",target="$OUTPUT_TARGET")"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    #-*|--*)
    #  echo "Unknown option $1"
    #  exit 1
    #  ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [[ "$BUILD" != false ]]; then
  echo -e "Container not found.\nBuilding container $CONTAINER:$VERSION"
  echo -e "FROM python:latest\nRUN apt update && apt install -y bowtie2 && pip install MetaPhlAn && metaphlan --install --bowtie2db /bowtiedb\nWORKDIR /app\nVOLUME /app /bowtiedb" | docker build -t $CONTAINER:$VERSION - < /dev/stdin
  exit 0
fi


CMD="$CMD $FIRST_TARGET$([ "$SECOND_FILE" != '' ] && echo ",$SECOND_TARGET")"
CMD="$CMD --input_type $INPUT_TYPE"
CMD="$CMD $([ "$UNCLASSIFIED_ESTIMATION" != '' ] && echo "--unclassified_estimation")"
CMD="$CMD $([ "$OUTPUT_FILE" != '' ] && echo "-o $OUTPUT_TARGET")"
## bowtie must not exists.
CMD="$CMD $([ "$BOWTIE_FILE" != '' ] && echo "--bowtie2out /tmp/bowtie.txt ${POSITIONAL_ARGS[@]} && cp /tmp/bowtie.txt $BOWTIE_TARGET")"

echo "Creating container..."
docker run -it --rm $MOUNT $CONTAINER:$VERSION /bin/bash -c "$CMD"
