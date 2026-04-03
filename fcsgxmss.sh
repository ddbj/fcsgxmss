#!/bin/bash
# ./fcsgxmss.sh
# You can find the fcs-gx result as on your ~/.

export LANG=C
export FCS_DEFAULT_IMAGE=fcs-gx.sif

FCSHOME="/data1/FCS"
GXQUERY=${FCSHOME}/gx-query
ACCOUNT=$(whoami)
GXOUTDIR=${HOME}/fcsgxmss
SUBMISSION="/home/w3const/submissions/production"
# Reference database, w/o RAMDISK
GXDB_LOC=${FCSHOME}/local_db
# w/ RAM disk, designate the directory mounted to RAM disk
# GXDB_LOC=/dev/shm/FCS-w3const/local_db

# delete former query
find ${GXQUERY} -type d -name "tmpmsswork_${ACCOUNT}_*" | xargs rm -rf

# Options
showusage() {
echo "Easily run FCS-GX against MSS submissions."
echo ""
echo "# How to use"
echo "ssh a012"
echo "cd /data1/FCS"
echo "./fcsgxmss.sh -q <NSUB######>|<path to a fasta file> -t <tax ID> [-o <directory name>]"
echo "You will find the FCS-GX result in ~/fcsgxmss as default."
echo ""
echo "e.g. 1"
echo "./fcsgxmss.sh -q ~/w3const/submissions/production/NSUB001887/20240702-151414/SAMD00797160_TA6350.fasta -t 2104"
echo "e.g. 2"
echo "You can do FCS-GX against the latest submission files when NSUB number is designated at -q option"
echo "./fcsgxmss.sh -q NSUB001972 -t 105296"
echo "e.g. 3"
echo "Use of -o option can change the output directory to your favorite one. You should prepare the output directory in advance when you use -d option."
echo "./fcsgxmss.sh -q ~/w3const/submissions/production/NSUB001887/20240702-151414/SAMD00797160_TA6350.fasta -t 2104 -o ~/myresult"
exit 0
}

OPTFLAG="N"
CHK=""
while getopts ":q:t:o:h" OPT
do
  case $OPT in
    q) OPTVALUE_Q=$OPTARG ;;
    t) OPTVALUE_T=$OPTARG ;;
    o) OPTVALUE_O=$OPTARG ;;
    h) showusage ;;
    :) showusage ;;
    \?) echo "[ERROR] Undefined options." ;;
  esac
done

if [ -d ${SUBMISSION}/${OPTVALUE_Q} ]; then
  echo "NSUB number is correct"
  CHK="good"
  OPTFLAG="NSUBnumber"
fi
if [ -s $OPTVALUE_Q ];then
  echo "Query is filepath"
  CHK="good"
  OPTFLAG="Filepash"
fi
if [ -n "${OPTVALUE_O}" ];then
    if [ -d "${OPTVALUE_O}" ];then
        GXOUTDIR=${OPTVALUE_O}
    else
        echo "Please make ${OPTVALUE_O} directory in advance."
        exit 0
    fi
fi
if [ -z ${CHK} ]; then
  echo "Wrong query"
  echo ""
  showusage
fi

# Query is NSUB
fcsgx1() {
  # Get query, copy to NVMe partition
  QDIRFULL=$(ls -lAd ${SUBMISSION}/${OPTVALUE_Q}/*/ | tail -n1 | awk '{print $9}')
  QDIRSHORT=${QDIRFULL/${SUBMISSION}\/${OPTVALUE_Q}\//}
  # e.g. ls -lAd /home/w3const/submissions/production/NSUB002278/*/ | tail -n1 | awk '{print $9}'

  cp -rv ${QDIRFULL} ${GXQUERY}/tmpmsswork_${ACCOUNT}_${OPTVALUE_Q}_${QDIRSHORT}

  # Remove // at .fasta .seq.fa .fa .fna .seq
  FASFILES=$(find ${GXQUERY}/tmpmsswork_${ACCOUNT}_${OPTVALUE_Q}_${QDIRSHORT} -name '*.fasta' -or -name '*.fa' -or -name '*.fna' -or -name '*.seq')
  for v in ${FASFILES};do
  # nkf -Lu --overwrite $v
  tr '\r' '\n' <${v} > ${v}.tmp && mv -f ${v}.tmp ${v}
  sed -i 's@^/\+$@@g' $v
  sed -i '/^$/d' $v
  done

  # Run fcs-gx
  cd ${FCSHOME}
  for v in ${FASFILES};do
  python3 ./fcs.py screen genome --fasta ${v} --out-dir ${GXOUTDIR}/${OPTVALUE_Q} --gx-db "$GXDB_LOC/gxdb" --tax-id ${OPTVALUE_T}
  done

  echo "The result is saved in ${GXOUTDIR}/${OPTVALUE_Q}"
}

# Query is a fasta file
fcsgx2() {
  # Get query, copy to NVMe partition
  mkdir -m 775 ${GXQUERY}/tmpmsswork_${ACCOUNT}
  cp -v ${OPTVALUE_Q} ${GXQUERY}/tmpmsswork_${ACCOUNT}/
  # Remove //
  # nkf -Lu --overwrite ${GXQUERY}/tmpmsswork_${ACCOUNT}/${OPTVALUE_Q##*/}
  tr '\r' '\n' <${GXQUERY}/tmpmsswork_${ACCOUNT}/${OPTVALUE_Q##*/} > ${GXQUERY}/tmpmsswork_${ACCOUNT}/${OPTVALUE_Q##*/}.tmp && \
  mv -f ${GXQUERY}/tmpmsswork_${ACCOUNT}/${OPTVALUE_Q##*/}.tmp ${GXQUERY}/tmpmsswork_${ACCOUNT}/${OPTVALUE_Q##*/}
  sed -i 's@^/\+$@@g' ${GXQUERY}/tmpmsswork_${ACCOUNT}/${OPTVALUE_Q##*/}
  sed -i '/^$/d' ${GXQUERY}/tmpmsswork_${ACCOUNT}/${OPTVALUE_Q##*/}

  # Run fcs-gx
  cd ${FCSHOME}
  python3 ./fcs.py screen genome --fasta ${GXQUERY}/tmpmsswork_${ACCOUNT}/${OPTVALUE_Q##*/} --out-dir ${GXOUTDIR} --gx-db "$GXDB_LOC/gxdb" --tax-id ${OPTVALUE_T}
  T=${OPTVALUE_Q##*/}
  echo "The result is saved as ${GXOUTDIR}/${T%.*}.${OPTVALUE_T}.*"
}

# Main
if [ ${OPTFLAG} = "NSUBnumber" ] && [ ${OPTVALUE_T} -gt 0 ]; then
  fcsgx1
elif [ ${OPTFLAG} = "Filepash" ] && [ ${OPTVALUE_T} -gt 0 ]; then
  fcsgx2
else
  echo "Taxonomy ID is wrong"
  echo ""
  showusage
fi
# Delete my query
find ${FCSHOME}/gx-query -type d -name "tmpmsswork_${ACCOUNT}" -or -name "tmpmsswork_${ACCOUNT}_*" | xargs rm -rf
