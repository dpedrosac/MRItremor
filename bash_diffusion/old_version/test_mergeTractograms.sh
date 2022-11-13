#!/bin/bash
# author: David Pedrosa
# version: 2022-08-31
# script to merge all tractograms from the ROI

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh


echo "======================================================================"
echo
echo " Coregistering Segmentation to diffusion data ... "
echo

for_each -nthreads 20 ./rawdata/* : mrtransform \
	IN/T1.mif \
	IN/T1.nii.gz \
	-force

for_each -nthreads 20 ./rawdata/* : mrtransform \
	IN/5tt_coreg.mif \
	IN/5tt_coreg.nii.gz \
	-force

for_each -nthreads 20 ./freesurfer/* : flirt \
	-in ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.nii.gz \
	-ref ${CURRENT_DIR}/rawdata/NAME/T1.nii.gz \
	-interp nearestneighbour \
	-dof 6 -omat ${CURRENT_DIR}/rawdata/NAME/T12aparc+aseg.mat \

for_each -nthreads 20 ./freesurfer/* : transformconvert ${CURRENT_DIR}/rawdata/NAME/T12aparc+aseg.mat \
${CURRENT_DIR}/rawdata/NAME/5tt_coreg.nii.gz ${FSLDIR}/data/standard/T1.nii.gz flirt_import ${CURRENT_DIR}/rawdata/NAME/T12aparc+aseg.txt -force

for_each -nthreads 20 ./freesurfer/* : mrtransform \
${CURRENT_DIR}/rawdata/NAME/aparc+aseg.mgz \
-linear ${CURRENT_DIR}/rawdata/NAME/T12aparc+aseg.txt -inverse ${CURRENT_DIR}/rawdata/NAME/aparc+aseg_transformed.mgz -force

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Adding ROI (4x) to entire segmentation (resulting from 'recon-all'"
echo


echo " Adding ROI (1, VLp_Left) to complete segmentation "
echo

for_each -nthreads 20 ./freesurfer/* : fslmaths ${CURRENT_DIR}/freesurfer/NAME/mri/Left_VLp.nii.gz \
	-mul 10000 \
	${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_VLp.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_transformed.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_VLp.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10028 8129 -replace \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " Adding ROI (2, VLp_Right) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths -mul ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.nii.gz 100000 tmpRight_VLp.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_VLp.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10049 8229 -replace \
	mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz

echo " Adding ROI (3, Left_dentate) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths -mul ${CURRENT_DIR}/freesurfer/NAME/mri/Left_Dentate.nii.gz 100000 tmpLeft_Dentate.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_Dentate.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10047 10001 -replace \
	mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " Adding ROI (4, Right_dentate) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths -mul ${CURRENT_DIR}/freesurfer/NAME/mri/Right_Dentate.nii.gz 100000 tmpRight_Dentate.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_Dentate.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10047 10001 -replace \
	mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo
echo "Done!"
echo "======================================================================"
echo


echo " Converting labels so that MRTRIX works"
echo

for_each -nthreads 20 ./rawdata/* -test :labelconvert ${CURRENT_DIR}/rawdata/NAME/aparc+aseg_complete.mgz
	$FREESURFER_HOME/FreeSurferColorLUT.txt /opt/mrtrix3/share/labelconvert/fs_default.txt ${CURRENT_DIR}/rawdata/NAME/parcels.mif


echo
echo "Done!"
echo "======================================================================"
echo

