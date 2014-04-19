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
        
        % estimated total retinal thickness
        rt = median(abs(rpe-ilm));
        
        % get data above and below ilm for half of that
        halfOfRt = round(rt/4);                
        croppedImg = zeros([halfOfRt*2+1,numel(ascanInd)]);
        for k = 1:numel(ascanInd)
            croppedImg(:,k) = img(ilm(k)-halfOfRt:ilm(k)+halfOfRt,ascanInd(k));
        end
        
        gaboredImgs = gaborTransform(croppedImg);        
        
        szG = size(gaboredImgs);
        
        gaboredImgs = reshape(gaboredImgs,[szG(1) szG(2) prod(szG(3:end))]);
        features = gaboredImgs(halfOfRt,:,:);        
        features = permute(features,[3 2 1]);
                        
        fovea = zeros(size(ascanInd));
        fovea(foveaInd-ascanInd(1)) = 1;
        
        dataset(i).fovea = fovea;
        dataset(i).subject = i*ones(size(ascanInd));
        dataset(i).feature = features;

        subplot(2,1,1)
        imagesc(croppedImg);
%         hold on;plot(foveaInd-ascanInd(1),feature1(foveaInd-ascanInd(1)),'r-');
%         hold off
%         subplot(2,1,2)
%         plot(feature2);
%         hold on;plot(foveaInd-ascanInd(1),feature2(foveaInd),'r-');
%         hold off;
%         ginput(1);
        
drawnow;

    end
    
end


%%
%% create features;

features = [dataset(:).feature]';
fovea = [dataset(:).fovea]';
ansa = fovea;
subjects = [dataset(:).subject];
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
        
        classifier = 'glm'; % 'knn';%   'adaboost';% %'svm'; % 
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

return;
%%

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
        rpe = manualLayers1(3,ascanInd,j);
        m = manualLayers1(2,ascanInd,j);
        ilm = manualLayers1(1,ascanInd,j);
        
        rpeInd = sub2ind(size(img),rpe,ascanInd);
        mInd = sub2ind(size(img),m,ascanInd);
        ilmInd = sub2ind(size(img),ilm,ascanInd);
        
        % estimated total retinal thickness
        rt = median(abs(rpe-ilm));
        
        % get data above and below ilm for half of that
        halfOfRt = round(rt/4);                
        croppedImg = zeros([halfOfRt*2+1,numel(ascanInd)]);
        for k = 1:numel(ascanInd)
            croppedImg(:,k) = img(ilm(k)-halfOfRt:ilm(k)+halfOfRt,ascanInd(k));
        end
        
        gaboredImgs = gaborTransform(croppedImg);        
        
        szG = size(gaboredImgs);
        
        gaboredImgs = reshape(gaboredImgs,[szG(1) szG(2) prod(szG(3:end))]);
        features = gaboredImgs(halfOfRt,:,:);        
        features = permute(features,[3 2 1]);
        
        fovea = zeros(size(ascanInd));      
        

        for k = 1:numel(ascanInd)
            fovea(k) = glmval(b,features(:,k)','logit');
        end

        subplot(2,1,1)
        imagesc(img);
         colormap('gray'); hold on;
        plot(manualLayers1(1,:,j));
        plot(manualLayers1(3,:,j));
        hold off;
        subplot(2,1,2)
        plot(ascanInd,fovea);
        hold on;
        plot(ascanInd,round(fovea),'r--','linewidth',3);
        axis([0 1000 -0.5 1.5]);
        drawnow;
        hold off;
        %ginput(1);

    end
    
end