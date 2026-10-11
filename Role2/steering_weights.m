function weights = steering_weights(array, f, azimuthDeg, elevationDeg)
%STEERING_WEIGHTS Return phased-array steering weights.
%
% Input:
%   array         phased.URA object
%   f             frequency in Hz
%   azimuthDeg    desired azimuth in degrees
%   elevationDeg  desired elevation in degrees
%
% Output:
%   weights       complex steering vector

sv = phased.SteeringVector( ...
    SensorArray=array, ...
    PropagationSpeed=physconst('LightSpeed'));

weights = sv(f, [azimuthDeg; elevationDeg]);
end
