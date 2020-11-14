#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import re
import shutil
import time
from multiprocessing import Process, Pool
import ants

from utils.HelperFunctions import Imaging, FileOperations
from dependencies import ROOTDIR, FILEDIR, CONFIGDATA


class Registration:
    """this class contains all functions used to register Imaging to templates."""

    def __init__(self):
        self.verbose = False
        self.cfg = CONFIGDATA['preprocess']['Registration']  # loads configuration data from yaml-file
        pass

    def RegisterSeq(self, subjects, template_folder=os.path.join(ROOTDIR, 'data', 'template', 'icbm152')):

        print('\nRegistering imaging of {} subject(s) to template'.format(len(subjects)))
        allfiles = FileOperations.get_filelist_as_tuple(FILEDIR, subjects, subdir='output')
        strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'norm_', 'diff_']

        fileIDs = [x for x in allfiles if x[0].endswith('.gz') and not
        any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z), os.path.basename(x[0]),
                      re.IGNORECASE) for z in strings2exclude)]

        strings2exclude = ['bcorr', 'reg_run', 'tANAT', 'bc_', 'diff_']

        # file_id_DTI = [x for x in allfiles if x[0].endswith('.gz') and not
        # any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z), os.path.basename(x[0]),
        #              re.IGNORECASE) for z in strings2exclude)]  # DTI data not necessary for the time being!

        # ------------------------------    Start sequential routines  ------------------------------ #

        args = []

        for file2process, no_subj in fileIDs:
            # self.process_registration(file2process, no_subj, template_folder)
            args.append([file2process, no_subj, template_folder])

        pool = Pool(8)
        pool.map(self.process_registration, args)


    def process_registration(self, args):
        # file2process, no_subj, template_folder
        start_time = time.time()
        print("\tRegistering subj: {}".format(args[1]))

        filename_template = 'mni_icbm152_t1_tal_nlin_asym_09b_hires.nii' \
            if any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                             os.path.basename(args[0]), re.IGNORECASE) for z in ['_MDEFT3D'] * 3) else \
            'mni_icbm152_t2_tal_nlin_asym_09b_hires.nii'

        template_imaging = ants.image_read(os.path.join(args[2], filename_template))
        print("\n\tRegistering {} (f) to {} (m)".format(filename_template, os.path.basename(args[0])))
        output_folder = os.path.join(FILEDIR, args[1], 'output')
        FileOperations.create_folder(output_folder)
        filename_save = os.path.join(output_folder, self.cfg['prefix'] + os.path.basename(args[0]))

        if not os.path.isfile(filename_save):
            # Start with Registration to template image (fixed image)
            original_image = ants.image_read(args[0])
            registered_imaging = ants.registration(fixed=original_image, moving=template_imaging,
                                                   type_of_transform=self.cfg['registration_method'],
                                                   grad_step=.1, aff_metric=self.cfg['metric'],
                                                   initial_transform="[%s,%s,1]" % (args[0],
                                                                                    os.path.join(args[2],
                                                                                                 filename_template)),
                                                   verbose=self.verbose)
            ants.image_write(registered_imaging['warpedmovout'], filename=filename_save)
            ants.image_write(registered_imaging['warpedfixout'],
                             filename=os.path.join(output_folder, 'wfi_' + os.path.basename(args[0])))

            shutil.move(registered_imaging['fwdtransforms'][1], os.path.join(output_folder, '0GenericAffine.mat'))
            shutil.move(registered_imaging['invtransforms'][1], os.path.join(output_folder, 'invGenericAffine.mat'))

            print(f"Time taken for registration: {(time.time() - start_time):.2f}\n\n")


        else:
            print('\t ...already finished, skipped')
