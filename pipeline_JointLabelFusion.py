#!/usr/bin/env python
# -*- coding: utf-8 -*-
import getpass
import os
import math

import ants
import antspynet

import numpy as np
from dependencies import ROOTDIR, FILEDIR, CONFIGDATA
from utils.HelperFunctions import FileOperations


def create_filenames(no_of_files, prefix, suffix1, suffix2, label_name):
    """creates the names of the atlases enabling to return a list of filenames which may be used to coregister data"""

    fID = []
    for idx in range(1, no_of_files + 1, 1):
        fID.append(tuple(('{}{}{}'.format(prefix, int(idx), suffix1),
                          '{}{}{}{}'.format(prefix, int(idx), label_name, suffix2))))  # :02d needed for hamers dataset
    return fID


def relabel_atlases(label_orig, list_of_regions, all_labels):
    """ANTsPy crashes, when there are too many labels so this part re-labels the atlases; it is also possible to
    relabel the data, so that a list may be returned which facilitates labeling back after joint_label_fusion"""

    iter_label = 0
    for k in all_labels:
        if k not in list_of_regions:
            label_orig[label_orig == k] = 0
    # iter_label += 1

    return label_orig


def split_runs(a, n):
    k, m = divmod(len(a), n)
    return (a[i * k + min(i, m):(i + 1) * k + min(i + 1, m)] for i in range(n))


def run_jlf(atlas_directory, template_image, debug=False):
    if not os.path.exists(atlas_directory):
        FileOperations.create_folder(atlas_directory)

    if not os.listdir(atlas_directory):
        print('No atlases were found, please make sure to add atlas with corresponding segmentation'
              'to folder {}'.format(atlas_directory))
        return

    template = ants.image_read(template_image)
    antsxnet_cache_directory = "ANTsXNet"
    template_probability_mask = antspynet.brain_extraction(template,
                                                           antsxnet_cache_directory=antsxnet_cache_directory,
                                                           verbose=True)
    template_mask = ants.threshold_image(template_probability_mask, 0.5, 1, 1, 0)
    if getpass.getuser() == 'david':
        template_mask = ants.image_clone(template_probability_mask)  # unnecessary except for david's machine
        template_mask[template_mask >= 0] = 0
        template_mask[template_probability_mask > .5] = 1
    targetImage = template_mask * template

    targetImage = ants.iMath(targetImage, operation='Normalize')
    targetMask = ants.image_clone(targetImage)
    targetMask[targetMask >= 0] = 0

    # allFiles = create_filenames(no_of_files=30, prefix='a', suffix1='.nii.gz',
    #                            suffix2='.nii.gz', label_name='-seg')
    allFiles = create_filenames(no_of_files=20, prefix='OASIS-TRT-20-', suffix1='_brain.nii.gz',
                                suffix2='.nii.gz', label_name='_DKT31_CMA_labels')
    if debug:
        allFiles = allFiles[0:3]

    atlases, labels = [[None] * len(allFiles) for _ in range(2)]
    for idx, (atlas_individual, label_individual) in enumerate(allFiles):
        atlas = ants.image_read(os.path.join(atlas_directory, atlas_individual))
        atlas_probability_mask = antspynet.brain_extraction(atlas,
                                                            antsxnet_cache_directory=antsxnet_cache_directory,
                                                            verbose=True)
        atlas_mask = ants.threshold_image(atlas_probability_mask, 0.5, 1, 1, 0)
        if getpass.getuser() == 'david':
            atlas_mask = ants.image_clone(atlas_probability_mask)  # unnecessary except for david's machine
            atlas_mask[atlas_mask >= 0] = 0
            atlas_mask[atlas_probability_mask > .5] = 1
        atlas = atlas_mask * atlas

        label = ants.image_read(os.path.join(atlas_directory, label_individual))
        label = atlas_mask * label

        print("\n{}\nRegistering {}; atlas {} of {}:\t\tRegistering".format('=' * 85, atlas_individual,
                                                                            idx + 1, len(atlases), '=' * 85))

        registration = ants.registration(fixed=targetImage,
                                         moving=ants.iMath(atlas, operation='Normalize'),  # Normalize
                                         type_of_transform="SyNRA",  # "SyNRA", #"antsRegistrationSyNQuick[a]",
                                         verbose=True)
        atlases[idx] = ants.apply_transforms(fixed=targetImage, moving=ants.iMath(atlas, operation='Normalize'),
                                             transformlist=registration['fwdtransforms'])

        labels[idx] = ants.apply_transforms(fixed=targetImage, moving=label,
                                            transformlist=registration['fwdtransforms'],
                                            interpolator='genericLabel')
        targetMask[labels[idx] != 0] = 1

    targetMask = targetMask.morphology(operation='dilate', radius=3)
    ants.plot(targetImage, targetMask, overlay_cmap="jet", overlay_alpha=0.4)

    all_labels = np.unique(labels[0].numpy())
    runs_list = list(split_runs(all_labels, math.ceil(len(all_labels)/20)))  # necessary to avoid memory problems
    for idx_run, runs in enumerate(runs_list):
        labels_renamed = [None] * len(labels)
        for idx in range(len(labels)):
            labels_renamed[idx] = ants.image_clone(labels[idx])
            print("\n{}\nPre-Processing {}; {} of {}:\t\tRe-labeling images".format('=' * 85, 'labels',
                                                                                    idx + 1, len(labels), '=' * 85))
            labels_renamed[idx] = relabel_atlases(labels_renamed[idx], np.unique(np.append(runs, 0)), all_labels)

        print("\n{}\nRunning JLF for {} labels (run {} of {}):\t\tJointLabelFusion".format('=' * 85, len(np.unique(labels_renamed[0].numpy())),
                                                                            idx_run + 1, len(runs_list), '=' * 85))

        jlf = ants.joint_label_fusion(target_image=targetImage, target_image_mask=targetMask, atlas_list=atlases,
                                      label_list=labels_renamed, rad=[2] * targetImage.dimension, verbose=True)

        directory2save = os.path.join(ROOTDIR, 'data', 'patients', 'probabilityJLF')
        filename_intensities = os.path.join(directory2save, 'intensity_run{}.nii.gz'.format(str(idx_run)))
        ants.image_write(jlf['intensity'], filename=filename_intensities)

        filename_segmentation = os.path.join(directory2save, 'segmentation_run{}.nii.gz'.format(str(idx_run)))
        ants.image_write(jlf['segmentation'], filename=filename_segmentation)

        for idx, prob_atlas in enumerate(jlf['probabilityimages']):
            if not os.path.exists(directory2save):
                FileOperations.create_folder(directory2save)

            filename_format = 'probmask_reg{:02d}_run{}.nii.gz'.format(jlf['segmentation_numbers'][idx], str(idx_run))
            region_filename = os.path.join(directory2save, filename_format)
            ants.image_write(prob_atlas, filename=region_filename)


if __name__ == "__main__":
    atlas_directory = os.path.join(ROOTDIR, 'data', 'atlases', CONFIGDATA['malf']['atlas'])
    template = os.path.join(ROOTDIR, 'data', 'template', CONFIGDATA['malf']['template'])

    exit(run_jlf(atlas_directory, template))
