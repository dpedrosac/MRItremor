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


def create_list_of_subjects(subjects):
    """Creates a list of subjects used to preprocess data according to the proposed pipeline in ANTsPyNet
    cf. https://github.com/ANTsX/ANTsPyNet/blob/master/antspynet/utilities/cortical_thickness.py"""

    print('\nPre-Processing the brains of {} subject(s)'.format(len(subjects)))
    allfiles = FileOperations.get_filelist_as_tuple(f"{FILEDIR}", subjects, subdir='')
    strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'bc_', 'diff_', 'reg_']

    start_preprocessing = time.time()
    sequences = {'t1': '_MDEFT3D', 't2': '_t2_'}
    list_of_files = {k: [] for k in sequences.keys()}

    for seq, keyword in sequences.items():
        list_of_files[seq] = [x for x in allfiles if x[0].endswith('.gz') and
                              any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                            os.path.basename(x[0]),
                                            re.IGNORECASE) for z in [keyword] * 3) and not
                              any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                            os.path.basename(x[0]),
                                            re.IGNORECASE) for z in strings2exclude)]

    imaging = []
    for fileID in list_of_files['t1']:
        imaging.append(ants.image_read(fileID[0]))

    print('\nIn total, a list of {} imaging file(s) was processed \nThis took '
          '{:.1f} secs.'.format(len(subjects), time.time() - start_preprocessing))

    return imaging, list_of_files['t1']

def preprocessMRIbatch(imaging, template_sequence, fileID, verbose=True):
    """ Pre-preprocessing steps applied according to the pipeline proposed for cortical thickness estimation"""

    output_folder = os.path.join(ROOTDIR, FILEDIR, 'preprocessed')
    FileOperations.create_folder(output_folder)

    # Load the subject-specific template created from all subjects included in this study
    sst = ants.image_read(template_sequence)
    sst_tmp = ants.image_clone(sst) * 0

    # Settings for first step:
    antsxnet_cache_directory = "ANTsXNet"
    template_transform_type = "SyNRA" #"antsRegistrationSyNQuick[r]"
    intensity_normalization_type = '01'
    truncate_intensity = (.01, .99)

    for idx, image in enumerate(imaging):
        print("\n{}\nSST processing image {} ( out of {} )\n{}".format('='*85, idx+1, len(imaging), '='*85))

        preprocessed_image = ants.image_clone(image)

        # Truncate intensities to avoid outliers at x < 1 & > 99 prctile
        if truncate_intensity is not None:
            quantiles = (image.quantile(truncate_intensity[0]), image.quantile(truncate_intensity[1]))
            print("Preprocessing:\t\t truncate intensities ( low =", quantiles[0], ", high =", quantiles[1], ")")
            preprocessed_image[image < quantiles[0]] = quantiles[0]
            preprocessed_image[image > quantiles[1]] = quantiles[1]

        registration = ants.registration(fixed=sst,
                                         moving=preprocessed_image,
                                         metric='mattes',
                                         grad_step=.1,
                                         type_of_transform=template_transform_type,
                                         verbose=verbose)
        preprocessed_image = registration['warpedmovout']
        transforms = dict(fwdtransforms=registration['fwdtransforms'], invtransforms=registration['invtransforms'])

        # Intensity normalization
        if intensity_normalization_type is not None:
            if verbose == True:
                print("Preprocessing:\t\tintensity normalization.") #print("\n{}\nPreprocessing:\t\tintensity normalization.\n{}".format('='*85, '='*85))

            if intensity_normalization_type == "01":
                preprocessed_image = (preprocessed_image - preprocessed_image.min()) / (
                        preprocessed_image.max() - preprocessed_image.min())
            elif intensity_normalization_type == "0mean":
                preprocessed_image = (preprocessed_image - preprocessed_image.mean()) / preprocessed_image.std()
            else:
                raise ValueError("Unrecognized intensity_normalization_type.")

        sst_tmp += preprocessed_image

    sst = sst_tmp / len(imaging)

    t1s_preprocessed = list()
    for idx, image in enumerate(imaging):
        print("\n{}\nFinal processing image ({} out of {} )\n{}".format('='*85, idx+1, len(imaging), '='*85))

        preprocessed_image = ants.image_clone(image)
        template_transform_type = "SyNRA" # "antsRegistrationSyNQuick[a]"
        do_bias_correction = True
        intensity_normalization_type = "01"

        # Truncate intensities to avoid outliers at x < 1 & > 99 prctile
        if truncate_intensity is not None:
            quantiles = (image.quantile(truncate_intensity[0]), image.quantile(truncate_intensity[1]))
            print("Preprocessing:\t\t truncate intensities ( low =", quantiles[0], ", high =", quantiles[1], ")")
            preprocessed_image[image < quantiles[0]] = quantiles[0]
            preprocessed_image[image > quantiles[1]] = quantiles[1]

        # Brain extraction
        mask = None
        print("Preprocessing:\t\tbrain extraction.")  # print("\n{}\nPreprocessing:\t\tintensity normalization.\n{}".format('='*85, '='*85))

        probability_mask = antspynet.brain_extraction(preprocessed_image,
                                                      antsxnet_cache_directory=antsxnet_cache_directory,
                                                      verbose=verbose)
        mask = ants.image_clone(probability_mask)
        mask = mask > .75
#        mask = ants.threshold_image(probability_mask, 0.5, 1, 1, 0)

        # Template normalization
        transforms = None
        if template_transform_type is not None:
            template_image = None
            if isinstance(sst, str):
                template_file_name_path = antspynet.get_antsxnet_data(sst,
                                                                      antsxnet_cache_directory=antsxnet_cache_directory)
                template_image = ants.image_read(template_file_name_path)
            else:
                template_image = sst

            if mask is None:
                registration = ants.registration(fixed=template_image, moving=preprocessed_image,
                                                 type_of_transform=template_transform_type, verbose=verbose)
                preprocessed_image = registration['warpedmovout']
                transforms = dict(fwdtransforms=registration['fwdtransforms'],
                                  invtransforms=registration['invtransforms'])
            else:
                template_probability_mask = antspynet.brain_extraction(template_image,
                                                                       antsxnet_cache_directory=antsxnet_cache_directory,
                                                                       verbose=verbose)
                template_mask = ants.image_clone(template_probability_mask)
                template_mask = template_mask > .75

                #template_mask = ants.threshold_image(template_probability_mask, 0.5, 1, 1, 0)
                template_brain_image = template_mask * template_image

                preprocessed_brain_image = preprocessed_image * mask

                registration = ants.registration(fixed=template_brain_image, moving=preprocessed_brain_image,
                                                 type_of_transform=template_transform_type, verbose=verbose)
                transforms = dict(fwdtransforms=registration['fwdtransforms'],
                                  invtransforms=registration['invtransforms'])

                preprocessed_image = ants.apply_transforms(fixed=template_brain_image, moving=preprocessed_brain_image,
                                                           transformlist=registration['fwdtransforms'],
                                                           interpolator="linear", verbose=verbose)
                mask = ants.apply_transforms(fixed=template_brain_image, moving=mask,
                                             transformlist=registration['fwdtransforms'], interpolator="genericLabel",
                                             verbose=verbose)

        # Do bias correction
        bias_field = None
        if do_bias_correction == True:
            return_bias_field = False
            if verbose == True:
                print("Preprocessing:  brain correction.")
            n4_output = None
            if mask is None:
                n4_output = ants.n4_bias_field_correction(preprocessed_image, shrink_factor=4,
                                                          return_bias_field=return_bias_field, verbose=verbose)
            else:
                n4_output = ants.n4_bias_field_correction(preprocessed_image, mask, shrink_factor=4,
                                                          return_bias_field=return_bias_field, verbose=verbose)
            if return_bias_field == True:
                bias_field = n4_output
            else:
                preprocessed_image = n4_output

        # Denoising
        do_denoising = True
        if do_denoising == True:
            if verbose == True:
                print("Preprocessing:  denoising.")

            if mask is None:
                preprocessed_image = ants.denoise_image(preprocessed_image, shrink_factor=1)
            else:
                preprocessed_image = ants.denoise_image(preprocessed_image, mask, shrink_factor=1)

        # Intensity normalization
        if intensity_normalization_type is not None:
            if verbose == True:
                print("Preprocessing:  intensity normalization.")

            if intensity_normalization_type == "01":
                preprocessed_image = (preprocessed_image - preprocessed_image.min()) / (
                        preprocessed_image.max() - preprocessed_image.min())
            elif intensity_normalization_type == "0mean":
                preprocessed_image = (preprocessed_image - preprocessed_image.mean()) / preprocessed_image.std()
            else:
                raise ValueError("Unrecognized intensity_normalization_type.")
        return_dict = {'preprocessed_image': preprocessed_image}
        if mask is not None:
            return_dict['brain_mask'] = mask
        if bias_field is not None:
            return_dict['bias_field'] = bias_field
        if transforms is not None:
            return_dict['template_transforms'] = transforms

        filename2save= 'PREPROC-T1_MRI_' + fileID[idx][1] + '.nii'
        ants.image_write(preprocessed_image, os.path.join(output_folder, filename2save))
        ants.image_write(preprocessed_image, os.path.join(output_folder, filename2save))

        t1s_preprocessed.append(preprocessed_image)

    ants.image_write(sst, filename=os.path.join(output_folder, 'SST_allsubj-T1_MRI.nii'))
    return t1s_preprocessed