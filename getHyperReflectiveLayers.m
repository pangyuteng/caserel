function paths = getHyperReflectiveLayers(inputImg,constants)
%$Revision: 1.1 $ $Date: 2013/09/15 21:00$ $Author: Pangyu Teng $

if nargin < 1
    display('requires at least 1 input (findHyperReflectiveZones.m)');
    return;
end

if nargin == 1
    %initiate parameters
    constants.shrinkScale = 0.2;
    constants.offsets = -20:20;
end

isPlot = 0;

%shrink the image.
szImg = size(inputImg);
procImg = imresize(inputImg,constants.shrinkScale,'bilinear');

%create adjacency matrices
[adjMatrixW, adjMatrixMW, adjMX, adjMY, adjMW, adjMmW, newImg] = getAdjacencyMatrix(procImg);

%create roi for getting shortestest path based on gradient-Y image.
[gx, gy] = gradient(newImg);
szImgNew = size(newImg);
roiImg = zeros(szImgNew);
roiImg(gy > mean(gy(:))) =1 ;

% find at least 2 layers
path{1} = 1;
count = 1;
while ~isempty(path) && count <= 2

    %add columns of one at both ends of images
    roiImg(:,1)=1;
    roiImg(:,end)=1;
    
    % include only region of interst in the adjacency matrix
    includeX = ismember(adjMX, find(roiImg(:) == 1));
    includeY = ismember(adjMY, find(roiImg(:) == 1));
    keepInd = includeX & includeY;
    
    % compile adjacency matrix
    adjMatrix = sparse(adjMX(keepInd),adjMY(keepInd),adjMmW(keepInd),numel(newImg(:)),numel(newImg(:)));
    
    % get layer going from dark to light        
    [ dist,path{1} ] = graphshortestpath( adjMatrix, 1, numel(newImg(:)));
    
    if ~isempty(path{1})
                        
        % get rid of first few points and last few points
        [pathX,pathY] = ind2sub(szImgNew,path{1});        

        pathX = pathX(gradient(pathY)~=0);
        pathY = pathY(gradient(pathY)~=0);
        
        %block the obtained path and abit around it
        pathXArr = repmat(pathX,numel(constants.offsets));
        pathYArr = repmat(pathY,numel(constants.offsets));
        for i = 1:numel(constants.offsets)
            pathYArr(i,:) = pathYArr(i,:)+constants.offsets(i);
        end
        
        pathXArr = pathXArr(pathYArr > 0 & pathYArr <= szImgNew(2));
        pathYArr = pathYArr(pathYArr > 0 & pathYArr <= szImgNew(2));
        
        pathArr = sub2ind(szImgNew,pathXArr,pathYArr);
        roiImg(pathArr) = 0;
        
        paths(count).pathX = pathX;
        paths(count).pathY = pathY;

        if isPlot;
            subplot(1,3,1);
            imagesc(inputImg);
            subplot(1,3,2);
            imagesc(gy);        
            subplot(1,3,3);
            imagesc(roiImg);
            drawnow;
            pause;
        end
        
    end % of ~empty
    count = count + 1;
end


if ~exist('paths','var')
    paths = {};
    keyboard;
    return;
end % if exist

%format paths back to original size
for i = 1:numel(paths)    
    [paths(i).path, paths(i).pathY, paths(i).pathX] = resizePath(szImg, szImgNew, constants, paths(i).pathY, paths(i).pathX);    
    paths(i).pathXmean = nanmean(paths(i).pathX);
    paths(i).name = [];
    
end

%name each path (numel(paths) should equal to 2)
if numel(paths) ~= 2
    paths = {};
    display('error');
    return;
end

%based on the mean location detemine the layer type.
if paths(1).pathXmean < paths(2).pathXmean
    paths(1).name = 'ilm';
    paths(2).name = 'isos';
else
    paths(1).name = 'isos';    
    paths(2).name = 'ilm';    
end


if isPlot;
    imagesc(inputImg);
    axis image; colormap('gray');
    hold on;
    for i = 1:numel(paths)
        cola = rand(1,3);
        plot(paths(i).pathY,paths(i).pathX,'r-','linewidth',3);
        text(paths(i).pathY(end),paths(i).pathX(end)-15,paths(i).name,'color',rand(1,3));
        drawnow;
    end
    hold off;
end

