
function we = weightedEfficiency(avgCap, refCap, avgTime, refTime)
%WEIGHTEDEFFICIENCY Calculate weighted efficiency.
% 70% capacity performance and 30% time performance.

we = 0.7*(avgCap/refCap) + ...
     0.3*((refTime - avgTime)/refTime);

end
