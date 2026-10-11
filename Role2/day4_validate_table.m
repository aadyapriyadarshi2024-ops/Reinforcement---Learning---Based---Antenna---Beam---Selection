%% DAY 4 - STEP 2: build the lookup table and CHECK it
% Needs: build_role1_scenario.m, project_config.m, steering_weights.m (Role 1)
%        + buildLinkTable.m, makeRealPower.m, getSignalPowerOriented.m,
%          totalCapacity.m (Role 2), all in ONE folder with berlin.osm.
% Everything printed is also saved in day4_validate_log.txt (send me that file).
clear; clc;
logFile = 'day4_validate_log.txt';
if exist(logFile, 'file'), delete(logFile); end
diary(logFile); diary on;

S   = build_role1_scenario();
cfg = S.cfg;

tic; T = Buildlinktable(S); fprintf('\nTable built in %.1f s\n', toc);
save('linkTable.mat', 'T');


fprintf('\n--- Antenna gain diagnostic ---\n');

for i = 1:2
    for j = 1:2
        if ~T.valid(i,j)
            continue;
        end

        [gT, aIdx] = max(squeeze(T.txGainDb(i,j,:)));
        [gR, bIdx] = max(squeeze(T.rxGainDb(i,j,:)));

        fprintf(['Tx%d-Rx%d: Tx gain %.2f dB at %g deg; ' ...
                 'Rx gain %.2f dB at %g deg\n'], ...
            i, j, gT, T.txAz(aIdx), gR, T.rxAz(bIdx));
    end
end


fprintf('\nArray headings (global azimuth each array faces):\n');
fprintf('  Tx1 %.1f   Tx2 %.1f   Rx1 %.1f   Rx2 %.1f\n', ...
    T.txHeading(1), T.txHeading(2), T.rxHeading(1), T.rxHeading(2));

% ---- summary of each link, in each array's OWN frame ----
fprintf('\nLink    PathLoss  localAoD  localAoA  bestTxAz bestRxAz  maxPower(dBm)  nonFiniteTx nonFiniteRx\n');
for i = 1:2
    for j = 1:2
        if ~T.valid(i,j)
            fprintf('Tx%d-Rx%d  NO PATH\n', i, j);
            continue;
        end
        gTx = squeeze(T.txGainDb(i,j,:));
        gRx = squeeze(T.rxGainDb(i,j,:));
        [gT, aIdx] = max(gTx);
        [gR, bIdx] = max(gRx);
        pmax = T.txPowerDbm + gT - T.pathLossDb(i,j) + gR;
        fprintf('Tx%d-Rx%d  %7.2f   %7.1f   %7.1f   %6d   %6d    %9.2f      %6d      %6d\n', ...
            i, j, T.pathLossDb(i,j), T.aodLocal(i,j), T.aoaLocal(i,j), ...
            T.txAz(aIdx), T.rxAz(bIdx), pmax, sum(~isfinite(gTx)), sum(~isfinite(gRx)));
    end
end

% ---- compare table vs direct (oriented) calls: should agree ----
fprintf('\nTable vs direct call (differences should be ~0 dB):\n');
txSites = {S.tx1, S.tx2};
rxSites = {S.rx1, S.rx2};
pf = makeRealPower(T);
rng(1);
maxDiff = 0;
for n = 1:8
    i  = randi(2);  j = randi(2);
    aT = cfg.txAzimuths(randi(numel(cfg.txAzimuths)));
    aR = cfg.rxAzimuths(randi(numel(cfg.rxAzimuths)));

    pDirect = Getsignalpoweroriented(txSites{i}, rxSites{j}, ...
        aT, cfg.txElevation, aR, cfg.rxElevation, ...
        S.txArray, S.rxArray, S.rayModel, cfg.f, cfg.txPowerDbm, ...
        T.txHeading(i), T.rxHeading(j));
    pTable = 10*log10(pf(i,j,aT,aR)*1000);

    if isinf(pDirect) && isinf(pTable)
        d = 0;
    else
        d = abs(pDirect - pTable);
    end
    maxDiff = max(maxDiff, d);
    fprintf('  Tx%d-Rx%d  txAz=%4d rxAz=%4d  direct=%8.3f dBm  table=%8.3f dBm  diff=%.4f dB\n', ...
        i, j, aT, aR, pDirect, pTable, d);
end
fprintf('Largest difference: %.4f dB\n', maxDiff);

% ---- first real capacity numbers ----
fprintf('\nFirst real capacity numbers (Gbps):\n');
fprintf('  all beams straight at partner [0 0 0 0] : %.3f\n', totalCapacity([0 0 0 0], pf)/1e9);
fprintf('  paper angles [30 50 -30 20]            : %.3f\n', totalCapacity([30 50 -30 20], pf)/1e9);

% ---- verdict LAST so it cannot be missed ----
fprintf('\n==============================================\n');
if maxDiff < 0.01
    fprintf(' RESULT: PASS  (table matches the direct calculation)\n');
else
    fprintf(' RESULT: CHECK (table and direct calculation disagree)\n');
end
fprintf('==============================================\n');
diary off;