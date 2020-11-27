#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import glob
import ants
import time
from utils.HelperFunctions import Configuration, Output, FileOperations, Imaging
from dependencies import FILEDIR, ROOTDIR


def get_registered_image(patient_id='4698P', type='t2'):
    patient_folder = os.path.join(ROOTDIR, FILEDIR, patient_id, 'output')
    file = glob.glob(f"{patient_folder}/wfi*{type}*")
    return file[0]


# TEST_PATIENT = '4698P'
TEST_PATIENT = '4701P'


start_time = time.time()
print("Starting...")

image_path = get_registered_image(patient_id=TEST_PATIENT)

img = ants.image_read(image_path)
mask = ants.get_mask(img)

print("Loading images completed in %2.f seconds" % (time.time() - start_time))

start_time = time.time()
print("Starting segmentation...")

segs = ants.atropos(a=img, x=mask, c='[2,0]', m='[0.2, 1x1x1]', i='kmeans[3]')

print("Segmentation done in", "%.2f seconds" % (time.time() - start_time))

output_folder = os.path.join(ROOTDIR, FILEDIR, TEST_PATIENT, 'seg_output')
ants.image_write(segs['segmentation'], f"{output_folder}/seg_atropos_{TEST_PATIENT}.nii")

start_time = time.time()
print("Starting cortical thickness calculation")

thickimg = ants.kelly_kapowski(s=segs['segmentation'],
                               g=segs['probabilityimages'][1],
                               w=segs['probabilityimages'][2],
                               its=45, r=0.5, m=1)

print("Calculation done in", "%.2f seconds" % (time.time() - start_time))

ants.image_write(thickimg, f"{output_folder}/seg_thickimg_{TEST_PATIENT}.nii")
