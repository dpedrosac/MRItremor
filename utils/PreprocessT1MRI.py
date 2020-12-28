#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import time
import ants
import antspynet
import sys
from contextlib import contextmanager
import getpass

from utils.HelperFunctions import FileOperations
from dependencies import ROOTDIR, FILEDIR


def create_list_of_subjects(subjects):
    """Creates a list of subjects used to preprocess data according to the proposed pipeline in ANTsPyNet
    cf. https://github.com/ANTsX/ANTsPyNet/blob/master/antspynet/utilities/cortical_thickness.py"""

    print("\n{}\nFile Preparation:\t\textracting filenames.\n{}".format('=' * 85, '=' * 85))
    allfiles = FileOperations.get_filelist_as_tuple(f"{FILEDIR}", subjects, subdir='')
    strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'bc_', 'diff_', 'reg_']

    start_preprocessing = time.time()
    sequences = {'t1': '_MDEFT3D', 't2': '_t2_'}  # so far t2 is not used andd only included for completeness
    list_of_files = {k: [] for k in sequences.keys()}

    for seq, keyword in sequences.items():
        list_of_files[seq] = [x for x in allfiles if x[0].endswith('.gz') and
                              any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                            os.path.basename(x[0]),
                                            re.IGNORECASE) for z in [keyword] * 3) and not
                              any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                            os.path.basename(x[0]),
                                            re.IGNORECASE) for z in strings2exclude)]

    all_processed_files = FileOperations.list_files_in_folder(f"{FILEDIR}" + 'preprocessed',
                                                              contains=subjects, suffix='nii.gz')
    regexp = '(T_template0tANAT).(\d{4}\w).*(MDEFT3D[0-9]*WarpedToTemplate.nii.gz)'
    if all_processed_files:
        all_processed_files = [re.search(regexp, x)[2] for x in all_processed_files]

    imaging, proc_subj = [[] for _ in range(2)]
    new_dict = {'t1': list_of_files['t1']}
    for idx, fileID in enumerate(list_of_files['t1']):
        if any(fileID[1] in s for s in all_processed_files):
            proc_subj.append(idx)
            new_dict['t1'] = [(i, j) for i, j in list_of_files['t1'] if j != fileID[1]]
        else:
            imaging.append(ants.image_read(fileID[0]))

    list_of_files['t1'] = new_dict['t1']
    print('\n{}\nFile Preparation: {} imaging file(s) will be processed. {} subjects already finished.\n{}'
          .format('=' * 85, len(subjects) - len(proc_subj), len(proc_subj), '=' * 85))

    return imaging, list_of_files['t1']


def preprocessMRIbatch(imaging, template_sequence, fileID, truncate_intensity=(.01, .99), return_bias_field=True, verbose=True):
    """ Pre-preprocessing steps applied according to the pipeline proposed for cortical thickness estimation"""

    # =================     General steps during processing     =================
    antsxnet_cache_directory = "ANTsXNet"
    # template_transform_type = "SyNRA"  # "antsRegistrationSyNQuick[r]"
    intensity_normalization_type = '01'
    output_folder = os.path.join(ROOTDIR, FILEDIR, 'preprocessed')
    FileOperations.create_folder(output_folder)

    if not os.path.exists(f"{FILEDIR}" + 'registrationMatrices'):
        FileOperations.create_folder(f"{FILEDIR}" + 'registrationMatrices')

    if not os.path.exists(f"{ROOTDIR}" + '/logs'):
        FileOperations.create_folder(f"{ROOTDIR}" + '/logs')

    # Load study specific template (SST) created from all subjects (cf. TemplateCreationParallel.py)
    sst = ants.image_read(template_sequence)
    sst_tmp = ants.image_clone(sst) * 0

    if isinstance(sst, str):
        template_file_name_path = antspynet.get_antsxnet_data(sst, antsxnet_cache_directory=antsxnet_cache_directory)
        template_image = ants.image_read(template_file_name_path)
    else:
        template_image = sst

    template_probability_mask = antspynet.brain_extraction(template_image,
                                                           antsxnet_cache_directory=antsxnet_cache_directory,
                                                           verbose=verbose)
    template_mask = ants.threshold_image(template_probability_mask, 0.5, 1, 1, 0)
    if getpass.getuser() == 'david':
        template_mask = ants.image_clone(template_probability_mask)  # unnecessary except for david's machine
        template_mask = template_mask > .75
    template_brain_image = template_mask * template_image

    for idx, image in enumerate(imaging):
        print("\n{}\nSST processing image {} ( out of {} )\n{}".format('=' * 85, idx + 1, len(imaging), '=' * 85))
        preprocessed_image = ants.image_clone(image)

        # =================     Truncate intensities to avoid outliers at x < 1 & > 99 prctile     =================
        if truncate_intensity is not None:
            quantiles = (image.quantile(truncate_intensity[0]), image.quantile(truncate_intensity[1]))
            print("\n{}\nPreprocessing:\t\ttruncate intensities [q1:{};q4:{}]\n{}".format('='*85, quantiles[0],
                                                                                          quantiles[1], '='*85))
            preprocessed_image[image < quantiles[0]] = quantiles[0]
            preprocessed_image[image > quantiles[1]] = quantiles[1]

        # =====================================     Brain extraction     =====================================
        print("\n{}\nPreprocessing:\t\tbrain extraction.\n{}".format('=' * 85, '=' * 85))
        probability_mask = antspynet.brain_extraction(preprocessed_image,
                                                      antsxnet_cache_directory=antsxnet_cache_directory,
                                                      verbose=verbose)
        mask = ants.threshold_image(probability_mask, 0.5, 1, 1, 0)
        if getpass.getuser() == 'david':
            mask = ants.image_clone(probability_mask) # unnecessary except for david's machine
            mask = mask > .75
        preprocessed_brain_image = preprocessed_image * mask

        # =====================================     Registration to SST     =====================================
        # @contextmanager
        # def custom_redirection(fileobj):
        #    old = sys.stdout
        #    sys.stdout = fileobj
        #    try:
        #        yield fileobj
        #    finally:
        #        sys.stdout = old

        # redirect stdout to file for debugging purposes:
        # logfile_name = os.path.join( f"{ROOTDIR}" + '/logs', fileID[idx][1] + "_registration2sst.txt")
        # with open(logfile_name, 'w') as out:
        #    with custom_redirection(out):
        registration = ants.registration(fixed=template_brain_image,
                                         moving=preprocessed_brain_image,
                                         # grad_step=.2,
                                         type_of_transform="antsRegistrationSyNQuick[a]", #"SyNRA", #"antsRegistrationSyNQuick[a]",
                                         verbose=verbose)

        preprocessed_image = ants.apply_transforms(fixed=template_image, moving=preprocessed_image,
                                                   transformlist=registration['fwdtransforms'], interpolator="linear",
                                                   verbose=verbose)
        mask = ants.apply_transforms(fixed=template_image, moving=mask,
                                     transformlist=registration['fwdtransforms'], interpolator="genericLabel",
                                     verbose=verbose)

        filename_raw = os.path.basename(fileID[idx][0]).split('.')[0]
        transform = ants.read_transform(registration['fwdtransforms'][0])
        filename_complete = 'T_' + filename_raw + 'GenericAffine.mat'
        ants.write_transform(transform, os.path.join(f"{FILEDIR}" + 'registrationMatrices', filename_complete))

        # This part is only necessary, when to matrices are returned (i.e. when type_of_transform is e.g. SyNRA?)
        # key2rename = {'fwdtransforms': ['{}_0GenericAffine.mat'.format(filename_raw), 1],
        #               'invtransforms': ['{}_1InvWarpMatrix.mat'.format(filename_raw), 0]}
        # for key, value in key2rename.items():
        #     transform = ants.read_transform(registration[key])
        #     ants.write_transform(transform, os.path.join(f"{FILEDIR}" + 'registrationMatrices', value[0]))

        # =====================================     Bias correction     =====================================
        bias_field = None
        print("\n{}\nPreprocessing:\t\tN4 bias correction\n{}".format('=' * 85, '=' * 85))
        if mask is None:
            n4_output = ants.n4_bias_field_correction(preprocessed_image, shrink_factor=4,
                                                      return_bias_field=return_bias_field, verbose=verbose)
        else:
            n4_output = ants.n4_bias_field_correction(preprocessed_image, mask, shrink_factor=4,
                                                      return_bias_field=return_bias_field, verbose=verbose)
        if return_bias_field:
            bias_field = n4_output
        else:
            preprocessed_image = n4_output

        # =====================================     Denoising     =====================================
        print("\n{}\nPreprocessing:\t\tDenoising".format('=' * 85, '=' * 85))
        if mask is None:
            preprocessed_image = ants.denoise_image(preprocessed_image, shrink_factor=1)
        else:
            preprocessed_image = ants.denoise_image(preprocessed_image, mask, shrink_factor=1)

        # =====================================     Intensity normalisation     =====================================
        if intensity_normalization_type is not None:
            print("\n{}\nPreprocessing:\t\tintensity normalization".format('=' * 85, '=' * 85))

            if intensity_normalization_type == "01":
                preprocessed_image = (preprocessed_image - preprocessed_image.min()) / (
                        preprocessed_image.max() - preprocessed_image.min())
            elif intensity_normalization_type == "0mean":
                preprocessed_image = (preprocessed_image - preprocessed_image.mean()) / preprocessed_image.std()
            else:
                raise ValueError("Unrecognized intensity_normalization_type.")

        # =================     Save results     =================
        filename2save = 'T_template0' + filename_raw + 'WarpedToTemplate.nii.gz'
        ants.image_write(preprocessed_image, os.path.join(output_folder, filename2save))
