function cfg = project_config()
%PROJECT_CONFIG Central configuration for Role 1.
%
% All angles are in degrees.
% Coordinates are [latitude, longitude, height_m].

cfg.f = 28e9;
cfg.c = physconst('LightSpeed');
cfg.lambda = cfg.c / cfg.f;

% 0.5 W = 500 mW = 26.99 dBm
cfg.txPowerW = 0.5;
cfg.txPowerDbm = 10*log10(cfg.txPowerW * 1000);

% Antenna arrays
cfg.txRows = 8;
cfg.txCols = 4;
cfg.rxRows = 4;
cfg.rxCols = 2;

cfg.elementSpacing = [cfg.lambda/2 cfg.lambda/2];

% Paper coordinates
cfg.tx1 = [52.561075, 13.503874, 14];
cfg.tx2 = [52.560802, 13.504149, 12];

cfg.rx1 = [52.560834, 13.504560, 1];
cfg.rx2 = [52.561001, 13.503810, 1];

% Paper steering grid
cfg.txAzimuths = -60:5:60;
cfg.rxAzimuths = -60:10:60;

% Transmitters start 30 degrees downward
cfg.txElevation = -30;

% Week-1 receiver elevation assumption.
% The paper specifies adjustable receiver orientation but does not give
% one fixed elevation value for the complete search in the supplied text.
cfg.rxElevation = 0;

% Map
cfg.osmFile = "berlin.osm";

% Ray tracing
cfg.maxReflections = 1;

% Noise temperature, passed to Role 2
cfg.noiseTemperatureK = 300;

% Paper's reported reference configuration from the project plan
cfg.referenceTx1Az = 30;
cfg.referenceTx2Az = 50;
cfg.referenceRx1Az = -30;
cfg.referenceRx2Az = 20;
cfg.referenceCapacityGbps = 61.04;
end
