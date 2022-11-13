#!/bin/bash
# user to change
export ANTSPATH=~/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

DATA_DIR=${PWD}
MALF_DIR=${PWD}/MALF_templates/OASIS-TRT-20/
ANTS_CT_DIR=${PWD}/MALF_templates/regOASIS/
OUT_DIR=${DATA_DIR}/Output/
INPUT_TEMPLATE=${DATA_DIR}/template_finished/T_template0.nii.gz

# Before this script is run, templates should be downloaded and saved at the
# location of MALF_DIR and especially the atlases in the first subfolder (or
# adapt the MALF_DIR folder)

bash ${ANTSPATH}antsCorticalThickness.sh -d 3 \
  -a $INPUT_TEMPLATE \
  -e ${ANTS_CT_DIR}T_template-Oasis.nii.gz\
  -m ${ANTS_CT_DIR}TemplateOasis_BrainCerebellumMask.nii.gz \
  -p ${ANTS_CT_DIR}Priors/priors%d.nii.gz \
  -f ${ANTS_CT_DIR}TemplateOasis_BrainCerebellumExtractionMask.nii.gz \
  -o ${OUT_DIR}antsCT \
  -u 1

templateBrainMask=${OUT_DIR}antsCTBrainExtractionMask.nii.gz
templateBrain=${OUT_DIR}antsCTBrainExtractionBrain.nii.gz

${ANTSPATH}/ImageMath 3 $templateBrain m $templateBrainMask $INPUT_TEMPLATE

command="${ANTSPATH}/antsJointLabelFusion.sh -d 3 -k 0 -o ${OUT_DIR}/ants"
command="$command -t $templateBrain"
for i in `ls ${MALF_DIR}/*labels*`;
  do
    #brain=${i/Labels/BrainCerebellum}
    brain=${i/DKT31_CMA_labels_in/in} $l
    command="${command} -g $brain -l $i";
    #echo $command
done
$command

IMG=${PWD}/MALF_templates/MICCAI2012/training-images/
IMGLABELS=${PWD}/MALF_templates/MICCAI2012/training-labels/

# convert labels to 6 tissue (4 in 2-D)
#  1. csf
#  2. gm
#  3. wm
#  4. subcortical gm
#  5. brain stem
#  6. cerebellum

# Labels were converted according to the information provided in https://mindboggle.readthedocs.io/en/latest/labels.html

csfLabels=( 4 5 14 15 24 43 44  )
wmLabels=( 91 92 )
corticalLabels=( 1002 2002 )  # also anything >= 1002
subcorticalLabels=( 4 5 10 11 12 13 14 15 17 18 25 26 28 30 43 44 49 50 51 52 53 54 57 58 60 62 72 75 76 85 91 92 )
brainstemLabels=( 16 )
cerebellumLabels=( 6 7 45 46 630 631 632)

tmp=${OUT_DIR}/tmpForRelabeling.nii.gz
tmpWM=${OUT_DIR}/tmpForWhiteMatter.nii.gz
malf=${OUT_DIR}/antsLabels.nii.gz
malf6=${OUT_DIR}/ants6Labels.nii.gz

ThresholdImage 3 $malf $malf6 1002 2035 2 0

echo "csf: "
for(( j=0; j<${#csfLabels[@]}; j++ ));
  do
    echo ${csfLabels[$j]}
    ${ANTSPATH}/ThresholdImage 3 $malf $tmp ${csfLabels[$j]} ${csfLabels[$j]} 1 0
    ${ANTSPATH}/ImageMath 3 $malf6 + $tmp $malf6
  done

echo "cortex: "
for(( j=0; j<${#corticalLabels[@]}; j++ ));
  do
    echo ${corticalLabels[$j]}
    ${ANTSPATH}/ThresholdImage 3 $malf $tmp ${corticalLabels[$j]} ${corticalLabels[$j]} 2 0
    ${ANTSPATH}/ImageMath 3 $malf6 + $tmp $malf6
  done

echo "white matter: "
for(( j=0; j<${#wmLabels[@]}; j++ ));
  do
    echo ${wmLabels[$j]}
    ${ANTSPATH}/ThresholdImage 3 $malf $tmp ${wmLabels[$j]} ${wmLabels[$j]} 3 0
    ${ANTSPATH}/ImageMath 3 $malf6 + $tmp $malf6
  done

# No white matter labels provided, hence prior results from all '0' values in initial mask
${ANTSPATH}/ThresholdImage 3 $malf $tmpWM 0 0 1 0
ImageMath 3 $tmpWM m $templateBrainMask $tmpWM
${ANTSPATH}/ThresholdImage 3 $tmpWM $tmpWM 1 1 3 0
${ANTSPATH}/ImageMath 3 $malf6 + $tmpWM $malf6

echo "sub-cortex: "
for(( j=0; j<${#subcorticalLabels[@]}; j++ ));
  do
    echo ${subcorticalLabels[$j]}
    ${ANTSPATH}/ThresholdImage 3 $malf $tmp ${subcorticalLabels[$j]} ${subcorticalLabels[$j]} 4 0
    ${ANTSPATH}/ImageMath 3 $malf6 + $tmp $malf6
  done

echo "brain stem: "
for(( j=0; j<${#brainstemLabels[@]}; j++ ));
  do
    echo ${brainstemLabels[$j]}
    ${ANTSPATH}/ThresholdImage 3 $malf $tmp ${brainstemLabels[$j]} ${brainstemLabels[$j]} 5 0
    ${ANTSPATH}/ImageMath 3 $malf6 + $tmp $malf6
  done

echo "cerebellum: "
for(( j=0; j<${#cerebellumLabels[@]}; j++ ));
  do
    echo ${cerebellumLabels[$j]}
    ${ANTSPATH}/ThresholdImage 3 $malf $tmp ${cerebellumLabels[$j]} ${cerebellumLabels[$j]} 6 0
    ${ANTSPATH}/ImageMath 3 $malf6 + $tmp $malf6
  done

# now convert each to a probability map

antsCtCsfPrior=${OUT_DIR}/antsCTPrior1.nii.gz
${ANTSPATH}/SmoothImage 3 ${OUT_DIR}/antsCTBrainSegmentationPosteriors1.nii.gz 1 $antsCtCsfPrior

for(( j=1; j<=6; j++ ));
  do
    prior=${OUT_DIR}/prior${j}.nii.gz
    ${ANTSPATH}/ThresholdImage 3 $malf6 $prior $j $j 1 0
    ${ANTSPATH}/SmoothImage 3 $prior 1 $prior
  done

${ANTSPATH}/ImageMath 3 ${OUT_DIR}/prior1.nii.gz max ${OUT_DIR}/prior1.nii.gz $antsCtCsfPrior

# subtract out csf prior from all other priors

prior1=${OUT_DIR}/prior1.nii.gz
for(( j=2; j<=6; j++ ));
  do
    prior=${OUT_DIR}/prior${j}.nii.gz
    ${ANTSPATH}/ImageMath 3 $prior - $prior $prior1
    ${ANTSPATH}/ThresholdImage 3 $prior $tmp 0 1 1 0
    ${ANTSPATH}/ImageMath 3 $prior m $prior $tmp
  done

rm $tmp

echo "Priors are cooked.  They can be found in ${OUT_DIR}"
