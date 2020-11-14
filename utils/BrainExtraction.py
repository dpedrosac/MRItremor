#!/usr/bin/env python
# -*- coding: utf-8 -*-

import multiprocessing as mp
import os
import re
import time
import ants
import antspynet
import sys

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
        allfiles = FileOperations.get_filelist_as_tuple(f"{FILEDIR}", subjects, subdir='output')
        strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'bc_', 'diff_', 'reg_']
        output_folder = os.path.join(FILEDIR, 'output')
        FileOperations.create_folder(output_folder)

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

        # print(list_of_files['t1'])
        # sys.exit()

        for file in list_of_files['t1']:
            print(f"creating mask for {file[0]}")

            filename2save = os.path.join(output_folder, 'brainmask_' + os.path.split(file[0])[1])
            modality = 't1combined' if seq == 't1' else 't2'

            template = os.path.join(template_folder, 'mni_icbm152_t1_tal_nlin_asym_09b_hires.nii')

            self.create_brainmask(file[0], template=template, filename2save=filename2save, modality=modality)

            print("mask created... ok\n")

        print('\nIn total, a list of {} file(s) was processed \nOverall, brain_extraction took '
              '{:.1f} secs.'.format(len(subjects), time.time() - start_extraction))

    def create_brainmask(self, registered_images, template, filename2save='brainmask_T1.nii', modality='t1combined'):
        """this function import antspynet in order to obtain a probabilistic brain mask for the T1 imaging"""
        import numpy as np

        classes = ("background", "brain")
        number_of_classification_labels = len(classes)

        image_mods = [modality]
        channel_size = len(image_mods)

        print("Reading reorientation template " + template)
        start_time = time.time()
        reorient_template = ants.image_read(template)
        end_time = time.time()
        elapsed_time = end_time - start_time
        print("  (elapsed time: ", elapsed_time, " seconds)")

        reorient_template = ants.resample_image(reorient_template, (256, 256, 128), True, 0)
        resampled_image_size = reorient_template.shape

        unet_model = antspynet.create_unet_model_3d((*resampled_image_size, channel_size),
                                                    number_of_outputs=number_of_classification_labels,
                                                    number_of_layers=4, number_of_filters_at_base_layer=8,
                                                    dropout_rate=0.0,
                                                    convolution_kernel_size=(3, 3, 3),
                                                    deconvolution_kernel_size=(2, 2, 2),
                                                    weight_decay=1e-5)

        print("Loading weights file")
        start_time = time.time()
        weights_file_name = "./brainExtractionWeights.h5"

        if not os.path.exists(weights_file_name):
            weights_file_name = antspynet.get_pretrained_network("brainExtraction", weights_file_name)

        unet_model.load_weights(weights_file_name)
        end_time = time.time()
        elapsed_time = end_time - start_time
        print("  (elapsed time: ", elapsed_time, " seconds)")

        start_time_total = time.time()

        print("Reading ", registered_images)
        start_time = time.time()
        image = ants.image_read(registered_images)
        image = (image - image.min()) / (image.max() - image.min())
        end_time = time.time()
        elapsed_time = end_time - start_time
        print("  (elapsed time: ", elapsed_time, " seconds)")

        print("Normalizing to template")
        start_time = time.time()
        center_of_mass_template = ants.get_center_of_mass(reorient_template)
        center_of_mass_image = ants.get_center_of_mass(image)
        translation = np.asarray(center_of_mass_image) - np.asarray(center_of_mass_template)
        xfrm = ants.create_ants_transform(transform_type="Euler3DTransform",
                                          center=np.asarray(center_of_mass_template),
                                          translation=translation)
        warped_image = ants.apply_ants_transform_to_image(xfrm, image,
                                                          reorient_template)
        warped_image = (warped_image - warped_image.mean()) / warped_image.std()

        batchX = np.expand_dims(warped_image.numpy(), axis=0)
        batchX = np.expand_dims(batchX, axis=-1)
        batchX = (batchX - batchX.mean()) / batchX.std()

        end_time = time.time()
        elapsed_time = end_time - start_time
        print("  (elapsed time: ", elapsed_time, " seconds)")

        print("Prediction and decoding")
        start_time = time.time()
        predicted_data = unet_model.predict(batchX, verbose=0)

        origin = reorient_template.origin
        spacing = reorient_template.spacing
        direction = reorient_template.direction

        probability_images_array = list()
        probability_images_array.append(
            ants.from_numpy(np.squeeze(predicted_data[0, :, :, :, 0]),
                            origin=origin, spacing=spacing, direction=direction))
        probability_images_array.append(
            ants.from_numpy(np.squeeze(predicted_data[0, :, :, :, 1]),
                            origin=origin, spacing=spacing, direction=direction))

        probability_images_array[1]
        end_time = time.time()
        elapsed_time = end_time - start_time
        print("  (elapsed time: ", elapsed_time, " seconds)")

        print("Renormalize to native space")
        start_time = time.time()
        probability_image = ants.apply_ants_transform_to_image(
            ants.invert_ants_transform(xfrm), probability_images_array[1],
            image)
        end_time = time.time()
        elapsed_time = end_time - start_time
        print("  (elapsed time: ", elapsed_time, " seconds)")

        # probability_image.plot(title="After Extraction", axis=1)

        print("Writing", 'brainmask_test_t1.nii.gz')
        start_time = time.time()
        ants.image_write(probability_image, 'brainmask_test_t1.nii.gz')
        end_time = time.time()
        elapsed_time = end_time - start_time
        print("  (elapsed time: ", elapsed_time, " seconds)")

        end_time_total = time.time()
        elapsed_time_total = end_time_total - start_time_total
        print("Total elapsed time: ", elapsed_time_total, "seconds")

        ants_image = ants.image_read(registered_images)
        brainmask = antspynet.brain_extraction(image=ants_image, modality=modality, verbose=self.verbose)
        ants.image_write(image=brainmask, filename=filename2save)
