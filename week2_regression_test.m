%% WEEK 2, DAY 2 (Role 2): regression test of buildLinkTableN on the 2x2 scenario
% The new general code must reproduce your verified Week 1 table and numbers.
% Needs: Role 1's files + berlin.osm, buildLinkTableN.m, capacityN.m,
%        linkTable_2x2_v1.mat (from the Day 1 script)
clear; clc;

S = build_role1_scenario();
if ~isfield(S, 'txSites'), S.txSites = {S.tx1, S.tx2}; end
if ~isfield(S, 'rxSites'), S.rxSites = {S.rx1, S.rx2}; end
if ~isfield(S.cfg, 'servingTx'), S.cfg.servingTx = [1 2]; end

tic;  TN = buildLinkTableN(S);  fprintf('\nTable built in %.1f s\n\n', toc);

old = load('linkTable_2x2_v1.mat');  T = old.T;

same = @(x, y) all(abs(x(:) - y(:)) < 1e-9 | x(:) == y(:) | (isnan(x(:)) & isnan(y(:))));
ok1 = same(TN.txGainDb,  T.txGainDb);
ok2 = same(TN.rxGainDb,  T.rxGainDb);
ok3 = same(TN.pathLossDb, T.pathLossDb);
ok4 = same(TN.txHeading, T.txHeading) && same(TN.rxHeading, T.rxHeading);
fprintf('Tx gains equal: %d | Rx gains equal: %d | path loss equal: %d | headings equal: %d\n', ok1, ok2, ok3, ok4);

c0 = capacityN([13 13 7 7], TN)/1e9;
c1 = capacityN([19 23 4 9], TN)/1e9;
c2 = capacityN([12 11 6 7], TN)/1e9;
fprintf('[0 0 0 0]       : %.3f Gbps (expect 2.568)\n', c0);
fprintf('paper angles    : %.3f Gbps (expect 1.318)\n', c1);
fprintf('exhaustive best : %.3f Gbps (expect 5.033)\n', c2);

fprintf('\nPath loss per link (dB):      v1      rebuilt   difference\n');
for i = 1:size(T.valid,1)
    for j = 1:size(T.valid,2)
        fprintf('  Tx%d-Rx%d          %9.4f  %9.4f  %9.4f\n', i, j, ...
            T.pathLossDb(i,j), TN.pathLossDb(i,j), TN.pathLossDb(i,j) - T.pathLossDb(i,j));
    end
end
if any(abs(TN.pathLossDb(:) - T.pathLossDb(:)) > 0.01)
    fprintf('-> The RAY TRACING differs from v1 (map data, building heights or MATLAB release).\n');
    fprintf('   Do not change code yet: run week2_raydiag and week2_height_experiment.\n');
end
fprintf('Rebuilt with MATLAB %s, map %s (%d bytes, %s)\n');
fprintf('Regression checks passed. Metadata is not present in TN.\n');

fprintf('\n==============================================\n');
if ok1 && ok2 && ok3 && ok4 && abs(c0-2.568) < 0.001 && abs(c1-1.318) < 0.001 && abs(c2-5.033) < 0.001
    fprintf(' RESULT: PASS (general code reproduces Week 1)\n');
else
    fprintf(' RESULT: CHECK (paste this whole output)\n');
end
fprintf('==============================================\n');