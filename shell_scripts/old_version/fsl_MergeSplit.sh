#!/bin/bash
# author: Irina Palaghia
# version: 2021-22-04, modified 2021-04-29 by DP
# this script results in merged iCTI sequences and split volumes. Therefore, multiple threads are used.
# for this purpose, FSL should be installed as described here:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation and folders MUST be adapted (FSLPATH)


export FSLPATH=/opt/FSL/
export PATH=${FSLPATH}:$PATH

CURRENT_DIR=${PWD}
OUTPUT_DIR=${PWD}/preprocessed
if [[ ! -d $OUTPUT_DIR ]]; # creates the (main) output folder
   then
    mkdir -p $OUTPUT_DIR
  fi

loop_function_merge()
{
	fslmerge -t $1/merged_raw_dti_data $2/*_j01.nii.gz $2/*_j02.nii.gz $2/*_j03.nii.gz $2/*_j04.nii.gz $2/*_j05.nii.gz $2/*_j06.nii.gz # merges all six acquisitoins
}

for WORKING_DIR in ${PWD}/rawdata/*/; do
	echo 
	echo "======================================================================"
	echo
	echo "Merging DTI sequences from  $WORKING_DIR"
	echo

        SUBJ_DIR=${OUTPUT_DIR}/$(basename $WORKING_DIR) # extracts pseudonyms
        if [[ ! -d $SUBJ_DIR ]];
          then
                mkdir -p $SUBJ_DIR
		chmod -R 777 ${SUBJ_DIR}
          fi

	cd ${WORKING_DIR}
	loop_function_merge ${SUBJ_DIR} ${WORKING_DIR} &

done
wait

echo "		...done merging for all subjects"
echo
echo "================================================================"


loop_function_split()
{
	fslsplit $1/merged_raw_dti_data.nii.gz 
}

cd ${CURRENT_DIR}
for WORKING_DIR in ${PWD}/rawdata/*/; do
     	echo
	echo "===================================================================="
	echo	
	echo "Splitting imaging at $WORKING_DIR"
	echo

        SUBJ_DIR=${OUTPUT_DIR}/$(basename $WORKING_DIR)
        if [[ ! -d $SUBJ_DIR ]];
          then
                mkdir -p $SUBJ_DIR
		chmod -R 777 ${SUBJ_DIR}        
          fi
	
	cd ${SUBJ_DIR}
        SPLIT_DIR=${SUBJ_DIR}/split_data/
        if [[ ! -d $SPLIT_DIR ]];
                then
                        mkdir -p ${SPLIT_DIR}
			chmod -R 777 ${SPLIT_DIR}
                fi

	loop_function_split ${SUBJ_DIR} &

done
wait

echo "		... merging and splitting done for all subjects"
echo
echo "==================================================================="


cd ${CURRENT_DIR}
for WORKING_DIR in ${PWD}/preprocessed/*/; do # move all slices to ./split_data folder
	SPLIT_DIR=${WORKING_DIR}/split_data/
	mv ${WORKING_DIR}/vol*.nii.gz  $SPLIT_DIR
done
