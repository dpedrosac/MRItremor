#!/bin/bash
# author: David Pedrosa
# version: 2022-18-08
# test script to append preprocessed ROIs

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH


echo
echo "======================================================================"
echo " Obtaining tracts for all four cebellar and thalamic regions within all subjects ... part 1 "
echo

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Left_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Left_VLp.tck -force

echo " Adding ROI (1, VLp_Left) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths ${CURRENT_DIR}/freesurfer/NAME/mri/Left_VLp.nii.gz -mul 10000 ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_VLp.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_VLp.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10010 8129 -replace ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " ... part 2 (Thalamus)"

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_VLp.tck -force

echo " Adding ROI (2, VLp_Right) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.nii.gz -mul 10000 ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_VLp.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_VLp.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10049 8229 -replace ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " ... part 3 (Cerebellum) "

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Left_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Left_Dentate.tck

echo " Adding ROI (3, Left_dentate) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths ${CURRENT_DIR}/freesurfer/NAME/mri/Left_Dentate.nii.gz -mul 10000 ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_Dentate.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_Dentate.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10008 10001 -replace ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " ... part 4 (Cerebellum) "

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_Dentate.tck

echo " Adding ROI (4, Right_dentate) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths ${CURRENT_DIR}/freesurfer/NAME/mri/Right_dentate.nii.gz -mul 10000 ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_dentate.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_dentate.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10047 10002 -replace ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo
echo "Done!"
echo "======================================================================"
echo
