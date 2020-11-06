function [hVelPlot, hPacePlot, hDistancePlot] = plotKeyValues(h, instSpeed, instPace, cumDist, time)
%PLOTKEYVLUES Plots velocity, pace and distance as a function of time
%   plotKeyValues(h, instSpeed, instPace, cumDist, time) plots the
%   instantaneous values for speed, pace and cumulated distance in the
%   uipanel/figure with handle h. It returns handles to the plots
%   corresponding to each of the instantaneous series.

hVelPlot = subplot(3, 1, 1, 'Parent', h);
plot(hVelPlot, time, instSpeed);
xlabel('Time');
ylabel('Inst. speed');

hPacePlot = subplot(3, 1, 2, 'Parent', h);
plot(hPacePlot, time, instPace);
xlabel('Time');
ylabel('Inst. pace');

hDistancePlot = subplot(3, 1, 3, 'Parent', h);
plot(hDistancePlot, time, cumDist);
xlabel('Time');
ylabel('Distance');

end