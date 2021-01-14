#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import glob
import ants
import getpass
import antspynet
import time
from utils.HelperFunctions import Configuration, Output, FileOperations, Imaging
from dependencies import FILEDIR, ROOTDIR



def get_preprocessed_image():
    patient_folder = os.path.join(FILEDIR, 'preprocessed')
    files = glob.glob(f"{patient_folder}/*")
    return files


OUTPUT_FOLDER = os.path.join(FILEDIR, 'seg_output')
PRIOR_TEMPLATE = os.path.join(ROOTDIR, 'data', 'template_finishedPriors', 'prior%02d.nii.gz')


def do_seg(image_path, antsxnet_cache_directory="ANTsXNet"):

    start_time = time.time()
    print("Starting...")
    # print(image_path)

    unique_id = image_path.split('_')[3]

    img = ants.image_read(image_path)

    # Load study specific template (SST) created from all subjects (cf. TemplateCreationParallel.py)
    sst = ants.image_read(os.path.join(ROOTDIR, FILEDIR, 'group_template.nii.gz'))

    if isinstance(sst, str):
        template_file_name_path = antspynet.get_antsxnet_data(sst, antsxnet_cache_directory=antsxnet_cache_directory)
        template_image = ants.image_read(template_file_name_path)
    else:
        template_image = sst

    template_probability_mask = antspynet.brain_extraction(template_image,
                                                           antsxnet_cache_directory=antsxnet_cache_directory,
                                                           verbose=True)
    template_mask = ants.threshold_image(template_probability_mask, 0.5, 1, 1, 0)
    if getpass.getuser() == 'david':
        template_mask = ants.image_clone(template_probability_mask)  # unnecessary except for david's machine
        template_mask = template_mask > .75

    mask = ants.get_mask(img)

    print("Loading images completed in %2.f seconds" % (time.time() - start_time))

    start_time = time.time()
    print("Starting segmentation...")

    segs = ants.atropos(a=img,
                        x=mask,
                        c='[2,0]',
                        m='[0.2, 1x1x1]',
                        i='kmeans[3]',
                        p=PRIOR_TEMPLATE)

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


