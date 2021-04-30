#!/bin/bash
# author: Irina Palaghia
# version: 2021-04-29, mod by DP 2021-04-30
# this script runs the bedpostX routines with GPU support for GTX3090
# for this purpose, FSL should be installed as described here:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation and additional drivers are required (cf. )


CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored hree

function_prepare_data()
{
	# cd $1 # necessary?!
    OUTPUT_DIR=$1/bedpostX # creates output folder 
    if [[ ! -d $OUTPUT_DIR ]];
    then
		mkdir -p $OUTPUT_DIR
		chmod -R 777 ${OUTPUT_DIR}
     fi

	cp $2/rawdata/ep2d_diff_rolled.bvals ${OUTPUT_DIR}
	cp $1/eddycorrected.eddy_rotated_bvecs ${OUTPUT_DIR}
	cp $1/eddycorrected.nii.gz ${OUTPUT_DIR}
	cp $1/bet_brain_mask.nii.gz ${OUTPUT_DIR}

	# renames all data according to the nomenclature needed  to run the script
	mv ${OUTPUT_DIR}/ep2d_diff_rolled.bvals ${OUTPUT_DIR}/bvals.txt
	mv ${OUTPUT_DIR}/eddycorrected.eddy_rotated_bvecs ${OUTPUT_DIR}/bvecs.txt
	mv ${OUTPUT_DIR}/eddycorrected.nii.gz ${OUTPUT_DIR}/data.nii.gz
	mv ${OUTPUT_DIR}/bet_brain_mask.nii.gz ${OUTPUT_DIR}/nodif_brain_mask.nii.gz
}

for WORKING_DIR in ${PWD}/preprocessed/*/; do # runs eddy for every preprocessed subject (cf. fsl_MergeSplit.sh and fsl_EddyCuda_noGPU.sh)
        echo 
        echo "======================================================================"
        echo
        echo "Running bedpostX with GPU support at $WORKING_DIR"
        echo
	function_prepare_data ${WORKING_DIR} ${CURRENT_DIR}
	# ${FSLDIR}/src/fdt/CUDA/bedpostx_gpu ${WORKING_DIR}/bedpostX/
	
done
echo "          ...done with bedpostX (FSL) for all subjects. Please perform visual checks"
echo
echo "================================================================"
