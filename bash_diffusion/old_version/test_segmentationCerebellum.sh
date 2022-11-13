#!/bin/bash
# author: David Pedrosa
# version: 2022-17-07, modified 2022-26-08
# test script preprocessing cerebellar ROIs before obtaining
# connectome using the MRITRIX3 routines
# cf.	https://github.com/aaewarren/ESTEL-DBS/blob/b46b08efb1ecbd8a8780074b1861095d8b296a99/HCP_DBS_3.sh AND
# cf.	https://neurobren.com/freesurfer-masks/

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

echo "======================================================================"
echo
echo " Coregistering Cerebellum to MNI ... "
echo

for_each -nthreads 20 ./freesurfer/* : flirt \
	-in ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.nii.gz \
	-ref ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz \
	-interp nearestneighbour \
	-dof 6 -omat ${CURRENT_DIR}/rawdata/NAME/MNI2diff.mat

for_each -nthreads 20 ./freesurfer/* : transformconvert ${CURRENT_DIR}/rawdata/NAME/MNI2diff.mat \
${CURRENT_DIR}/rawdata/NAME/wmfod_norm.nii.gz ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz flirt_import ${CURRENT_DIR}/rawdata/NAME/MNI2diff.txt -force

for_each -nthreads 20 ./freesurfer/* : mrtransform \
${CURRENT_DIR}/CerebellarAtlas/Diedrichsen_2009/atl-Anatom_space-MNI_dseg.nii \
-linear ${CURRENT_DIR}/rawdata/NAME/MNI2diff.txt -inverse ${CURRENT_DIR}/freesurfer/NAME/mri/Warped_Cerebellar_Atlas.nii.gz -force

echo "          ...done coregistering standard space (Cerebellum in FSL) to native space. Please perform visual checks!"
echo
echo "================================================================"

echo "======================================================================"
echo
echo " Copying data to 'freesurfer' folder within ... "
echo

for_each -nthreads 20 ./freesurfer/* : cp ${CURRENT_DIR}/rawdata/NAME/Warped_Cerebellar_Atlas.nii.gz ${CURRENT_DIR}/freesurfer/NAME/mri/Warped_Cerebellar_Atlas.nii.gz

#for_each -nthreads 20 ./freesurfer/* : mrtransform ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
#${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif.nii.gz

#for_each -nthreads 20 ./freesurfer/* : antsRegistrationSyNQuick.sh -d 3 \
#-f IN/mri/5tt_coreg.nii \
#-m ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz \
#-o IN/mri/transformationMNI2_native_ 
#for_each -nthreads 20 ./freesurfer/* : antsApplyTransforms \
#-d 3 \
#-i ${CURRENT_DIR}/CerebellarAtlas/Diedrichsen_2009/atl-Anatom_space-MNI_dseg.nii \
#-r IN/mri/transformationMNI2_native_Warped.nii.gz \
#-t IN/mri/transformationMNI2_native_1Warp.nii.gz \
#-t IN/mri/transformationMNI2_native_0GenericAffine.mat \
#-o IN/mri/Warped_Cerebellar_Atlas.nii

echo
echo "Done!"
echo "======================================================================"
echo

function_cerebellumextract() # function to extract all cerebellar cores from the Diedrichsen Atlas (2011), cf. FSL 
{
	while IFS=$'\t' read -r number name color ; do
		FILE=/$2/mri/${name}xx.nii.gz
		if ! [ -f "$FILE" ]; then
			echo "... subj: $2 already processed!"
			echo
			echo "======================================================================"
		else 
			mri_binarize \
			--i $2/mri/Warped_Cerebellar_Atlas.nii.gz \
			--o $2/mri/${name}.mgz \
			--match "$number"
			mri_convert \
			--in_type mgz \
			--out_type nii \
			$2/mri/${name}.mgz $2/mri/${name}.nii.gz
			echo "======================================================================"
		fi
	done < $1/CerebellarAtlas/Diedrichsen_2009/atl-Anatom.tsv
}

echo "======================================================================"
echo
echo " Extracting all cerebellar subnuclei/regions ... "
echo


num_processes=20
for WORKING_DIR in ${CURRENT_DIR}/freesurfer/*     # list directories
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Extracting cerebellar segmentation to single images (MRITRIX3) at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${WORKING_DIR##*/}"
	
	SUBJ = ${WORKING_DIR##*/}
	function_cerebellumextract ${CURRENT_DIR} ${WORKING_DIR} ${SUBJ} & 
done
wait

echo "          ...!"
echo
echo "================================================================"

