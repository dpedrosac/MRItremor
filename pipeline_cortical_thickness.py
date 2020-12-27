#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
from utils.HelperFunctions import Output, FileOperations, Imaging
from utils import CreateTemplate, PreprocessT1MRI

from dependencies import FILEDIR, ROOTDIR

if __name__ == "__main__":
    try:
        Imaging.set_viewer()
        print("viewer set!")
    except Exception:
        Output.msg_box(text="Something went wrong with defining the standard location for ITK-snap!",
                       title="Problem defining ITKSnap location")

    # Get files ready to analyse using the functions in the HelperFunctions.py module
    subjects2analyse = list(FileOperations.list_folders(os.path.join(ROOTDIR, FILEDIR), prefix='[\d+]'))
    group_template = os.path.join(ROOTDIR, FILEDIR, 'group_template.nii')
    if not os.path.isfile(group_template):
        CreateTemplate.all_subjects(subjects=subjects2analyse, output_dir=FILEDIR)

    imaging, fileID = PreprocessT1MRI.create_list_of_subjects(subjects=subjects2analyse)
    preprocessed_data = PreprocessT1MRI.preprocessMRIbatch(imaging=imaging,
                                                           template_sequence=group_template,
                                                           fileID=fileID)


    # BiasFieldCorrection.Correction().N4BiasSeq(subjects=subjects2analyse)
    # Normalization.Registration().RegisterSeq(subjects=subjects2analyse)

