#!/bin/bash
# author: David Pedrosa
# version: 2022-19-10, $modification: added registration of DWI data to T1, revomed redundancy
# this script runs all the preprocessing steps for the MRTRIX3 pipeline
# cf. https://www.youtube.com/channel/UCh9KmApDY_z_Zom3x9xrEQw

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored hree

function_fslmerge() # function to merge all independent dwi sequences to one
{
	ls $1/*diff*.nii.gz
	echo "======================================================================"
	fslmerge -a $1/diff_complete.nii.gz  $1/*diff*.nii.gz							# merges all DWI sequences to one file
}

echo "================================================================"
echo "1. Concatenate images from nifti-output"
echo

num_processes=5
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running fslmerge at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${WORKING_DIR##*/}"
	# function_fslmerge ${WORKING_DIR} ${PARAMETER_DIR} ${CURRENT_DIR} & 
done
wait

echo "          ...done merging (FSL) for all subjects. Please perform visual checks"
echo
echo "================================================================"


echo "================================================================"
echo "2. Convert images to mif-format and add (bvecs/bvals) information"
echo

function_mrconvert() # function to merge all independent dwi sequences to one
{
	echo "======================================================================"
	mrconvert $1/diff_complete.nii.gz -fslgrad $3/params/ep2d_diff_rolled.bvecs $3/params/ep2d_diff_rolled.bvals $1/dwi_raw.mif # -force
}

num_processes=5
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running mrconvert (MRITRIX3) at multiple cores on $WORKING_DIR:" # subj: ${dir##*/}"
	echo

	FILE=/${WORKING_DIR}/dwi_raw.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_mrconvert ${WORKING_DIR} ${PARAMETER_DIR} ${CURRENT_DIR} & 
	fi
done
wait

echo "          ...done adding information from bval/bvec (MRITRIX) for all subjects"
echo
echo "================================================================"


echo "================================================================"
echo "3. Denoise and preprocess data"
echo

function_mrpreprocess() # function to merge all independent dwi sequences to one
{
	
	OUTPUT_DIR=$1/eddy_output/
	if [[ ! -d $OUTPUT_DIR ]];
	then
		mkdir -p $OUTPUT_DIR
	fi
	
	dwidenoise $1/dwi_raw.mif $1/dwi_den.mif # -force
	mrdegibbs $1/dwi_den.mif $1/dwi_den_unring.mif -axes 0,1 # -force
	dwifslpreproc $1/dwi_den_unring.mif $1/dwi_den_unring_eddycorr.mif -rpe_none -pe_dir AP -readout_time 0.0889 -force -eddyqc_all ${OUTPUT_DIR} -eddy_options " --slm=linear --repol  --acqp=$3/params/acqparams.txt --cnr_maps --fwhm=0" 
}

num_processes=2
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running dwifslpreproc (MRITRIX3) at two cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/dwi_den_unring_eddycorr.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_mrpreprocess ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi
done
wait

echo "          ...done denoising, 'deringing' and with eddy correction (MRITRIX/FSL) for all subjects"
echo
echo "================================================================"

# Sanity check for denoise (should be similar (identical?) to noise.mif):
FLAG_CHECK="FALSE"
SUBJ="3011S"
if [ "$FLAG_CHECK" = "TRUE" ]; then
	echo "Sanity check for residuals after denoise for subj:"
	dwidenoise ./rawdata/${SUBJ}/dwi_raw.mif ./rawdata/${SUBJ}/dwi_raw_den.mif
	mrcalc ./rawdata/${SUBJ}/dwi_raw.mif ./rawdata/${SUBJ}/dwi_raw_den.mif -subtract ./rawdata/${SUBJ}/residual.mif
	mrview ./rawdata/${SUBJ}/residual.mif
fi

echo "================================================================"
echo "4. Debias data"
echo

function_debias()
{
	dwibiascorrect ants $1/dwi_den_unring_eddycorr.mif $1/dwi_den_unring_eddycorr_unbiased.mif -bias $1/bias.mif # -force
}

num_processes=5
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running dwibiascorrect (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/dwi_den_unring_eddycorr_unbiased.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_debias ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

done
wait

echo "          ...done debiasting (MRITRIX/ANTs) for all subjects"
echo
echo "================================================================"


echo "================================================================"
echo "5. Create mask for DTI and anatomical data"
echo

function_mask()  # function to create a skull-stripped brain from the dwi data; somewhat a relict from prior versions wher coreg was performed later
{
	dwi2mask $1/dwi_den_unring_eddycorr_unbiased.mif $1/betmask.mif -force
}

function_mask2() # function to create a skull-stripped brain from the anatomy data
{
	bet $1/T1.nii.gz $1/betT1.nii.gz -f .1 -B
}


num_processes=40
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running dwi2mask (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/betmask.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_mask ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

	FILE=/${WORKING_DIR}/betT1.nii.gz
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_mask2 ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi
done
wait

echo "          ...masks created (MRITRIX/ANTs) for all subjects"
echo
echo "================================================================"


# sanity check for debias:
FLAG_CHECK="FALSE"
SUBJ="3011S"
if [ "$FLAG_CHECK" = "TRUE" ]; then
	echo "Sanity check for masks and debiasing results"
	mrview ./rawdata/${SUBJ}/dwi_den_unring_eddycorr_unbiased.mif -overlay.load ./rawdata/${SUBJ}/betmask.mif
fi

echo "================================================================"
echo "6. Coregisterin DWI to anatomical (T1.nii.gz) imaging"
echo

function_coregister() # function to merge all independent dwi sequences to one
{
	mrconvert $1/dwi_den_unring_eddycorr_unbiased.mif $1/dwi_den_unring_eddycorr_unbiased.nii.gz # -force
	dwiextract $1/dwi_den_unring_eddycorr_unbiased.mif - -bzero | mrmath - mean $1/mean_b0.mif -axis 3 # -force # extract b0 images
	mrconvert $1/mean_b0.mif $1/mean_b0.nii.gz
	epi_reg --epi=$1/mean_b0.nii.gz --t1=$1/T1.nii.gz --t1brain=$1/betT1.nii.gz --out=$1/dwi2T1
}

num_processes=10
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running epi_reg (FSL) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/dwi2T1.mat
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_coregister ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi
done
wait

echo "          ...masks created (MRITRIX/ANTs) for all subjects"
echo
echo "================================================================"


echo "================================================================"
echo "7. Apply co-registration and transform to mif-file " # https://www.fmrib.ox.ac.uk/primers/intro_primer/ExBox18/IntroBox18.html
echo

for_each -nthreads 10 ./rawdata/* : applywarp --in=IN/dwi_den_unring_eddycorr_unbiased.nii.gz --ref=IN/T1.nii.gz --premat=IN/dwi2T1.mat --interp=spline --out=IN/dwi_den_unring_eddycorr_unbiased_coreg.nii.gz
for_each -nthreads 10 ./rawdata/* : mrconvert IN/dwi_den_unring_eddycorr_unbiased_coreg.nii.gz IN/dwi_den_unring_eddycorr_unbiased_coreg.mif -fslgrad ./params/ep2d_diff_rolled.bvecs ./params/ep2d_diff_rolled.bvals -force

echo "          ...dwi was registered to (anat) T1 (FSL) for all subjects"
echo
echo "================================================================"


echo "================================================================"
echo "8. Create basis model"
echo

for_each -nthreads 10 ./rawdata/* : dwi2response dhollander IN/dwi_den_unring_eddycorr_unbiased_coreg.mif IN/wm.txt IN/gm.txt IN/csf.txt -voxels IN/voxels.mif -nocleanup -scratch IN/ -force

echo "          ...done with modeling (MRITRIX) for all subjects"
echo
echo "================================================================"

