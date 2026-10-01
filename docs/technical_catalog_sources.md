# Mobile technical catalog and diagram sources

The mobile technical catalog is defined by `data/technical_catalog.json`. Its system and node hierarchy is a navigation layer over the existing `PartCatalogService` records; existing part IDs are retained. Components that lack a validated procedure keep empty diagnostic and repair references.

## Vehicle construction reference

- Škoda Yeti 5L front suspension overview and service steps: [SkodaBook — Front suspension](https://www.skodabook.ru/en/Yeti/5L/chassis/fsuspension). Used to describe the front axle as a MacPherson-strut arrangement with L-shaped lower arms and to avoid presenting another suspension layout as Yeti-specific.
- Yeti 5L parts application by year and market: [Škoda OEM parts catalog — Yeti 5L](https://skoda.catalogs-parts.com/). Consult the VIN/PR-code catalog before attaching OEM positions or variant-specific diagrams.
- Front-axle steering and suspension application: [OCAP 2024 steering and suspension catalog](https://www.ocap.it/images/cataloghi/2024/OCAP_STEERING__SUSPENSION.pdf). Used only as a secondary component-layout cross-check, not as a Yeti-specific image source.

## Images

No external technical diagram or 3D asset is currently included in the mobile catalog. The existing `assets/manual/figures/` files are operating-manual illustrations and are not represented as workshop exploded views. Catalog nodes without an independently checked, compatible image therefore expose an empty diagram state rather than an illustrative substitute.

When an image is added, record its direct source, author/publisher, license, vehicle/engine/transmission applicability, asset path, and any crop or annotation in this file. Store callout coordinates and part IDs in the corresponding node's `diagram.markers` array in `data/technical_catalog.json`; do not bake the numbers into the source image.

## Compatibility

The catalog scope is Yeti type 5L, model years 2009–2017. Catalog entries can be gated by year, engine code, transmission code, drivetrain, and equipment. The `requires_drivetrain` gate hides the 4×4 branch unless the saved vehicle explicitly identifies AWD/4WD/4×4. More specific engine and transmission variants remain unverified until the saved vehicle profile and source catalog identify them.

## Working profile: VIN XW8JF25LXBK701304

The working profile is Škoda Yeti 5L, MY2011, CBZB 1.2 TSI, FWD, 7-speed DSG, family 0AM/DQ200. The exact production date, three-letter gearbox code, market destination, and individual PR codes are not available in the source record. The profile selects CBZB and FWD architecture and suppresses AWD nodes. It does not invent PR codes or OEM numbers.

The catalog links to Yeti workshop-information pages. Those pages contain copyrighted Škoda service illustrations; the accessible web copies do not state a redistribution license. The app links to the references instead of copying those images into the APK. `VERIFIED_ARCHITECTURE` means the construction is supported by Yeti workshop information. `VERIFIED_EXACT` is reserved for an image with exact vehicle fitment and a redistribution license. `REFERENCE_ONLY` is supplemental and is not treated as an exact-fit image.

Key Yeti-specific references:

- CBZB timing chain, tensioner sequence, and oil-pump drive chain: [Yeti 1.2 TSI timing-chain service page](https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/engine_cylinder_head_valve_gear/cylinder_head_part_1/removing_and_installing_timing_chain_and_drive_chain_for_oil_pump/).
- 0AM/DQ200 shaft layout: [Yeti DSG 0AM transmission-system overview](https://workshop-manuals.com/skoda/yeti/power_transmission/gearbox_0am-dsg/technical_data/technical_data_for_the_gearbox/transmission_system_overview/).
- DSG dry double-clutch components: [Yeti 0AM clutch assembly](https://workshop-manuals.com/skoda/yeti/power_transmission/gearbox_0am-dsg/clutch_control/removing_and_installing_the_double_clutch/double_clutch_summary_of_components_%28as_of_06.11%29/).
- CBZB fuel distributor and pressure sensor: [Yeti CBZB intake manifold/fuel distributor parts](https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/mixture_preparation_system_electronic_inj.gas/intake_manifold_and_fuel_distributor/intake_manifold_summary_of_components/part_ii/).
- FWD rear axle variant after CW22/2010: [Yeti FWD rear-axle overview](https://workshop-manuals.com/skoda/yeti/axles_steering/rear_suspension_drive_shaft/repairing_rear_wheel_suspension_%28vehicles_with_front-wheel-drive%29/overview_of_rear_axle/).
- Front-axle construction and alternate carriers: [Yeti front-axle overview](https://workshop-manuals.com/skoda/yeti/axles_steering/front_suspension_drive_shafts/repairing_front_axle/front_axle_overview/).
- Brake variants require PR lookup; the Yeti brake material directs identification to vehicle PR codes: [Yeti brake-system technical data](https://www.scribd.com/document/480875831/skoda-yeti-brake-systems-eng-1).

The catalog contains 89 recursive nodes (81 top-level plus 8 nested), a source reference on every node, and zero bundled technical diagrams or marker coordinates. Marker arrays remain empty until a redistributable, correctly fitted image exists; coordinates are not guessed against text pages.

## Current fill pass (VIN profile)

The catalog has 81 top-level nodes and 8 nested nodes. It currently has 58 `VERIFIED_ARCHITECTURE` source references and 31 `REFERENCE_ONLY` references; none is marked `VERIFIED_EXACT`. These labels describe evidence for construction, not the presence of an embedded image. No technical images are bundled and no marker coordinates are claimed: copying the source workshop illustrations into the APK is not permitted by a license identified in the source.

Direct Yeti/CBZB references used for this pass include the 1.2 TSI timing-chain and oil-pump-chain procedure, intake/fuel-distributor component pages, engine lubrication component list, CBZB cooling hose/radiator pages, Yeti brake repair and handbrake-cable pages, FWD rear-axle overview, front-axle overview, and 0AM DSG overview. The app exposes source links and component lists in place of a fabricated diagram. Brake sizes, spring/damper selections, lighting equipment, climate-control variant, gearbox code, and the fitted front-carrier material remain unresolved where the PR/build data is required.


## Batch 1 — CBZB source pass

Direct Yeti 1.2/63; 77 kW TSI references are now attached to the engine assembly, bottom end, cylinder head/valve gear, timing chain and oil-pump drive chain, camshaft drive, accessory belt drive, intake filter, charge-air/turbo system, cooling circuit/radiator, lubrication system, oil pan/filter/pump, and ignition nodes. The pages are identified as the applicable 77 kW TSI engine family, but the source scans are not bundled: their reproduction rights remain unestablished. No marker coordinates were added without a displayed source diagram.


## Batch 2 — fuel and exhaust

Fuel tank/delivery and CBZB fuel-distributor references now point to the Yeti 1.2 TSI fuel-supply and intake-manifold pages. The front exhaust/catalyst nodes point to the CBZB catalytic-converter component page. The rear silencer has both pre- and post-06.10.2010 source variants recorded; model year alone cannot select one because the production date is unknown. These remain source links, not copied image assets.


## Batch 3 — DSG 0AM/DQ200

Gearbox internals, shafts/gears, mechatronic J743, transmission electronics, selector mechanism, and both date-dependent dry double-clutch source pages are now linked from the DSG nodes. The clutch variants (up to 05.11 / as of 06.11) remain alternatives because the exact build date is unknown. No source illustration is copied into the APK.


## Batch 4 — front drive shafts and CV joints

Both FWD driveshaft nodes now link to Yeti removal instructions and the Yeti inner/outer joint summaries. Their vehicle scope is recorded as FWD/CBZB, while joint type/dimension and OEM selection remain unclaimed.


## Batch 5 — front suspension

Front-axle nodes now expose Yeti sources for the steel-sheet and aluminium carriers, general front suspension, wheel suspension, hub/bearing/brake/ABS and outer drive joint. The two carrier constructions are visible as alternatives; no PR-dependent dimension or specific OEM number is selected.


## Batch 6 — steering

The steering-column, electro-mechanical rack, and tie-rod/linkage nodes now link to Yeti service pages. Rack references include both steel and aluminium carrier layouts; left-hand-drive assumptions and exact rack part numbers are not asserted as VIN-confirmed fitment.

## Batch 7 — brakes

Added direct Yeti front/rear brake repair and caliper procedures, plus front ABS component removal and brake-line references. These sources establish the architecture; disc diameter, caliper variant and PR-dependent hardware remain unresolved. No image is bundled and no image markers are added.

## Batch 8 — rear suspension, FWD only

The rear spring/damper source and anti-roll-bar reference are explicitly for Yeti front-wheel-drive. The catalog keeps the CW22/2010 FWD branch and does not attach any 4×4 rear-axle source. The carrier overview includes FWD layout; exact date/configuration and PR-specific spring rate remain unresolved. No image is bundled.

## Batch 9 — ABS/ESP and brake hydraulics

Added Yeti ABS Mark 60 EC and Mark 70 alternate component/fitting-location sources, axle sensor service material and master-cylinder/hydraulic-unit component pages. Catalog does not select the ABS family or steering side without vehicle build evidence. These are documentation references, not bundled images; hydraulic repair procedures remain subject to the applicable service safety instructions.

## Batch 10 — heating and climate

Added the Yeti heater-unit component page, separate Climatic and Climatronic component references, and refrigerant-circuit layout. Equipment-specific pages remain alternatives; the VIN profile does not establish which control system is fitted. Refrigerant service requires the source safety procedure. Images remain external references because reuse rights are not established.

## Batch 11 — electrical equipment and lighting

Added Yeti component/service references for battery, starter, alternator, fuse/relay carriers, control units, wiring repair, front lamps, tail lamps and plate lighting. Halogen and xenon headlamp sources are alternatives; the fitted lamp package and exact electrical equipment are not selected without build/PR evidence. Source diagrams are not embedded.

## Batch 12 — body, doors, mirrors and wipers

Added Yeti body-front/wing, front/rear door, tailgate/lock, mirror, wiper and washer-system references. Glass itself remains reference-only where no direct, variant-appropriate source page was confirmed in this pass. No generic vehicle images or copied source images were introduced; body colour/trim and glazing options are still build-dependent.
