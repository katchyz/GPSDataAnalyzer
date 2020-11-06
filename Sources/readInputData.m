function [x, y, z, time, lat, lon] = readInputData()
% READINPUTDATA Reads data from a file
%   readInputData() reads the data from a file. The file is to be selected
%   via a standard dialog box. The accepted file types are *.txt, *.mat,
%   *.csv. The input files must have the following predefined structures:
%       *.csv & *.txt: 3 values per row, representing latitude, longitute
%       and time values.
%       *.mat files: containing the (x, y, z, time) or (lat, lon, time)
%       variables.
%
%   If the input data is in the latitude, longitude this function converts
%   it into x, y, z coordinates.

[filename, pathname, filterindex] = uigetfile(...
    {'*.txt', 'Text files (*.txt)';...
    '*.mat', 'MAT files (*.mat)';...
    '*.csv', 'Comma separated spreadsheet file (*.csv)'});

% check if the cancel button was pressed
if (filename == 0)
    % return empty arrays
    x = [];
    y = [];
    z = [];
    time = [];
    lat = [];
    lon = [];
else
    filepath = fullfile(pathname, filename);
    
    switch filterindex
        case 1 || 3 % txt files || csv files
            data = importdata(filepath);
            lat = data(:, 1);
            lon = data(:, 2);
            time = data(:, 3);
            [x, y, z] = reformatData(lat, lon);
        case 2 % mat files
            data = load(filepath);
            % determine how many fields are there in the structure
            % this is an indication of the .mat file format
            % 3 fields => (lat, lon, time)
            % 4 fields => (x, y, z, time)
            fields = fieldnames(data);
            switch size(fields, 1)
                case 3
                    lat = data.lat;
                    lon = data.lon;
                    [x, y, z] = reformatData(lat, lon);
                    time = data.time;
                case 4
                    x = data.x;
                    y = data.y;
                    z = data.z;
                    time = data.time;
                    lat = [];
                    lon = [];
                otherwise
                    error(['UnexpectedNumberOfFields', 'A *.mat file can only contain '...
                        '3 or 4 fields!']);
            end
        otherwise
            error('UnsupportedFileType', 'The chosen file extension is not supported.');
    end
end
