function varargout = octSegmentationGUI(varargin)

% OCTSEGMENTATIONGUI MATLAB code for octSegmentationGUI.fig
%      OCTSEGMENTATIONGUI, by itself, creates a new OCTSEGMENTATIONGUI or raises the existing
%      singleton*.
%
%      H = OCTSEGMENTATIONGUI returns the handle to a new OCTSEGMENTATIONGUI or the handle to
%      the existing singleton*.
%
%      OCTSEGMENTATIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OCTSEGMENTATIONGUI.M with the given input arguments.
%
%      OCTSEGMENTATIONGUI('Property','Value',...) creates a new OCTSEGMENTATIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before octSegmentationGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to octSegmentationGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help octSegmentationGUI

% Last Modified by GUIDE v2.5 09-Sep-2013 22:00:39
% $Revision: 1.1 $ $Date: 2013/09/15 21:00$ $Author: Pangyu Teng $

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




% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @octSegmentationGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @octSegmentationGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
               
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

%6666666666666===================
if length(varargin)< 1,
    display('needs 1 parameter! (octSegmentationGUI.m)');
    return;
end
%9999999999999===================


if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before octSegmentationGUI is made visible.
function octSegmentationGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to octSegmentationGUI (see VARARGIN)

% Choose default command line output for octSegmentationGUI
%69% handles.output = hObject;

%6666666666666===================

handles.output = handles.octSegmentationGUI_figure;

% initiate stuff
handles.layersToPlot =  {'ilm' 'isos' 'rpe' 'inlopl' 'nflgcl' 'iplinl' 'oplonl' 'rpeSmooth'};
handles.proceed = 0; %when exiting
handles.isUpdateLayer = 0; %for resegmentation
handles.isShowLayer = 1; %for resegmentation
handles.pathsTemp = [];

% get input filepath
handles.filePath = varargin{1};

% load file
tempLoaded=load(handles.filePath);
handles.imageLayer=tempLoaded.imageLayer;
clear tempLoaded;

% create figure;
handles.figureOCT = figure;
set(handles.figureOCT,'Name','oct image', ...
           'Position',[50 100 512 512], ...
           'NumberTitle','off', ...
           'Color','w', ...
           'Resize','on', ...
           'MenuBar','none');

       

handles.imgInd = 1;
handles.selectedLayer = nan;

handles.errorMsg = '';
handles.imgRange = [0 255];
handles.figureOCTh = [];

handles = updateDisplay(handles);
handles = updateMaterials(handles);

figure(handles.octSegmentationGUI_figure);


%9999999999999===================

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes octSegmentationGUI wait for user response (see UIRESUME)
uiwait(handles.octSegmentationGUI_figure);


function handles = updateMaterials(handles)
    %create rois
    for newRoisInd = 1:numel({handles.imageLayer(handles.imgInd).retinalLayers.name})
        handles.newRois{newRoisInd} = zeros(handles.szImg,'uint8');
    end

% --- Outputs from this function are returned to the command line.
function varargout = octSegmentationGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

%69%varargout{1} = handles.output;
%6666666666666===================
varargout{1} = handles.octSegmentationGUI_figure;
guiParam.figureOCT = handles.figureOCT;
guiParam.proceed = handles.proceed;
varargout{2} = guiParam;

display('outputFcn');
%9999999999999===================

% --- Executes on selection change in listboxLayerName.
function listboxLayerName_Callback(hObject, eventdata, handles)
% hObject    handle to listboxLayerName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxLayerName contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxLayerName

%get list
contents = cellstr(get(hObject,'String'));
%get selected item
index_selected_str = contents{get(hObject,'Value')};
handles.selectedLayer = get(hObject,'Value');

pathY = handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathY;
pathX = handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathX;
params = handles.imageLayer(handles.imgInd).params;

newRoi = handles.newRois{handles.selectedLayer};
if ~sum(newRoi(:))
    %block the obtained layer in the roi image.
    for k = 2:handles.szImg(2)-1
        indPathX = find(pathY==k);
        startInd = pathX(indPathX) - params.smallIncre;%#*2;
        endInd = pathX(indPathX) + params.smallIncre;%#*2;
        if startInd < 1
            startInd = 1;
        end
        if endInd > handles.szImg(1)
            endInd = handles.szImg(1);
        end
        newRoi(startInd:endInd,k) = 1;
    end
    newRoi(:,1)=1;
    newRoi(:,end)=1;
    handles.newRois{handles.selectedLayer} = newRoi;
end

%update display
handles = updateDisplay(handles);

%show roi
handles = updateDisplayROI(handles);

%refocus to main window
figure(handles.octSegmentationGUI_figure);

%guidata
guidata(hObject, handles);




function handles = updateDisplayROI(handles)


redImg = cat(3, ones(handles.szImg), zeros(handles.szImg), zeros(handles.szImg));

figure(handles.figureOCT);
hold on;
handles.figureOCTh = imshow(redImg);
hold off;

set(handles.figureOCTh, 'AlphaData', double(handles.newRois{handles.selectedLayer}).*0.25);


% --- Executes during object creation, after setting all properties.
function listboxLayerName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxLayerName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in checkboxSmooth.
function checkboxSmooth_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSmooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSmooth


% --- Executes on button press in pushbuttonPrevious.
function pushbuttonPrevious_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPrevious (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%previous image
handles.imgInd = handles.imgInd - 1;

if handles.imgInd < 1 
    handles.imgInd = 1;
    handles.errorMsg = '!';
elseif handles.imgInd > numel(handles.imageLayer)
    handles.imgInd = numel(handles.imageLayer);
    handles.errorMsg = '!';
else
    handles.errorMsg = '';
    handles.selectedLayer = nan;
    handles = updateMaterials(handles);
    handles.isShowLayer = 1;    
end

%show image
handles = updateDisplay(handles);
%refocus to main window
figure(handles.octSegmentationGUI_figure);

%guidata
guidata(hObject, handles);

% --- Executes on button press in pushbuttonNext.
function pushbuttonNext_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonNext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%next image
handles.imgInd = handles.imgInd + 1;

if handles.imgInd < 1 
    handles.imgInd = 1;
    handles.errorMsg = '!';
elseif handles.imgInd > numel(handles.imageLayer)
    handles.imgInd = numel(handles.imageLayer);
    handles.errorMsg = '!';
else
    handles.errorMsg = '';
    handles.selectedLayer = nan;
    handles = updateMaterials(handles); 
    handles.isShowLayer = 1;
end


%show image
handles =updateDisplay(handles);
%refocus to main window
figure(handles.octSegmentationGUI_figure);

%guidata
guidata(hObject, handles);



function handles = updateDisplay(handles)

figure(handles.figureOCT);
hold off;

%get stuff from handles for plotting images
retinalLayers = handles.imageLayer(handles.imgInd).retinalLayers;
params = handles.imageLayer(handles.imgInd).params;

%imgPath = [params.folderPath params.strImgNum '.tif'];
imgPath = handles.imageLayer(handles.imgInd).imagePath;


images=imread(imgPath);
img = double(images(params.yrange,params.xrange,1));

%resize image.
if isfield(params,'isResize')
    if params.isResize(1)
        img = imresize(img,params.isResize(2),'bilinear');
    end
end

handles.imgNew = [zeros([size(img,1),1]) img zeros([size(img,1),1])];
handles.szImg = size(handles.imgNew);

handles.figureOCTh = imshow(handles.imgNew,handles.imgRange(:));axis image;colormap('gray');


slashInd = strfind(handles.filePath,'\');
title(sprintf('%s, image %d of %d, %s',handles.filePath(slashInd(end-1):slashInd(end)),...
    handles.imgInd,numel(handles.imageLayer),handles.errorMsg));
hold on;

%layersToPlot = {retinalLayers(:).name};
layersToPlot = handles.layersToPlot;
if handles.isShowLayer
for k = 1:numel(layersToPlot)
    matchedLayers = strcmpi(layersToPlot{k},{retinalLayers(:).name});
    
    %if layer is resegment, show new layer or else show olde layers
    isPlotNewLayer = 0;
    if handles.isUpdateLayer
          if strcmp(layersToPlot{k},handles.pathsTemp.name)
              isPlotNewLayer = 1;
          end
    end
    
    if ~isPlotNewLayer,
        layerToPlotInd = find(matchedLayers == 1);
        if ~isempty(retinalLayers(layerToPlotInd))
            if ~isempty(retinalLayers(layerToPlotInd).pathX)
                colora = params.colorarr(k,:);        
                plot(retinalLayers(layerToPlotInd).pathY,retinalLayers(layerToPlotInd).pathX,'-','color',colora,'linewidth',2);
                plotInd = round(numel(retinalLayers(layerToPlotInd).pathX)/2);
                text(retinalLayers(layerToPlotInd).pathY(plotInd),retinalLayers(layerToPlotInd).pathX(plotInd)+params.txtOffset,retinalLayers(layerToPlotInd).name,'color',colora,'linewidth',2);
            end
        end
    
    else
        if ~isempty(handles.pathsTemp)
            colora = params.colorarr(k,:);        
            plot(handles.pathsTemp.pathY,handles.pathsTemp.pathX,'-','color',colora,'linewidth',2);
            plotInd = round(numel(handles.pathsTemp.pathX)/2);
            text(handles.pathsTemp.pathY(plotInd),handles.pathsTemp.pathX(plotInd)+params.txtOffset,handles.pathsTemp.name,'color',colora,'linewidth',2);
        end                
        handles.isUpdateLayer = 0;
        
    end %of if ~isPloatNewLayer
end %of k
end % of if handles.isShowLayer

drawnow;
hold off;


%update list 
set(handles.listboxLayerName,'String',{handles.imageLayer(handles.imgInd).retinalLayers.name});

% --- Executes on button press in pushbuttonExit.
function pushbuttonExit_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonExit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%6666666666666===================


%folderPath = handles.imageLayer(handles.imgInd).params.folderPath;
imageLayer = handles.imageLayer;
% Handle response
choice = questdlg('Save and Exit?', 'Alert', 'SaveAndExit','Exit','Resume','Resume');

switch choice
    
    case 'SaveAndExit'        
        handles.proceed = 1;                
        
        save(handles.filePath, 'imageLayer');
                
        display('file successfully saved');
        % Resume execution
        uiresume;
    case 'Exit'        
        handles.proceed = 1;
        % Resume execution
        uiresume;
    case 'Resume'        
        handles.proceed = 0;
end

guidata(hObject, handles);
%9999999999999===================


% --- Executes on button press in pushbuttonResegment.
function pushbuttonResegment_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonResegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%6666666666666===================
if ~isnan(handles.selectedLayer)
    
newRoi = handles.newRois{handles.selectedLayer};
newRoi(:,1)=1;
newRoi(:,end)=1;
retinalLayerName = handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).name;

img = handles.imgNew;
params = handles.imageLayer(handles.imgInd).params;

display('wait for a while, calculating adjacency matrices...');
if get(handles.checkboxSmooth,'Value'),
    img = imfilter(img,fspecial('gaussian',params.filterParams(1:2),params.filterParams(3)),'replicate');
    [adjMatrixW, adjMatrixMW, adjMX, adjMY, adjMW, adjMmW, ~] = getAdjacencyMatrix(img);
else
    [adjMatrixW, adjMatrixMW, adjMX, adjMY, adjMW, adjMmW, ~] = getAdjacencyMatrix(img);
end     

% include only region of interst in the adjacency matrix
includeX = ismember(adjMX, find(newRoi(:) == 1));
includeY = ismember(adjMY, find(newRoi(:) == 1));
keepInd = includeX & includeY;


display('wait for a while, calculating shortest path...');
switch retinalLayerName
    
    case {'rpe' 'nflgcl' 'oplonl' 'iplinl'} %{'rpe' 'nflipl'}
        adjMatrixW = sparse(adjMX(keepInd),adjMY(keepInd),adjMW(keepInd),numel(img(:)),numel(img(:)));    
        [ dist( 1 ), path{1} ] = graphshortestpath( adjMatrixW, 1, numel(img(:)) );                
    
    case {'inlopl' 'ilm' 'isos'}
        adjMatrixMW = sparse(adjMX(keepInd),adjMY(keepInd),adjMmW(keepInd),numel(img(:)),numel(img(:)));
        [ dist( 1 ), path{1} ] = graphshortestpath( adjMatrixMW, 1, numel(img(:)) );        
end


[pathX, pathY] = ind2sub(handles.szImg,path{1});
handles.pathsTemp.path = path{1};
handles.pathsTemp.pathX = pathX;
handles.pathsTemp.pathY = pathY;
handles.pathsTemp.pathXmean = mean(handles.pathsTemp.pathX(gradient(handles.pathsTemp.pathY)~=0));
handles.pathsTemp.name = retinalLayerName;
handles.isUpdateLayer = 1;
        
handles = updateDisplay(handles);

% Handle response
choice = questdlg('Keep new segmentation?', 'Alert', 'yes','no','no');

switch choice
    case 'yes'
        handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).path = handles.pathsTemp.path;
        handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathX = handles.pathsTemp.pathX;
        handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathY = handles.pathsTemp.pathY;
        handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathXmean = handles.pathsTemp.pathXmean;
    case 'no'

        %update display
        handles = updateDisplay(handles);

        %show roi
        handles = updateDisplayROI(handles);

        %refocus to main window
        figure(handles.octSegmentationGUI_figure);
end

else
    display('select a layer first');
end % of if ~isnan(handles.selectedLayer)
guidata(hObject, handles);
%9999999999999===================


% --- Executes on button press in pushbuttonSelectROI.
function pushbuttonSelectROI_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSelectROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isnan(handles.selectedLayer)
    
%get roi
newRoi = handles.newRois{handles.selectedLayer};

%draw revisions
figure(handles.figureOCT);
revisedRoi = roipoly;

%if out selected
if get(handles.radiobuttonIn,'Value')
    newRoi(revisedRoi == 1) = 1;
else
    newRoi(revisedRoi == 1) = 0;
end

%update roi
handles.newRois{handles.selectedLayer} = newRoi;

%show image
handles =updateDisplay(handles);
handles = updateDisplayROI(handles);

%refocus to main window
figure(handles.octSegmentationGUI_figure);

else
    display('select a layer first');
end%if ~isnan(handles.selectedLayer)
    
%guidata
guidata(hObject, handles);



% --- Executes on button press in pushbuttonAutoMagicMarker.
function pushbuttonAutoMagicMarker_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAutoMagicMarker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isnan(handles.selectedLayer)
    %get roi
    newRoi = handles.newRois{handles.selectedLayer};

    %imfreehand revisions
    figure(handles.figureOCT);
    h = imfreehand;
    position = wait(h);
    
    pathX = round(position(:,2));
    pathY = round(position(:,1));    
    
    %make sure subscript-Y is inbound image
    indValidPath = find(pathY >= 1 & pathY <= handles.szImg(2));
    pathX = pathX(indValidPath);
    pathY = pathY(indValidPath); 
    
    %make sure subscript-ys are unique
    [uniqVal uniqInd] = unique(pathY);
    pathX = pathX(uniqInd);
    pathY = pathY(uniqInd); 
    
    %sort subscript-ys
    [sortVal sortInd] = sort(pathY,'ascend');
    pathX = pathX(sortInd);
    pathY =  pathY(sortInd);
    
    %interp
    pathYNew = round(min(pathY):max(pathY));
    pathXNew = round(interp1(pathY,... %original Y
        pathX,... %original X, to be interp
        pathYNew,... %new Y
        'nearest'));
    
    %revise roi
    for i = 1:numel(pathYNew)
        %if position is inbound image
        if i >= 1 && i <= handles.szImg(2)
        newRoi(:,pathYNew(i)) = 0;
        startInd = pathXNew(i) - handles.imageLayer(handles.imgInd).params.smallIncre;
        endInd = pathXNew(i)+ handles.imageLayer(handles.imgInd).params.smallIncre;
        if startInd < 1
            startInd = 1;
        end
        if endInd > handles.szImg(1)
            endInd = handles.szImg(1);
        end   
        newRoi(startInd:endInd,pathYNew(i)) = 1;
        end % of if position(i,1) >= 1 &&...
    end

    %update roi
    handles.newRois{handles.selectedLayer} = newRoi;

%guidata
guidata(hObject, handles);
    
    %update newRoi
    pushbuttonResegment_Callback(hObject, eventdata, handles);

    %refocus to main window
    figure(handles.octSegmentationGUI_figure);
else
    display('select a layer first');

%guidata
guidata(hObject, handles);
    
end% if ~isnan(handles.selectedLayer)



%6666666666666===================
%9999999999999===================
%uiwait(handles.octSegmentationGUI_figure)
%uiresume
%figure(handles.octSegmentationGUI_figure);


% --- Executes on button press in pushbuttonToggleLayer.
function pushbuttonToggleLayer_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonToggleLayer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%flip the switch
if handles.isShowLayer == 1,
    %update display
    handles.isShowLayer = 0;
    handles = updateDisplay(handles);    
else
    handles.isShowLayer = 1;
    handles = updateDisplay(handles);    
end
%guidata
guidata(hObject, handles);


% --- Executes on button press in pushbuttonManualSegButton.
function pushbuttonManualSegButton_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonManualSegButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if ~isnan(handles.selectedLayer)
    %get roi
    newRoi = handles.newRois{handles.selectedLayer};

    %imfreehand revisions
    figure(handles.figureOCT);
    h = imfreehand;
    position = wait(h);
    
    pathX = round(position(:,2));
    pathY = round(position(:,1));    
    
    %make sure subscript-Y is inbound image
    indValidPath = find(pathY >= 1 & pathY <= handles.szImg(2));
    pathX = pathX(indValidPath);
    pathY = pathY(indValidPath); 
    
    %make sure subscript-ys are unique
    [uniqVal uniqInd] = unique(pathY);
    pathX = pathX(uniqInd);
    pathY = pathY(uniqInd); 
    
    %sort subscript-ys
    [sortVal sortInd] = sort(pathY,'ascend');
    pathX = pathX(sortInd);
    pathY =  pathY(sortInd);
    
    %interp
    pathYNew = round(min(pathY):max(pathY));
    pathXNew = round(interp1(pathY,... %original Y
        pathX,... %original X, to be interp
        pathYNew,... %new Y
        'nearest'));
    
    pathXOriginal = handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathX;
    pathYOriginal = handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathY;    
    
    %revise path
    for i = 1:numel(pathYNew)        
        
        %if position is inbound image
        if pathYNew(i) >= 1 && pathYNew(i) <= handles.szImg(2)            
            pathXOriginal(pathYOriginal == pathYNew(i)) = pathXNew(i);
        end % of if position(i,1) >= 1 &&...
    end

    %update roi
    handles.newRois{handles.selectedLayer} = newRoi;
        
%#$
handles.pathsTemp.path = sub2ind(handles.szImg,pathX,pathY);
handles.pathsTemp.pathX = pathXOriginal;
handles.pathsTemp.pathY = pathYOriginal;
handles.pathsTemp.pathXmean = mean(handles.pathsTemp.pathX(gradient(handles.pathsTemp.pathY)~=0));
handles.pathsTemp.name = handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).name;
handles.isUpdateLayer = 1;
        
handles = updateDisplay(handles);

% Handle response
choice = questdlg('Keep new segmentation?', 'Alert', 'yes','no','no');

switch choice
    case 'yes'
        handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).path = handles.pathsTemp.path;
        handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathX = handles.pathsTemp.pathX;
        handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathY = handles.pathsTemp.pathY;
        handles.imageLayer(handles.imgInd).retinalLayers(handles.selectedLayer).pathXmean = handles.pathsTemp.pathXmean;
    case 'no'

        %update display
        handles = updateDisplay(handles);

        %show roi
        handles = updateDisplayROI(handles);

        %refocus to main window
        figure(handles.octSegmentationGUI_figure);
end

    %refocus to main window
    figure(handles.octSegmentationGUI_figure);
else
    display('select a layer first');
    
end% if ~isnan(handles.selectedLayer)

%guidata
guidata(hObject, handles);

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
edit1text = str2num(get(hObject,'String'));
if ~isempty(edit1text);
	handles.imageLayer(handles.imgInd).params.smallIncre = round(edit1text);
else
    set(hObject,'String',num2str(handles.imageLayer(handles.imgInd).params.smallIncre));
end


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

 
