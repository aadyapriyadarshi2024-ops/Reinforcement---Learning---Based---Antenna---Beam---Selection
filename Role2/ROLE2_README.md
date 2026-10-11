# Role 2 — Capacity function and exhaustive search

## Files needed in the project folder
From Role 1 (unchanged, used as they are):
- `build_role1_scenario.m`, `project_config.m`, `steering_weights.m`, `berlin.osm`

From Role 2:
- `totalCapacity.m`        total capacity of the 2 Tx / 2 Rx links (Shannon, with interference)
- `buildLinkTable.m`       ray-traces each link once and tabulates the antenna gains
- `getSignalPowerOriented.m` slow direct calculation, used only to check the table
- `makeRealPower.m`        turns the table into the function that totalCapacity calls
- `mockPower.m`            made-up channel for testing without Role 1
- `day4_validate_table.m`  builds the table and checks it (saves `linkTable.mat` and a log)
- `day5_exhaustive_search.m` searches all 105,625 combinations (saves `exhaustive_small.mat`)

Role 1's other files (`getSignalPower.m`, `main_role1.m`, `test_role1.m`, debug files)
are not used by the Role 2 pipeline.

## Run order
1. `day4_validate_table`  -> the last lines must say `RESULT: PASS`
2. `day5_exhaustive_search`

## Assumptions (write these in the report)
- Rx j is served by Tx j; the other Tx is interference.
- Each array faces its partner node (the paper's text does not give array orientation).
  Beam angles (-60..60 Tx in 5 deg steps, -60..60 Rx in 10 deg steps) are relative to that direction.
- Only the strongest (lowest path loss) ray is used.
- Antenna gain = directivity in dBi from MATLAB `pattern`. The element comes from `build_role1_scenario.m`:
  Role 1's package uses CosineAntennaElement, Role 2's working copy uses IsotropicAntennaElement
  (the cosine element has zero gain behind the array). The paper uses a patch element. The team must
  agree on ONE element and keep ONE copy of `build_role1_scenario.m`.
- Tx beam elevation -30 deg, Rx beam elevation 0 deg (Role 1's configuration).
- Capacity = B*log2(1+SINR), B = 400 MHz, noise = kTB at 300 K.
- The paper's 61.04 Gbps is not reachable with this formula and these numbers; compare
  best angles and ranking instead of the absolute Gbps value.

## Reference numbers (independent Python recomputation from Role 2's linkTable.mat, isotropic element)
MATLAB should print the same values:
- `totalCapacity([0 0 0 0])`        = 2.568 Gbps
- `totalCapacity([30 50 -30 20])`   = 1.318 Gbps
- Exhaustive search best angles `[-5 -10 -10 0]` = 5.033 Gbps; paper angles rank 20141 of 105625

## Known limitation
Beams are steered at fixed elevations (Tx -30, Rx 0) but the partner nodes are at elevations of
-13.6 to -54 deg (seen from Tx) and +13.6 to +54 deg (seen from Rx), so beam gains are low
(Tx1-Rx1 best Tx gain is only -8.6 dBi). Pointing the Rx beam elevation at its partner is the
first improvement to try.

## For Role 3 (GitHub upload list)
Needed: `totalCapacity.m`, `makeRealPower.m`, `linkTable.mat`, `exhaustive_small.mat`,
`example_for_role3.m`, this README. No toolboxes and no Role 1 files are needed.
Only the 2 Tx / 2 Rx scenario is supported so far (3 Tx / 6 Rx needs an extended table).
