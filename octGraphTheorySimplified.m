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


%% This script demonstrates how graph theory can be used to segment 
% retinal layers in optical coherence tomography images. The method is based on 
% 
% Chiu SJ et al, Automatic segmentation of seven retinal layers in SDOCT
% images congruent with expert manual segmentation, Optics Express, 2010;18(18);19413-19428
% Section 3.2
% link(pubmed): http://goo.gl/Z8zsY
% 
% USAGE:
% run the script by pressing F5.
% 
% I am working on a more comprehensive software package for computer-aided 
% segmentation of retinal layers in optical coherence tomography images, 
% which currently includes 1. automated segmentation of 6 reitnal layers and 
% 2. GUI for examination and manual correction of the automated segmentation. 
% It is called caserel and can be downloaded at my github page. http://goo.gl/yPqhPu
%
%
% $Revision: 1.0 $ $Date: 2013/01/23 21:00$ $Author: Pangyu Teng $
% $Revision: 1.1 $ $Date: 2013/09/15 21:00$ $Author: Pangyu Teng $
%                   Comment: simplified the script to detect only ILM and RPE
%

close all;clear all;clc;
warning off;

%% load data
if exist('exampleOCTimage0002.tif','file') == 2
   img = imread('http://files.abstractsonline.com/CTRL/a7/f/f52/85a/21f/4bf/c96/efa/5b4/85d/99a/0d/g6297_1.jpg');
   imwrite(imresize(img(1000:end,2001:4000,1),0.5),'exampleOCTimage0002.tif');
end
    
%get path of an image.
folderPath = cd;
img = imread([folderPath '/exampleOCTimage0002.tif']);

% blur image
img = imfilter(img,fspecial('gaussian',[5 20],3));

% shrink the image (not necessary, but this helps to decrease compuation time)
img = imresize(img,0.1);


%% ### Section 3.2 Calculatge graph weights ### 

% pad image with vertical column on both sides
szImg = size(img);
imgNew = zeros([szImg(1) szImg(2)+2]);
imgNew(:,2:1+szImg(2)) = img;

szImgNew = size(imgNew);

% get  vertical gradient image
gradImg = nan(szImgNew);
for i = 1:szImgNew(2)
    gradImg(:,i) = -1*gradient(imgNew(:,i),2);
end
gradImg = (gradImg-min(gradImg(:)))/(max(gradImg(:))-min(gradImg(:)));

% get the "invert" of the gradient image.
gradImgMinus = gradImg*-1+1; 

%% generate adjacency matrix, see equation 1.

%minimum weight
minWeight = 1E-5;
%arry to store weights
adjMW = nan([numel(imgNew(:)),8]);
%arry to store negative weights
adjMmW = nan([numel(imgNew(:)),8]);
%arry to store point A locations
adjMX = nan([numel(imgNew(:)),8]);
%arry to store point B locations
adjMY = nan([numel(imgNew(:)),8]);

neighborIter = [1 1  1 0  0 -1 -1 -1;...
                1 0 -1 1 -1  1  0 -1];
            
%fill in the above arrays according to Section 3.2
szadjMW = size(adjMW);
ind = 1; indR = 0;
while ind ~= szadjMW(1)*szadjMW(2) %this step can be made more efficient to increase speed.
    [i, j] = ind2sub(szadjMW,ind);    
    [iX,iY] = ind2sub(szImgNew,i);    
    jX = iX + neighborIter(1,j);
    jY  = iY + neighborIter(2,j);
     if jX >=1 && jX <= szImgNew(1) && jY >=1 && jY <= szImgNew(2),
         %save weight
         % set to minimum if on the sides
         if jY == 1 || jY == szImgNew(2);
            adjMW(i,j) = minWeight;
            adjMmW(i,j) = minWeight;
         % else, calculate the actual weight based on equation 1.
         else
            adjMW(i,j) = 2 - gradImg(iX,iY) - gradImg(jX,jY) + minWeight;
            adjMmW(i,j) = 2 - gradImgMinus(iX,iY) - gradImgMinus(jX,jY) + minWeight;
         end
        %save the subscript of the corresponding nodes
        adjMX(i,j) = sub2ind(szImgNew,iX,iY);
        adjMY(i,j) = sub2ind(szImgNew,jX,jY);
    end
    ind = ind+1;
    
    %display progress
    if indR < round(10*ind/szadjMW(1)/szadjMW(2)),
        indR = round(10*ind/szadjMW(1)/szadjMW(2));
        display(sprintf('progress: %1.0f%% done, this may take a while...\n',100*indR/10));
    end
    
end

%assemble the adjacency matrix
keepInd = ~isnan(adjMW(:)) & ~isnan(adjMX(:)) & ~isnan(adjMY(:)) & ~isnan(adjMmW(:));
adjMW = adjMW(keepInd);
adjMmW = adjMmW(keepInd);
adjMX = adjMX(keepInd);
adjMY = adjMY(keepInd);

%sparse matrices, based on eq 1 with the gradient,
adjMatrixW = sparse(adjMX(:),adjMY(:),adjMW(:),numel(imgNew(:)),numel(imgNew(:)));
                    % and the invert of gradient.
adjMatrixMW = sparse(adjMX(:),adjMY(:),adjMmW(:),numel(imgNew(:)),numel(imgNew(:)));

%% get shortest path 

% get layer going from dark to light
[ dist,path{1} ] = graphshortestpath( adjMatrixMW, 1, numel(imgNew(:)) );

[pathX,pathY] = ind2sub(szImgNew,path{1});

% get rid of first and last few points that is by the image borders
pathX =pathX(gradient(pathY)~=0);
pathY =pathY(gradient(pathY)~=0);

% get layer going from light to dark
[ dist2,path2{1} ] = graphshortestpath( adjMatrixW, 1, numel(imgNew(:)) );
[pathX2,pathY2] = ind2sub(szImgNew,path2{1});

% get rid of first and last few points that is by the image borders
pathX2 =pathX2(gradient(pathY2)~=0);
pathY2 =pathY2(gradient(pathY2)~=0);

%% visualize the detected boundaries, which are ilm and rpe
imagesc(imgNew); axis image; colormap('gray'); hold on;
plot(pathY,pathX,'g--','linewidth',2); hold on;
plot(pathY2,pathX2,'r--','linewidth',2); hold on;
legend({'ilm' 'rpe'});