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


function [retinalLayers, params] = getRetinalLayers(img,params)
%%
%
% Caserel - Computer-Aided SEgmentation of REtinal Layers in
%           optical coherence tomography images
% 
% The aim of this project, caserel`, is to build an open-source software
% suite for computer-aided segmentation and analysis of retinal layers in
% optical coherence tomography images.
% 
% This project is at its infancy stage. Currently, the software supports 
% segmentation of 6 retinal layers by automatically delineating 7 boundaries
% (ILM, NFL/GCL, IPL/INL, INL/OPL, OPL/ONL, IS/OS,RPE). An image
% browser/editor is provided for manual or semi-automated correction of the 
% segmented retinal boundaries. The segmentation algorithms used are based 
% on graph-theory and is written in Matlab. You will need Matlab to execute 
% this software.
% 
% `How to pronounce CASeReL? say is like casserole.
%%
%
% [retinalLayers params] = getRetinalLayers(img,params)
% identifies the boundaries between retinal layeres given an optical 
% coherence tomography image, 'img'.
% 
% The method for identification of these retinal layer boundaries is
% based on graph theory.
% 
% $Created: 1.0 $ $Date: 2013/09/09 20:00$ $Author: Pangyu Teng $
% $Revision: 1.1 $ $Date: 2013/09/15 21:00$ $Author: Pangyu Teng $
%%

if nargin < 1
    display('requires 1 input');
    return;
end

%initialize constants
if nargin < 2        
    
    % resize the image if 1st value set to 'true',
    % with the second value to be the scale.
    params.isResize = [true 0.5];
    
    % parameter for smothing the images.
    params.filter0Params = [5 5 1];
    params.filterParams = [20 20 2];           
        
    % constants used for defining the region for segmentation of individual layer
    params.roughILMandISOS.shrinkScale = 0.2;
    params.roughILMandISOS.offsets = -20:20;    
    params.ilm_0 = 4;
    params.ilm_1 = 4;
    params.isos_0 = 4;
    params.isos_1 = 4;
    params.rpe_0 = 0.05;
    params.rpe_1 = 0.05;
    params.inlopl_0 = 0.1; %   0.4;%
    params.inlopl_1 = 0.3; %   0.5;%  
    params.nflgcl_0 = 0.05;%  0.01;
    params.nflgcl_1 = 0.3; %   0.1;
    params.iplinl_0 = 0.6;
    params.iplinl_1 = 0.2;
    params.oplonl_0 = 0.05;%4;
    params.oplonl_1 = 0.5;%4;    
        
    % parameters for ploting
    params.txtOffset = -7;
    colorarr=colormap('jet'); 
    params.colorarr=colorarr(64:-8:1,:);
    
    % a constant (not used in this function, used in 'octSegmentationGUI.m'.)
    params.smallIncre = 2;    
    
end

%clear up matlab's mind
clear retinalLayers

%get image size
szImg = size(img);

%resize image.
if params.isResize(1)
    img = imresize(img,params.isResize(2),'bilinear');
end

%smooth image with specified kernels
%for denosing
img = imfilter(img,fspecial('gaussian',params.filter0Params(1:2),params.filter0Params(3)),'replicate');        

%for a very smooth image, a "broad stroke" of the image
imgSmo = imfilter(img,fspecial('gaussian',params.filterParams(1:2),params.filterParams(3)),'replicate');

% create adjacency matrices and its elements base on the image.
[params.adjMatrixW, params.adjMatrixMW, params.adjMA, params.adjMB, params.adjMW, params.adjMmW, imgNew] = getAdjacencyMatrix(img);

% % [this is not used as the moment] Create adjacency matrices and its elements based on the smoothed image.
% [params.adjMatrixWSmo, params.adjMatrixMWSmo, params.adjMA, params.adjMB, params.adjMWSmo, params.adjMmWSmo, ~] = getAdjacencyMatrix(imgSmo);

% obtain rough segmentation of the ilm and isos, then find the retinal
% layers in the order of 'retinalLayerSegmentationOrder'
%%vvvvvvvvvvvvvvvDO  NOT  CHANGE BELOW LINE (ORDER OF LAYERS SHALL NOT BE CHANGED)vvvvvvvvvvvvvv%%
retinalLayerSegmentationOrder = {'roughILMandISOS' 'ilm' 'isos' 'rpe' 'inlopl' 'nflgcl' 'iplinl' 'oplonl'};
%%^^^^^^^^^^^^^^^DO  NOT  CHANGE ABOVE LINE (ORDER OF LAYERS SHOULD NOT BE CHANGED)^^^^^^^^^^^^^%%
% segment retinal layers
retinalLayers = [];
for layerInd = 1:numel(retinalLayerSegmentationOrder)        
    [retinalLayers, ~] = getRetinalLayersCore(retinalLayerSegmentationOrder{layerInd},imgNew,params,retinalLayers);
end

%delete elements of the adjacency matrices prior function exit to save memory
toBeDeleted = {'adjMatrixWSmo' 'adjMatrixMWSmo' 'adjMWSmo' 'adjMmWSmo'  'adjMW' 'adjMmW' 'adjMatrixW' 'adjMatrixMW' 'adjMA' 'adjMB'};
for delInd = 1:numel(toBeDeleted)
    params.(toBeDeleted{delInd}) = [];
end


% plot oct image and the obtained retinal layers.
isPlot = 1;
if isPlot,

    imagesc(img);
    axis image; colormap('gray'); hold on; drawnow;

    layersToPlot = {'ilm' 'isos' 'rpe' 'inlopl' 'nflgcl' 'iplinl' 'oplonl'};% 'rpeSmooth'}; %
    hOffset =       [40    0      40    0        0        40       -40      -40]; % for displaying text
    for k = 1:numel(layersToPlot)

        matchedLayers = strcmpi(layersToPlot{k},{retinalLayers(:).name});
        layerToPlotInd = find(matchedLayers == 1);

        if ~isempty(retinalLayers(layerToPlotInd).pathX)            
            colora = params.colorarr(k,:);
            plot(retinalLayers(layerToPlotInd).pathY,retinalLayers(layerToPlotInd).pathX-1,'--','color',colora,'linewidth',1.5);
            plotInd = round(numel(retinalLayers(layerToPlotInd).pathX)/2);            
            text(retinalLayers(layerToPlotInd).pathY(plotInd)+hOffset(k),retinalLayers(layerToPlotInd).pathX(plotInd)+params.txtOffset,retinalLayers(layerToPlotInd).name,'color',colora,'linewidth',2);            
            drawnow;
        end % of if ~isempty            

    end % of k
    hold off;

end % of isPlot        
