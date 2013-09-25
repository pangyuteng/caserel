# Welcome!

Project Caserel is an open-source software suite for computer-aided segmentation of retinal layers in optical coherence tomography images written in Matlab.

Currently, the software supports segmentation of 6 retinal layers by automatically delineating 7 boundaries (ILM, NFL/GCL, IPL/INL, INL/OPL, OPL/ONL, IS/OS,RPE). An image browser/editor is provided for manual and semi-automated correction of the segmented retinal boundaries.  For a quick demonstration, please run script `getRetinalLayersExample.m`.

# Example Results
[![An example image demonstrating the segmentation results by Caserel.](https://sites.google.com/site/pangyuteng/projects/091313__yux005.jpg)](http://www.youtube.com/embed/UWW0Y52PskA)

Above video illustrates the segmentation results by Caserel.

# Disclaimer
Please note that this project is "work-in-progress", meaning many features still needs to be implemented, e.g. detection of macula and vessels.  In addition, the accuracy of the automated segmentation are not yet validated, so if you are to use the resulting segmentation for quantification of retinal layer thickness, I recommend carefully reviewing the segmentation results using either the provided GUI or other image segmentation tools.

Drop your comments/ideas [here](https://github.com/pangyuteng/caserel/issues).

# How to pronounce Caserel? 
Say it like casserole.  The name is derived from "Computer-Aided SEgmentation of REtinal Layers in optical coherence tomography images".

# TODOS:
- [x] Retinal Thickness Output
        added 'calculateRetinalThickness.m'
- [] Macular detection
- [ ] Vessel detection
- [ ] Evaluation of segmentation accuracy using publicaly available datasets.
        09/24/2013, Compared ILM and RPE segmentations with the automated segmentation by [S.J. Chiu](http://people.duke.edu/~sf59/Chiu_IOVS_2011_dataset.htm).
                    In 214 of 220 b-scans from 20 patients, segmentation of ILM and RPE by Caserel was in good agreement with that obtained by S.J. Chiu's method.
                    Mean absolute difference between the segmented ILM and RPE by the two methods were 0.7+/-0.7 and 2.2+/-1.7 pixels, respectively (N = 214 images).
- [ ] Minimize the use of constants

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/pangyuteng/caserel/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/1375c1d50439709f78fe58b7ca085e7e "githalytics.com")](http://githalytics.com/pangyuteng/caserel)
