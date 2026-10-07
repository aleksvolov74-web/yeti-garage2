# Technical catalog sources and asset notes

Current aggregate metadata: [`technical_catalog_manifest.json`](technical_catalog_manifest.json).

The catalog contains independently generated technical visuals; linked workshop pages support general architecture, not exact VIN/PR fitment. Original service-manual images are not bundled. Source details, applicability notes and marker mappings for every node are preserved in the aggregate manifest and `data/technical_catalog.json`.

## Existing source/batch documents

- [`../../docs/technical_catalog_sources.md`](../../docs/technical_catalog_sources.md) — vehicle scope, architecture references and current catalog status.
- [`SOURCES_cbzb_air_fuel_cooling_exhaust.md`](SOURCES_cbzb_air_fuel_cooling_exhaust.md)
- [`SOURCES_cbzb_dq200_batch.md`](SOURCES_cbzb_dq200_batch.md)
- [`SOURCES_rear_steering_abs.md`](SOURCES_rear_steering_abs.md)
- [`SOURCES_electrics_lighting.md`](SOURCES_electrics_lighting.md)
- [`body_glass_wipers_SOURCES.md`](body_glass_wipers_SOURCES.md)
- [`climate/SOURCES.md`](climate/SOURCES.md)
- [`front_suspension/front_suspension_batch_manifest.json`](front_suspension/front_suspension_batch_manifest.json) — source and variant data for the front suspension additions.

## Applicability

Project vehicle: Škoda Yeti 5L, MY2011, CBZB 1.2 TSI 77 kW, FWD, 0AM/DQ200. `VERIFIED_ARCHITECTURE` means general construction is supported, not VIN-exact geometry. `REFERENCE_ONLY` is not a fitment claim. The four 4×4 reference nodes are not installed on this FWD vehicle.

## Audit limitation

The 2026-10-06 visual audit moved both `srs_sensors` marker targets onto visible sensor modules; the image asset itself was unchanged. Exact fitment remains `REFERENCE_ONLY`.
