function [hroute, hPartRoute, hinterp, hp1, hp2] = plotPath(h, x, y, xi, yi)
%PLOTPATH Plot GPS path/route.
%   plotPath(h, x, y, xi, yi) plots, on the axes with handle h, the
%   trajectories defined by x, y (original) and xi, yi (interpolated).
%   It also creates two markers (impoints) placed at the beginnig and at the
%   end of the interpolated trajectory.
%   Output arguments:
%       hroute: handle to the lineseries defined by the original trajectory
%       hPartRoute: handle to the lineseries defined by the points between
%       the start and end markers
%       hinterp: handle to the lineserios defined by the points on the
%       interpolated trajectory
%       hp1: handle to the start marker
%       hp2: handle to the end marker

lineseries = plot(h, xi, yi, xi, yi, x, y);
hroute = lineseries(3);
hinterp = lineseries(2);
hPartRoute = lineseries(1);
set(hroute, 'Color', 'k', 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 6);
set(hinterp, 'Color', 'k', 'LineStyle', '-');
set(hPartRoute, 'Color', 1/255 * [240 190 166], 'LineStyle', '-', 'LineWidth', 6);

% create two draggable points used to set the partial route
hp1 = impoint(h, xi(1), yi(1));
hp2 = impoint(h, xi(end), yi(end));
setColor(hp1, 'r');
setString(hp1, 'S');
setColor(hp2, 'b');
setString(hp2, 'F');
