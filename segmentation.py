#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import glob
import ants
from utils.HelperFunctions import Configuration, Output, FileOperations, Imaging
from dependencies import FILEDIR, ROOTDIR


def get_registered_image(patient_id='4698P', type='t2'):
    patient_folder = os.path.join(ROOTDIR, FILEDIR, patient_id, 'output')
    file = glob.glob(f"{patient_folder}/wfi*{type}*")
    return file[0]


TEST_PATIENT = '4698P'

image_path = get_registered_image(patient_id=TEST_PATIENT)

img = ants.image_read(image_path)
mask = ants.get_mask(img)

segs = ants.atropos(a=img, x=mask, c='[2,0]', m='[0.2, 1x1x1]', i='kmeans[3]')

output_folder = os.path.join(ROOTDIR, FILEDIR, TEST_PATIENT, 'seg_output')
ants.image_write(segs['segmentation'], f"{output_folder}/seg_{TEST_PATIENT}.nii")
