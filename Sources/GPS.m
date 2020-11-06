function varargout = GPS(varargin)
%GPS M-file for GPS.fig
%      GPS, by itself, creates a new GPS or raises the existing
%      singleton*.
%
%      H = GPS returns the handle to a new GPS or the handle to
%      the existing singleton*.
%
%      GPS('Property','Value',...) creates a new GPS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to GPS_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      GPS('CALLBACK') and GPS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in GPS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GPS

% Last Modified by GUIDE v2.5 18-Mar-2013 11:09:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GPS_OpeningFcn, ...
    'gui_OutputFcn',  @GPS_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GPS is made visible.
function GPS_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for GPS
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GPS wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GPS_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% read the input data
[x_new, y_new, z_new, time_new, lat_new, lon_new] = readInputData();

if (size(x_new) ~= 0)
    % update user data
    handles.x = x_new;
    handles.y = y_new;
    handles.z = z_new;
    handles.time = time_new;
    handles.lat = lat_new;
    handles.lon = lon_new;
    handles.simActive = false;
    
    % new data available - enable the disabled uicontrols
    set(handles.interpPopUp, 'Enable', 'on');
    set(handles.interpPointsText, 'Enable', 'on');
    set(handles.simulationButton, 'Enable', 'on');
    set(handles.saveButton, 'Enable', 'on');
    set(handles.exportButton, 'Enable', 'on');
    set(handles.zoomBtn, 'Enable', 'on');
    set(handles.panBtn, 'Enable', 'on');
    set(handles.resetButton, 'Enable', 'on');
    
    % by the default, the number of interpolation points should be equal to
    % the number of GPS data records - write the value in the corresponding
    % text box.
    set(handles.interpPointsText, 'String', size(handles.x, 1));
    
    % create an axes object in the route panel
    handles.routePlot = axes('Parent', handles.routePanel);
    
    % update user data
    guidata(hObject, handles);
    
    % refresh guid data
    refreshGPSRoute(hObject, handles)
else
    % nothing loaded
end


% --- Refreshes GPS data
function refreshGPSRoute(hObject, handles)
%   This function recalculates all the internal data, assuming that the GPS
%   data changed. It also fills the GRP Route plot with the appropriate
%   data.

% read the number of interpolation points
handles.interpPoints = str2double(get(handles.interpPointsText, 'String'));

% interpolate data
switch get(handles.interpPopUp, 'Value')
    case 1
        [handles.xi, handles.yi, handles.zi, handles.ti] = ...
            interpolateData(handles.x, handles.y, handles.z, handles.time, handles.interpPoints, 'spline');
    case 2
        [handles.xi, handles.yi, handles.zi, handles.ti] = ...
            interpolateData(handles.x, handles.y, handles.z, handles.time, handles.interpPoints, 'pchip');
end

% compute instant key values
[handles.instSpeed, handles.instPace, handles.cumDist] = getInstantKeyValues(handles.xi, handles.yi, handles.zi, handles.ti);

% set user data
handles.speedUp = 1;
handles.startTimeIdx = 1;
handles.endTimeIdx = size(handles.xi, 1);

% plot GPS route
[handles.hroute, handles.hPartRoute, handles.hinterp,  handles.hStartP, handles.hEndP] = ...
    plotPath(handles.routePlot, handles.x, handles.y, handles.xi, handles.yi);

% set marker constraints
setPositionConstraintFcn(handles.hStartP, @constrainStartCursorPos);
setPositionConstraintFcn(handles.hEndP, @constrainEndCursorPos);
addNewPositionCallback(handles.hStartP, @startCursorMoved_Callback);
addNewPositionCallback(handles.hEndP, @endCursorMoved_Callback);

%update user data
guidata(hObject, handles);

% reset the cursors
setConstrainedPosition(handles.hStartP, [handles.xi(1), handles.yi(1)]);
setConstrainedPosition(handles.hEndP, [handles.xi(end), handles.yi(end)]);

refreshKeyValues();


% --- Constrains the position of the start cursor
function newpos = constrainStartCursorPos(pos)
%   This function imposes the start cursor to move only on the interpolated
%   trajectory. Additionally, if a simulation is running, the user cannot
%   move the cursor.

handles = guidata(gcbo);

if handles.simActive
    if any(handles.startCursorPos ~= pos)
        % start point should not be allowed to change its position
        setConstrainedPosition(handles.hStartP, handles.startCursorPos);
    end
    
    newpos = handles.startCursorPos;
else
    [xp, yp] = getClosestPoint(handles.xi, handles.yi, pos(1), pos(2));
    newpos = [xp yp];
    handles.startCursorPos = newpos;
    guidata(gcbo, handles);
end


% --- Constrains the position of the end cursor
function newpos = constrainEndCursorPos(pos)
%   This function imposes the start cursor to move only on the interpolated
%   trajectory. 

handles = guidata(gcbo);

[xp, yp] = getClosestPoint(handles.xi, handles.yi, pos(1), pos(2));
newpos = [xp yp];

% rememeber the old position before the simulation started
if ~handles.simActive
    handles.endCursorPos = newpos;
    guidata(gcbo, handles);
end


% --- Executes when the start cursor moves 
function startCursorMoved_Callback(pos)
%   This function triggers the refresh of the key values after the start
%   cursor has moved.

handles = guidata(gcbo);

% find the point in the interpolated data
handles.startTimeIdx = find((handles.xi == pos(1)) & (handles.yi == pos(2)));

partRouteIdx = handles.startTimeIdx:handles.endTimeIdx;
set(handles.hPartRoute, 'XData', handles.xi(partRouteIdx), ...
    'YData', handles.yi(partRouteIdx));

guidata(gcbo, handles);
refreshKeyValues();


% --- Executes when the end cursor moves
function endCursorMoved_Callback(pos)
%   This function triggers the refresh of the key values after the end
%   cursor has moved.

handles = guidata(gcbo);

% find the point in the interpolated data
handles.endTimeIdx = find((handles.xi == pos(1)) & (handles.yi == pos(2)));

partRouteIdx = handles.startTimeIdx:handles.endTimeIdx;

set(handles.hPartRoute, 'XData', handles.xi(partRouteIdx), ...
    'YData', handles.yi(partRouteIdx));

guidata(gcbo, handles);
refreshKeyValues();



% --- Refreshes key values
function refreshKeyValues()
%   This function triggers the calculation of the aggregated key values. It
%   fills then the appropriate text fields with the aggregated values. It
%   also refreshes the key values plots.

handles = guidata(gcbo);

if (handles.startTimeIdx < handles.endTimeIdx)
    partRouteIdx = handles.startTimeIdx:handles.endTimeIdx;
    
    % refresh key values plots
    [handles.hVelPlot, handles.hPacePlot, handles.hDistancePlot] = ...
        plotKeyValues(handles.keyValPanel, handles.instSpeed(partRouteIdx), handles.instPace(partRouteIdx), handles.cumDist(partRouteIdx), handles.ti(partRouteIdx));
    
    % get aggregated values
    [tdist, ttime, avgspeed, avgpace] = getAggKeyValues(handles.instSpeed(partRouteIdx), handles.instPace(partRouteIdx), handles.cumDist(partRouteIdx), handles.ti(partRouteIdx));
    
    set(handles.totalTimeText, 'String', ttime);
    set(handles.totalDistText, 'String', tdist);
    set(handles.avgSpeedText, 'String', avgspeed);
    set(handles.avgPaceText, 'String', avgpace);
    
    set(handles.startTimeText, 'String', handles.ti(handles.startTimeIdx), 'ForegroundColor','k', 'BackgroundColor', 'w');
    set(handles.endTimeText, 'String', handles.ti(handles.endTimeIdx), 'ForegroundColor','k', 'BackgroundColor', 'w');
else
    %clear the axes and the text boxes
    cla(handles.hVelPlot)
    cla(handles.hPacePlot)
    cla(handles.hDistancePlot)
    
    set(handles.totalTimeText, 'String', []);
    set(handles.totalDistText, 'String', []);
    set(handles.avgSpeedText, 'String', []);
    set(handles.avgPaceText, 'String', []);
    
    set(handles.startTimeText, 'String', handles.ti(handles.startTimeIdx), 'ForegroundColor','w', 'BackgroundColor', 'r');
    set(handles.endTimeText, 'String', handles.ti(handles.endTimeIdx), 'ForegroundColor','w', 'BackgroundColor', 'r');
    
end
guidata(gcbo, handles);


% --- Executes on button press in exportButton.
function exportButton_Callback(hObject, eventdata, handles)
% hObject    handle to exportButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% create new figure to copy the axes in

[filename, pathname, filteridx] = uiputfile({'*.pdf', 'PDF (*.pdf)'; ...
    '*.jpg', 'JPEG (*,jpg)'}, 'Save route plot as');

if filename ~= 0
    hfig = figure('Visible','Off');
    haxes = axes('Parent', hfig);
    copyobj([handles.hroute, handles.hPartRoute, handles.hinterp], haxes);
    
    filepath = ['' fullfile(pathname, filename) ''];
    switch filteridx
        case 1
            print(hfig, '-dpdf', filepath);
        case 2
            print(hfig, '-djpeg', filepath);
    end
    close(hfig);
else
    % do nothing
end

[filename, pathname, filteridx] = uiputfile({'*.pdf', 'PDF (*.pdf)'; ...
    '*.jpg', 'JPEG (*,jpg)'}, 'Save key values plots as');

if filename ~= 0
    hfig = figure('Visible','Off');
    hVelPlot = subplot(3, 1, 1, 'Parent', hfig);
    hPacePlot = subplot(3, 1, 2, 'Parent', hfig);
    hDistancePlot = subplot(3, 1, 3, 'Parent', hfig);
    copyobj(get(handles.hVelPlot, 'Children'), hVelPlot);
    copyobj(get(handles.hPacePlot, 'Children'), hPacePlot);
    copyobj(get(handles.hDistancePlot, 'Children'), hDistancePlot);
    filepath = ['' fullfile(pathname, filename) ''];
    switch filteridx
        case 1
            print(hfig, '-dpdf', filepath);
        case 2
            print(hfig, '-djpeg', filepath);
    end
    close(hfig);
else
    % do nothing
end



% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

choice = questdlg(['Would you like to save the data in (x, y, z, time) format? '...
    'Choose ''No'' if you want to save it as (lat, lon, time).'], 'Yes');

switch choice
    case []
        % do nothing
    case 'Yes'
        saveData(handles.x, handles.y, handles.z, handles.time);
    case'No'
        saveData(handles.lat, handles.lon, handles.time);
    case 'Cancel'
        % do nothing
    otherwise
        % do nothing
end


% --- Executes on button press in simulationButton.
function simulationButton_Callback(hObject, eventdata, handles)
% hObject    handle to simulationButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of simulationButton

if (get(hObject, 'Value') == 1)
    
    if handles.startTimeIdx < handles.endTimeIdx
        %disable the zoom and pan buttons
        set(handles.zoomBtn, 'Enable', 'on');
        set(handles.panBtn, 'Enable', 'on');
        
        handles.simActive = true;
        guidata(hObject, handles);
        
        % set both cursors where the route starts
        setConstrainedPosition(handles.hEndP, [handles.xi(handles.startTimeIdx), handles.yi(handles.startTimeIdx)]);
        
        pause on
        
        for i = handles.startTimeIdx + 1 : handles.endTimeIdx
            % get the speedup
            switch get(get(handles.speedUpPanel, 'SelectedObject'), 'String')
                case 'x1'
                    speedUp = 1;
                case 'x2'
                    speedUp = 100;
                case 'x3'
                    speedUp = 1000;
                otherwise
                    speedUp = 1;
            end
            
            % calculate time between two positions
            pause((handles.ti(i) - handles.ti(i - 1))/speedUp);
            if get(hObject, 'Value') == 0
                break;
            end
            
            setConstrainedPosition(handles.hEndP, [handles.xi(i), handles.yi(i)]);
        end
        
        % untoggle the button
        set(hObject, 'Value', 0);
        handles.simActive = false;
        
        %reenable the zoom and pan buttons
        set(handles.zoomBtn, 'Enable', 'on');
        set(handles.panBtn, 'Enable', 'on');
        
        pause off
    else
        msgbox('Start time should be less than end time!', 'Invalid route selection')
        set(hObject, 'Value', 0);
    end
else
    handles.simActive = false;
    
    %reenable the zoom and pan buttons
    set(handles.zoomBtn, 'Enable', 'on');
    set(handles.panBtn, 'Enable', 'on');
    % set the position of the end cursor as it was before the simulation
    % started
    setConstrainedPosition(handles.hEndP, handles.endCursorPos);
end

guidata(hObject, handles);


function startTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to startTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of startTimeText as text
%        str2double(get(hObject,'String')) returns contents of startTimeText as a double


% --- Executes during object creation, after setting all properties.
function startTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function endTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to endTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of endTimeText as text
%        str2double(get(hObject,'String')) returns contents of endTimeText as a double


% --- Executes during object creation, after setting all properties.
function endTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to endTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in resetButton.
function resetButton_Callback(hObject, eventdata, handles)
% hObject    handle to resetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% reset the position of the start and finish cursors
setConstrainedPosition(handles.hStartP, [handles.xi(1), handles.yi(1)]);
setConstrainedPosition(handles.hEndP, [handles.xi(end), handles.yi(end)]);



function totalTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to totalTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of totalTimeText as text
%        str2double(get(hObject,'String')) returns contents of totalTimeText as a double


% --- Executes during object creation, after setting all properties.
function totalTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to totalTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function totalDistText_Callback(hObject, eventdata, handles)
% hObject    handle to totalDistText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of totalDistText as text
%        str2double(get(hObject,'String')) returns contents of totalDistText as a double


% --- Executes during object creation, after setting all properties.
function totalDistText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to totalDistText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function avgSpeedText_Callback(hObject, eventdata, handles)
% hObject    handle to avgSpeedText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of avgSpeedText as text
%        str2double(get(hObject,'String')) returns contents of avgSpeedText as a double


% --- Executes during object creation, after setting all properties.
function avgSpeedText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to avgSpeedText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function avgPaceText_Callback(hObject, eventdata, handles)
% hObject    handle to avgPaceText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of avgPaceText as text
%        str2double(get(hObject,'String')) returns contents of avgPaceText as a double


% --- Executes during object creation, after setting all properties.
function avgPaceText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to avgPaceText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function interpPointsText_Callback(hObject, eventdata, handles)
% hObject    handle to interpPointsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of interpPointsText as text
%        str2double(get(hObject,'String')) returns contents of interpPointsText as a double

% validity check
n = str2double(get(hObject,'String'));
if ~isnan(n)
    if n < size(handles.x, 1)
        msgbox(['The number of interpolation points can''t be less than ' num2str(size(handles.x, 1)) ' !'], 'Incorrect value');
        set(hObject, 'String', handles.interpPoints);
    else
        refreshGPSRoute(hObject, handles);
    end
else
    msgbox('The value you entered is invalid!', 'Invalid value');
    set(hObject, 'String', handles.interpPoints);
end


% --- Executes during object creation, after setting all properties.
function interpPointsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to interpPointsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in interpPopUp.
function interpPopUp_Callback(hObject, eventdata, handles)
% hObject    handle to interpPopUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns interpPopUp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from interpPopUp

refreshGPSRoute(hObject, handles);

% --- Executes during object creation, after setting all properties.
function interpPopUp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to interpPopUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in speedUpPanel.
function speedUpPanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in speedUpPanel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in zoomInBtn.
function zoomInBtn_Callback(hObject, eventdata, handles)
% hObject    handle to zoomInBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of zoomInBtn


% --- Executes on button press in zoomBtn.
function zoomBtn_Callback(hObject, eventdata, handles)
% hObject    handle to zoomBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of zoomBtn

if 1 == get(hObject, 'Value')
    % disable pan mode
    set(handles.panBtn, 'Value', 0);
    
    zoom(handles.routePlot,'on');
else
    % disable zoom mode
    zoom(handles.routePlot,'off');
end


% --- Executes on button press in panBtn.
function panBtn_Callback(hObject, eventdata, handles)
% hObject    handle to panBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of panBtn

if 1 == get(hObject, 'Value')
    % disable zoom mode
    set(handles.zoomBtn, 'Value', 0);
    
    pan(handles.routePlot,'on');
else
    % disable pan mode
    pan(handles.routePlot,'off');
end
