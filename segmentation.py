#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import glob
import ants
import time
from utils.HelperFunctions import Configuration, Output, FileOperations, Imaging
from dependencies import FILEDIR, ROOTDIR


def get_preprocessed_image():
    patient_folder = os.path.join(FILEDIR, 'preprocessed')
    files = glob.glob(f"{patient_folder}/*")
    return files


OUTPUT_FOLDER = os.path.join(FILEDIR, 'seg_output')


def do_seg(image_path):
    start_time = time.time()
    print("Starting...")
    # print(image_path)

    unique_id = image_path.split('_')[3]

    img = ants.image_read(image_path)
    mask = ants.get_mask(img)

    print("Loading images completed in %2.f seconds" % (time.time() - start_time))

    start_time = time.time()
    print("Starting segmentation...")

    segs = ants.atropos(a=img, x=mask, c='[2,0]', m='[0.2, 1x1x1]', i='kmeans[3]')

    print("Segmentation done in", "%.2f seconds" % (time.time() - start_time))

    output_folder = os.path.join(OUTPUT_FOLDER)
    ants.image_write(segs['segmentation'], f"{output_folder}/seg_atropos_{unique_id}.nii")

    start_time = time.time()
    print("Starting cortical thickness calculation")

    thickimg = ants.kelly_kapowski(s=segs['segmentation'],
                                   g=segs['probabilityimages'][1],
                                   w=segs['probabilityimages'][2],
                                   its=45, r=0.5, m=1)

    print("Calculation done in", "%.2f seconds" % (time.time() - start_time))

    ants.image_write(thickimg, f"{output_folder}/seg_thickimg_{unique_id}.nii")


for image in get_preprocessed_image():
    do_seg(image)
