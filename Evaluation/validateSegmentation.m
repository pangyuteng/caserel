%% load data
close all;clear all;clc;
folderPath = 'D:\playground\course_ImagingInformatics\Chiu_IOVS_2011\Automatic versus Manual Study\';
%folderPath = 'P:\oct_images\';
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

%validate
%% iterate through 'imageLayer(i).retinalLayers(j)'
% and save location to the corresponding vector 'layerCompile(storeInd)'

imgCount = 1;

for p = 1: numel(imageDir);
    
    clear imageLayer
    imagePath = [folderPath imageDir(p).name];
    load(imagePath);        
    load([imagePath '_octSegmentation.mat']);    
    
    %format paths for analysis
    imageLayer = formatPathsForAnalysis(imageLayer);
        
    for i = 1:numel(imageLayer),        
        
        for j = 1:numel(imageLayer(i).retinalLayers),

            %find location in layerCompile to save the new pathX
            storeInd = find( strcmpi(imageLayer(i).retinalLayers(j).name,layersToPlot) ==1);

            if ~isempty(storeInd)
                layerCompile(storeInd).x = [ layerCompile(storeInd).x imageLayer(i).retinalLayers(j).pathXAnalysis];
            end

        end % of for j = 1:numel(imageLayer(i).retinalLayers),

    rpeInd = find(strcmpi({imageLayer(i).retinalLayers(:).name},'rpe')==1);
    ilmInd = find(strcmpi({imageLayer(i).retinalLayers(:).name},'ilm')==1);

    validInd = 200:800;
    layerDiff(imgCount,1) = nanmean(abs(squeeze(automaticLayers(1,validInd,i))-imageLayer(i).retinalLayers(ilmInd).pathXAnalysis(1:601)));
    layerDiff(imgCount,2) = nanstd(abs(automaticLayers(1,validInd,i)-imageLayer(i).retinalLayers(ilmInd).pathXAnalysis(1:601)));
    layerDiff(imgCount,3) = nanmean(abs(squeeze(automaticLayers(3,validInd,i))-imageLayer(i).retinalLayers(rpeInd).pathXAnalysis(1:601)));
    layerDiff(imgCount,4) = nanstd(abs(automaticLayers(3,validInd,i)-imageLayer(i).retinalLayers(rpeInd).pathXAnalysis(1:601)));
    imgCount = imgCount+1;

    plot(squeeze(automaticLayers(1,:,i))); hold on;
    plot(squeeze(automaticLayers(3,:,i)));
    plot(200+imageLayer(i).retinalLayers(ilmInd).pathYAnalysis,imageLayer(i).retinalLayers(ilmInd).pathXAnalysis,'r-');
    plot(200+imageLayer(i).retinalLayers(rpeInd).pathYAnalysis,imageLayer(i).retinalLayers(rpeInd).pathXAnalysis,'r-');    
    hold off;
    drawnow;
    %pause;


    end % of for i = 1:numel(imageLayer),

end % of p


%%
badSegInd = find(layerDiff(:,1) >= 10 | layerDiff(:,3) >= 10);
goodSegInd = find(layerDiff(:,1) < 10 & layerDiff(:,3) < 10);
[numel(badSegInd), numel(goodSegInd), numel(badSegInd) + numel(goodSegInd)]
[mean(layerDiff(goodSegInd,1)),mean(layerDiff(goodSegInd,2)),mean(layerDiff(goodSegInd,3)),mean(layerDiff(goodSegInd,4))]
