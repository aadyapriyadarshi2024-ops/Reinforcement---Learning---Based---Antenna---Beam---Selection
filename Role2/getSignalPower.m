
function [powerDbm, info] = getSignalPower( ...
    txSite, rxSite, ...
    txAz, txEl, rxAz, rxEl, ...
    txArray, rxArray, rayModel, f, txPowerDbm)
%GETSIGNALPOWER Calculate received power for one Tx-Rx link.
%
% Inputs:
%   txSite, rxSite       Transmitter and receiver site objects
%   txAz, txEl           Tx steering azimuth/elevation [deg]
%   rxAz, rxEl           Rx steering azimuth/elevation [deg]
%   txArray, rxArray     Tx and Rx antenna arrays
%   rayModel             Ray-tracing propagation model
%   f                    Carrier frequency [Hz]
%   txPowerDbm           Transmit power [dBm]
%
% Outputs:
%   powerDbm             Received power [dBm]
%   info                 Diagnostic structure

%% 1. Initialize outputs and diagnostics

powerDbm = -Inf;

info = struct( ...
    'validPath', false, ...
    'pathLossDb', NaN, ...
    'txGainDb', NaN, ...
    'rxGainDb', NaN, ...
    'aodDeg', [NaN NaN], ...
    'aoaDeg', [NaN NaN], ...
    'phaseShiftDeg', NaN, ...
    'propagationDelaySec', NaN, ...
    'selectedPathIndex', NaN, ...
    'numRays', 0);

%% 2. Ray trace the physical Tx-to-Rx link

rays = raytrace(txSite, rxSite, rayModel);

if isempty(rays) || isempty(rays{1})
    % No propagation path exists for this link.
    return;
end

pathList = rays{1};
info.numRays = numel(pathList);

%% 3. Select the path with minimum path loss

pathLosses = [pathList.PathLoss];
[~, selectedIndex] = min(pathLosses);

ray = pathList(selectedIndex);

if ~isfinite(ray.PathLoss)
    error('getSignalPower:InvalidPathLoss', ...
        'The selected ray has a non-finite path loss.');
end

info.selectedPathIndex = selectedIndex;
info.pathLossDb = ray.PathLoss;

%% 4. Extract departure and arrival angles

aod = normalizeAnglePair(ray.AngleOfDeparture);
aoa = normalizeAnglePair(ray.AngleOfArrival);

info.aodDeg = aod;
info.aoaDeg = aoa;

%% 5. Read optional ray properties

if isprop(ray, 'PhaseShift')
    info.phaseShiftDeg = ray.PhaseShift;
end

if isprop(ray, 'PropagationDelay')
    info.propagationDelaySec = ray.PropagationDelay;
end


%% 6. Calculate transmitter gain in dBi

wTx = steering_weights(txArray, f, txAz, txEl);

gainTxDb = pattern( ...
    txArray, f, ...
    aod(1), aod(2), ...
    'Weights', wTx, ...
    'Type', 'directivity');

%% 7. Calculate receiver gain in dBi
% Reverse the ray's arrival direction to obtain the
% direction from the receiver back toward the source.

rxPatternAz = mod(aoa(1) + 180 + 180, 360) - 180;
rxPatternEl = -aoa(2);

wRx = steering_weights(rxArray, f, rxAz, rxEl);

gainRxDb = pattern( ...
    rxArray, f, ...
    rxPatternAz, rxPatternEl, ...
    'Weights', wRx, ...
    'Type', 'directivity');



%% 8. Validate the gain outputs

if isempty(gainTxDb) || isempty(gainRxDb)
    error('getSignalPower:EmptyGain', ...
        'The pattern function returned an empty gain.');
end

gainTxDb = double(gainTxDb(1));
gainRxDb = double(gainRxDb(1));

info.txGainDb = gainTxDb;
info.rxGainDb = gainRxDb;

if ~isfinite(gainTxDb) || ~isfinite(gainRxDb)
    error('getSignalPower:InvalidGain', ...
        ['Antenna gain is NaN or Inf. Inspect the antenna ' ...
         'pattern output and angle conventions.']);
end


%% 9. Calculate received power using the link budget
%
% Pr[dBm] = Pt[dBm] + Gtx[dB] - PathLoss[dB] + Grx[dB]

powerDbm = txPowerDbm + gainTxDb ...
    - ray.PathLoss + gainRxDb;

if ~isfinite(powerDbm)
    error('getSignalPower:InvalidPower', ...
        'The calculated received power is non-finite.');
end

info.validPath = true;

fprintf('Transmit power:     %.3f dBm\n', txPowerDbm);
fprintf('Received power:     %.3f dBm\n', powerDbm);

end


%% Helper function: normalize ray angle format

function ang = normalizeAnglePair(raw)
%NORMALIZEANGLEPAIR Return ray angles as [azimuth elevation].

raw = double(raw(:));

if numel(raw) < 2
    error('getSignalPower:InvalidAngles', ...
        'Unexpected ray angle format: at least two values required.');
end

ang = raw(1:2).';

end
