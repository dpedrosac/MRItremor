#!/bin/bash
# author: David Pedrosa
# version: 2022-17-07, modified 2022-22-10
# script preprocessing thalamic and cerebellar ROIs before obtaining connectome using the MRITRIX3 routines
# cf.	https://github.com/aaewarren/ESTEL-DBS/blob/b46b08efb1ecbd8a8780074b1861095d8b296a99/HCP_DBS_3.sh AND
# cf.	https://neurobren.com/freesurfer-masks/

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ 						# all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer			# adding freesurfer routines
source $FREESURFER_HOME/SetUpFreeSurfer.sh		# setting up freesurfer

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

echo
echo "======================================================================"
echo " Running thalamic segmentation for all subjects ... "
echo

for_each -t -nthreads 40 ./freesurfer/* : segmentThalamicNuclei.sh IN

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Aligning thalamic segmentation to DTI data... "
echo

for_each -nthreads 20 ./freesurfer/* : mrtransform ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif \
${CURRENT_DIR}/rawdata/NAME/wmfod_norm.nii.gz -reorient_fod no

for_each -nthreads 20 ./freesurfer/* : flirt -in ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.nii.gz \
	-ref ${CURRENT_DIR}/rawdata/NAME/5tt_vol0.nii.gz \
	-interp nearestneighbour \
	-dof 6 \
	-omat ${CURRENT_DIR}/rawdata/NAME/thalamus2diff.mat

for_each -nthreads 20 ./freesurfer/* : transformconvert ${CURRENT_DIR}/rawdata/NAME/thalamus2diff.mat \
	${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif \
	${CURRENT_DIR}/rawdata/NAME/5tt_vol0.nii.gz flirt_import ${CURRENT_DIR}/rawdata/NAME/thalamus2diff.txt 
	-force

for_each -nthreads 20 ./freesurfer/* : mrtransform ${CURRENT_DIR}/freesurfer/NAME/mri/ThalamicNuclei.v12.T1.mgz \
	-linear ${CURRENT_DIR}/rawdata/NAME/thalamus2diff.txt \
	-inverse ${CURRENT_DIR}/freesurfer/NAME/mri/ThalamicNuclei.v12.T1adapted.mif 
	-force

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Creating thalamic volumes for all subjects ... "
echo

for_each -nthreads 40 ./freesurfer/* : mri_label2vol \
	--seg IN/mri/ThalamicNuclei.v12.T1.mgz \
	--temp IN/mri/T1.mgz \
	--regheader IN/mri/ThalamicNuclei.v12.T1.mgz \
	--o IN/mri/ThalamicNuclei.v12.T1-anat.mgz

echo
echo "Done!"
echo "======================================================================"
echo

function_thalamusextract() # function to merge all independent dwi sequences to one
{
	while IFS=$'\t' read -r number name column3 ; do
		mri_binarize --i $2/mri/ThalamicNuclei.v12.T1-anat.mgz \
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

echo "======================================================================"
echo
echo " Coregistering Cerebellum to MNI ... "
echo

for_each -nthreads 20 ./freesurfer/* : antsRegistrationSyNQuick.sh -d 3 \
-f IN/mri/T1.mgz \
-m ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz \
-o IN/mri/transformationMNI2_native_ 
for_each -nthreads 20 ./freesurfer/* : antsApplyTransforms \
-d 3 \
-i ${CURRENT_DIR}/CerebellarAtlas/Diedrichsen_2009/atl-Anatom_space-MNI_dseg.nii \
-r IN/mri/transformationMNI2_native_Warped.nii.gz \
-t IN/mri/transformationMNI2_native_1Warp.nii.gz \
-t IN/mri/transformationMNI2_native_0GenericAffine.mat \
-o IN/mri/Warped_Cerebellar_Atlas.nii

echo
echo "Done!"
echo "======================================================================"
echo

function_cerebellumextract() # function to extract all cerebellar cores from the Diedrichsen Atlas (2011), cf. FSL 
{
	while IFS=$'\t' read -r number name color ; do
		FILE=/$2/mri/${name}.nii.gz
		if [ -f "$FILE" ]; then
			echo "... subj: $2 already processed!"
			echo
			echo "======================================================================"
		else 
			mri_binarize \
			--i $2/mri/Warped_Cerebellar_Atlas.nii \
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

num_processes=20
for WORKING_DIR in ${CURRENT_DIR}/freesurfer/*     # list directories
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Extracting cerebellar segmentation to single images (MRITRIX3) at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${WORKING_DIR##*/}"

	function_cerebellumextract ${CURRENT_DIR} ${WORKING_DIR} & 
done
wait

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
for_each -nthreads 20 ./freesurfer/* : fslmaths -mul ${CURRENT_DIR}/freesurfer/NAME/mri/Left_VLp.nii.gz 100000 tmpLeft_VLp.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_VLp.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10010 8129 -replace \
	mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " ... part 2 (Thalamus)"

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_VLp.tck

echo " Adding ROI (2, VLp_Right) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths -mul ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.nii.gz 100000 tmpRight_VLp.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_VLp.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10049 8229 -replace \
	mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " ... part 3 (Cerebellum) "

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Left_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Left_Dentate.tck

echo " Adding ROI (3, Left_dentate) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths -mul ${CURRENT_DIR}/freesurfer/NAME/mri/Left_Dentate.nii.gz.nii.gz 100000 tmpLeft_Dentate.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpLeft_Dentate.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10047 10001 -replace \
	mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo " ... part 4 (Cerebellum) "

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_Dentate.tck

echo " Adding ROI (4, Right_dentate) to complete segmentation "
echo
for_each -nthreads 20 ./freesurfer/* : fslmaths -mul ${CURRENT_DIR}/freesurfer/NAME/mri/Right_Dentate.nii.gz.nii.gz 100000 tmpRight_Dentate.nii.gz
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz ${CURRENT_DIR}/freesurfer/NAME/mri/tmpRight_Dentate.nii.gz -add \
	${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force
for_each -nthreads 20 ./freesurfer/* : mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz 10047 10001 -replace \
	mrcalc ${CURRENT_DIR}/freesurfer/NAME/mri/aparc+aseg_complete.mgz -force

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Concatenating all Tracts for all subjects ... "
echo

# for_each -t -nthreads 20 ./rawdata/* : tckedit ${CURRENT_DIR}/rawdata/NAME/*.tck ${CURRENT_DIR}/rawdata/NAME/tracts_all_concat.tck

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Running tcksift2 for all subjects ... "
echo

#for_each -t -nthreads 10 ./freesurfer/* : tcksift2 -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
#-out_mu ${CURRENT_DIR}/rawdata/NAME/sift2_mu.txt \
#-out_coeffs ${CURRENT_DIR}/rawdata/NAME/sift_coeffs.txt \
#-nthreads 4 \
#${CURRENT_DIR}/rawdata/NAME/tracts_all_concat.tck ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif \
#${CURRENT_DIR}/rawdata/NAME/sift_all.txt

echo
echo "Done!"
echo "======================================================================"
echo


echo
echo "======================================================================"
echo " Creating connectome for all subjects ... "
echo

#for_each -t -nthreads 10 ./freesurfer/* : tck2connectome \${CURRENT_DIR}/rawdata/NAME/tracts_all_concat.tck \
#-tck_weights_in ${CURRENT_DIR}/rawdata/NAME/CONN_parcels.mif \
#${CURRENT_DIR}/rawdata/NAME/CONN_parcels.csv \
#$PP_DIR/connectome_sift2_vta_${vta}.csv \
#-symmetric \
#-zero_diagonal \
#-scale_invnodevol \
#-nthreads 4 \
#-tck_weights_in ${CURRENT_DIR}/rawdata/NAME/sift_all.txt \
#-out_assignment ${CURRENT_DIR}/rawdata/NAME/assignments_CONN_parcels.csv;


#tck2connectome -symmetric -zero_diagonal -scale_invnodevol -tck_weights_in sift_1M.txt tracks_10M.tck sub-CON02_parcels.mif sub-CON02_parcels.csv -out_assignment assignments_sub-CON02_parcels.csv


echo
echo "Done!"
echo "======================================================================"
echo
