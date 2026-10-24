
% EVAL_RESULTS Analyse Role 3's five-algorithm seed comparison.
% Uses the supplied results; does not rerun training.

clear; clc; close all;

%% 1. Load the recorded results
data = readtable('all_seed_test_details.csv');

load('all_five_algorithms_seed_tests.mat', ...
     'optimalGbps');

algorithms = unique(string(data.Algorithm), 'stable');
n = numel(algorithms);

%% 2. Set reference values using Double Q-learning
% Following the project guide's large-scenario convention:
% reference capacity = maximum recorded Double Q-learning BestGbps
% reference time     = maximum recorded Double Q-learning runtime

dq = string(data.Algorithm) == "Double Q-learning";

refCap = max(data.BestGbps(dq));
refTime = max(data.RuntimeSeconds(dq));

fprintf('Saved MAT reference optimum: %.4f Gbps\n', optimalGbps);
fprintf('Double Q-learning reference capacity: %.4f Gbps\n', refCap);
fprintf('Double Q-learning reference time: %.4f seconds\n\n', refTime);

%% 3. Calculate statistics for each algorithm
MeanBestGbps = zeros(n,1);
StdBestGbps = zeros(n,1);
MeanGreedyGbps = zeros(n,1);
StdGreedyGbps = zeros(n,1);
MeanGreedyGapPercent = zeros(n,1);
MeanLast100Gbps = zeros(n,1);
MeanRuntimeSeconds = zeros(n,1);
AccuracyPercent = zeros(n,1);
WeightedEfficiency = zeros(n,1);

for k = 1:n
    rows = string(data.Algorithm) == algorithms(k);

    bestCap = data.BestGbps(rows);
    greedyCap = data.GreedyGbps(rows);
    gap = data.GreedyGapPercent(rows);
    last100 = data.MeanLast100Gbps(rows);
    runtime = data.RuntimeSeconds(rows);

    MeanBestGbps(k) = mean(bestCap);
    StdBestGbps(k) = std(bestCap, 0);
    MeanGreedyGbps(k) = mean(greedyCap);
    StdGreedyGbps(k) = std(greedyCap, 0);
    MeanGreedyGapPercent(k) = mean(gap);
    MeanLast100Gbps(k) = mean(last100);
    MeanRuntimeSeconds(k) = mean(runtime);

    % Final greedy-policy capacity relative to reference capacity
    AccuracyPercent(k) = 100 * MeanGreedyGbps(k) / refCap;

    % Project guide's weighted-efficiency formula
    WeightedEfficiency(k) = ...
        0.7 * (MeanGreedyGbps(k) / refCap) + ...
        0.3 * ((refTime - MeanRuntimeSeconds(k)) / refTime);
end

%% 4. Display and save the summary
summary = table(algorithms, MeanBestGbps, StdBestGbps, ...
    MeanGreedyGbps, StdGreedyGbps, MeanGreedyGapPercent, ...
    MeanLast100Gbps, MeanRuntimeSeconds, AccuracyPercent, ...
    WeightedEfficiency, ...
    'VariableNames', {'Algorithm','MeanBestGbps','StdBestGbps', ...
    'MeanGreedyGbps','StdGreedyGbps','MeanGreedyGapPercent', ...
    'MeanLast100Gbps','MeanRuntimeSeconds','AccuracyPercent', ...
    'WeightedEfficiency'});

disp('===== EVALUATION SUMMARY =====');
disp(summary);

writetable(summary, 'eval_results_summary.csv');
save('eval_results_output.mat', 'summary', 'refCap', 'refTime');

%% 5. Plot mean greedy-policy capacity
figure;
bar(categorical(summary.Algorithm), summary.MeanGreedyGbps);
ylabel('Mean greedy capacity (Gbps)');
title('Greedy-Policy Capacity Comparison');
grid on;

%% 6. Plot standard deviation of greedy capacity
figure;
bar(categorical(summary.Algorithm), summary.StdGreedyGbps);
ylabel('Standard deviation (Gbps)');
title('Greedy-Policy Capacity Variability');
grid on;

%% 7. Plot mean runtime
figure;
bar(categorical(summary.Algorithm), summary.MeanRuntimeSeconds);
ylabel('Mean runtime (seconds)');
title('Runtime Comparison');
grid on;

%% 8. Plot weighted efficiency
figure;
bar(categorical(summary.Algorithm), summary.WeightedEfficiency);
ylabel('Weighted efficiency');
title('Weighted-Efficiency Comparison');
grid on;

fprintf('\nEvaluation completed.\n');
fprintf('Saved eval_results_summary.csv\n');
fprintf('Saved eval_results_output.mat\n');
