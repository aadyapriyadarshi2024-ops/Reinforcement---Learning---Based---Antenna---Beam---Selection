function T = Buildlinktable(S, headingOffsets)
%BUILDLINKTABLE Pre-compute everything that does NOT change during the search.
%
%   T = buildLinkTable(S)                    each array faces its own partner
%   T = buildLinkTable(S, [o1 o2 o3 o4])     extra rotation in degrees for
%                                            [Tx1 Tx2 Rx1 Rx2] (the "knob")
%
% Ray tracing only depends on where the sites are, so each link is traced
% ONCE. The beam angle only changes the antenna gain toward the ray's
% departure/arrival direction, so we tabulate those gains for every angle.
%
% Array heading: the paper does not give the array orientation in the text,
% so we ASSUME each array faces the node it is paired with (Tx i <-> Rx i).
% Beam angles (-60..60) are measured relative to that facing direction.
%
%   Pr[dBm] = Pt[dBm] + Gtx[dB] - PathLoss[dB] + Grx[dB]

if nargin < 2 || isempty(headingOffsets)
    headingOffsets = zeros(1,4);
end

cfg     = S.cfg;
txSites = {S.tx1, S.tx2};
rxSites = {S.rx1, S.rx2};
wrap180 = @(x) mod(x + 180, 360) - 180;

txAz = cfg.txAzimuths;          % -60:5:60  (25 values)
rxAz = cfg.rxAzimuths;          % -60:10:60 (13 values)
nT = numel(txAz);
nR = numel(rxAz);

T.txAz  = txAz;
T.rxAz  = rxAz;
T.txPowerDbm = cfg.txPowerDbm;
T.valid      = false(2,2);
T.pathLossDb = NaN(2,2);
T.aod        = NaN(2,2,2);      % (tx, rx, [az el])  global angles
T.aoa        = NaN(2,2,2);
T.aodLocal   = NaN(2,2);        % az relative to the array's facing direction
T.aoaLocal   = NaN(2,2);
T.txHeading  = zeros(1,2);
T.rxHeading  = zeros(1,2);
T.txGainDb   = NaN(2,2,nT);     % (tx, rx, tx-azimuth index)
T.rxGainDb   = NaN(2,2,nR);     % (tx, rx, rx-azimuth index)

% ---------- pass 1: ray trace every link once ----------
for i = 1:2
    for j = 1:2
        fprintf('Ray tracing Tx%d -> Rx%d ... ', i, j);
        rays = raytrace(txSites{i}, rxSites{j}, S.rayModel);
        if isempty(rays) || isempty(rays{1})
            fprintf('NO PATH\n');
            continue;
        end
        pathList = rays{1};
        [~, k] = min([pathList.PathLoss]);       % strongest ray (same as Role 1)
        ray = pathList(k);

        aod = double(ray.AngleOfDeparture(:)).';  aod = aod(1:2);
        aoa = double(ray.AngleOfArrival(:)).';    aoa = aoa(1:2);

        T.valid(i,j)      = true;
        T.pathLossDb(i,j) = ray.PathLoss;
        T.aod(i,j,:)      = aod;
        T.aoa(i,j,:)      = aoa;
        fprintf('done (%d rays, using the lowest path loss one)\n', numel(pathList));
    end
end

% ---------- array headings: each array faces its partner ----------
for i = 1:2
    if T.valid(i,i)
        T.txHeading(i) = T.aod(i,i,1) + headingOffsets(i);
        T.rxHeading(i) = T.aoa(i,i,1) + headingOffsets(2+i);
    end
end

% ---------- pass 2: gains for every steering angle ----------
wTx = cell(1,nT);
for a = 1:nT
    wTx{a} = steering_weights(S.txArray, cfg.f, txAz(a), cfg.txElevation);
end
wRx = cell(1,nR);
for b = 1:nR
    wRx{b} = steering_weights(S.rxArray, cfg.f, rxAz(b), cfg.rxElevation);
end

for i = 1:2
    for j = 1:2
        if ~T.valid(i,j), continue; end

        aodLocal = wrap180(T.aod(i,j,1) - T.txHeading(i));
        aoaLocal = wrap180(T.aoa(i,j,1) - T.rxHeading(j));
        T.aodLocal(i,j) = aodLocal;
        T.aoaLocal(i,j) = aoaLocal;

        for a = 1:nT
            g = pattern(S.txArray, cfg.f, aodLocal, T.aod(i,j,2), ...
    Weights=wTx{a}, Type="directivity");
            T.txGainDb(i,j,a) = g(1);
        end
        for b = 1:nR
            g = pattern(S.rxArray, cfg.f, aoaLocal, T.aoa(i,j,2), ...
    Weights=wRx{b}, Type="directivity");
            T.rxGainDb(i,j,b) = g(1);
        end
    end
end
end