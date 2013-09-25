%% load data
close all;clear all;clc;
folderPath = 'D:\playground\course_ImagingInformatics\Chiu_IOVS_2011\Automatic versus Manual Study\';

imageDir=dir(folderPath);
imageDirSize = [imageDir.bytes];
imageDir = imageDir(imageDirSize >  233020);

patientNums = numel(imageDir);

%intitialize a vector location of the layers
layersToPlot  = {'ilm' 'nflgcl' 'iplinl' 'inlopl' 'oplonl' 'isos' 'rpe'};
for i = 1:numel(layersToPlot)
    layerCompile(i).name = layersToPlot{i};
    layerCompile(i).x = [];
end

p = 1;
imagePath = [folderPath imageDir(p).name];
load(imagePath);        
load([imagePath '_octSegmentation.mat']);
params = imageLayer(1).params;

blankImg=ones([numel(imageLayer(1).params.yrange) numel(imageLayer(1).params.xrange)]);
%shorten the pathx and pathy
if params.isResize(1)
    szImg = size(imresize(blankImg,params.isResize(2)));
else
    szImg = [size(blankImg)];
end


%validate
%% iterate through 'imageLayer(i).retinalLayers(j)'
% and save location to the corresponding vector 'layerCompile(storeInd)'

imgCount = 1;

for p = 1: numel(imageDir);
    
    clear imageLayer
    imagePath = [folderPath imageDir(p).name];
    load(imagePath);        
    load([imagePath '_octSegmentation.mat']);

    
for i = 1:numel(imageLayer),

    params =  imageLayer(i).params;

    for j = 1:numel(imageLayer(i).retinalLayers),

        indValidPath = find(imageLayer(i).retinalLayers(j).pathY ~=1 & ...
                       imageLayer(i).retinalLayers(j).pathY ~= szImg(2)+2);

        %make sure subscript-Y is inbound image, and left shift subscript-y
        imageLayer(i).retinalLayers(j).pathX = imageLayer(i).retinalLayers(j).pathX(indValidPath);
        imageLayer(i).retinalLayers(j).pathY = imageLayer(i).retinalLayers(j).pathY(indValidPath)-1; 

        %make sure subscript-ys are unique
        [uniqVal uniqInd] = unique(imageLayer(i).retinalLayers(j).pathY);

        imageLayer(i).retinalLayers(j).pathX = imageLayer(i).retinalLayers(j).pathX(uniqInd);
        imageLayer(i).retinalLayers(j).pathY = imageLayer(i).retinalLayers(j).pathY(uniqInd); 

        %make sure Ys are contiguous
        imageLayer(i).retinalLayers(j).pathYNew = 1:szImg(2);
        imageLayer(i).retinalLayers(j).pathXNew = interp1(imageLayer(i).retinalLayers(j).pathY,... %original Y
            imageLayer(i).retinalLayers(j).pathX,... %original X, to be interp
            1:szImg(2),... %new Y
            'nearest');
        
    if params.isResize(1)

            %translate before scaling
            pathY = imageLayer(i).retinalLayers(j).pathYNew - 1;
            pathX = imageLayer(i).retinalLayers(j).pathXNew - 1;

            %scale back
            %built scaling matrix T
            scale = 1/params.isResize(2);
            T = [scale 0 0; 0 scale 0; 0 0 1];
            arr= [pathY; pathX; ones(size(pathY))];
            arr = T*arr;
            pathY = arr(1,:);
            pathX = arr(2,:);

            %translate after scaling
            pathY = pathY+round(scale/2);
            pathX = pathX+round(scale/2);    

            %resample, use extrap to extrap out of range subscripts.            
            imageLayer(i).retinalLayers(j).pathYNew = 1:1000;%1:szImg(2)/params.isResize(2);        
            imageLayer(i).retinalLayers(j).pathXNew = nan([1 1000]);
            imageLayer(i).retinalLayers(j).pathXNew(200:801) = round(interp1(pathY,pathX,1:szImg(2)/params.isResize(2),'linear','extrap'));

    end    
        
        %find location in layerCompile to save the new pathX
        storeInd = find( strcmpi(imageLayer(i).retinalLayers(j).name,layersToPlot) ==1);

        if ~isempty(storeInd)
            layerCompile(storeInd).x = [ layerCompile(storeInd).x imageLayer(i).retinalLayers(j).pathXNew];
        end

    end % of for j = 1:numel(imageLayer(i).retinalLayers),

rpeInd = find(strcmpi({imageLayer(i).retinalLayers(:).name},'rpe')==1);
ilmInd = find(strcmpi({imageLayer(i).retinalLayers(:).name},'ilm')==1);

layerDiff(imgCount,1) = nanmean(abs(squeeze(automaticLayers(1,:,i))-imageLayer(i).retinalLayers(ilmInd).pathXNew));
layerDiff(imgCount,2) = nanstd(abs(automaticLayers(1,:,i)-imageLayer(i).retinalLayers(ilmInd).pathXNew));
layerDiff(imgCount,3) = nanmean(abs(squeeze(automaticLayers(3,:,i))-imageLayer(i).retinalLayers(rpeInd).pathXNew));
layerDiff(imgCount,4) = nanstd(abs(automaticLayers(3,:,i)-imageLayer(i).retinalLayers(rpeInd).pathXNew));
imgCount = imgCount+1;

plot(squeeze(automaticLayers(1,:,i))); hold on;
plot(squeeze(automaticLayers(3,:,i)));
plot(imageLayer(i).retinalLayers(ilmInd).pathYNew,imageLayer(i).retinalLayers(ilmInd).pathXNew,'r-');
plot(imageLayer(i).retinalLayers(rpeInd).pathYNew,imageLayer(i).retinalLayers(rpeInd).pathXNew,'r-');    
hold off;
drawnow;
%pause;


end % of for i = 1:numel(imageLayer),

end % of p


%%
badSegInd = find(layerDiff(:,1) >= 50 | layerDiff(:,3) >= 10);
goodSegInd = find(layerDiff(:,1) < 50 & layerDiff(:,3)<10);
[numel(badSegInd), numel(goodSegInd), numel(badSegInd) + numel(goodSegInd)]
[mean(layerDiff(goodSegInd,1)),mean(layerDiff(goodSegInd,2)),mean(layerDiff(goodSegInd,3)),mean(layerDiff(goodSegInd,4))]
