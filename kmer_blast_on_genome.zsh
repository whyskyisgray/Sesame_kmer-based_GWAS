#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 -i <input_file> -r <reference_db>"
    echo ""
    echo "Options:"
    echo "  -i <input_file>    Specify the input fasta file"
    echo "  -r <reference_db>  Specify the reference database"
    echo "  -h                 Show this help message"
}

# Parse command line arguments
while getopts "hi:r:" opt; do
    case ${opt} in
        h )
            show_help
            exit 0
            ;;
        i )
            infile=$OPTARG
            ;;
        r )
            ref=$OPTARG
            ;;
        \? )
            show_help
            exit 1
            ;;
    esac
done

# Check if both -i and -r options were provided
if [ -z "$infile" ] || [ -z "$ref" ]; then
    echo "Error: Both input file and reference database must be specified."
    show_help
    exit 1
fi

# Process the input file and run the blastn command
line=`echo $infile | rev | cut -d . -f 2- | rev`
blastn -query $line.fa -db $ref -outfmt 6 | awk '$3>99 && $4==31' | awk -v OFS="\t" '{split($1, a, "_")} {print $2,$9,a[1],a[2]}' | sed '1i chr\tpos\tno\tp'