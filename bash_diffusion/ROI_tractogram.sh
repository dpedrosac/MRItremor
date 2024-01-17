#!/bin/bash
# author: David Pedrosa
# version: 2022-17-07, modified 2022-28-10
# script creating tracts for all subjects which may be used later to create the connectome using the MRITRIX3 routines
# cf.	https://github.com/aaewarren/ESTEL-DBS/blob/b46b08efb1ecbd8a8780074b1861095d8b296a99/HCP_DBS_3.sh AND
# cf.	https://neurobren.com/freesurfer-masks/

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ 						# all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer			# adding freesurfer routines
source $FREESURFER_HOME/SetUpFreeSurfer.sh		# setting up freesurfer

export ANTSPATH=/opt/ANTs/bin/					# adding ANTs routines
export PATH=${ANTSPATH}:$PATH


echo
echo "======================================================================"
echo " Obtaining tracts for all four cerebellar and thalamic regions within all subjects ... part 1 "
echo

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Left_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Left_VLp.tck

echo " Adding ROI (1, VLp_Left) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths ${CURRENT_DIR}/freesurfer/NAME/mri/Left_VLp.nii.gz -mul 10000 ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_VLp.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_VLp.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10010 8129 -replace \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " ... part 2 (Thalamus)"

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_VLp.tck

echo " Adding ROI (2, VLp_Right) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.nii.gz -mul 10000 ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_VLp.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_VLp.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10049 8229 -replace \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

# {3011S,4699S,4723S,4858S}
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
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_Dentate.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10007 10001 -replace \
	 ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " ... part 4 (Cerebellum) "

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_Dentate.tck

echo " Adding ROI (4, Right_dentate) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths ${CURRENT_DIR}/freesurfer/NAME/mri/Right_Dentate.nii.gz -mul 10000 ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_Dentate.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_Dentate.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10046 10002 -replace \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Concatenating all tracts for all subjects including steps from create_tractogram.sh... "
echo

for_each -nthreads 20 ./rawdata/* : tckedit ${CURRENT_DIR}/rawdata/NAME/*.tck /media/inthd1/MRItremor/rawdata/NAME/tracts_all_concat.tck

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Running tcksift2 for all subjects ... "
echo

for_each -nthreads 20 ./freesurfer/* : tcksift2 -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-out_mu ${CURRENT_DIR}/rawdata/NAME/sift2_mu.txt \
-out_coeffs ${CURRENT_DIR}/rawdata/NAME/sift_coeffs.txt \
/media/inthd1/MRItremor/rawdata/NAME/tracts_all_concat.tck ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif \
${CURRENT_DIR}/rawdata/NAME/sift_all.txt

echo
echo "Done!"
echo "======================================================================"
echo


echo
echo "======================================================================"
echo " Converting labels for all subjects ... "
echo

for_each -nthreads 40 ./rawdata/* : labelconvert ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/params/FreeSurferColorLUTMod.txt ${CURRENT_DIR}/params/fs_defaultMod.txt ${CURRENT_DIR}/rawdata/NAME/CON_parcels.mif -force

echo
echo "Done!"
echo "======================================================================"
echo


echo
echo "======================================================================"
echo " Creating connectome for all subjects ... "
echo

for_each -nthreads 10 ./freesurfer/* : tck2connectome /media/inthd1/MRItremor/rawdata/NAME/tracts_all_concat.tck \
${CURRENT_DIR}/rawdata/NAME/CON_parcels.mif \
${CURRANT_DIR}/rawdata/NAME/CON_parcels.csv \
-tck_weights_in ${CURRENT_DIR}/rawdata/NAME/sift_all.txt \
-symmetric \
-zero_diagonal \
-scale_invnodevol \
-out_assignment ${CURRENT_DIR}/rawdata/NAME/assignments_CON_parcels.csv

echo
echo "Done!"
echo "======================================================================"
echo
