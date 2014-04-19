
function features = getHaarLikeFeatures(data,scales)


%scales = [0 1 2];
sampleSize = size(data,2);
intensitySize = size(data,1);

for scaleInd = 1:numel(scales)
    lut(scaleInd).zp = 1-2^(scales(scaleInd)):1+2^(scales(scaleInd));
    lut(scaleInd).gp = [2^(scales(scaleInd)) -2^(scales(scaleInd))];
end

%%
for scaleInd = 1:numel(scales)
    switch scales(scaleInd)
        case 0
            gd(scaleInd).scale = scales(scaleInd);
            gd(scaleInd).data = data;            
        otherwise
            gd(scaleInd).scale = scales(scaleInd);     
            gd(scaleInd).data = zeros(size(data));
         for j = 1:intensitySize
             validInd = j+lut(scaleInd).zp;
             validInd = validInd(validInd > 0 & validInd <= intensitySize);
             gd(scaleInd).data(j,:) = sum(data(validInd,:));
         end           
    end
end
        %%

for scaleInd = 1:numel(scales)
    switch scales(scaleInd)
        case 0
            if sampleSize
                gx=gradient(gd(scaleInd).data);            
            else
                [gx, gy]=gradient(gd(scaleInd).data);            
            end
            gd(scaleInd).gdata = gx;            
        otherwise
            gd(scaleInd).gdata = zeros(size(data));
         for j = 1:intensitySize
             validInd = j+lut(scaleInd).gp;
             %validInd = validInd(validInd > 0 & validInd <= intensitySize);
             %if numel(validInd)==2             
             %   gd(scaleInd).gdata(j,:) = gd(scaleInd).data(validInd(1),:)-gd(scaleInd).data(validInd(2),:);
             %end
             value = zeros([numel(validInd),sampleSize]);
             for ind =1:numel(validInd)
                 if validInd(ind) > 0 && validInd(ind) <= intensitySize
                     value(ind,:) = gd(scaleInd).data(validInd(ind),:);
                 else
                     value(ind,:) = zeros([1, sampleSize]);
                 end
                 gd(scaleInd).gdata(j,:) = value(1,:)-value(2,:);
             end
             
         end           
    end
end

features=[];
for scaleInd = 1:numel(scales)
    features = [features;gd(scaleInd).data;gd(scaleInd).gdata];
    %features = [features;gd(scaleInd).gdata];
end