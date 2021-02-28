# !/bin/bash
# this script runs the antsJointLabelFusion.sh script in order to get a majority voting scheme for the regions defined in the multiple atlases
# to run the script,  The THOMAS atlases for thalamic segmentations should be downloaded, ANTs be built from the source code, as described here:
# https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS and folders MUST be adapted (ANTSPATH, INPUT_DIR, OUTPUT_DIR, )

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

CURRENT_DIR=${PWD}
OUTPUT_DIR=${PWD}/stats_THOMAS/
DATA_DIR=${PWD}/SST/
JLF_DIR=${PWD}/JLF_thalamus_wnMPRAGE/

if [[ ! -d $OUTPUT_DIR ]];
  then
    echo "Output directory \"$OUTPUT_DIR\" does not exist. Creating it."
    mkdir -p $OUTPUT_DIR
  fi

echo "---------------------  Warping JLF results to template  and estimating stats---------------------"

TEMPLATE_BRAIN=${JLF_DIR}/ants_Labels.nii.gz
TMP_DIR=tmp$RANDOM
mkdir -p $TMP_DIR

for f in ~/Projects/MRItremor/SST/*Repaired*.nii.gz; 
	do psdnym=$(echo $f | egrep -o '([0-9]{4}(S|P))' | head -n1)
	echo "Processing subj:" $psdnym "..";
	REFERENCE=$(ls ${DATA_DIR}/*$psdnym*Repaired*)
	INVERSE=$(ls ${DATA_DIR}/*$psdnym*InverseWarp*)
	AFFINE=$(ls ${DATA_DIR}/*$psdnym*GenericAffine*)
	CSV_FILE=${OUTPUT_DIR}/$psdnym.csv

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
