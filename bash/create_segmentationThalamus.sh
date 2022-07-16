#!/bin/bash
# author: David Pedrosa
# version: 2022-17-07
# script preprocessing thalamic and cerebellar ROIs before obtaining
# connectome using the MRITRIX3 routines
# cf. https://github.com/aaewarren/ESTEL-DBS/blob/b46b08efb1ecbd8a8780074b1861095d8b296a99/HCP_DBS_3.sh AND
##		https://neurobren.com/freesurfer-masks/

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

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
echo " Creating thalamic volumes for all subjects ... "
echo

for_each -nthreads 40 ./freesurfer/* : mri_label2vol \
--seg IN/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz \
--temp IN/mri/T1.mgz \
--regheader IN/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz \
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
	echo "Running segmentation for thalamus (MRITRIX3) at multiple cores on" $WORKING_DIR
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

function_cerebellumextract() # function to merge all independent dwi sequences to one
{
	while IFS=$'\t' read -r number name color ; do
		mri_binarize \
		--i $2/mri/Warped_Cerebellar_Atlas.nii \
		--o $2/mri/${name}.mgz \
		--match "$number"
		mri_convert \
		--in_type mgz \
		--out_type nii \
		$2/mri/${name}.mgz $2/mri/${name}.nii.gz
		echo "======================================================================"
	done < $1/CerebellarAtlas/Diedrichsen_2009/atl-Anatom.tsv
}

num_processes=20
for WORKING_DIR in ${CURRENT_DIR}/freesurfer/*     # list directories
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running segmentation for cerebellum (MRITRIX3) at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${WORKING_DIR##*/}"

	function_cerebellumextract ${CURRENT_DIR} ${WORKING_DIR} & 
done
wait

echo
echo "======================================================================"
echo " Running thalamic segmentation for all subjects ... part 1 "
echo

for_each -nthreads 10 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Left_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 4 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Left_VLp.tck -force

echo " ... part 2 "

for_each -nthreads 10 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 4 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_VLp.tck -force

echo " ... part 3 (Cerebellum) "

for_each -nthreads 10 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Left_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 4 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Left_Dentate.tck -force

echo " ... part 4 (Cerebellum) "

for_each -nthreads 10 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 4 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_Dentate.tck -force

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Concatenating all Tracts for all subjects ... "
echo

for_each -t -nthreads 20 ./freesurfer/* : tckedit ${CURRENT_DIR}/rawdata/NAME/*.tck ${CURRENT_DIR}/rawdata/NAME/tracts_all_concat.tck

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Running tcksift2 for all subjects ... "
echo

for_each -t -nthreads 20 ./freesurfer/* : tcksift2 -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-out_mu ${CURRENT_DIR}/rawdata/NAME/sift2_mu.txt ${CURRENT_DIR}/rawdata/NAME/tracts_all_concat.tck ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif 
${CURRENT_DIR}/rawdata/NAME/sift_all.txt

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Creating connectome for all subjects ... "
echo

for_each -t -nthreads 20 ./freesurfer/* : tck2connectome ${CURRENT_DIR}/rawdata/NAME/tracts_all_concat.tck \
${CURRENT_DIR}/rawdata/NAME/CONN_parcels.mif \
${CURRENT_DIR}/rawdata/NAME/CONN_parcels.csv \
$PP_DIR/connectome_sift2_vta_${vta}.csv \
-tck_weights_in ${CURRENT_DIR}/rawdata/NAME/sift_all.txt \
-out_assignment ${CURRENT_DIR}/rawdata/NAME/assignments_CONN_parcels.csv;


echo
echo "Done!"
echo "======================================================================"
echo