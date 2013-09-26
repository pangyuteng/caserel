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


function [adjMatrixW, adjMatrixMW, adjMAsub, adjMBsub, adjMW, adjMmW, img] = getAdjacencyMatrix(inputImg)
%
% Ouputs the adjacency matrices, and the weights and locations for building these matrices based on eq 1
% of following article with the input image 'imgOld'
%
% Chui SJ et al, Automatic segmentation of seven retinal layers in SDOCT
% images congruent with expert manual segmentation, Optics Express, 2010;18(18);19413-19428
% Section 3.1 to 3.3
% link(pubmed): http://goo.gl/Z8zsY
% link(pdf from Duke.edu): http://goo.gl/i3cJ0
%
% Usage
% Input: 'inputImg' - an image.
% Outputs: 
%   %Sparse Matrices
%   'adjMatrixW'    -  dark-to-light adjacency matrix
%   'adjMatrixMW'   - light-to-dark adjacency matrix
%   %Non zero weights in the sparse matrices
%   'adjMBsub'      - locations of the weights
%   'adjMAsub'      - locations of the weights
%   'adjMmW'        - light-to-dark weights
%   'adjMW'         - dark-to-light weights
%   'img'           - updated image with 1 column of 0s on the each verticle side of the image
%
% $Revision: 1.0 $ $Date: 2013/04/29 09:00$ $Author: Pangyu Teng $
% $Revision: 1.1 $ $Date: 2013/09/15 21:00$ $Author: Pangyu Teng $

% pad image with vertical column on both sides
szImg = size(inputImg);
img = zeros([szImg(1) szImg(2)+2]);

img(:,2:1+szImg(2)) = inputImg;

% update size of image
szImg = size(img);

% get vertical gradient image
[~,gradImg] = gradient(img,2,2);
gradImg = -1*gradImg;

% normalize gradient
gradImg = (gradImg-min(gradImg(:)))/(max(gradImg(:))-min(gradImg(:)));

% get the "invert" of the gradient image.
gradImgMinus = gradImg*-1+1; 

%% generate adjacency matrix, see equation 1 in the refered article.

%minimum weight
minWeight = 1E-5;

neighborIterX = [1 1  1 0  0 -1 -1 -1];
neighborIterY = [1 0 -1 1 -1  1  0 -1];

% get location A (in the image as indices) for each weight.
adjMAsub = 1:szImg(1)*szImg(2);

% convert adjMA to subscripts
[adjMAx,adjMAy] = ind2sub(szImg,adjMAsub);

adjMAsub = adjMAsub';
szadjMAsub = size(adjMAsub);

% prepare to obtain the 8-connected neighbors of adjMAsub
% repmat to [1,8]
neighborIterX = repmat(neighborIterX, [szadjMAsub(1),1]);
neighborIterY = repmat(neighborIterY, [szadjMAsub(1),1]);

% repmat to [8,1]
adjMAsub = repmat(adjMAsub,[1 8]);
adjMAx = repmat(adjMAx, [1 8]);
adjMAy = repmat(adjMAy, [1 8]);

% get 8-connected neighbors of adjMAsub
% adjMBx,adjMBy and adjMBsub
adjMBx = adjMAx+neighborIterX(:)';
adjMBy = adjMAy+neighborIterY(:)';

% make sure all locations are within the image.
keepInd = adjMBx > 0 & adjMBx <= szImg(1) & ...
    adjMBy > 0 & adjMBy <= szImg(2);

% adjMAx = adjMAx(keepInd);
% adjMAy = adjMAy(keepInd);
adjMAsub = adjMAsub(keepInd);
adjMBx = adjMBx(keepInd);
adjMBy = adjMBy(keepInd); 

adjMBsub = sub2ind(szImg,adjMBx(:),adjMBy(:))';

% calculate weight
adjMW = 2 - gradImg(adjMAsub(:)) - gradImg(adjMBsub(:)) + minWeight;
adjMmW = 2 - gradImgMinus(adjMAsub(:)) - gradImgMinus(adjMBsub(:)) + minWeight;

% pad minWeight on the side
imgTmp = nan(size(gradImg));
imgTmp(:,1) = 1;
imgTmp(:,end) = 1;
imageSideInd = ismember(adjMBsub,find(imgTmp(:)==1));
adjMW(imageSideInd) = minWeight;
adjMmW(imageSideInd) = minWeight;

% build sparse matrices
adjMatrixW = [];%sparse(adjMAsub(:),adjMBsub(:),adjMW(:),numel(img(:)),numel(img(:)));
% build sparse matrices with inverted gradient.
adjMatrixMW = [];%sparse(adjMAsub(:),adjMBsub(:),adjMmW(:),numel(img(:)),numel(img(:)));

% %% http://tipstrickshowtos.blogspot.com/2010/02/fast-replacement-for-sub2ind.html
% function [r,c] = ind2subSimple(sz, idx)
% 
% nrows = sz(1);
% r = rem(idx-1,nrows)+1;
% c = (idx-r)./nrows + 1;
% r = r';
% c = c';
% 
% function idx = sub2indSimple( sz, rows, cols)
% nrows = sz(1);
% idx = rows + (cols-1)*nrows;