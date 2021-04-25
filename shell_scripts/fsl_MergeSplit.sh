#!/bin/bash
# author: Irina Palaghia (slight modifications by DP)
# version: 2021-04-22, modified 2021-04-23 by DP
# this script merges and splits raw data and takes advantage of parallel processing 
# for this purpose, FSL should be installed as described here:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation and folders MUST be adapted (FSLPATH)

export FSLPATH=/opt/FSL/
export PATH=${FSLPATH}:$PATH

CURRENT_DIR=${PWD}

for WORKING_DIR in ${PWD}/rawdata/*/; do
	echo 
	echo "======================================================================"
	echo
	echo "Merging imaging at $WORKING_DIR"
	echo
	cd ${WORKING_DIR}
	fslmerge -t merged_raw_dti_data *_j01.nii.gz *_j02.nii.gz *_j03.nii.gz *_j04.nii.gz *_j05.nii.gz *_j06.nii.gz &

done
wait

echo "		...done merging for all subjects"
echo
echo "================================================================"

cd ${CURRENT_DIR}
for WORKING_DIR in ${PWD}/rawdata/*/; do
     	echo
	echo "===================================================================="
	echo	
	echo "Splitting imaging at $WORKING_DIR"
	echo
        cd ${WORKING_DIR}

        OUTPUT_DIR=${WORKING_DIR}/split_data/
        if [[ ! -d $OUTPUT_DIR ]];
                then
                        mkdir -p $OUTPUT_DIR
                fi

	mv ${WORKING_DIR}/merged_raw_dti_data.nii.gz ${OUTPUT_DIR}
	fslsplit ${OUTPUT_DIR}/merged_raw_dti_data.nii.gz &
done
wait

echo "		... merging and splitting done for all subjects"
echo
echo "==================================================================="

cd ${CURRENT_DIR}
for WORKING_DIR in ${PWD}/rawdata/*/; do
	OUTPUT_DIR=${WORKING_DIR}/split_data/
	mv ${WORKING_DIR}/vol*.nii.gz  $OUTPUT_DIR
done
