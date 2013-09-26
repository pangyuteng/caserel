% 
%     {{Caserel}}
%     Copyright (C) {{2013}}  {{Pangyu Teng}}
% 
%     This program is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License along
%     with this program; if not, write to the Free Software Foundation, Inc.,
%     51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%

%   
%
%   This example script demonstrates the usage of CASEREL
%
%   Section 1, loads the path of the image.
%   Section 2, automatically segments the retinal layers based on graph theory.
%   Section 3, using a GUI, iterate through the segmentation results,
%              and maually or semi-automatically correct the segmented
%              retainl layers.
%   Section 4, calculate and print out retinal thickness (in pixels)
%
%   $Created: 1.0 $ $Date: 2013/09/09 20:00$ $Author: Pangyu Teng $
%   $Revision: 1.1 $ $Date: 2013/09/15 21:00$ $Author: Pangyu Teng $

close all;clear all;clc;
%% Section 1, loads the path of the image.

%set 'isUseExampleImage' to 1 to download example image or to 0 to use your
%own images.
isUseExampleImage = 1;

if isUseExampleImage    
    
    %if no example images in folder, download an image and save as 3
    %images to serve as 3 b-scans.
    if exist('exampleOCTimage0001.tif','file') == 0
       img = imread('http://files.abstractsonline.com/CTRL/a7/f/f52/85a/21f/4bf/c96/efa/5b4/85d/99a/0d/g6297_1.jpg');
       imwrite(imresize(img(1000:end,   1:2000,1),0.5),'exampleOCTimage0001.tif');
       imwrite(imresize(img(1000:end,2001:4000,1),0.5),'exampleOCTimage0002.tif');
       imwrite(imresize(img(1000:end,4001:6000,1),0.5),'exampleOCTimage0003.tif');
    end
    
    %get the filepath of the images
    folderPath = cd;
    imagePath{1} = [folderPath '\exampleOCTimage0001.tif'];
    imagePath{2} = [folderPath '\exampleOCTimage0002.tif'];
    imagePath{3} = [folderPath '\exampleOCTimage0003.tif'];
    
    yrange = [];
    xrange = [];

    
else    
    
    path = '\';
    [filename, folderPath , filterindex] = uigetfile([path '*.tif' ],'Pick some images','MultiSelect', 'on');
    for i = 1:numel(filename)
        imagePath{i} = [folderPath ,filename{i}];
    end
    
    figure;
    title('pick a region of interest to segment for the selected images');
    [trsh rect] = imcrop(imread(imagePath{1}));
    xrange = round(rect(1)):round(rect(1)+rect(3));
    yrange = round(rect(2)):round(rect(2)+rect(4));
    
end

%% Section 2, automatically segments the retinal layers based on graph theory.

for i = 1:numel(imagePath)
    
    display(sprintf('segmenting image %d of %d',i,numel(imagePath)));
    
    % read in the image.
    img = imread(imagePath{i});
    
    % error checking, get one channel from image.
    if size(img,3) > 1
        img = img(:,:,1);
        display('warning: this is probably not an oct image');
    end
    
    % make image type as double.
    img = double(img);
    
    % get size of image.
    szImg = size(img);
    
    %segment whole image if yrange/xrange is not specified.
    if isempty(yrange) && isempty(xrange)
        yrange = 1:szImg(1);
        xrange = 1:szImg(2);
    end    
    img = img(yrange,xrange);
    
    % get retinal layers.
    [retinalLayers, params] = getRetinalLayers(img);
    
    % save range of image.
    params.yrange = yrange;
    params.xrange = xrange;
    
    % save data to struct.
    imageLayer(i).imagePath = imagePath{i};
    imageLayer(i).retinalLayers = retinalLayers;    
    imageLayer(i).params = params;

end

% save segmentation
filename = [imageLayer(1).imagePath '_octSegmentation.mat'];
save(filename, 'imageLayer');
display(sprintf('segmentation saved to %s',filename));

%%   Section 3, using a GUI, iterate through the segmentation results,
%              and maually or semi-automatically correct the segmented
%              retainl layers.

close all;

filename = [imagePath{1} '_octSegmentation.mat'];

isReviewSegmentation = 1;
if isReviewSegmentation,
    [h,guiParam] = octSegmentationGUI(filename);   

    if guiParam.proceed
        delete(guiParam.figureOCT);
        delete(h);
    else
        return;
    end    
end


%%  Section 4, calculate and print out retinal thickness (in pixels)

calculateRetinalThickness
