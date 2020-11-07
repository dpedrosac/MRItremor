#!/usr/bin/env python
# -*- coding: utf-8 -*-

import multiprocessing as mp
import os
import re
import time
import ants
import antspynet

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
        allfiles = FileOperations.get_filelist_as_tuple(FILEDIR, subjects)
        strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'bc_', 'diff_']
        output_folder = os.path.join(FILEDIR, 'output')
        FileOperations.create_folder(output_folder)

        start_extraction = time.time()
        sequences = {'t1': '_MDEFT3D', 't2': '_t2_'}
        list_of_files = {k: [] for k in sequences.keys()}

        print(list_of_files)

        for seq, keyword in sequences.items():
            list_of_files[seq] = [x for x in allfiles if x[0].endswith('.gz') and
                                  any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                                os.path.basename(x[0]),
                                                re.IGNORECASE) for z in [keyword] * 3) and not
                                  any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                                os.path.basename(x[0]),
                                                re.IGNORECASE) for z in strings2exclude)]

            for file in list_of_files[seq]:
                print(f"creating mask for {file[0]}")

                filename2save = os.path.join(output_folder, 'brainmask_' + os.path.split(file[0])[1])
                modality = 't1combined' if seq == 't1' else 't2'
                self.create_brainmask(file[0], filename2save=filename2save, modality=modality)

                print("mask created... ok\n")

        print('\nIn total, a list of {} file(s) was processed \nOverall, brain_extraction took '
              '{:.1f} secs.'.format(len(subjects), time.time() - start_extraction))

    def create_brainmask(self, registered_images, filename2save='brainmask_T1.nii', modality='t1combined'):
        """this function import antspynet in order to obtain a probabilistic brain mask for the T1 imaging"""
        ants_image = ants.image_read(registered_images)
        brainmask = antspynet.brain_extraction(image=ants_image, modality=modality, verbose=self.verbose)
        ants.image_write(image=brainmask, filename=filename2save)
