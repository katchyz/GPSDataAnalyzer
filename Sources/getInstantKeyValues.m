function [instSpeed, instPace, cumDist] = getInstantKeyValues(x, y, z, time)
%GETINSTANTKEYVALUES Get instant key timeseries.
%   getInstantKeyValues(x, y, z, time) returns the time series containing
%   instant values for speed, pace and cumulated distance. x, y, z and time
%   define the trajectory of the movement.
%   NOTE: expected units for x, y, z: [m]
%         expected units for time: [s]

% distance between consecutive points
distance = sqrt((x(2:end) - x(1:end-1)).^2 + ...
    (y(2:end) - y(1:end-1)).^2 + ...
    (z(2:end) - z(1:end-1)).^2);

% instantaneous velocity [m/s]
instSpeed = (distance ./ (time(2:end) - time(1:end-1)));

% instantaneous pace [min/km]
instPace = [0; ((1./instSpeed) * 100 / 6)];

instSpeed = [0; (distance ./ (time(2:end) - time(1:end-1)))];

% current total covered distance [m]
cumDist = [0; cumsum(distance)];