% Fully automated segmentation of retinal layers in SD-OCT images by graph theory
% 
% This video demonstrates automated segmentation of 7 retinal boundaries by graph theory in SD-OCT images without any knowledge of the location of vessels and macula.  Images used and presented in the video are kindly provided by the following article.
% 
% S.J. Chiu, J.A. Izatt, R.V. O'Connell, K.P. Winter, C.A. Toth, S. Farsiu, Validated Automatic Segmentation of AMD Pathology including Drusen and Geographic Atrophy in SDOCT Images, IOVS 53(1)53-61.
% 
% An earlier version of this implementation can be found at:
% http://www.mathworks.com/matlabcentral/fileexchange/39997-segmentation-of-retinal-layers-in-oct-images-with-graph-theory

% DEMO SD-OCT Image Segmentation by Graph Theory
% author: Pangyu Teng, 29 JUL 2013

% This demo will demonstrate segmentation of 7 retinal boundaries
% by graph theory without any knowledge of
% the location of vessels and macula.  Images shown are kindly provided
% by Dr. Farsiu, and can be obtained from his website
%
%S.J. Chiu, J.A. Izatt, R.V. O'Connell, 
%K.P. Winter, C.A. Toth, S. Farsiu,
%Validated Automatic Segmentation of AMD Pathology including Drusen
%and Geographic Atrophy in SDOCT Images, IOVS 53(1)53-61,

% ENJOY!


close all;clear all;
tic;

%folderPath = 'P:\oct_images\';
addpath('D:\playground\Google Drive\APL\m_files\googleCode\caserel\');
folderPath = 'D:\playground\course_ImagingInformatics\Chiu_IOVS_2011\Automatic versus Manual Study\';

imageDir=dir(folderPath);
imageDirSize = [imageDir.bytes];
imageDir = imageDir(imageDirSize > 233020);
load([folderPath imageDir(1).name]);
patientNums = numel(imageDir);


for i = 1:patientNums
    
    clear imageLayer
    imagePath = [folderPath imageDir(i).name];
    load(imagePath);
    
    for imgNum = 1:size(images,3)
imgNum
        % resize the image if 1st value set to 'true',
        % with the second value to be the scale.
        params.isResize = [true 0.5];
        params.filter0Params = [5 5 1];
        params.filterParams = [20 20 2];           
        params.smallIncre = 2;    
        params.roughILMandISOS.shrinkScale = 0.2;
        params.roughILMandISOS.offsets = -20:20;    
        params.ilm_0 = 4;
        params.ilm_1 = 4;
        params.isos_0 = 4;
        params.isos_1 = 4;
        params.rpe_0 = 0.05;
        params.rpe_1 = 0.05;        
        params.inlopl_0 = 0.4;
        params.inlopl_1 = 0.5;
        params.nflgcl_0 = 0.05;
        params.nflgcl_1 = 0.3;
        params.iplinl_0 = 0.6;
        params.iplinl_1 = 0.2;
        params.oplonl_0 = 0.05;
        params.oplonl_1 = 0.5;
        params.txtOffset = -7;
        colorarr=colormap('jet'); 
        params.colorarr=colorarr(64:-8:1,:);

        params.xrange = 200:800;
        params.yrange = 1:size(images,1);

        img = images(params.yrange,params.xrange,imgNum);
        [retinalLayers, params] = getRetinalLayers(img,params);
        %save the obatined layers

        imageLayer(imgNum).imagePath = imagePath;
        imageLayer(imgNum).imgNum = imgNum;
        imageLayer(imgNum).retinalLayers=retinalLayers;    
        imageLayer(imgNum).params = params;

        title(sprintf('subject %d of %d,img %d of %d',i,patientNums,imgNum,size(images,3)));        
        hold off;

    end %of imgNum
   
    save([imageLayer(1).imagePath '_octSegmentation.mat'], 'imageLayer');    
    
end% of i


%% compare segmentation results with those obtained by Chiu et al.
validateSegmentation