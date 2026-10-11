function [powerDbm, info] = Getsignalpoweroriented( ...
    txSite, rxSite, txAz, txEl, rxAz, rxEl, ...
    txArray, rxArray, rayModel, f, txPowerDbm, ...
    txHeadingDeg, rxHeadingDeg)
%GETSIGNALPOWERORIENTED Role 1's getSignalPower + array headings.
%
% Same link budget as Role 1:  Pr = Pt + Gtx - PathLoss + Grx   (dBm)
%
% The only change: each array now FACES a direction (its heading, a global
% azimuth). Ray angles are converted into the array's own frame before the
% pattern is evaluated:   local angle = ray angle - heading
%
% txAz / rxAz are measured relative to the array's own broadside direction
% (so the paper's -60..60 sweep is centred on where the array faces).

wrap180 = @(x) mod(x + 180, 360) - 180;

info = struct('validPath', false, 'pathLossDb', NaN, ...
    'txGainDb', NaN, 'rxGainDb', NaN, ...
    'aodDeg', [NaN NaN], 'aoaDeg', [NaN NaN], ...
    'aodLocalDeg', NaN, 'aoaLocalDeg', NaN, 'numRays', 0);
powerDbm = -Inf;

rays = raytrace(txSite, rxSite, rayModel);
if isempty(rays) || isempty(rays{1})
    return;
end

pathList = rays{1};
info.numRays = numel(pathList);
[~, k] = min([pathList.PathLoss]);          % strongest ray (as in Role 1)
ray = pathList(k);
info.pathLossDb = ray.PathLoss;

aod = double(ray.AngleOfDeparture(:)).';  aod = aod(1:2);
aoa = double(ray.AngleOfArrival(:)).';    aoa = aoa(1:2);
info.aodDeg = aod;
info.aoaDeg = aoa;

aodLocal = wrap180(aod(1) - txHeadingDeg);
aoaLocal = wrap180(aoa(1) - rxHeadingDeg);
info.aodLocalDeg = aodLocal;
info.aoaLocalDeg = aoaLocal;

wTx = steering_weights(txArray, f, txAz, txEl);
gTx = pattern(txArray, f, aodLocal, aod(2), Weights=wTx, Type="directivity");

wRx = steering_weights(rxArray, f, rxAz, rxEl);
gRx = pattern(rxArray, f, aoaLocal, aoa(2), Weights=wRx, Type="directivity");

gTx = gTx(1);
gRx = gRx(1);
info.txGainDb = gTx;
info.rxGainDb = gRx;
info.validPath = true;

powerDbm = txPowerDbm + gTx - ray.PathLoss + gRx;
end