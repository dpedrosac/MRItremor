#!/bin/bash
# author: Irina Palaghia
# version: 2021-22-04, modified 2021-04-23 by DP
# this script extracts the brains of the subjects via the bet function of FSL after fsl_mergeandsplit.sh is finished
# for this purpose, FSL should be installed as described here:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation and folders MUST be adapted (FSLPATH)

export FSLPATH=/opt/FSL/
export PATH=${FSLPATH}:$PATH

CURRENT_DIR=${PWD}
OUTPUT_DIR=${PWD}/preprocessed

loop_function()
{
	cp $1/split_data/vol0000.nii.gz $1
	bet $1/vol0000.nii.gz $1/bet_brain -m -f .3
}

for WORKING_DIR in ${OUTPUT_DIR}/*/; do
	echo 
	echo "======================================================================"
	echo
	echo "Extracting the brain (FSL bet routine) at $WORKING_DIR"
	echo
	# echo $(basename $WORKING_DIR)
	SUBJ_DIR=${OUTPUT_DIR}/$(basename $WORKING_DIR)
	if [[ ! -d $SUBJ_DIR ]];
	  then
		mkdir -p $SUBJ_DIR 	  
	  fi
	loop_function $SUBJ_DIR &

done
wait

echo "	...done extracting brain for all subjects, please visually check"
echo " brains and adjust -f if necessary"
echo
echo "================================================================"
