#!/bin/bash
# author: Irina Palaghia
# version: 2021-22-04, last modified 2021-06-13 by DP
# this script runs the eddy routing WITHOUT support for GPU due to conflict with GTX3090
# for this purpose, FSL should be installed as described here:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation and folders MUST be adapted (FSLPATH)


CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored hree

function_eddy()
{
cd $1

mask=$(find . -regextype egrep -regex '.*/(bet_brain)[a-z_].*(mask.nii.gz)$' -type f)

eddy_openmp \
	--imain=$1/merged_raw_dti_data.nii.gz \
	--mask=$1/$(basename $mask) \
	--acqp=$2/acqparams.txt \
	--index=$2/index.txt \
	--bvecs=$3/rawdata/ep2d_diff_rolled.bvecs \
	--bvals=$3/rawdata/ep2d_diff_rolled.bvals \
	--repol \
	--out=eddycorrected \
	--cnr_maps \
	--verbose > eddy_openmp_log.txt
}

num_processes=2
for WORKING_DIR in ${PWD}/preprocessed_kavi/*/; do # runs eddy for every preprocessed subject (cf. fsl_MergeSplit.sh)
	((i=i%num_processes)); ((i++==0)) && wait

	if [[ ! -f ${WORKING_DIR}/merged_raw_dti_data.nii.gz ]]; then
    		echo "File 'merged_raw_dti_data.nii.gz' does not exist. Copying it."
    		sudo cp ${PWD}/preprocessed/$(basename $WORKING_DIR)/merged_raw_dti_data.nii.gz ${PWD}/preprocessed_kavi/$(basename $WORKING_DIR)/merged_raw_dti_data.nii.gz	
	fi
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
