import os
import ants
# joint label fusion - classic
ref = ants.image_read( ants.get_ants_data('r16'))
ref = ants.iMath(ref,'Normalize')
mi = ants.image_read( ants.get_ants_data('r27'))
mi2 = ants.image_read( ants.get_ants_data('r30'))
mi3 = ants.image_read( ants.get_ants_data('r62'))
mi4 = ants.image_read( ants.get_ants_data('r64'))
mi5 = ants.image_read( ants.get_ants_data('r85'))
refmask = ants.get_mask(ref)
ilist = [mi,mi2,mi3,mi4,mi5]
seglist = [None]*len(ilist)
for i in range(len(ilist)):
    ilist[i] = ants.iMath(ilist[i],'Normalize')
    mytx = ants.registration(fixed=ref , moving=ilist[i] ,
        typeofTransform = ('Affine') )
    mywarpedimage = ants.apply_transforms(fixed=ref,moving=ilist[i],
            transformlist=mytx['fwdtransforms'])
    ilist[i] = mywarpedimage
    seg = ants.threshold_image(ilist[i],'Otsu', 3)
    seglist[i] = ( seg ) + ants.threshold_image( seg, 1, 3 ).morphology( operation='dilate', radius=3 )
r = 2
pp = ants.joint_label_fusion(ref, refmask, ilist, r_search=2,
                    label_list=seglist, rad=[r]*ref.dimension )
truSeg = ants.threshold_image(ref,'Otsu', 3)
truSeg = truSeg + ants.threshold_image( truSeg, 1, 3 ).morphology( operation='dilate', radius=3 )
#myOl = ants.label_overlap_measures( truSeg, pp['segmentation'] )
pp = ants.joint_label_fusion(ref,refmask,ilist, r_search=2, rad=[r]*ref.dimension)


# pseudo-geodesic version
ref = ants.image_read( ants.get_ants_data('r16'))
ref = ants.iMath(ref,'Normalize')
ilist = [mi,mi2,mi3,mi4,mi5]
txlistF = [None]*len(ilist)
txlistI = [None]*len(ilist)
for i in range(len(ilist)):
    mytx = ants.registration(fixed=ref , moving=ilist[i] ,
        typeofTransform = ('SyN') )
    txlistF[i] = mytx['fwdtransforms']
    txlistI[i] = mytx['invtransforms']

# construct the concatenated transforms - we use the first image as target
concatlist = [None]*len(ilist)
seglist = [None]*len(ilist)
iwlist = [None]*len(ilist)
wTar = 0
for i in range(len(ilist)):
    concatlist[i] = txlistI[wTar] +  txlistF[i]
    seg = ants.threshold_image(ilist[i],'Otsu', 3)
    iwlist[i] = ants.apply_transforms(fixed=ilist[wTar],moving=ilist[i],
            transformlist=concatlist[i], interpolator = 'nearestNeighbor',
            whichtoinvert = [True,False,False,False] )
    seglist[i] = ants.apply_transforms(fixed=ilist[wTar],moving=seg,
            transformlist=concatlist[i], interpolator = 'nearestNeighbor',
            whichtoinvert = [True,False,False,False] )

# test the concatenation
mywarpedimage = ants.apply_transforms(fixed=ilist[wTar],moving=ilist[4],
        transformlist=concatlist[4], whichtoinvert = [True,False,False,False] )

# these images have similar shape - that's good
ants.plot( mywarpedimage )
ants.plot( ilist[wTar] )


# remove the target image from the list
intensityImageList = iwlist[1:5]
segmentationImageList = seglist[1:5]
r = 2
refmask = ants.get_mask( ilist[wTar] )
# take the parameters from the cookpa example - not from this one - these
# are just chosen for this quick example
pp = ants.joint_label_fusion( ilist[wTar], refmask, intensityImageList, r_search=2,
                    label_list=segmentationImageList, rad=[r]*ref.dimension )

ants.plot(pp['probabilityimages'][0])
ants.plot(pp['probabilityimages'][1])
ants.plot(pp['probabilityimages'][2])

ants.plot(pp['segmentation'])
ants.plot(pp['intensity'])


folder2save = os.path.join(os.getcwd(), '../data', 'test_data')
if not os.path.isdir(folder2save):
    os.mkdir(folder2save)
ants.image_write(pp, filename=os.path.join(folder2save, 'test_fusion_atlases.nii'))
