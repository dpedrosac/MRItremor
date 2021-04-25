#!/bin/bash
# author: Irina Palaghia
# version: 2021-21-04, modified 2021-04-23 by DP
# this script runs the eddy routines for all subjects without taking advantage of the GPU in the workstation
# for this purpose, FSL should be installed as described here:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation and folders MUST be adapted (FSLPATH, PARAMETER_DIR)
# moreover a couple offiles are required (ep2d_diff_rolled.bvecs/bvals, index.txt, acqparams.txt)

FSLPATH=/opt/FSL/
export PATH=${FSLPATH}:$PATH

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored hree

function_eddy() # before running eddy, brain extraction (bet) and merging images is required
{
cd $1
eddy_openmp \
	--imain=$1/split_data/merged_raw_dti_data.nii.gz \
	--mask=$1/bet_brain_mask.nii.gz \
	--acqp=$2/acqparams.txt \
	--index=$2/index.txt \
	--bvecs=$3/rawdata/ep2d_diff_rolled.bvecs \
	--bvals=$3/rawdata/ep2d_diff_rolled.bvals \
	--repol --out=eddycorrected \
	--verbose > eddy_openmp_log.txt
}

num_processes=1
# folders=${PWD}/rawdata/*/
# for (( i=0; i<${#folders[@]} ; i+=2 )); 
for WORKING_DIR in ${PWD}/rawdata/*/; do
	((i=i%num_processes)); ((i++==0)) && wait
        echo 
        echo "======================================================================"
        echo
        echo "Running eddy without GPU support at $WORKING_DIR"
        echo
	function_eddy ${WORKING_DIR} ${PARAMETER_DIR} ${CURRENT_DIR} &

done
wait
echo "          ...done with eddy (FSL) for all subjects. Please perform visual checks"
echo
echo "================================================================"
