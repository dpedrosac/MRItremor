#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import subprocess
import ants
import antspynet
import getpass

from utils.HelperFunctions import FileOperations
from dependencies import ROOTDIR, FILEDIR

PRIOR_TEMPLATE = os.path.join(ROOTDIR, 'data', 'template_finishedPriors', 'prior%02d.nii.gz')


def preprocessed_subjects(folder):
    """Creates a list of subjects used to preprocess data according to the proposed pipeline in ANTsPyNet
    cf. https://github.com/ANTsX/ANTsPyNet/blob/master/antspynet/utilities/cortical_thickness.py"""

    print("\n{}\nFile Preparation:\t\textracting filenames.\n{}".format('=' * 85, '=' * 85))
    allfiles = FileOperations.list_files_in_folder(inputdir=folder, suffix='nii.gz')  # get a list of files from folder

    regexp = '(T_template0tANAT).(\d{4}\w).*(MDEFT3D[0-9]*WarpedToTemplate.nii.gz)'
    fileID = [re.search(regexp, x)[2] for x in allfiles]

    return allfiles, fileID


def create_mask(imaging, fileID, cleanup=2):
    """as threshold_image and therefore get_mask are not working, here is a function emulating the cleanup-option"""

    for idx, image in enumerate(imaging):
        filename_save = os.path.join(ROOTDIR, FILEDIR, 'preprocessed', 'mask' + fileID[idx] + '.nii.gz')
        if os.path.isfile(filename_save):
            mask = ants.get_mask(image, cleanup=cleanup)
            ants.image_write(mask, filename=filename_save)


def segmentationAtropos(imaging, template_sequence, fileID, c='[2,0]', m='[0.2, 1x1x1]', i='kmeans[6]',
                        prior='Socrates[0]', verbose=True):
    """ Pre-preprocessing steps applied according to the pipeline proposed for cortical thickness estimation"""

    # =================     General steps during processing     =================
    antsxnet_cache_directory = "ANTsXNet"
    preprocessed_folder = os.path.join(ROOTDIR, FILEDIR, 'preprocessed')
    output_folder = os.path.join(ROOTDIR, FILEDIR, 'seg_output')

    if not os.path.exists(output_folder):
        FileOperations.create_folder(f"{FILEDIR}" + 'registrationMatrices')

    # Load study specific template (SST) created from all subjects (cf. TemplateCreationParallel.py)
    sst = ants.image_read(template_sequence)

    if isinstance(sst, str):
        template_file_name_path = antspynet.get_antsxnet_data(sst, antsxnet_cache_directory=antsxnet_cache_directory)
        template_image = ants.image_read(template_file_name_path)
    else:
        template_image = sst

    template_probability_mask = antspynet.brain_extraction(template_image,
                                                           antsxnet_cache_directory=antsxnet_cache_directory,
                                                           verbose=verbose)
    template_mask = ants.threshold_image(template_probability_mask, 0.5, 1, 1, 0)
    if getpass.getuser() == 'david' or getpass.getuser() == 'dplab':
        template_mask = ants.image_clone(template_probability_mask)  # unnecessary except for david's machine
        template_mask = template_mask > .5
    template_brain_image = template_mask * template_image

    for idx, image in enumerate(imaging):
        print("\n{}\nProcessing image {} ( out of {} )\n{}".format('=' * 85, idx + 1, len(imaging), '=' * 85))

        # =================     Atropos segmentation wth given priors     =================
        image = ants.image_read(os.path.join(preprocessed_folder, image)) if isinstance(image, str) else image
        mask = ants.get_mask(image) # replace this part with ants.read_image

        mask = antspynet.brain_extraction(image,antsxnet_cache_directory=antsxnet_cache_directory, verbose=verbose)


        subprocess.check_call("~/ANTs/bin/ThresholdImage %d %s %s %s %d %d %d" % (3, os.path.join(preprocessed_folder, imaging[0]),
                                                                     'Thresh-test.nii.gz', str(.5), 1, 1, 0), shell=True)
        image_mask = ants.image_clone(mask)
        image_mask = image_mask > .5

        # template_brain_image = mask * image

        mask = ants.get_mask(image)
        if PRIOR_TEMPLATE:
            segs = ants.atropos(a=image, x=mask, c=c, m=m, i=i, p=prior)
        else:
            segs = ants.atropos(a=image, x=mask, c=c, m=m, i=i)

        filename2save = 'xxx' + '' + 'WarpedToTemplate.nii.gz'
        ants.image_write(segs, os.path.join(output_folder, filename2save))
