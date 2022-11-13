
# !/bin/bash
# this script runs the antsJointLabelFusion.sh script in order to get a majority voting scheme for the regions defined in the multiple atlases
# to run the script,  The THOMAS atlases for thalamic segmentations should be downloaded, ANTs be built from the source code, as described here:
# https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS and folders MUST be adapted (ANTSPATH, INPUT_DIR, OUTPUT_DIR, )

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

export FSLPATH=~/usr/local/fsl/
export PATH=${FSLPATH}:$PATH

CURRENT_DIR=${PWD}
DATA_DIR=${PWD}/SST/

OUTPUT_DIR=${PWD}/stats_THOMAS/
if [[ ! -d $OUTPUT_DIR ]];
  then
    echo "Output directory \"$OUTPUT_DIR\" does not exist. Creating it."
    mkdir -p $OUTPUT_DIR
  fi

echo "---------------------  Warping JLF results to template  and estimating stats---------------------"

TMP_DIR=tmp$RANDOM
mkdir -p $TMP_DIR

time_start='date +%s'

side=(right left)
for i in "${side[@]}"; do 
echo "---------------------  Copying and flipping images for "$i" side   ---------------------"	
	if [ "$i" == "right" ] ; then
	JLF_DIR=${PWD}/JLF_thalamus_wnMPRAGE_right//
	SUFFIX="_R"
	
	else
	JLF_DIR=${PWD}/JLF_thalamus_wnMPRAGE/
	SUFFIX="_L"
	
	fi;
	
TEMPLATE_BRAIN=${JLF_DIR}/ants_Labels.nii.gz
for f in ~/Projects/MRItremor/SST/*Repaired*.nii.gz; 
	do psdnym=$(echo $f | egrep -o '([0-9]{4}(S|P))' | head -n1)
	echo "Processing subj:" $psdnym "..";
	filename=$psdnym.csv
	CSV_FILE=${OUTPUT_DIR}/${filename%.csv}$SUFFIX.csv


	REFERENCE=$(ls ${DATA_DIR}/*$psdnym*Repaired*)
	INVERSE=$(ls ${DATA_DIR}/*$psdnym*InverseWarp*)
	AFFINE=$(ls ${DATA_DIR}/*$psdnym*GenericAffine*)

	${ANTSPATH}antsApplyTransforms -d 3 \
	-i $TEMPLATE_BRAIN  \
	-r $REFERENCE \
	-o ${TMP_DIR}/tmpWarped.nii.gz \
	-t $INVERSE \
	-t [$AFFINE, 1] \
	-n GenericLabel \
	-v 1
	
	${ANTSPATH}LabelGeometryMeasures 3 ${TMP_DIR}/tmpWarped.nii.gz > $CSV_FILE
done

done
rm -rf ${TMP_DIR}
time_end_jlfscript='date +%s'
time_elapsed_jlf_script=$((time_end_jlfscript - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done with label stats estimation for both sides:  $(( time_elapsed_template_creation / 3600 ))h $(( time_elapsed_template_creation %3600 / 60 ))m $(( time_elapsed_template_creation % 60 ))s"
echo "--------------------------------------------------------------------------------------"
echo
