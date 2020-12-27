#!/usr/bin/env python
# -*- coding: utf-8 -*-

import multiprocessing as mp
import os
import re
import time
import ants
import antspynet
import sys
import numpy as np

from utils.HelperFunctions import Imaging, FileOperations
from dependencies import ROOTDIR, FILEDIR, CONFIGDATA


class AntsPyX:
    """this class contains functions to extract the brain from different datasets"""

    def __init__(self):
        self.verbose = False
        pass

    def extract_list_of_patients(self, subjects):
        """Brain extraction using the routines from the ANTs environment  cf.
        https://github.com/ANTsX/ANTsPyNet/blob/master/antspynet/utilities/brain_extraction.py."""

        print('\nExtracting the brain of {} subject(s)'.format(len(subjects)))
        allfiles = FileOperations.get_filelist_as_tuple(f"{FILEDIR}", subjects, subdir='')
        strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'bc_', 'diff_', 'reg_']

        start_extraction = time.time()
        sequences = {'t1': '_MDEFT3D', 't2': '_t2_'}
        list_of_files = {k: [] for k in sequences.keys()}

        # print(allfiles)
        template_folder = os.path.join(ROOTDIR, 'data', 'template', 'icbm152')

        for seq, keyword in sequences.items():
            list_of_files[seq] = [x for x in allfiles if x[0].endswith('.gz') and
                                  any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                                os.path.basename(x[0]),
                                                re.IGNORECASE) for z in [keyword] * 3) and not
                                  any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                                os.path.basename(x[0]),
                                                re.IGNORECASE) for z in strings2exclude)]

        for file in list_of_files['t1']:
            output_folder = os.path.join(FILEDIR, file[1], 'output')
            FileOperations.create_folder(output_folder)

            print(f"creating mask for {file[0]}")
            filename2save = os.path.join(output_folder, 'brainmask_' + os.path.split(file[0])[1])
            modality = 't1combined' if seq == 't1' else 't2'

            template = os.path.join(template_folder, 'mni_icbm152_t1_tal_nlin_asym_09b_hires.nii')

            preprocess_imaged, mask = self.create_brainmask(file[0])
            self.skullstrip(image=preprocess_imaged, mask=mask,
                            output_file=os.path.join(output_folder, 'noskull_' + os.path.split(file[0])[1]))


            print("mask created... ok\n")
            return_dict = {'preprocessed_image': preprocessed_image}

        print('\nIn total, a list of {} file(s) was processed \nOverall, brain_extraction took '
              '{:.1f} secs.'.format(len(subjects), time.time() - start_extraction))

    @staticmethod
    def create_brainmask(registered_images, truncate_intensity=(.01, .99), verbose=True, antsxnet_cache_directory=None):
        """this function imports antspynet in order to obtain a probabilistic brain mask for the T1 imaging"""

        preprocessed_image = ants.image_clone(registered_images)
        if antsxnet_cache_directory is None:
            antsxnet_cache_directory = "ANTsXNet"

        # Truncate intensity
        if truncate_intensity is not None:
            quantiles = (preprocessed_image.quantile(truncate_intensity[0]),
                         preprocessed_image.quantile(truncate_intensity[1]))
            if verbose:
                print("Preprocessing: truncate intensities ( low =", quantiles[0], ", high =", quantiles[1], ").")

            preprocessed_image[preprocessed_image < quantiles[0]] = quantiles[0]
            preprocessed_image[preprocessed_image > quantiles[1]] = quantiles[1]

        # Brain extraction
        if verbose:
            print("Preprocessing:  brain extraction.")
        probability_mask = antspynet.brain_extraction(preprocessed_image,
                                                      antsxnet_cache_directory=antsxnet_cache_directory,
                                                      verbose=verbose)
        mask = ants.threshold_image(probability_mask, 0.5, 1, 1, 0)

        return preprocessed_image, mask