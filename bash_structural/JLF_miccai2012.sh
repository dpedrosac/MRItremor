

# !/bin/bash
# this script runs the antsJointLabelFusion.sh script in order to get a majority voting scheme for the regions defined in the multiple atlases
# to run the script,  MICCAI2012 data should be downloaded, ANTs be built from the source code, as described here:
# https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS and folders MUST be adapted (ANTSPATH, INPUT_DIR, OUTPUT_DIR, )

export ANTSPATH=~/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

CURRENT_DIR=${PWD}
MALF_DIR=${PWD}/atlases/
OUTPUT_DIR=${PWD}/JLF_results/

if [[ ! -d $OUTPUT_DIR ]];
  then
    echo "Output directory \"$OUTPUT_DIR\" does not exist. Creating it."
    mkdir -p $OUTPUT_DIR
  fi

echo "---------------------  Running Joint Label Fusion  ---------------------"

time_start=`date +%s`

TEMPLATE_BRAIN=${CURRENT_DIR}/template/SST_MRITremor_template.nii.gz
IMG=${PWD}/MALF_templates/MICCAI2012/training-images/
IMGLABELS=${PWD}/MALF_templates/MICCAI2012/training-labels/


${ANTSPATH}antsJointLabelFusion.sh -d 3  -k 0 \
 -c 2 -j 2 \
 -o ${OUTPUT_DIR}ants \
 -x or \
 -p ${OUTPUT_DIR}Posteriors%02d.nii.gz \
 -t $templateBrain \
 -g ${IMG}1000_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1000_3_glm.nii.gz \
 -g ${IMG}1001_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1001_3_glm.nii.gz \
 -g ${IMG}1002_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1002_3_glm.nii.gz \
 -g ${IMG}1006_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1006_3_glm.nii.gz \
 -g ${IMG}1007_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1007_3_glm.nii.gz \
 -g ${IMG}1008_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1008_3_glm.nii.gz \
 -g ${IMG}1009_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1009_3_glm.nii.gz \
 -g ${IMG}1010_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1010_3_glm.nii.gz \
 -g ${IMG}1011_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1011_3_glm.nii.gz \
 -g ${IMG}1012_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1012_3_glm.nii.gz \
 -g ${IMG}1013_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1013_3_glm.nii.gz \
 -g ${IMG}1014_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1014_3_glm.nii.gz \
 -g ${IMG}1015_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1015_3_glm.nii.gz \
 -g ${IMG}1017_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1017_3_glm.nii.gz \
 -g ${IMG}1036_3_BrainCerebellum.nii.gz -l ${IMGLABELS}1036_3_glm.nii.gz


time_end_jlfscript=`date +%s`
time_elapsed_jlf_script=$((time_end_jlfscript - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done with joint label fusion:  $(( time_elapsed_template_creation / 3600 ))h $(( time_elapsed_template_creation %3600 / 60 ))m $(( time_elapsed_template_creation % 60 ))s"
echo "--------------------------------------------------------------------------------------"
echo
