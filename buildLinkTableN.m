function T = buildLinkTableN(S, opts)
% BUILDLINKTABLEN: N-Tx / M-Rx version of buildLinkTable.
%
% Optional inputs:
% headingOffsets   : 1 x (nTx+nRx)
% txElevationMode  : 'fixed' (default) or 'partner'
% rxElevationMode  : 'fixed' (default) or 'partner'

if nargin < 2
    opts = struct();
end

if ~isfield(opts, 'headingOffsets')
    opts.headingOffsets = [];
end

if ~isfield(opts, 'txElevationMode')
    opts.txElevationMode = 'fixed';
end

if ~isfield(opts, 'rxElevationMode')
    opts.rxElevationMode = 'fixed';
end

cfg = S.cfg;
tx = S.txSites;
rx = S.rxSites;

nTx = numel(tx);
nRx = numel(rx);

serve = cfg.servingTx;

if isempty(opts.headingOffsets)
    opts.headingOffsets = zeros(1, nTx + nRx);
end

wrap180 = @(x) mod(x + 180, 360) - 180;

txAz = cfg.txAzimuths;
rxAz = cfg.rxAzimuths;

nT = numel(txAz);
nR = numel(rxAz);

% Initialize the lookup table
T.txAz = txAz;
T.rxAz = rxAz;
T.txPowerDbm = cfg.txPowerDbm;
T.serve = serve;

T.valid = false(nTx, nRx);
T.pathLossDb = NaN(nTx, nRx);

T.aod = NaN(nTx, nRx, 2);
T.aoa = NaN(nTx, nRx, 2);

T.aodLocal = NaN(nTx, nRx);
T.aoaLocal = NaN(nTx, nRx);

T.txHeading = zeros(1, nTx);
T.rxHeading = zeros(1, nRx);

T.txGainDb = NaN(nTx, nRx, nT);
T.rxGainDb = NaN(nTx, nRx, nR);

% Pass 1: Ray trace every link once
for i = 1:nTx
    for j = 1:nRx

        fprintf('Ray tracing Tx%d -> Rx%d ... ', i, j);

        rays = raytrace(tx{i}, rx{j}, S.rayModel);

        if isempty(rays) || isempty(rays{1})
            fprintf('NO PATH\n');
            continue;
        end

        pathList = rays{1};
        [~, k] = min([pathList.PathLoss]);
        ray = pathList(k);

        aod = double(ray.AngleOfDeparture(:)).';
        aod = aod(1:2);

        aoa = double(ray.AngleOfArrival(:)).';
        aoa = aoa(1:2);

        T.valid(i, j) = true;
        T.pathLossDb(i, j) = ray.PathLoss;

        T.aod(i, j, :) = aod;
        T.aoa(i, j, :) = aoa;

        fprintf('done\n');
    end
end

% Headings: each array faces its partner(s)
for i = 1:nTx

    js = find(serve == i & T.valid(i, :));

    if ~isempty(js)
        az = squeeze(T.aod(i, js, 1));
        az = az(:);

        T.txHeading(i) = ...
            atan2d(mean(sind(az)), mean(cosd(az))) ...
            + opts.headingOffsets(i);
    end
end

for j = 1:nRx

    if T.valid(serve(j), j)
        T.rxHeading(j) = ...
            T.aoa(serve(j), j, 1) ...
            + opts.headingOffsets(nTx + j);
    end
end

% Steering elevations
T.txEl = repmat(cfg.txElevation, 1, nTx);
T.rxEl = repmat(cfg.rxElevation, 1, nRx);

if strcmp(opts.rxElevationMode, 'partner')
    for j = 1:nRx
        if T.valid(serve(j), j)
            T.rxEl(j) = T.aoa(serve(j), j, 2);
        end
    end
end

if strcmp(opts.txElevationMode, 'partner')
    for i = 1:nTx
        js = find(serve == i & T.valid(i, :));

        if ~isempty(js)
            T.txEl(i) = mean(squeeze(T.aod(i, js, 2)));
        end
    end
end

T.opts = opts;

% Pass 2: Calculate gains for every steering angle
wTx = cell(nTx, nT);

for i = 1:nTx
    for a = 1:nT
        wTx{i, a} = steering_weights( ...
            S.txArray, cfg.f, txAz(a), T.txEl(i));
    end
end

wRx = cell(nRx, nR);

for j = 1:nRx
    for b = 1:nR
        wRx{j, b} = steering_weights( ...
            S.rxArray, cfg.f, rxAz(b), T.rxEl(j));
    end
end

for i = 1:nTx
    for j = 1:nRx

        if ~T.valid(i, j)
            continue;
        end

        aodLocal = wrap180( ...
            T.aod(i, j, 1) - T.txHeading(i));

        aoaLocal = wrap180( ...
            T.aoa(i, j, 1) - T.rxHeading(j));

        T.aodLocal(i, j) = aodLocal;
        T.aoaLocal(i, j) = aoaLocal;

        for a = 1:nT
            g = pattern( ...
                S.txArray, cfg.f, ...
                aodLocal, T.aod(i, j, 2), ...
                Weights=wTx{i, a}, ...
                Type="directivity");

            T.txGainDb(i, j, a) = g(1);
        end

        for b = 1:nR
            g = pattern( ...
                S.rxArray, cfg.f, ...
                aoaLocal, T.aoa(i, j, 2), ...
                Weights=wRx{j, b}, ...
                Type="directivity");

            T.rxGainDb(i, j, b) = g(1);
        end
    end
end

end