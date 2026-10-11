%% DAY 5: full exhaustive search (2 Tx / 2 Rx) using the lookup table
% Needs linkTable.mat from day4_validate_table.m
clear; clc;

load('linkTable.mat', 'T');
pf = makeRealPower(T);

nT = numel(T.txAz);      % 25
nR = numel(T.rxAz);      % 13
Call = zeros(nT, nT, nR, nR);     % capacity of EVERY combination (bits/s)

tic;
for a1 = 1:nT
    for a2 = 1:nT
        for b1 = 1:nR
            for b2 = 1:nR
                Call(a1,a2,b1,b2) = totalCapacity( ...
                    [T.txAz(a1) T.txAz(a2) T.rxAz(b1) T.rxAz(b2)], pf);
            end
        end
    end
    if mod(a1,5) == 0
        fprintf('  %d/%d done, %.0f s elapsed\n', a1, nT, toc);
    end
end
elapsed = toc;
fprintf('\nSearched %d combinations in %.1f s\n', numel(Call), elapsed);

% ---- best combination ----
[best, lin] = max(Call(:));
[a1,a2,b1,b2] = ind2sub(size(Call), lin);
bestAngles = [T.txAz(a1) T.txAz(a2) T.rxAz(b1) T.rxAz(b2)];
fprintf('\nBEST angles [Tx1 Tx2 Rx1 Rx2] = [%g %g %g %g]\n', bestAngles);
fprintf('BEST total capacity = %.3f Gbps\n', best/1e9);

% ---- where does the paper's configuration rank? ----
refAngles = [30 50 -30 20];
Cref = totalCapacity(refAngles, pf);
rankRef = sum(Call(:) > Cref) + 1;
fprintf('\nPaper angles [30 50 -30 20] give %.3f Gbps -> rank %d of %d\n', ...
    Cref/1e9, rankRef, numel(Call));

% ---- top 10 ----
[sortedC, order] = sort(Call(:), 'descend');
fprintf('\nTop 10 combinations:\n');
for k = 1:10
    [i1,i2,j1,j2] = ind2sub(size(Call), order(k));
    fprintf('  %2d)  [%4g %4g %4g %4g]   %.3f Gbps\n', k, ...
        T.txAz(i1), T.txAz(i2), T.rxAz(j1), T.rxAz(j2), sortedC(k)/1e9);
end

save('exhaustive_small.mat', 'Call', 'best', 'bestAngles', 'elapsed');
fprintf('\nSaved exhaustive_small.mat (give this to Role 3 as the ground truth).\n');