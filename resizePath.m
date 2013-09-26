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


function [path, pathY, pathX] = resizePath(szImg, szImgNew, constants, pathY, pathX)

if nargin < 5
    display('requires 5 inputs');
    return;
end
    

%delete paths outside of original image;
pathX = pathX(pathY > 1 & pathY < szImgNew(2));
pathY = pathY(pathY > 1 & pathY < szImgNew(2));

%sort paths
[sortVal sortInd] = sort(pathY,'ascend');
pathX = pathX(sortInd);
pathY = pathY(sortInd)-1; %update subscriptY

%ensure paths are unique
[uniqVal uniqInd] =unique(pathY);
pathY = pathY(uniqInd);
pathX = pathX(uniqInd);

%translate before scaling
pathY = pathY-1;
pathX = pathX-1;

%scale back
%built scaling matrix T
scale = 1/constants.shrinkScale;
T = [scale 0 0; 0 scale 0; 0 0 1];
arr= [pathY; pathX; ones(size(pathY))];
arr = T*arr;
pathY = arr(1,:);
pathX = arr(2,:);

%translate after scaling
pathY = pathY+round(scale/2);
pathX = pathX+round(scale/2);    

%resample, use extrap to extrap out of range subscripts.
pathX = round(interp1(pathY,pathX,1:szImg(2),'linear','extrap'));
pathY = 1:szImg(2);    

%add front and back segments, so to be compatible with other
%structures.
startSegmentX = 1:pathX(1);
endSegmentX = pathX(end):szImg(1);
startSegmentY = ones([1 numel(startSegmentX)]);
endSegmentY = szImg(2).*ones([1 numel(endSegmentX)]);
pathX = [startSegmentX pathX endSegmentX];
pathY = [startSegmentY pathY+1 endSegmentY];

szImg(2) = szImg(2)+2;
%get indices
path = sub2ind(szImg,pathX,pathY);