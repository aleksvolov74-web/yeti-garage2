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
