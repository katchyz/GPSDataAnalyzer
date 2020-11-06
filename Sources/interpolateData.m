function [xi, yi, zi, ti] = interpolateData(x, y, z, time, n, method)
% INTERPOLATEDATA Interpolates the route points.
% 	interpolateData(x, y, z, time, n, method) returns the interpolated
% 	trajectory given an initial trajectory. x, y, z and time define the
% 	initial trajectory. n is the number of interpolation points. method
% 	defines the method for interpolation (accepted values 'spline' or
% 	'pchip').

% take n interpolation points
tt = linspace(min(time), max(time), n)';
ti =  tt;

switch method
    case 'spline'
        xi = spline(time, x, tt);
        yi = spline(time, y, tt);
        zi = spline(time, z, tt);
    case 'pchip'
        xi = pchip(time, x, tt);
        yi = pchip(time, y, tt);
        zi = pchip(time, z, tt);
    otherwise
        error(['The ''' method ''' interpolation method is not supported']);
end