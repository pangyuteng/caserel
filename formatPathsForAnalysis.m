function imageLayer = formatPathsForAnalysis(imageLayer)

% transform the path back to orignial space (so when you plot pathY and
% pahtX on the image, it fits with the coordinates of the original image)

params = imageLayer(1).params;
blankImg=ones([numel(imageLayer(1).params.yrange) numel(imageLayer(1).params.xrange)]);

%get image size
if params.isResize(1)
    szImg = size(imresize(blankImg,params.isResize(2)));
else
    szImg = [size(blankImg)];
end

for i = 1:numel(imageLayer);
    %get info
    params =  imageLayer(i).params;

    for j = 1:numel(imageLayer(i).retinalLayers),

       
        %make sure subscript-Y is inbound image, and left shift subscript-y
        indValidPath = find(imageLayer(i).retinalLayers(j).pathY ~=1 & ...
                       imageLayer(i).retinalLayers(j).pathY ~= szImg(2)+2);
        
        pathX = imageLayer(i).retinalLayers(j).pathX(indValidPath);
        pathY = imageLayer(i).retinalLayers(j).pathY(indValidPath)-1; 
        
        %make sure subscript-ys are unique
        [uniqVal uniqInd] = unique(pathY);

        pathX = pathX(uniqInd);
        pathY = pathY(uniqInd); 

        %make sure Ys are contiguous
        pathYNew = 1:szImg(2);
        pathXNew = interp1(pathY,... %original Y
            pathX,... %original X, to be interp
            pathYNew,... %new Y
            'nearest');
        
        if params.isResize(1)

                %translate before scaling
                pathYNew = pathYNew - 1;
                pathXNew = pathXNew - 1;

                %scale back
                %built scaling matrix T
                scale = 1/params.isResize(2);
                T = [scale 0 0; 0 scale 0; 0 0 1];
                arr= [pathYNew; pathXNew; ones(size(pathY))];
                arr = T*arr;
                pathYNew = arr(1,:);
                pathXNew = arr(2,:);

                %translate after scaling
                pathYNew = pathYNew+round(scale/2);
                pathXNew = pathXNew+round(scale/2);    

                %resample, use extrap to extrap out of range subscripts.            
                imageLayer(i).retinalLayers(j).pathYAnalysis = 1:szImg(2)/params.isResize(2);        
                imageLayer(i).retinalLayers(j).pathXAnalysis = nan([1 szImg(2)/params.isResize(2)]);

                %imageLayer(i).retinalLayers(j).pathXAnalysis(params.xrange) = round(interp1(pathYNew,pathXNew,1:szImg(2)/params.isResize(2),'linear','extrap'));
                imageLayer(i).retinalLayers(j).pathXAnalysis(:) = round(interp1(pathYNew,pathXNew,1:szImg(2)/params.isResize(2),'linear','extrap'));
                

        end % of resize
    end % of j
end % of i