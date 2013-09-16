function [rPaths, img] = getRetinalLayersCore(layerName,img,params,rPaths)

% this is a founction used within getRetinalLayers.m
%
%   $Created: 1.0 $ $Date: 2013/09/09 20:00$ $Author: Pangyu Teng $
%
if nargin < 3
    display('3 inputs required, getLayers.m');
    return;   
end

szImg = size(img);

switch layerName
    
    case {'roughILMandISOS'}
        
        imgOld = img(:,2:end-1);
        pathsTemp = getHyperReflectiveLayers(imgOld,params.roughILMandISOS);                 
                        
        %save to structure 
        clear rPaths
        rPaths = pathsTemp;
        
        return;        

    case {'nflgcl' 'inlopl' 'ilm' 'isos' 'oplonl' 'iplinl' 'rpe'}
        
        adjMA = params.adjMA;
        adjMB = params.adjMB;
        adjMW = params.adjMW;
        adjMmW = params.adjMmW;        
        
    case {'IF_YOU_WANT_A_SMOOTHER_EDGE_PUT_THE_LAYER_NAMES_HERE'}

        adjMA = params.adjMA;
        adjMB = params.adjMB;
        adjMW = params.adjMWSmo;
        adjMmW = params.adjMmWSmo;
        
end


% initialize region of interest
szImg = size(img);
roiImg = zeros(szImg);

% avoid the top part of image
roiImg(1:20,:) = 0;

% select region of interest based on layers priorly segmented.
for k = 2:szImg(2)-1
    
    switch layerName
        
        case {'nflgcl'}
            
            % define a region (from 'startInd' to 'endInd') between 'ilm'
            % and 'inlopl'.
            indPathX = find(rPaths(strcmp('ilm',{rPaths.name})).pathY==k);
            startInd0 = rPaths(strcmp('ilm',{rPaths.name})).pathX(indPathX(1));            
            indPathX = find(rPaths(strcmp('inlopl',{rPaths.name})).pathY==k);
            endInd0 = rPaths(strcmp('inlopl',{rPaths.name})).pathX(indPathX(1));
                        
            startInd = startInd0 - ceil(params.nflgcl_0*(endInd0-startInd0));
            endInd = endInd0 - round(params.nflgcl_1*(endInd0-startInd0));
            
        case {'rpe'}

            indPathX = find(rPaths(strcmp('isos',{rPaths.name})).pathY==k);
            
            % define a region (from 'startInd' to 'endInd') below 'isos'.
            startInd = rPaths(strcmp('isos',{rPaths.name})).pathX(indPathX(1));
            endInd = startInd+round((rPaths(strcmp('isos',{rPaths.name})).pathXmean-rPaths(strcmp('ilm',{rPaths.name})).pathXmean));

        case {'inlopl'}     
            
            % define a region (from 'startInd' to 'endInd') between 'ilm'
            % and 'isos'.
            indPathX = find(rPaths(strcmp('ilm',{rPaths.name})).pathY==k);
            startInd0 = rPaths(strcmp('ilm',{rPaths.name})).pathX(indPathX(1));
            indPathX = find(rPaths(strcmp('isos',{rPaths.name})).pathY==k);
            endInd0 = rPaths(strcmp('isos',{rPaths.name})).pathX(indPathX(1));
                                    
            startInd = startInd0+round(params.inlopl_0*(endInd0-startInd0));
            endInd = endInd0-round(params.inlopl_1*(endInd0-startInd0));            
            
        case {'ilm'}
            
            % define a region (from 'startInd' to 'endInd') near 'ilm'.
            indPathX = find(rPaths(strcmp('ilm',{rPaths.name})).pathY==k);
                        
            startInd = rPaths(strcmp('ilm',{rPaths.name})).pathX(indPathX(1)) - params.ilm_0; 
            endInd = rPaths(strcmp('ilm',{rPaths.name})).pathX(indPathX(1)) + params.ilm_1;             
            
        case {'isos'}            
            
            % define a region (from 'startInd' to 'endInd') near 'isos'.
            indPathX = find(rPaths(strcmp('isos',{rPaths.name})).pathY==k);            
            
            startInd = rPaths(strcmp('isos',{rPaths.name})).pathX(indPathX(1)) - params.isos_0; 
            endInd = rPaths(strcmp('isos',{rPaths.name})).pathX(indPathX(1)) + params.isos_1;             
            
        case {'iplinl'}

            % define a region (from 'startInd' to 'endInd') between
            % 'nflgcl' and 'inlopl'.
            indPathX = find(rPaths(strcmp('nflgcl',{rPaths.name})).pathY==k);
            startInd0 = rPaths(strcmp('nflgcl',{rPaths.name})).pathX(indPathX(1));
            indPathX = find(rPaths(strcmp('inlopl',{rPaths.name})).pathY==k);
            endInd0 = rPaths(strcmp('inlopl',{rPaths.name})).pathX(indPathX(1));
            
            startInd = startInd0 + round(params.iplinl_0*(endInd0-startInd0));
            endInd = endInd0 - round(params.iplinl_1*(endInd0-startInd0));
            
            
        case {'oplonl'}
                        
            % define a region (from 'startInd' to 'endInd') between
            % 'inlopl' and 'isos'.
            indPathX = find(rPaths(strcmp('inlopl',{rPaths.name})).pathY==k);
            startInd0 = rPaths(strcmp('inlopl',{rPaths.name})).pathX(indPathX(1));
            indPathX = find(rPaths(strcmp('isos',{rPaths.name})).pathY==k);
            endInd0 = rPaths(strcmp('isos',{rPaths.name})).pathX(indPathX(1));
                        
%           startInd = startInd0 + params.oplonl_0;
%           endInd = endInd0 - params.oplonl_1;
            startInd = startInd0 +round(params.oplonl_0*(endInd0-startInd0));
            endInd = endInd0 -round(params.oplonl_1*(endInd0-startInd0));
    end
    
    %error checking    
    if startInd > endInd
        startInd = endInd - 1;
    end            
    
    if startInd < 1
        startInd = 1;
    end
    
    if endInd > szImg(1)
        endInd = szImg(1);
    end
                    
    % set region of interest at column k from startInd to endInd
    roiImg(startInd:endInd,k) = 1;
    
end

%ensure the 1st and last column is part of the region of interest.
roiImg(:,1)=1;
roiImg(:,end)=1;            

% include only region of interst in the adjacency matrix
includeA = ismember(adjMA, find(roiImg(:) == 1));
includeB = ismember(adjMB, find(roiImg(:) == 1));
keepInd = includeA & includeB;

%     %alternative to ismember, 
%     roiImgOne = find(roiImg(:) == 1)';
%     includeA = sum(bsxfun(@eq,adjMA(:),roiImgOne),2);
%     includeB = sum(bsxfun(@eq,adjMB(:),roiImgOne),2);
%     keepInd = includeA & includeB;

%get the shortestpath
switch layerName
    %bright to dark
    case {'rpe' 'nflgcl' 'oplonl' 'iplinl' }
        adjMatrixW = sparse(adjMA(keepInd),adjMB(keepInd),adjMW(keepInd),numel(img(:)),numel(img(:)));    
        [ dist( 1 ), path{1} ] = graphshortestpath( adjMatrixW, 1, numel(img(:)) );
    %dark to bright
    case {'inlopl' 'ilm' 'isos' }
        adjMatrixMW = sparse(adjMA(keepInd),adjMB(keepInd),adjMmW(keepInd),numel(img(:)),numel(img(:)));    
        [ dist( 1 ), path{1} ] = graphshortestpath( adjMatrixMW, 1, numel(img(:)) );        
end

%convert path indices to subscript
[pathX, pathY] = ind2sub(szImg,path{1});

%if name layer existed, overwrite it, else add layer info to struct
matchedLayers = strcmpi(layerName,{rPaths(:).name});
layerToPlotInd = find(matchedLayers == 1);
if isempty(layerToPlotInd)    
    layerToPlotInd = numel(rPaths)+1;
    rPaths(layerToPlotInd).path = path{1};
    rPaths(layerToPlotInd).pathX = pathX;
    rPaths(layerToPlotInd).pathY = pathY;
    rPaths(layerToPlotInd).pathXmean = mean(rPaths(layerToPlotInd).pathX(gradient(rPaths(layerToPlotInd).pathY)~=0));
    rPaths(layerToPlotInd).name = layerName;
else
    rPaths(layerToPlotInd).path = path{1};
    rPaths(layerToPlotInd).pathX = pathX;
    rPaths(layerToPlotInd).pathY = pathY;
    rPaths(layerToPlotInd).pathXmean = mean(rPaths(layerToPlotInd).pathX(gradient(rPaths(layerToPlotInd).pathY)~=0));
end

%create an additional smoother layer for rpe
isSmoothRpe = 1;
if isSmoothRpe,
    switch layerName
        case {'rpe'}       

            %find lines where pathY is on the image
            rpePathInd = gradient(pathY) ~= 0;

            % fit line with cubic smoothing spline
            lambda = 1E-6; %small means really smooth
            pathXpoly = pathX;
            pathYpoly = pathY;

            [pathXpoly(rpePathInd), ~] = csaps(pathY(rpePathInd),pathX(rpePathInd),...
               lambda,pathY(rpePathInd));               

            %add layer info to struct
            layerToPlotInd = numel(rPaths)+1;
            rPaths(layerToPlotInd).name = 'rpeSmooth';
            rPaths(layerToPlotInd).pathX = round(pathXpoly);
            rPaths(layerToPlotInd).pathY = round(pathYpoly);            
            rPaths(layerToPlotInd).path = sub2ind(szImg,rPaths(layerToPlotInd).pathX,rPaths(layerToPlotInd).pathY);
            rPaths(layerToPlotInd).pathXmean = mean(rPaths(layerToPlotInd).pathX(gradient(rPaths(layerToPlotInd).pathY)~=0));            

        otherwise
    end
end