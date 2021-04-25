#!/bin/bash
# author: Irina Palaghia
# version: 2021-22-04, modified 2021-04-23 by DP
# this script extracts the brains of the subjects via the bet function of FSL
# for this purpose, FSL should be installed as described here:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation and folders MUST be adapted (FSLPATH)

FSLPATH=/opt/FSL/
export PATH=${FSLPATH}:$PATH

export FSLPATH=/opt/FSL/
export PATH=${FSLPATH}:$PATH

CURRENT_DIR=${PWD}

loop_function()
{
	cp $1/split_data/vol0000.nii.gz $1
	bet $1/vol0000.nii.gz $1/bet_brain -m -f .3
}

for WORKING_DIR in ${PWD}/rawdata/*/; do
	echo 
	echo "======================================================================"
	echo
	echo "Extracting the brain (FSL bet routine) at $WORKING_DIR"
	echo

	loop_function $WORKING_DIR &

done
wait

echo "	...done extracting brain for all subjects, please visually check"
echo " brains and adjust -f if necessary"
echo
echo "================================================================"
