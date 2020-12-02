#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
from utils.HelperFunctions import Configuration, Output, FileOperations, Imaging
from utils import CreateTemplate

from utils import MRI_BiasField as BiasFieldCorrection
from utils import TemplateRegistration as Normalization
from utils import BrainExtraction
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

    # Skull strip at this point here
    BrainExtraction.AntsPyX().extract_list_of_patients(subjects=subjects2analyse, template=group_template)



    # BiasFieldCorrection.Correction().N4BiasSeq(subjects=subjects2analyse)
    # Normalization.Registration().RegisterSeq(subjects=subjects2analyse)

