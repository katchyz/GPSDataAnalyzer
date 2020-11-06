function [xo, yo] = getClosestPoint(x, y, xi, yi)
%GETCLOSESTPOINT Get closest point.
%   getClosestPoint(x, y, xi, yi) returns the point from vector [xi, yi],
%   defined by [xo, yo],  which is closest to point to [x, y]

% calculate the disntace from the point of interest to all the points in
% the vector [xi, yi]
distance = sqrt((x - xi).^2 + (y - yi).^2);

% get the index of the closest point
[min_val index] = min(abs(distance));

xo = x(index);
yo = y(index);