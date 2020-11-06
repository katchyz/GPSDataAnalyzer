function [tdist, ttime, avgspeed, avgpace] = getAggKeyValues(instSpeed, instPace, cumDist, time)
%GETAGGKEYVALUES Get aggregated key values.
%   getAggKeyValues(instSpeed, instPace, cumDist, time) returns the
%   aggregated values for distance (total), time (total), speed
%   (average), pace (average) given the instantaneous values.
%
%   The length of the instantaneous vectors should be greater than 1,
%   otherwise the function will return empty sets for the aggregated
%   values.

if (size(time,1) > 1)
    tdist = cumDist(end) - cumDist(1);
    
    ttime = time(end) - time(1);
    
    avgspeed = tdist / ttime;
    
    avgpace = 1 / avgspeed * 100 / 6;
else
    tdist = [];
    ttime = [];
    avgspeed = [];
    avgpace = [];
end