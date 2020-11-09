#!/usr/bin/env python
# -*- coding: utf-8 -*-

import multiprocessing as mp
import os
import re
import time
import ants

from utils.HelperFunctions import Imaging, FileOperations
from dependencies import ROOTDIR, FILEDIR, CONFIGDATA
from ants.utils import n4_bias_field_correction as n4biascorr


class Correction:
    """this class contains all functions used by the ANTsPy Toolbox; in general the multiprocessing routines are
    implemented aiming at making the code as efficient and quick as possible."""

    def __init__(self):
        self.verbose = False
        self.cfg = CONFIGDATA['preprocess']['ANTsN4']  # loads configuration data from yaml-file
        pass

    def N4BiasMult(self, subjects):
        """N4BiasCorrection according to N.J. Tustison, ..., and J.C. Gee.
        "N4ITK: Improved N3 Bias Correction" IEEE Transactions on Medical Imaging, 29(6):1310-1320, June 2010."""

        print('\nDebiasing imaging of {} subject(s)'.format(len(subjects)))
        allfiles = FileOperations.get_filelist_as_tuple(FILEDIR, subjects)
        strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'bc_', 'diff_']

        fileIDs = [x for x in allfiles if x[0].endswith('.gz') and not
        any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z), os.path.basename(x[0]),
                      re.IGNORECASE) for z in strings2exclude)]

        strings2exclude = ['bcorr', 'reg_run', 'tANAT', 'bc_', 'diff_']

        file_id_DTI = [x for x in allfiles if x[0].endswith('.gz') and not
        any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z), os.path.basename(x[0]),
                      re.IGNORECASE) for z in strings2exclude)]  # DTI data not necessary for the time being!

        # ------------------------------    Start multiprocessing routines  ------------------------------ #
        start_multi = time.time()
        status = mp.Queue()
        processes = [mp.Process(target=self.N4BiasCorrection_multiprocessing,
                                args=(name_file, no_subj, os.path.join(FILEDIR, no_subj), status))
                     for name_file, no_subj in fileIDs]

        for p in processes:
            p.start()

        while any([p.is_alive() for p in processes]):
            while not status.empty():
                process, no_subj, filename = status.get()
                print("{}; \tDebiasing subj: {}, filename: {}".format(process, no_subj, filename))
            time.sleep(0.25)

        for p in processes:
            p.join()

        print('\nIn total, a list of {} subject(s) was processed \nOverall, bias correction took '
              '{:.1f} secs.'.format(len(subjects), time.time() - start_multi))

    def N4BiasCorrection_multiprocessing(self, file2rename, subj, input_folder, status):
        """Performs Bias correction taking advantage of multicores, so that multiple subjects can be processed in
        parallel; For that a list of tuples including the entire filename and the subject to be processed are entered"""

        status.put(tuple([mp.current_process().name, subj, os.path.basename(file2rename)]))
        output_folder = os.path.join(FILEDIR, subj, 'output')
        FileOperations.create_folder(output_folder)
        filename_save = os.path.join(output_folder, self.cfg['prefix'] + os.path.basename(file2rename))

        if not os.path.isfile(filename_save):
            # Start with N4 Bias correction for sequences specified before
            original_image = ants.image_read(file2rename)
            rescaler_nonneg = ants.contrib.RescaleIntensity(10, 100)  # to avoid values <0 causing problems w/ log data
            if self.cfg['denoise'] == 'yes':  # takes forever and therefore not used by default
                original_image = ants.denoise_image(image=original_image, noise_model='Rician')

            min_orig, max_orig = original_image.min(), original_image.max()
            if not os.path.basename(file2rename).startswith('ep2d'):  # this must be changed if DWI is used
                original_image_nonneg = rescaler_nonneg.transform(original_image)
            else:
                original_image_nonneg = original_image

            bcorr_image = n4biascorr(original_image_nonneg, mask=None,
                                     shrink_factor=self.cfg['shrink-factor'],
                                     convergence={'iters': self.cfg['convergence'],
                                                  'tol': self.cfg['threshold']},
                                     spline_param=self.cfg['bspline-fitting'],
                                     verbose=True)

            if not os.path.basename(file2rename).startswith('ep2d'): # this must be changed if DWI is used
                rescaler = ants.contrib.RescaleIntensity(min_orig, max_orig)
                bcorr_image = rescaler.transform(bcorr_image)

            # difference between both images is saved for debugging purposes
            diff_image = original_image - bcorr_image
            FileOperations.create_folder(os.path.join(input_folder, 'debug'))  # only creates folder if not present
            ants.image_write(diff_image, filename=os.path.join(input_folder, 'debug', 'diff_biasCorr_' +
                                                               os.path.basename(file2rename)))

            spacing = 1 # Converts the spacing to 1mm if necessary
            bcorr_image = Imaging.resampleANTsImaging(mm_spacing=spacing, ANTsImageObject=bcorr_image,
                                                      file_id=filename_save, method=1)
            ants.image_write(bcorr_image, filename=filename_save)
        else:
            status.put(tuple([mp.current_process().name, subj, os.path.basename(file2rename) +
                              '\t ...already finished, skipped']))

    def N4BiasSeq(self, subjects):
        """N4BiasCorrection according to N.J. Tustison, ..., and J.C. Gee.
        "N4ITK: Improved N3 Bias Correction" IEEE Transactions on Medical Imaging, 29(6):1310-1320, June 2010."""

        print('\nDebiasing imaging of {} subject(s)'.format(len(subjects)))
        allfiles = FileOperations.get_filelist_as_tuple(FILEDIR, subjects)
        strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'bc_', 'diff_']

        fileIDs = [x for x in allfiles if x[0].endswith('.gz') and not
        any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z), os.path.basename(x[0]),
                      re.IGNORECASE) for z in strings2exclude)]

        strings2exclude = ['bcorr', 'reg_run', 'tANAT', 'bc_', 'diff_']

        file_id_DTI = [x for x in allfiles if x[0].endswith('.gz') and not
        any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z), os.path.basename(x[0]),
                      re.IGNORECASE) for z in strings2exclude)]  # DTI data not necessary for the time being!

        # ------------------------------    Start sequential routines  ------------------------------ #
        start_multi = time.time()
        for file2rename, no_subj in fileIDs:
            print("\tDebiasing subj: {}, filename: {}".format(no_subj, file2rename))
            input_folder = os.path.join(FILEDIR, no_subj)
            output_folder = os.path.join(FILEDIR, no_subj, 'output')
            FileOperations.create_folder(output_folder)
            filename_save = os.path.join(output_folder, self.cfg['prefix'] + os.path.basename(file2rename))

            if not os.path.isfile(filename_save):
                # Start with N4 Bias correction for sequences specified before
                original_image = ants.image_read(file2rename)
                rescaler_nonneg = ants.contrib.RescaleIntensity(10,100)  # to avoid values <0 causing problems w/ log data
                if self.cfg['denoise'] == 'yes':  # takes forever and therefore not used by default
                    original_image = ants.denoise_image(image=original_image, noise_model='Rician')

                min_orig, max_orig = original_image.min(), original_image.max()
                if not os.path.basename(file2rename).startswith('ep2d'):  # this must be changed if DWI is used
                    original_image_nonneg = rescaler_nonneg.transform(original_image)
                else:
                    original_image_nonneg = original_image

                bcorr_image = n4biascorr(original_image_nonneg, mask=None,
                                         shrink_factor=self.cfg['shrink-factor'],
                                         convergence={'iters': self.cfg['convergence'],
                                                      'tol': self.cfg['threshold']},
                                         spline_param=self.cfg['bspline-fitting'],
                                         verbose=True)

                if not os.path.basename(file2rename).startswith('ep2d'):  # this must be changed if DWI is used
                    rescaler = ants.contrib.RescaleIntensity(min_orig, max_orig)
                    bcorr_image = rescaler.transform(bcorr_image)

                # difference between both images is saved for debugging purposes
                diff_image = original_image - bcorr_image
                FileOperations.create_folder(os.path.join(input_folder, 'debug'))  # only creates folder if not present
                ants.image_write(diff_image, filename=os.path.join(input_folder, 'debug', 'diff_biasCorr_' +
                                                                   os.path.basename(file2rename)))

                spacing = 1  # Converts the spacing to 1mm if necessary
                bcorr_image = Imaging.resampleANTsImaging(mm_spacing=spacing, ANTsImageObject=bcorr_image,
                                                          file_id=filename_save, method=1)
                ants.image_write(bcorr_image, filename=filename_save)
            else:
                print('\t ...already finished, skipped')
