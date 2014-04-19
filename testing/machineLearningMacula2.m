% %%
% # is macula detection with svm necessary?
% # why not just segment ILM and RPE for multiple b-scans
% # then detect macula based on thickness between ILM and RPE?


%% get images with macula
%clear all;close all;
folderPath = 'D:\playground\course_ImagingInformatics\Chiu_IOVS_2011\Automatic versus Manual Study\';
%folderPath = 'E:\Chiu_IOVS_2011\Automatic versus Manual Study\';
 
imageDir=dir(folderPath);
imageDirSize = [imageDir.bytes];
imageDir = imageDir(imageDirSize > 5000000);
load([folderPath imageDir(1).name]);
patientNums = numel(imageDir);

%% label image
% dataMacula = nan([patientNums size(images,3)]);
% 
% for i = 1:patientNums
%     clear imageLayer
%     imagePath = [folderPath imageDir(i).name];
%     load(imagePath);
%     
%     for j = 1:size(images,3)
%                 
%         img = images(:,:,j);
%         img = imfilter(img,fspecial('gaussian',[5 20],2),'replicate');
%         
%         rpe = manualLayers1(3,:,j);
%         ilm = manualLayers1(1,:,j);            
% 
%         imagesc(img);
%         hold on;
%         plot(1:numel(rpe),rpe);        
%         plot(1:numel(ilm),ilm);        
%         grid on;        
%         
%         [x1 y1]=ginput(1)
%         if x1 > 500
%             dataMacula(i,j) = 1;
%         end
% 
%         
%     end
%     
% end

%% extract features from images;

load('dataMacula.mat');
load('maculaLabels.mat');
retinalThickness = 200; 

dataMacula(isnan(dataMacula))=0;
d = [];
for i = 1:patientNums
    clear imageLayer
    imagePath = [folderPath imageDir(i).name];
    load(imagePath);
    i
    for j = maculaLabels.imgOI(i)%1:size(images,3)
        
        foveaInd = maculaLabels.rois(j,3):maculaLabels.rois(j,4);
        
        img = images(:,:,j);
        img = imfilter(img,fspecial('gaussian',[5 20],2),'replicate');
        
        ascanInd = find(isnan(manualLayers1(1,:,j)) ==0);                
        rpe = manualLayers1(3,ascanInd,j);
        m = manualLayers1(2,ascanInd,j);
        ilm = manualLayers1(1,ascanInd,j);
        
        rpeInd = sub2ind(size(img),rpe,ascanInd);
        mInd = sub2ind(size(img),m,ascanInd);
        ilmInd = sub2ind(size(img),ilm,ascanInd);
        
        img(rpeInd)=nan;
        img(mInd)=nan;
        img(ilmInd)=nan;
        
        y = [rpe,ilm(end:-1:1)];
        x = [ascanInd, ascanInd(end:-1:1)];                
        k = convhull(x,y);

        % area of "retinal profile + buttom line of profile"
        bwProfile = poly2mask(x, y, size(img,1), size(img,2));
        
        % area of convex hull of bwProfile
        bwConv = poly2mask(x(k), y(k), size(img,1), size(img,2));

        % get convext hull
        ascans = cell([numel(ascanInd),1]);
        for aInd = 1:numel(ascanInd)
            if aInd == 1 
                ascans{aInd}= img(bwConv(:,ascanInd(aInd+1))==1,ascanInd(aInd));
            else                
                ascans{aInd}= img(bwConv(:,ascanInd(aInd))==1,ascanInd(aInd));
            end
        end
        
        % resample
        ascansResampledCell = cellfun(@(x) resample(x,retinalThickness,numel(x)), ascans,'Uniformoutput',false);
        
        % reshape the resampled ascans.
        ascansResampled = reshape(cell2mat(ascansResampledCell),[retinalThickness numel(ascanInd)]);
                
        % perform svm on each ascans
        
        subplot(2,1,1)
        imagesc(ascansResampled);
        colormap('gray');axis image;
        
        hold on;
        foveaSignal = 180*ones([1 size(ascansResampled,2)]);
        foveaSignal(foveaInd-200)= 20;
        plot(1:size(ascansResampled,2),foveaSignal);
        drawnow;
        ginput(1);
    end
    
end



%%
% conclusion
% at the moment, false positive rate too high.