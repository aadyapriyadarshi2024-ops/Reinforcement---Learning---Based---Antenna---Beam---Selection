

function [bestIdx, bestC] = coordinateAscent(T, nRestarts)
%COORDINATEASCENT Search for a high-capacity solution using random restarts.
% This heuristic does not guarantee the global optimum.

nTx = size(T.valid, 1);
nRx = size(T.valid, 2);

sizes = [repmat(numel(T.txAz), 1, nTx), ...
         repmat(numel(T.rxAz), 1, nRx)];

bestC = -Inf;
bestIdx = [];

for r = 1:nRestarts
    idx = arrayfun(@(n) randi(n), sizes);
    C = capacityN(idx, T);

    improved = true;

    while improved
        improved = false;

        for k = randperm(numel(idx))
            for v = 1:sizes(k)
                trial = idx;
                trial(k) = v;
                Ct = capacityN(trial, T);

                if Ct > C
                    C = Ct;
                    idx = trial;
                    improved = true;
                end
            end
        end
    end

    if C > bestC
        bestC = C;
        bestIdx = idx;
    end
end
end
