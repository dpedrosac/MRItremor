#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import time
import ants

from utils.HelperFunctions import FileOperations
from dependencies import FILEDIR


def all_subjects(subjects, output_dir=FILEDIR):
    """Create a template specific for this study including all subjects and the corresponding matched-control
    subjects"""

    print('\nCreating a template comprised of {} subject(s) using their respective T1 files'.format(len(subjects)))
    allfiles = FileOperations.get_filelist_as_tuple(f"{FILEDIR}", subjects, subdir='')
    strings2exclude = ['bcorr', 'reg_run', '_ep2d', 'bc_', 'diff_', 'reg_']

    start_extraction = time.time()
    sequences = {'t1': '_MDEFT3D'}
    list_of_files = {k: [] for k in sequences.keys()}

    for seq, keyword in sequences.items():
        list_of_files = [x for x in allfiles if x[0].endswith('.gz') and
                         any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                       os.path.basename(x[0]),
                                       re.IGNORECASE) for z in [keyword] * 3) and not
                         any(re.search(r'\w+(?!_).({})|^({}[\-])\w+.|^({})[a-z\-\_0-9].'.format(z, z, z),
                                       os.path.basename(x[0]),
                                       re.IGNORECASE) for z in strings2exclude)]

    population = list()
    for i in range(len(list_of_files)):
        population.append(ants.image_read(list_of_files[i][0], dimension=3))

    group_template = ants.build_template(initialTemplate=None,
                                         image_list=population,
                                         iterations=4,
                                         gradient_step=0.2,
                                         verbose=True,
                                         syn_metric='CC',
                                         reg_iterations=(100, 70, 50, 0)
                                         )

    ants.image_write(group_template, os.path.join(output_dir, 'group_template.nii'))

    print('\nIn total, a list of {} file(s) was processed \nOverall, template creation took '
          '{:.1f} secs.'.format(len(subjects), time.time() - start_extraction))
