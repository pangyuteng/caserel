% %%
% # is macula detection with svm necessary?
% # why not just segment ILM and RPE for multiple b-scans
% # then detect macula based on thickness between ILM and RPE?


%% get images with macula
clear all;close all;
folderPath = 'D:\playground\course_ImagingInformatics\Chiu_IOVS_2011\Automatic versus Manual Study\';
%folderPath = 'E:\Chiu_IOVS_2011\Automatic versus Manual Study\';

imageDir=dir(folderPath);
imageDirSize = [imageDir.bytes];
imageDir = imageDir(imageDirSize > 5000000);
load([folderPath imageDir(1).name]);
patientNums = numel(imageDir);


%%
isSelectImages = 0;
if isSelectImages,
imgOI = zeros([patientNums 1]);
for i = 1:patientNums
    
    clear imageLayer
    imagePath = [folderPath imageDir(i).name];
    load(imagePath);
    
    for j = 1:size(images,3)
        imagesc(images(:,:,j));
        title(sprintf('%d,%d',j,size(images,3)));
        drawnow;
        [x y] = ginput(1);
        if x < 900
            imgOI(i) = j
            break;
        end
    end

end

%maculaLabels.imgOI = imgOI;
%save 'maculaLabels.mat' maculaLabels
end % of save image


%% label macula and non macula
isLabelImage = 0;
if isLabelImage
load('maculaLabels.mat');
for i = 1:patientNums
    
    clear imageLayer
    imagePath = [folderPath imageDir(i).name];
    load(imagePath);
    
    img = images(:,:,maculaLabels.imgOI(i));
    img = imfilter(img,fspecial('gaussian',[5 20],2),'replicate');
    imagesc(img); axis image; colormap('gray');
    %hold on;
    %plot(1:size(manualLayers1,2),manualLayers1(1,:,maculaLabels.imgOI(i)),'linewidth',2);
    %plot(1:size(manualLayers1,2),manualLayers1(3,:,maculaLabels.imgOI(i)),'linewidth',2);
    
    [crop, rect] = imcrop;
    maculasLabels.rois(i,:) = round([rect(1)-rect(3)-30 rect(1)-30 rect(1),rect(1)+rect(3)]);

end

%save 'maculaLabels.mat' maculaLabels
end % if isLabelImage

%% browse through
isFormatData = 1;
if isFormatData    
load('maculaLabels.mat');
retinalThickness = 10;
cMaxT = 1.2;
dataInd = 1;
for i = 1:patientNums
    
    clear imageLayer
    imagePath = [folderPath imageDir(i).name];
    load(imagePath);
    
    img = images(:,:,maculaLabels.imgOI(i));
    img = imfilter(img,fspecial('gaussian',[5 20],2),'replicate');

%     subplot(1,2,1)
%     imagesc(img(:,maculaLabels.rois(i,1):maculaLabels.rois(i,2)));
%     axis image; colormap('gray');
%     hold on;
%     plot(manualLayers1(1,maculaLabels.rois(i,1):maculaLabels.rois(i,2),maculaLabels.imgOI(i)));
%     plot(manualLayers1(3,maculaLabels.rois(i,1):maculaLabels.rois(i,2),maculaLabels.imgOI(i)));
%     hold off;
%     
%     subplot(1,2,2)
%     imagesc(img(:,maculaLabels.rois(i,3):maculaLabels.rois(i,4)));
%     axis image; colormap('gray');
%     hold on;
%     plot(manualLayers1(1,maculaLabels.rois(i,3):maculaLabels.rois(i,4),maculaLabels.imgOI(i)));
%     plot(manualLayers1(3,maculaLabels.rois(i,3):maculaLabels.rois(i,4),maculaLabels.imgOI(i)));    
%     hold off;
%     
%     drawnow;
%     ginput(1);
    
   
    
    for k = 1:2
        
        if k == 1
            range = maculaLabels.rois(i,1):maculaLabels.rois(i,2);
            isMacula = 0;
        else
            range = maculaLabels.rois(i,3):maculaLabels.rois(i,4);
            isMacula = 1;
        end
        
        %ilm = manualLayers1(1,range,maculaLabels.imgOI(i));
        rpe = manualLayers1(3,range,maculaLabels.imgOI(i));
        maxT = nanmax(manualLayers1(3,:,maculaLabels.imgOI(i))-manualLayers1(1,:,maculaLabels.imgOI(i)));
        maxT = floor(cMaxT*maxT);
        ilm = rpe - maxT.*ones(size(rpe))+1;
               
        for j = 1:numel(range)
            if ~isnan(ilm(j))
            dataset(dataInd).patient = i;
            dataset(dataInd).imgNum = maculaLabels.imgOI(i);
            dataset(dataInd).macula = isMacula;
            signal = nanmean(img(ilm(j):rpe(j),range(j)-1:range(j)+1),2);
            minSig = min(signal);
            maxSig = max(signal);
            signal = (signal-minSig)./(maxSig-minSig);
            signal = resample(signal,retinalThickness,numel(signal));        
            dataset(dataInd).signal = signal;        
            dataInd = dataInd + 1;        
            end
        end
    end
    
end % for i = 1:patientNums
%     c = 0;
%     for i = 1%1:numel(dataset)
%         if dataset(i).macula,
%             subplot(1,2,1)
%             plot(dataset(i).signal); hold on;
%         else
%             subplot(1,2,2)
%             plot(dataset(i).signal); hold on;        
%         end
%         drawnow;
%         c = c+1;
%         if c == 100
%             c= 0 ;        
%             hold off;
%         end
%     end

end % of formatdata


%% create features;

data=reshape([dataset(:).signal],[numel(dataset(1).signal),numel(dataset)]);
scales = [0 1 2];
features = getHaarLikeFeatures2(data,scales);
features = features';
macula = [dataset(:).macula];
ansa = macula';
subjects = [dataset(:).patient];
subjectUnique = unique(subjects);
%subjects = crossvalind('Kfold', numel(ansa), 20);

%%  train and classify, with leave one subject out.
sensitivity = [];
specificity = [];

for j = 1:numel(subjectUnique)
    
    trainingInd = find( subjects ~= subjectUnique(j));    
    testingInd = find( subjects == subjectUnique(j));
    
    %for i =  1:numel(tharr)-1, %1:1, % 
        
        progressStr = sprintf('progress: %d/%d',j,numel(subjectUnique) );
        display(progressStr);         
        
        %try
        
        classifier = 'glm'; %   'adaboost';% 'knn';% %'svm'; % 
        switch classifier
            case 'glm'
                
               b = glmfit(features(trainingInd,:),ansa(trainingInd),'binomial');  
               % logistic regression
               C = glmval(b,features(testingInd,:),'logit');
               C = round(C);
                
            case 'knn'
                C = knnclassify(features(testingInd,:),features(trainingInd,:),ansa(trainingInd),50,'euclidean');
                
            case 'svm'            
                
                svmStruct = svmtrain(features(trainingInd,:),ansa(trainingInd),...
                    'autoscale','true',...                
                    'kernel_function', 'rbf'...%'linear'... %'polynomial'...%'mlp'...%
                    );

                Ctraining = svmclassify(svmStruct,features(trainingInd,:));
                tp = sum(Ctraining==1 & ansa(trainingInd) ==1);
                fn = sum(Ctraining==0 & ansa(trainingInd) ==1);
                tn = sum(Ctraining==0 & ansa(trainingInd) ==0);
                fp = sum(Ctraining==1 & ansa(trainingInd) ==0);
                display(sprintf('sesa %1.2f,spec %1.2f', tp/(tp+fn),tn/(tn+fp)));

                C = svmclassify(svmStruct,features(testingInd,:));
            case 'adaboost'

                 % Use Adaboost to make a classifier
                  [classestimate,model]=adaboost('train',features(trainingInd,:),ansa(trainingInd),50);
                   C=adaboost('apply',features(testingInd,:),model);
        end
        

        %#% sensitivity = TP/(TP+FN);
        %#% specificity = TN/(TN+FP);
        tp = sum(C==1 & ansa(testingInd) ==1);
        fn = sum(C==0 & ansa(testingInd) ==1);
        tn = sum(C==0 & ansa(testingInd) ==0);
        fp = sum(C==1 & ansa(testingInd) ==0);
               
        sensitivity = [sensitivity tp/(tp+fn)]; %true positive rate
        specificity = [specificity tn/(tn+fp)]; %true negative rate
               
        currentStatus = sprintf('%d, sensitivity:%1.2f , specificity:%1.2f',j,sensitivity(end),specificity(end));
        display(currentStatus);

        
        plot(1-specificity,sensitivity,'ro'); hold on;
        axis([0 1 0 1]);grid on;
        xlabel('FPR or 1-specificity');ylabel('TPR or sensitivity');
        drawnow;
       
%     catch ME
%         
%         sensitivity = [sensitivity NaN]; %true positive rate
%         specificity = [specificity NaN]; %true negative rate
%         
%     end                         
%    end % of i
end % of j


% save 'glmfitMacula.mat' b
%% calculate auc
[fprSort fprSortInd]=sort([1-specificity],'ascend');
auc = trapz([0 fprSort 1],[0 sensitivity(fprSortInd) 1]);
% aucArr(q) = auc;

% plot roc
plot(1-specificity,sensitivity,'ro'); hold on;
%plot(mean(reshape(1-specificity,[i,j]),2),mean(reshape(sensitivity,[i,j]),2),':','color',[0.8 0.8 0.8]);
axis([0 1 0 1]);grid on;
xlabel('FPR or 1-specificity');ylabel('TPR or sensitivity');
title(sprintf('auc: %1.2f',auc));

%% actul testing
%load('glmfitMacula.mat');
for i = 1:patientNums
    clear imageLayer
    imagePath = [folderPath imageDir(i).name];
    load(imagePath);
    
%     for l = 1%
%         j = maculaLabels.imgOI(i);
    for j = 1:size(images,3)
                
        img = images(:,:,j);
        img = imfilter(img,fspecial('gaussian',[5 20],2),'replicate');
        
        ascanInd = find(isnan(manualLayers1(1,:,j)) ==0);
        prctMacula = nan(size(manualLayers1(1,:,j)));
%         profile on
        

        rpe = manualLayers1(3,ascanInd,j);
        maxT = max(manualLayers1(3,ascanInd,j)-manualLayers1(1,ascanInd,j));
        maxT = floor(cMaxT*maxT);
        ilm = rpe - maxT.*ones(size(rpe))+1;
        

        
        
        is2dTest = 1;
        if is2dTest == 0

            for k = 1:numel(ascanInd)
                signal = img(manualLayers1(1,ascanInd(k),j):manualLayers1(3,ascanInd(k),j),ascanInd(k));
                minSig = min(signal);
                maxSig = max(signal);
                signal = (signal-minSig)./(maxSig-minSig);
                signal = resample(signal,retinalThickness,numel(signal));        
                features = getHaarLikeFeatures2(signal,scales);
                prctMacula(ascanInd(k)) = glmval(b,features','logit');
            end
    %         profile viewer;
    %         return;
            subplot(2,1,1)
            imagesc(img);
             colormap('gray'); hold on;
            plot(manualLayers1(1,:,j));
            plot(manualLayers1(3,:,j));
            hold off;
            subplot(2,1,2)
            plot(prctMacula);
            hold on;
            plot(round(prctMacula),'r--','linewidth',3);
            axis([0 1000 -0.5 1.5]);
            drawnow;
            hold off;
            %ginput(1);
        else
            
        
        rpe = manualLayers1(3,ascanInd,j);
        ilm = manualLayers1(1,ascanInd,j);            
        y = rpe-ilm;
        x = 1:numel(y);
        k = convhull(x,y);
        plot(x(k),y(k),'r-',x,y,'b+');
        hold on;
        plot(x(k),y(k),'ro');
        drawnow; hold off;
        ginput(1);
%             testImage = zeros([maxT numel(ascanInd)]);
%             %2-d macula detection?
%             for k = 1:numel(ascanInd)
%                 testImage(:,k) = images(ilm(k):rpe(k),ascanInd(k),j);            
%             end
%             imagesc(testImage);
%             colormap('gray');axis image;
%             drawnow;
%             ginput(1);
        end
        
    end
    
end



%%
% conclusion
% at the moment, false positive rate too high.