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

excelCompiled = {};
excelLumped = {};
filename = [imagePath{1} '_octSegmentation.mat'];

load(filename);

%intitialize a vector location of the layers
layersToPlot  = {'ilm' 'nflgcl' 'iplinl' 'inlopl' 'oplonl' 'isos' 'rpe'};
for i = 1:numel(layersToPlot)
    layerCompile(i).name = layersToPlot{i};
    layerCompile(i).x = [];
end

% format the paths for analysis (get rid of uneeded 
imageLayer = formatPathsForAnalysis(imageLayer);

%% iterate through 'imageLayer(i).retinalLayers(j)'
% and save location to the corresponding vector 'layerCompile(storeInd)'

for i = 1:numel(imageLayer),

    for j = 1:numel(imageLayer(i).retinalLayers),

        %find location in layerCompile to save the new pathX
        storeInd = find( strcmpi(imageLayer(i).retinalLayers(j).name,layersToPlot) ==1);

        if ~isempty(storeInd)
            layerCompile(storeInd).x = [ layerCompile(storeInd).x imageLayer(i).retinalLayers(j).pathXAnalysis];
        end

    end % of for j = 1:numel(imageLayer(i).retinalLayers),


end % of for i = 1:numel(imageLayer),

%%
% quantify retinal layer thickness
excel = {};
layersToAnalyze = {'ilm' 'nflgcl' 'iplinl' 'inlopl' 'oplonl' 'isos' 'rpe'};

excel = [excel; {'name' 'mean' 'sd'}];
for i = 2:numel(layersToAnalyze)
    firstLayerInd = find(strcmpi(layersToAnalyze{i-1},layersToPlot)==1);
    secondLayerInd = find(strcmpi(layersToAnalyze{i},layersToPlot)==1);
    excel = [excel; {strcat( [ layersToAnalyze{i-1} ' - ' layersToAnalyze{i}] ),...
        nanmean(layerCompile(secondLayerInd).x-layerCompile(firstLayerInd).x),...
        nanstd(layerCompile(secondLayerInd).x-layerCompile(firstLayerInd).x)}];
end

% print out thickness
excel