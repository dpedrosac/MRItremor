
## FROM	: https://github.com/aaewarren/ESTEL-DBS/blob/b46b08efb1ecbd8a8780074b1861095d8b296a99/HCP_DBS_3.sh 
## AND	: https://neurobren.com/freesurfer-masks/

CURRENT_DIR=${PWD}
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

mri_label2vol --seg ThalamicNuclei.v12.T1.FSvoxelSpace.mgz --temp T1.mgz \
	--regheader ThalamicNuclei.v12.T1.FSvoxelSpace.mgz --o ThalamicNuclei.v12.T1-anat.mgz

# Thalamic preprocessing

while IFS=$'\t' read -r number name column3 ; do
	mri_binarize --i ${CURRENT_DIR}/freesurfer/4701P/mri/ThalamicNuclei.v12.T1-anat.mgz --o ${CURRENT_DIR}/freesurfer/4701P/mri/${name}.mgz --match "$number"
	mri_convert --in_type mgz --out_type nii ${name}.mgz ${name}.nii.gz
done < FreeSurferThalamus.txt

# Cerebellar preprocessing

antsRegistrationSyNQuick.sh -d 3 -f ${CURRENT_DIR}/freesurfer/4701P/mri/T1.mgz -m ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz -o transformationMNI_standard_ -n 8

antsApplyTransforms -d 3 -i ${CURRENT_DIR}/CerebellarAtlas/Diedrichsen_2009/atl-Anatom_space-MNI_dseg.nii -r ./transformationMNI_standard_Warped.nii.gz -t ./transformationMNI_standard_1Warp.nii.gz -t ./transformationMNI_standard_0GenericAffine.mat -o Warped_Cerebellum.nii

while IFS=$'\t' read -r number name color ; do
	# echo print $name
	mri_binarize --i ./Warped_Cerebellum.nii --o ${CURRENT_DIR}/freesurfer/4701P/mri/${name}.mgz --match "$number"
	mri_convert --in_type mgz --out_type nii ${name}.mgz ./freesurfer/4701P/mri/${name}.nii.gz
done < ./CerebellarAtlas/Diedrichsen_2009/atl-Anatom.tsv

# Run tckgen for cerebellar nuclei
tckgen -act ${CURRENT_DIR}/rawdata/4701P/5tt_coreg.mif -backtrack -seed_image ./freesurfer/4701P/mri/Left_Dentate.mgz -maxlength 250 -cutoff 0.06 -select 10000000 ${CURRENT_DIR}/rawdata/4701P/wmfod_norm.mif ${CURRENT_DIR}/rawdata/4701P/tracks_10M_Left_Dentate.tck -force

tckgen -act ${CURRENT_DIR}/rawdata/4701P/5tt_coreg.mif -backtrack -seed_image ./freesurfer/4701P/mri/Right_Dentate.mgz -maxlength 250 -cutoff 0.06 -select 10000000 ${CURRENT_DIR}/rawdata/4701P/wmfod_norm.mif ${CURRENT_DIR}/rawdata/4701P/tracks_10M_Right_Dentate.tck -force

# Run tckgen for thalamic nuclei
tckgen -act ${CURRENT_DIR}/rawdata/4701P/5tt_coreg.mif -backtrack -seed_image ./freesurfer/4701P/mri/Left_VLp.mgz -maxlength 250 -cutoff 0.06 -select 10000000 ${CURRENT_DIR}/rawdata/4701P/wmfod_norm.mif ${CURRENT_DIR}/rawdata/4701P/tracks_10M_Left_VLp.tck -force

tckgen -act ${CURRENT_DIR}/rawdata/4701P/5tt_coreg.mif -backtrack -seed_image ./freesurfer/4701P/mri/Right_VLp.mgz -maxlength 250 -cutoff 0.06 -select 10000000 ${CURRENT_DIR}/rawdata/4701P/wmfod_norm.mif ${CURRENT_DIR}/rawdata/4701P/tracks_10M_Right_VLp.tck -force


tckedit ${CURRENT_DIR}/rawdata/4701P/*.tck ${CURRENT_DIR}/rawdata/4701P/tracts_all_concat.tck

tcksift2 -act ${CURRENT_DIR}/rawdata/4701P/5tt_coreg.mif -out_mu ${CURRENT_DIR}/rawdata/4701P/sift2_mu.txt ${CURRENT_DIR}/rawdata/4701P/tracts_all_concat.tck ${CURRENT_DIR}/rawdata/4701P/wmfod_norm.mif ${CURRENT_DIR}/rawdata/4701P/sift_all.txt

tck2connectome ${CURRENT_DIR}/rawdata/4701P/tracts_all_concat.tck ${CURRENT_DIR}/rawdata/4701P/CONN_parcels.mif ${CURRENT_DIR}/rawdata/4701P/CONN_parcels.csv $PP_DIR/connectome_sift2_vta_${vta}.csv -tck_weights_in ${CURRENT_DIR}/rawdata/4701P/sift_all.txt -out_assignment ${CURRENT_DIR}/assignments_CONN_parcels.csv;
