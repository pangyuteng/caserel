# Welcome!

Project Caserel is an open-source software suite for computer-aided segmentation of retinal layers in optical coherence tomography images written in Matlab.  For more information, check out the main project page: [pangyuteng.github.io/caserel](http://pangyuteng.github.io/caserel/).

# Progress

- [x] Automated segmentation of retinal boundaries
                   - added 'getRetinalLayers.m', segmentation method based on graph theory ([S.J. Chiu, et al](http://goo.gl/Z8zsY)).
- [x] Retinal thickness output
                   - added 'calculateRetinalThickness.m'.
- [x] Evaluation of ILM and RPE
                   - [latest evaluation](https://github.com/pangyuteng/caserel/wiki/Evaluation-of-segmentation).
- [ ] Macular detection
                   - current stage of developtment, considering to use support vector machine ([K.A. Vermeer, et al](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3114239/)).
- [ ] Vessel detection
- [ ] Minimize the use of constants
- [ ] Final evaluation of segmentation using publicaly available datasets



# License
This project is under [GPL v2, "a copyleft license that requires anyone who distributes code or a derivative work to make the source available under the same terms."](http://choosealicense.com/licenses/gpl-v2/)  For full details, see the [LICENSE](https://github.com/pangyuteng/caserel/blob/master/LICENSE) file provided in the project folder.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/pangyuteng/caserel/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/1375c1d50439709f78fe58b7ca085e7e "githalytics.com")](http://githalytics.com/pangyuteng/caserel)
