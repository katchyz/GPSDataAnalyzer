function [ ] = saveData(varargin)
% SAVEDATA Save data to file.
%   saveData(varargin) saves data to a *.mat file. The data to be saved
%   defines a trajectory in (latitude, longitude, time) or (x, y, z, time)
%   formats.

[filename, pathname] = uiputfile('output.mat');

if filename ~= 0
    switch size(varargin,2)
        case 3
            lat = varargin{1}; lon = varargin{2}; time = varargin{3};
            save(fullfile(pathname,filename), 'lat', 'lon', 'time');
            
        case 4
            x = varargin{1}; y = varargin{2}; z = varargin{3}; time = varargin{4};
            save(fullfile(pathname,filename), 'x', 'y', 'z', 'time');
        otherwise
            disp('Incorrect input arguments!')
    end
else
    % do nothing
end