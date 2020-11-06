function [x,y,z] = reformatData(lat, lon)
% REFORMATDATA Reformat data to Cartesian coordinates
%   reformatData(lat, lon) transforms lat, lon coordinates into carthesian
%   coordinates by considering the altitude value equal to 0.

h = 0; % height

a = 6378137; % semi major axis of earth ellipsoid [m]
f = 1/298.257223563; % flattening of ellipsoid
e_sq = f*(2-f); % eccentricity of ellipsoid
v = a./(sqrt(1-e_sq.*((sind(lat)).^2)));

x = (v+h).*cosd(lat).*cosd(lon);
y = (v+h).*cosd(lat).*sind(lon);
z = (v.*(1-e_sq)+h).*sind(lat);
