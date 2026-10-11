%% EXAMPLE FOR ROLE 3 - how to use the Role 2 capacity function
% Needs only: totalCapacity.m, makeRealPower.m, linkTable.mat
% (no toolboxes, no Role 1 files, no map).
clear; clc;

s = load('linkTable.mat');  T = s.T;
reward = makeRealPower(T);          % function handle: received power in Watts

% angles = [Tx1 Tx2 Rx1 Rx2] in degrees. They MUST be on these grids:
txAngles = T.txAz;                  % -60:5:60   (25 values)
rxAngles = T.rxAz;                  % -60:10:60  (13 values)

C = totalCapacity([0 0 0 0], reward);            % bits per second
fprintf('Capacity at [0 0 0 0] = %.3f Gbps\n', C/1e9);

% TIP: use C/1e9 (Gbps) as the RL reward so values are about 0..5, not 1e9.

% FAST ALTERNATIVE for the small scenario:
% after Role 2 runs day5_exhaustive_search, exhaustive_small.mat holds
%   Call(a1,a2,b1,b2) = capacity (bits/s) of EVERY combination,
% where a1,a2 index txAngles and b1,b2 index rxAngles.
% It gives exactly the same values as totalCapacity, but instantly.
e = load('exhaustive_small.mat');
a1 = find(txAngles==0);  a2 = find(txAngles==0);
b1 = find(rxAngles==0);  b2 = find(rxAngles==0);
fprintf('Same value from the table : %.3f Gbps\n', e.Call(a1,a2,b1,b2)/1e9);
fprintf('Best possible (exhaustive): %.3f Gbps at %s\n', e.best/1e9, mat2str(e.bestAngles));
% Paper-style accuracy of an RL result:  RL capacity / e.best
