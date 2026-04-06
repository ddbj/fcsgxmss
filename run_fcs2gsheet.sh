#!/bin/bash

# RESULTDIR="/home/$(whoami)/fcsgxmss"
RESULTDIR="/home/w3const/fcslog/gx"
FCSDIR="/data1/FCS"
INSTALLDIR="/home/w3const/fcsgx_mss"

# enable python3 modules
. /home/w3const/work-kosuge/mypy/bin/activate

showusage() {
echo "Easily run FCS-GX against MSS submissions, ant put the result in ~/fcsgxmss and Gsheet."
echo ""
echo "# Prerequisites"
echo "Create ~/fcsgxmss directory, it is used for saving the results."
echo "# How to use"
echo "bash run_fcs2gsheet.sh -d <NSUB directory e.g. /home/w3const/submissions/production/NSUB001123/20230831-145646> [-h]" 
exit 0
}

[ -e ${FCSDIR}/fcsgxmss.sh ] || { echo "Please prepare 'fcsgxmss.sh' in ${FCSDIR}/, aborting." ; exit 1; }

# Show usage if options are not specified
if [ $# -eq 0 ]; then
  showusage
fi

while getopts ":d:h" OPT
do
  case $OPT in
    d) NSUBDIR="$OPTARG" ;;
    h) showusage ;;
    :) showusage ;;
    \?) showusage ;;
  esac
done
tmp=${NSUBDIR}
NSUBDIR=${tmp%/} # Remove trailing slash if exists
[ -d "$NSUBDIR" ] || { echo "${NSUBDIR} directory does not exist, aborting." ; exit 1; }

# Existence of result directory
if [ -d "$RESULTDIR" ] ; then
    echo "${RESULTDIR} directory is used for saving the results."
    echo "------------------------------"
else
    read -p "${RESULTDIR} directory does not exist. Do you want to create it? (y/n) " yn
    case $yn in
    [Yy] ) mkdir -v -p ${RESULTDIR} ;;
    [Nn] ) echo "Please create ${RESULTDIR} directory and run the script again." ; exit 0 ;;
    * ) echo "Please answer y or n, aborted." ; exit 0 ;;
    esac
fi

# Picks up the NSUB number from directory name
nsubnum=$(grep -oP "NSUB\d{6}" <<< ${NSUBDIR})
if [ -z "$nsubnum" ]; then
    read -p "Please input NSUB number (e.g. NSUB001234): " n
    nsubnum=${n}
fi

# Create NSUBnum directory in RESULTDIR
if [ -d "${RESULTDIR}/${nsubnum}" ] ;then
    echo "${RESULTDIR}/${nsubnum} directory already exists, the result will be put in this directory."
else
    mkdir -v ${RESULTDIR}/${nsubnum}
fi

exec > >(tee ${RESULTDIR}/${nsubnum}/run_fcs2gsheet.log)
echo "# mass-id: ${nsubnum}"
truncate -s 0 ${RESULTDIR}/${nsubnum}/00fcs.sh

# Checking each submission pair file
anns=$(ls ${NSUBDIR}/*{.ann,.annt.tsv,.ann.txt} 2>/dev/null)
[ -z "$anns" ] && echo "No annotation file (.ann, .annt.tsv, .ann.txt) is found in ${NSUBDIR}, aborting." && exit 0
for f in $anns; do
    # echo ${f##*/}
    filename_ann=${f##*/}
    for extann in ".annt.tsv" ".ann.txt" ".ann"; do
        if [ ${filename_ann} != ${filename_ann%$extann} ]; then
        # echo "File extension is $extann"
        filename_base=${filename_ann%$extann}
        tmp=$(ls ${NSUBDIR}/${filename_base}{.fasta,.fa,.fna,.seq,.seq.fa} 2>/dev/null) #.fa includes .seq.fa
        if [ -z "$tmp" ]; then
        echo "Cannot find the corresponding sequence file: ${filename_base}, aborting."
        exit 0
        else
        filename_seq=${tmp##*/}
        fi
        break
        fi
    done
    # Parsing the annotation file
    echo "# $filename_ann, $filename_seq"
    tmp=$(python3 ${INSTALLDIR}/getsourcesum.py ${NSUBDIR}/${filename_ann})
    [ -z "$tmp" ] && echo "Some error occurred in ${filename_ann}, aborting." && exit 0
    echo "$tmp"
    taxid=$(echo "$tmp" | grep -oP "(?<=taxid:)\d+")
    echo "TAXID = $taxid"
    [ -z "$taxid" ] && taxid="UNKNOWN"
    echo "${FCSDIR}/fcsgxmss.sh -q ${NSUBDIR}/${filename_seq} -t ${taxid} -o ${RESULTDIR}/${nsubnum}" >> ${RESULTDIR}/${nsubnum}/00fcs.sh
done

# Run FCS-GX
if grep -q 't UNKNOWN' ${RESULTDIR}/${nsubnum}/00fcs.sh ; then
    echo "Taxid is UNKNOWN in one or more annotation files, please open ${RESULTDIR}/${nsubnum}/00fcs.sh and fill in an accurate taxid."
    read -p "Have you edited 00fcs.sh (y/n)? " yn
    case $yn in
    [Yy] ) echo "Soon FCS-GX will be started." ;;
    [Nn] ) echo "Program will be aborted. Please edit ${RESULTDIR}/${nsubnum}/00fcs.sh and run the script manually." ; exit 0 ;;
    * ) echo "Please answer y/n. Program aported." ; exit 0 ;;
    esac
fi
# Delete old result
rm -f ${RESULTDIR}/${nsubnum}/*.fcs_gx_report.txt ${RESULTDIR}/${nsubnum}/*.taxonomy.rpt
echo "# Running FCS-GX"
bash ${RESULTDIR}/${nsubnum}/00fcs.sh 2>&1 | tee ${RESULTDIR}/${nsubnum}/00fcs.log

# Looking for the contamination in the log
c=$(grep "TOTAL                       " ${RESULTDIR}/${nsubnum}/00fcs.log | awk 'BEGIN { sum=0 } { sum+=$2 } END { print sum }')
echo ""

# Create xlsx and upload it to Gdrive
python3 ${INSTALLDIR}/fcsresult-xls.py -d ${RESULTDIR}/${nsubnum}

echo ""
if [ $c -eq 0 ]; then
    echo "No contamination"
    echo "Please find the result in ${RESULTDIR}/${nsubnum}/${nsubnum}.xlsx"
else
    echo "Contamination is detected"
    echo "Please find the result in ${RESULTDIR}/${nsubnum}/${nsubnum}.xlsx or https://drive.google.com/drive/u/1/folders/15E0yNLuRQdmW5bN6wDOxEoAzE-EuLyjH"
fi
echo "# Finished."
