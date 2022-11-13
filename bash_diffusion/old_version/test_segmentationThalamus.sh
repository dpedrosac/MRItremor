#!/bin/bash
# author: David Pedrosa
# version: 2022-17-07, modified 2022-26-08
# script preprocessing thalamic and cerebellar ROIs before obtaining
# connectome using the MRITRIX3 routines
# cf.	https://github.com/aaewarren/ESTEL-DBS/blob/b46b08efb1ecbd8a8780074b1861095d8b296a99/HCP_DBS_3.sh AND
# cf.	https://neurobren.com/freesurfer-masks/

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

echo
echo "======================================================================"
echo " Creating thalamic volumes for all subjects ... "
echo

for_each -nthreads 40 ./freesurfer/* : mrtransform IN/mri/ThalamicNuclei.v12.T1adapted.mif \
 	IN/mri/ThalamicNuclei.v12.T1adapted.nii.gz -force

for_each -nthreads 40 ./freesurfer/* : mri_label2vol \
	--seg IN/mri/ThalamicNuclei.v12.T1adapted.nii.gz \
	--temp IN/mri/T1.mgz \
	--regheader IN/mri/ThalamicNuclei.v12.T1adapted.nii.gz \
	--o IN/mri/ThalamicNuclei.v12.T1adapted-anat.nii.gz

echo
echo "Done!"
echo "======================================================================"
echo

function_thalamusextract() # function to merge all independent dwi sequences to one
{
	while IFS=$'\t' read -r number name column3 ; do
		mri_binarize --i $2/mri/ThalamicNuclei.v12.T1adapted-anat.nii.gz \
		--o $2/mri/${name}.mgz \
		--match "$number"
		mri_convert \
		--in_type mgz \
		--out_type nii \
		$2/mri/${name}.mgz $2/mri/${name}.nii.gz
		echo "======================================================================"
	done < $1/FreeSurferThalamus.txt
}

num_processes=20
for WORKING_DIR in ${CURRENT_DIR}/freesurfer/*     # list directories
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Extracting thalamic segmentation to single images (MRITRIX3) at multiple cores on" $WORKING_DIR
	echo
	echo "Processing subj: ${WORKING_DIR##*/}"

	function_thalamusextract ${CURRENT_DIR} ${WORKING_DIR} & 
done
wait
